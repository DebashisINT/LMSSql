IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LMS_TblMasterUser_Audit]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LMS_TblMasterUser_Audit] AS' 
END
GO

-- EXEC PRC_LMS_TblMasterUser_Audit @UserId=378, @Action='I',@DOC_ID='54808'

--select * from Tbl_Master_User_Audit
--select * from FTS_UserPartyCreateAccess_Audit
--select * from Employee_ChannelMap_Audit
--select * from FTS_EMPSTATEMAPPING_Audit
--select * from FTS_EmployeeBranchMap_Audit

ALTER PROCEDURE [dbo].[PRC_LMS_TblMasterUser_Audit]
	@TABLE_NAME NVARCHAR(200)=NULL,
	@USERID NVARCHAR(20)=NULL,
	@ACTION NVARCHAR(10)=NULL,
	@DOC_ID NVARCHAR(50)=NULL
 
AS
/****************************************************************************************************************************
Wrtiien by Sanchita	
****************************************************************************************************************************/
BEGIN

	DECLARE @LOGGEDDATE NVARCHAR(50)=CONVERT(VARCHAR(32),GETDATE(),121)

	DECLARE @SQLSTAT NVARCHAR(max)=''
	
	IF (@TABLE_NAME='TBL_MASTER_USER')
		BEGIN
			--HEADER
			SET @SQLSTAT = '
			INSERT INTO DBO.[Tbl_Master_User_Audit] (user_id, user_name, user_loginId, user_password, user_contactId, user_branchId,
				user_group, user_lastsegement, user_LastFinYear, user_LastStno, user_LastStType, user_LastBatch, user_status,
				user_leavedate, user_TimeForTickerRefrsh, user_type, CreateDate, CreateUser, LastModifyDate, LastModifyUser,
				last_login_date, user_superUser, user_lastIP, user_EntryProfile, user_activity, user_AllowAccessIP, user_inactive,
				Mac_Address, DEviceType, SessionToken, user_imei_no, user_maclock, Gps_Accuracy, Custom_Configuration,
				HierarchywiseTargetSettings, isChangePasswordAllowed, HierarchywiseLoginInPortal,
				LoggedOn, LoggedBy, Action) 

			SELECT user_id, user_name, user_loginId, user_password, user_contactId, user_branchId,
				user_group, user_lastsegement, user_LastFinYear, user_LastStno, user_LastStType, user_LastBatch, user_status,
				user_leavedate, user_TimeForTickerRefrsh, user_type, CreateDate, CreateUser, LastModifyDate, LastModifyUser,
				last_login_date, user_superUser, user_lastIP, user_EntryProfile, user_activity, user_AllowAccessIP, user_inactive,
				Mac_Address, DEviceType, SessionToken, user_imei_no, user_maclock, Gps_Accuracy, Custom_Configuration,
				HierarchywiseTargetSettings, isChangePasswordAllowed, HierarchywiseLoginInPortal,
				GETDATE(),'''+@USERID+''','''+@ACTION+ ''' 
			FROM TBL_MASTER_USER WHERE USER_ID='''+@DOC_ID+''''

			--SELECT @SQLSTAT
			EXEC SP_EXECUTESQL @SQLSTAT
		END
	
	IF (@TABLE_NAME='FTS_EMPSTATEMAPPING')
		BEGIN
			INSERT INTO FTS_EMPSTATEMAPPING_Audit ([USER_ID], [STATE_ID], [SYS_DATE_TIME ], [AUTHOR ], [LoggedOn], [LoggedBy], [Action])
			SELECT [USER_ID], [STATE_ID], [SYS_DATE_TIME ], [AUTHOR ], GETDATE(), @USERID, @ACTION FROM FTS_EMPSTATEMAPPING 
				WHERE USER_ID=@DOC_ID
		END

	IF (@TABLE_NAME='FTS_EmployeeBranchMap')
		BEGIN
			INSERT INTO FTS_EmployeeBranchMap_Audit ([ID] ,[EmployeeId],[BranchId],[CreatedBy],[CreatedOn],[Emp_Contactid], [LoggedOn], [LoggedBy], [Action])
			SELECT [ID] ,[EmployeeId],[BranchId],[CreatedBy],[CreatedOn],[Emp_Contactid], GETDATE(), @USERID, @ACTION FROM FTS_EmployeeBranchMap 
				WHERE ID=@DOC_ID
		END
END
GO
