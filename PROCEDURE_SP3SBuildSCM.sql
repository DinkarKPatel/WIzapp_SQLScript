create PROCEDURE SP3SBuildSCM
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
	EXEC SP3S_RFDBTABLE 'SCM',@cXnID,@cRFTABLENAME OUTPUT 

	
	
	SET @cFilter=(CASE WHEN @nUpdateMode IN (0,4) THEN '1=1' ELSE 'b.MEMO_ID='''+@cXnID+'''' END)+@cWhereClause				   		
	IF @nUpdateMode<>1
	BEGIN
		SET @CSTEP = 10
		
		IF @NUPDATEMODE IN (3)			
		BEGIN
		
		
		     SET @CCMD=N'UPDATE A SET PFI_QTY=A.PFI_QTY-B.PFI_QTY FROM '+@cRFTABLEName+' A
		     JOIN
		     (
			  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
			   B.MEMO_DT AS XN_DT,  
			   A.PRODUCT_CODE,  
			   SUM(ABS(A.QUANTITY))  AS PFI_QTY,    
			   ''000''  AS [BIN_ID]
			   FROM SCF01106 A (NOLOCK)  
			   JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+'
			   WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND '+@cFilter +'
			   GROUP BY LEFT(B.MEMO_ID,2) , B.MEMO_DT , A.PRODUCT_CODE
			    ) B ON A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD

			SET @CSTEP=30
			SET @CCMD=N'UPDATE A SET CIP_QTY=A.CIP_QTY-B.CIP_QTY FROM '+@cRFTABLEName+' A
			             JOIN
			             (
						  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
						   B.MEMO_DT AS XN_DT,  
						   A.PRODUCT_CODE,  
						   SUM(ABS(A.QUANTITY+ADJ_QUANTITY)) AS CIP_QTY,  
						   ''000''  AS [BIN_ID],
						  SUBSTRING(A.PRODUCT_CODE, NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)+1,1),LEN(A.PRODUCT_CODE)) AS BATCHLOTNO    
						 FROM SCC01106 A (NOLOCK)  
						 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+' 
						 WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND '+@cFilter +' 
						 GROUP BY LEFT(B.MEMO_ID,2) , B.MEMO_DT,A.PRODUCT_CODE
						 ) B ON A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
				PRINT @CCMD 
				EXEC SP_EXECUTESQL @CCMD  
		     
		END

	   
	END
	
	IF @nUpdateMode<>3
	BEGIN
		SET @CSTEP = 20
        
          SET @CCMD=N'UPDATE A SET PFI_QTY=A.PFI_QTY+B.PFI_QTY FROM '+@cRFTABLEName+' A
		     JOIN
		     (
			  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
			   B.MEMO_DT AS XN_DT,  
			   A.PRODUCT_CODE,  
			   SUM(ABS(A.QUANTITY))  AS PFI_QTY,    
			   ''000''  AS [BIN_ID]
			   FROM SCF01106 A (NOLOCK)  
			   JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+'
			   WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND '+@cFilter +'
			   GROUP BY LEFT(B.MEMO_ID,2) , B.MEMO_DT , A.PRODUCT_CODE
			    ) B ON A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD

			SET @CSTEP=30
			SET @CCMD=N'UPDATE A SET CIP_QTY=A.CIP_QTY+B.CIP_QTY FROM '+@cRFTABLEName+' A
			             JOIN
			             (
						  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
						   B.MEMO_DT AS XN_DT,  
						   A.PRODUCT_CODE,  
						   SUM(ABS(A.QUANTITY+ADJ_QUANTITY)) AS CIP_QTY,  
						   ''000''  AS [BIN_ID],
						  SUBSTRING(A.PRODUCT_CODE, NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)+1,1),LEN(A.PRODUCT_CODE)) AS BATCHLOTNO    
						 FROM SCC01106 A (NOLOCK)  
						 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+' 
						 WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND '+@cFilter +' 
						 GROUP BY LEFT(B.MEMO_ID,2) , B.MEMO_DT,A.PRODUCT_CODE
						 ) B ON A.PROduct_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
				PRINT @CCMD 
				EXEC SP_EXECUTESQL @CCMD  
	    
	    
		SET @CCMD=N'INSERT '+@cRFTABLEName+' (DEPT_ID,XN_DT,PRODUCT_CODE,PFI_QTY,BIN_ID)
		          SELECT XN.DEPT_ID,XN.XN_DT,XN.PRODUCT_CODE,XN.PFI_QTY,XN.BIN_ID 
		          FROM 
		          (
				  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
				   B.MEMO_DT AS XN_DT,  
				   A.PRODUCT_CODE,   
				   SUM(ABS(A.QUANTITY)) AS PFI_QTY,   
				   ''000''  AS [BIN_ID] ,
				   SUBSTRING(A.PRODUCT_CODE, NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)+1,1),LEN(A.PRODUCT_CODE)) AS BATCHLOTNO
				   FROM SCF01106 A (NOLOCK)  
				   JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+'
				   WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND '+@cFilter +'
				   GROUP BY LEFT(B.MEMO_ID,2) ,B.MEMO_DT ,  A.PRODUCT_CODE
				   ) XN 
				   LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
			       AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
			       WHERE b.product_code IS NULL '
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD
	
		SET @CSTEP=30
		SET @CCMD=N'INSERT '+@cRFTABLEName+'(DEPT_ID,XN_DT,PRODUCT_CODE,CIP_QTY,BIN_ID)
		              SELECT XN.DEPT_ID,XN.XN_DT,XN.PRODUCT_CODE,XN.CIP_QTY,XN.BIN_ID FROM 
		              (
					  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
					   B.MEMO_DT AS XN_DT,  
					   A.PRODUCT_CODE,  
					   SUM(ABS(A.QUANTITY+ADJ_QUANTITY)) AS CIP_QTY,   
					   ''000''  AS [BIN_ID],
					 FROM SCC01106 A (NOLOCK)  
					 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+' 
					 WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND '+@cFilter +'
					 GROUP BY LEFT(B.MEMO_ID,2) ,B.MEMO_DT , A.PRODUCT_CODE
					 ) XN 
					 LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
			         AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
			         WHERE b.product_code IS NULL'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
	END
	
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildSCM: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildSCM
