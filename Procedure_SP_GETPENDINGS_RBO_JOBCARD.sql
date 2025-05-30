CREATE PROCEDURE SP_GETPENDINGS_RBO_JOBCARD  
(  
  @CMEMO_TYPE  NUMERIC(5)=0,  
  @CCUSTCODE   VARCHAR(50)='',  
  @CDEPT_ID   VARCHAR(5)='',  
  @CUSERCODE   VARCHAR(10)='',  
  @CBINID   VARCHAR(7)='000' ,
  @cOrderID		VARCHAR(50)=''
 )  
 AS  
 BEGIN  

 ;WITH ADJUSTED_PO  
 AS  
 (  
	  SELECT '' ref_order_id,a.PRODUCT_CODE ,SUM(a.QUANTITY) AS ADJ_QTY  
	  FROM pod01106 A (NOLOCK)  
	  JOIN pom01106 B (NOLOCK) ON B.po_id=A.po_id  
	  join WSL_ORDER_DET c (nolock) on a.wod_row_id =c.row_id   
	  join WSL_ORDER_MST d (nolock) on c.order_id =d.order_id   
	  WHERE  B.CANCELLED=0 and d.CANCELLED =0  
	  AND (@CCUSTCODE='' OR (@CMEMO_TYPE=1 AND d.CUSTOMER_CODE=@CCUSTCODE)  
	  OR (@CMEMO_TYPE=2 AND b.AC_CODE=@CCUSTCODE)) 
	  AND (@cOrderID='' OR @cOrderID=d.order_id)
	  GROUP BY c.order_id,a.PRODUCT_CODE   
	  HAVING SUM(a.QUANTITY) >0  
 )  
 ,ADJUSTED_JC
 AS  
 (  
	  SELECT '' ref_order_id,BC.PRODUCT_CODE ,SUM(a.QUANTITY) AS ADJ_QTY  
	  FROM ORD_PLAN_DET A (NOLOCK)  
	  JOIN ORD_PLAN_MST B (NOLOCK) ON B.MEMO_ID=A.MEMO_ID  
	  JOIN ORD_PLAN_BARCODE_DET BC (NOLOCK) ON BC.REFROW_ID=A.ROW_ID
	  join WSL_ORDER_DET c (nolock) on a.RBO_ROW_ID =c.row_id   
	  join WSL_ORDER_MST d (nolock) on c.order_id =d.order_id   
	  WHERE  B.CANCELLED=0 and d.CANCELLED =0  
	  AND (@CCUSTCODE='' OR (@CMEMO_TYPE=1 AND d.CUSTOMER_CODE=@CCUSTCODE)  
	  OR (@CMEMO_TYPE=2 AND b.AC_CODE=@CCUSTCODE)) 
	  AND (@cOrderID='' OR @cOrderID=d.order_id)
	  GROUP BY c.order_id,bc.PRODUCT_CODE   
	  HAVING SUM(a.QUANTITY) >0  
 )  
 ,ALL_ORDERS  
 AS  
 (  
  SELECT(CASE WHEN B.CUSTOMER_CODE = '000000000000' THEN B.AC_CODE ELSE C.CUSTOMER_CODE END) AS CUSTOMER_CODE1,  
        A.product_code product_code1,  
  B.REF_NO,order_dt,order_no,B.sale_emp_code mst_emp_code,A.*,  
  ISNULL(C.CUSTOMER_FNAME,'')+' '+ISNULL(C.customer_lname,'') AS Customer_Name ,C.user_customer_code,B.trail_dt,B.DELIVERY_DT  
  FROM WSL_ORDER_DET A(NOLOCK)  
  JOIN WSL_ORDER_MST B(NOLOCK) ON A.ORDER_ID = B.ORDER_ID  
  LEFT OUTER JOIN CUSTDYM C(NOLOCK) ON B.CUSTOMER_CODE = C.CUSTOMER_CODE  
  LEFT OUTER JOIN LM01106 D(NOLOCK) ON B.AC_CODE = D.AC_CODE  
  WHERE B.CANCELLED = 0 and isnull(A.cancelled,0)= 0  
  AND (@CCUSTCODE='' OR (@CMEMO_TYPE=1 AND B.CUSTOMER_CODE=@CCUSTCODE)  
  OR (@CMEMO_TYPE=2 AND B.AC_CODE=@CCUSTCODE ))  
  AND (@cOrderID='' OR @cOrderID=B.order_id)
  and isnull(a.order_type ,0)<>1 and a.product_code<>''
 )   

 
   
 SELECT CONVERT(BIT,0) AS CHKITEM,A.ORDER_ID AS MEMO_ID,a.PRODUCT_CODE1 PRODUCT_CODE,A.QUANTITY AS [TOTAL_QTY],    
 CONVERT(NUMERIC(14,2),0) AS [RET_QTY],  
 A.QUANTITY-ISNULL(B.ADJ_QTY,0) AS BALANCE_QUANTITY,        
 A.gross_wsp  MRP,a.ws_price AS TEMPMRP,CONVERT(NUMERIC(14,2),((A.ws_price/A.QUANTITY)*(A.QUANTITY-ISNULL(B.ADJ_QTY,0)))) AS [NET],
 --as discuss with sir Rate discount & new always pick retail buyer order(06072023)
 A.order_no  MEMO_NO,A.order_dt MEMO_DT,        
 A.ROW_ID,A.EMP_CODE,A.RFNET,E.ARTICLE_NO,             
 F.PARA1_CODE,F.PARA1_NAME , G.PARA2_CODE , G.PARA2_NAME,H.SUB_SECTION_NAME, I.SECTION_NAME,        
 J.DT_CREATED AS PARA3_DT_CREATED,J.PARA3_NAME,  e.FIX_MRP,'' PRODUCT_NAME,      
 P4.PARA4_NAME,P5.PARA5_NAME,P6.PARA6_NAME,UOM.UOM_TYPE       
 ,A.EMP_CODE,A.ROW_ID AS APD_ROW_ID        
 ,EMP.EMP_NAME,UOM.UOM_NAME,CONVERT(BIT,0) AS FREEZED,  
 A.DISCOUNT_PERCENTAGE,CONVERT(NUMERIC(14,2),((A.DISCOUNT_AMOUNT/A.QUANTITY)*(A.QUANTITY-ISNULL(B.ADJ_QTY,0)))) AS [DISCOUNT_AMOUNT]  
 ,A.Customer_Name,A.user_customer_code,A.trail_dt,A.DELIVERY_DT,A.Ref_no,A.CUSTOMER_CODE1 AS CUSTOMER_CODE ,E.article_code 
 FROM ALL_ORDERS A  
 LEFT OUTER JOIN ADJUSTED_PO B ON  B.PRODUCT_CODE=A.product_code1   
 LEFT OUTER JOIN ADJUSTED_JC JC ON  JC.PRODUCT_CODE=A.product_code1   
 JOIN ARTICLE E (NOLOCK) ON a.ARTICLE_CODE = E.ARTICLE_CODE  
 JOIN SECTIOND H (NOLOCK) ON E.SUB_SECTION_CODE = H.SUB_SECTION_CODE             
 JOIN SECTIONM I (NOLOCK) ON H.SECTION_CODE = I.SECTION_CODE      
 JOIN PARA1 F (NOLOCK) ON a.PARA1_CODE = F.PARA1_CODE             
 JOIN PARA2 G (NOLOCK) ON a.PARA2_CODE = G.PARA2_CODE             
 JOIN PARA3 J (NOLOCK) ON a.PARA3_CODE = J.PARA3_CODE       
 JOIN PARA4 P4 (NOLOCK) ON P4.PARA4_CODE = a.PARA4_CODE       
 JOIN PARA5 P5 (NOLOCK) ON P5.PARA5_CODE = a.PARA5_CODE       
 JOIN PARA6 P6 (NOLOCK) ON P6.PARA6_CODE = a.PARA6_CODE       
 JOIN UOM (NOLOCK) ON E.UOM_CODE = UOM.UOM_CODE       
 LEFT OUTER JOIN EMPLOYEE EMP  (NOLOCK) ON A.EMP_CODE = EMP.EMP_CODE    
 WHERE ( (A.QUANTITY-(ISNULL(B.ADJ_QTY,0)+ISNULL(JC.ADJ_QTY,0)))>0  )
-- and a.order_id ='0101124000000101000127'

END