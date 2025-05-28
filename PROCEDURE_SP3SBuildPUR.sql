CREATE PROCEDURE SP3SBuildPUR
(
	 @cXnID			varchar(50)
	,@nUpdateMode	numeric(2)
    ,@cInsJoinStr   VARCHAR(1000)=''
	,@cWhereclause	VARCHAR(1000)=''
	,@nSpId			INT=0
	,@cRfTableName  varchar(500)=''
	,@cBuildXnType VARCHAR(10)=''
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
			EXEC SP3S_RFDBTABLE 'PUR',@cXnID,@cRFTABLENAME OUTPUT 
		
		--Start of Build Process for Purchase Transaction
		SET @cFilter=(CASE WHEN @nUpdateMode  IN (0,4) THEN '1=1' ELSE 'a.mrr_id='''+@cXnID+'''' END)+@cWhereClause
	   IF @NUPDATEMODE IN (3)
	   BEGIN
			
			SET @cStep=10
			
			SET @CCMD=N'UPDATE a SET pur_qty=a.pur_qty-b.pur_qty,chi_qty=a.chi_qty-b.chi_qty,
					  pur_taxable_value=a.pur_taxable_value-b.pur_taxable_value,
					  chi_taxable_value=a.chi_taxable_value-b.chi_taxable_value,
					  pur_tax_amount=a.pur_tax_amount-b.pur_tax_amount,
					  chi_tax_amount=a.chi_tax_amount-b.chi_tax_amount
					  FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT (CASE WHEN b.inv_mode=2 THEN LEFT(a.mrr_id,2) ELSE  B.DEPT_ID END) AS DEPT_ID,  
					  B.receipt_DT AS XN_DT,  
					   A.PRODUCT_CODE,
					   SUM(case when b.inv_mode=1 THEN A.QUANTITY ELSE 0 END)  AS pur_QTY,
					   SUM(case when b.inv_mode=1 THEN A.xn_value_without_gst ELSE 0 END)  AS pur_taxable_value,
					   SUM(case when b.inv_mode=1 THEN A.sgst_amount+a.cgst_amount+a.igst_amount ELSE 0 END)  AS pur_tax_amount,
					   SUM(case when b.inv_mode=2 THEN A.QUANTITY ELSE 0 END)  AS chi_QTY,
					   SUM(case when b.inv_mode=2 THEN A.xn_value_without_gst ELSE 0 END)  AS chi_taxable_value,
					   SUM(case when b.inv_mode=2 THEN A.sgst_amount+a.cgst_amount+a.igst_amount ELSE 0 END)  AS chi_tax_amount,
					   b.BIN_ID  AS [BIN_ID]
					 FROM PID01106 A  
					 JOIN PIM01106 B ON A.MRR_ID = B.MRR_ID '+@cInsJoinStr+'  
					 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id						 
					 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''LOCATION_ID'') LOC ON 1=1
					 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''HO_LOCATION_ID'') HO ON 1=1 
					 WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
					 AND ISNULL(b.xn_item_type,0) IN (0,1)
					 AND pim_ref.mrr_id IS NULL
					 AND (B.INV_MODE<>2 OR B.RECEIPT_DT<>'''')
					 GROUP BY (CASE WHEN b.inv_mode=2 THEN LEFT(a.mrr_id,2) ELSE  B.DEPT_ID END),
					 B.receipt_DT,A.PRODUCT_CODE,b.bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD

			IF @cCurLocId=@cHoLocId
			BEGIN
				SET @cStep=15
		
				SET @CCMD=N'UPDATE a SET git_qty=a.git_qty-b.git_qty
						  FROM '+REPLACE(@cRFTABLEName,'rf_opt','rf_opt_git')+' a
						  JOIN (	
						  SELECT B.DEPT_ID,  
						  B.receipt_DT AS XN_DT,  
						   A.PRODUCT_CODE,
						   SUM(A.QUANTITY)*-1 AS git_QTY,
						   b.BIN_ID  AS [BIN_ID]
						 FROM PID01106 A  
						 JOIN PIM01106 B ON A.MRR_ID = B.MRR_ID '+@cInsJoinStr+'  
						 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id						 
						 WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
						 AND ISNULL(b.xn_item_type,0) IN (0,1)
						 AND pim_ref.mrr_id IS NULL
						 AND B.INV_MODE=2 AND B.RECEIPT_DT<>''''
						 GROUP BY B.DEPT_ID,B.receipt_DT,A.PRODUCT_CODE,b.bin_id
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
				PRINT @CCMD 
				EXEC SP_EXECUTESQL @CCMD	
			END
			
			SET @cStep=20 
			SET @CCMD=N'UPDATE a SET grnpsout_qty=a.grnpsout_qty-b.grnpsout_qty
					  FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT B.DEPT_ID,  
					  B.receipt_DT AS XN_DT,  
					   A.PRODUCT_CODE,
					   SUM(A.QUANTITY)  AS grnpsout_QTY,
					   b.BIN_ID  AS [BIN_ID]
					 FROM PID01106 A  
					 JOIN PIM01106 B ON A.MRR_ID = B.MRR_ID '+@cInsJoinStr+'  
					 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id						 
					 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''LOCATION_ID'') LOC ON 1=1
					 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''HO_LOCATION_ID'') HO ON 1=1 
					 WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
					 AND ISNULL(b.xn_item_type,0) IN (0,1)
					 AND isnull(b.pim_mode,0)=6 AND B.RECEIPT_DT<>''''
					 GROUP BY B.DEPT_ID,B.receipt_DT,A.PRODUCT_CODE,b.bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD			
			
			
		END
	
		If @nUpdateMode<>3
		BEGIN
			--Data Should only be inserted for the passed memo_id
			SET @CSTEP = 22
			SET @CCMD=N'UPDATE a SET pur_qty=a.pur_qty+(CASE WHEN '''+@cBuildXnType+''' IN (''PUR'','''') THEN 
					  b.pur_qty ELSE 0 END),chi_qty=a.chi_qty+(CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') 
					  THEN b.chi_qty ELSE 0 END),
					  pur_taxable_value=a.pur_taxable_value+(CASE WHEN '''+@cBuildXnType+''' IN (''PUR'','''') 
					  THEN b.pur_taxable_value ELSE 0 END),
					  chi_taxable_value=a.chi_taxable_value+(CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') 
					  THEN b.chi_taxable_value ELSE 0 END),
					  pur_tax_amount=a.pur_tax_amount+(CASE WHEN '''+@cBuildXnType+''' IN (''PUR'','''') 
					  THEN b.pur_tax_amount ELSE 0 END),
					  chi_tax_amount=a.chi_tax_amount+(CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') 
					  THEN b.chi_tax_amount ELSE 0 END)
					  FROM '+@cRFTABLEName+' a  JOIN 
					  (	
					  SELECT (CASE WHEN b.inv_mode=2 THEN LEFT(a.mrr_id,2) ELSE  B.DEPT_ID END) AS DEPT_ID,  
					  B.receipt_DT AS XN_DT,A.PRODUCT_CODE,
					   SUM(case when b.inv_mode=1 THEN A.QUANTITY ELSE 0 END)  AS pur_QTY,
					   SUM(case when b.inv_mode=1 THEN A.xn_value_without_gst ELSE 0 END)  AS pur_taxable_value,
					   SUM(case when b.inv_mode=1 THEN A.sgst_amount+a.cgst_amount+a.igst_amount ELSE 0 END)  AS pur_tax_amount,
					   SUM(case when b.inv_mode=2 THEN A.QUANTITY ELSE 0 END)  AS chi_QTY,
					   SUM(case when b.inv_mode=2 THEN A.xn_value_without_gst ELSE 0 END)  AS chi_taxable_value,
					   SUM(case when b.inv_mode=2 THEN A.sgst_amount+a.cgst_amount+a.igst_amount ELSE 0 END)  AS chi_tax_amount,
					   b.BIN_ID  AS [BIN_ID]
					 FROM PID01106 A  
					 JOIN PIM01106 B ON A.MRR_ID = B.MRR_ID '+@cInsJoinStr+'  
					 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id						 
					 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''LOCATION_ID'') LOC ON 1=1
					 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''HO_LOCATION_ID'') HO ON 1=1 
					 WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
					 AND ISNULL(b.xn_item_type,0) IN (0,1)
					 AND pim_ref.mrr_id IS NULL
					 AND (B.INV_MODE<>2 OR B.RECEIPT_DT<>'''')
					 GROUP BY (CASE WHEN b.inv_mode=2 THEN LEFT(a.mrr_id,2) ELSE  B.DEPT_ID END),
					 B.receipt_DT,A.PRODUCT_CODE,b.bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
			
			IF @cCurLocId=@cHoLocId AND @cBuildXnType IN ('GIT','')
			BEGIN
				SET @CSTEP = 25
				SET @CCMD=N'UPDATE a SET git_qty=a.git_qty+b.git_qty
						  FROM '+REPLACE(@cRFTABLEName,'rf_opt','rf_opt_git')+' a
						  JOIN (	
						  SELECT B.DEPT_ID,  
						  B.receipt_DT AS XN_DT,  
						   A.PRODUCT_CODE,
						   SUM(A.QUANTITY)*-1 AS git_QTY,
						   b.BIN_ID  AS [BIN_ID]
						 FROM PID01106 A  
						 JOIN PIM01106 B ON A.MRR_ID = B.MRR_ID '+@cInsJoinStr+'  
						 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id						 
						 WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
						 AND ISNULL(b.xn_item_type,0) IN (0,1)
						 AND pim_ref.mrr_id IS NULL
						 AND B.INV_MODE=2 AND B.RECEIPT_DT<>''''
						 GROUP BY B.DEPT_ID,B.receipt_DT,A.PRODUCT_CODE,b.bin_id
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
				PRINT @CCMD 
				EXEC SP_EXECUTESQL @CCMD
			

				SET @cStep=30
				  --Inserting Purchase/ChallanIn Data
				SET @CCMD=N'INSERT '+REPLACE(@cRFTABLEName,'rf_opt','rf_opt_git')+' 
							(DEPT_ID,XN_DT,PRODUCT_CODE,git_qty,bin_id)
						  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.git_qty,xn.bin_id FROM 
						  (	
							   SELECT B.DEPT_ID AS DEPT_ID,
							   B.RECEIPT_DT AS XN_DT,A.PRODUCT_CODE,
							   SUM(A.QUANTITY)  AS git_QTY,
							   B.BIN_ID  AS [BIN_ID] 
							 FROM PID01106 A  
							 JOIN PIM01106 B ON A.MRR_ID = B.MRR_ID '+@cInsJoinStr+'  
							 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id						 
							 WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
							 AND ISNULL(b.xn_item_type,0) IN (0,1)
							 AND pim_ref.mrr_id IS NULL
							 AND B.INV_MODE=2 AND B.RECEIPT_DT<>''''
						   GROUP BY B.DEPT_ID,B.receipt_DT,A.PRODUCT_CODE,b.BIN_ID
						  ) xn  
						  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
						  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
						  WHERE b.product_code IS NULL'
							   
				 PRINT @CCMD			  
				 EXEC SP_EXECUTESQL @CCMD
			END
												
			SET @cStep=35
			  --Inserting Purchase/ChallanIn Data
			SET @CCMD=N'INSERT '+@cRFTABLEName+' 
						(DEPT_ID,XN_DT,PRODUCT_CODE,pur_qty,chi_qty,BIN_ID,pur_taxable_value,chi_taxable_value,
						 pur_tax_amount,chi_tax_amount)
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,
					  (CASE WHEN '''+@cBuildXnType+''' IN (''PUR'','''') THEN xn.pur_qty ELSE 0 END),
					  (CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') THEN xn.chi_qty ELSE 0 END),xn.bin_id,
					  (CASE WHEN '''+@cBuildXnType+''' IN (''PUR'','''') THEN xn.pur_taxable_value ELSE 0 END),
					  (CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') THEN xn.chi_taxable_value ELSE 0 END),
					  (CASE WHEN '''+@cBuildXnType+''' IN (''PUR'','''') THEN xn.pur_tax_amount ELSE 0 END),
					  (CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') THEN xn.chi_tax_amount ELSE 0 END) FROM 
					  (	
						   SELECT (CASE WHEN b.inv_mode=2 THEN LEFT(a.mrr_id,2) ELSE  B.DEPT_ID END) AS DEPT_ID,
						   B.RECEIPT_DT AS XN_DT,A.PRODUCT_CODE,
						   SUM(case when b.inv_mode=1 THEN A.QUANTITY ELSE 0 END)  AS pur_QTY,
						   SUM(case when b.inv_mode=1 THEN A.xn_value_without_gst ELSE 0 END)  AS pur_taxable_value,
						   SUM(case when b.inv_mode=1 THEN A.sgst_amount+a.cgst_amount+a.igst_amount ELSE 0 END)  AS pur_tax_amount,
						   SUM(case when b.inv_mode=2 THEN A.QUANTITY ELSE 0 END)  AS chi_QTY,
						   SUM(case when b.inv_mode=2 THEN A.xn_value_without_gst ELSE 0 END)  AS chi_taxable_value,
						   SUM(case when b.inv_mode=2 THEN A.sgst_amount+a.cgst_amount+a.igst_amount ELSE 0 END)  AS chi_tax_amount,
						   SUM(CASE WHEN LOC.VALUE=HO.VALUE AND b.inv_mode=2 THEN A.QUANTITY ELSE 0 END)  AS tro_QTY
						   ,B.BIN_ID  AS [BIN_ID] 
						 FROM PID01106 A  
						 JOIN PIM01106 B ON A.MRR_ID = B.MRR_ID '+@cInsJoinStr+'  
						 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id						 
						 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''LOCATION_ID'') LOC ON 1=1
						 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''HO_LOCATION_ID'') HO ON 1=1 
						 WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
						 AND ISNULL(b.xn_item_type,0) IN (0,1)
						 AND pim_ref.mrr_id IS NULL
						 AND (B.INV_MODE<>2 OR B.RECEIPT_DT<>'''')
					   GROUP BY (CASE WHEN b.inv_mode=2 THEN LEFT(a.mrr_id,2) ELSE  B.DEPT_ID END),
					   B.receipt_DT,A.PRODUCT_CODE,b.BIN_ID
					  ) xn  
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL'
						   
			 PRINT @CCMD			  
			 EXEC SP_EXECUTESQL @CCMD
			
			IF @cBuildXnType IN ('GRNPSIN','')
			BEGIN
				SET @cStep=40 
				SET @CCMD=N'UPDATE a SET grnpsout_qty=a.grnpsout_qty+b.grnpsout_qty
						  FROM '+@cRFTABLEName+' a
						  JOIN (	
						  SELECT b.dept_id,  
						  B.receipt_DT AS XN_DT,  
						   A.PRODUCT_CODE,
						   SUM(A.QUANTITY)  AS grnpsout_QTY,
						   b.BIN_ID  AS [BIN_ID]
						 FROM PID01106 A  
						 JOIN PIM01106 B ON A.MRR_ID = B.MRR_ID '+@cInsJoinStr+'  
						 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id						 
						 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''LOCATION_ID'') LOC ON 1=1
						 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''HO_LOCATION_ID'') HO ON 1=1 
						 WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
						 AND ISNULL(b.xn_item_type,0) IN (0,1)
						 AND isnull(b.pim_mode,0)=6 AND B.RECEIPT_DT<>''''
						 GROUP BY B.DEPT_ID,B.receipt_DT,A.PRODUCT_CODE,b.bin_id
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
				PRINT @CCMD 
				EXEC SP_EXECUTESQL @CCMD
				 
				SET @cStep=50 
				SET @CCMD=N'INSERT '+@cRFTABLEName+' 
							(DEPT_ID,XN_DT,PRODUCT_CODE,grnpsout_QTY,BIN_ID)
						  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.grnpsout_QTY,xn.bin_id FROM 
						  (	
							   SELECT B.DEPT_ID
								,B.RECEIPT_DT AS XN_DT
								,A.PRODUCT_CODE
								,SUM(A.QUANTITY) AS grnpsout_QTY
								,B.BIN_ID  AS [BIN_ID] 
							 FROM PID01106 A  
							 JOIN PIM01106 B ON A.MRR_ID = B.MRR_ID '+@cInsJoinStr+'  						 
							 WHERE '+@cFilter+' AND  B.CANCELLED = 0  AND A.PRODUCT_CODE<>''''
							 AND ISNULL(b.xn_item_type,0) IN (0,1)
							 AND isnull(b.pim_mode,0)=6 AND B.RECEIPT_DT<>''''
						  GROUP BY B.DEPT_ID,B.RECEIPT_DT,A.PRODUCT_CODE,b.BIN_ID
						  ) xn  
						  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
						  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
						  WHERE b.product_code IS NULL'
				 PRINT @CCMD			  
				 EXEC SP_EXECUTESQL @CCMD
			 END			
		END
	--End of Build Process for Purchase Transaction
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildPUR: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildPUR
/*
declare @cErrMsg varchar(max)
EXEC SP3SBuildPUR
 @cXnID	=''
,@nUpdateMode=2
,@cRfTableName='jmloc3_rfopt..rf_opt'
,@cErrMsg=@cErrMsg output

select @cErrMsg

)
*/
