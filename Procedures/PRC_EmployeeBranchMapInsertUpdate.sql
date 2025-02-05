IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_EmployeeBranchMapInsertUpdate]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_EmployeeBranchMapInsertUpdate] AS'  
 END 
 GO 
ALTER PROCEDURE [dbo].[PRC_EmployeeBranchMapInsertUpdate]
(
@EMPID NVARCHAR(100)=NULL,
@BranchId NVARCHAR(max)=NULL,
@User_id BIGINT=NULL
) 
AS
/***********************************************************************************
************************************************************************************/
BEGIN
	DECLARE @sqlStrTable NVARCHAR(MAX)

	IF OBJECT_ID('tempdb..#Branch_List') IS NOT NULL
		DROP TABLE #Branch_List
	CREATE TABLE #Branch_List (Branch NVARCHAR(10) collate SQL_Latin1_General_CP1_CI_AS)
	CREATE NONCLUSTERED INDEX Branch ON #Branch_List (Branch ASC)
	IF @BranchId<>''
	BEGIN
		set @BranchId = REPLACE(''''+@BranchId+'''',',',''',''')
		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #Branch_List select branch_id from tbl_master_branch where branch_id in('+@BranchId+')'
		EXEC SP_EXECUTESQL @sqlStrTable
	END

	-- Rev 2.0
	--IF NOT EXISTS(SELECT * FROM FTS_EmployeeBranchMap WHERE EmployeeId=@EMPID)
	--BEGIN
	--	INSERT INTO FTS_EmployeeBranchMap (EmployeeId,BranchId,CreatedBy,CreatedOn)
	--	SELECT @EMPID,Branch,@User_id,GETDATE() FROM #Branch_List
	--END
	--ELSE
	--BEGIN
	--	INSERT INTO FTS_EmployeeBranchMap_Log (ID,EmployeeId,BranchId,CreatedBy,CreatedOn)
	--	SELECT * FROM FTS_EmployeeBranchMap WHERE EmployeeId=@EMPID

	--	DELETE FROM FTS_EmployeeBranchMap WHERE EmployeeId=@EMPID

	--	INSERT INTO FTS_EmployeeBranchMap (EmployeeId,BranchId,CreatedBy,CreatedOn)
	--	SELECT @EMPID,Branch,@User_id,GETDATE() FROM #Branch_List
	--END

	DECLARE @Emp_Contactid NVARCHAR(100) = (SELECT TOP 1 cnt_internalId from tbl_master_contact where cnt_id=@EMPID)

	IF NOT EXISTS(SELECT * FROM FTS_EmployeeBranchMap WHERE EmployeeId=@EMPID)
	BEGIN
		INSERT INTO FTS_EmployeeBranchMap (EmployeeId,BranchId,CreatedBy,CreatedOn,Emp_Contactid)
		SELECT @EMPID,Branch,@User_id,GETDATE(),@Emp_Contactid FROM #Branch_List
	END
	ELSE
	BEGIN
		INSERT INTO FTS_EmployeeBranchMap_Log (ID,EmployeeId,BranchId,CreatedBy,CreatedOn,Emp_Contactid)
		SELECT * FROM FTS_EmployeeBranchMap WHERE EmployeeId=@EMPID

		DELETE FROM FTS_EmployeeBranchMap WHERE EmployeeId=@EMPID

		INSERT INTO FTS_EmployeeBranchMap (EmployeeId,BranchId,CreatedBy,CreatedOn,Emp_Contactid)
		SELECT @EMPID,Branch,@User_id,GETDATE(),@Emp_Contactid FROM #Branch_List
	END
	-- End of Rev 2.0
	
	DROP TABLE #Branch_List
END
GO