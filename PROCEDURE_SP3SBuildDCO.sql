CREATE PROCEDURE SP3SBuildDCO
(
	 @cXnID			varchar(50)
	,@nUpdateMode	numeric(2)
    ,@cInsJoinStr   VARCHAR(1000)=''
	,@cWhereclause	VARCHAR(1000)=''
	,@cRfTableName  varchar(500)=''
	,@cErrMsg		varchar(max) output
	,@NRECEIPTMODE      BIT=0
)
AS
BEGIN
/*
XnType Filter is required during deletion from RFOPT Table because in some cases like TRO From PIM01106
,the inserted xn_id is that of wholesale invoice.
*/
	Declare @cCmd nvarchar(max),@cStep varchar(10),@cDelStr VARCHAR(1000),@cDelJoinStr VARCHAR(500),
			@cFilter VARCHAR(1000)
	
BEGIN TRY

	DECLARE @bBuildRfopt BIT
	
	EXEC SP3S_CHKRFOPT_BUILD @bBuildRfopt OUTPUT
	
	IF @bBuildRfopt=0
		RETURN
		
	IF @cRfTableName=''
		EXEC SP3S_RFDBTABLE 'DCO',@cXnID,@cRFTABLENAME OUTPUT 	
	
	
	--Start of Build Process for InterFloor Transaction
		SET @cFilter=(CASE WHEN @nUpdateMode IN (0,4) THEN '1=1' ELSE 'B.MEMO_ID='''+@cXnID+'''' END)+@cWhereClause

	   IF @NUPDATEMODE IN (3)		   
	   BEGIN
			SET @CSTEP = 10
			SET @CCMD=N'UPDATE a SET dco_qty=a.dco_qty-b.dco_qty FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(a.MEMO_ID,2) AS DEPT_ID,  
					  B.MEMO_DT AS XN_DT,  
					   A.PRODUCT_CODE,
					   SUM(ABS(A.QUANTITY))  AS dco_QTY,
					   A.SOURCE_BIN_ID AS [BIN_ID]
					   FROM FLOOR_ST_DET A  
					   JOIN FLOOR_ST_MST B  ON A.MEMO_ID  = B.MEMO_ID'+@cInsJoinStr+'    
					   WHERE  B.CANCELLED = 0 AND '+@cFilter+'
					   GROUP BY LEFT(a.MEMO_ID,2),B.MEMO_DT, A.PRODUCT_CODE,a.source_bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
			
			SET @CSTEP = 20		
			SET @CCMD=N'UPDATE a SET dci_qty=a.dci_qty-b.dci_qty FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(a.MEMO_ID,2) AS DEPT_ID,  
					  B.MEMO_DT AS XN_DT,  
					   A.PRODUCT_CODE,
					   SUM(ABS(A.QUANTITY))  AS dci_QTY,
					   A.ITEM_TARGET_BIN_ID AS [BIN_ID]
					   FROM FLOOR_ST_DET A  
					   JOIN FLOOR_ST_MST B  ON A.MEMO_ID  = B.MEMO_ID'+@cInsJoinStr+'    
					   WHERE  B.CANCELLED = 0 AND ISNULL(B.RECEIPT_DT,'''')<>'''' AND  '+@cFilter+'
					   GROUP BY LEFT(a.MEMO_ID,2),B.MEMO_DT, A.PRODUCT_CODE,a.ITEM_TARGET_BIN_ID
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
				
		END
		
		IF @nUpdateMode<>3
		BEGIN
			  	
			  SET @CSTEP = 30
			  IF ISNULL(@NRECEIPTMODE,0)<>1
			  BEGIN

				  SET @CSTEP = 35		
				  SET @CCMD=N'UPDATE a SET dco_qty=a.dco_qty+b.dco_qty FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(a.MEMO_ID,2) AS DEPT_ID,  
					  B.MEMO_DT AS XN_DT,  
					   A.PRODUCT_CODE,
					   SUM(ABS(A.QUANTITY))  AS dco_QTY,
					   A.SOURCE_BIN_ID AS [BIN_ID]
					   FROM FLOOR_ST_DET A  
					   JOIN FLOOR_ST_MST B  ON A.MEMO_ID  = B.MEMO_ID'+@cInsJoinStr+'    
					   WHERE  B.CANCELLED = 0 AND '+@cFilter+'
					   GROUP BY LEFT(a.MEMO_ID,2),B.MEMO_DT, A.PRODUCT_CODE,a.source_bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
				  PRINT @CCMD 
				  EXEC SP_EXECUTESQL @CCMD
				
				  SET @cStep=40			  
 				  SET @CCMD=N'INSERT '+@cRFTABLEName+' 
						   (DEPT_ID,XN_DT,PRODUCT_CODE,dco_qty,BIN_ID)
					  
						  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.dco_qty,xn.bin_id FROM 
						  (	
							  SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,  
							   B.MEMO_DT   AS XN_DT,  
							   A.PRODUCT_CODE,   
							   SUM(A.QUANTITY) AS dco_qty,       
							   A.SOURCE_BIN_ID  AS [BIN_ID]
							   FROM FLOOR_ST_DET A  
							   JOIN FLOOR_ST_MST B  ON A.MEMO_ID  = B.MEMO_ID'+@cInsJoinStr+'    
							   WHERE  B.CANCELLED = 0 AND '+@cFilter+'
							   GROUP BY LEFT(A.MEMO_ID,2),B.MEMO_DT,A.PRODUCT_CODE,A.SOURCE_BIN_ID
						   ) xn  
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL'	   							   
					  
				  PRINT @CCMD
				  EXEC SP_EXECUTESQL @CCMD
				  
			  END
			  
			  SET @CSTEP = 50
			  SET @CCMD=N'UPDATE a SET dci_qty=a.dci_qty+b.dci_qty FROM '+@cRFTABLEName+' a
				  JOIN (	
				  SELECT LEFT(a.MEMO_ID,2) AS DEPT_ID,  
				  B.MEMO_DT AS XN_DT,  
				   A.PRODUCT_CODE,
				   SUM(ABS(A.QUANTITY))  AS dci_QTY,
				   A.ITEM_TARGET_BIN_ID AS [BIN_ID]
				   FROM FLOOR_ST_DET A  
				   JOIN FLOOR_ST_MST B  ON A.MEMO_ID  = B.MEMO_ID'+@cInsJoinStr+'    
				   WHERE  B.CANCELLED = 0  AND ISNULL(B.RECEIPT_DT,'''')<>''''  AND '+@cFilter+'
				   GROUP BY LEFT(a.MEMO_ID,2),B.MEMO_DT, A.PRODUCT_CODE,a.ITEM_TARGET_BIN_ID
				   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			  PRINT @CCMD 
			  EXEC SP_EXECUTESQL @CCMD
			
			  SET @cStep=60			  
			  SET @CCMD=N'INSERT '+@cRFTABLEName+' 
					   (DEPT_ID,XN_DT,PRODUCT_CODE,dci_qty,BIN_ID)
				  
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.dci_qty,xn.bin_id FROM 
					  (	
						  SELECT LEFT(A.MEMO_ID,2) AS DEPT_ID,  
						   B.MEMO_DT   AS XN_DT,  
						   A.PRODUCT_CODE,   
						   SUM(A.QUANTITY) AS dci_qty,       
						   A.ITEM_TARGET_BIN_ID  AS [BIN_ID]
						   FROM FLOOR_ST_DET A  
						   JOIN FLOOR_ST_MST B  ON A.MEMO_ID  = B.MEMO_ID'+@cInsJoinStr+'    
						   WHERE  B.CANCELLED = 0   AND ISNULL(B.RECEIPT_DT,'''')<>'''' AND '+@cFilter+'
						   GROUP BY LEFT(a.MEMO_ID,2),B.MEMO_DT,A.PRODUCT_CODE,A.ITEM_TARGET_BIN_ID
					   ) xn  
				  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
				  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
				  WHERE b.product_code IS NULL'	   							   
				  
			  PRINT @CCMD
			  EXEC SP_EXECUTESQL @CCMD
			  
		END
	
	--End of Build Process for InterFloor Transaction
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildDCO: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	
	
EndProc:

END
--End of procedure - SP3SBuildDCO
