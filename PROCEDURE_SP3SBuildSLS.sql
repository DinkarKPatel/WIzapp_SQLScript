CREATE PROCEDURE SP3SBuildSLS
(
	 @cXnID			varchar(50)
	,@nUpdateMode	numeric(2)
    ,@cInsJoinStr	VARCHAR(1000)=''
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
		EXEC SP3S_RFDBTABLE 'SLS',@cXnID,@cRFTABLENAME OUTPUT 
		

	SET @cFilter=(CASE WHEN @nUpdatemode=4 THEN '1=1' ELSE ' B.CM_ID='''+@cXnID+'''' END)+@cWhereClause
	
	--Start of Build Process for Retail Sale Transaction
	   IF @NUPDATEMODE IN (3)
	   BEGIN
			SET @cStep=10
			SET @CCMD=N'UPDATE a SET sls_qty=a.sls_qty-b.sls_qty,slr_qty=a.slr_qty-b.slr_qty ,
						sls_taxable_value=a.sls_taxable_value-b.sls_taxable_value,
						slr_taxable_value=a.slr_taxable_value-b.slr_taxable_value,
						sls_tax_amount=a.sls_tax_amount-b.sls_tax_amount,
						slr_tax_amount=a.slr_tax_amount-b.slr_tax_amount,
						SLS_NET_AMT=a.SLS_NET_AMT-b.SLS_NET_AMT
						FROM '+@cRFTABLEName+' a
						  JOIN (	
						  SELECT LEFT(B.CM_ID,2) AS DEPT_ID,  
						  B.CM_DT AS XN_DT,  
						   A.PRODUCT_CODE,
						   SUM(CASE WHEN a.quantity>0 THEN A.QUANTITY ELSE 0 END)  AS sls_QTY,
						   SUM(CASE WHEN a.quantity<0 THEN ABS(A.QUANTITY) ELSE 0 END)  AS slr_QTY,
						   SUM(case when quantity>0 THEN A.xn_value_without_gst ELSE 0 END)  AS sls_taxable_value,						   
						   SUM(case when quantity>0 THEN A.sgst_amount+a.cgst_amount+a.igst_amount ELSE 0 END)  AS sls_tax_amount,						   
						   SUM(case when quantity<0 THEN ABS(A.xn_value_without_gst) ELSE 0 END)  AS slr_taxable_value,						   
						   SUM(case when quantity<0 THEN ABS(A.sgst_amount+a.cgst_amount+a.igst_amount) ELSE 0 END)  AS slr_tax_amount,						   						   						   
						   SUM(A.xn_value_without_gst+A.sgst_amount+a.cgst_amount+a.igst_amount) as sls_net_amt,
						   A.BIN_ID  AS [BIN_ID]
						   FROM CMD01106 A 
						   JOIN CMM01106 B ON A.CM_ID = B.CM_ID '+@CINSJOINSTR+' 
						   WHERE B.CANCELLED = 0 AND ISNULL(B.xn_item_type,0) in (0,1)  AND '+@CFILTER+'
						   GROUP BY LEFT(B.cM_ID,2),B.cm_DT, A.PRODUCT_CODE,a.bin_id
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			 PRINT @CCMD 
			 EXEC SP_EXECUTESQL @CCMD
					
		END

	
		IF @nUpdateMode<>3
		BEGIN
			SET @cStep=20

			SET @CCMD=N'UPDATE a SET sls_qty=a.sls_qty+b.sls_qty,slr_qty=a.slr_qty+b.slr_qty,
						sls_taxable_value=a.sls_taxable_value+b.sls_taxable_value,
						slr_taxable_value=a.slr_taxable_value+b.slr_taxable_value,
						sls_tax_amount=a.sls_tax_amount+b.sls_tax_amount,
						slr_tax_amount=a.slr_tax_amount+b.slr_tax_amount,
						SLS_NET_AMT=a.SLS_NET_AMT+b.SLS_NET_AMT			 
						FROM '+@cRFTABLEName+' a
						  JOIN (	
						  SELECT LEFT(B.CM_ID,2) AS DEPT_ID,  
						  B.CM_DT AS XN_DT,  
						   A.PRODUCT_CODE,
						   SUM(CASE WHEN a.quantity>0 THEN A.QUANTITY ELSE 0 END)  AS sls_QTY,
						   SUM(CASE WHEN a.quantity<0 THEN ABS(A.QUANTITY) ELSE 0 END)  AS slr_QTY,
						   SUM(case when quantity>0 THEN A.xn_value_without_gst ELSE 0 END)  AS sls_taxable_value,						   
						   SUM(case when quantity>0 THEN A.sgst_amount+a.cgst_amount+a.igst_amount ELSE 0 END)  AS sls_tax_amount,						   
						   SUM(case when quantity<0 THEN ABS(A.xn_value_without_gst) ELSE 0 END)  AS slr_taxable_value,						   
						   SUM(case when quantity<0 THEN ABS(A.sgst_amount+a.cgst_amount+a.igst_amount) ELSE 0 END)  AS slr_tax_amount,						
						   SUM(A.xn_value_without_gst+A.sgst_amount+a.cgst_amount+a.igst_amount) as sls_net_amt,   						   
						   A.BIN_ID  AS [BIN_ID]
						   FROM CMD01106 A 
						   JOIN CMM01106 B ON A.CM_ID = B.CM_ID '+@CINSJOINSTR+' 
						   WHERE B.CANCELLED = 0 AND ISNULL(B.xn_item_type,0) in (0,1)  AND '+@CFILTER+'
						   GROUP BY LEFT(B.cM_ID,2),B.cm_DT, A.PRODUCT_CODE,a.bin_id
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			 PRINT @CCMD 
			 EXEC SP_EXECUTESQL @CCMD
			
			SET @cStep=30 			
			SET @CCMD=N'INSERT '+@cRFTABLEName+' 
						(DEPT_ID,XN_DT,PRODUCT_CODE,sls_qty,slr_qty,BIN_ID,sls_taxable_value,slr_taxable_value,
						sls_tax_amount,slr_tax_amount,SLS_NET_AMT)
					  
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.sls_qty,xn.slr_qty,xn.bin_id,
					  xn.sls_taxable_value,xn.slr_taxable_value,xn.sls_tax_amount,xn.slr_tax_amount,xn.SLS_NET_AMT
					  FROM 
					  (	 SELECT LEFT(B.CM_ID,2) AS DEPT_ID,  
					   B.CM_DT AS XN_DT,  
					   A.PRODUCT_CODE,  
					   SUM(CASE WHEN a.quantity>0 THEN A.QUANTITY ELSE 0 END)  AS sls_QTY,
					   SUM(CASE WHEN a.quantity<0 THEN ABS(A.QUANTITY) ELSE 0 END)  AS slr_QTY,
					   SUM(case when quantity>0 THEN A.xn_value_without_gst ELSE 0 END)  AS sls_taxable_value,						   
					   SUM(case when quantity>0 THEN A.sgst_amount+a.cgst_amount+a.igst_amount ELSE 0 END)  AS sls_tax_amount,						   
					   SUM(case when quantity<0 THEN ABS(A.xn_value_without_gst) ELSE 0 END)  AS slr_taxable_value,						   
					   SUM(case when quantity<0 THEN ABS(A.sgst_amount+a.cgst_amount+a.igst_amount) ELSE 0 END)  AS slr_tax_amount,						   						   
					   SUM(A.xn_value_without_gst+A.sgst_amount+a.cgst_amount+a.igst_amount) as sls_net_amt,   						   
					   A.BIN_ID  AS [BIN_ID]
					   FROM CMD01106 A 
					   JOIN CMM01106 B ON A.CM_ID = B.CM_ID '+@CINSJOINSTR+' 
					   WHERE B.CANCELLED = 0 AND ISNULL(B.xn_item_type,0) in (0,1)  AND '+@CFILTER+'
					   GROUP BY LEFT(B.CM_ID,2),B.CM_DT,A.PRODUCT_CODE,A.BIN_ID
					  ) xn  
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL'
					   
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
		END
	--End of Build Process for Retail Sale Transaction
	
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildSLS: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildSLS
/*
declare @cErrMsg varchar(max)
exec SP3SBuildSLS
	 @cXnID=''
	,@nUpdateMode=3
	,@cRfTableName='jmho_rfopt..rf_opt'
	,@cErrMsg=@cErrMsg output
select @cErrMsg
	
*/
