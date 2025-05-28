CREATE PROCEDURE SP3S_PENDINGORDER_PO_MATERIAL
(
	@CWHERE NVARCHAR(MAX)='',
	@dlogindt DateTime='2021-04-01',
	@cdept_id varchar(5)='h1'
)
AS
BEGIN


       DECLARE @CCMD VARCHAR(MAX),@cStep VARCHAR(20),@cErrormsg VARCHAR(MAX)

BEGIN TRY
	SET @cStep='10'

	 SELECT CAST('' AS VARCHAR(100)) AS  UNQ_ID,A.ROW_ID,A.ROW_ID AS BO_ROW_ID,
	        CAST('' AS VARCHAR(100)) AS Ac_NAME,  CAST('' AS VARCHAR(100)) AS Order_No, CAST('' AS DateTime) AS Order_Dt,A.QUANTITY AS BO_QTY,
	        CAST('' AS VARCHAR(100)) AS SECTION_NAME,CAST('' AS VARCHAR(100)) AS SUB_SECTION_NAME,CAST('' AS VARCHAR(100)) AS ARTICLE_NO,
			A.ARTICLE_CODE ,CAST('' AS VARCHAR(100))  AS PARA1_NAME,A.PARA1_CODE ,CAST('' AS VARCHAR(100))  AS PARA2_NAME,A.PARA2_CODE ,A.AVG_QUANTITY,A.ADD_AVG_QUANTITY,
			ISNULL(A.AVG_QUANTITY,0)+ISNULL(A.ADD_AVG_QUANTITY,0) AS NET_AVG_QTY,
		    CAST('' AS VARCHAR(100)) AS UOM_NAME,CAST('' AS VARCHAR(100)) AS CONVERSION_UOM_NAME,
			CAST(0 AS NUMERIC(10,3)) AS Conversion_Value,cast('' as varchar(20)) as hsn_code,
		   CAST(0 AS NUMERIC(10,3)) AS Quantity,
			CAST(0 AS NUMERIC(10,3)) AS Total_Requirement,
			CAST(0 AS NUMERIC(10,3)) AS Generated_po_qty,
			CAST(0 AS NUMERIC(10,3)) AS MATERIAL_REQ_QTY,A.TOL_PER

		INTO #PENDINGBUYERORDER
 		FROM ORD_PLAN_BOM_DET A (NOLOCK)
		WHERE 1=2
    
	if isnull(@cdept_id,'')=''
	SELECT TOP 1 @cdept_id=value FROM config (NOLOCK) WHERE config_option='location_id'
			
	SET @cStep='40'
		SET @CCMD=N'SELECT CAST('''' AS VARCHAR(100)) AS  UNQ_ID,T.ROW_ID,BUYER_ORDER_MST.ORDER_ID AS BO_ROW_ID,OD.QUANTITY AS BO_QTY,
		       SECTIONM.SECTION_NAME,SECTIOND.SUB_SECTION_NAME ,ARTICLE.ARTICLE_NO,ARTICLE.ARTICLE_CODE,
			   PARA1.PARA1_NAME,PARA1.PARA1_CODE,PARA2.PARA2_NAME,PARA2.PARA2_CODE,

			   T.AVG_QUANTITY,T.ADD_AVG_QUANTITY,ISNULL(T.AVG_QUANTITY,0)+ISNULL(T.ADD_AVG_QUANTITY,0) AS NET_AVG_QTY,
			   UOM.UOM_NAME,BU.CONVERSION_UOM_NAME,UC.Conversion_Value,ARTICLE.HSN_CODE,
			   T.QUANTITY,
			   CONVERT(NUMERIC(14,4), CASE WHEN ISNULL(UC.CONVERSION_VALUE,0) =0 THEN ISNULL(T.QUANTITY,0)
	           ELSE (ISNULL(T.QUANTITY,0))/ISNULL(UC.CONVERSION_VALUE,0) END  ) AS  Total_Requirement   ,
			   0 Generated_po_qty,
			   LM01106.AC_NAME,BUYER_ORDER_MST.ORDER_NO,BUYER_ORDER_MST.ORDER_DT,T.TOL_PER

 		 FROM ORD_PLAN_BOM_DET T (NOLOCK)    
		 JOIN ORD_PLAN_DET T1 (NOLOCK) ON  T.MEMO_ID=T1.MEMO_ID  AND T.REF_ROW_ID =T1.ROW_ID
		 JOIN ORD_PLAN_MST T2 (NOLOCK) ON  T1.MEMO_ID=T2.MEMO_ID  
		 JOIN BUYER_ORDER_DET OD (NOLOCK) ON OD.ROW_ID =T1.WOD_ROW_ID
		 JOIN BUYER_ORDER_MST  (NOLOCK) ON OD.ORDER_ID =BUYER_ORDER_MST.ORDER_ID 
		 JOIN ARTICLE  (NOLOCK) ON T.ARTICLE_CODE = ARTICLE.ARTICLE_CODE         
		 JOIN PARA1  (NOLOCK) ON T.PARA1_CODE = PARA1.PARA1_CODE        
		 JOIN PARA2  (NOLOCK) ON T.PARA2_CODE = PARA2.PARA2_CODE        
		 JOIN UOM  (NOLOCK) ON UOM.UOM_CODE = ARTICLE.UOM_CODE        
		 JOIN SECTIOND  (NOLOCK) ON SECTIOND.SUB_SECTION_CODE = ARTICLE.SUB_SECTION_CODE        
		 JOIN SECTIONM  (NOLOCK) ON SECTIONM.SECTION_CODE = SECTIOND.SECTION_CODE 
		 JOIN LM01106 (NOLOCK) ON LM01106.AC_CODE=BUYER_ORDER_MST.AC_CODE
		 LEFT OUTER JOIN UOM_CONVERSION UC ON UC.UOM_CODE=UOM.UOM_CODE
		 LEFT OUTER JOIN BOM_UOM BU ON BU.CONVERSION_UOM_CODE=UC.CONVERSION_UOM_CODE  
		 WHERE  T.QUANTITY>0
		 and   BUYER_ORDER_MST.approvedlevelno=99 and BUYER_ORDER_MST.DELIVERY_DT>='''+convert(varchar(10),@DLOGINDT,121)+'''
		 and BUYER_ORDER_MST.dept_id='''+@cdept_id+'''
		 AND BUYER_ORDER_MST.CANCELLED = 0 and T2.cancelled=0   AND ISNULL(BUYER_ORDER_MST.Short_close,0) = 0 AND '
		+ 
		(CASE WHEN ISNULL(@CWHERE,'')='' THEN ' 1=1 ' ELSE ISNULL(@CWHERE,'') END)
		
		SET @cStep='45'
		PRINT @cCmd
		INSERT INTO #PENDINGBUYERORDER( UNQ_ID,ROW_ID, BO_ROW_ID,BO_QTY,SECTION_NAME,SUB_SECTION_NAME, ARTICLE_NO,ARTICLE_CODE ,PARA1_NAME,PARA1_CODE ,PARA2_NAME,PARA2_CODE ,
		AVG_QUANTITY,ADD_AVG_QUANTITY,NET_AVG_QTY,UOM_NAME,CONVERSION_UOM_NAME,Conversion_Value,hsn_code,QUANTITY,Total_Requirement,Generated_po_qty,Ac_name,Order_no,order_dt,TOL_PER)
		EXEC ( @CCMD)

		if object_id ('tempdb..#tmppendingrm','u') is not null
		   drop table #tmppendingrm


		SELECT a.section_name ,a.SUB_SECTION_NAME , A.UNQ_ID, AC_NAME,A.BO_ROW_ID,ORDER_NO ,ORDER_DT ,
		       A.ARTICLE_NO,A.ARTICLE_CODE,A.HSN_CODE,
		       A.PARA1_NAME,A.PARA1_CODE ,
			   A.PARA2_NAME ,A.PARA2_code ,
			   A.UOM_NAME,
			   SUM(TOTAL_REQUIREMENT) as TOTAL_REQUIREMENT,
			   b.PO_QTY AS GENERATED_PO_QTY,
		       newid() as DET_UNQ_ID,A.TOL_PER,
			   CAST(c.Allocated_qty AS NUMERIC(10,3)) AS Allocated_qty
		into #tmppendingrm
		FROM #PENDINGBUYERORDER A
		LEFT JOIN
		(
		  SELECT A.WOD_ROW_ID ,A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE ,
		             SUM(QUANTITY) AS PO_QTY
		  FROM POD01106 A (nolock)
		  JOIN POM01106 B (nolock) ON A.PO_ID=B.PO_ID 
		  WHERE B.CANCELLED =0 AND isnull(A.WOD_ROW_ID,'') <>'' AND MODE=5
		  GROUP BY A.WOD_ROW_ID ,A.ARTICLE_CODE ,A.PARA1_CODE,A.PARA2_CODE
		
		) B ON A.ARTICLE_CODE =B.ARTICLE_CODE AND A.PARA1_CODE =B.PARA1_CODE AND A.PARA2_CODE =B.PARA2_CODE and a.BO_ROW_ID=b.wod_row_id
		left join
		(
		  
		SELECT A.REF_ORDER_ID  ,SKU.ARTICLE_CODE ,SKU.PARA1_CODE ,SKU.PARA2_CODE ,
		       SUM(quantity_in_stock ) AS Allocated_qty 
		FROM BOMDQRQDET A WITH (NOLOCK)
		JOIN BOMDQRQMST B ON A.MEMO_ID =B.MEMO_ID 
		JOIN PMT01106 C ON A.PRODUCT_CODE =C.PRODUCT_CODE AND B.location_code =C.DEPT_ID AND A.BIN_ID =C.BIN_ID AND A.REF_ORDER_ID=C.BO_ORDER_ID 
		JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE =A.PRODUCT_CODE 
		WHERE B.CANCELLED =0 and b.MEMO_TYPE =1
		group by A.REF_ORDER_ID  ,SKU.ARTICLE_CODE ,SKU.PARA1_CODE ,SKU.PARA2_CODE 

		) c ON A.ARTICLE_CODE =c.ARTICLE_CODE AND A.PARA1_CODE =c.PARA1_CODE AND A.PARA2_CODE =c.PARA2_CODE and a.BO_ROW_ID=c.REF_ORDER_ID		GROUP BY a.section_name ,a.SUB_SECTION_NAME ,A.UNQ_ID, AC_NAME,A.BO_ROW_ID,ORDER_NO ,ORDER_DT ,
		       A.ARTICLE_NO,A.ARTICLE_CODE,A.HSN_CODE,
		       A.PARA1_NAME,A.PARA1_CODE ,A.PARA2_NAME ,A.PARA2_code ,A.UOM_NAME,PO_QTY,A.TOL_PER,
			   CAST(c.Allocated_qty AS NUMERIC(10,3))
		having SUM(TOTAL_REQUIREMENT)-isnull(PO_QTY,0)>0

	
	
	   SELECT CAST('''' AS VARCHAR(100)) AS  UNQ_ID,SECTION_NAME ,SUB_SECTION_NAME ,
	           ARTICLE_NO,PARA1_NAME  ,PARA2_NAME ,a.UOM_NAME  ,
			   a.article_code ,a.para1_code,a.para2_code ,
				sum(isnull(Total_Requirement,0)) as Total_Requirement,
				sum(isnull(Generated_po_qty,0)) as Generated_po_qty,
				SUM(isnull(Total_Requirement,0))-sum(isnull(Generated_po_qty,0)+isnull(Allocated_qty,0)) qty_required,
				sum(isnull(Allocated_qty,0)) as Allocated_qty,
				CONVERT(NUMERIC(10,3),0) current_po_qty_total, a.hsn_code,
				CONVERT(NUMERIC(10,3),0) Stock_qty
	   into #PENDINGBUYERORDER_stock
	   FROM #tmppendingrm A
	   GROUP BY SECTION_NAME ,SUB_SECTION_NAME ,ARTICLE_NO,PARA1_NAME  ,PARA2_NAME ,a.UOM_NAME  ,a.hsn_code,
	   a.article_code ,a.para1_code,a.para2_code

	   	UPDATE #PENDINGBUYERORDER_stock SET unq_id=CONVERT(VARCHAR(40),NEWID()) 

        UPDATE b SET  unq_id=c.unq_id FROM #tmppendingrm b
		JOIN #PENDINGBUYERORDER_stock c on b.article_code=c.article_code and b.para1_code=c.para1_code and b.para2_code=c.para2_code


		       UPDATE B SET STOCK_QTY=C.STOCK_QTY
				FROM #PENDINGBUYERORDER_STOCK B
				JOIN
				(  

					SELECT Article_code,para1_code,para2_code,
					SUM(QUANTITY_IN_STOCK) AS STOCK_QTY
					FROM sku A (NOLOCK)
					JOIN PMT01106 B (NOLOCK) ON B.PRODUCT_CODE=A.PRODUCT_CODE
					 WHERE(@CWHERE='' or  B.DEPT_ID=@cdept_id) AND B.BIN_ID<>'999' and isnull(b.bo_order_id,'') =''
					GROUP BY Article_code,para1_code,para2_code
					HAVING SUM(QUANTITY_IN_STOCK)>0 
				)C  ON  b.article_code=c.article_code and b.para1_code=c.para1_code and b.para2_code=c.para2_code
				
			


		SELECT CONVERT(BIT,0) CHK,  UNQ_ID,SECTION_NAME ,SUB_SECTION_NAME ,ARTICLE_NO ,hsn_code,
		       PARA1_NAME ,PARA2_NAME ,
			   TOTAL_REQUIREMENT ,
			   Generated_po_qty As Po_Generated_qty,
			   Stock_qty,
			   Allocated_qty,
			   qty_required ,
			   current_po_qty_total 
		FROM #PENDINGBUYERORDER_STOCK
		order by ARTICLE_NO
		



		SELECT CONVERT(BIT,0) CHK,unq_id,ac_name customer_name,
				ORDER_DT,ORDER_NO,	
				BO_ROW_ID as ord_row_id,
				a.article_no ,a.para1_name ,a.para2_name ,uom_name ,
				(isnull(a.Total_Requirement,0)) as Total_Requirement,
				(isnull(a.Generated_po_qty,0)) as Po_Generated_qty,
				(isnull(a.Allocated_qty,0)) as Allocated_qty,
				(isnull(a.Total_Requirement,0)-(isnull(a.Generated_po_qty,0)+isnull(a.Allocated_qty,0))) as Qty_required,
			--	pending_po_qty,
				CONVERT(NUMERIC(10,2),0) AS current_po_qty,
				a.DET_UNQ_ID,a.TOL_PER AS tolerance_percentage
		FROM #tmppendingrm a 
		order by ORDER_DT,ORDER_NO

	
	


	  -- #PENDINGBUYERORDER_stock
	
	
		GOTO END_PROC	
