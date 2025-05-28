CREATE PROCEDURE SP3SBuildCNC
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
		EXEC SP3S_RFDBTABLE 'CNC',@cXnID,@cRFTABLENAME OUTPUT 
		
	SET @cFilter=(CASE WHEN @nUpdateMode IN (0,4) THEN ' AND 1=1' ELSE ' AND b.cnc_MEMO_ID='''+@cXnID+'''' END)+@cWhereClause				   

	--Start of Build Process for Cancellation Transaction
	IF @nUpdateMode<>1
	BEGIN
	   SET @CSTEP =  250
	   IF @NUPDATEMODE IN (3)	  
	   BEGIN

			SET @CCMD=N'UPDATE a SET cnc_qty=a.cnc_qty-b.cnc_qty,unc_qty=a.unc_qty-b.unc_qty,
					  sac_net=a.sac_net-b.sac_net,sacm_net=a.sacm_net-b.sacm_net
					  FROM '+@cRFTABLEName+' a
					  JOIN (	
					  SELECT LEFT(B.CNC_MEMO_ID,2) AS DEPT_ID,  
					  B.CNC_MEMO_DT AS XN_DT,  
					   A.PRODUCT_CODE,
					   SUM(CASE WHEN B.STOCK_ADJ_NOTE=0 AND CNC_TYPE=1 THEN quantity ELSE 0 END) AS cnc_qty,
					   SUM(CASE WHEN B.STOCK_ADJ_NOTE=0 AND CNC_TYPE=2 THEN quantity ELSE 0 END) AS unc_qty, 
					   SUM(CASE WHEN B.STOCK_ADJ_NOTE=1 AND ISNULL(b.stock_adj_type,0) IN (0,1) THEN
							( CASE WHEN cnc_type=1 THEN a.rate ELSE -a.rate END) ELSE 0 END) AS sac_net, 
				       SUM(CASE WHEN B.STOCK_ADJ_NOTE=1 AND ISNULL(b.stock_adj_type,0)=2 THEN
						 ( CASE WHEN cnc_type=1 THEN a.rate ELSE -a.rate END) ELSE 0 END) AS sacm_net,
					   A.BIN_ID  AS [BIN_ID]
					   FROM ICD01106 A (NOLOCK)  
					   JOIN ICM01106 B (NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID
					   join sku c (nolock) on c.product_code=a.product_code
					   join article d (nolock) on d.article_code=c.article_code'+@cInsJoinStr+'  
					   JOIN sectiond sd (NOLOCK) ON sd.sub_Section_code=d.sub_section_code
					   JOIN sectionm sm (NOLOCK) ON sm.section_code=sd.section_code
					   WHERE ISNULL(B.xn_item_type,0) in (0,1) '+@cFilter+'
					   GROUP BY LEFT(B.CNC_MEMO_ID,2),B.CNC_MEMO_DT, A.PRODUCT_CODE,a.bin_id
					   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
			PRINT @CCMD 
			EXEC SP_EXECUTESQL @CCMD
		
	  END	   
	   
	   
	END
	
	IF @nUpdateMode<>3
	BEGIN
		---DEPT_ID COLUMN TAKEN BECAUSE OF CANCELLATION MEMO GENERATED AT HO ON BEHALF OF LOCATION (JASHN)
	   SET @CSTEP =  260

	   SET @CCMD=N'UPDATE a SET cnc_qty=a.cnc_qty+b.cnc_qty,unc_qty=a.unc_qty+b.unc_qty,
				  sac_net=a.sac_net+b.sac_net,sacm_net=a.sacm_net+b.sacm_net
				  FROM '+@cRFTABLEName+' a
				  JOIN (	
				  SELECT LEFT(B.CNC_MEMO_ID,2) AS DEPT_ID,  
				  B.CNC_MEMO_DT AS XN_DT,  
				   A.PRODUCT_CODE,
				   SUM(CASE WHEN B.STOCK_ADJ_NOTE=0 AND CNC_TYPE=1 THEN quantity ELSE 0 END) AS cnc_qty,
				   SUM(CASE WHEN B.STOCK_ADJ_NOTE=0 AND CNC_TYPE=2 THEN quantity ELSE 0 END) AS unc_qty, 
				   SUM(CASE WHEN B.STOCK_ADJ_NOTE=1 AND ISNULL(b.stock_adj_type,0) IN (0,1) THEN
							( CASE WHEN cnc_type=1 THEN a.rate ELSE -a.rate END) ELSE 0 END) AS sac_net, 
				   SUM(CASE WHEN B.STOCK_ADJ_NOTE=1 AND ISNULL(b.stock_adj_type,0)=2 THEN
						 ( CASE WHEN cnc_type=1 THEN a.rate ELSE -a.rate END) ELSE 0 END) AS sacm_net,
				   A.BIN_ID  AS [BIN_ID]
				   FROM ICD01106 A (NOLOCK)  
				   JOIN ICM01106 B (NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID
				   join sku c (nolock) on c.product_code=a.product_code
				   join article d (nolock) on d.article_code=c.article_code'+@cInsJoinStr+'  
				   JOIN sectiond sd (NOLOCK) ON sd.sub_Section_code=d.sub_section_code
				   JOIN sectionm sm (NOLOCK) ON sm.section_code=sd.section_code
				   WHERE B.CANCELLED = 0 AND ISNULL(B.xn_item_type,0) in (0,1) '+@cFilter+'
				   GROUP BY LEFT(B.CNC_MEMO_ID,2),B.CNC_MEMO_DT, A.PRODUCT_CODE,a.bin_id
				   ) b ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
		PRINT @CCMD 
		EXEC SP_EXECUTESQL @CCMD
	   
	   SET @CSTEP =  270				   
	   SET @CCMD=N'INSERT '+@cRFTABLEName+' 
						(DEPT_ID,XN_DT,PRODUCT_CODE,cnc_qty,unc_qty,sac_net,sacm_net,BIN_ID)
					  
					  SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.cnc_qty,xn.unc_qty,xn.sac_net,xn.sacm_net,
					  xn.bin_id FROM 
					  (	
				 SELECT LEFT(B.CNC_MEMO_ID,2) as dept_id, 
			     B.CNC_MEMO_DT AS XN_DT,  
			     A.PRODUCT_CODE,  
			     SUM(CASE WHEN B.STOCK_ADJ_NOTE=0 AND CNC_TYPE=1 THEN quantity ELSE 0 END) AS cnc_qty,
				   SUM(CASE WHEN B.STOCK_ADJ_NOTE=0 AND CNC_TYPE=2 THEN quantity ELSE 0 END) AS unc_qty, 
				   SUM(CASE WHEN B.STOCK_ADJ_NOTE=1 AND ISNULL(b.stock_adj_type,0) IN (0,1) THEN
							( CASE WHEN cnc_type=1 THEN a.rate ELSE -a.rate END) ELSE 0 END) AS sac_net, 
				   SUM(CASE WHEN B.STOCK_ADJ_NOTE=1 AND ISNULL(b.stock_adj_type,0)=2 THEN
						 ( CASE WHEN cnc_type=1 THEN a.rate ELSE -a.rate END) ELSE 0 END) AS sacm_net,
			     A.BIN_ID  AS [BIN_ID]
			   FROM ICD01106 A (NOLOCK)  
			   JOIN ICM01106 B (NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID
			   join sku c (nolock) on c.product_code=a.product_code
			   join article d (nolock) on d.article_code=c.article_code'+@cInsJoinStr+'  
			   JOIN sectiond sd (NOLOCK) ON sd.sub_Section_code=d.sub_section_code
			   JOIN sectionm sm (NOLOCK) ON sm.section_code=sd.section_code
			   WHERE B.CANCELLED = 0 AND ISNULL(B.xn_item_type,0) in (0,1)  '+@cFilter+'
			   GROUP BY LEFT(B.CNC_MEMO_ID,2),B.CNC_MEMO_DT, A.PRODUCT_CODE,a.bin_id
			   ) xn  
			  LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
			  AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
			  WHERE b.product_code IS NULL'
	  PRINT @CCMD 
	  EXEC SP_EXECUTESQL @CCMD
 	END
	--End of Build Process for Cancellation Transaction
END TRY
BEGIN CATCH
	SET @cErrMsg='SP3SBuildCNC: Step :'+@cStep+',Error :'+ERROR_MESSAGE()
END CATCH	

EndProc:

END
--End of procedure - SP3SBuildCNC
/*

select cancelled,cnc_memo_id, * from icm01106 order by last_update desc

select product_code, * from icd01106 where cnc_memo_id='JM0111900000JMC-000048'

select * from jmho_rfopt..rf_opt where cnc_qty<>0 and product_code='JM43220'

declare @CERRMSG VARCHAR(MAX)
exec SP3SBUILDCNC
	 @CXNID='JM0111900000JMC-000050'
	,@NUPDATEMODE=2
	,@cRfTableName ='jmho_rfopt..rf_opt'
	,@CERRMSG=@CERRMSG OUTPUT
select @CERRMSG	


*/
