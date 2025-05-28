CREATE PROCEDURE SP3SBuildPRT
(
	 @cXnID			varchar(50)
	,@nUpdateMode	numeric(2)
    ,@cInsJoinStr   VARCHAR(1000)=''
	,@cWhereclause	VARCHAR(1000)=''
	,@cRfTableName  varchar(500)=''
	,@cBuildXnType VARCHAR(100)=''
	,@cErrMsg		VARCHAR(MAX) output
)
AS

BEGIN
/*
XnType Filter is required during deletion from RFOPT Table because in some cases like TRO From PIM01106
,the inserted xn_id is that of wholesale invoice.
*/
	Declare @cCmd nvarchar(max),@cStep varchar(10),@cFilter VARCHAR(500),
			@cCurLocId VARCHAR(5),@cHoLocId VARCHAR(5),@cChiFilter VARCHAR(500),@cDelstr VARCHAR(100),@cDelJoinStr VARCHAR(1000)
	
BEGIN TRY

	

	DECLARE @bBuildRfopt BIT
	
	
	EXEC SP3S_CHKRFOPT_BUILD @bBuildRfopt OUTPUT
	
	IF @bBuildRfopt=0
		RETURN
		
	IF @cRfTableName=''
		EXEC SP3S_RFDBTABLE 'PRT',@cXnID,@cRFTABLENAME OUTPUT 	
			
	SELECT TOP 1 @CCURLOCID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
	SELECT TOP 1 @CHOLOCID=VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID' 

	SET @cFilter=(CASE WHEN @nUpdateMode IN (0,4) THEN '1=1' ELSE 'a.rm_id='''+@cXnID+'''' END)+@cWhereClause

	--Start of Build Process for DebitNote Transaction
    IF @NUPDATEMODE IN (3)
	BEGIN
		SET @cStep=10
		SET @CCMD=N'UPDATE a SET cho_qty=a.cho_qty-b.cho_qty,
					  cho_taxable_value=a.cho_taxable_value-b.cho_taxable_value,
					  cho_tax_amount=a.cho_tax_amount-b.cho_tax_amount FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(b.rm_id,2) AS DEPT_ID,  
					  B.rM_DT AS XN_DT, A.PRODUCT_CODE,
					  SUM(A.QUANTITY) AS cho_QTY,
		  			  SUM(A.xn_value_without_gst)  AS cho_taxable_value,
					  SUM(A.sgst_amount+a.cgst_amount+a.igst_amount)  AS cho_tax_amount,
					  a.bin_id AS [BIN_ID]
					  FROM RMD01106 A (NOLOCK)
					  JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
					  JOIN LOCATION D (NOLOCK) ON D.DEPT_ID=B.PARTY_DEPT_ID 
					  JOIN LOCATION e (NOLOCK) ON e.DEPT_ID=left(B.rm_id,2)'+@cInsJoinStr+'
					  WHERE '+@cFilter+@cChiFilter+' AND B.CANCELLED = 0 AND B.MODE=2 AND B.DN_TYPE IN (0,1)
					  AND ISNULL(b.xn_item_type,0) IN (0,1)
					   GROUP BY LEFT(b.rm_id,2),B.rM_DT, A.PRODUCT_CODE,a.bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
		  PRINT @CCMD 
		  EXEC SP_EXECUTESQL @CCMD
		
		IF @cCurLocId=@cHoLocId
		BEGIN
			SET @cStep=15
			SET @CCMD=N'UPDATE a SET git_qty=a.git_qty-b.git_qty
						  FROM '+REPLACE(@cRFTABLEName,'rf_opt','rf_opt_git')+' a
						  JOIN (	
						  SELECT B.PARTY_DEPT_ID AS DEPT_ID,  
						  B.rM_DT AS XN_DT, A.PRODUCT_CODE,
						  SUM(A.QUANTITY) AS git_QTY,
						  B.TARGET_BIN_ID AS [BIN_ID]
						  FROM RMD01106 A (NOLOCK)
						  JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
						  JOIN LOCATION D (NOLOCK) ON D.DEPT_ID=B.PARTY_DEPT_ID 
						  JOIN LOCATION e (NOLOCK) ON e.DEPT_ID=left(B.rm_id,2)'+@cInsJoinStr+' 
						  WHERE '+@cFilter+@cChiFilter+' AND B.CANCELLED = 0 AND B.MODE=2 AND B.DN_TYPE IN (0,1)
						  AND ISNULL(e.sis_loc,0)=0
						  AND ISNULL(b.xn_item_type,0) IN (0,1)
						  GROUP BY B.PARTY_DEPT_ID,
						   B.rM_DT, A.PRODUCT_CODE,B.TARGET_BIN_ID
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			  PRINT @CCMD 
			  EXEC SP_EXECUTESQL @CCMD
		 END
		  					
		 print 'Check exp for rmm'		  
		 SET @cStep=20
		  SET @CCMD=N'UPDATE a SET prt_qty=a.prt_qty-b.prt_qty,prt_taxable_value=a.prt_taxable_value-b.prt_taxable_value,
					  prt_tax_amount=a.prt_tax_amount-b.prt_tax_amount FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(B.RM_ID,2) AS DEPT_ID,  
					  B.rM_DT AS XN_DT,  
					  A.PRODUCT_CODE,
					  SUM(A.QUANTITY) AS prt_QTY,
					  SUM(A.xn_value_without_gst)  AS prt_taxable_value,
					  SUM(A.sgst_amount+a.cgst_amount+a.igst_amount)  AS prt_tax_amount,					  
					  a.bin_id AS [BIN_ID]
					  FROM RMD01106 A (NOLOCK)
					  JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID '+@cInsJoinStr+'
					  WHERE '+@cFilter+' AND B.CANCELLED = 0 AND B.MODE=1 AND B.DN_TYPE IN (0,1)
					  AND ISNULL(b.xn_item_type,0) IN (0,1)
					   GROUP BY LEFT(b.rm_id,2),B.rM_DT, A.PRODUCT_CODE,a.bin_id 
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
					   	 
		  PRINT @CCMD 
		  EXEC SP_EXECUTESQL @CCMD

		 SET @CSTEP = 30
		 SET @CCMD=N'UPDATE a SET dnpr_qty=a.dnpr_qty-b.dnpr_qty FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(B.RM_ID,2) AS DEPT_ID,  
					  B.rM_DT AS XN_DT,  
					  A.PRODUCT_CODE,
					  SUM(A.QUANTITY) AS dnpr_qty,
					  a.bin_id AS [BIN_ID]
					  FROM RMD01106 A (NOLOCK)
					  JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
					  JOIN DNPS_MST c ON c.ps_id=a.ps_id'+@cInsJoinStr+' 
	  				  WHERE '+@cFilter+' AND ISNULL(B.xn_item_type,0) in (0,1)  AND B.CANCELLED = 0 
	  				  AND ISNULL(A.PS_ID,'''')<>''''
					  GROUP BY LEFT(b.rm_id,2),B.rM_DT, A.PRODUCT_CODE,a.bin_id 
					  ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'

		 PRINT ISNULL(@CCMD,'null cho expr for prt')
		 EXEC SP_EXECUTESQL @CCMD	
			     
	END
	
	IF @nUpdateMode<>3
	BEGIN
		IF @cBuildXnType IN ('CHO','')
		BEGIN
			SET @CSTEP = 40
			SET @CCMD=N'UPDATE a SET cho_qty=a.cho_qty+b.cho_qty,
						  cho_taxable_value=a.cho_taxable_value+b.cho_taxable_value,
						  cho_tax_amount=a.cho_tax_amount+b.cho_tax_amount FROM '+@cRFTABLEName+' a
						  JOIN (	
						  SELECT LEFT(b.rm_id,2) AS DEPT_ID,  
						  B.rM_DT AS XN_DT,  
						  A.PRODUCT_CODE,
						  SUM(A.QUANTITY) AS cho_QTY,
						  SUM(A.xn_value_without_gst)  AS cho_taxable_value,
						  SUM(A.sgst_amount+a.cgst_amount+a.igst_amount)  AS cho_tax_amount,						  
						  a.bin_id AS [BIN_ID]
						  FROM RMD01106 A (NOLOCK)
						  JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
						  JOIN LOCATION D (NOLOCK) ON D.DEPT_ID=B.PARTY_DEPT_ID 
						  JOIN LOCATION e (NOLOCK) ON e.DEPT_ID=left(B.rm_id,2)'+@cInsJoinStr+'
						  WHERE '+@cFilter+@cChiFilter+' AND B.CANCELLED = 0 AND B.MODE=2 AND B.DN_TYPE IN (0,1)
						  AND ISNULL(b.xn_item_type,0) IN (0,1)
						   GROUP BY LEFT(b.rm_id,2) , B.rM_DT, A.PRODUCT_CODE,a.bin_id  
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD		
			
			SET @CSTEP = 50
			SET @CCMD=N'INSERT '+@cRFTABLEName+' 
							(DEPT_ID,XN_DT,PRODUCT_CODE,cho_qty,cho_taxable_value,cho_tax_amount,BIN_ID)
						  
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.cho_qty,xn.cho_taxable_value,
					  xn.cho_tax_amount,xn.bin_id FROM 
						(	
					  SELECT LEFT(b.rm_id,2) AS DEPT_ID,  
					  B.rm_DT AS XN_DT,  
					  A.PRODUCT_CODE,   
					  SUM(A.QUANTITY) AS cho_QTY,
					  SUM(A.xn_value_without_gst)  AS cho_taxable_value,
					  SUM(A.sgst_amount+a.cgst_amount+a.igst_amount)  AS cho_tax_amount,					  
					  a.bin_id  AS [BIN_ID]
					  FROM RMD01106 A
					  JOIN RMM01106 B  ON A.RM_ID = B.RM_ID  
					  JOIN LOCATION D ON D.DEPT_ID=B.PARTY_DEPT_ID 
					  JOIN LOCATION e ON e.DEPT_ID=left(B.rm_id,2)'+@cInsJoinStr+'
					  WHERE '+@cFilter+@cChiFilter+' AND B.CANCELLED = 0 AND B.MODE=2 AND B.DN_TYPE IN (0,1)
					  AND ISNULL(b.xn_item_type,0) IN (0,1)
					  GROUP BY LEFT(b.rm_id,2),B.rM_DT, A.PRODUCT_CODE,a.bin_id 
					  )	 xn  
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL' 
					  
			 print 'Check exp for rmm'		  
			 PRINT ISNULL(@CCMD,'null tri expr for prt')
			 EXEC SP_EXECUTESQL @CCMD
		END
				
		IF @cCurLocId=@cHoLocId AND @cBuildXnType IN ('GIT','') 
		BEGIN

			SET @cStep=55
			SET @CCMD=N'UPDATE a SET git_qty=a.git_qty+b.git_qty
						  FROM '+REPLACE(@cRFTABLEName,'rf_opt','rf_opt_git')+' a
						  JOIN (	
						  SELECT B.PARTY_DEPT_ID AS DEPT_ID,  
						  B.rM_DT AS XN_DT, A.PRODUCT_CODE,
						  SUM(A.QUANTITY) AS git_QTY,
						  B.TARGET_BIN_ID AS [BIN_ID]
						  FROM RMD01106 A (NOLOCK)
						  JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
						  JOIN LOCATION D (NOLOCK) ON D.DEPT_ID=B.PARTY_DEPT_ID 
						  JOIN LOCATION e (NOLOCK) ON e.DEPT_ID=left(B.rm_id,2)'+@cInsJoinStr+' 
						  WHERE '+@cFilter+@cChiFilter+' AND B.CANCELLED = 0 AND B.MODE=2 AND B.DN_TYPE IN (0,1)
						  AND ISNULL(e.sis_loc,0)=0
						  AND ISNULL(b.xn_item_type,0) IN (0,1)
						  GROUP BY B.PARTY_DEPT_ID,
						   B.rM_DT, A.PRODUCT_CODE,B.TARGET_BIN_ID
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
				  				
			SET @CSTEP = 60
			SET @CCMD=N'INSERT '+@cRFTABLEName+' 
						(DEPT_ID,XN_DT,PRODUCT_CODE,git_qty,BIN_ID)
						  
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.git_qty,xn.bin_id FROM 
						(	
					 SELECT B.PARTY_DEPT_ID AS DEPT_ID,  
							  B.rM_DT AS XN_DT, A.PRODUCT_CODE,
							  SUM(A.QUANTITY) AS git_QTY,
							  B.TARGET_BIN_ID AS [BIN_ID]
							  FROM RMD01106 A (NOLOCK)
							  JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
							  JOIN LOCATION D (NOLOCK) ON D.DEPT_ID=B.PARTY_DEPT_ID 
							  JOIN LOCATION e (NOLOCK) ON e.DEPT_ID=left(B.rm_id,2)'+@cInsJoinStr+' 
							  WHERE '+@cFilter+@cChiFilter+' AND B.CANCELLED = 0 AND B.MODE=2 AND B.DN_TYPE IN (0,1)
							  AND ISNULL(e.sis_loc,0)=0
							  AND ISNULL(b.xn_item_type,0) IN (0,1)
							  GROUP BY B.PARTY_DEPT_ID,
							   B.rM_DT, A.PRODUCT_CODE,B.TARGET_BIN_ID 
					  )	 xn  
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL' 
					  
			 print 'Check exp for rmm'		  
			 PRINT ISNULL(@CCMD,'null tri expr for prt')
			 EXEC SP_EXECUTESQL @CCMD
		 END
		 
		 IF @cBuildXnType IN ('PRT','') 			
		 BEGIN
			 SET @CSTEP = 65	
			 SET @CCMD=N'UPDATE a SET prt_qty=a.prt_qty+b.prt_qty,prt_taxable_value=a.prt_taxable_value+b.prt_taxable_value,
						  prt_tax_amount=a.prt_tax_amount+b.prt_tax_amount FROM '+@cRFTABLEName+' a
						  JOIN (	
						  SELECT LEFT(b.rm_id,2) AS DEPT_ID,  
						  B.rM_DT AS XN_DT,  
						  A.PRODUCT_CODE,
						  SUM(A.QUANTITY) AS prt_qty,
						  SUM(A.xn_value_without_gst)  AS prt_taxable_value,
						  SUM(A.sgst_amount+a.cgst_amount+a.igst_amount)  AS prt_tax_amount,					  
						  a.bin_id  AS [BIN_ID]
						  FROM RMD01106 A (NOLOCK)
						  JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  '+@cInsJoinStr+'
						  WHERE '+@cFilter+' AND B.CANCELLED = 0 AND B.MODE=1 AND B.DN_TYPE IN (0,1)
						  AND ISNULL(b.xn_item_type,0) IN (0,1)
						   GROUP BY LEFT(b.rm_id,2),B.rM_DT, A.PRODUCT_CODE,a.bin_id
						   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			 PRINT @CCMD 
			 EXEC SP_EXECUTESQL @CCMD		
					 
			 SET @CSTEP = 70
			 SET @CCMD=N'INSERT '+@cRFTABLEName+' 
							(DEPT_ID,XN_DT,PRODUCT_CODE,prt_qty,prt_taxable_value,prt_tax_amount,BIN_ID)
						 
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.PRT_qty,xn.prt_taxable_value,xn.prt_tax_amount,xn.bin_id FROM 
						(	
					  SELECT LEFT(B.RM_ID,2) AS DEPT_ID,  
					   B.RM_DT AS XN_DT,  
					   A.PRODUCT_CODE,  
					   SUM(A.QUANTITY)  AS prt_QTY,  
					   SUM(A.xn_value_without_gst)  AS prt_taxable_value,
					   SUM(A.sgst_amount+a.cgst_amount+a.igst_amount)  AS prt_tax_amount,				   
					   A.BIN_ID  AS [BIN_ID] 
					   FROM RMD01106 A 
					   JOIN RMM01106 B ON A.RM_ID = B.RM_ID'+@cInsJoinStr+' 
					   WHERE '+@cFilter+' AND B.CANCELLED = 0 AND B.DN_TYPE IN (0,1) AND b.mode=1
					   AND ISNULL(b.xn_item_type,0) IN (0,1)
					   GROUP BY LEFT(B.RM_ID,2),B.RM_DT,A.PRODUCT_CODE,A.BIN_ID
					   ) xn  
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL'
					  
			 PRINT ISNULL(@CCMD,'null cho expr for prt')
			 EXEC SP_EXECUTESQL @CCMD


			 SET @CSTEP = 80
			 SET @CCMD=N'UPDATE a SET dnpr_qty=a.dnpr_qty+b.dnpr_qty FROM '+@cRFTABLEName+' a
						  JOIN (	
						  SELECT LEFT(B.RM_ID,2) AS DEPT_ID,  
						  B.rM_DT AS XN_DT,  
						  A.PRODUCT_CODE,
						  SUM(A.QUANTITY) AS dnpr_qty,
						  a.bin_id AS [BIN_ID]
						  FROM RMD01106 A (NOLOCK)
						  JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID  
						  JOIN DNPS_MST c ON c.ps_id=a.ps_id'+@cInsJoinStr+' 
	  					  WHERE '+@cFilter+' AND ISNULL(B.xn_item_type,0) in (0,1)  AND B.CANCELLED = 0 
	  					  AND ISNULL(A.PS_ID,'''')<>''''
						  GROUP BY LEFT(b.rm_id,2),B.rM_DT, A.PRODUCT_CODE,a.bin_id 
						  ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'

			 PRINT ISNULL(@CCMD,'null cho expr for dnpr')
			 EXEC SP_EXECUTESQL @CCMD
			 
			 SET @CSTEP = 90 
			 SET @CCMD=N'INSERT '+@cRFTABLEName+' 
							(DEPT_ID,XN_DT,PRODUCT_CODE,DNPR_QTY,BIN_ID)
						 
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.DNPR_QTY,xn.bin_id FROM 
						(	
					  SELECT LEFT(B.RM_ID,2) AS DEPT_ID,  
					   B.RM_DT AS XN_DT,  
					   A.PRODUCT_CODE,  
					   SUM(A.QUANTITY)  AS DNPR_QTY,  
					   A.BIN_ID  AS [BIN_ID]
					   FROM RMD01106 A 
					   JOIN RMM01106 B ON A.RM_ID = B.RM_ID
					   JOIN DNPS_MST c ON c.ps_id=a.ps_id'+@cInsJoinStr+' 
					   WHERE '+@cFilter+' AND ISNULL(B.xn_item_type,0) in (0,1)  AND B.CANCELLED = 0
					   AND ISNULL(A.PS_ID,'''')<>''''
					   GROUP BY LEFT(b.rm_id,2),B.rM_DT, A.PRODUCT_CODE,a.bin_id 
					  ) xn
					   
					  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					  WHERE b.product_code IS NULL'
			 PRINT ISNULL(@CCMD,'null cho expr for prt')
			 EXEC SP_EXECUTESQL @CCMD		 
		 END
	 END
	--End of Build Process for DebitNote Transaction
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildPRT: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildPRT
/*

update jmloc3..rmm01106 set cancelled=0 where rm_id='020111902DN-000014'
select * from jmloc3..rmd01106 where rm_id='020111902DN-000014'

select xn_item_type,dn_type,cancelled,mode,* from jmloc3..rmm01106 where rm_id='020111902DN-000014'

select last_update as lupd,rm_id, * from jmloc3..rmm01106 where cancelled=1 order by last_update desc

declare @cErrMsg VARCHAR(MAX)
exec SP3SBuildPRT
	 @cXnID='020111902DN-000014'
	,@nUpdateMode=3
	,@cRfTableName='jmloc3_rfopt..rf_opt'
	,@cErrMsg=@cErrMsg output
	
select @cErrMsg

*/
