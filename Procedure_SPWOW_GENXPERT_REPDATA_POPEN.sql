create PROCEDURE SPWOW_GENXPERT_REPDATA_POPEN
@cRepTempTable VARCHAR(400),  
@dFromDt DATETIME,  
@dToDt DATETIME,  
@cHoLocId VARCHAR(5)='',  
@bCalledfromStkAnalysis BIT=0  
AS  
BEGIN  
 DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cBaseExprOutput VARCHAR(MAX),  
 @cGrpCols VARCHAR(MAX), @cLayoutCols VARCHAR(MAX),@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX),@nLoop INT,  
 @cGitTable VARCHAR(200),@cPiJoin varchar(2000)   
   
  
   --drop table if exists  #tmporderreport  
    
     
 SELECT B.PO_ID,  REFROWID REFMEMOID ,B.PRODUCT_CODE , ARTICLE_CODE ARTICLECODE ,PARA1_CODE PARA1CODE ,PARA2_CODE PARA2CODE ,PARA3_CODE  PARA3CODE,  
 PARA4_CODE PARA4CODE,PARA5_CODE PARA5CODE,B.purchase_price purchaseprice ,B.Mrp ,B.wholesale_price as wsp,  
    SUM(CASE WHEN A.XNTYPE='PURCHASEORDER' THEN QTY ELSE 0 END ) AS OrderQtyIncT,  
    SUM(CASE WHEN A.XNTYPE='PURCHASEINVOICE' THEN QTY ELSE 0 END ) AS plInvoiceQty,  
    SUM(CASE WHEN A.XNTYPE='POADJUSTMENT' THEN QTY ELSE 0 END ) AS ADJQTY,  
    SUM(CASE WHEN A.XNTYPE='PURCHASEORDER' THEN B.quantity ELSE qty*-1 END ) AS pendingOrderQty,  
    SUM(CASE WHEN A.XNTYPE='PURCHASEORDER' THEN B.quantity  ELSE 0 END ) AS OrderQty,  
    CAST(0 as numeric(10,3)) as ExcessQty,   
    SUM(CASE WHEN A.XNTYPE='POSHORTCLOSE' THEN QTY ELSE 0 END ) as ShortCloseQty,
    SUM(CASE WHEN A.XNTYPE='GRN' THEN QTY ELSE 0 END ) AS GRNQty  
   INTO #TMPPOREPORT  
 FROM PURCHASEORDERPROCESSINGNEW A WITH (NOLOCK)  
 JOIN POD01106 B (NOLOCK) ON A.REFROWID =B.ROW_ID    
 join pom01106 pom (nolock) on b.po_id =pom.po_id  
 WHERE  XNTYPE IN('PURCHASEORDER','PURCHASEINVOICE','POADJUSTMENT','POSHORTCLOSE','GRN')  
 AND QTY>0 and po_dt between  @dFromDt and @dToDt   
 GROUP BY B.PO_ID, REFROWID,B.PRODUCT_CODE,ARTICLE_CODE ,PARA1_CODE ,  
 PARA2_CODE,PARA3_CODE,PARA4_CODE,PARA5_CODE,  
 B.purchase_price  ,B.Mrp,B.wholesale_price  
   
 --rate revised master display on the Reports  
 UPDATE A SET ARTICLECODE =B.ARTICLE_CODE  ,PARA1CODE=B.PARA1_CODE ,  
 PARA2CODE =B.PARA2_CODE ,PARA3CODE =B.PARA3_CODE   
 FROM #TMPPOREPORT A  
 JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE   
 WHERE (A.ARTICLECODE <>B.ARTICLE_CODE OR A.PARA1CODE  <>B.PARA1_CODE  OR   
        A.PARA2CODE <>B.PARA2_CODE OR A.PARA3CODE <>B.PARA3_CODE )  
 and b.product_code <>''  
   
   
 --  
 
   
 Update #TMPPOREPORT set ExcessQty =ABS(pendingOrderQty),pendingOrderQty=0 where pendingOrderQty<0  
    set @cPiJoin=''  
    IF EXISTS (SELECT TOP 1 'U' FROM #WOW_XPERT_REP_DET   
            WHERE COLUMN_ID IN('C1322','C1323','C1324','C1438'))  
    begin  
          
        SELECT A.REFMEMOID , PIM01106.BILL_NO ,PIM01106.BILL_DT,PIM01106.MRR_NO ,  
               PIM01106.MRR_DT  
             into #tmppim  
        FROM #TMPPOREPORT A  
        JOIN PURCHASEORDERPROCESSINGNEW B (NOLOCK) ON A.REFMEMOID=B.REFROWID   
        JOIN PID01106 (NOLOCK) ON B.ROWID =PID01106 .ROW_ID   
        JOIN PIM01106 (NOLOCK) ON PIM01106 .MRR_ID =PID01106 .MRR_ID   
        WHERE B.XNTYPE ='PURCHASEINVOICE'  
        group by A.REFMEMOID , PIM01106.BILL_NO ,PIM01106.BILL_DT,PIM01106.MRR_NO ,  
        PIM01106.MRR_DT   
          
        set @cPiJoin=' Left join #tmppim pim on pim.REFMEMOID =#TMPPOREPORT.REFMEMOID  '  
      
    end  
   
 --#tmporderreport  
  
 SELECT @cBaseExpr='[LAYOUT_COLS]   from #TMPPOREPORT (NOLOCK)         
 JOIN article (NOLOCK) ON article.article_code=#TMPPOREPORT.articleCode  
 JOIN para1 (NOLOCK) ON para1.para1_code=#TMPPOREPORT.para1Code  
 JOIN para2 (NOLOCK) ON para2.para2_code=#TMPPOREPORT.para2Code  
 JOIN para3 (NOLOCK) ON para3.para3_code=#TMPPOREPORT.para3Code  
 JOIN para4 (NOLOCK) ON para4.para4_code=#TMPPOREPORT.para4Code  
 JOIN para5 (NOLOCK) ON para5.para5_code=#TMPPOREPORT.para5Code   
 JOIN   art_names (NOLOCK) ON art_names.article_code=#TMPPOREPORT.articlecode  
 left outer JOIN   sku_names (NOLOCK) ON sku_names.product_code=#TMPPOREPORT.product_code  
 JOIN pom01106 (NOLOCK) ON pom01106.PO_id=#TMPPOREPORT.po_id   
 Left Outer JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=pom01106.ac_code  
 Left outer JOIN Hd01106 supplier_Hdd on supplier_Hdd.head_code = supplier_lm01106.Head_code  
 Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=SKU_NAMES.ac_code  
 Left Outer  JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code  
 Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code  
 Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code   
 LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=1  
 LEFT OUTER JOIN lm01106 party_lm01106 on party_lm01106.ac_code=pom01106.ac_code  
 Left Outer JOIN lmp01106 party_lmp01106 on party_lmp01106.ac_code=pom01106.ac_code  
    Left Outer  JOIN area  party_area on party_lmp01106.area_code=party_area.area_code  
 Left Outer  JOIN city  party_city on party_city.city_code=party_area.city_code  
 Left Outer  JOIN state  party_state on party_state.state_code=party_city.state_code  
 JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id=pom01106.dept_id  
 JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id=pom01106.dept_id  
 LEFT OUTER JOIN location TargetLocation on TargetLocation.dept_id=pom01106.dept_id/*left(pom01106.po_id,2)*//*Rohit 05-11-2024*/  
 LEFT OUTER JOIN area  TargetLocation_area on TargetLocation.area_code=TargetLocation_area.area_code  
 LEFT OUTER  JOIN city  TargetLocation_city on TargetLocation_city.city_code=TargetLocation_area.city_code  
 LEFT OUTER JOIN state  TargetLocation_state on TargetLocation_state.state_code=TargetLocation_city.state_code  
 LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=pom01106.SHIPPING_FROM_AC_CODE  
 LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=pom01106.SHIPPING_FROM_AC_CODE  
 LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code  
 LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code  
 LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code  
 LEFT JOIN lm01106 Broker_lm01106 on Broker_lm01106.ac_code=party_lmp01106.BROKER_AC_CODE  
 LEFT OUTER JOIN users  ON POM01106.USER_CODE= USERS.USER_CODE  
 left outer JOIN bin SourceBin on SourceBin.bin_id=''000''  
 LEFT OUTER JOIN EMPLOYEE (NOLOCK) ON pom01106.PO_EMP_CODE = EMPLOYEE.EMP_CODE  
 LEFT OUTER JOIN PO_TYPE_MST ON POM01106.PO_TYPE_ID= PO_TYPE_MST.PO_TYPE_ID '+  
 @cPiJoin+  
 ' WHERE [WHERE]  group by [GROUPBY] '  
  
 EXEC SPWOW_GETXPERT_INSCOLS  
 @cXntype='POPEN',  
 @dFromDt=@dFromDt,  
 @dToDt=@dToDt,  
 @cHoLocId=@cHoLocId,  
 @cBaseExprInput=@cBaseExpr,  
 @cInsCols=@cInsCols OUTPUT,  
 @cBaseExprOutput=@cBaseExprOutput OUTPUT  
  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'Sku_Names.SECTION_NAME','ART_NAMES.SECTION_NAME')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'Sku_Names.SUB_SECTION_NAME','ART_NAMES.SUB_SECTION_NAME')  
 
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'Sku_Names.ARTICLE_NO','Article.Article_No')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'Sku_Names.ARTICLE_NAME','Article.Article_NAME')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA1_name','para1.para1_name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA1_ALIAS','para1.ALIAS')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA2_name','para2.para2_name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA2_ALIAS','para2.ALIAS')  
    Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA3_name','para3.para3_name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA3_ALIAS','para3.ALIAS')  
    Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA4_name','para4.para4_name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA4_ALIAS','para4.ALIAS')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA5_name','para5.para5_name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.PARA5_ALIAS','para5.ALIAS')  
 
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.AC_NAME','supplier_lm01106.ac_name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.SUPPLIER_ALIAS','supplier_lm01106.alias')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.OEM_AC_NAME','oem_supplier_lm01106.ac_name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.ATTR1_KEY_NAME','ART_NAMES.Attr1_Key_Name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.ATTR2_KEY_NAME','ART_NAMES.Attr2_Key_Name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.ATTR3_KEY_NAME','ART_NAMES.Attr3_Key_Name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.ATTR4_KEY_NAME','ART_NAMES.Attr4_Key_Name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.ATTR5_KEY_NAME','ART_NAMES.Attr5_Key_Name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.ATTR6_KEY_NAME','ART_NAMES.Attr6_Key_Name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.ATTR7_KEY_NAME','ART_NAMES.Attr7_Key_Name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.ATTR8_KEY_NAME','ART_NAMES.Attr8_Key_Name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.ATTR9_KEY_NAME','ART_NAMES.Attr9_Key_Name')  
 Set @cBaseExprOutput= REPLACE(@cBaseExprOutput,'SKU_NAMES.ATTR10_KEY_NAME','ART_NAMES.Attr10_Key_Name')  
   
  
  
  
 SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')  
    SELECT '+@cBaseExprOutput  
  
 PRINT @cCmd  
 EXEC SP_EXECUTESQL @cCmd  
END  
  
  