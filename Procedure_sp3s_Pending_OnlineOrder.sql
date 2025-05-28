create Procedure sp3s_Pending_OnlineOrder
(
  @NMODE INT=1,
  @CDEPT_ID VARCHAR(5)='',
  @CORDER_ID VARCHAR(50)='',
  @cspid varchar(50)=''
)
as
begin

         DECLARE @CLOCGSTSTATE VARCHAR(2)
	     SELECT @CLOCGSTSTATE=gst_state_code FROM LOCATION (nolock) WHERE DEPT_ID=@CDEPT_ID

		IF OBJECT_ID('TEMPDB..#CMMORDER','U') IS NOT NULL
	       	  DROP TABLE #CMMORDER

		IF OBJECT_ID('TEMPDB..#TMPRPSFINALMST','U') IS NOT NULL
	       	  DROP TABLE #TMPRPSFINALMST


         SELECT REF_ORDER_ID 
		 INTO #CMMORDER
		 FROM cmd01106 A (NOLOCK)
		 JOIN CMM01106 B (NOLOCK) ON A.cm_id=B.CM_ID 
		 WHERE ISNULL(A.REF_ORDER_ID,'')<>'' AND CANCELLED=0
		 and (@corder_id='' or REF_ORDER_ID=@corder_id)
		 GROUP BY REF_ORDER_ID 


		
	 
	      SELECT A.order_no AS CM_NO ,A.order_id CM_ID ,A.ORDER_DT AS CM_DT ,LM.AC_NAME ,
		         A.SHIPPING_MOBILE as mobile,
				 CASE WHEN ISNULL(A.SHIPPING_MOBILE,'')<>'' THEN  A.SHIPPING_MOBILE ELSE SHIPPING_EMAIL END  as User_customer_code,
				 a.SHIPPING_FNAME as CUSTOMER_FNAME,a.SHIPPING_LNAME as CUSTOMER_LNAME,
				ISNULL(A.shipping_Address3,'') AS address0,ISNULL(A.shipping_Address,'') AS address1,ISNULL(A.shipping_address2,'') AS address2,
				A.shipping_area_code as area_code ,A.shipping_pin as pin,cast('000000000000' as varchar(50)) CUSTOMER_CODE,
				A.shipping_area_name as area,A.shipping_city_name as City,shipping_state_name as state ,
				cast(a.other_charges  as numeric(14,2)) as atd_charges,cast(0 as numeric(8,2)) mrp_wsp,
				cast(0 as int) as CM_MODE,cast(0 as numeric(14,2))  SUBTOTAL,cast(0 as numeric(14,2))  NET_AMOUNT,
				cast(0 as bit) CANCELLED,cast('' as varchar(10)) as USER_CODE,getdate() as LAST_UPDATE,getdate() as cm_time,
				cast('' as varchar(50))  as ref_cm_id,cast('' as varchar(10))  fin_year,
				cast(0 as numeric(8,2))	DISCOUNT_PERCENTAGE,cast(0 as numeric(8,2))	DISCOUNT_AMOUNT,
				cast('' as varchar(1000)) 	REMARKS,cast(0 as numeric(8,2))	Manual_discount,CAST('000' AS VARCHAR(7)) as BIN_ID,
				cast(0 as numeric(8,0))	total_quantity,isnull(A.SaleReturnType,1) as  SaleReturnType,
				(case when A.SaleReturnType =2 then 'Sale Return' else  'Sale' End) as OrderType,A.Tendermode,
                shipping_company as company_name,shipping_email as email,shipping_GSTIN cus_gst_no,
				CASE WHEN ISNULL(SHIPPING_GSTIN,'')<>'' THEN LEFT(SHIPPING_GSTIN,2) 
				     WHEN ISNULL(SHIPPING_GST_STATE_CODE,'')<>'' THEN SHIPPING_GST_STATE_CODE 
				ELSE isnull(gm.gst_state_code,@CLOCGSTSTATE)  END cus_gst_state,
				CAST('' AS VARCHAR(10)) AS city_Code,CAST('' AS VARCHAR(10)) AS state_CODE,CAST('' AS VARCHAR(10)) AS address9,
				a.Ref_no 
		   INTO #TMPRPSFINALMST
		  FROM BUYER_ORDER_MST A (NOLOCK)
		  LEFT JOIN #CMMORDER CMM (NOLOCK) ON A.ORDER_ID =CMM.REF_ORDER_ID 
		  JOIN LM01106 LM (NOLOCK) ON A.AC_CODE =LM.AC_CODE 
		  left join gst_state_mst gm on gm.gst_state_name =a.shipping_state_name
		  WHERE MODE=3 AND A.CANCELLED =0 and cmm.REF_ORDER_ID is null
		  and case when isnull(a.WBO_FOR_DEPT_ID,'')<>'' then WBO_FOR_DEPT_ID     else A.location_Code  end =@CDEPT_ID 
		  and  (@corder_id='' or a.order_id=@corder_id)

		 SELECT BM.cm_no AS CM_NO ,Bd.order_id CM_ID ,BM.cm_dt AS CM_DT,Bd.order_id  ,bm.LAST_UPDATE AS RPS_LAST_UPDATE, 
			CAST('' AS VARCHAR(50)) AS EMP_NAME,D.ARTICLE_NO,D.ARTICLE_CODE,D.ARTICLE_NAME,
			P1.PARA1_NAME,P2.PARA2_NAME,P3.PARA3_NAME,P4.PARA4_NAME,P5.PARA5_NAME,P6.PARA6_NAME,
			P1.PARA1_CODE,P2.PARA2_CODE,P3.PARA3_CODE,P4.PARA4_CODE,P5.PARA5_CODE,P6.PARA6_CODE,p7.PARA7_CODE ,
			U.UOM_NAME,U.UOM_CODE,d.coding_scheme AS CODING_SCHEME,D.INACTIVE,d.PURCHASE_PRICE,bd.WS_PRICE,
			E.SUB_SECTION_NAME,F.SECTION_NAME,U.UOM_TYPE,P3.DT_CREATED AS PARA3_DT_CREATED,D.DT_CREATED AS ART_DT_CREATED,
			''  AS SKU_DT_CREATED,D.STOCK_NA, CAST(0 AS BIT) AS SALERETURN ,CAST(0 AS BIT) AS CREDIT_REFUND,
			CAST('' AS VARCHAR(50))  AS EMP_NAME1 ,CAST('' AS VARCHAR(50))   AS EMP_NAME2 ,cast('' as varchar(100)) AS HOLD_ID,cast('' as varchar(100)) AS CMD_HOLD_ROW_ID,
			'N' AS [HOLD_FOR_ALTER_TXT],CONVERT(NUMERIC(6,2),0) AS LAST_SLS_DISCOUNT_PERCENTAGE,d.HSN_CODE,cast(0 as numeric(8,0)) rfnet,
			0 tax_type,1 as tax_method,cast('' as varchar(100)) PRODUCT_CODE,
			CASE WHEN BM.SALERETURNTYPE=1 THEN  1 ELSE -1 END AS QUANTITY,bd.ws_price MRP,
			(CASE WHEN BM.SALERETURNTYPE=1 THEN 1 ELSE -1 END)* bd.ws_price  NET,
			cast(0 as numeric(14,2)) as discount_percentage,cast(0 as numeric(14,2)) as discount_amount,cast('LATER' as varchar(50)) AS ROW_ID,0 as tax_percentage,0 as tax_amount,
			cast('' as varchar(50)) slsdet_row_id,@CDEPT_ID dept_id,cast('' as varchar(50)) as ITEM_DESC,0 as Manual_discount,
			ROW_NUMBER() OVER (ORDER BY bd.order_id) SR_NO,ROW_NUMBER() OVER (ORDER BY bd.order_id) SRNO,
			cast('0000000' as varchar(10))  emp_code,cast('0000000' as varchar(10))  EMP_CODE1,cast('0000000' as varchar(10))  EMP_CODE2,
			cast(0 as bit) as Hold_for_Alter,CAST('000' AS VARCHAR(7)) BIN_ID,
			0 as FOC_QUANTITY,cast(0 as numeric(14,2)) as basic_discount_percentage,cast(0 as numeric(14,2)) as card_discount_percentage,
			cast(0 as numeric(14,2)) as basic_discount_amount,cast(0 as numeric(14,2)) as card_discount_amount,
			cast('' as varchar(50)) ref_sls_memo_no,cast('' as datetime) as ref_sls_memo_dt,
			Bd.order_id AS REF_ORDER_ID,
			p7.PARA7_NAME,bm.SALERETURNTYPE
			into #TMPRPSFINALDET
			FROM  #TMPRPSFINALMST bm 
			join buyer_order_det bd (nolock) on bm.CM_ID=bd.order_id
			JOIN ARTICLE D (NOLOCK) ON bd.ARTICLE_CODE = D.ARTICLE_CODE
			JOIN PARA1 P1 (NOLOCK)  ON bd.PARA1_CODE = P1.PARA1_CODE
			JOIN PARA2 P2 (NOLOCK)  ON bd.PARA2_CODE = P2.PARA2_CODE
			JOIN PARA3 P3 (NOLOCK)  ON bd.PARA3_CODE = P3.PARA3_CODE
			JOIN PARA4 P4 (NOLOCK)  ON bd.PARA4_CODE = P4.PARA4_CODE
			JOIN PARA5 P5 (NOLOCK)  ON bd.PARA5_CODE = P5.PARA5_CODE
			JOIN PARA6 P6 (NOLOCK)  ON bd.PARA6_CODE = P6.PARA6_CODE
			left JOIN PARA7 P7 (NOLOCK)  ON bd.PARA7_CODE = P7.PARA7_CODE
			JOIN UOM U (NOLOCK) ON U.UOM_CODE = D.UOM_CODE
			JOIN SECTIOND E (NOLOCK)  ON D.SUB_SECTION_CODE = E.SUB_SECTION_CODE
			JOIN SECTIONM F (NOLOCK)  ON F.SECTION_CODE = E.SECTION_CODE
	        where 1=2
		
	   declare @cAUTO_ALLOCATE_ONLINE_ORDERS varchar(5),@CERRMSG varchar(1000)
	   select @cAUTO_ALLOCATE_ONLINE_ORDERS=value  from config where config_option='AUTO_ALLOCATE_ONLINE_ORDERS'
	
	
	
	   if isnull(@cAUTO_ALLOCATE_ONLINE_ORDERS,'')='1'
	   begin
	          
			 
			select a.row_id ,a.quantity ,a.gross_wsp ,a.ws_price ,a.article_code ,a.para1_code ,a.para2_code ,a.para3_code ,a.PARA4_CODE ,
			       a.PARA5_CODE, a.PARA6_CODE,a.order_id,a.para7_code
				   into #TMPORDER
			from BUYER_ORDER_DET A (nolock)
			join #TMPRPSFINALMST b on a.order_id=b.cm_id 

			;with QTYcte as
			(
			  select row_id, quantity ,1 as srNo
			  from #TMPORDER
			  union all
			  select row_id,quantity ,SrNo=srNo+1
			  from QTYcte
			  where SrNo <quantity
			)

			select * into #tmpNormalize from QTYcte

				
			insert into #TMPRPSFINALDET (CM_NO,CM_ID,CM_DT,order_id,RPS_LAST_UPDATE,EMP_NAME,ARTICLE_NO,ARTICLE_CODE,
			ARTICLE_NAME,PARA1_NAME,PARA2_NAME,PARA3_NAME,PARA4_NAME,PARA5_NAME,PARA6_NAME,PARA1_CODE,PARA2_CODE,PARA3_CODE,
			PARA4_CODE,PARA5_CODE,PARA6_CODE,PARA7_CODE,UOM_NAME,UOM_CODE,CODING_SCHEME,INACTIVE,PURCHASE_PRICE,WS_PRICE,
			SUB_SECTION_NAME,SECTION_NAME,UOM_TYPE,PARA3_DT_CREATED,ART_DT_CREATED,SKU_DT_CREATED,STOCK_NA,SALERETURN,
			CREDIT_REFUND,EMP_NAME1,EMP_NAME2,HOLD_ID,CMD_HOLD_ROW_ID,HOLD_FOR_ALTER_TXT,LAST_SLS_DISCOUNT_PERCENTAGE,
			HSN_CODE,rfnet,tax_type,tax_method,PRODUCT_CODE,QUANTITY,MRP,NET,discount_percentage,discount_amount,
			ROW_ID,tax_percentage,tax_amount,slsdet_row_id,dept_id,ITEM_DESC,Manual_discount,SR_NO,SRNO,emp_code,
			EMP_CODE1,EMP_CODE2,Hold_for_Alter,BIN_ID,FOC_QUANTITY,basic_discount_percentage,card_discount_percentage,
			basic_discount_amount,card_discount_amount,ref_sls_memo_no,ref_sls_memo_dt,REF_ORDER_ID,PARA7_NAME,SALERETURNTYPE)

	      SELECT BM.cm_no AS CM_NO ,Bd.order_id CM_ID ,BM.cm_dt AS CM_DT,Bd.order_id  ,bm.LAST_UPDATE AS RPS_LAST_UPDATE, 
			CAST('' AS VARCHAR(50)) AS EMP_NAME,D.ARTICLE_NO,D.ARTICLE_CODE,D.ARTICLE_NAME,
			P1.PARA1_NAME,P2.PARA2_NAME,P3.PARA3_NAME,P4.PARA4_NAME,P5.PARA5_NAME,P6.PARA6_NAME,
			P1.PARA1_CODE,P2.PARA2_CODE,P3.PARA3_CODE,P4.PARA4_CODE,P5.PARA5_CODE,P6.PARA6_CODE,p7.PARA7_CODE ,
			U.UOM_NAME,U.UOM_CODE,d.coding_scheme AS CODING_SCHEME,D.INACTIVE,d.PURCHASE_PRICE,bd.WS_PRICE,
			E.SUB_SECTION_NAME,F.SECTION_NAME,U.UOM_TYPE,P3.DT_CREATED AS PARA3_DT_CREATED,D.DT_CREATED AS ART_DT_CREATED,
			''  AS SKU_DT_CREATED,D.STOCK_NA, CAST(0 AS BIT) AS SALERETURN ,CAST(0 AS BIT) AS CREDIT_REFUND,
			CAST('' AS VARCHAR(50))  AS EMP_NAME1 ,CAST('' AS VARCHAR(50))   AS EMP_NAME2 ,cast('' as varchar(100)) AS HOLD_ID,cast('' as varchar(100)) AS CMD_HOLD_ROW_ID,
			'N' AS [HOLD_FOR_ALTER_TXT],CONVERT(NUMERIC(6,2),0) AS LAST_SLS_DISCOUNT_PERCENTAGE,d.HSN_CODE,cast(0 as numeric(8,0)) rfnet,
			0 tax_type,1 as tax_method,cast('' as varchar(100)) PRODUCT_CODE,
			CASE WHEN BM.SALERETURNTYPE=1 THEN  1 ELSE -1 END AS QUANTITY,bd.ws_price MRP,
			(CASE WHEN BM.SALERETURNTYPE=1 THEN 1 ELSE -1 END)* bd.ws_price  NET,
			cast(0 as numeric(14,2)) as discount_percentage,cast(0 as numeric(14,2)) as discount_amount,cast('LATER' as varchar(50)) AS ROW_ID,0 as tax_percentage,0 as tax_amount,
			cast('' as varchar(50)) slsdet_row_id,@CDEPT_ID dept_id,cast('' as varchar(50)) as ITEM_DESC,0 as Manual_discount,
			ROW_NUMBER() OVER (ORDER BY bd.order_id) SR_NO,ROW_NUMBER() OVER (ORDER BY bd.order_id) SRNO,
			cast('0000000' as varchar(10))  emp_code,cast('0000000' as varchar(10))  EMP_CODE1,cast('0000000' as varchar(10))  EMP_CODE2,
			cast(0 as bit) as Hold_for_Alter,'000' BIN_ID,
			0 as FOC_QUANTITY,cast(0 as numeric(14,2)) as basic_discount_percentage,cast(0 as numeric(14,2)) as card_discount_percentage,
			cast(0 as numeric(14,2)) as basic_discount_amount,cast(0 as numeric(14,2)) as card_discount_amount,
			cast('' as varchar(50)) ref_sls_memo_no,cast('' as datetime) as ref_sls_memo_dt,
			Bd.order_id AS REF_ORDER_ID,
			p7.PARA7_NAME,bm.SALERETURNTYPE
			FROM  #TMPRPSFINALMST bm 
			join #TMPORDER bd (nolock) on bm.CM_ID=bd.order_id
			join #tmpNormalize nord on bd.row_id =nord.row_id
			JOIN ARTICLE D (NOLOCK) ON bd.ARTICLE_CODE = D.ARTICLE_CODE
			JOIN PARA1 P1 (NOLOCK)  ON bd.PARA1_CODE = P1.PARA1_CODE
			JOIN PARA2 P2 (NOLOCK)  ON bd.PARA2_CODE = P2.PARA2_CODE
			JOIN PARA3 P3 (NOLOCK)  ON bd.PARA3_CODE = P3.PARA3_CODE
			JOIN PARA4 P4 (NOLOCK)  ON bd.PARA4_CODE = P4.PARA4_CODE
			JOIN PARA5 P5 (NOLOCK)  ON bd.PARA5_CODE = P5.PARA5_CODE
			JOIN PARA6 P6 (NOLOCK)  ON bd.PARA6_CODE = P6.PARA6_CODE
			left JOIN PARA7 P7 (NOLOCK)  ON bd.PARA7_CODE = P7.PARA7_CODE
			JOIN UOM U (NOLOCK) ON U.UOM_CODE = D.UOM_CODE
			JOIN SECTIOND E (NOLOCK)  ON D.SUB_SECTION_CODE = E.SUB_SECTION_CODE
			JOIN SECTIONM F (NOLOCK)  ON F.SECTION_CODE = E.SECTION_CODE
	     
	

	   end
	   Else
	   begin
 
	

	      insert into #TMPRPSFINALDET (CM_NO,CM_ID,CM_DT,order_id,RPS_LAST_UPDATE,EMP_NAME,ARTICLE_NO,ARTICLE_CODE,
			ARTICLE_NAME,PARA1_NAME,PARA2_NAME,PARA3_NAME,PARA4_NAME,PARA5_NAME,PARA6_NAME,PARA1_CODE,PARA2_CODE,PARA3_CODE,
			PARA4_CODE,PARA5_CODE,PARA6_CODE,PARA7_CODE,UOM_NAME,UOM_CODE,CODING_SCHEME,INACTIVE,PURCHASE_PRICE,WS_PRICE,
			SUB_SECTION_NAME,SECTION_NAME,UOM_TYPE,PARA3_DT_CREATED,ART_DT_CREATED,SKU_DT_CREATED,STOCK_NA,SALERETURN,
			CREDIT_REFUND,EMP_NAME1,EMP_NAME2,HOLD_ID,CMD_HOLD_ROW_ID,HOLD_FOR_ALTER_TXT,LAST_SLS_DISCOUNT_PERCENTAGE,
			HSN_CODE,rfnet,tax_type,tax_method,PRODUCT_CODE,QUANTITY,MRP,NET,discount_percentage,discount_amount,
			ROW_ID,tax_percentage,tax_amount,slsdet_row_id,dept_id,ITEM_DESC,Manual_discount,SR_NO,SRNO,emp_code,
			EMP_CODE1,EMP_CODE2,Hold_for_Alter,BIN_ID,FOC_QUANTITY,basic_discount_percentage,card_discount_percentage,
			basic_discount_amount,card_discount_amount,ref_sls_memo_no,ref_sls_memo_dt,REF_ORDER_ID,PARA7_NAME,SALERETURNTYPE)

			SELECT BM.order_no AS CM_NO ,BM.order_id CM_ID ,BM.ORDER_DT AS CM_DT,BM.order_id  ,bm.LAST_UPDATE AS RPS_LAST_UPDATE, 
			CAST('' AS VARCHAR(50)) AS EMP_NAME,D.ARTICLE_NO,D.ARTICLE_CODE,D.ARTICLE_NAME,
			P1.PARA1_NAME,P2.PARA2_NAME,P3.PARA3_NAME,P4.PARA4_NAME,P5.PARA5_NAME,P6.PARA6_NAME,
			P1.PARA1_CODE,P2.PARA2_CODE,P3.PARA3_CODE,P4.PARA4_CODE,P5.PARA5_CODE,P6.PARA6_CODE,p7.PARA7_CODE ,
			U.UOM_NAME,U.UOM_CODE,C.BARCODE_CODING_SCHEME AS CODING_SCHEME,D.INACTIVE,C.PURCHASE_PRICE,C.WS_PRICE,
			E.SUB_SECTION_NAME,F.SECTION_NAME,U.UOM_TYPE,P3.DT_CREATED AS PARA3_DT_CREATED,D.DT_CREATED AS ART_DT_CREATED,
			isnull(C.DT_CREATED,'') AS SKU_DT_CREATED,D.STOCK_NA, CAST(0 AS BIT) AS SALERETURN ,CAST(0 AS BIT) AS CREDIT_REFUND,
			CAST('' AS VARCHAR(50))  AS EMP_NAME1 ,CAST('' AS VARCHAR(50))   AS EMP_NAME2 ,cast('' as varchar(100)) AS HOLD_ID,cast('' as varchar(100)) AS CMD_HOLD_ROW_ID,
			'N' AS [HOLD_FOR_ALTER_TXT],CONVERT(NUMERIC(6,2),0) AS LAST_SLS_DISCOUNT_PERCENTAGE,C.HSN_CODE,cast(0 as numeric(8,0)) rfnet,
			0 tax_type,1 as tax_method,pmt.PRODUCT_CODE,
			CASE WHEN BM.SALERETURNTYPE=1 THEN  PMT.QUANTITY_IN_STOCK ELSE -1 END AS QUANTITY,c.MRP,
			(CASE WHEN BM.SALERETURNTYPE=1 THEN 1 ELSE -1 END)* C.MRP  NET,
			cast(0 as numeric(14,2)) as discount_percentage,cast(0 as numeric(14,2)) as discount_amount,cast('LATER' as varchar(50)) AS ROW_ID,0 as tax_percentage,0 as tax_amount,
			cast('' as varchar(50)) slsdet_row_id,bm.dept_id,cast('' as varchar(50)) as ITEM_DESC,0 as Manual_discount,
			ROW_NUMBER() OVER (ORDER BY bm.order_id) SR_NO,ROW_NUMBER() OVER (ORDER BY bm.order_id) SRNO,
			cast('0000000' as varchar(10))  emp_code,cast('0000000' as varchar(10))  EMP_CODE1,cast('0000000' as varchar(10))  EMP_CODE2,
			cast(0 as bit) as Hold_for_Alter,pmt.BIN_ID,
			0 as FOC_QUANTITY,cast(0 as numeric(14,2)) as basic_discount_percentage,cast(0 as numeric(14,2)) as card_discount_percentage,
			cast(0 as numeric(14,2)) as basic_discount_amount,cast(0 as numeric(14,2)) as card_discount_amount,
			cast('' as varchar(50)) ref_sls_memo_no,cast('' as datetime) as ref_sls_memo_dt,
			BM.order_id AS REF_ORDER_ID,
			p7.PARA7_NAME,bm.SALERETURNTYPE
			--INTO #TMPRPSFINALDET 
			FROM  SKU C(NOLOCK) 
			join pmt01106 pmt (nolock) on c.product_code =pmt.product_code  and pmt.DEPT_ID =@CDEPT_ID
			join buyer_order_mst bm (nolock) on bm.order_id =isnull(pmt.bo_order_id,'')
			LEFT JOIN #CMMORDER CMM (NOLOCK) ON bm.ORDER_ID =CMM.REF_ORDER_ID 
			JOIN ARTICLE D (NOLOCK) ON C.ARTICLE_CODE = D.ARTICLE_CODE
			JOIN PARA1 P1 (NOLOCK)  ON C.PARA1_CODE = P1.PARA1_CODE
			JOIN PARA2 P2 (NOLOCK)  ON C.PARA2_CODE = P2.PARA2_CODE
			JOIN PARA3 P3 (NOLOCK)  ON C.PARA3_CODE = P3.PARA3_CODE
			JOIN PARA4 P4 (NOLOCK)  ON C.PARA4_CODE = P4.PARA4_CODE
			JOIN PARA5 P5 (NOLOCK)  ON C.PARA5_CODE = P5.PARA5_CODE
			JOIN PARA6 P6 (NOLOCK)  ON C.PARA6_CODE = P6.PARA6_CODE
			left JOIN PARA7 P7 (NOLOCK)  ON C.PARA7_CODE = P7.PARA7_CODE
			JOIN UOM U (NOLOCK) ON U.UOM_CODE = D.UOM_CODE
			JOIN SECTIOND E (NOLOCK)  ON D.SUB_SECTION_CODE = E.SUB_SECTION_CODE
			JOIN SECTIONM F (NOLOCK)  ON F.SECTION_CODE = E.SECTION_CODE
			WHERE bm.MODE=3 AND bm.CANCELLED =0 and cmm.REF_ORDER_ID is null
			and  (@corder_id='' or bm.order_id=@corder_id)
	        
		
		end

		
		--if exists (select top 1 'u' from #TMPRPSFINALMST where SaleReturnType =2)
		--begin


		--    --Query Optimization required
		--	   SELECT SLR_order_id, a.product_code,a.REF_ORDER_ID ,a.bin_id,left(a.cm_id,2) as Dept_id,CM_NO as ref_sls_memo_no,CM_DT as ref_sls_memo_dt
		--			into #TmpSale
		--	   FROM CMD01106 A
		--	   JOIN CMM01106 B ON A.CM_ID=B.CM_ID
		--	   join
		--	   (
	    
		--	   SELECT A.order_id as Order_id ,b.cm_id  as SLR_order_id
		--	   FROM BUYER_ORDER_MST A with (nolock)
		--	   join #TMPRPSFINALMST b on CASE WHEN ISNULL(A.SHIPPING_MOBILE,'')<>'' THEN  A.SHIPPING_MOBILE ELSE a.SHIPPING_EMAIL END=b.User_customer_code
		--							 and a.SHIPPING_FNAME=b.CUSTOMER_FNAME and a.SHIPPING_LNAME=b.CUSTOMER_lNAME
		--							 and a.shipping_pin=b.pin
		--	   WHERE Mode=3 
		--	   and a.SaleReturnType=1  and b.SaleReturnType=2
		--	   and a.cancelled=0
		--	   group by A.order_id,b.cm_id
		--	   )  c on a.REF_ORDER_ID=c.order_id
		--	   where b.cancelled=0 and isnull(a.REF_ORDER_ID,'')<>''


		--	  UPDATE A SET REF_SLS_MEMO_NO=B.REF_SLS_MEMO_NO ,
		--				   REF_SLS_MEMO_DT=B.REF_SLS_MEMO_DT
		--	  FROM #TMPRPSFINALDET A
		--	   JOIN #TMPSALE B ON A.CM_ID =B.SLR_order_id AND A.PRODUCT_CODE =B.PRODUCT_CODE


	 --  end
	   
        
		 --Pick Mrp and net from Buyer order 
	    DECLARE @CCONFIGCOLS VARCHAR(MAX),@DTSQL NVARCHAR(MAX)

		  SET @cConfigCols='  a.PARA7_NAME=sn.PARA7_NAME '  
    
		
					
           -- as Per discussion in SLR qty only Negative and net always Positive
		   -- buyer order me discount nahi aayega
		   --(CASE WHEN a.QUATITY<0 THE -1 ELSE 1 END)
		set @DTSQL=N'update a SET NET=(A.QUANTITY * SN.WS_PRICE)
		   FROM #TMPRPSFINALDET A  
		   JOIN   
		   (  
			SELECT b.product_code,  B.ORDER_ID,B.WS_PRICE as WS_PRICE,B.GROSS_WSP,B.DISCOUNT_PERCENTAGE,B.DISCOUNT_AMOUNT,
			        Art.article_no,p1.para1_name,p2.para2_name,p3.para3_name,p4.para4_name,p5.para5_name,p6.para6_name,p7.para7_name,sd.sub_section_name,sm.section_name
			FROM BUYER_ORDER_DET B   
			JOIN BUYER_ORDER_MST C ON C.ORDER_ID=B.ORDER_ID  
			JOIN ARTICLE ART ON ART.ARTICLE_CODE=B.ARTICLE_CODE  
			JOIN SECTIOND SD ON ART.SUB_SECTION_CODE =SD.SUB_SECTION_CODE  
			JOIN SECTIONM SM ON SD.section_code  =SM.SECTION_CODE  
			LEFT JOIN PARA1 P1 ON P1.PARA1_CODE=B.PARA1_CODE  
			LEFT JOIN PARA2 P2 ON P2.PARA2_CODE=B.PARA2_CODE  
			LEFT JOIN PARA3 P3 ON P3.PARA3_CODE=B.PARA3_CODE  
			LEFT JOIN PARA4 P4 ON P4.PARA4_CODE=B.PARA4_CODE  
			LEFT JOIN PARA5 P5 ON P5.PARA5_CODE=B.PARA5_CODE  
			LEFT JOIN PARA6 P6 ON P6.PARA6_CODE=B.PARA6_CODE  
			LEFT JOIN PARA7 P7 ON P7.PARA7_CODE=B.PARA7_CODE  
		   ) SN ON a.order_id=sn.order_id  AND '+@cConfigCols+'  
       
		   '    
		PRINT @DTSQL  
		EXEC SP_EXECUTESQL @DTSQL  
  

		set @DTSQL=N'update a set NET_AMOUNT=round(sn.NET,0)+isnull(a.atd_charges,0)
		   FROM #TMPRPSFINALMST A  
		   JOIN   
		   (  
			SELECT cm_id, SUM(NET) AS NET FROM        #TMPRPSFINALDET GROUP BY cm_id
		   ) SN ON a.cm_id=sn.cm_id'    
		PRINT @DTSQL  
		EXEC SP_EXECUTESQL @DTSQL  

		
		update #TMPRPSFINALDET set discount_amount =(MRP*QUANTITY)-((case when quantity >0 then 1 else -1 end)* ABS(NET))
		update #TMPRPSFINALDET set discount_percentage  =abs(discount_amount*100/ (MRP*QUANTITY)) where (MRP*QUANTITY) <>0
		
		

	--end Rate Picking 
	if isnull(@corder_id,'')=''
	begin
		SELECT * FROM #TMPRPSFINALMST
 		ORDER BY CM_DT,CM_NO ,CM_ID 

		SELECT * FROM #TMPRPSFINALDET
 		ORDER BY SRNO
	end
	else
	begin
	     DELETE A FROM SLS_IMPORT_DATA A WITH (NOLOCK) WHERE SP_ID=@CSPID

		 INSERT SLS_IMPORT_DATA ( BIN_ID, cancelled,  dept_id, memo_dt, memo_no, MRP, net, product_code, quantity, row_id, SP_ID,
		 errormsg,CMD_DISCOUNT_AMOUNT,CMD_DISCOUNT_PERCENTAGE  )  
		 select a.BIN_ID,0 cancelled, @CDEPT_ID dept_id,
		 CASE WHEN SALERETURNTYPE=1 THEN '' ELSE ref_sls_memo_dt END memo_dt, 
		 CASE WHEN SALERETURNTYPE=1 THEN '' ELSE REF_SLS_MEMO_NO END memo_no, 
		 MRP,NET , 
		 a.product_code,                
         quantity, newid() row_id, @cspid SP_ID,
		 CASE WHEN SALERETURNTYPE=1 AND A.QUANTITY<ISNULL(B.QUANTITY_IN_STOCK,0) THEN 'STOCK GOING NEGATIVE' ELSE '' END,
		 a.discount_amount,a.discount_percentage
		 FROM #TMPRPSFINALDET A
		 LEFT JOIN PMT01106 B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.DEPT_ID =B.DEPT_ID AND A.ORDER_ID =B.BO_ORDER_ID
		
		 
     end

   END_PROC:
end

