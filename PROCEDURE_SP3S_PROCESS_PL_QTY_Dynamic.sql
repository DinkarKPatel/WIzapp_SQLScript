create PROCEDURE SP3S_PROCESS_PL_QTY_Dynamic
(
  @cMemoId VARCHAR(40),
  @NREVERTFLAG INT=0,
  @CERRORMSG VARCHAR(1000) OUTPUT,
  @nmode int=0
 
)
AS
BEGIN
    
      DECLARE @NOUTFLAG INT ,@cStep VARCHAR(5)
      
	
	     
SET @CERRORMSG=''
BEGIN TRY  
	   SET @cStep='10'		  

	   IF @NREVERTFLAG = 1  
		SET @NOUTFLAG =  1  
       ELSE  
		SET @NOUTFLAG = -1  
	  

		print 'Upadte pl qty in order'	
		SET @cStep='20'	

	
	if @nmode<>4
	begin
		UPDATE A SET PL_QTY=ISNULL(A.PL_QTY,0)-(@NOUTFLAG*B.quantity)  
		FROM BUYER_ORDER_DET  A (NOLOCK)
		JOIN 
		(
		 select b.ORD_ROW_ID,sum(quantity) as quantity 
		   from  pld01106 b (NOLOCK) 
		   WHERE b.MEMO_ID=@cMemoid
		   group by b.ORD_ROW_ID
	  ) b ON b.ORD_ROW_ID=a.row_id
	
	end 
	else
	begin
	      
		 ;with PLDCTE as
		  (
		  SELECT a.ORD_ROW_ID, B.ORDER_ID,A.PLD_Product_code ,A.BIN_ID ,PLM.location_code  AS DEPT_ID,
			   (CASE WHEN C.QUANTITY_IN_STOCK < A.QUANTITY THEN C.QUANTITY_IN_STOCK ELSE A.QUANTITY END) as Quantity 
		FROM PLD01106 A (NOLOCK)
		JOIN PLM01106 PLM (NOLOCK) ON A.MEMO_ID = PLM.MEMO_ID 
		JOIN BUYER_ORDER_DET B (NOLOCK)  ON B.ROW_ID =A.ORD_ROW_ID 
		JOIN PMT01106 C ON a.PLD_Product_code =c.product_code and c.BIN_ID =a.BIN_ID and PLM.location_code =c.DEPT_ID and b.order_id =c.bo_order_id 
		WHERE A.MEMO_ID =@CMEMOID
		)
		
		UPDATE A SET PL_QTY=ISNULL(A.PL_QTY,0)-(@NOUTFLAG*B.quantity)  
		FROM BUYER_ORDER_DET  A (NOLOCK)
		JOIN 
		(
		  select b.ORD_ROW_ID,sum(quantity) as quantity 
		   from  PLDCTE b (NOLOCK) 
		   group by b.ORD_ROW_ID
	  ) b ON b.ORD_ROW_ID=a.row_id
	
	

	end
		
		
		--if @@spid=96
	 --  select 'check order after pl',pl_qty,* FROM BUYER_ORDER_DET  A (NOLOCK)
		--JOIN pld01106 b (NOLOCK) ON b.ORD_ROW_ID=a.row_id
		--WHERE b.MEMO_ID=@cMemoid
		    
	   SET @cStep='30'	    
	   UPDATE A  SET TOTAL_PICK_LIST_QTY=ISNULL(A.TOTAL_PICK_LIST_QTY,0)-(@NOUTFLAG*ISNULL(B.PICK_LIST_QTY,0))
	   FROM BUYER_ORDER_MST A (NOLOCK)
	   JOIN
	   (
		SELECT A.ORDER_ID ,SUM(B.QUANTITY) AS PICK_LIST_QTY 
		FROM BUYER_ORDER_DET A (NOLOCK)
		JOIN pld01106 b (NOLOCK) ON b.ORD_ROW_ID=a.row_id
		WHERE b.MEMO_ID=@cMemoid
		GROUP BY A.ORDER_ID
		) B ON A.order_id =B.ORDER_ID 
     
     
END TRY  
BEGIN CATCH  
	  SET @CERRORMSG = 'Procedure SP3S_PROCESS_PL_QTY_Dynamic STEP#' + @cStep + ' ' + ERROR_MESSAGE()  
	  GOTO END_PROC  
END CATCH  

   
END_PROC:  

END
