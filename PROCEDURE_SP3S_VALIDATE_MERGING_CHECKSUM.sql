CREATE PROCEDURE SP3S_VALIDATE_MERGING_CHECKSUM
@cSpId VARCHAR(50),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cTableName VARCHAR(400),@nRecCount NUMERIC(5,0),@cCmd NVARCHAR(MAX),@nStoredCount NUMERIC(5,0),
			@nActualCount NUMERIC(5,0),@cMergeStr VARCHAR(20)
	
	PRINT 'checksumn start'		
	SET @cErrormsg=''
	EXEC SP_CHKXNSAVELOG 'ChkSum','0.8.2',0,@cSpId,'',1
	

	DECLARE @tChkSum TABLE (sp_id varchar(40),tablename VARCHAR(250),recordcount numeric(5,0))

	INSERT @tChkSum (sp_id,tablename,recordcount)
	SELECT sp_id,replace(tablename,'_mirror','_upload') as tablename,
	recordcount FROM xns_merge_checksum (NOLOCK) WHERE sp_id=@cSpId

	EXEC SP_CHKXNSAVELOG 'ChkSum','0.8.4',0,@cSpId,'',1
	WHILE EXISTS (SELECT TOP 1 * FROM @tChkSum)
	BEGIN
		SELECT @cTableName=tablename,@nStoredCount=recordcount FROM @tChkSum

		SET @cCmd=N'SELECT @nActualCount=count(sp_id) from '+@cTableName+' (NOLOCK) WHERE sp_id='''+@cSpId+''''

		print @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nActualCount NUMERIC(5,0) OUTPUT',@nActualCount OUTPUT

		IF @nActualCount<>@nStoredCount
		BEGIN
			SET @cErrormsg= 'Mismatch in Record count of Table :'+@cTableName+' Stored:'+
			ltrim(rtrim(str(@nStoredCount)))+',Actual:'+ltrim(rtrim(str(@nActualCount)))
			BREAK
		END
		DELETE FROM @tChkSum WHERE tablename=@cTableName
	END

	EXEC SP_CHKXNSAVELOG 'ChkSum','0.8.2',0,@cSpId,'',1
	DELETE FROM xns_merge_checksum WITH (ROWLOCK) WHERE sp_id=@cSpId
	PRINT 'checksumn finish'		
END


/*
CREATE TABLE xns_merge_checksum (sp_id varchar(40),tablename VARCHAR(250),recordcount numeric(5,0))

create index ind_xns_merge_checksum  on xns_merge_checksum (sp_id)

use jmloc6
INSERT xns_merge_checksum	( recordcount, sp_id, tablename )  
SELECT 	  recordcount, sp_id, tablename FROM <SOURCEDB>.[DBO].xns_merge_checksum

create table xntype_merging_errors (xn_type varchar(10),memo_id varchar(40),errmsg varchar(max))

select * from prt_rmm01106_upload

*/