END TRY
BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_PENDINGORDER_PO_MATERIAL at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	SELECT ISNULL(@cErrormsg,'') errmsg

	;WITH CTE
	AS
	(
		select ROW_NUMBER() OVER (PARTITION BY A.ARTICLE_CODE ORDER BY B.ARTICLE_NO) SR_NO,A.ARTICLE_CODE,B.ARTICLE_NO,A.PRODUCT_CODE 
		FROM SKU A
		JOIN ARTICLE B ON B.article_code=A.article_code
		JOIN #tmppendingrm A1 ON A1.article_code=B.article_code
		WHERE A.barcode_coding_scheme=1
		AND CHARINDEX('@',A.product_code,1)<=0
	)
	SELECT * INTO #PENDINGBUYERORDER_PC FROM CTE WHERE SR_NO=1

	SELECT A.BO_ROW_ID AS ORD_ROW_ID ,0 as  ORDER_QTY   ,A.ARTICLE_NO ,A.PARA1_NAME ,A.PARA2_NAME ,
		  '' PARA3_NAME ,''  PARA4_NAME ,''  PARA5_NAME ,''  PARA6_NAME ,
	      CASE WHEN  ISNULL(ART_DET.WS_PRICE,0)>0 THEN ART_DET.WS_PRICE ELSE ART.wholesale_price  END  AS WHOLESALE_PRICE,
		  CASE WHEN  ISNULL(ART_DET.MRP,0)>0 THEN ART_DET.MRP ELSE ART.MRP  END AS MRP,
		  CASE WHEN  ISNULL(ART_DET.purchase_price,0)>0 THEN ART_DET.purchase_price ELSE CASE WHEN ISNULL(ART.purchase_price,0)=0 THEN ART.Gross_purchase_price ELSE ART.purchase_price END   END AS purchase_price,
		  CASE WHEN  ISNULL(ART_DET.purchase_price,0)>0 THEN ART_DET.purchase_price ELSE ART.Gross_purchase_price  END AS Gross_purchase_price,
		   A.HSN_CODE,A.UNQ_ID ,
		   a.ARTICLE_CODE ,
	       ISNULL(A.PARA1_CODE,'0000000') AS PARA1_CODE,
		   ISNULL(A.PARA2_CODE,'0000000') AS PARA2_CODE,
		   '0000000' AS PARA3_CODE,
		  '0000000' AS PARA4_CODE,
		   '0000000' AS PARA5_CODE,
		  '0000000' AS PARA6_CODE,
		   A.SUB_SECTION_NAME ,A.SECTION_NAME ,A.UOM_NAME ,
		   a.DET_UNQ_ID,

		    isnull(a1.attr1_key_name,'') as attr1_key_name,isnull(a2.attr2_key_name,'') as attr2_key_name,isnull(a3.attr3_key_name,'') as attr3_key_name,
		   isnull(a4.attr4_key_name,'') as attr4_key_name,isnull(a5.attr5_key_name,'') as attr5_key_name,isnull(a6.attr6_key_name,'') as attr6_key_name,
		   isnull(a7.attr7_key_name,'') as attr7_key_name,isnull(a8.attr8_key_name,'') as attr8_key_name,isnull(a9.attr9_key_name,'') as attr9_key_name,
		   isnull(a10.attr10_key_name,'') as attr10_key_name,isnull(a11.attr11_key_name,'') as attr11_key_name,isnull(a12.attr12_key_name,'') as attr12_key_name,
		   isnull(a13.attr13_key_name,'') as attr13_key_name,isnull(a14.attr14_key_name,'') as attr14_key_name,isnull(a15.attr15_key_name,'') as attr15_key_name,
		   isnull(a16.attr16_key_name,'') as attr16_key_name,isnull(a17.attr17_key_name,'') as attr17_key_name,isnull(a18.attr18_key_name,'') as attr18_key_name,
		   isnull(a19.attr19_key_name,'') as attr19_key_name,isnull(a20.attr20_key_name,'') as attr20_key_name,isnull(a21.attr21_key_name,'') as attr21_key_name,
		   isnull(a22.attr22_key_name,'') as attr22_key_name,isnull(a23.attr23_key_name,'') as attr23_key_name,isnull(a24.attr24_key_name,'') as attr24_key_name,
		   isnull(a25.attr25_key_name,'') as attr25_key_name
		   ,A.TOL_PER AS tolerance_percentage
		   ,ISNULL(PC.PRODUCT_CODE,'') AS PRODUCT_CODE
	FROM #tmppendingrm A
	JOIN ARTICLE ART (NOLOCK) ON A.ARTICLE_CODE =ART.ARTICLE_CODE 
	LEFT OUTER JOIN #PENDINGBUYERORDER_PC PC ON PC.article_code=ART.article_code
	LEFT JOIN ART_DET (NOLOCK) ON A.article_code =art_det .article_code AND A.para2_code =art_det .para2_code 
	Left join ARTICLE_FIX_ATTR fix_attr(nolock) on fix_attr.article_code =art.article_code 
	LEFT JOIN ATTR1_MST A1 (NOLOCK) ON A1.ATTR1_KEY_CODE=fix_attr.attr1_KEY_CODE      
	LEFT JOIN ATTR2_MST A2 (NOLOCK) ON A2.ATTR2_KEY_CODE=fix_attr.attr2_KEY_CODE      
	LEFT JOIN ATTR3_MST A3 (NOLOCK) ON A3.ATTR3_KEY_CODE=fix_attr.attr3_KEY_CODE      
	LEFT JOIN ATTR4_MST A4 (NOLOCK) ON A4.ATTR4_KEY_CODE=fix_attr.attr4_KEY_CODE      
	LEFT JOIN ATTR5_MST A5 (NOLOCK) ON A5.ATTR5_KEY_CODE=fix_attr.attr5_KEY_CODE      
	LEFT JOIN ATTR6_MST A6 (NOLOCK) ON A6.ATTR6_KEY_CODE=fix_attr.attr6_KEY_CODE      
	LEFT JOIN ATTR7_MST A7 (NOLOCK) ON A7.ATTR7_KEY_CODE=fix_attr.attr7_KEY_CODE      
	LEFT JOIN ATTR8_MST A8 (NOLOCK) ON A8.ATTR8_KEY_CODE=fix_attr.attr8_KEY_CODE      
	LEFT JOIN ATTR9_MST A9 (NOLOCK) ON A9.ATTR9_KEY_CODE=fix_attr.attr9_KEY_CODE      
	LEFT JOIN ATTR10_MST A10 (NOLOCK) ON A10.ATTR10_KEY_CODE=fix_attr.attr10_KEY_CODE      
	LEFT JOIN ATTR11_MST A11 (NOLOCK) ON A11.ATTR11_KEY_CODE=fix_attr.attr11_KEY_CODE      
	LEFT JOIN ATTR12_MST A12 (NOLOCK) ON A12.ATTR12_KEY_CODE=fix_attr.attr12_KEY_CODE      
	LEFT JOIN ATTR13_MST A13 (NOLOCK) ON A13.ATTR13_KEY_CODE=fix_attr.attr13_KEY_CODE      
	LEFT JOIN ATTR14_MST A14 (NOLOCK) ON A14.ATTR14_KEY_CODE=fix_attr.attr14_KEY_CODE      
	LEFT JOIN ATTR15_MST A15 (NOLOCK) ON A15.ATTR15_KEY_CODE=fix_attr.attr15_KEY_CODE      
	LEFT JOIN ATTR16_MST A16 (NOLOCK) ON A16.ATTR16_KEY_CODE=fix_attr.attr16_KEY_CODE      
	LEFT JOIN ATTR17_MST A17 (NOLOCK) ON A17.ATTR17_KEY_CODE=fix_attr.attr17_KEY_CODE      
	LEFT JOIN ATTR18_MST A18 (NOLOCK) ON A18.ATTR18_KEY_CODE=fix_attr.attr18_KEY_CODE      
	LEFT JOIN ATTR19_MST A19 (NOLOCK) ON A19.ATTR19_KEY_CODE=fix_attr.attr19_KEY_CODE      
	LEFT JOIN ATTR20_MST A20 (NOLOCK) ON A20.ATTR20_KEY_CODE=fix_attr.attr20_KEY_CODE      
	LEFT JOIN ATTR21_MST A21 (NOLOCK) ON A21.ATTR21_KEY_CODE=fix_attr.attr21_KEY_CODE      
	LEFT JOIN ATTR22_MST A22 (NOLOCK) ON A22.ATTR22_KEY_CODE=fix_attr.attr22_KEY_CODE      
	LEFT JOIN ATTR23_MST A23 (NOLOCK) ON A23.ATTR23_KEY_CODE=fix_attr.attr23_KEY_CODE      
    LEFT JOIN ATTR24_MST A24 (NOLOCK) ON A24.ATTR24_KEY_CODE=fix_attr.attr24_KEY_CODE      
	LEFT JOIN ATTR25_MST A25 (NOLOCK) ON A25.ATTR25_KEY_CODE=fix_attr.ATTR25_KEY_CODE
	
	
	
	
	

END
