create PROCEDURE SP3SBuildSNC
(
	 @cXnID			varchar(50)
	,@nUpdateMode	numeric(2)
    ,@cInsJoinStr   VARCHAR(1000)=''
	,@cWhereclause	VARCHAR(1000)=''
	,@cRfTableName  varchar(500)=''		
	,@cErrMsg		varchar(max) output
)
AS
BEGIN
/*
XnType Filter is required during deletion from RFOPT Table because in some cases like TRO From PIM01106
,the inserted xn_id is that of wholesale invoice.
*/
	Declare @cCmd nvarchar(max),@cStep varchar(10),@cFilter varchar(1000),@cDelStr VARCHAR(1000),@cDelJoinStr VARCHAR(500)
BEGIN TRY

	DECLARE @bBuildRfopt BIT
	
	EXEC SP3S_CHKRFOPT_BUILD @bBuildRfopt OUTPUT
	
	IF @bBuildRfopt=0
		RETURN
	IF @cRfTableName=''	
	EXEC SP3S_RFDBTABLE 'SNC',@cXnID,@cRFTABLENAME OUTPUT 
	
	SET @cFilter=(CASE WHEN @nUpdateMode IN (0,4) THEN '1=1' ELSE 'b.memo_ID='''+@cXnID+'''' END)+@cWhereClause				   		
	IF @nUpdateMode<>1
	BEGIN
		SET @CSTEP = 10

		IF @NUPDATEMODE IN (3)		
		BEGIN
		
		      SET @CCMD=N'UPDATE A SET SCF_QTY=A.SCF_QTY-B.SCF_QTY 
		      FROM '+@cRFTABLEName+' A
		      JOIN
		      (
			  SELECT LEFT(A.MEMO_ID,2) AS [DEPT_ID],  
					   B.RECEIPT_DT AS XN_DT,  
					   B2.PRODUCT_CODE,  
					   SUM(CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN B2.TOTAL_QTY ELSE A.QUANTITY END)  AS SCF_QTY,  
					   ,A.BIN_ID  AS [BIN_ID]
					 FROM SNC_DET A (NOLOCK)  
					 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
					 JOIN
					 (
						SELECT REFROW_ID AS [ROW_ID],a.PRODUCT_CODE,COUNT(*) AS [TOTAL_QTY]
						FROM SNC_BARCODE_DET a (NOLOCK)
						WHERE ISNULL(a.PRODUCT_CODE,'''')<>''''
						GROUP BY REFROW_ID,a.PRODUCT_CODE
					 )B2 ON A.ROW_ID = B2.ROW_ID
					 JOIN SKU S1 (NOLOCK) ON S1.product_code=B2.PRODUCT_CODE 
					 JOIN ARTICLE A1 (NOLOCK) ON A1.ARTICLE_CODE=A.ARTICLE_CODE '+@cInsJoinStr+'
					 WHERE  B.WIP=0 AND B.CANCELLED=0 AND '+@cFilter +' 
					 GROUP BY LEFT(A.MEMO_ID,2) ,B.RECEIPT_DT ,  B2.PRODUCT_CODE,  A.BIN_ID 
					 ) B ON  A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
				PRINT @CCMD 
				EXEC SP_EXECUTESQL @CCMD
				
				SET @CSTEP=30
				--PRODUCT_CODES THAT WERE CONSUMED FROM TRADING STOCK
				SET @CCMD=N'UPDATE A SET SCC_QTY=A.SCC_QTY-B.SCC_QTY FROM  '+@cRFTABLEName+' A
				      (
					  SELECT LEFT(A.MEMO_ID,2) AS [DEPT_ID], 
							   B.RECEIPT_DT AS XN_DT,  
							   A.PRODUCT_CODE,  
							   SUM(ABS(A.QUANTITY)) AS SCC_QTY_QTY,
							   A.BIN_ID  AS [BIN_ID]
					 FROM SNC_CONSUMABLE_DET A (NOLOCK)  
					 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+' 
					 WHERE A.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''''
					 AND '+@cFilter +' 
					 GROUP BY LEFT(A.MEMO_ID,2) , B.RECEIPT_DT , A.PRODUCT_CODE, A.BIN_ID
					 ) B ON A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
					 
				PRINT @CCMD 
				EXEC SP_EXECUTESQL @CCMD
		 END
			
		
	END
	
	IF @nUpdateMode<>3
	BEGIN
		SET @CSTEP = 20
		
		
		
		      SET @CCMD=N'UPDATE A SET SCF_QTY=A.SCF_QTY+B.SCF_QTY 
		      FROM '+@cRFTABLEName+' A
		      JOIN
		      (
			  SELECT LEFT(A.MEMO_ID,2) AS [DEPT_ID],  
					   B.RECEIPT_DT AS XN_DT,  
					   B2.PRODUCT_CODE,  
					   SUM(CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN B2.TOTAL_QTY ELSE A.QUANTITY END)  AS SCF_QTY,  
					   ,A.BIN_ID  AS [BIN_ID]
					 FROM SNC_DET A (NOLOCK)  
					 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
					 JOIN
					 (
						SELECT REFROW_ID AS [ROW_ID],a.PRODUCT_CODE,COUNT(*) AS [TOTAL_QTY]
						FROM SNC_BARCODE_DET a (NOLOCK)
						WHERE ISNULL(a.PRODUCT_CODE,'''')<>''''
						GROUP BY REFROW_ID,a.PRODUCT_CODE
					 )B2 ON A.ROW_ID = B2.ROW_ID
					 JOIN SKU S1 (NOLOCK) ON S1.product_code=B2.PRODUCT_CODE 
					 JOIN ARTICLE A1 (NOLOCK) ON A1.ARTICLE_CODE=A.ARTICLE_CODE '+@cInsJoinStr+'
					 WHERE  B.WIP=0 AND B.CANCELLED=0 AND '+@cFilter +' 
					 GROUP BY LEFT(A.MEMO_ID,2) ,B.RECEIPT_DT ,  B2.PRODUCT_CODE,  A.BIN_ID 
					 ) B ON  A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
				PRINT @CCMD 
				EXEC SP_EXECUTESQL @CCMD
				
				SET @CSTEP=30
				--PRODUCT_CODES THAT WERE CONSUMED FROM TRADING STOCK
				SET @CCMD=N'UPDATE A SET SCC_QTY=A.SCC_QTY+B.SCC_QTY FROM  '+@cRFTABLEName+' A
				      (
					  SELECT LEFT(A.MEMO_ID,2) AS [DEPT_ID], 
							   B.RECEIPT_DT AS XN_DT,  
							   A.PRODUCT_CODE,  
							   SUM(ABS(A.QUANTITY)) AS SCC_QTY_QTY,
							   A.BIN_ID  AS [BIN_ID]
					 FROM SNC_CONSUMABLE_DET A (NOLOCK)  
					 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+' 
					 WHERE A.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''''
					 AND '+@cFilter +' 
					 GROUP BY LEFT(A.MEMO_ID,2) , B.RECEIPT_DT , A.PRODUCT_CODE, A.BIN_ID
					 ) B ON A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
					 
				PRINT @CCMD 
				EXEC SP_EXECUTESQL @CCMD
		
		---FINISHED PRODUCT_CODES TO TRADING 
		
		SET @CCMD=N'INSERT '+@cRFTABLEName+'(DEPT_ID,XN_DT,PRODUCT_CODE,SCF_QTY,BIN_ID)
		          SELECT XN.DEPT_ID,XN.XN_DT,XN.PRODUCT_CODE,XN.SCF_QTY,XN.BIN_ID FROM 
		          (
				  SELECT LEFT(A.MEMO_ID,2) AS [DEPT_ID],  
						   B.RECEIPT_DT AS XN_DT,  
						   B2.PRODUCT_CODE,   
						   SUM(CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN B2.TOTAL_QTY ELSE A.QUANTITY END) AS SCF_QTY,  
						   A.BIN_ID  AS [BIN_ID]
						 FROM SNC_DET A (NOLOCK)  
						 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
						 JOIN
						 (
							SELECT REFROW_ID AS [ROW_ID],a.PRODUCT_CODE,COUNT(*) AS [TOTAL_QTY]
							FROM SNC_BARCODE_DET a (NOLOCK)
							WHERE ISNULL(a.PRODUCT_CODE,'''')<>''''
							GROUP BY REFROW_ID,a.PRODUCT_CODE
						 )B2 ON A.ROW_ID = B2.ROW_ID
						 JOIN SKU S1 (NOLOCK) ON S1.product_code=B2.PRODUCT_CODE 
						 JOIN ARTICLE A1 (NOLOCK) ON A1.ARTICLE_CODE=A.ARTICLE_CODE '+@cInsJoinStr+'
						 WHERE  B.WIP=0 AND B.CANCELLED=0 AND '+@cFilter +'
						 GROUP BY LEFT(A.MEMO_ID,2) , B.RECEIPT_DT , B2.PRODUCT_CODE,A.BIN_ID
						 ) XN 
						 LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
	                     AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
	                      WHERE b.product_code IS NULL'
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD
		
		SET @CSTEP=30
		--PRODUCT_CODES THAT WERE CONSUMED FROM TRADING STOCK
		SET @CCMD=N'INSERT '+@cRFTABLEName+'(DEPT_ID,XN_DT,PRODUCT_CODE,SCC_QTY,BIN_ID)
		       SELECT XN.DEPT_ID,XN.XN_DT,XN.PRODUCT_CODE,XN.SCC_QTY,XN.BIN_ID 
		     FROM
		     (
				  SELECT LEFT(A.MEMO_ID,2) AS [DEPT_ID], 
						 B.RECEIPT_DT AS XN_DT,  
						 A.PRODUCT_CODE,   
						 SUM(ABS(A.QUANTITY)) AS SCC_QTY,   
						 A.BIN_ID  AS [BIN_ID] 
				 FROM SNC_CONSUMABLE_DET A (NOLOCK)  
				 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+' 
				 WHERE A.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''''
				 AND '+@cFilter +' 
				 GROUP BY LEFT(A.MEMO_ID,2) ,B.RECEIPT_DT ,A.PRODUCT_CODE,A.BIN_ID
			 ) XN
			 LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
	         AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
	         WHERE b.product_code IS NULL'
			 
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD
	END
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildSNC: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildSNC
