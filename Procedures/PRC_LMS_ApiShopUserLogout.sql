IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FSM_LMS_ApiShopUserLogout]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FSM_LMS_ApiShopUserLogout] AS' 
END
GO

ALTER PROCEDURE [dbo].[FSM_LMS_ApiShopUserLogout]
(
@user_id NVARCHAR(MAX),
@SessionToken NVARCHAR(MAX)=NULL,
@logout_time NVARCHAR(MAX)=NULL
) --WITH ENCRYPTION
AS
/*******************************************************************************************************************************************
Written by Sanchita
*******************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @InternalID NVARCHAR(50)
	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @val NVARCHAR(MAX)
	DECLARE @datefetch DATETIME 
	DECLARE @ROWCOUNT BIGINT

	SET @datefetch=@logout_time
	SET @InternalID=(select user_contactId from tbl_master_user WITH(NOLOCK) WHERE user_id=@user_id)
	SET @SessionToken=right(@SessionToken,10)+convert(varchar(100),@datefetch,109)+'_'+CONVERT(NVARCHAR(13),REPLACE(REPLACE(CAST(getdate() as time),':',''),'.',''))
	
	
	UPDATE tbl_master_user SET SessionToken=NULL,user_status=0 WHERE user_id=@user_id

	SET @ROWCOUNT = @@ROWCOUNT

	IF(@ROWCOUNT>0)
		BEGIN
			
			select  'success' as output
		END

	SET NOCOUNT OFF
END
GO