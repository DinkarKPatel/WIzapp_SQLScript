CREATE PROCEDURE SP3S_EOSS_UPDATE_ADDITIONAL_DISCOUNT_FLATSCHEME
AS
BEGIN
	DECLARE @bLoop BIT,@cSchemeRowId VARCHAR(40),@nCmdQty NUMERIC(4,0),@nBaseQty NUMERIC(4,0)
	
	IF NOT EXISTS (SELECT TOP 1 CMD_ROW_ID FROM #TMPCMD a JOIN scheme_Setup_det b ON a.SCHEME_SETUP_DET_ROW_ID=b.row_id
		 WHERE ISNULL(additional_discount,0)<>0)
		GOTO END_PROC
	

	SELECT 	 SCHEME_SETUP_DET_ROW_ID,additional_discount_base_qty,SUM(quantity) as cmd_qty
	INTO #tmpAddnlSchemes
	FROM #tmpcmd a JOIN  scheme_Setup_det b ON a.SCHEME_SETUP_DET_ROW_ID=b.row_id
	WHERE ISNULL(additional_discount,0)<>0 AND scheme_mode=1
	GROUP BY SCHEME_SETUP_DET_ROW_ID,additional_discount_base_qty
	
	SET @bLoop=0
	
	WHILE @bLoop=0
	BEGIN
		SET @cSchemeRowId=''
		
		SELECT TOP 1 @cSchemeRowId=SCHEME_SETUP_DET_ROW_ID,@nBaseQty=additional_discount_base_qty,@nCmdQty=cmd_qty
		from #tmpAddnlSchemes
		
		IF ISNULL(@cSchemeRowId,'')=''	
			BREAK
		

		IF @nCmdQty>=@nBaseQty
		BEGIN
			print 'Now Update additional Discount'
			
			UPDATE a SET discount_amount=a.discount_amount+(a.net*b.additional_discount/100)
			FROM #tmpcmd a JOIN  scheme_Setup_det b ON a.SCHEME_SETUP_DET_ROW_ID=b.row_id
			WHERE b.scheme_mode=1 AND b.disc_method=1 AND a.SCHEME_SETUP_DET_ROW_ID=@cSchemeRowId

			UPDATE a SET discount_amount=a.discount_amount+(CASE WHEN b.additional_discount>a.net 
			THEN a.net ELSE b.additional_discount END)
			FROM #tmpcmd a JOIN  scheme_Setup_det b ON a.SCHEME_SETUP_DET_ROW_ID=b.row_id
			WHERE b.scheme_mode=1 AND b.disc_method=3 AND a.SCHEME_SETUP_DET_ROW_ID=@cSchemeRowId
			
			UPDATE a SET discount_percentage=(a.discount_amount/(a.mrp*a.quantity))*100 from #tmpcmd a
			JOIN  scheme_Setup_det b ON a.SCHEME_SETUP_DET_ROW_ID=b.row_id
			WHERE b.scheme_mode=1 AND b.disc_method IN (1,3) AND a.SCHEME_SETUP_DET_ROW_ID=@cSchemeRowId
		END
		
		DELETE from #tmpAddnlSchemes WHERE SCHEME_SETUP_DET_ROW_ID=@cSchemeRowId
	END	
	
END_PROC:

END
