IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LMS_EmployeeCTCInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LMS_EmployeeCTCInsert] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_LMS_EmployeeCTCInsert]
	@emp_cntId 				nvarchar(50),
	@emp_dateofJoining  	datetime,
	@emp_Organization		int,
	@emp_JobResponsibility	int,
	@emp_Designation		int,
	@emp_Grade		        int=null, 
	@emp_type				int,
	@emp_Department			int,
	@emp_reportTo			int,
	@emp_deputy				int,
	@emp_colleague			int,
	@emp_workinghours		int,
	@emp_currentCTC			nvarchar(50), 
	@emp_basic 				nvarchar(50),
	@emp_HRA 				nvarchar(50),
	@emp_CCA 				nvarchar(50),
	@emp_spAllowance 		nvarchar(50),
	@emp_childrenAllowance	nvarchar(50),
	@emp_totalLeavePA 		nvarchar(50),
	@emp_PF 				nvarchar(50),
	@emp_medicalAllowance	nvarchar(50),
	@emp_LTA				nvarchar(50),
	@emp_convence 			nvarchar(50),
	@emp_mobilePhoneExp		nvarchar(50),
	@emp_totalMedicalLeavePA nvarchar(50),	
	@userid 				int,	
	@emp_LeaveSchemeAppliedFrom	datetime,
	@emp_branch				int,
	@emp_Remarks			varchar(max),
	@EMP_CarAllowance  numeric(10, 0),
	@EMP_UniformAllowance  numeric(10, 0),
	@EMP_BooksPeriodicals  numeric(10, 0),
	@EMP_SeminarAllowance   numeric(10, 0),
	@EMP_OtherAllowance   numeric(10, 0),
	-- Rev 1.0
	@emp_colleague1			int=0,
	@emp_colleague2			int=0
	-- End of Rev 1.0
	
AS
/****************************************************************************************************************************************************
1.0		Sanchita		V2.0.26		29-01-2022		CTC Tab - "Colleague1" and "Colleague2", refer: 24655
2.0		Sanchita		V2.0.36		27-12-2022		After saving an Employee through Employee Master 
													The 'Office Type' Address of the respective employee to be updated as Branch Ad
													Employee Master Branch Selection will be the same Branch to be mapped for this employee Branch Mapping
													Refer: 25531, 25533
3.0		Sanchita		V2.0.40		20-04-2023		Employee Office address shall be updated along with City Long Lat in employee 
													address table. Refer: 25826
****************************************************************************************************************************************************/
begin
	declare @rowEffected int,@oldLeaveScheme int, @oldEffectiveDate datetime

	-- Rev 2.0
	DECLARE @branch_address1 VARCHAR(500), @branch_address2 VARCHAR(500), @branch_address3 VARCHAR(500),
		@branch_country INT, @branch_state int, @branch_pin varchar(50), @branch_city int, @branch_area int, @emp_userid bigint
	-- End of Rev 2.0
	-- Rev 3.0
	DECLARE @City_Lat nvarchar(max)='0.0', @City_Long nvarchar(max)='0.0'
	-- End of Rev 3.0

	select @oldLeaveScheme=isnull(emp_totalLeavePA,'0'),@oldEffectiveDate=emp_LeaveSchemeAppliedFrom from tbl_trans_employeeCTC where ( emp_effectiveuntil is null or emp_effectiveuntil = '1/1/1900 12:00:00 AM' or emp_effectiveuntil = '1/1/1900')  and emp_cntId = @emp_cntId

	---Rejoin Section----------
--	IF Not Exists(select * from tbl_trans_employeectc where emp_cntId=@emp_cntId  and (emp_effectiveuntil is null or emp_effectiveuntil = '1/1/1900 12:00:00 AM' or emp_effectiveuntil = '1/1/1900'))
--	BEGIN
		update tbl_master_employee set emp_dateofLeaving=NULL,emp_ReasonLeaving=NULL where emp_contactId=@emp_cntId
