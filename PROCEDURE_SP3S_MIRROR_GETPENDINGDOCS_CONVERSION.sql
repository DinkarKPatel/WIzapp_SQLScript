CREATE PROCEDURE SP3S_MIRROR_GETPENDINGDOCS_CONVERSION
@NMODE INT,
@CTARGETLOCID VARCHAR(5)='',
@NSPID INT=0
AS
BEGIN
	DECLARE @CCMD NVARCHAR(MAX),@CERRORMSG VARCHAR(MAX),@CSTEP VARCHAR(5),@CREQCHALLANID VARCHAR(40),
			@CREQXNTYPE VARCHAR(10),@CCALLFORPENDINGW8DOCS VARCHAR(2),@BGETPENDINGDOCS BIT,
			@CTEMPDBNAME VARCHAR(200)

BEGIN TRY
	SET @CERRORMSG=''
		
	SET @CSTEP='10'
	
	IF @NMODE=1
	BEGIN
		SELECT TOP 1 @CCALLFORPENDINGW8DOCS=VALUE FROM CONFIG WHERE CONFIG_OPTION='SKIP_ITEMRECON_DUETO_W8CONVERSION'	
		SET @CCALLFORPENDINGW8DOCS=ISNULL(@CCALLFORPENDINGW8DOCS,'')
		
		SET @BGETPENDINGDOCS=0
		IF @CCALLFORPENDINGW8DOCS='1'
		BEGIN
			IF NOT EXISTS (SELECT TOP 1 MEMO_ID FROM PENDING_DOCS_W8CONVERSION)
				SET @BGETPENDINGDOCS=1	
		END
		
		SELECT 	@BGETPENDINGDOCS AS GET_DOCLIST
	END
	
	ELSE	
	IF @NMODE=2
	BEGIN
		SET @CSTEP='20'
				
		SELECT A.MRR_ID AS MEMO_ID,'PUR' AS XN_TYPE,'' AS ERRMSG FROM PIM01106 A
		WHERE A.location_Code =@CTARGETLOCID AND INV_MODE=2
		UNION
		SELECT A.RM_ID AS MEMO_ID,'PRT' AS XN_TYPE,'' AS ERRMSG FROM RMM01106 A
		WHERE A.location_Code=@CTARGETLOCID AND MODE=2
		UNION
		SELECT A.INV_ID AS MEMO_ID,'WSL' AS XN_TYPE,'' AS ERRMSG FROM INM01106 A
		WHERE A.location_Code=@CTARGETLOCID AND INV_MODE=2		
		UNION
		SELECT TOP 1 DEPT_ID AS MEMO_ID,'OPS' AS XN_TYPE,'' AS ERRMSG FROM OPS01106 A
		WHERE DEPT_ID=@CTARGETLOCID
		
		GOTO END_PROC
	END
	
	ELSE
	IF @NMODE=3
	BEGIN
		BEGIN TRANSACTION
		
		SET @CTEMPDBNAME=DB_NAME()+'_TEMP.DBO.'
		SET @CSTEP='30'
		TRUNCATE TABLE PENDING_DOCS_W8CONVERSION
		
		SET @CSTEP='40'
		SET @CCMD=N'SELECT XN_TYPE,MEMO_ID FROM '+@CTEMPDBNAME+'TMP_PENDING_DOCS_W8CONVERSION_'+LTRIM(RTRIM(STR(@NSPID)))
		
		INSERT PENDING_DOCS_W8CONVERSION (XN_TYPE,MEMO_ID)
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP='50'
		SET @CCMD=N'DROP TABLE '+@CTEMPDBNAME+'TMP_PENDING_DOCS_W8CONVERSION_'+LTRIM(RTRIM(STR(@NSPID)))
		EXEC SP_EXECUTESQL @CCMD
		
		GOTO END_PROC
	END	
	
	ELSE
	IF @NMODE=4
	BEGIN	
		SELECT TOP 1 @CREQCHALLANID=A.MEMO_ID,@CREQXNTYPE=A.XN_TYPE FROM PENDING_DOCS_W8CONVERSION A
		WHERE ISNULL(SYNCH,0)=0 ORDER BY (CASE WHEN XN_TYPE IN ('PUR','OPS') THEN 1 ELSE 2 END),MEMO_ID ASC
		
		SELECT @CREQCHALLANID AS MEMO_ID,@CREQXNTYPE AS XN_TYPE,'' AS ERRMSG
	END
	
END TRY

BEGIN CATCH
	SET @CERRORMSG='PROCEDURE SP3S_MIRROR_GETPENDINGDOCS_CONVERSION: STEP#'+@CSTEP+' ERROR MESSAGE - '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')<>''	
			ROLLBACK
		ELSE 
			COMMIT	
	END
	
	IF ISNULL(@CERRORMSG,'')<>''	
		SELECT @CERRORMSG AS ERRMSG
	
END
