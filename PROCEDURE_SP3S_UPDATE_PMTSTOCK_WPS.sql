create PROCEDURE SP3S_UPDATE_PMTSTOCK_WPS
@cMemoId VARCHAR(40),
@bREvertFlag BIT,
@BALLOWNEGSTOCK BIT,
@nSpId VARCHAR(40)='',
@BNEGSTOCKFOUND BIT OUTPUT
AS
BEGIN
	DECLARE @cStep VARCHAR(5),@bNewEntry BIT
	
	SET @bNewEntry=(CASE WHEN @bRevertFlag=1 THEN 0 ELSE 1 END)

	

-- UPDATING STOCK OF PMT W.R.T. CURRENT MEMO
	SET @cStep = 178		-- UPDATING PMT TABLE
	EXEC SP_CHKXNSAVELOG 'WPS',@cStep,0,@nSpId,'',1
		
	 
	SET @cStep = 182
	EXEC SP_CHKXNSAVELOG 'WPS',@cStep,0,@nSpId,'',1

	 INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK,bo_order_id )  
	 SELECT  distinct 	  a.BIN_ID, a.DEPT_ID, '' as DEPT_ID_NOT_STUFFED, getdate() as last_update, a.product_code,0 as  quantity_in_stock,'' rep_id,0 STOCK_RECO_QUANTITY_IN_STOCK ,
	          case when isnull(a.bo_order_id,'')='' then null else isnull(a.bo_order_id,'') end
	 FROM #BARCODE_NETQTY a
	 left join pmt01106 b (nolock) on a.product_code =b.product_code and  a.dept_id=b.dept_id and a.bin_id=b.bin_id and isnull(a.bo_order_id,'')=isnull(b.bo_order_id,'')
	 and isnull(a.Pick_list_id,'')=isnull(b.Pick_list_id,'') 
	 WHERE new_entry=@bNewEntry and  b.product_code is null


	 

	print 'revert wps pmt-1'
	--UPDATING STOCK IN PMT01106
	UPDATE A
	SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK-XN_QTY
	FROM PMT01106 A WITH (ROWLOCK)
	JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
	and  isnull(a.bo_order_id,'')=isnull(b.bo_order_id,'')  and isnull(a.Pick_list_id,'')=isnull(b.Pick_list_id,'') 
	WHERE new_entry=@bNewEntry 

	SET @cStep = 184
	EXEC SP_CHKXNSAVELOG 'WPS',@cStep,0,@nSpId,'',1		
	
	

	IF @BALLOWNEGSTOCK=0
	BEGIN
		IF EXISTS(SELECT TOP 1 'U' FROM PMT01106 A (NOLOCK) JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code
					AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
					and isnull(a.bo_order_id,'')=isnull(b.bo_order_id,'')
					and isnull(a.Pick_list_id,'')=isnull(b.Pick_list_id,'') 
					WHERE A.quantity_in_stock<0    )
		BEGIN	
			SET @cStep = 186
			EXEC SP_CHKXNSAVELOG 'WPS',@cStep,0,@nSpId,'',1			
					  
			SELECT A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,'STOCK is GOING NEGATIVE' AS ERRMSG
			FROM PMT01106 A WITH (NOLOCK)
			JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code 
			AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
			and  isnull(a.bo_order_id,'')=isnull(b.bo_order_id,'')
			and isnull(a.Pick_list_id,'')=isnull(b.Pick_list_id,'') 
			WHERE A.quantity_in_stock<0  
					  
			SET @BNEGSTOCKFOUND=1
		END
	END


END