
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LMS_InsertUpdateUser]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LMS_InsertUpdateUser] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_LMS_InsertUpdateUser]
(
@txtusername NVARCHAR(300)=NULL,
@b_id NVARCHAR(100)=NULL,
@txtuserid NVARCHAR(500)=NULL,
@Encryptpass NVARCHAR(500)=NULL,
@contact NVARCHAR(100)=NULL,
@usergroup NVARCHAR(100)=NULL,
@CreateDate  NVARCHAR(50)=NULL,
@CreateUser  NVARCHAR(100)=NULL,
@superuser NVARCHAR(100)=NULL,
@ddDataEntry NVARCHAR(100)=NULL,
@IPAddress NVARCHAR(100)=NULL,
@isactive NVARCHAR(100)=NULL,
@isactivemac NVARCHAR(100)=NULL,
@txtgps NVARCHAR(100)=NULL, 
@Remarks NVARCHAR(200)=NULL,
@istargetsettings INT=NULL,
@user_id BIGINT=NULL,
@ACTION NVARCHAR(MAX),
@IsAllDataInPortalwithHeirarchy INT=0

) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************
***************************************************************************************************************************************/
BEGIN
	DECLARE @sqlStrTable NVARCHAR(MAX)
	--Rev 19.0
	Declare @user_contactId nvarchar(100)='', @ChannelId bigint=0
	--End of Rev 19.0
	-- Rev 25.0
	DECLARE @branch_state int
	-- End of Rev 25.0
	-- Rev 26.0
	DECLARE @DOC_ID BIGINT = 0
	-- End of Rev 26.0


	IF @ACTION='INSERT'
		BEGIN
			INSERT INTO tbl_master_user 
			( user_name,user_branchId,user_loginId,user_password,user_contactId,user_group,CreateDate,CreateUser,
				user_lastsegement,user_TimeForTickerRefrsh,user_superuser,
				user_EntryProfile,user_AllowAccessIP,user_inactive,user_maclock,Gps_Accuracy, USER_REMARKS,
				HierarchywiseTargetSettings, IsAllDataInPortalwithHeirarchy
			)
			VALUES (@txtusername,@b_id,@txtuserid,@Encryptpass,@contact,@usergroup,@CreateDate,@CreateUser ,
				( select top 1 grp_segmentId from tbl_master_userGroup where grp_id in(@usergroup)),
				86400,@superuser,@ddDataEntry,@IPAddress,@isactive,@isactivemac,@txtgps,
				@Remarks,@istargetsettings, @IsAllDataInPortalwithHeirarchy
			)

			set @user_id=SCOPE_IDENTITY();

			
			insert into FTS_EmployeeBranchMap
			select C.cnt_id,U.user_branchId,378,getdate(), U.user_contactId from tbl_master_user U 
			inner join tbl_master_contact C on U.user_contactId=C.cnt_internalid
			inner join tbl_master_employee E on E.emp_contactId=U.user_contactId
			where U.user_id=@user_id and not exists(select employeeid from FTS_EmployeeBranchMap where Employeeid= C.cnt_id )

			set @DOC_ID=SCOPE_IDENTITY();


			select @branch_state=isnull(branch_state,0) from tbl_master_branch	where branch_id=@b_id

			if not exists(select * from FTS_EMPSTATEMAPPING where user_id=@user_id and state_id=@branch_state)
			begin
				insert into FTS_EMPSTATEMAPPING (USER_ID,STATE_ID,SYS_DATE_TIME ,AUTHOR )
				values(@user_id,@branch_state,GETDATE(),@CreateUser)

				-- End of Rev 26.0
			end
			-- End of Rev 25.0
		END

	ELSE IF @ACTION='UPDATE'
		BEGIN
			-- Rev 26.0
			SET @DOC_ID = 0
			
			IF EXISTS (SELECT USER_ID FROM TBL_MASTER_USER WHERE USER_ID=@user_id AND (
				user_name<>@txtusername OR user_branchId<>@b_id OR user_group<>@usergroup OR user_loginId<>@txtuserid OR user_inactive<>@isactive OR user_maclock<>@isactivemac OR user_contactid<>@contact  
				--LastModifyDate<>@CreateDate OR LastModifyUser<>@CreateUser 
				OR user_superuser <>@superuser OR user_EntryProfile<>@ddDataEntry OR user_AllowAccessIP<>@IPAddress OR Gps_Accuracy<>@txtgps OR HierarchywiseTargetSettings<>@istargetsettings 
				OR USER_REMARKS <>@Remarks
				 )
				)
			BEGIN
				SET @DOC_ID = 1
			END
			-- End of Rev 26.0

			DECLARE @Old_b_id bigint
			set @Old_b_id = (select user_branchId from tbl_master_user where user_id=@user_id)

			SET @user_contactId = (select user_contactId from tbl_master_user where user_id=@user_id)

			Update tbl_master_user SET user_name=@txtusername,user_branchId=@b_id,user_group=@usergroup,user_loginId=@txtuserid,user_inactive=@isactive,user_maclock=@isactivemac,user_contactid=@contact,
			LastModifyDate=@CreateDate,LastModifyUser=@CreateUser,user_superuser =@superuser,user_EntryProfile=@ddDataEntry,user_AllowAccessIP=@IPAddress,Gps_Accuracy=@txtgps,HierarchywiseTargetSettings=@istargetsettings
			,USER_REMARKS= @Remarks
			 Where  user_id =@user_id

			 -- Branch Update
			 UPDATE tbl_master_contact SET cnt_branchid=@b_id WHERE cnt_internalId = @user_contactId
			 UPDATE tbl_trans_employeeCTC SET emp_branch=@b_id WHERE emp_cntId = @user_contactId
			 update FTS_EmployeeBranchMap set BranchId=@b_id where Emp_Contactid =@user_contactId AND BranchId=@Old_b_id

			IF @DOC_ID=1
			BEGIN
				EXEC PRC_LMS_TblMasterUser_Audit @TABLE_NAME='TBL_MASTER_USER', @UserId=@CreateUser, @Action='U',@DOC_ID=@user_id 
			END
		END

	ELSE IF @ACTION='ShowSettingsActivateEmployeeBranchHierarchy'
		BEGIN
			select [key],[Value] from FTS_APP_CONFIG_SETTINGS where [Key] ='IsUserBranchHierarchyWiseLMS'
		END
	ELSE IF @ACTION='DELETEUSER'
	begin
		DECLARE @Emp_Contactid NVARCHAR(100) = (SELECT TOP 1 user_contactId from tbl_master_user where USER_ID=@user_id)
		
		--DECLARE @User_GroupId BIGINT = (SELECT TOP 1 user_group from tbl_master_user where USER_ID=@user_id)
		--DECLARE @User_BranchId BIGINT = (SELECT TOP 1 user_branchId from tbl_master_user where USER_ID=@user_id)
		--DECLARE @User_DesigId BIGINT = (SELECT TOP 1 emp_Designation from tbl_trans_employeeCTC where emp_cntId=@Emp_Contactid)

		DECLARE @REC_CNT INT = 0

		--select * from LMS_TOPIC_BRANCHMAP 

		--select * from LMS_TOPIC_DESIGMAP

		--select * from LMS_TOPIC_DEPTMAP

		SET @REC_CNT = ( select COUNT(0) from LMS_TOPIC_EMPMAP WHERE TOPIC_USERID=@user_id)

		IF(@REC_CNT>0)
		BEGIN
			SELECT '-1'
		END
		ELSE
		BEGIN
			BEGIN TRY
			BEGIN TRANSACTION

				DELETE FROM tbl_master_contact WHERE cnt_internalId=@Emp_Contactid 
				DELETE FROM tbl_master_employee WHERE emp_contactId=@Emp_Contactid
				DELETE FROM FTS_EmployeeBranchMap WHERE Emp_Contactid=@Emp_Contactid
				DELETE FROM FTS_EmployeeBranchMap_Log WHERE Emp_Contactid=@Emp_Contactid
				DELETE FROM tbl_trans_employeeCTC WHERE emp_cntId=@Emp_Contactid
				DELETE FROM tbl_master_address WHERE add_cntId=@Emp_Contactid
				DELETE FROM tbl_FTS_MapEmployeeGrade WHERE Emp_Code=@Emp_Contactid
				DELETE FROM tbl_master_phonefax WHERE phf_cntId=@Emp_Contactid
				DELETE FROM TBL_MASTER_USER WHERE USER_ID=@user_id
				DELETE FROM FTS_EMPSTATEMAPPING WHERE USER_ID =@user_id
				

			COMMIT TRANSACTION

				SELECT '1'
			END TRY

			BEGIN CATCH

			ROLLBACK TRANSACTION
				SELECT '-10'
		
			END CATCH
		END

	end
END
GO