--	END



	--Updating Old data
	update tbl_trans_employeeCTC set emp_effectiveuntil = dateadd(dd,-1,@emp_dateofJoining) where ( emp_effectiveuntil is null or emp_effectiveuntil = '1/1/1900 12:00:00 AM' or emp_effectiveuntil = '1/1/1900')  and emp_cntId = @emp_cntId
	select @rowEffected=@@rowcount
	
	-- Rev 1.0 [ ,emp_colleague1 and ,emp_colleague1 added]
	--Inserting New row of data
	INSERT INTO tbl_trans_employeeCTC 
                            (emp_cntId,emp_effectiveDate,emp_organization, emp_JobResponsibility,
                            emp_Designation,Emp_Grade,emp_type,emp_Department,emp_reportTo,emp_deputy,emp_colleague,emp_workinghours,
                            emp_currentCTC,emp_basic,emp_HRA,emp_CCA,emp_spAllowance,emp_totalLeavePA,emp_PF,emp_medicalAllowance,
                            emp_LTA,emp_convence,emp_mobilePhoneExp,emp_totalMedicalLeavePA,CreateUser,CreateDate,
							emp_branch,emp_LeaveSchemeAppliedFrom,emp_Remarks,EMP_CarAllowance,EMP_UniformAllowance,EMP_BooksPeriodicals,EMP_SeminarAllowance,
							EMP_OtherAllowance,emp_colleague1,emp_colleague2)
                            Values(@emp_cntId,@emp_dateofJoining,@emp_organization,@emp_JobResponsibility,
                            @emp_Designation,@emp_Grade,@emp_type,@emp_Department,@emp_reportTo,@emp_deputy,@emp_colleague,@emp_workinghours,
                            @emp_currentCTC,@emp_basic,@emp_HRA,@emp_CCA,@emp_spAllowance,@emp_totalLeavePA,@emp_PF,@emp_medicalAllowance,
                            @emp_LTA,@emp_convence,@emp_mobilePhoneExp,@emp_totalMedicalLeavePA,@userid,getdate(),
							@emp_branch,@emp_LeaveSchemeAppliedFrom,@emp_Remarks,@EMP_CarAllowance,@EMP_UniformAllowance,@EMP_BooksPeriodicals,@EMP_SeminarAllowance,
							@EMP_OtherAllowance,@emp_colleague1,@emp_colleague2)
							--Updating tbl_master_contact
							update [tbl_master_contact] set
							[cnt_branchid]=@emp_branch 
						where [cnt_internalId]=@emp_cntId
						
  -- Code Added by  Sandip on 20032017 to update Branchid in tbl_master_user if User of this employee exists.	
	-- Rev 2.0
	select @branch_address1=isnull(branch_address1,''), @branch_address2=isnull(branch_address2,''), @branch_address3=isnull(branch_address3,''),
	@branch_country=isnull(branch_country,0), @branch_state=isnull(branch_state,0), @branch_pin=isnull(branch_pin,''), 
	@branch_city=isnull(branch_city,0), @branch_area=branch_area from tbl_master_branch
	where branch_id=@emp_branch

	-- Rev 3.0
	set @City_Lat = (select top 1 isnull(City_lat,'0.0') from tbl_master_city where city_id=@branch_city )
	set @City_Long = (select top 1 isnull(City_Long,'0.0') from tbl_master_city where city_id=@branch_city )
	-- End of Rev 3.0

	select top 1 @emp_userid=user_id from tbl_master_user where user_contactid=@emp_cntId

	if not exists(select * from tbl_master_address where add_cntId=@emp_cntId and add_entity='employee' and add_addressType='Office')
	begin
		-- Rev 3.0 [ columns add_Lat and add_Long added in query ]
		insert into tbl_master_address(Isdefault,contactperson,add_cntId,add_entity,add_addressType,add_address1,add_address2,
		add_address3,add_city,add_landMark,add_country,add_state,add_area,add_pin,CreateDate,CreateUser,add_Phone,add_Email,add_Website,
		add_Designation,add_address4,add_Lat,add_Long) 
		values(0,'',@emp_cntId,'employee','Office',@branch_address1,@branch_address2,
		@branch_address3,@branch_city,'',@branch_country,@branch_state,@branch_area,@branch_pin,getdate(),@userid,'','',''
		,'','',@City_Lat,@City_Long)
	end

	-- To be updated at the time of user add
	--if not exists(select * from FTS_EMPSTATEMAPPING where user_id=@emp_userid and state_id=@branch_state)
	--begin
	--	insert into FTS_EMPSTATEMAPPING (USER_ID,STATE_ID,SYS_DATE_TIME ,AUTHOR )
	--	values(@emp_userid,@branch_state,GETDATE(),@userid)
	--end

	if (select top 1 [Value] from FTS_APP_CONFIG_SETTINGS where [key]='IsActivateEmployeeBranchHierarchy')=0
	begin
		select top 1 @emp_userid=cnt_id from tbl_master_contact where cnt_internalId=@emp_cntId

		if not exists(select * from FTS_EmployeeBranchMap where Emp_Contactid=@emp_cntId and BranchId=@emp_branch )
		begin
			insert into FTS_EmployeeBranchMap(EmployeeId, BranchId, CreatedBy, CreatedOn, Emp_Contactid)
			values(@emp_userid,@emp_branch,@userid,getdate(),@emp_cntId)
		end
	end
	-- End of Rev 2.0
  
	--Sudip Pal 05-02-2019 Grade


	if not exists(select Emp_Grade from  tbl_FTS_MapEmployeeGrade where Emp_Code=@emp_cntId)
	BEGIN
	if(@emp_Grade<>0)
	
	INSERT  INTO tbl_FTS_MapEmployeeGrade values(@emp_Grade,@emp_cntId,GETDATE())
	

	END
	ELSE
	BEGIN
	if(@emp_Grade<>0)
	update tbl_FTS_MapEmployeeGrade set Emp_Grade=@emp_Grade where Emp_Code=@emp_cntId
	else
	delete  from tbl_FTS_MapEmployeeGrade where Emp_Code=@emp_cntId
	END


	--Sudip Pal 05-02-2019 Grade
	
  
  			
	 if exists(select 'Y' from tbl_master_user where user_contactId=@emp_cntId)
      begin
          update tbl_master_user set user_branchId=@emp_branch where user_contactId=@emp_cntId
          --set @ReturnValue='1'
      end
       -- Code Above Added by  Sandip on 20032017 to update Branchid in tbl_master_user if User of this employee exists.									
						
end
GO

