create PROCEDURE SP3S_FETCH_BATCHWISEBC ---- Do not overwrite in May 2022 release
@cXnType VARCHAR(10),
@nSpid VARCHAR(40),
@cLocationId VARCHAR(4),
@bDonotCheckStock BIT=0,
@cErrormsg VARCHAR(MAX) output,
@CUSERCODE CHAR(7)=''
AS
BEGIN
	DECLARE @NSISLOC BIT ,@ctable VARCHAR(100),@CStep VARCHAR(10),
	@cCmd NVARCHAR(MAX),@cSpIdJoin VARCHAR(200),@cWhere VARCHAR(200)
		


BEGIN TRY
	SET @CStep='10'
	SET @cErrormsg=''

	DELETE FROM BATCHWISE_FIXCODE_UPLOAD WITH (ROWLOCK)  WHERE SP_ID=@NSPID
	print 'enter SP3S_FETCH_BATCHWISEBC step'+@cStep
	select @NSISLOC=sis_loc from location where dept_id=@CLOCATIONID

	if NOT (@cXntype='SLS' AND isnull(@NSISLOC,0)=1)
	begin
		
		SET @CStep='20'

		SET @ctable=(CASE WHEN @cXntype='SLS' THEN 'SLS_CMD01106_UPLOAD' ELSE 'tmpcmd_'+ltrim(rtrim(str(@nSpId))) END)

		IF @cXntype<>'SLS'
		BEGIN
			SET @CStep='22'


			IF EXISTS (SELECT TOP 1 product_code FROM EossRPS_UPLOAD (NOLOCK)  WHERE sp_id=@nSpid)
				DELETE FROM EossRPS_UPLOAD WITH (ROWLOCK) WHERE sp_id=@nSpid

			SET @CStep='24'

			DECLARE @cManualDiscExpr varchar(40)
			SET  @cManualDiscExpr=(CASE WHEN @cXntype='RPS' THEN 'ISNULL(manual_discount,0)' ELSE '0' END)

			SET @cCmd=N'SELECT '''+@nSpid+''','''+@cLocationId+''' dept_id,''000'' bin_id,a.product_code,a.mrp,
			quantity,row_id,'+
			'row_id temp_row_id,discount_percentage,discount_amount,
			'+@cManualDiscExpr+',net FROM '+@ctable+' a (NOLOCK)
			JOIN sku b (NOLOCK) ON a.product_code=b.product_code'
			PRINT @cCmd
			
			INSERT INTO EossRPS_UPLOAD (sp_id,dept_id,bin_id,product_code,mrp,quantity,row_id,temp_row_id,
			discount_percentage,discount_amount,manual_discount,net)
			EXEC SP_EXECUTESQL @cCmd

			SET @cTable='EossRPS_UPLOAD'
			
			IF @cXntype='TEOSS'
				GOTO END_PROC
		END
		
		SET @CStep='30'
		
		--if @@spid=949
		--	SELECT 'CHECK XNTYPE',@CxNTYPE,@bDonotCheckStock

		--if @@spid=217
		--	select 'check tmpcmdrps before normalize',* from EossRPS_UPLOAD (NOLOCK) WHERE sp_id=@nSpId
		--	print 'enter SP3S_FETCH_BATCHWISEBC step'+@cStep
		EXEC SP3S_NORMALIZE_FIX_PRODUCT_CODE
		@CXN_TYPE='RPS',
		@NSPID=@NSPID,
		@NUPDATEMODE=1,
		@CTEMPDETAILTABLE1=@ctable,
		@CMEMO_ID='',
		@bDonotCheckStock=@bDonotCheckStock,
		@CERRORMSG=@CERRORMSG OUTPUT,
		@CLOC_ID=@cLocationId,
        @CWIZAPPUSERCODE=@CUSERCODE

		--if @@spid=217
		--	select 'check tmpcmdrps after normalize',* from EossRPS_UPLOAD (NOLOCK) WHERE sp_id=@nSpId	
		
		UPDATE EossRPS_UPLOAD WITH (ROWLOCK) SET net=mrp*quantity WHERE sp_id=@nSpId AND net IS NULL

		IF ISNULL(@CERRORMSG,'')<>''
		BEGIN
			SET @CERRORMSG='ERROR IN NORMALIZATION '+@CERRORMSG
			GOTO END_PROC
		END

		
	end

		print 'enter SP3S_FETCH_BATCHWISEBC step'+@cStep
	IF EXISTS(SELECT TOP 1 'U' FROM BATCHWISE_FIXCODE_UPLOAD (NOLOCK) WHERE SP_ID=@NSPID)
	BEGIN
		SET @CStep='40'
		EXEC SP_CHKXNSAVELOG 'SLS_TMP',@cStep,0,@NSPID,'',0

		SELECT @cSpIdJoin=' AND a.sp_id=b.sp_id ',
			   @cWhere=	' WHERE  B.SP_ID ='''+LTRIM(RTRIM((@nSPID)))+''''

		SET @cCmd=N' IF EXISTS (SELECT TOP 1 A.SP_ID FROM '+@cTable+' A WITH (NOLOCK)
				JOIN BATCHWISE_FIXCODE_UPLOAD B (NOLOCK) ON A.ROW_ID=B.ROW_ID '+@cSpIdJoin+' '+@cWhere+') 
			DELETE A FROM '+@cTable+' A WITH (ROWLOCK)
			JOIN BATCHWISE_FIXCODE_UPLOAD B (NOLOCK) ON A.ROW_ID=B.ROW_ID  '+@cSpIdJoin+' '+@cWhere
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
		SET @cStep = 50
		EXEC SP_CHKXNSAVELOG 'SLS_TMP',@cStep,0,@NSPID,'',0

		
		SET @cStep = 60
		EXEC SP_CHKXNSAVELOG 'SLS_TMP',@cStep,0,@NSPID,'',0

		SET @cCmd=N'UPDATE A SET SP_ID=B.SP_ID FROM  '+@cTable+' A WITH (ROWLOCK)
		JOIN BATCHWISE_FIXCODE_UPLOAD B (NOLOCK) ON A.temp_ROW_ID=B.ROW_ID AND A.SP_ID =B.SP_ID+''ZZ''
		WHERE B.SP_ID = '''+LTRIM(RTRIM((@NSPID)))+''' and A.temp_ROW_ID<>a.ROW_ID'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
		
		IF @cXntype<>'SLS'
			UPDATE EossRPS_UPLOAD SET row_id=temp_row_id WHERE sp_id=@nSpId
	END				  		       

END TRY

BEGIN CATCH
	SET @CERRORMSG='Error in Procedure SP3S_FETCH_BATCHWISEBC AT Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

print 'Error in SP3S_FETCH_BATCHWISEBC :'+isnull(@cErrormsg,'')
END