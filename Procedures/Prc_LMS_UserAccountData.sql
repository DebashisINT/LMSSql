IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Prc_LMS_UserAccountData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Prc_LMS_UserAccountData] AS' 
END
GO
ALTER PROCEDURE [dbo].[Prc_LMS_UserAccountData]
	@User_id int=null
AS
/*==================================================================================================================================================
Written by Sanchita for LMS

==================================================================================================================================================*/
Begin
	DECLARE @sqlStrTable NVARCHAR(MAX)
	
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)	
	BEGIN
		DECLARE @empcode VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@User_id)		
		CREATE TABLE #EMPHR
		(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
		)

		CREATE TABLE #EMPHR_EDIT
		(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
		)
		
		INSERT INTO #EMPHR
		SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
		FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
		;with cte as(select	
		EMPCODE,RPTTOEMPCODE
		from #EMPHR 
		where EMPCODE IS NULL OR EMPCODE=@empcode  
		union all
		select	
		a.EMPCODE,a.RPTTOEMPCODE
		from #EMPHR a
		join cte b
		on a.RPTTOEMPCODE = b.EMPCODE
		) 
		INSERT INTO #EMPHR_EDIT
		select EMPCODE,RPTTOEMPCODE  from cte 
	END

	

	SET @sqlStrTable = ''
	SET @sqlStrTable += 'SELECT DISTINCT U.USER_ID AS UID, U.user_loginId as USER_ID,U.USER_NAME, '
	SET @sqlStrTable += '(SELECT BRANCH_DESCRIPTION FROM TBL_MASTER_BRANCH WHERE BRANCH_ID=C.CNT_BRANCHID) AS BRANCHNAME,CTC.REPORTTO '
	SET @sqlStrTable += ',u.CreateDate ,CTC.deg_designation, (CASE WHEN U.user_inactive=''N'' THEN ''Yes'' ELSE ''No'' END) user_inactive, U.USER_CONTACTID ContactID, C.cnt_id, '
	SET @sqlStrTable += ' GRP.grp_name GROUPNAME, CTC.cost_description DEPARTMENTNAME '
	SET @sqlStrTable += 'FROM TBL_MASTER_USER U '
	SET @sqlStrTable += 'INNER JOIN TBL_MASTER_EMPLOYEE E '
	SET @sqlStrTable += 'ON E.EMP_CONTACTID=U.USER_CONTACTID '
	SET @sqlStrTable += 'INNER JOIN TBL_MASTER_CONTACT C ON C.CNT_INTERNALID=U.USER_CONTACTID '
	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
	BEGIN
		SET @sqlStrTable += 'INNER JOIN #EMPHR_EDIT EH ON EH.EMPCODE=C.CNT_INTERNALID '
	END
	SET @sqlStrTable += 'LEFT OUTER JOIN '
	SET @sqlStrTable += '( '
	SET @sqlStrTable += '	SELECT EMPCTC.emp_cntId, '
	SET @sqlStrTable += '	ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''')+''[''+EMP.emp_uniqueCode +'']'' AS REPORTTO '
	SET @sqlStrTable += '	,EMPCTC.emp_Designation AS DESGID ,DG.deg_designation, COST.cost_description '
	SET @sqlStrTable += '	FROM tbl_master_employee EMP '
	SET @sqlStrTable += '	INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @sqlStrTable += '	INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=EMP.emp_contactId and CNT.cnt_contactType=''EM'' '
	SET @sqlStrTable += '	LEFT OUTER JOIN  TBL_MASTER_DESIGNATION DG ON EMPCTC.emp_Designation=DG.deg_id  '
	SET @sqlStrTable += '	LEFT OUTER JOIN  TBL_MASTER_COSTCENTER COST ON EMPCTC.emp_Department=COST.cost_id  '
	SET @sqlStrTable += '	WHERE EMPCTC.emp_effectiveuntil IS NULL '
	SET @sqlStrTable += ')CTC ON CTC.emp_cntId=C.cnt_internalId '
	SET @sqlStrTable += 'LEFT OUTER JOIN  tbl_master_userGroup GRP ON U.user_group=GRP.grp_id '
	SET @sqlStrTable += 'WHERE C.cnt_contactType=''EM'' '
	--SET @sqlStrTable += 'AND U.user_inactive=''N'' '
	SET @sqlStrTable += 'ORDER BY UID DESC '

	--SELECT @sqlStrTable
	EXEC SP_EXECUTESQL @sqlStrTable

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@User_id)=1)
	BEGIN
		DROP TABLE #EMPHR
		DROP TABLE #EMPHR_EDIT	
	END
	
End
GO