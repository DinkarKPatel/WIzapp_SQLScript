create PROCEDURE SP3SBuildJWR
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
	EXEC SP3S_RFDBTABLE 'JWR',@cXnID,@cRFTABLENAME OUTPUT 

	SET @cFilter=(CASE WHEN @nUpdateMode IN (0,4) THEN '1=1' ELSE 'b.RECEIPT_ID='''+@cXnID+'''' END)+@cWhereClause				   

	IF @nUpdateMode<>1
	BEGIN
		SET @CSTEP = 10
		
	   IF @NUPDATEMODE IN (3)	  
	   BEGIN 
			 SET @CCMD=N'UPDATE A  SET JWR_QTY=A.JWR_QTY-B.JWR_QTY
			          FROM '+@CRFTABLENAME+' A
			          JOIN
			          (
					  SELECT LEFT(B.RECEIPT_ID,2) AS DEPT_ID,  
					   B.RECEIPT_DT AS XN_DT,  
					   A.PRODUCT_CODE,  
					   SUM(ABS(A.QUANTITY)) AS JWR_QTY, 
					   A.BIN_ID  AS [BIN_ID]
					 FROM JOBWORK_RECEIPT_DET A (NOLOCK)  
					 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID  
					 JOIN JOBWORK_ISSUE_DET D (NOLOCK) ON D.ROW_ID=A.REF_ROW_ID  
					 JOIN JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = D.ISSUE_ID  '+@CINSJOINSTR+'
					 WHERE B.CANCELLED=0 AND E.ISSUE_TYPE=1 AND ISNULL(B.WIP,0)=0 AND ISNULL(B.RECEIVE_MODE,0)<>1 AND '+@CFILTER+'
					 GROUP BY  LEFT(B.RECEIPT_ID,2) , B.RECEIPT_DT , A.PRODUCT_CODE,  A.BIN_ID
					 ) B ON A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
	  END	
	END
	
	IF @nUpdateMode<>3
	BEGIN
		SET @CSTEP = 20
		
		 SET @CCMD=N'UPDATE A  SET JWR_QTY=A.JWR_QTY+B.JWR_QTY
			          FROM '+@CRFTABLENAME+' A
			          JOIN
			          (
					  SELECT LEFT(B.RECEIPT_ID,2) AS DEPT_ID,  
					   B.RECEIPT_DT AS XN_DT,  
					   A.PRODUCT_CODE,  
					   SUM(A.QUANTITY) AS JWR_QTY, 
					   A.BIN_ID  AS [BIN_ID]
					 FROM JOBWORK_RECEIPT_DET A (NOLOCK)  
					 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID  
					 JOIN JOBWORK_ISSUE_DET D (NOLOCK) ON D.ROW_ID=A.REF_ROW_ID  
					 JOIN JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = D.ISSUE_ID  '+@CINSJOINSTR+'
					 WHERE B.CANCELLED=0 AND E.ISSUE_TYPE=1 AND ISNULL(B.WIP,0)=0 AND ISNULL(B.RECEIVE_MODE,0)<>1 AND '+@CFILTER+'
					 GROUP BY  LEFT(B.RECEIPT_ID,2) , B.RECEIPT_DT , A.PRODUCT_CODE,  A.BIN_ID
					 ) B ON A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
		
		SET @cStep=30
		
		SET @CCMD=N'INSERT '+@cRFTABLEName+'(DEPT_ID,XN_DT,PRODUCT_CODE,JWR_QTY,BIN_ID)
		          select XN.DEPT_ID,XN.XN_DT,XN.PRODUCT_CODE,XN.JWR_QTY,XN.BIN_ID 
		          from
		          (
				  SELECT LEFT(B.RECEIPT_ID,2) AS DEPT_ID,  
				   B.RECEIPT_DT AS XN_DT,  
				   A.PRODUCT_CODE,  
				   SUM(A.QUANTITY) AS JWR_QTY,  
				   A.BIN_ID  AS [BIN_ID]
				 FROM JOBWORK_RECEIPT_DET A (NOLOCK)  
				 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID  
				 JOIN JOBWORK_ISSUE_DET D (NOLOCK) ON D.ROW_ID=A.REF_ROW_ID  
				 JOIN JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = D.ISSUE_ID  '+@cInsJoinStr+'
				 WHERE B.CANCELLED=0 AND E.ISSUE_TYPE=1 AND ISNULL(B.WIP,0)=0 AND ISNULL(B.RECEIVE_MODE,0)<>1 AND '+@cFilter+'
				 GROUP BY LEFT(B.RECEIPT_ID,2) ,B.RECEIPT_DT ,A.PRODUCT_CODE ,A.BIN_ID 
				 ) XN 
				 LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
			     AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
			     WHERE b.product_code IS NULL 
				 '
			
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD
	END
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildJWR: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildJWR
