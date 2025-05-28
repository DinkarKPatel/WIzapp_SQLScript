CREATE PROCEDURE SP3SBuildGRNPS
(
	 @cXnID			varchar(50)
	,@nUpdateMode	numeric(2)
    ,@cInsJoinStr   VARCHAR(1000)=''
	,@cWhereclause	VARCHAR(1000)=''
	,@nSpId			INT=0
	,@cRfTableName  varchar(500)=''
	,@cErrMsg		varchar(max) output
)
AS
BEGIN
/*
XnType Filter is required during deletion from RFOPT Table because in some cases like TRO From PIM01106
,the inserted xn_id is that of wholesale invoice.
*/
	Declare @cCmd nvarchar(max),@cStep varchar(10),@cCurLocId VARCHAR(5),@cHoLocId VARCHAR(5),
			@cFilter VARCHAR(500),@cDelStr VARCHAR(200),@cDelJoinStr VARCHAR(500)

BEGIN TRY
		SELECT TOP 1 @CCURLOCID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
		SELECT TOP 1 @CHOLOCID=VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID' 
		
		DECLARE @bBuildRfopt BIT
		
		EXEC SP3S_CHKRFOPT_BUILD @bBuildRfopt OUTPUT
	
		IF @bBuildRfopt=0
			RETURN
		
		IF @cRfTableName=''	
			EXEC SP3S_RFDBTABLE 'GRNPS',@cXnID,@cRFTABLENAME OUTPUT 
		
		
		--Start of Build Process for Purchase Transaction
		SET @cFilter=(CASE WHEN @nUpdateMode  IN (0,4) THEN '1=1' ELSE 'a.MEMO_ID='''+@cXnID+'''' END)+@cWhereClause
	    IF @NUPDATEMODE IN (3)			
		BEGIN
			
			SET @cStep=20
			SET @CCMD=N'UPDATE a SET grnpsin_qty=a.grnpsin_qty-b.grnpsin_qty FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
					  B.MEMO_DT AS XN_DT,  
					   A.PRODUCT_CODE,
					   SUM(ABS(A.QUANTITY))  AS grnpsin_qty,
					   b.BIN_ID  AS [BIN_ID]
					   FROM GRN_PS_DET A  
					   JOIN GRN_PS_MST B ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+'  
					   WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
					   GROUP BY LEFT(B.MEMO_ID,2),B.MEMO_DT, A.PRODUCT_CODE,b.bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
		END
	
		If @nUpdateMode<>3
		BEGIN
		
			--Data Should only be inserted for the passed memo_id
			SET @CSTEP = 30
			SET @CCMD=N'UPDATE a SET grnpsin_qty=a.grnpsin_qty+b.grnpsin_qty FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(B.MEMO_ID,2) AS DEPT_ID,  
					  B.MEMO_DT AS XN_DT,  
					   A.PRODUCT_CODE,
					   SUM(ABS(A.QUANTITY))  AS grnpsin_qty,
					   b.BIN_ID  AS [BIN_ID]
					   FROM GRN_PS_DET A  
					   JOIN GRN_PS_MST B ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+'  
					   WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
					   GROUP BY LEFT(B.MEMO_ID,2),B.MEMO_DT, A.PRODUCT_CODE,b.bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
			
			SET @cStep=40			
			--Inserting Purchase/ChallanIn Data
			SET @CCMD=N'INSERT '+@cRFTABLEName+' 
						(DEPT_ID,XN_DT,PRODUCT_CODE,grnpsin_qty,BIN_ID)
					  
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.grnpsin_qty,xn.bin_id FROM 
					  (		
					     SELECT LEFT (b.MEMO_ID,2) AS DEPT_ID
							,B.MEMO_DT AS XN_DT
							,A.PRODUCT_CODE
							,SUM(A.QUANTITY) AS GRNPSIN_QTY
							,B.BIN_ID  AS [BIN_ID] 
						 FROM GRN_PS_DET A  
						 JOIN GRN_PS_MST B ON A.MEMO_ID = B.MEMO_ID '+@cInsJoinStr+'  
						 WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
						 GROUP BY LEFT(B.MEMO_ID,2),B.MEMO_DT, A.PRODUCT_CODE,b.bin_id
						 ) xn  
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL'
			PRINT @CCMD			  
			EXEC SP_EXECUTESQL @CCMD
			 
			
		END
	--End of Build Process for Purchase Transaction
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildGRNPS: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildGRNPS
/*
select * from jmloc3_rfopt..rf_opt where grnpsin_qty<>0


select cancelled, * from grn_ps_mst


select * from grn_ps_det

 SELECT LEFT (b.MEMO_ID,2) AS DEPT_ID
							,B.MEMO_DT AS XN_DT
							,A.PRODUCT_CODE
							,SUM(A.QUANTITY) AS GRNPSIN_QTY
							,B.BIN_ID  AS [BIN_ID] 
						 FROM GRN_PS_DET A  
						 JOIN GRN_PS_MST B ON A.MEMO_ID = B.MEMO_ID   
						 WHERE a.MEMO_ID='0201119000000200000001' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''
						 GROUP BY LEFT(B.MEMO_ID,2),B.MEMO_DT, A.PRODUCT_CODE,b.bin_id
						 
declare @cErrMsg varchar(max)
exec SP3SBuildGRNPS
 @cXnID='0201119000000200000002'
,@nUpdateMode=3
,@cRfTableName='jmloc3_rfopt..rf_opt'
,@cErrMsg=@cErrMsg output

select @cErrMsg

*/
