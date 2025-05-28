create PROCEDURE SP3S_UPDATE_PMTSTOCK_RPS
@nUpdatemode NUMERIC(1,0),
@nSpId VARCHAR(40),
@bREvertFlag BIT,
@BALLOWNEGSTOCK BIT,
@BNEGSTOCKFOUND BIT OUTPUT,
@cErrormsg varchar(max) OUTPUT
AS
BEGIN
	DECLARE @cStep VARCHAR(5),@bNewEntry BIT

BEGIN TRY
	SET @bNewEntry=(CASE WHEN @bRevertFlag=1 THEN 0 ELSE 1 END)
	

	IF @nUpdatemode=2 AND @bREvertFlag=1
		SET @BALLOWNEGSTOCK=1

	SET @cStep = 182
	EXEC SP_CHKXNSAVELOG 'RPS',@cStep,0,@nSpId,'',1


	 INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK )  
	 SELECT  distinct 	  a.BIN_ID, a.DEPT_ID, '' as DEPT_ID_NOT_STUFFED, getdate() as last_update, a.product_code,0 as  quantity_in_stock,'' rep_id,0 STOCK_RECO_QUANTITY_IN_STOCK 
	 FROM SAVETRAN_BARCODE_NETQTY a
	 left join pmt01106 b (nolock) on a.product_code =b.product_code and  a.dept_id=b.dept_id and a.bin_id=b.bin_id 
	  WHERE  sp_id=@nSpId AND   b.product_code is null


	print 'revert wps pmt-1'
	--UPDATING STOCK IN PMT01106
	;WITH CTE_STOCK AS
	(
	   SELECT B.DEPT_ID ,B.BIN_ID ,B.PRODUCT_CODE ,SUM(XN_QTY ) AS XN_QTY
	   FROM  SAVETRAN_BARCODE_NETQTY B  (NOLOCK)
	   WHERE SP_ID=@NSPID 
	   GROUP BY B.DEPT_ID ,B.BIN_ID ,B.PRODUCT_CODE
	   having SUM(XN_QTY )<>0
	)
	
	UPDATE A
	SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK-XN_QTY
	FROM PMT01106 A WITH (ROWLOCK)
	JOIN CTE_STOCK B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
	WHERE ISNULL(A.BO_ORDER_ID ,'')=''
	
	--AND new_entry=@bNewEntry

	SET @cStep = 184
	EXEC SP_CHKXNSAVELOG 'RPS',@cStep,0,@nSpId,'',1			

	IF @BALLOWNEGSTOCK=0
	BEGIN
		IF EXISTS(SELECT TOP 1 'U' FROM PMT01106 A (NOLOCK) JOIN SAVETRAN_BARCODE_NETQTY B (NOLOCK) ON A.product_code=B.product_code
					AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
					WHERE sp_id=@nSpId AND  (A.quantity_in_stock<0  OR ISNULL(a.bo_order_id,'')<>''))
		BEGIN	
			SET @cStep = 186
			EXEC SP_CHKXNSAVELOG 'RPS',@cStep,0,@nSpId,'',1			
					  
			SELECT A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,'STOCK is GOING NEGATIVE'+(Case when @bREvertFlag=1 then 'y' else 'n' end)
			AS ERRMSG
			FROM PMT01106 A WITH (NOLOCK)
			JOIN SAVETRAN_BARCODE_NETQTY B (NOLOCK) ON A.product_code=B.product_code 
			AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
			WHERE sp_id=@nSpId AND (A.quantity_in_stock<0  OR ISNULL(a.bo_order_id,'')<>'')
					  
			SET @BNEGSTOCKFOUND=1
		END
	END

	GOTO END_PROC
END TRY
BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_UPDATE_PMTSTOCK_RPS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END