CREATE PROCEDURE SP3SBuildDNPI
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
		EXEC SP3S_RFDBTABLE 'DNPI',@cXnID,@cRFTABLENAME OUTPUT 
	
	
	SET @cFilter=(CASE WHEN @nUpdateMode  IN (0,4) THEN '1=1' ELSE 'B.PS_ID='''+@cXnID+'''' END)+@cWhereClause			

	--Start of Build Process for wsl pack slip Transaction
    IF @NUPDATEMODE IN (3)			
	BEGIN
		
		SET @cStep=100
		SET @CCMD=N'UPDATE a SET dnpi_qty=a.dnpi_qty-b.dnpi_qty FROM '+@cRFTABLEName+' a
				  JOIN (	
				  SELECT LEFT(B.PS_ID,2) AS DEPT_ID,  
				  B.PS_DT AS XN_DT,  
				   A.PRODUCT_CODE,
				   SUM(ABS(A.QUANTITY))  AS dnpi_qty,
				   A.BIN_ID  AS [BIN_ID]
				   FROM DNPS_DET A (NOLOCK)  
				   JOIN DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID '+@cInsJoinStr+'
				   WHERE B.CANCELLED = 0 AND '+@cFilter+'
				   GROUP BY LEFT(B.PS_ID,2),B.PS_DT, A.PRODUCT_CODE,a.bin_id
				   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
				
	 END	
	
	 IF @nUpdateMode<>3
	 BEGIN
			SET @CSTEP = 120
			SET @CCMD=N'UPDATE a SET dnpi_qty=a.dnpi_qty+b.dnpi_qty FROM '+@cRFTABLEName+' a
				  JOIN (	
				  SELECT LEFT(B.PS_ID,2) AS DEPT_ID,  
				  B.PS_DT AS XN_DT,  
				   A.PRODUCT_CODE,
				   SUM(ABS(A.QUANTITY))  AS dnpi_qty,
				   A.BIN_ID  AS [BIN_ID]
				   FROM DNPS_DET A (NOLOCK)  
				   JOIN DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID '+@cInsJoinStr+'
				   WHERE B.CANCELLED = 0 AND '+@cFilter+'
				   GROUP BY LEFT(B.PS_ID,2),B.PS_DT, A.PRODUCT_CODE,a.bin_id
				   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
			
			SET @CCMD=N'INSERT '+@cRFTABLEName+' 
						(DEPT_ID,XN_DT,PRODUCT_CODE,dnpi_qty,BIN_ID)
					  
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.dnpi_qty,xn.bin_id FROM 
					  (	
					  SELECT LEFT(B.PS_ID,2) AS DEPT_ID,  
					   B.PS_DT AS XN_DT,  
					   A.PRODUCT_CODE,   
					   ABS(A.QUANTITY) AS dnpi_qty,  
					   A.BIN_ID  AS [BIN_ID] 
					   FROM DNPS_DET A (NOLOCK)  
					   JOIN DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID '+@cInsJoinStr+'
					   WHERE B.CANCELLED = 0 AND '+@cFilter+ '
					  )xn 
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL'					   
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
		END
	--End of Build Process for Debit Note PACK SLIP Transaction
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildDNPI: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildDNPi
