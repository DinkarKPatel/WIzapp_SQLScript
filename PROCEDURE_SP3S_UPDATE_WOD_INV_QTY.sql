CREATE PROCEDURE SP3S_UPDATE_WOD_INV_QTY
(
  @NUPDATEMODE		NUMERIC(1,0)=1,
  @CKEYFIELDVAL VARCHAR(100),
  @NREVERTFLAG INT=0,
  @CXNTYPE VARCHAR(10)='WSL',
  @NBOXNO NUMERIC(3,0)=0,
  @CPRODUCTCODE varchar(50)='',
  @CERRORMSG VARCHAR(1000) OUTPUT

)
AS
BEGIN
    
      DECLARE @NOUTFLAG INT 
      
	
	   IF @NREVERTFLAG = 1  
			SET @NOUTFLAG =  1  
       ELSE  
			SET @NOUTFLAG = -1  
	  
	
  SET @CERRORMSG=''
  BEGIN TRY  
     

      IF @CXNTYPE='WPS'
      BEGIN
		   
		   if @NUPDATEMODE in(3,4,5)
		   begin
				
				INSERT INTO #BuyerOrderInvqty (order_row_id,inv_qty)				
				SELECT  a.BO_DET_ROW_ID,
						SUM(A.QUANTITY) AS INV_QTY
				FROM WPS_DET  A (NOLOCK)
				WHERE A.PS_ID =@CKEYFIELDVAL
				and ((A.BOX_NO =@NBOXNO and @NUPDATEMODE=4)
					or (A.PRODUCT_CODE =@CPRODUCTCODE and @NUPDATEMODE=5)
					OR @nUpdatemode=3)
				AND  ISNULL (a.BO_DET_ROW_ID,'')<>''
				GROUP BY a.BO_DET_ROW_ID

		   end
		   else
		   begin
				
				INSERT INTO #BuyerOrderInvqty (order_row_id,inv_qty)				
				SELECT  a.BO_DET_ROW_ID,
						SUM(A.QUANTITY) AS INV_QTY
				FROM WPS_wps_det_UPLOAD  A (NOLOCK)
				WHERE A.SP_ID =@CKEYFIELDVAL
				AND  ISNULL (a.BO_DET_ROW_ID,'')<>''
				GROUP BY a.BO_DET_ROW_ID

		    
			end
	
		END    
		ELSE IF  @CXNTYPE='WSL'
		BEGIN
		
		   IF @NUPDATEMODE IN(3,4,5)
		   BEGIN
		 
				INSERT INTO #BuyerOrderInvqty (order_row_id,inv_qty)				
				SELECT  A.BO_DET_ROW_ID,
						SUM(A.QUANTITY) AS INV_QTY
				FROM IND01106   A (NOLOCK)
				WHERE A.INV_ID =@CKEYFIELDVAL
				AND ((A.BOX_NO =@NBOXNO AND @NUPDATEMODE=4)
					OR (A.PRODUCT_CODE =@CPRODUCTCODE AND @NUPDATEMODE=5)
					OR @nUpdatemode=3)
				AND  ISNULL (a.BO_DET_ROW_ID,'')<>''
				GROUP BY a.BO_DET_ROW_ID

		   END
		   ELSE 
		   BEGIN
				INSERT INTO #BuyerOrderInvqty (order_row_id,inv_qty)				
				SELECT  A.BO_DET_ROW_ID,
						SUM(A.QUANTITY) AS INV_QTY
				FROM Wsl_ind01106_UPLOAD  A (NOLOCK)
				WHERE A.SP_ID =@CKEYFIELDVAL
				AND  ISNULL (A.BO_DET_ROW_ID,'')<>''
				GROUP BY A.BO_DET_ROW_ID

		   END
		END
		

		--if @@spid=66
		--begin
		--	select 'check bo',@NUPDATEMODE	, @CKEYFIELDVAL,@NREVERTFLAG, @CXNTYPE,@NOUTFLAG,* from #BuyerOrderInvqty
		--end

		UPDATE A SET INV_QTY=ISNULL(A.INV_QTY,0)-(@NOUTFLAG*B.INV_QTY)  
		FROM BUYER_ORDER_DET  A (NOLOCK)
		JOIN #BuyerOrderInvqty b ON a.row_id=b.order_row_id
		
 END TRY  
 BEGIN CATCH  
  SET @CERRORMSG = 'STEP-  SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()  
  GOTO END_PROC  
 END CATCH  
  
END_PROC:  
END