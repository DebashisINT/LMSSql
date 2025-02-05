IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_DashboardSettingMappedListByID_Get]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_DashboardSettingMappedListByID_Get] AS' 
END
GO
/*****************************************************************************************************************************************************
*****************************************************************************************************************************************************/
ALTER PROC [dbo].[prc_DashboardSettingMappedListByID_Get]
(
	@USERID INT 
)
AS 
    SET NOCOUNT ON ;
    BEGIN TRY 

		SELECT DSM.DashboardSettingMappedID, DST.PermissionLevel,
		DSM.FKDashboardSettingID,  DSM.FKuser_id,DSM.FKDashboardDetailsID,DSM.CreatedDate,
		DSD.DetailsName
		FROM tbl_FTS_DashboardSettingMapped DSM
		INNER JOIN tbl_FTS_DashboardSetting DST ON DST.DashboardSettingID = DSM.FKDashboardSettingID
		INNER JOIN tbl_FTS_DashboardDetails DSD ON DSD.DashboardDetailsID = DSM.FKDashboardDetailsID
		INNER JOIN tbl_FTS_DashboardHeader DSH ON DSD.FKDashboardHeaderID=DSH.DashboardHeaderID
		WHERE DSM.FKuser_id = @USERID AND DSH.HeaderName='MobiLearn'

		---- Rev 1.0
		--DECLARE @IsUserWiseLMSFeatureOnly BIT = (SELECT top 1 IsUserWiseLMSFeatureOnly FROM TBL_MASTER_USER where user_id=@userid)

		--IF(@IsUserWiseLMSFeatureOnly=1)
		--BEGIN
		--	SELECT DSM.DashboardSettingMappedID, DST.PermissionLevel,
		--	DSM.FKDashboardSettingID,  DSM.FKuser_id,DSM.FKDashboardDetailsID,DSM.CreatedDate,
		--	DSD.DetailsName
		--	FROM tbl_FTS_DashboardSettingMapped DSM
		--	INNER JOIN tbl_FTS_DashboardSetting DST ON DST.DashboardSettingID = DSM.FKDashboardSettingID
		--	INNER JOIN tbl_FTS_DashboardDetails DSD ON DSD.DashboardDetailsID = DSM.FKDashboardDetailsID
		--	INNER JOIN tbl_FTS_DashboardHeader DSH ON DSD.FKDashboardHeaderID=DSH.DashboardHeaderID
		--	WHERE DSM.FKuser_id = @USERID AND DSH.HeaderName='MobiLearn'
		--END
		--ELSE
		--BEGIN
		---- End of Rev 1.0
		--	SELECT DSM.DashboardSettingMappedID, DST.PermissionLevel,
		--	DSM.FKDashboardSettingID,  DSM.FKuser_id,DSM.FKDashboardDetailsID,DSM.CreatedDate,
		--	DSD.DetailsName
		--	FROM tbl_FTS_DashboardSettingMapped DSM
		--	INNER JOIN tbl_FTS_DashboardSetting DST ON DST.DashboardSettingID = DSM.FKDashboardSettingID
		--	INNER JOIN tbl_FTS_DashboardDetails DSD ON DSD.DashboardDetailsID = DSM.FKDashboardDetailsID
		--	WHERE DSM.FKuser_id = @USERID
		---- Rev 1.0
		--END
		---- End of Rev 1.0
		
		

    END TRY



    BEGIN CATCH

        DECLARE @ErrorMessage NVARCHAR(4000) ;

        DECLARE @ErrorSeverity INT ;

        DECLARE @ErrorState INT ;

        SELECT  @ErrorMessage = ERROR_MESSAGE() ,

                @ErrorSeverity = ERROR_SEVERITY() ,

                @ErrorState = ERROR_STATE() ;

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState) ;

    END CATCH ;

    RETURN ;
