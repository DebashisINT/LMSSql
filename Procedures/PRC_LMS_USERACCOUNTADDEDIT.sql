IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LMS_USERACCOUNTADDEDIT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LMS_USERACCOUNTADDEDIT] AS' 
END
GO
--EXEC PRC_LMS_USERACCOUNTADDEDIT @action='ADDNEW',@userid=11706,@firstname='',@shortname=''
ALTER PROCEDURE [dbo].[PRC_LMS_USERACCOUNTADDEDIT]
(
	@action NVARCHAR(MAX)=NULL,
	@userid int=null,
	@firstname nvarchar(100)=null,
	@shortname nvarchar(100)=null,
	@USER_LOGINID VARCHAR(50)=NULL,
	@USER_NEWLOGINID VARCHAR(50)=NULL,
	@PASSWORD VARCHAR(50)=NULL,
	@BRANCHID INT=NULL,
	@DEPT INT=NULL,
	@DESIGNATION INT=NULL,
	@REPORTTO INT=NULL,
	@GROUP INT=NULL,
	@REMARKS NVARCHAR(200)=NULL,
	@ISACTIVE char(2)=NULL,
	@RETURN_VALUE nvarchar(500)=NULL OUTPUT
)
AS
/***************************************************************************************************************************************
***************************************************************************************************************************************/
BEGIN
	
	IF @action='ADDNEW'
	BEGIN
		select ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS Name, tbl_master_employee.emp_id as Id   
			from tbl_master_employee, tbl_master_contact,tbl_trans_employeeCTC	where 
			tbl_master_employee.emp_contactId = tbl_trans_employeeCTC.emp_cntId and  tbl_trans_employeeCTC.emp_cntId = tbl_master_contact.cnt_internalId 
			and cnt_contactType='EM'  
			and (cnt_firstName Like '%' + @firstname + '%' or cnt_shortName like '%' + @shortname + '%')

		----Rev 1.0
		--IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		----IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		----End of Rev 1.0
		--BEGIN
		--	select DISTINCT ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS Name, tbl_master_employee.emp_id as Id   
		--	from tbl_master_employee, tbl_master_contact,tbl_trans_employeeCTC,FTS_EmployeeShopMap
		--	 where 
		--	tbl_master_employee.emp_contactId = tbl_trans_employeeCTC.emp_cntId and  tbl_trans_employeeCTC.emp_cntId = tbl_master_contact.cnt_internalId 
		--	and tbl_master_contact.cnt_internalId=FTS_EmployeeShopMap.EMP_INTERNALID 
		--	and cnt_contactType='EM'  
		--	and (cnt_firstName Like '%' + @firstname + '%' or cnt_shortName like '%' + @shortname + '%')
		--	AND FTS_EmployeeShopMap.SHOP_CODE IN (select SHOP_CODE from FTS_EmployeeShopMap WHERE USER_ID=@userid)
		--END
		--ELSE
		--BEGIN
		--	select ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS Name, tbl_master_employee.emp_id as Id   
		--	from tbl_master_employee, tbl_master_contact,tbl_trans_employeeCTC	where 
		--	tbl_master_employee.emp_contactId = tbl_trans_employeeCTC.emp_cntId and  tbl_trans_employeeCTC.emp_cntId = tbl_master_contact.cnt_internalId 
		--	and cnt_contactType='EM'  
		--	and (cnt_firstName Like '%' + @firstname + '%' or cnt_shortName like '%' + @shortname + '%')
		--END
	END
	-- Rev 2.0
	ELSE IF @action='ADDNEW_WD'
	BEGIN
		IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@userid)=1)
		BEGIN
			select DISTINCT ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS Name, tbl_master_employee.emp_id as Id   
			from tbl_master_employee, tbl_master_contact,tbl_trans_employeeCTC,FTS_EmployeeShopMap, tbl_master_designation
			 where 
			tbl_master_employee.emp_contactId = tbl_trans_employeeCTC.emp_cntId and  tbl_trans_employeeCTC.emp_cntId = tbl_master_contact.cnt_internalId 
			and tbl_master_contact.cnt_internalId=FTS_EmployeeShopMap.EMP_INTERNALID 
			AND tbl_trans_employeeCTC.emp_Designation=tbl_master_designation.deg_ID AND tbl_master_designation.deg_designation='WD'
			and cnt_contactType='EM'  
			and (cnt_firstName Like '%' + @firstname + '%' or cnt_shortName like '%' + @shortname + '%')
			AND FTS_EmployeeShopMap.SHOP_CODE IN (select SHOP_CODE from FTS_EmployeeShopMap WHERE USER_ID=@userid)
		END
		ELSE
		BEGIN
			select ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS Name, tbl_master_employee.emp_id as Id   
			from tbl_master_employee, tbl_master_contact,tbl_trans_employeeCTC, tbl_master_designation	where 
			tbl_master_employee.emp_contactId = tbl_trans_employeeCTC.emp_cntId and  tbl_trans_employeeCTC.emp_cntId = tbl_master_contact.cnt_internalId 
			AND tbl_trans_employeeCTC.emp_Designation=tbl_master_designation.deg_ID AND tbl_master_designation.deg_designation='WD'
			and cnt_contactType='EM'  
			and (cnt_firstName Like '%' + @firstname + '%' or cnt_shortName like '%' + @shortname + '%')
		END
	END
	-- End of Rev 2.0
	IF @action='EDITUSERDATA'
	BEGIN
		select U.user_name, U.user_loginId, U.user_password, U.user_branchId, U.user_group, U.USER_REMARKS, 
			CTC.emp_Designation, CTC.emp_Department, CTC.emp_reportTo, 
			ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS emp_reportTo_name,
			user_inactive
		FROM tbl_master_user U 
		INNER JOIN tbl_trans_employeeCTC CTC ON U.user_contactId=CTC.emp_cntId
		INNER JOIN tbl_master_employee EMP ON CTC.emp_reportTo=EMP.EMP_ID
		INNER JOIN tbl_master_contact CNT ON EMP.emp_contactId=CNT.cnt_internalId
		WHERE U.user_loginId=@USER_LOGINID
		

	END
	IF @action='MODIFYUSERDATA'
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION

			DECLARE @CNTID NVARCHAR(100)
			SET @CNTID = (SELECT user_contactId FROM TBL_MASTER_USER WHERE user_loginId=@USER_LOGINID)

			DECLARE @Old_b_id bigint
			set @Old_b_id = (select user_branchId from tbl_master_user where user_loginId=@USER_LOGINID)

			UPDATE TBL_MASTER_USER SET user_name=@firstname,user_loginId=@USER_NEWLOGINID, user_password=@PASSWORD, User_branchId=@BRANCHID, 
				user_group=@GROUP, USER_REMARKS=@REMARKS, user_inactive=@ISACTIVE WHERE user_loginId=@USER_LOGINID

			UPDATE tbl_trans_employeeCTC SET emp_Designation=@DESIGNATION, emp_Department=@DEPT, emp_reportTo=@REPORTTO, emp_branch=@BRANCHID 
			WHERE emp_cntId=@CNTID

			UPDATE TBL_MASTER_CONTACT SET cnt_branchid=@BRANCHID WHERE cnt_internalId=@CNTID

			update FTS_EmployeeBranchMap set BranchId=@BRANCHID where Emp_Contactid =@CNTID AND BranchId=@Old_b_id


			set @RETURN_VALUE='Success'

		COMMIT TRANSACTION
		END TRY

		BEGIN CATCH

		ROLLBACK TRANSACTION
			set @RETURN_VALUE='Error in Update.'
		
		END CATCH
	END
END
GO
