CREATE PROCEDURE SP3SBuildAPR
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
	Declare @cCmd nvarchar(max),@cStep varchar(10),@cFilter VARCHAR(1000),@cDelStr VARCHAR(1000),@cDelJoinStr VARCHAR(500)
	
BEGIN TRY

	DECLARE @bBuildRfopt BIT
	
	EXEC SP3S_CHKRFOPT_BUILD @bBuildRfopt OUTPUT
	
	IF @bBuildRfopt=0
		RETURN
		
	IF @cRfTableName=''	
		EXEC SP3S_RFDBTABLE 'APR',@cXnID,@cRFTABLENAME OUTPUT 
	
	
	SET @cFilter=(CASE WHEN @nUpdateMode IN (0,4) THEN '1=1' ELSE 'c.MEMO_ID='''+@cXnID+'''' END)+@cWhereClause			

	--Start of Build Process for Approval Return Transaction
		IF @nUpdateMode<>1
		BEGIN
		    IF @NUPDATEMODE IN (3)		    
		    BEGIN
				 SET @CSTEP = 220	

				 SET @CCMD=N'UPDATE a SET apr_qty=a.apr_qty-b.apr_qty FROM '+@cRFTABLEName+' a
						  JOIN (	
						  SELECT LEFT(C.MEMO_ID,2) AS DEPT_ID,  
						  C.MEMO_DT AS XN_DT,  
						   B.PRODUCT_CODE,
						   SUM(ABS(A.QUANTITY))  AS apr_QTY,
						   A.BIN_ID  AS [BIN_ID]
						   FROM APPROVAL_RETURN_DET A (NOLOCK)  
						   JOIN APD01106 B (NOLOCK)ON A.APD_ROW_ID = B.ROW_ID  
						   JOIN APPROVAL_RETURN_MST C (NOLOCK) ON C.MEMO_ID = A.MEMO_ID '+REPLACE(@cInsJoinstr,'b.memo_id','c.memo_id')+'
						   WHERE  C.CANCELLED = 0 AND '+@cFilter+'
						   GROUP BY LEFT(C.MEMO_ID,2),C.MEMO_DT, b.PRODUCT_CODE,a.bin_id
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
				 PRINT @CCMD 
				 EXEC SP_EXECUTESQL @CCMD
								 
		    END  
		END
		
		IF @nUpdateMode<>3
		BEGIN
			SET @CSTEP =  240
			
			SET @CCMD=N'UPDATE a SET apr_qty=a.apr_qty+b.apr_qty FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(C.MEMO_ID,2) AS DEPT_ID,  
					  c.MEMO_DT AS XN_DT,  
					   B.PRODUCT_CODE,
					   SUM(ABS(A.QUANTITY))  AS apr_QTY,
					   A.BIN_ID  AS [BIN_ID]
					   FROM APPROVAL_RETURN_DET A (NOLOCK)  
					   JOIN APD01106 B (NOLOCK)ON A.APD_ROW_ID = B.ROW_ID  
					   JOIN APPROVAL_RETURN_MST C (NOLOCK) ON C.MEMO_ID = A.MEMO_ID '+REPLACE(@cInsJoinstr,'b.memo_id','c.memo_id')+'
					   WHERE  C.CANCELLED = 0 AND '+@cFilter+'
					   GROUP BY LEFT(C.MEMO_ID,2),C.MEMO_DT, b.PRODUCT_CODE,a.bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			 PRINT @CCMD 
			 EXEC SP_EXECUTESQL @CCMD
			
			SET @CSTEP =  250
		    SET @CCMD=N'INSERT '+@cRFTABLEName+' 
						(DEPT_ID,XN_DT,PRODUCT_CODE,apr_qty,BIN_ID)
					   SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.apr_qty,xn.bin_id FROM 
					  (	
					   SELECT LEFT(C.MEMO_ID,2) AS DEPT_ID,  
							  C.MEMO_DT AS XN_DT,  
							  B.PRODUCT_CODE,   
							  SUM(ABS(A.QUANTITY)) AS apr_QTY,  
							  A.BIN_ID  AS [BIN_ID]
						  FROM APPROVAL_RETURN_DET A (NOLOCK)  
						  JOIN APD01106 B (NOLOCK)ON A.APD_ROW_ID = B.ROW_ID  
						  JOIN APPROVAL_RETURN_MST C (NOLOCK) ON C.MEMO_ID = A.MEMO_ID '+REPLACE(@cInsJoinstr,'b.memo_id','c.memo_id')+'
						  WHERE  C.CANCELLED = 0 AND '+@cFilter+'
						  GROUP BY LEFT(C.MEMO_ID,2),C.MEMO_DT,B.PRODUCT_CODE,A.BIN_ID
					  ) xn  
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL'	
		    PRINT @CCMD 
		    EXEC SP_EXECUTESQL @CCMD
		END
	--End of Build Process for Approval Return Transaction
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildAPR: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildAPR
