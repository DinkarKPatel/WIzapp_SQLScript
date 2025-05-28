CREATE PROCEDURE SP3S_CREATE_TRG_KEYSCMM
@cKeysTable VARCHAR(100)
AS
BEGIN
	DECLARE @cTableName VARCHAR(100),@cCmd NVARCHAR(MAX),@cTrgname VARCHAR(200)

	SET @cTrgName='TRG_CHK_'+ltrim(rtrim(@cKeysTable))+'_LASTCMDT'
	print 'check trigger for existense of :'+@cTrgName
	IF NOT EXISTS (SELECT name FROM sys.triggers (NOLOCK) WHERE name=@cTrgName)
	BEGIN
		SET @cCmd=N'CREATE TRIGGER '+@cTrgName+' ON '+@cKeysTable+' FOR UPDATE
					AS
					BEGIN
						IF EXISTS (SELECT TOP 1 a.LAST_cm_dt FROM inserted a JOIN  deleted b on a.prefix=b.prefix AND a.finyear=b.finyear
									JOIN cmm01106 c (NOLOCK) ON c.cm_dt=b.last_cm_dt AND LEFT(c.cm_no,len(a.prefix))=a.prefix
									WHERE a.last_cm_dt<b.last_cm_dt)
						BEGIN
							RAISERROR(''Can not raise bill in Lower Date....Please check'',16,1)
						END		   	
					END'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

END
