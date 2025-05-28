CREATE PROCEDURE SP3S_CALTOTALS_WPS
@nUpdatemode NUMERIC(2,0),
@cPsId VARCHAR(40),
@nSpId VARCHAR(40),
@nBoxUpdateMode NUMERIC(1,0),
@CERRORMSG VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cStep VARCHAR(10)

	IF OBJECT_ID('tempdb..#tMstTable','U') IS NOT NULL
		DROP TABLE #tMstTable

	IF OBJECT_ID('tempdb..#tDetTable','U') IS NOT NULL
		DROP TABLE #tDetTable
		
	SET @cStep = 195.2
	EXEC SP_CHKXNSAVELOG 'wPS',@cStep,0,@nSpId,'',1

	CREATE TABLE #tMstTable  (ps_id VARCHAR(40),SUBTOTAL NUMERIC(10,2),TOTAL_QUANTITY_STR VARCHAR(300),
							  SCANNED_QTY NUMERIC(10,2),NO_OF_BOXES NUMERIC(4,0),TOTAL_QUANTITY NUMERIC(10,2))

	CREATE TABLE #tDetTable  (product_code VARCHAR(50),BOX_NO NUMERIC(4,0),ps_id VARCHAR(40),
	QUANTITY NUMERIC(10,2),rate NUMERIC(10,2),MRP NUMERIC(10,2),ws_price NUMERIC(10,2))

	DECLARE @cMstTable VARCHAR(200),@CdETtABLE VARCHAR(200),@cWhereClause VARCHAR(500)

	IF @nUpdatemode NOT IN (1,2)
		SELECT @cMstTable='wps_mst',@cDetTable='wps_det',@cWhereClause='A.ps_id='''+@cPsId+''''
	ELSE
		SELECT @cMstTable='wps_wps_mst_upload',@cDetTable='wps_wps_det_upload',
		@cWhereClause='sp_id='''+@nSpId+''''

	SET @cCmd=N'SELECT ps_id,SUBTOTAL,TOTAL_QUANTITY_STR,SCANNED_QTY,NO_OF_BOXES,TOTAL_QUANTITY FROM '+@cMstTable+' A (NOLOCK)
				WHERE '+@cWhereClause
	
	INSERT #tMstTable
	EXEC SP_EXECUTESQL @cCmd

	SET @cCmd=N'SELECT product_code,BOX_NO,ps_id,QUANTITY,rate,MRP,ws_price FROM '+@cDetTable+'  A (NOLOCK)
				WHERE '+@cWhereClause
	
	print @cCmd

	INSERT #tDetTable
	EXEC SP_EXECUTESQL @cCmd

	IF @nUpdatemode=2 AND @nBoxUpdateMode=1
	BEGIN
		SET @cCmd=N'SELECT product_code,BOX_NO,ps_id,QUANTITY,rate,MRP,ws_price FROM wps_det (NOLOCK)
					WHERE ps_id='''+@cPsId+''''
		
		print @cCmd

		INSERT #tDetTable
		EXEC SP_EXECUTESQL @cCmd
	END

	UPDATE #tDetTable SET rate=mrp WHERE rate=0 and ws_price=0

	UPDATE wps_wps_det_upload SET rate=mrp WHERE sp_id=@nSpId AND rate=0 and ws_price=0
	
	DECLARE @STR VARCHAR(MAX),@STR1 VARCHAR(MAX)
    SET @STR=NULL
    SET @STR1=NULL
     
	SELECT  @STR1=PS_ID,@STR =  COALESCE(@STR +  '/ ', ' ' ) + (''+C.UOM_NAME+': '+CAST(SUM(QUANTITY) AS VARCHAR) +' ')  
		FROM #tDetTable A  (NOLOCK)
		JOIN SKU S (nolock) ON S.PRODUCT_CODE=A.PRODUCT_CODE
		JOIN ARTICLE B (nolock) ON S.ARTICLE_CODE=B.ARTICLE_CODE
	JOIN UOM C (nolock) ON C.UOM_CODE=B.UOM_CODE
	GROUP BY C.UOM_NAME ,PS_ID
		
    UPDATE #tMstTable SET TOTAL_QUANTITY_STR =@STR

	EXEC SP_CHKXNSAVELOG 'wps',@cStep,0,@NSPID,'',1
	DECLARE @NSUBTOTAL NUMERIC(14,2),@NTAX NUMERIC(10,2)
		
	-- UPDATING TOTALS IN PIM TABLE
	UPDATE A SET SUBTOTAL = ISNULL( B.SUBTOTAL ,0 ),TOTAL_QUANTITY=INVOICE_QUANTITY
	FROM #tMstTable A 
	LEFT OUTER JOIN
	( 	
		SELECT	PS_ID, SUM(QUANTITY*RATE) AS SUBTOTAL,SUM(QUANTITY) AS INVOICE_QUANTITY
		FROM #tDEtTable
		GROUP BY PS_ID  
	) B ON  A.PS_ID = B.PS_ID  


	DECLARE @nScanqty numeric(10,2),@nBoxes numeric(3,0)

	SELECT @nScanqty= SUM(QUANTITY),@nBoxes=COUNT(DISTINCT BOX_NO) FROM #tDEtTable

	SET @cStep = 297
	EXEC SP_CHKXNSAVELOG 'wps',@cStep,0,@NSPID,'',1
	
	UPDATE #tMstTable SET SCANNED_QTY=@nScanqty,NO_OF_BOXES=@nBoxes



	SET @cCmd=N'UPDATE a SET SUBTOTAL=B.SUBTOTAL,TOTAL_QUANTITY_STR=B.TOTAL_QUANTITY_STR,SCANNED_QTY=B.SCANNED_QTY,
	TOTAL_QUANTITY=B.TOTAL_QUANTITY,NO_OF_BOXES=B.NO_OF_BOXES FROM '+@cMstTable+' a (ROWLOCK) JOIN #tMstTable b ON a.ps_id=b.ps_id
	WHERE '+@cWhereClause
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	
	--if @@spid=103
	--begin
	--	select 'check #tmsttable', * from #tmsttable
	--	select 'check #tdettable', * from #tdettable
	--end
END