create PROC [DBO].SP_JOBWORK_RECIEVE_2                      
@NQUERYID INT,                        
@CWHERE NVARCHAR(4000)='',          
@NMODE INT=0,  
@BWIP BIT=0,  
@NISSUE_MODE BIT=0,  
@cLocID VARCHAR(5)=''  
AS                        
BEGIN     
--(dinkar) Replace  left(memoid,2) to Location_code 
  
declare @SHOW_PRODUCT_CODE_IN_PRD varchar(10)
select @SHOW_PRODUCT_CODE_IN_PRD=value  from config where config_option='SHOW_PRODUCT_CODE_IN_PRD'

	if exists (select top 1 'u' FROM JOBWORK_RECEIPT_MST (NOLOCK) WHERE RECEIPT_ID = @CWHERE and wip=1 and isnull(Receive_Mode,0)=0)
	begin
      

	  		 SELECT (CAST(1 AS BIT)) AS CHKDELIVER , B.*,        
				 B.QUANTITY AS RECEIVE_QUNATITY,         
				 CONVERT(NUMERIC(10,2), 0) AS BALANCE_QUANTITY,         
				 CONVERT(NUMERIC(10,2),0) AS PENDING_QUANTITY,        
				 M.QUANTITY AS ISSUE_QUANTITY,     
				 B.ROW_ID AS TMP_ROW_ID,       
				 (B.QUANTITY * B.JOB_RATE) AS AMOUNT, ART.ARTICLE_NO, ART.ARTICLE_NAME,           
				 PARA1_NAME,PARA2_NAME,PARA3_NAME,e.uom_name as UOM_NAME,3 CODING_SCHEME,CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,      
				 pmt.BASE_PRICE as PURCHASE_PRICE,0 MRP,0 WS_PRICE,   sm.SECTION_NAME, sd.SUB_SECTION_NAME,               
				 PARA4_NAME,PARA5_NAME,PARA6_NAME,e.uom_code,e.uom_type AS [UOM_TYPE],            
				 '' AS [ART_DT_CREATED],'' AS [PARA3_DT_CREATED],      
				 '' AS [SKU_DT_CREATED],            
				 0 as STOCK_NA,F.JOB_NAME, A.RECEIPT_NO ,      
				 O.ISSUE_NO,'' AS ARTICLE_ALIAS,BI.BIN_NAME,A.REMARKS ,M.REMARKS AS [ISSUE_REMARKS]   
				 ,B.MERCHANT_NAME,B.BUYER_NAME  
				 ,AT1.attr1_key_name,AT2.attr2_key_name,AT3.attr3_key_name,AT4.attr4_key_name,AT5.attr5_key_name,AT6.attr6_key_name,    
					AT7.attr7_key_name,AT8.attr8_key_name,AT9.attr9_key_name,AT10.attr10_key_name,AT11.attr11_key_name,AT12.attr12_key_name,    
					AT13.attr13_key_name,AT14.attr14_key_name,AT15.attr15_key_name,AT16.attr16_key_name,AT17.attr17_key_name,AT18.attr18_key_name,    
					AT19.attr19_key_name,AT20.attr20_key_name,AT21.attr21_key_name,AT22.attr22_key_name,AT23.attr23_key_name,AT24.attr24_key_name,    
					AT25.attr25_key_name     ,  dm.design_no,b.row_id as old_row_id
				 FROM JOBWORK_RECEIPT_MST A (NOLOCK)                           
				 JOIN JOBWORK_RECEIPT_DET B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID                         
				 JOIN JOBWORK_ISSUE_DET M (NOLOCK) ON M.ROW_ID = B.REF_ROW_ID          
				 JOIN JOBWORK_ISSUE_MST O (NOLOCK) ON O.ISSUE_ID = M.ISSUE_ID   
				 JOIN WIP_PMT PMT (NOLOCK) ON PMT.PRODUCT_CODE=B.PRODUCT_CODE    
				JOIN ARTICLE ART (NOLOCK) ON PMT.article_Code = ART.article_Code 
				JOIN SECTIOND SD (NOLOCK) ON ART.SUB_SECTION_CODE = SD.SUB_SECTION_CODE 
				JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE
				JOIN PARA1 P1 (NOLOCK) ON pmt.PARA1_CODE = P1.PARA1_CODE          
				JOIN PARA2 P2 (NOLOCK) ON pmt.PARA2_CODE = P2.PARA2_CODE          
				JOIN PARA3 P3 (NOLOCK) ON pmt.PARA3_CODE = P3.PARA3_CODE          
				JOIN PARA4 P4 (NOLOCK) ON pmt.PARA4_CODE = P4.PARA4_CODE          
				JOIN PARA5 P5 (NOLOCK) ON pmt.PARA5_CODE = P5.PARA5_CODE          
				JOIN PARA6 P6 (NOLOCK) ON pmt.PARA6_CODE = P6.PARA6_CODE                            
				JOIN UOM E (NOLOCK) ON ART.UOM_CODE = E.UOM_CODE           
				JOIN JOBS F (NOLOCK) ON F.JOB_CODE = M.JOB_CODE       
				JOIN BIN BI (NOLOCK) ON BI.BIN_ID = B.BIN_ID     
				left outer JOIN designm dm (NOLOCK) ON m.design_code =dm.design_code   
				LEFT OUTER JOIN article_fix_attr ATTR  (NOLOCK) ON ART.article_code = ATTR.ARTICLE_CODE     
				LEFT OUTER JOIN attr1_mst at1 (NOLOCK) ON at1.attr1_key_code=ATTR.attr1_key_code    
				LEFT OUTER JOIN attr2_mst at2 (NOLOCK) ON at2.attr2_key_code=ATTR.attr2_key_code    
				LEFT OUTER JOIN attr3_mst at3 (NOLOCK) ON at3.attr3_key_code=ATTR.attr3_key_code    
				LEFT OUTER JOIN attr4_mst at4 (NOLOCK) ON at4.attr4_key_code=ATTR.attr4_key_code    
				LEFT OUTER JOIN attr5_mst at5 (NOLOCK) ON at5.attr5_key_code=ATTR.attr5_key_code    
				LEFT OUTER JOIN attr6_mst at6 (NOLOCK) ON at6.attr6_key_code=ATTR.attr6_key_code    
				LEFT OUTER JOIN attr7_mst at7 (NOLOCK) ON at7.attr7_key_code=ATTR.attr7_key_code    
				LEFT OUTER JOIN attr8_mst at8 (NOLOCK) ON at8.attr8_key_code=ATTR.attr8_key_code    
				LEFT OUTER JOIN attr9_mst at9 (NOLOCK) ON at9.attr9_key_code=ATTR.attr9_key_code    
				LEFT OUTER JOIN attr10_mst at10 (NOLOCK) ON at10.attr10_key_code=ATTR.attr10_key_code    
				LEFT OUTER JOIN attr11_mst at11 (NOLOCK) ON at11.attr11_key_code=ATTR.attr11_key_code    
				LEFT OUTER JOIN attr12_mst at12 (NOLOCK) ON at12.attr12_key_code=ATTR.attr12_key_code    
				LEFT OUTER JOIN attr13_mst at13 (NOLOCK) ON at13.attr13_key_code=ATTR.attr13_key_code    
				LEFT OUTER JOIN attr14_mst at14 (NOLOCK) ON at14.attr14_key_code=ATTR.attr14_key_code    
				LEFT OUTER JOIN attr15_mst at15 (NOLOCK) ON at15.attr15_key_code=ATTR.attr15_key_code    
				LEFT OUTER JOIN attr16_mst at16 (NOLOCK) ON at16.attr16_key_code=ATTR.attr16_key_code    
				LEFT OUTER JOIN attr17_mst at17 (NOLOCK) ON at17.attr17_key_code=ATTR.attr17_key_code    
				LEFT OUTER JOIN attr18_mst at18 (NOLOCK) ON at18.attr18_key_code=ATTR.attr18_key_code    
				LEFT OUTER JOIN attr19_mst at19 (NOLOCK) ON at19.attr19_key_code=ATTR.attr19_key_code    
				LEFT OUTER JOIN attr20_mst at20 (NOLOCK) ON at20.attr20_key_code=ATTR.attr20_key_code    
				LEFT OUTER JOIN attr21_mst at21 (NOLOCK) ON at21.attr21_key_code=ATTR.attr21_key_code    
				LEFT OUTER JOIN attr22_mst at22 (NOLOCK) ON at22.attr22_key_code=ATTR.attr22_key_code    
				LEFT OUTER JOIN attr23_mst at23 (NOLOCK) ON at23.attr23_key_code=ATTR.attr23_key_code    
				LEFT OUTER JOIN attr24_mst at24 (NOLOCK) ON at24.attr24_key_code=ATTR.attr24_key_code    
				LEFT OUTER JOIN attr25_mst at25(NOLOCK) ON at25.attr25_key_code=ATTR.attr25_key_code    
				 WHERE A.RECEIPT_ID= @CWHERE                        
				 order by art.article_no ,p1.para1_name ,p2.para2_order  


	end
	else
	begin


	if isnull(@SHOW_PRODUCT_CODE_IN_PRD,'')='1'OR  ((SELECT ISNULL(receive_mode,0) FROM JOBWORK_RECEIPT_MST (NOLOCK) WHERE RECEIPT_ID = @CWHERE)<>1)
	begin


			 SELECT (CAST(1 AS BIT)) AS CHKDELIVER , B.*,        
			 B.QUANTITY AS RECEIVE_QUNATITY,         
			 CONVERT(NUMERIC(10,2), 0) AS BALANCE_QUANTITY,         
			 CONVERT(NUMERIC(10,2),0) AS PENDING_QUANTITY,        
			 M.QUANTITY AS ISSUE_QUANTITY,     
			 B.ROW_ID AS TMP_ROW_ID,       
			 (B.QUANTITY * B.JOB_RATE) AS AMOUNT, sn.ARTICLE_NO, sn.ARTICLE_NAME,           
			 PARA1_NAME,PARA2_NAME,PARA3_NAME,e.uom_name as UOM_NAME,3 CODING_SCHEME,CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,      
			 sn.pp as PURCHASE_PRICE,sn.MRP,sn.WS_PRICE,   sn.SECTION_NAME, sn.SUB_SECTION_NAME,               
			 PARA4_NAME,PARA5_NAME,PARA6_NAME,e.uom_code,e.uom_type AS [UOM_TYPE],            
			 '' AS [ART_DT_CREATED],'' AS [PARA3_DT_CREATED],      
			 '' AS [SKU_DT_CREATED],            
			 0 as STOCK_NA,F.JOB_NAME, A.RECEIPT_NO ,      
			 O.ISSUE_NO,'' AS ARTICLE_ALIAS,BI.BIN_NAME,A.REMARKS ,M.REMARKS AS [ISSUE_REMARKS]   
			 ,B.MERCHANT_NAME,B.BUYER_NAME  
			 ,sn.attr1_key_name,sn.attr2_key_name,sn.attr3_key_name,sn.attr4_key_name,sn.attr5_key_name,sn.attr6_key_name,  
			   sn.attr7_key_name,sn.attr8_key_name,sn.attr9_key_name,sn.attr10_key_name,sn.attr11_key_name,sn.attr12_key_name,  
			   sn.attr13_key_name,sn.attr14_key_name,sn.attr15_key_name,sn.attr16_key_name,sn.attr17_key_name,sn.attr18_key_name,  
			   sn.attr19_key_name,sn.attr20_key_name,sn.attr21_key_name,sn.attr22_key_name,sn.attr23_key_name,sn.attr24_key_name,  
			 sn.attr25_key_name    ,  dm.design_no,b.row_id as old_row_id,JPMT.Trading_Product_code
			 FROM JOBWORK_RECEIPT_MST A (NOLOCK)                           
			 JOIN JOBWORK_RECEIPT_DET B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID                         
			 JOIN JOBWORK_ISSUE_DET M (NOLOCK) ON M.ROW_ID = B.REF_ROW_ID          
			 JOIN JOBWORK_ISSUE_MST O (NOLOCK) ON O.ISSUE_ID = M.ISSUE_ID   
			 join sku_names sn (nolock) on sn.product_Code =b.product_code                
			 JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=M.PRODUCT_CODE          
			 JOIN ARTICLE ART (NOLOCK) ON SKU.ARTICLE_CODE = ART.ARTICLE_CODE              
			 JOIN UOM E (NOLOCK) ON ART.UOM_CODE = E.UOM_CODE           
			 JOIN JOBS F (NOLOCK) ON F.JOB_CODE = M.JOB_CODE       
			 JOIN BIN BI (NOLOCK) ON BI.BIN_ID = B.BIN_ID     
			left outer JOIN designm dm (NOLOCK) ON m.design_code =dm.design_code    
			LEFT OUTER JOIN JOBWORK_PMT JPMT (NOLOCK) ON JPMT.PRODUCT_CODE=B.product_code
			 WHERE A.RECEIPT_ID= @CWHERE                        
			 order by sn.article_no ,sn.para1_name ,sn.para2_order  
 
	 end 
	 else
	 begin
      

	  
			 SELECT (CAST(1 AS BIT)) AS CHKDELIVER,    
			 'List' as product_code,sum(b.quantity) as quantity,sum(b.SHRINK_QTY) as SHRINK_QTY,
			 B.JOB_RATE as job_rate,
			 CAST('LATER'+sku.ARTICLE_CODE +sku.PARA1_CODE +sku.PARA2_CODE AS VARCHAR(40)) as row_id,
			 b.PRINT_LABEL,b.receipt_id,b.no_hrs,b.REMARKS,
			 '' as ref_row_id,b.BIN_ID,b.WIP_UID,b.PREV_JOB_RATE,b.JOB_CODE
			,b.hsn_code,b.gst_percentage,
			sum(b.igst_amount) as igst_amount,
			sum(b.cgst_amount) as cgst_amount,
			sum(b.sgst_amount) as sgst_amount,
			sum(b.xn_value_without_gst) as xn_value_without_gst,
			sum(b.xn_value_with_gst) as xn_value_with_gst,
			sum(b.JWRDISCOUNTAMOUNT) as JWRDISCOUNTAMOUNT,
			sum(b.CESS_AMOUNT) as CESS_AMOUNT,
			b.Gst_Cess_Percentage,
			sum(b.Gst_Cess_Amount) as Gst_Cess_Amount,  
			sum(B.QUANTITY) AS RECEIVE_QUNATITY,              
			 sum(M.QUANTITY) AS ISSUE_QUANTITY,     
			 '' AS TMP_ROW_ID,       
			 cast(sum(B.QUANTITY * B.JOB_RATE) as numeric(14,2)) AS AMOUNT, sn.ARTICLE_NO, sn.ARTICLE_NAME,           
			 PARA1_NAME,PARA2_NAME,PARA3_NAME,e.uom_name as UOM_NAME,3 CODING_SCHEME,CONVERT(NUMERIC(10,2),0) AS QUANTITY_IN_STOCK,      
			 sum(sn.pp) as PURCHASE_PRICE,sum(sn.MRP) MRP,sum(sn.WS_PRICE) as WS_PRICE,   sn.SECTION_NAME, sn.SUB_SECTION_NAME,               
			 PARA4_NAME,PARA5_NAME,PARA6_NAME,e.uom_code,e.uom_type AS [UOM_TYPE],            
			 '' AS [ART_DT_CREATED],'' AS [PARA3_DT_CREATED],      
			 '' AS [SKU_DT_CREATED],            
			 0 as STOCK_NA,F.JOB_NAME, A.RECEIPT_NO ,      
			 '' as ISSUE_NO,'' AS ARTICLE_ALIAS,BI.BIN_NAME,A.REMARKS ,M.REMARKS AS [ISSUE_REMARKS]   
			 ,'' as MERCHANT_NAME,'' as BUYER_NAME  
			 ,sn.attr1_key_name,sn.attr2_key_name,sn.attr3_key_name,sn.attr4_key_name,sn.attr5_key_name,sn.attr6_key_name,  
			   sn.attr7_key_name,sn.attr8_key_name,sn.attr9_key_name,sn.attr10_key_name,sn.attr11_key_name,sn.attr12_key_name,  
			   sn.attr13_key_name,sn.attr14_key_name,sn.attr15_key_name,sn.attr16_key_name,sn.attr17_key_name,sn.attr18_key_name,  
			   sn.attr19_key_name,sn.attr20_key_name,sn.attr21_key_name,sn.attr22_key_name,sn.attr23_key_name,sn.attr24_key_name,  
			 sn.attr25_key_name    ,  dm.design_no,'' as old_row_id,a.last_update ,cast('' as timestamp) as Ts,JPMT.Trading_Product_code
			 FROM JOBWORK_RECEIPT_MST A (NOLOCK)                           
			 JOIN JOBWORK_RECEIPT_DET B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID                         
			 JOIN JOBWORK_ISSUE_DET M (NOLOCK) ON M.ROW_ID = B.REF_ROW_ID          
			 JOIN JOBWORK_ISSUE_MST O (NOLOCK) ON O.ISSUE_ID = M.ISSUE_ID   
			 join sku_names sn (nolock) on sn.product_Code =b.product_code                
			 JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=M.PRODUCT_CODE          
			 JOIN ARTICLE ART (NOLOCK) ON SKU.ARTICLE_CODE = ART.ARTICLE_CODE              
			 JOIN UOM E (NOLOCK) ON ART.UOM_CODE = E.UOM_CODE           
			 JOIN JOBS F (NOLOCK) ON F.JOB_CODE = M.JOB_CODE       
			 JOIN BIN BI (NOLOCK) ON BI.BIN_ID = B.BIN_ID     
			left outer JOIN designm dm (NOLOCK) ON m.design_code =dm.design_code
			LEFT OUTER JOIN JOBWORK_PMT JPMT (NOLOCK) ON JPMT.PRODUCT_CODE=B.product_code
			 WHERE A.RECEIPT_ID= @CWHERE   
			group by b.PRINT_LABEL,b.receipt_id,b.no_hrs,b.REMARKS,
			 b.BIN_ID,b.WIP_UID,b.PREV_JOB_RATE,b.JOB_CODE
			,b.hsn_code,b.gst_percentage,b.Gst_Cess_Percentage , sn.ARTICLE_NO, sn.ARTICLE_NAME,           
			 PARA1_NAME,PARA2_NAME,PARA3_NAME,e.uom_name ,sn.SECTION_NAME, sn.SUB_SECTION_NAME,               
			 PARA4_NAME,PARA5_NAME,PARA6_NAME,e.uom_code,e.uom_type ,            
			 F.JOB_NAME, A.RECEIPT_NO , BI.BIN_NAME,A.REMARKS ,M.REMARKS  ,sn.para2_order   
			 ,sn.attr1_key_name,sn.attr2_key_name,sn.attr3_key_name,sn.attr4_key_name,sn.attr5_key_name,sn.attr6_key_name,  
			   sn.attr7_key_name,sn.attr8_key_name,sn.attr9_key_name,sn.attr10_key_name,sn.attr11_key_name,sn.attr12_key_name,  
			   sn.attr13_key_name,sn.attr14_key_name,sn.attr15_key_name,sn.attr16_key_name,sn.attr17_key_name,sn.attr18_key_name,  
			   sn.attr19_key_name,sn.attr20_key_name,sn.attr21_key_name,sn.attr22_key_name,sn.attr23_key_name,sn.attr24_key_name,  
			 sn.attr25_key_name    ,  dm.design_no  ,a.last_update , CAST('LATER'+sku.ARTICLE_CODE +sku.PARA1_CODE +sku.PARA2_CODE AS VARCHAR(40)) ,B.JOB_RATE  
			 ,JPMT.Trading_Product_code
			 order by sn.article_no ,sn.para1_name ,sn.para2_order 
	

	 end


 end

 
 
                
END 
