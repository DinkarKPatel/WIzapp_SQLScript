create PROCEDURE SP3S_PENDINGORDER_PICKLIST_DYNAMIC    
(    
 @CWHERE NVARCHAR(MAX)='',    
 @cCurLocId varchar(5)=''    
)    
AS    
BEGIN    
    
 DECLARE @cErrormsg VARCHAR(1000),@cStep varchar(10),@CCMD varchar(max) ,  
         @DONOT_CHKPO_APPROVAL varchar(10)   
    
BEGIN TRY    
 SET @cStep='10'    
    
 PRINT 'Getting data Step#'+@cStep+convert(varchar,getdate(),113)    
 if @cCurLocId=''    
 SELECT TOP 1 @cCurLocId=value FROM config (NOLOCK) WHERE config_option='location_id'    
   
 select @DONOT_CHKPO_APPROVAL=value  from config where config_option='DONOT_CHKPO_APPROVAL'    
 SET @DONOT_CHKPO_APPROVAL=ISNULL(@DONOT_CHKPO_APPROVAL,'')    
    
 SELECT DEPT_ID    
      INTO #TMPLOC    
 FROM LOCATION  (NOLOCK)    
 WHERE 1=2    
 --order pick from all centara lized location as discuss with sir(13062023)    
    
 IF EXISTS (SELECT TOP 1 'U' FROM LOCATION WHERE DEPT_ID =@CCURLOCID AND SERVER_LOC=1)    
 BEGIN    
          
   INSERT INTO #TMPLOC(DEPT_ID)    
   SELECT DEPT_ID FROM LOCATION (NOLOCK) WHERE  SERVER_LOC=1    
    
 END    
 ELSE    
 BEGIN    
      INSERT INTO #TMPLOC(DEPT_ID)    
   SELECT @CCURLOCID DEPT_ID     
    
 END    
    
 PRINT @CWHERE    
 SET @CWHERE=REPLACE(@CWHERE,'`','''')    
    
 SET @cStep='10'     
    
 if object_id ('tempdb..#PENDINGBUYERORDER','u') is not null    
    drop table #PENDINGBUYERORDER    
    
 SELECT CONVERT(VARCHAR(10),'') AC_CODE,AC_NAME ,cast('' as varchar(50)) as Order_id,    
         cast('' as varchar(50)) as Order_No,cast('' as datetime) as Order_dt,    
         CONVERT(VARCHAR(200),'') ARTICLE_NO,CONVERT(VARCHAR(200),'') ARTICLE_NAME,CONVERT(VARCHAR(10),'') ARTICLE_CODE,    
   CONVERT(VARCHAR(9),'') PARA1_CODE,PARA1_NAME,    
   CONVERT(VARCHAR(9),'') PARA2_CODE,para2_name,cast(0 as numeric(10,0)) as Para2_order,    
   CONVERT(VARCHAR(9),'') PARA3_CODE,para3_name,    
   cast(0 as numeric(10,3)) ORDER_QTY,cast(0 as numeric(10,3)) PL_QTY,C.QUANTITY PENDING_PL_QTY,    
   CONVERT(VARCHAR(200),'') SECTION_NAME,CONVERT(VARCHAR(200),'') SUB_SECTION_NAME,    
         CONVERT(VARCHAR(9),'') SECTION_CODE,CONVERT(VARCHAR(9),'') SUB_SECTION_CODE,    
   b.quantity_in_stock stock_qty,CAST(0 AS NUMERIC(10,3)) AS Peding_for_wps    
  INTO #PENDINGBUYERORDER     
  FROM SKU_NAMES A (NOLOCK)    
  JOIN PMT01106 B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE    
  JOIN BUYER_ORDER_DET C (NOLOCK) ON C.PRODUCT_CODE=A.PRODUCT_CODE    
  WHERE 1=2    
    
   SET @cStep='20'     
    
  SET @CCMD=N'SELECT BUYER_ORDER_MST.ORDER_ID,BUYER_ORDER_MST.ORDER_NO,BUYER_ORDER_MST.ORDER_DT, LM01106.AC_CODE,LM01106.AC_NAME,    
              ARTICLE.ARTICLE_NO,ARTICLE.ARTICLE_NAME,ARTICLE.ARTICLE_CODE,    
              PARA1.PARA1_CODE,PARA1.PARA1_NAME,PARA2.PARA2_CODE,PARA2.para2_name,PARA2.Para2_order,    
              PARA3.PARA3_CODE,PARA3.para3_name,    
             SECTIONM.SECTION_NAME,SECTIONM.SECTION_CODE,SECTIONd.SUB_SECTION_NAME,SECTIONd.SUB_SECTION_CODE,    
			 SUM(CASE WHEN XNTYPE=''ORDER'' THEN QTY WHEN XNTYPE=''ORDERSHORTCLOSE'' then -QTY ELSE 0 END) AS ORDER_QTY,    
			 SUM(CASE WHEN XNTYPE=''ORDER'' THEN QTY ELSE -QTY END) AS PENDING_PL_QTY,    
             0 AS STOCK_QTY    
  FROM SALESORDERPROCESSING A (NOLOCK)    
  JOIN BUYER_ORDER_MST (NOLOCK) ON A.RefMemoId = BUYER_ORDER_MST.ORDER_ID    
  JOIN LM01106 (NOLOCK) ON BUYER_ORDER_MST.AC_CODE = LM01106.AC_CODE    
  JOIN ARTICLE (NOLOCK) ON ARTICLE.ARTICLE_CODE = A.ARTICLECODE    
  JOIN PARA1 (NOLOCK) ON PARA1.PARA1_CODE = A.PARA1CODE    
  JOIN PARA2 (NOLOCK) ON PARA2.PARA2_CODE = A.PARA2CODE    
  JOIN PARA3 (NOLOCK) ON PARA3.PARA3_CODE = A.PARA3CODE    
  JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE = ARTICLE.SUB_SECTION_CODE    
  JOIN SECTIONM (NOLOCK) ON SECTIONM.SECTION_CODE = SECTIOND.SECTION_CODE    
  LEFT JOIN ARTICLE_FIX_ATTR ATTR (NOLOCK) ON ATTR.ARTICLE_CODE=A.ARTICLECODE    
  LEFT JOIN ATTR1_MST A1 (NOLOCK) ON A1.ATTR1_KEY_CODE=ATTR.attr1_KEY_CODE          
  LEFT JOIN ATTR2_MST A2 (NOLOCK) ON A2.ATTR2_KEY_CODE=ATTR.attr2_KEY_CODE          
  LEFT JOIN ATTR3_MST A3 (NOLOCK) ON A3.ATTR3_KEY_CODE=ATTR.attr3_KEY_CODE          
  LEFT JOIN ATTR4_MST A4 (NOLOCK) ON A4.ATTR4_KEY_CODE=ATTR.attr4_KEY_CODE          
  LEFT JOIN ATTR5_MST A5 (NOLOCK) ON A5.ATTR5_KEY_CODE=ATTR.attr5_KEY_CODE          
  LEFT JOIN ATTR6_MST A6 (NOLOCK) ON A6.ATTR6_KEY_CODE=ATTR.attr6_KEY_CODE          
  LEFT JOIN ATTR7_MST A7 (NOLOCK) ON A7.ATTR7_KEY_CODE=ATTR.attr7_KEY_CODE         
  LEFT JOIN ATTR8_MST A8 (NOLOCK) ON A8.ATTR8_KEY_CODE=ATTR.attr8_KEY_CODE          
  LEFT JOIN ATTR9_MST A9 (NOLOCK) ON A9.ATTR9_KEY_CODE=ATTR.attr9_KEY_CODE          
  LEFT JOIN ATTR10_MST A10 (NOLOCK) ON A10.ATTR10_KEY_CODE=ATTR.attr10_KEY_CODE          
  LEFT JOIN ATTR11_MST A11 (NOLOCK) ON A11.ATTR11_KEY_CODE=ATTR.attr11_KEY_CODE          
  LEFT JOIN ATTR12_MST A12 (NOLOCK) ON A12.ATTR12_KEY_CODE=ATTR.attr12_KEY_CODE          
  LEFT JOIN ATTR13_MST A13 (NOLOCK) ON A13.ATTR13_KEY_CODE=ATTR.attr13_KEY_CODE          
  LEFT JOIN ATTR14_MST A14 (NOLOCK) ON A14.ATTR14_KEY_CODE=ATTR.attr14_KEY_CODE          
  LEFT JOIN ATTR15_MST A15 (NOLOCK) ON A15.ATTR15_KEY_CODE=ATTR.attr15_KEY_CODE          
  LEFT JOIN ATTR16_MST A16 (NOLOCK) ON A16.ATTR16_KEY_CODE=ATTR.attr16_KEY_CODE          
  LEFT JOIN ATTR17_MST A17 (NOLOCK) ON A17.ATTR17_KEY_CODE=ATTR.attr17_KEY_CODE          
  LEFT JOIN ATTR18_MST A18 (NOLOCK) ON A18.ATTR18_KEY_CODE=ATTR.attr18_KEY_CODE          
  LEFT JOIN ATTR19_MST A19 (NOLOCK) ON A19.ATTR19_KEY_CODE=ATTR.attr19_KEY_CODE          
  LEFT JOIN ATTR20_MST A20 (NOLOCK) ON A20.ATTR20_KEY_CODE=ATTR.attr20_KEY_CODE          
  LEFT JOIN ATTR21_MST A21 (NOLOCK) ON A21.ATTR21_KEY_CODE=ATTR.attr21_KEY_CODE          
  LEFT JOIN ATTR22_MST A22 (NOLOCK) ON A22.ATTR22_KEY_CODE=ATTR.attr22_KEY_CODE          
  LEFT JOIN ATTR23_MST A23 (NOLOCK) ON A23.ATTR23_KEY_CODE=ATTR.attr23_KEY_CODE          
  LEFT JOIN ATTR24_MST A24 (NOLOCK) ON A24.ATTR24_KEY_CODE=ATTR.attr24_KEY_CODE          
  LEFT JOIN ATTR25_MST A25 (NOLOCK) ON A25.ATTR25_KEY_CODE=ATTR.ATTR25_KEY_CODE    
  WHERE WBO_FOR_DEPT_ID in (select dept_id from #TMPLOC)     
  and XNTYPE IN  (''ORDER'',''ORDERPICKLIST'',''ORDERPACKSLIP'',''ORDERINVOICE'',''ORDERSHORTCLOSE'')    
 -- AND BUYER_ORDER_MST.MEMO_TYPE=2   
  AND   (approvedlevelno=99 OR '''+RTRIM(LTRIM(STR(@DONOT_CHKPO_APPROVAL)))+'''=''1'')         
  AND BUYER_ORDER_MST.CANCELLED = 0  AND ISNULL(BUYER_ORDER_MST.Short_close,0) = 0 AND ' +     
  (CASE WHEN ISNULL(@CWHERE,'')='' THEN ' 1=1 ' ELSE ISNULL(@CWHERE,'') END) +    
  'group by BUYER_ORDER_MST.ORDER_ID,LM01106.AC_CODE,BUYER_ORDER_MST.order_no,BUYER_ORDER_MST.order_dt,LM01106.AC_NAME,ARTICLE.ARTICLE_NO,ARTICLE.ARTICLE_NAME,ARTICLE.ARTICLE_CODE,    
   PARA1.PARA1_CODE,PARA1.PARA1_NAME,PARA2.PARA2_CODE,PARA2.para2_name,para2.PARA2_order,    
   PARA3.PARA3_CODE,PARA3.para3_name,SECTIONM.SECTION_NAME,SECTIONM.SECTION_CODE,SECTIONd.SUB_SECTION_NAME,SECTIONd.SUB_SECTION_CODE    
               '    
  PRINT @cCmd    
  INSERT INTO #PENDINGBUYERORDER (order_id,order_no,order_dt,AC_CODE,AC_NAME,ARTICLE_NO,ARTICLE_NAME,ARTICLE_CODE,PARA1_CODE,PARA1_NAME,PARA2_CODE,para2_name,PARA2_order,    
   PARA3_CODE,para3_name,SECTION_NAME,SECTION_CODE,SUB_SECTION_NAME,SUB_SECTION_CODE,ORDER_QTY,PENDING_PL_QTY,stock_qty)    
  EXEC ( @CCMD)    
   
   
   UPDATE A SET PARA1_NAME =(CASE WHEN ISNULL(soPara1,0)=0 THEN 'NA' ELSE A.PARA1_NAME END ),
			    PARA2_NAME =(CASE WHEN ISNULL(soPara2,0)=0 THEN 'NA' ELSE A.PARA2_NAME END ),
			    PARA3_NAME =(CASE WHEN ISNULL(soPara3,0)=0 THEN 'NA' ELSE A.PARA3_NAME END ),

				PARA1_Code =(CASE WHEN ISNULL(soPara1,0)=0 THEN '0000000' ELSE A.PARA1_Code END ),
			    PARA2_CODE =(CASE WHEN ISNULL(soPara2,0)=0 THEN '0000000' ELSE A.PARA2_CODE END ),
			    PARA3_code =(CASE WHEN ISNULL(soPara3,0)=0 THEN '0000000' ELSE A.PARA3_code END )
					
    FROM #PENDINGBUYERORDER A
	JOIN ARTICLE ART (NOLOCK) ON A.ARTICLE_CODE =ART.ARTICLE_CODE 
	JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE =ART.SUB_SECTION_CODE 

      
    
    
    
  SET @cStep='40'     
    
   IF OBJECT_ID ('TEMPDB..#TMPORDERSUMMARY','U') IS NOT NULL    
      DROP TABLE #TMPORDERSUMMARY    
    
    SELECT cast(0 as bit ) as chk,newid() unq_id ,      
     ARTICLE_NO ,para1_name ,para2_name ,Para2_order ,para3_name ,    
     ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE ,para3_code ,stock_qty,    
     sum(a.PENDING_PL_QTY) as pending_pl_qty,    
     cast(0 as numeric(10,3)) as current_pl_qty_total,    
     sum(Peding_for_wps) as Peding_for_wps    
    into #tmporderSummary    
    FROM #PENDINGBUYERORDER a    
    group by ARTICLE_NO ,para1_name ,para2_name,para3_name ,Para2_order ,    
       ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE,para3_code ,stock_qty    
    having sum(a.PENDING_PL_QTY)>0    
    
      
   
 ;WITH CTE_PENDINGPL AS    
 (    
  SELECT A.ARTICLECODE ,
         PARA1Code =(CASE WHEN ISNULL(soPara1,0)=0 THEN '0000000' ELSE A.PARA1Code END ),
		 PARA2CODE =(CASE WHEN ISNULL(soPara2,0)=0 THEN '0000000' ELSE A.PARA2CODE END ),
		 PARA3code =(CASE WHEN ISNULL(soPara3,0)=0 THEN '0000000' ELSE A.PARA3code END ) ,
         SUM(CASE WHEN XNTYPE='PICKLIST' THEN QTY ELSE -QTY END) AS Peding_for_wps      
  FROM SALESORDERPROCESSING A (nolock)    
  JOIN PLM01106 B ON A.REFMEMOID =B.MEMO_ID    
  JOIN ARTICLE ART (NOLOCK) ON A.ARTICLECODE =ART.ARTICLE_CODE 
  JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE =ART.SUB_SECTION_CODE 

  JOIN (  
  SELECT ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE ,PARA3_CODE  FROM #tmporderSummary   
  GROUP BY ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE ,PARA3_CODE   
  ) C ON a.ARTICLECODE =C.ARTICLE_CODE   and a.Para1Code =c.PARA1_CODE and a.Para2Code =c.PARA2_CODE and a.Para3Code =c.PARA3_CODE   
  WHERE A.XNTYPE IN('PICKLIST','PLPACKSLIP','PLShortClose')    
  and isnull(B.ORDER_ID,'')<>'' AND B.location_code=@CCURLOCID  and CANCELLED =0  
  GROUP BY A.ARTICLECODE ,
  (CASE WHEN ISNULL(soPara1,0)=0 THEN '0000000' ELSE A.PARA1Code END ),
  (CASE WHEN ISNULL(soPara2,0)=0 THEN '0000000' ELSE A.PARA2CODE END ),
  (CASE WHEN ISNULL(soPara3,0)=0 THEN '0000000' ELSE A.PARA3code END )

  )  
    
  
  Update a set Peding_for_wps=b.Peding_for_wps from #tmporderSummary A  
  join CTE_PENDINGPL b on a.ARTICLE_CODE =b.ArticleCode and a.PARA1_CODE =b.Para1Code and a.PARA2_CODE =b.Para2Code   
  and a.PARA3_CODE =b.Para3Code   
    
    
        
   SET @cStep='50'     
    
    ;with cte_stock as     
    (    
    select  a.ARTICLE_CODE ,a.PARA1_CODE ,a.PARA2_CODE ,a.PARA3_CODE ,isnull(Peding_for_wps,0) as Peding_for_wps,    
           sum(c.quantity_in_stock) as quantity_in_stock    
    from #TMPORDERSUMMARY A    
	JOIN ARTICLE ART (NOLOCK) ON A.ARTICLE_CODE =ART.ARTICLE_CODE 
    JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE =ART.SUB_SECTION_CODE 
    JOIN SKU B (NOLOCK) ON A.ARTICLE_CODE =B.ARTICLE_CODE 
	                      AND A.PARA1_CODE =(CASE WHEN ISNULL(soPara1,0)=0 THEN '0000000' ELSE b.PARA1_Code END )  
						  AND A.PARA2_CODE =(CASE WHEN ISNULL(soPara2,0)=0 THEN '0000000' ELSE b.PARA2_Code END )  
						  AND A.PARA3_CODE =(CASE WHEN ISNULL(soPara3,0)=0 THEN '0000000' ELSE b.PARA3_Code END )     
    join pmt01106 c (nolock) on b.product_code =c.product_code     
    where c.quantity_in_stock <>0 and c.BIN_ID <>'999' and c.dept_id=@cCurLocId    
    group by a.ARTICLE_CODE ,a.PARA1_CODE ,a.PARA2_CODE ,a.PARA3_CODE,isnull(Peding_for_wps,0)    
    )    
    
    Update a set stock_qty =b.quantity_in_stock-isnull(b.Peding_for_wps,0)      
    from #tmporderSummary a    
    join cte_stock b on a.ARTICLE_CODE =b.article_code and a.PARA1_CODE =b.para1_code  and a.PARA2_CODE =b.para2_code and a.PARA3_CODE =b.para3_code     
        
    SET @cStep='60'     
    
     SELECT a.chk,a.unq_id ,      
     ARTICLE_NO ,para1_name ,para2_name ,Para2_order as size_order ,para3_name ,    
     ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE ,para3_code ,stock_qty,    
     a.pending_pl_qty,    
     a.current_pl_qty_total     
     FROM #TMPORDERSUMMARY A    
     order by a.ARTICLE_NO ,a.para1_name ,a.Para2_order  ,a.para2_name   
    
     SELECT cast(0 as bit) as chk, b.unq_id ,    
            AC_CODE ,AC_NAME as Customer_name ,    
      A.order_dt as order_dt,    
      a.Order_No  as order_no ,    
      cast('' as varchar(100))  as Ord_row_id ,    
      a.Order_id  as Order_id ,    
      a.ARTICLE_NO ,a.para1_name ,a.para2_name  ,    
      a.order_qty,a.pending_pl_qty , cast(0 as numeric(10,3)) as current_pl_qty,a.para3_name,    
      a.ARTICLE_CODE ,a.PARA1_CODE ,a.PARA2_CODE ,a.PARA3_CODE ,    
      cast(0 as numeric(10,3)) as PL_inv_qty    
     FROM #PENDINGBUYERORDER A    
     join #TMPORDERSUMMARY b on a.ARTICLE_CODE =b.article_code and a.PARA1_CODE =b.para1_code    
  and a.PARA2_CODE =b.para2_code and a.PARA3_CODE =b.para3_code     
     WHERE a.pending_pl_qty >0    
    
    
    
  GOTO END_PROC     
END TRY    
BEGIN CATCH    
 SET @cErrormsg='Error in Procedure SP3S_PENDINGORDER_PICKLIST_DYNAMIC at Step#'+@cStep+' '+ERROR_MESSAGE()    
 GOTO END_PROC    
END CATCH    
    
END_PROC:    
 SELECT ISNULL(@cErrormsg,'') errmsg    
END  
  
  