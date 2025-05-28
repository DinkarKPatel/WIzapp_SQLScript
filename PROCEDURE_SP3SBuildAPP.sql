CREATE PROCEDURE SP3SBuildAPP
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
	Declare @cCmd nvarchar(max),@cStep varchar(10),@cFilter VARCHAR(1000)
	
BEGIN TRY

	DECLARE @bBuildRfopt BIT
	
	EXEC SP3S_CHKRFOPT_BUILD @bBuildRfopt OUTPUT
	
	IF @bBuildRfopt=0
		RETURN
	
		
	IF @cRfTableName=''
		EXEC SP3S_RFDBTABLE 'APP',@cXnID,@cRFTABLENAME OUTPUT 
   
	
	SET @cFilter=(CASE WHEN @nUpdateMode in (0,4) THEN '1=1' ELSE 'B.MEMO_ID='''+@cXnID+'''' END)+@cWhereClause			
	--Start of Build Process for Approval Issue Transaction
		IF @nUpdateMode<>1
		BEGIN
			SET @CSTEP = 210
			
			IF @NUPDATEMODE IN (3)			
			BEGIN

				SET @CCMD=N'UPDATE a SET app_qty=a.app_qty-b.app_qty FROM '+@cRFTABLEName+' a
						  JOIN (	
						  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
						  B.MEMO_DT AS XN_DT,  
						   A.PRODUCT_CODE,
						   SUM(ABS(A.QUANTITY))  AS app_QTY,
						   A.BIN_ID  AS [BIN_ID]
						   FROM APD01106 A (NOLOCK)  
						   JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+'
						   WHERE B.CANCELLED = 0 AND '+@cFilter+'
						   GROUP BY LEFT(B.MEMO_ID,2),B.MEMO_DT, A.PRODUCT_CODE,a.bin_id
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
				PRINT @CCMD 
				EXEC SP_EXECUTESQL @CCMD
		  END	
		END
	
		IF @nUpdateMode<>3
		BEGIN
			SET @CSTEP = 220

			SET @CCMD=N'UPDATE a SET app_qty=a.app_qty+b.app_qty FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
					  B.MEMO_DT AS XN_DT,  
					   A.PRODUCT_CODE,
					   SUM(ABS(A.QUANTITY))  AS app_QTY,
					   A.BIN_ID  AS [BIN_ID]
					   FROM APD01106 A (NOLOCK)  
					   JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+'
					   WHERE B.CANCELLED = 0 AND '+@cFilter+'
					   GROUP BY LEFT(B.MEMO_ID,2),B.MEMO_DT, A.PRODUCT_CODE,a.bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
			
			SET @CSTEP = 230									
			SET @CCMD=N'INSERT '+@cRFTABLEName+' 
						(DEPT_ID,XN_DT,PRODUCT_CODE,app_qty,BIN_ID)
					  
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.app_qty,xn.bin_id FROM 
					  (	
					  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
					  B.MEMO_DT AS XN_DT,  
					   A.PRODUCT_CODE,
					   SUM(ABS(A.QUANTITY)) AS app_QTY,
					   A.BIN_ID  AS [BIN_ID]
					   FROM APD01106 A (NOLOCK)  
					   JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+'
					   WHERE B.CANCELLED = 0 AND '+@cFilter+'
					   GROUP BY LEFT(B.MEMO_ID,2),B.MEMO_DT,A.PRODUCT_CODE,A.BIN_ID
					  ) xn  
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL'
					  						  
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
		END
	--End of Build Process for Approval Issue Transaction
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildAPP: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildAPP

