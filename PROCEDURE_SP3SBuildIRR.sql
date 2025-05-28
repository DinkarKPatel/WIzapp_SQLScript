create PROCEDURE SP3SBuildIRR
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
	Declare @cCmd nvarchar(max),@cStep varchar(10),@cDelStr VARCHAR(1000),@cDelJoinStr VARCHAR(500),@cFilter VARCHAR(1000)
BEGIN TRY

	DECLARE @bBuildRfopt BIT
	
	EXEC SP3S_CHKRFOPT_BUILD @bBuildRfopt OUTPUT
	
	IF @bBuildRfopt=0
		RETURN
	
	IF @cRfTableName=''	
		EXEC SP3S_RFDBTABLE 'IRR',@cXnID,@cRFTABLENAME OUTPUT 

	SET @cFilter=(CASE WHEN @nUpdateMode IN (0,4) THEN '1=1' ELSE 'b.irm_MEMO_ID='''+@cXnID+'''' END)+@cWhereClause				   

    IF @NUPDATEMODE IN (3)
	BEGIN
		SET @cStep=10
		
		SET @CCMD=N'UPDATE a SET pfi_qty=a.pfi_qty-b.pfi_qty
				  FROM '+@cRFTABLEName+' a
				  JOIN (	
				  SELECT LEFT(B.IRM_MEMO_ID,2) AS DEPT_ID,  
				  B.irm_memo_dt AS XN_DT,  
				   A.NEW_PRODUCT_CODE AS PRODUCT_CODE,
				   SUM(ABS(A.QUANTITY))  AS pfi_qty,
				   A.BIN_ID  AS [BIN_ID]
				   FROM IRD01106 A (NOLOCK)  
				   JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID '+@cInsJoinStr+'
				   WHERE A.NEW_PRODUCT_CODE<>'''' AND '+@cFilter+'
				   GROUP BY LEFT(B.IRM_MEMO_ID,2),B.irm_memo_dt, A.NEW_PRODUCT_CODE,a.bin_id
				   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD	
		
		SET @cStep=20
		SET @CCMD=N'UPDATE a SET cip_qty=a.cip_qty-b.cip_qty
				  FROM '+@cRFTABLEName+' a
				  JOIN (	
				  SELECT LEFT(B.IRM_MEMO_ID,2) AS DEPT_ID,  
				  B.irm_memo_dt AS XN_DT,  
				   A.PRODUCT_CODE,
				   SUM(ABS(A.QUANTITY))  AS cip_qty,
				   A.BIN_ID  AS [BIN_ID]
				   FROM IRD01106 A (NOLOCK)  
				   JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID '+@cInsJoinStr+'
				   WHERE A.NEW_PRODUCT_CODE<>'''' AND '+@cFilter+'
				   GROUP BY LEFT(B.IRM_MEMO_ID,2),B.irm_memo_dt, A.PRODUCT_CODE,a.bin_id
				   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD	


	END

	IF @nUpdateMode<>3
	BEGIN
		SET @CSTEP = 30

		SET @CCMD=N'UPDATE a SET pfi_qty=a.pfi_qty+b.pfi_qty
		  FROM '+@cRFTABLEName+' a
		  JOIN (	
		  SELECT LEFT(B.IRM_MEMO_ID,2) AS DEPT_ID,  
		  B.irm_memo_dt AS XN_DT,  
		   A.NEW_PRODUCT_CODE AS PRODUCT_CODE,
		   SUM(ABS(A.QUANTITY))  AS pfi_qty,
		   A.BIN_ID  AS [BIN_ID]
		   FROM IRD01106 A (NOLOCK)  
		   JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID '+@cInsJoinStr+'
		   WHERE A.NEW_PRODUCT_CODE<>'''' AND '+@cFilter+'
		   GROUP BY LEFT(B.IRM_MEMO_ID,2),B.irm_memo_dt, A.NEW_PRODUCT_CODE,a.bin_id
		   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD	

		SET @cStep=40	    
		SET @CCMD=N'INSERT '+@cRFTABLEName+' (DEPT_ID,XN_DT,PRODUCT_CODE,pfi_qty,BIN_ID)
					  
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.pfi_qty,xn.bin_id FROM 
					  (
				   SELECT LEFT(B.IRM_MEMO_ID,2) AS DEPT_ID,  
				   B.IRM_MEMO_DT AS XN_DT,  
				   A.NEW_PRODUCT_CODE AS PRODUCT_CODE,  
				   SUM(A.QUANTITY) AS pfi_qty,  
				   a.BIN_ID  AS [BIN_ID] 
				   FROM IRD01106 A (NOLOCK)  
				   JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID '+@cInsJoinStr+'
				   WHERE A.NEW_PRODUCT_CODE<>'''' AND '+@cFilter+'
				   GROUP BY LEFT(B.IRM_MEMO_ID,2),B.IRM_MEMO_DT,A.NEW_PRODUCT_CODE,A.BIN_ID
				   ) xn  
				  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
				  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
				  WHERE b.product_code IS NULL'
				   
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD	  


		SET @cStep=50
		SET @CCMD=N'UPDATE a SET cip_qty=a.cip_qty+b.cip_qty
				  FROM '+@cRFTABLEName+' a
				  JOIN (	
				  SELECT LEFT(B.IRM_MEMO_ID,2) AS DEPT_ID,  
				  B.irm_memo_dt AS XN_DT,  
				   A.PRODUCT_CODE,
				   SUM(ABS(A.QUANTITY))  AS cip_qty,
				   A.BIN_ID  AS [BIN_ID]
				   FROM IRD01106 A (NOLOCK)  
				   JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID '+@cInsJoinStr+'
				   WHERE A.NEW_PRODUCT_CODE<>'''' AND '+@cFilter+'
				   GROUP BY LEFT(B.IRM_MEMO_ID,2),B.irm_memo_dt, A.PRODUCT_CODE,a.bin_id
				   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD		
		
						
		SET @CSTEP = 60
				SET @CCMD=N'INSERT '+@cRFTABLEName+' (DEPT_ID,XN_DT,PRODUCT_CODE,cip_qty,BIN_ID)
					  
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.cip_qty,xn.bin_id FROM 
					  (
				   SELECT LEFT(B.IRM_MEMO_ID,2) AS DEPT_ID,  
				   B.IRM_MEMO_DT AS XN_DT,  
				   A.PRODUCT_CODE,  
				   SUM(A.QUANTITY) AS cip_qty,  
				   a.BIN_ID  AS [BIN_ID] 
				   FROM IRD01106 A (NOLOCK)  
				   JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID '+@cInsJoinStr+'
				   WHERE A.NEW_PRODUCT_CODE<>'''' AND '+@cFilter+'
				   GROUP BY LEFT(B.IRM_MEMO_ID,2),B.IRM_MEMO_DT,A.PRODUCT_CODE,a.BIN_ID
				   ) xn  
				  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
				  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
				  WHERE b.product_code IS NULL'
		
		
		
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD
	END
	
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildIRR: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildIRR
