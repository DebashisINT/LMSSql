IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSSystemConfiguration]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSSystemConfiguration] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSSystemConfiguration]
(
@ACTION NVARCHAR(50)=NULL,
@USER_ID BIGINT =NULL,
@VALUE NVARCHAR(500)=NULL,
@SETTING_KEY NVARCHAR(50)=NULL,
@CONTROL_TYPE NVARCHAR(100)=NULL,
@RETURNMESSAGE NVARCHAR(500) =NULL OUTPUT ,
@RETURNCODE NVARCHAR(20) =NULL OUTPUT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @sqlStrTable NVARCHAR(MAX),@Strsql NVARCHAR(MAX),@sqlStateStrTable NVARCHAR(MAX)

	IF @ACTION='GETLISTING'
	BEGIN
		-- exec [PRC_FTSSystemConfiguration] @ACTION='GETLISTING'
		select [Key],[Description], [CONTROL_TYPE],[VALUE]  from FTS_APP_CONFIG_SETTINGS WHERE IsActive=1

	END

	IF @ACTION = 'SAVESETTINGS'
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION
			-- exec [PRC_FTSSystemConfiguration] @ACTION='SAVESETTINGS', @VALUE='', @SETTING_KEY='',@USER_ID=''
			UPDATE FTS_APP_CONFIG_SETTINGS SET [VALUE]=@VALUE WHERE [KEY]=@SETTING_KEY
			
			COMMIT TRANSACTION

			Set @RETURNMESSAGE= 'Success';
			Set @RETURNCODE='1'

		END TRY

		BEGIN CATCH

		ROLLBACK TRANSACTION
			
			Set @RETURNMESSAGE= ERROR_MESSAGE();
			Set @RETURNCODE='-10'
	
		END CATCH
	END

	SET NOCOUNT OFF
END
GO
