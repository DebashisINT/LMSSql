IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LMS_ApiUserLogin]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LMS_ApiUserLogin] AS' 
END
GO

-- EXEC PRC_LMS_ApiUserLogin @userName ='8017845376', @password ='mpcBb4q+5Dj/igo5ESszqw==', @version_name = 'Version 1.0.1', @device_token ='123'

ALTER PROCEDURE [dbo].[PRC_LMS_ApiUserLogin]
(
@userName NVARCHAR(MAX),
@password NVARCHAR(MAX),
@version_name NVARCHAR(MAX)=NULL,
@device_token NVARCHAR(300)=NULL,
@SessionToken NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************************************
Written by Sanchita for LMS Separation

REV NO.		DATE			VERSION			DEVELOPER			CHANGES										           	INSTRUCTED BY
-------		----			-------			---------			-------											        -------------					


****************************************************************************************************************************************************************************************************/
BEGIN
	--BEGIN  TRAN
	SET NOCOUNT ON

	declare @SQL NVARCHAR(MAX) , @val NVARCHAR(MAX), @UserId  int, @Cnt_Id  NVARCHAR(100), @User_Type NVARCHAR(MAX)
		,@branchid int, @InternalID NVARCHAR(50), @DesignationID NVARCHAR(50)=NULL, @datefetch datetime =GETDATE(), @versions int
	
	
	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName FROM TBL_MASTER_CONTACT WITH (NOLOCK)
	WHERE cnt_contactType IN('EM')
	
	set @versions=REPLACE(REPLACE(REPLACE(REPLACE(@version_name,'Version ',''),'D',''),'L',''),'.','')
	IF(@versions>=(SELECT REPLACE(Value,'.','') FROM FTS_APP_CONFIG_SETTINGS WHERE [Key]='min_req_version'))
		BEGIN
			set @UserId=(select user_id  from  tbl_master_user as usr WITH(NOLOCK) where  user_loginId=@userName   and user_password=@password and user_inactive='N')
			set @InternalID=(select  user_contactId  from tbl_master_user WITH(NOLOCK) where user_id=@UserId)


			SET @DesignationID=(
				select  N.deg_id  from tbl_master_user as musr WITH(NOLOCK) 
				INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId = musr.user_contactId
				INNER JOIN
				(
				select  cnt.emp_cntId,desg.deg_designation,MAx(emp_id) as emp_id,desg.deg_id  from 
				tbl_trans_employeeCTC as cnt WITH(NOLOCK) 
				left outer join tbl_master_designation as desg WITH(NOLOCK) on desg.deg_id=cnt.emp_Designation
				group by emp_cntId,desg.deg_designation,desg.deg_id,emp_effectiveuntil having emp_effectiveuntil is null
				)N
				on  N.emp_cntId=musr.user_contactId 
				where musr.user_id=@UserId)


			if(isnull(@UserId,'') !='')
				BEGIN

					update tbl_master_user  set  SessionToken=@SessionToken,user_status=1 where user_loginId=@userName   and user_password=@password and user_inactive='N'

					-------------------------Device Token----------------------------------------

					If exists(select  Id  from tbl_FTS_devicetoken WITH(NOLOCK) where UserID=@UserId)
						BEGIN
							UPDATE tbl_FTS_devicetoken set device_token=@device_token  where UserID=@UserId
						END
					ELSE
						BEGIN
							INSERT INTO tbl_FTS_devicetoken(device_token,UserID)VALUES(@device_token,@UserId)
						END

				
					-----------------------Total Counting Return---------------------

					SELECT top 1 cast(USR.user_id as varchar(50)) as [user_id],cnt_firstName+' '+cnt_lastName  as name,
					phf.phf_phoneNumber as phone_number,addr.add_address1,eml.eml_email as email 
					,S.add_address1 as [address] ,S.add_country as country, cast(S.add_city as varchar(50)) as city, STAT.id as [state]
					,pinzip.pin_code as pincode, '200' as success

					FROM tbl_master_user as usr WITH(NOLOCK) 
					LEFT OUTER JOIN #TEMPCONTACT CONT ON usr.user_contactId=cont.cnt_internalId
					LEFT OUTER JOIN tbl_master_address as addr WITH(NOLOCK) on addr.add_cntId= usr.user_contactId 
					LEFT OUTER JOIN tbl_master_phonefax as phf WITH(NOLOCK) on phf.phf_cntId= usr.user_contactId 
					LEFT OUTER JOIN tbl_master_email as eml WITH(NOLOCK) on eml.eml_internalId= usr.user_contactId 
					LEFT OUTER  JOIN (
					SELECT   add_cntId,add_state,add_city,add_country,add_pin,add_address1  FROM  tbl_master_address  WITH(NOLOCK) where add_addressType='Office'
					)S on S.add_cntId=cont.cnt_internalId
					--LEFT OUTER JOIN tbl_master_pinzip as pinzip on pinzip.pin_id=S.add_pin
					LEFT OUTER JOIN tbl_master_state as STAT WITH(NOLOCK) on STAT.id=S.add_state
					LEFT outer join tbl_master_pinzip as pinzip WITH(NOLOCK) on pinzip.pin_id=S.add_pin
					where
					USR.user_id=@UserId  and user_inactive='N'
					order by  phf.Isdefault desc

					IF NOT EXISTS (SELECT DESIGNATION_ID FROM TBL_FTS__NOTALLOW_STATE_TARGET WITH(NOLOCK) WHERE DESIGNATION_ID=@DesignationID)--<>119
						BEGIN
							IF EXISTS(SELECT STATE_ID from FTS_EMPSTATEMAPPING WITH(NOLOCK) where STATE_ID=0 and  USER_ID=@UserId)
								BEGIN
									select  stat.id as id,stat.state as state_name  from tbl_master_state as stat WITH(NOLOCK) 
									INNER JOIN 
									(
									select distinct  add_state  from tbl_master_address WITH(NOLOCK) 
									)T on stat.id=T.add_state
								END
							ELSE
								BEGIN
									select STATE_ID as id,stat.state as state_name from FTS_EMPSTATEMAPPING as empstate WITH(NOLOCK)  
									INNER JOIN tbl_master_state as stat WITH(NOLOCK) ON empstate.STATE_ID=stat.id WHERE USER_ID=@UserId 
								END
						END
				


				END
			ELSE
				BEGIN
					--SELECT 0
					SELECT '202' as success
				END
		END
	ELSE
		BEGIN
			--SELECT 0
			SELECT '206' as success,'New version is available now. Please update it from the Play Store.' as 'Dynamic_message' -- Unless you can''t login into the app.
		END	


	DROP TABLE #TEMPCONTACT
	
	SET NOCOUNT OFF
END
GO