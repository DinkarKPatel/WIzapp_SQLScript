CREATE PROCEDURE SPWOW_GETXNSDATA_OBSCBSCALC
@dFromDt VARCHAR(20),
@dToDt  VARCHAR(20),
@cFilter VARCHAR(MAX)='',
@bCalledFromDbQty BIT=0,
@cFilterJoinStr VARCHAR(500)='',
@cErrormsg varchar(max) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cStep VARCHAR(10),@cAddnlJoin VARCHAR(100),@nLoop INT,@cXnType VARCHAR(4)

	SET @cErrormsg=''

BEGIN TRY
	SET @cFilter=(CASE WHEN @cFilter<>'' THEN ' AND '+@cFilter ELSE '' END)
	
	SET @cStep='10'
	SET @cCmd=N'SELECT a.product_code,a.bin_id,a.dept_id,SUM(quantity_ob) xn_qty,''OPS''
    FROM OPS01106 A WITH (NOLOCK)
	JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=a.dept_id
	LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	 LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.bin_id'+@cFilterJoinStr+
	' WHERE xn_dt BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+
    ' group by  a.product_code,a.bin_id,a.dept_id '

	INSERT INTO #tmpXnsCbs (product_code,bin_id,dept_id,xn_qty,xn_type)
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='15'
	--Production
	 SET @cCmd=N' SELECT  B.DEPT_ID, A.PRODUCT_CODE ,SUM(A.QUANTITY) AS XN_QTY,''000''  AS [BIN_ID],''PRD''
	 FROM PRD_STK_TRANSFER_DTM_DET A WITH (NOLOCK)
	 JOIN PRD_STK_TRANSFER_DTM_MST B WITH (NOLOCK) ON A.MEMO_ID = B.MEMO_ID   
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=b.dept_id
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	 LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
     LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	 LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=''000'''+@cFilterJoinStr+
	' WHERE b.MEMO_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED=0    
	 GROUP BY B.DEPT_ID, A.PRODUCT_CODE'
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
    
	print @cCmd
	--Bin transfer out
	SET @cStep='20'
    SET @cCmd=N' SELECT B.Location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID,  A.PRODUCT_CODE ,SUM(A.QUANTITY)*-1 AS XN_QTY, A.SOURCE_BIN_ID  AS [BIN_ID],''DCO'' 
	 FROM FLOOR_ST_DET A WITH (NOLOCK)
	 JOIN FLOOR_ST_MST B WITH (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	 LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	 LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.SOURCE_BIN_ID'+@cFilterJoinStr+
	' WHERE b.MEMO_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED=0    
	 GROUP BY B.Location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE, A.SOURCE_BIN_ID '
     
	   print @cCmd
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	  EXEC SP_EXECUTESQL @cCmd


	 
	 --Bin transfer In
	 SET @cStep='25'
     SET @cCmd=N' SELECT B.Location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE ,sum(A.QUANTITY) AS XN_QTY,A.ITEM_TARGET_BIN_ID  AS [BIN_ID],''DCI''
	 FROM FLOOR_ST_DET A (NOLOCK)    
	 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID      
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	 LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	 LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.ITEM_TARGET_BIN_ID'+@cFilterJoinStr+
	' WHERE b.RECEIPT_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED=0    
	 GROUP BY B.Location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE, A.ITEM_TARGET_BIN_ID'      

	   print @cCmd
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='30'
	--Party Purchase/Challan In at POS database
     
	 SET @cCmd=N' SELECT B.DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,b.BIN_ID,''PUR''
	 FROM PID01106 A WITH(NOLOCK)    
	 JOIN PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id= B.DEPT_ID
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	 LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	 LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=b.BIN_ID'+@cFilterJoinStr+
	' JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''LOCATION_ID'') LOC ON 1=1
	 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION=''HO_LOCATION_ID'') HO ON 1=1 
	 LEFT OUTER JOIN pim01106 c (NOLOCK) ON c.ref_converted_mrntobill_mrrid=b.mrr_id AND c.cancelled=0
	 WHERE b.RECEIPT_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+'  AND B.CANCELLED=0   
	 AND (b.inv_mode IN (0,1) OR loc.value<>ho.value) AND a.PRODUCT_CODE<>'''' and c.mrr_id is null
	 GROUP BY B.DEPT_ID,A.PRODUCT_CODE, b.BIN_ID'
	 
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='35'
	 --Group WSL Challan In at HO database
     SET @cCmd=N'SELECT B.DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,b.BIN_ID,''CHI''
	 FROM IND01106 A WITH(NOLOCK)    
	 JOIN PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID
	 JOIN inm01106 d (nolock) on d.inv_id=a.inv_id
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id= B.DEPT_ID
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=b.BIN_ID'+@cFilterJoinStr+
	' WHERE b.RECEIPT_DT  BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED = 0 AND b.inv_mode=2 AND d.cancelled=0
     GROUP BY B.DEPT_ID,A.PRODUCT_CODE, b.BIN_ID'

	   print @cCmd
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
	
	SET @cStep='40'
	--GRN Pack Slip Issue
     SET @cCmd=N'SELECT B.Location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,a.BIN_ID,''GRNPSIN''
	 FROM GRN_PS_DET  A WITH(NOLOCK)    
	 JOIN GRN_PS_MST B WITH(NOLOCK) ON A.MEMO_ID  = B.MEMO_ID
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id= B.Location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 06-11-2024*/ 
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.MEMO_DT  BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED = 0 
	 GROUP BY B.Location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 06-11-2024*/,A.PRODUCT_CODE, a.BIN_ID'

	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 --GRN Pack Slip reversal
    
	 SET @cStep='45'
	 SET @cCmd=N'SELECT B.DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,b.BIN_ID,''GRNPSOUT''
	 FROM PID01106 A WITH(NOLOCK)    
	 JOIN PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id= B.DEPT_ID
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=b.BIN_ID'+@cFilterJoinStr+
	' WHERE b.RECEIPT_DT  BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+'  AND  B.CANCELLED = 0 
	 AND A.PRODUCT_CODE<>'''' AND B.RECEIPT_DT<>''''
	 AND ISNULL(B.PIM_MODE,0)=6
	 GROUP BY B.DEPT_ID, A.PRODUCT_CODE,b.BIN_ID'
	
	  print @cCmd
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='50'
	 --Party Debit note
	 SET @cCmd=N'SELECT B.Location_code/*LEFT(B.RM_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,A.BIN_ID,(CASE WHEN mode=2 THEN ''CHO'' ELSE ''PRT'' END)
	 FROM RMD01106 A WITH(NOLOCK)
	 JOIN RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id= B.Location_code/*LEFT(B.RM_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.RM_DT  BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+'  AND  B.CANCELLED = 0 AND B.DN_TYPE IN (0,1) 
     GROUP BY B.Location_code/*LEFT(B.RM_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,A.BIN_ID,(CASE WHEN mode=2 THEN ''CHO'' ELSE ''PRT'' END)'
	 
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 DECLARE @cWhere VARCHAR(100)
	 SET @cStep='55'
	 --Net Sales
	 SET @nLoop=1
	 SET @cWhere=''

	 WHILE @nLoop<=(CASE WHEN @bCalledFromDbQty=1 THEN 2 ELSE 1 END)
	 BEGIN
		 SET @cXnType=(CASE WHEN @bCalledFromDbQty=0 OR @nLoop=1 THEN 'SLS' ELSE 'SLR' END)
		 if @bCalledFromDbQty=1
			SET @cWhere=(CASE WHEN  @nLoop=1 THEN ' AND quantity>0 ' ELSE ' AND quantity<0 ' END)

		 SET @cCmd=N'SELECT B.Location_code/*LEFT(B.CM_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,A.BIN_ID,'''+@cXnType+'''
 		 FROM CMD01106 A WITH(NOLOCK)    
		 JOIN CMM01106 B WITH(NOLOCK) ON A.CM_ID = B.CM_ID 
		 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
		 JOIN location sourceLocation (NOLOCK) ON sourceLocation.dept_id=B.Location_code/*left(b.cm_id,2)*//*Rohit 06-11-2024*/
		 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
		LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
		LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
		 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
		 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
		  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
		Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
		Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
		Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
		Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
			LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
			LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
			LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
			LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
			LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	    ' WHERE b.CM_DT  BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+@cWhere+'  AND  B.CANCELLED = 0
		 GROUP BY B.Location_code/*LEFT(B.CM_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,A.BIN_ID'

		   print @cCmd
		 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
		 EXEC SP_EXECUTESQL @cCmd

		 SET @nLoop=@nLoop+1
	 END

	 SET @cStep='60'
	 --Retail Pack slip not converted into Bill
     SET @cCmd=N' SELECT B.Location_code/*LEFT(B.CM_ID,2)*//*Rohit 06-11-2024*/  AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,A.BIN_ID,''RPS''
 	 FROM RPS_DET A (NOLOCK)    
	 JOIN RPS_MST B (NOLOCK) ON A.CM_ID = B.CM_ID  
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*left(b.cm_id,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID'+@cFilterJoinStr+
	' WHERE b.CM_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED = 0  AND  isnull( b.ref_cm_id  ,'''') =''''
     GROUP BY B.Location_code/*LEFT(B.CM_ID,2)*//*Rohit 06-11-2024*/ , A.PRODUCT_CODE,A.BIN_ID'

	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='65'
	 --Approval Issue
	 SET @cCmd=N'SELECT B.Location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 06-11-2024*/  AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,A.BIN_ID,''APP''
 	 FROM APD01106 A WITH(NOLOCK)    
	 JOIN APM01106 B WITH(NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*left(b.MEMO_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.memo_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED = 0   
	 GROUP BY B.Location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 06-11-2024*/ , A.PRODUCT_CODE,A.BIN_ID'
    
	 print @cCmd
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

     SET @cStep='70'
	 --Approval return
	 SET @cCmd=N'SELECT C.Location_code/*LEFT(C.MEMO_ID,2)*//*Rohit 06-11-2024*/  AS DEPT_ID, A.apd_PRODUCT_CODE PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,A.BIN_ID,''APR''
 	 FROM APPROVAL_RETURN_DET A WITH(NOLOCK)    
	 JOIN APPROVAL_RETURN_MST C WITH(NOLOCK) ON C.MEMO_ID = A.MEMO_ID  
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.apd_PRODUCT_CODE
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=C.Location_code/*left(c.MEMO_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE C.memo_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND   C.CANCELLED = 0    
     GROUP BY C.Location_code/*LEFT(c.MEMO_ID,2)*//*Rohit 06-11-2024*/ , A.apd_PRODUCT_CODE,A.BIN_ID'

	 print @cCmd
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='75'
	 --Cancelllation/Uncancellation
	 SET @nLoop=1
	 SET @cWhere=''

	 WHILE @nLoop<=(CASE WHEN @bCalledFromDbQty=1 THEN 2 ELSE 1 END)
	 BEGIN
		 SET @cXnType=(CASE WHEN @bCalledFromDbQty=0 OR @nLoop=1 THEN 'CNC' ELSE 'UNC' END)
		 if @bCalledFromDbQty=1
			SET @cWhere=(CASE WHEN  @nLoop=1 THEN ' AND cnc_type=1 ' ELSE ' and cnc_type=2 ' END)

		  SET @cCmd=N'SELECT B.Location_code/*LEFT(B.cnc_memo_id,2)*//*Rohit 06-11-2024*/  AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY*(CASE WHEN cnc_type=1 then -1 else 1 end)) AS XN_QTY,A.BIN_ID,'''+@cXnType+'''
		 FROM ICD01106 A WITH(NOLOCK)    
		 JOIN ICM01106 B WITH(NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID    
		 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
		 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*left(B.cnc_memo_id,2)*//*Rohit 06-11-2024*/
		 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
		LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
		LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
		 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
		 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
		  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
		Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
		Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
		Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
		Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
			LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
			LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
			LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
			LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
			LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	    ' WHERE b.cnc_memo_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+@cWhere+' AND   B.CANCELLED = 0   AND ISNULL(B.STOCK_ADJ_NOTE,0)=0
		 GROUP BY B.Location_code/*LEFT(B.cnc_memo_id,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,A.BIN_ID'
     
		 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
		 EXEC SP_EXECUTESQL @cCmd

		 SET @nLoop=@nLoop+1
     END

	 --Group wholesale/Party Invoice
	SET @cStep='80'
      SET @cCmd=N'SELECT B.Location_code/*LEFT(b.inv_id,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,A.BIN_ID ,(CASE WHEN b.inv_mode=1 THEN ''WSL'' else ''CHO'' END)
	 FROM IND01106 A WITH(NOLOCK)    
	 JOIN INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID  
	  JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.inv_id,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.inv_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  B.CANCELLED = 0   AND ISNULL(B.PENDING_GIT,0)=0
    GROUP BY B.Location_code/*LEFT(b.inv_id,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,A.BIN_ID,(CASE WHEN b.inv_mode=1 THEN ''WSL'' else ''CHO'' END)'
	
	
	INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='85'
    --Wholesale Pack Slip reversal
     SET @cCmd=N'SELECT b.Location_code/*LEFT(b.inv_id,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,A.BIN_ID ,''WPR''
  	 FROM IND01106 A WITH(NOLOCK)   
	 JOIN INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID 
	 JOIN wps_mst c (NOLOCK) ON  c.wsl_inv_id=a.inv_id AND a.ps_id=c.ps_id
	  JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=b.Location_code/*LEFT(b.inv_id,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE  b.inv_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  B.CANCELLED = 0 AND c.cancelled=0   AND ISNULL(B.PENDING_GIT,0)=0
     GROUP BY b.Location_code/*LEFT(b.inv_id,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,A.BIN_ID '

	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='90'
	 --API(Bin Transfer)
     SET @cCmd=N'SELECT b.Location_code/*LEFT(B.inv_id,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,b.TARGET_BIN_ID,''API''
    FROM IND01106 A WITH(NOLOCK)    
	 JOIN INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=b.Location_code/*LEFT(b.inv_id,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=b.TARGET_BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE  b.inv_DT BETWEEN '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  B.CANCELLED = 0 AND B.BIN_TRANSFER=1  
	 AND B.ENTRY_MODE<>2    AND ISNULL(B.PENDING_GIT,0)=0
    GROUP BY b.Location_code/*LEFT(B.inv_id,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,b.TARGET_BIN_ID'
    
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='95'
	--Wholesale Pack Slip Issue
	
     SET @cCmd=N'SELECT b.Location_code/*LEFT(B.ps_id,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,a.BIN_ID,''WPI''
    FROM WPS_DET A WITH(NOLOCK)    
	 JOIN WPS_MST B WITH(NOLOCK) ON A.PS_ID = B.PS_ID    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=b.Location_code/*LEFT(b.ps_id,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE  b.ps_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND   B.CANCELLED = 0   
	GROUP BY b.Location_code/*LEFT(B.ps_id,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,a.BIN_ID'
	
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='100'
	--Wholesale Return
     SET @cCmd=N'SELECT b.Location_code/*LEFT(B.cn_id,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,a.BIN_ID,''CHI''
	FROM CND01106 A (NOLOCK)    
	 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID   
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=b.Location_code/*LEFT(b.cn_id,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.receipt_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND b.mode=2 AND   B.CANCELLED = 0 AND B.CN_TYPE<>2 
     GROUP BY b.Location_code/*LEFT(B.cn_id,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,a.BIN_ID'

	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
	
	SET @cStep='105'
	--Group Credit Note
     SET @cCmd=N'SELECT b.Location_code/*LEFT(B.cn_id,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,a.BIN_ID,''WSR''
	FROM CND01106 A (NOLOCK)    
	 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID   
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=b.Location_code/*LEFT(b.cn_id,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.cn_dt BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND b.mode<>2 AND   B.CANCELLED = 0 AND B.CN_TYPE<>2 
     GROUP BY b.Location_code/*LEFT(B.cn_id,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,a.BIN_ID'

	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
	 --APO (Bin Transfer)
   
    SET @cStep='110'
    SET @cCmd=N'SELECT b.Location_code/*LEFT(B.CN_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,(case when isnull(B.SOURCE_BIN_ID,'''')='''' then b.BIN_ID else B.SOURCE_BIN_ID end ) BIN_ID,''APO''
 	 FROM CND01106 A (NOLOCK)    
	 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	 JOIN (SELECT TOP 1 * FROM  config WHERE CONFIG_OPTION=''LOCATION_ID'') CL ON 1=1
	 JOIN (SELECT TOP 1 * FROM  config WHERE CONFIG_OPTION=''HO_LOCATION_ID'') HL ON 1=1
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=b.Location_code/*LEFT(b.cn_id,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=(case when isnull(B.SOURCE_BIN_ID,'''')='''' then b.BIN_ID else B.SOURCE_BIN_ID end )'+@cFilterJoinStr+
	' WHERE b.cn_dt BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  B.CANCELLED = 0 AND B.BIN_TRANSFER=1
	 and (CL.value =HL.value or CL.value =LEFT(B.CN_ID,2) )
     GROUP BY b.Location_code/*LEFT(B.CN_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,(case when isnull(B.SOURCE_BIN_ID,'''')='''' then b.BIN_ID else B.SOURCE_BIN_ID end ) '

	  INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
	---New Barcodes (Rate revision)
   
   SET @cStep='115'
    SET @cCmd=N'SELECT b.Location_code/*LEFT(B.IRM_MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.NEW_PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,B.BIN_ID,''IRR_PFI''
    FROM IRD01106 A (NOLOCK)    
	 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.NEW_PRODUCT_CODE
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=b.Location_code/*LEFT(b.IRM_MEMO_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=b.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.irm_memo_dt BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  A.NEW_PRODUCT_CODE<>''''    
    GROUP BY B.Location_code/*LEFT(B.IRM_MEMO_ID,2)*//*Rohit 06-11-2024*/, A.NEW_PRODUCT_CODE,B.BIN_ID'

	  INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
	---New Barcodes (Split Combine)

	SET @cStep='120'
    SET @cCmd=N'SELECT B.Location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,''000'' BIN_ID,''SCFPFI''
    FROM SCF01106 A (NOLOCK)    
	 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID   
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=''000''
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.memo_dt BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''''    
     GROUP BY B.Location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 06-11-2024*/ , A.PRODUCT_CODE'
	
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	--Consumed Barcodes(Rate revision)

	 SET @cStep='125'
     SET @cCmd=N'SELECT B.Location_code/*LEFT(B.IRM_MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,a.BIN_ID ,''IRR_CIP''
    FROM IRD01106 A (NOLOCK)    
	 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.IRM_MEMO_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.irm_memo_dt BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  A.NEW_PRODUCT_CODE<>''''    
     GROUP BY B.Location_code/*LEFT(B.IRM_MEMO_ID,2)*//*Rohit 06-11-2024*/ , A.PRODUCT_CODE,a.BIN_ID '

	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='130'
	 --Consumed Barcodes(Split/Combine)
    SET @cCmd=N'SELECT B.Location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,''000'' BIN_ID ,''SCC''
    FROM SCC01106 A (NOLOCK)    
	 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=''000''
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE  b.memo_dt BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND    B.CANCELLED=0 AND A.PRODUCT_CODE<>''''     
     GROUP BY  B.Location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE '

	  INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
	 
	 SET @cStep='135'
	 --Jobwork Issue
     SET @cCmd=N'SELECT B.Location_code/*LEFT(B.ISSUE_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,a.BIN_ID ,''JWI''
	FROM JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.ISSUE_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE  b.ISSUE_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND    B.CANCELLED=0 AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
	 AND ISNULL(B.ISSUE_MODE,0)<>1  
	 GROUP BY B.Location_code/*LEFT(B.ISSUE_ID,2)*//*Rohit 06-11-2024*/ , A.PRODUCT_CODE ,a.bin_id'
     
	  INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='140'
	--Jobwork Receipt
	  SET @cCmd=N'SELECT B.Location_code/*LEFT(B.RECEIPT_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,a.BIN_ID ,''JWR''
	  FROM JOBWORK_RECEIPT_DET A (NOLOCK)    
	 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN JOBWORK_ISSUE_DET D (NOLOCK) ON D.ROW_ID=A.REF_ROW_ID    
	 JOIN JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = D.ISSUE_ID    
	 JOIN PRD_AGENCY_MST PAM(NOLOCK) ON PAM.AGENCY_CODE=B.AGENCY_CODE  
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.RECEIPT_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	'  WHERE  b.RECEIPT_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  B.CANCELLED=0 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 
      GROUP BY B.Location_code/*LEFT(B.RECEIPT_ID,2)*//*Rohit 06-11-2024*/ , A.PRODUCT_CODE ,a.bin_id'
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='145'
  --BOC
	  SET @cCmd=N'SELECT D.Location_code/*LEFT(D.ORDER_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, e.PRODUCT_CODE,SUM(E.CONS_QTY_PER_PICE*P.QUANTITY)*-1 AS XN_QTY,''000'' BIN_ID ,''BOC''
	  FROM WSL_ORDER_BOM E(NOLOCK)     
	 LEFT OUTER JOIN WSL_ORDER_DET C (NOLOCK) ON E.REF_ROW_ID=C.ROW_ID    
	 LEFT OUTER JOIN WSL_ORDER_MST D (NOLOCK) ON C.ORDER_ID=D.ORDER_ID    
	 JOIN POD01106 P ON C.ROW_ID = P.WOD_ROW_ID     
	 JOIN POM01106 PM ON P.PO_ID = PM.PO_ID      
	 LEFT OUTER JOIN SKU ON E.PRODUCT_CODE=SKU.PRODUCT_CODE   
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=e.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=D.Location_code/*LEFT(d.ORDER_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=''000''
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE  d.ORDER_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND PM.CANCELLED = 0    
     GROUP BY D.Location_code/*LEFT(D.ORDER_ID,2)*//*Rohit 06-11-2024*/ , e.PRODUCT_CODE '
   	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='145'
   --New Barcodes (Split/Combine)
    
	   SET @cCmd=N' SELECT B.Location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, B2.PRODUCT_CODE,SUM(CASE WHEN sn_BARCODE_CODING_SCHEME=3 THEN B2.TOTAL_QTY ELSE A.QUANTITY END) AS XN_QTY,a.BIN_ID ,''SNC_PFI''
	 FROM SNC_DET A (NOLOCK)    
	 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN  
	 (  
	 SELECT REFROW_ID AS [ROW_ID],a.PRODUCT_CODE,sn_BARCODE_CODING_SCHEME,COUNT(*) AS [TOTAL_QTY]  
	 FROM SNC_BARCODE_DET a (NOLOCK)  
	 JOIN snc_det sd (NOLOCK) ON sd.ROW_ID=a.REFROW_ID
	 JOIN snc_mst sm (NOLOCK) ON sm.MEMO_ID=sd.MEMO_ID
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=sm.Location_code/*LEFT(sm.MEMO_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=sd.BIN_ID
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE  sm.RECEIPT_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND cancelled=0 and sm.WIP=0 and a.PRODUCT_CODE<>''''
	 GROUP BY REFROW_ID,a.PRODUCT_CODE ,sn_BARCODE_CODING_SCHEME 
	 )B2 ON A.ROW_ID = B2.ROW_ID  
	 GROUP BY B.Location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 06-11-2024*/ , B2.PRODUCT_CODE ,a.BIN_ID'

	 SET @cStep='150'
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
    --Consumed Barcodes (Split/Combine)
	  SET @cCmd=N'SELECT B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,ISNULL(A.BIN_ID,''000''),''SNC_CIP''
	  FROM SNC_CONSUMABLE_DET A (NOLOCK)    
	  JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	  JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	  JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/
	  LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	  JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	   LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
		Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
			LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
	  JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=ISNULL(A.BIN_ID,''000'')'+@cFilterJoinStr+
	'  WHERE b.RECEIPT_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND   A.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''''   
	  GROUP BY B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/ , a.PRODUCT_CODE ,a.BIN_ID'

	  SET @cStep='155'
	   INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
   --TTM
	 SET @cCmd=N'SELECT B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QTY) AS XN_QTY,''000'',''TTM''
	  FROM PRD_TRANSFER_MAIN_DET A (NOLOCK)    
	 JOIN PRD_TRANSFER_MAIN_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=''000''
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.memo_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  B.CANCELLED=0 AND A.PRODUCT_CODE<>''''   
	 GROUP BY B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/ , A.PRODUCT_CODE'

	 SET @cStep='160'
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
	 
   
   SET @cCmd=N'SELECT B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,a.bin_id,''TTM''
   FROM TRANSFER_TO_TRADING_DET A (NOLOCK)    
   JOIN TRANSFER_TO_TRADING_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
   JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
   JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/
   LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
   JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.bin_id
   JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
    LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.memo_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''''   
  GROUP BY B.Location_code/*LEFT(b.MEMO_ID,2)*//*Rohit 06-11-2024*/ , A.PRODUCT_CODE    ,a.bin_id '     
   
   SET @cStep='170'
   INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

  --Debit note Packslip Issue
	SET @cCmd=N'  SELECT B.Location_code/*LEFT(B.PS_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,a.bin_id ,''DNPI'' 
  	 FROM DNPS_DET A (NOLOCK)    
	 JOIN DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.PS_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.bin_id
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.ps_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''''   
	  GROUP BY B.Location_code/*LEFT(B.PS_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE    ,a.bin_id '

     SET @cStep='175'
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
  --Debit note Packslip reversal	    
     SET @cCmd=N'SELECT B.Location_code/*LEFT(B.ps_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,a.bin_id ,''DNPR'' 
  	 FROM dnps_det A (NOLOCK)    
	 JOIN dnps_mst B (NOLOCK) ON A.ps_ID = B.ps_ID 
	 JOIN rmm01106 C (NOLOCK) ON b.prt_rm_id=c.rm_id
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.PS_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.bin_id
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE c.rm_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  B.CANCELLED = 0 AND ISNULL(A.PS_ID,'''')<>''''
     GROUP BY B.Location_code/*LEFT(B.ps_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,a.bin_id '
     
	 SET @cStep='180'
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

   --Credit note Packslip Issue
     SET @cCmd=N'SELECT B.Location_code/*LEFT(B.PS_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY) AS XN_QTY,a.bin_id ,''CNPI'' 
	 FROM CNPS_DET A (NOLOCK)    
	 JOIN CNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID 
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=	B.Location_code/*LEFT(b.PS_ID,2)*//*Rohit 06-11-2024*/ 
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.bin_id
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.ps_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''''   
	 GROUP BY B.Location_code/*LEFT(B.PS_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE,a.bin_id '
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd	 

	 SET @cStep='185'
    --Credit note Packslip reversal
   	 SET @cCmd=N' SELECT B.Location_code/*LEFT(B.PS_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,a.bin_id ,''CNPR''
  	 FROM CNPS_DET A (NOLOCK)    
	 JOIN CNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID 
	 JOIN cnm01106 C ON B.wsr_cn_id=C.cn_id    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=	 B.Location_code/*LEFT(b.PS_ID,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.bin_id
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE c.cn_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''''   
	 GROUP BY B.Location_code/*LEFT(B.PS_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE    ,a.bin_id'
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd	 
     
	 SET @cStep='190'
   --Material Receipt/Issue
	SET @cCmd=N'SELECT B.Location_code/*LEFT(B.ISSUE_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.STOCK_QTY*(CASE WHEN ISNULL(B.ISSUE_TYPE,0)=0 THEN -1 ELSE 1 END)) AS XN_QTY,a.bin_id ,''MIS''
    FROM BOM_ISSUE_DET A (NOLOCK)  
	JOIN BOM_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
	JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.ISSUE_ID,2)*//*Rohit 06-11-2024*/	
	LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.bin_id
	JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	 LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.ISSUE_DT BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''''   
	GROUP BY B.Location_code/*LEFT(B.ISSUE_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE    ,a.bin_id'     
	INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd


	 SET @cStep='195'
	--SLS/SLR OF Consumables
   
	SET @cCmd=N'SELECT B.Location_code/*LEFT(B.CM_ID,2)*//*Rohit 06-11-2024*/ AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,''000'' bin_id ,''SLS''
   	 FROM cmd_cons A WITH(NOLOCK)    
	 JOIN CMM01106 B WITH(NOLOCK) ON A.CM_ID = B.CM_ID    
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.CM_ID,2)*//*Rohit 06-11-2024*/	
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=''000''
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.cm_dt BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  B.CANCELLED = 0  
    GROUP BY  B.Location_code/*LEFT(B.CM_ID,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE'
	INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd

    
	SET @cStep='200'
	SET @cCmd=N'SELECT B.Location_code/*Left(b.memo_id,2)*//*Rohit 06-11-2024*/  AS DEPT_ID, A.PRODUCT_CODE,SUM(A.QUANTITY)*-1 AS XN_QTY,''000'' bin_id ,''SLS''

	 FROM sls_delivery_cons A WITH(NOLOCK)    
	 JOIN sls_delivery_mst B WITH(NOLOCK) ON A.memo_id = B.memo_id  
	 JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
	 JOIN location sourceLocation(NOLOCK) ON sourceLocation.dept_id=B.Location_code/*LEFT(b.memo_id,2)*//*Rohit 06-11-2024*/
	 LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
	LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
	LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
	 JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=''000''
	 JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
	  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
	Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
	Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
	Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
	Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code'+@cFilterJoinStr+
	' WHERE b.memo_dt BETWEEN  '''+@dFromDt+''' AND '''+@dToDt+''''+@cFilter+' AND  B.CANCELLED = 0  
	 GROUP BY  B.Location_code/*Left(b.memo_id,2)*//*Rohit 06-11-2024*/, A.PRODUCT_CODE'
	 INSERT INTO #tmpXnsCbs (dept_id,product_code,xn_qty,bin_id,xn_type)
	 EXEC SP_EXECUTESQL @cCmd
	  

	 GOTO END_PROC
END TRY
BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_GETXNSDATA_OBSCBSCALC at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END