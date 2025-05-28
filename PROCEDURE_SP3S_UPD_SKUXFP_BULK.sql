create PROCEDURE SP3S_UPD_SKUXFP_BULK  
AS  
BEGIN  
    TRUNCATE TABLE SKU_XFP  
      
  
 declare @CHODEPTID VARCHAR(5),@CLOCATIONID VARCHAR(5),@cHoPanNo VARCHAR(20)  
 SELECT TOP 1  @CLOCATIONID=VALUE FROM config WHERE config_option='LOCATION_ID'  
 SELECT TOP 1  @CHODEPTID=VALUE FROM config WHERE config_option='HO_LOCATION_ID'  
   
 SELECT TOP 1 @cHoPanNo=(CASE WHEN ISNULL(loc_gst_no,'')<>'' THEN SUBSTRING (loc_gst_no ,3,10)   
 else pan_no END) FROM  location (NOLOCK) WHERE dept_id=@CHODEPTID  
   
    Declare @TMPSKUXFP table ( DEPT_ID varchar(5),PRODUCT_CODE varchar(100),ROW_ID varchar(100),mrr_id varchar(50),xn_type varchar(50) ,receipt_dt dateTime,SRNo int)  
      
   DECLARE @TMPSKUXFPPUR TABLE (  
                                DEPT_ID VARCHAR(5) ,PRODUCT_CODE VARCHAR(100),RECEIPT_DT DATETIME ,INV_NO VARCHAR(100),INV_DT DATETIME,  
        XFER_PRICE NUMERIC(14,2),XFER_PRICE_WITHOUT_GST NUMERIC(18,2),XFER_PRICE_IGST_AMOUNT NUMERIC(18,2),  
        XFER_PRICE_CGST_AMOUNT NUMERIC(18,2),XFER_PRICE_SGST_AMOUNT NUMERIC(18,2),XFER_GST_CESS_AMOUNT NUMERIC(18,2),  
        PARTY_PAN_NO VARCHAR(50),LOC_PAN_NO VARCHAR(50),LOC_PP NUMERIC(18,2),SR INT,CHALLAN_SOURCE_LOCATION_CODE VARCHAR(10)  
        )  
          
    
if @CLOCATIONID<>@CHODEPTID  
 begin  
  
  ;WITH CTE AS  
  (  
   SELECT D.location_Code as  DEPT_ID ,C.PRODUCT_CODE,C.ROW_ID,  
   SR=ROW_NUMBER () OVER (PARTITION BY D.location_code ,C.PRODUCT_CODE ORDER BY RECEIPT_DT DESC )  
   FROM PID01106 C (NOLOCK)   
   JOIN PIM01106 D (NOLOCK) ON C.MRR_ID=D.MRR_ID  
   WHERE  D.CANCELLED=0 and isnull(c.invoice_quantity,0)<>0  
  )  
  INSERT INTO @TMPSKUXFP(DEPT_ID,PRODUCT_CODE,ROW_ID)  
  SELECT DEPT_ID,PRODUCT_CODE,ROW_ID  FROM CTE WHERE SR=1  
  
    insert into @TMPSKUXFPPUR  (DEPT_ID  ,PRODUCT_CODE ,RECEIPT_DT  ,INV_NO ,INV_DT ,XFER_PRICE ,XFER_PRICE_WITHOUT_GST ,XFER_PRICE_IGST_AMOUNT ,  
        XFER_PRICE_CGST_AMOUNT ,XFER_PRICE_SGST_AMOUNT ,XFER_GST_CESS_AMOUNT ,PARTY_PAN_NO ,LOC_PAN_NO ,LOC_PP ,SR ,CHALLAN_SOURCE_LOCATION_CODE  
        )  
            
    SELECT A.DEPT_ID ,B.PRODUCT_CODE ,a.Receipt_dt,a.inv_no,a.inv_dt,  
         XFER_PRICE= (B.PURCHASE_PRICE-(B.PURCHASE_PRICE*A.DISCOUNT_PERCENTAGE/100)    
           +(CASE WHEN A.BILL_LEVEL_TAX_METHOD=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.TAX_AMOUNT ,0))/B.INVOICE_QUANTITY) ELSE 0 END))   ,  
        xfer_price_without_gst =round(b.xn_value_without_gst/b.invoice_quantity,2)  ,  
	   xfer_price_igst_amount =round(b.igst_amount/b.invoice_quantity,2) ,  
	   xfer_price_cgst_amount =round(b.cgst_amount/b.invoice_quantity,2) ,  
	   xfer_price_sgst_amount =round(b.sgst_amount/b.invoice_quantity,2) ,  
      xfer_gst_cess_amount=b.Gst_Cess_Amount,  
       Party_Pan_No=LM.PAN_NO,  
      Loc_Pan_No=loc.PAN_NO,  
   loc_pp=CAST(round(b.xn_value_without_gst/b.invoice_quantity,2)  AS NUMERIC(18,2)),  
   sr =ROW_NUMBER () over (partition by B.PRODUCT_CODE, A.DEPT_ID order by a.receipt_dt desc),  
   a.challan_source_location_code  
    FROM PIM01106 A (NOLOCK)    
    JOIN PID01106 B (NOLOCK) ON A.MRR_ID=B.MRR_ID    
    JOIN @TMPSKUXFP TMP ON TMP.ROW_ID =B.ROW_ID    
 JOIN LOCATION LOC (NOLOCK) ON LOC.DEPT_ID =A.DEPT_ID   
 JOIN LMP01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE   
    WHERE A.CANCELLED=0  AND ISNULL(A.RECEIPT_DT,'')<>'' AND A.INV_MODE=2     
    AND ISNULL(B.PRODUCT_CODE,'')<>''   
      
 UPDATE A  SET LOC_PP=B.PURCHASE_PRICE  
 FROM @TMPSKUXFPPUR A   
 JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE  
 WHERE ISNULL(PARTY_PAN_NO,'')=ISNULL(LOC_PAN_NO,'')  
  
  INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,GROUP_INV_NO,GROUP_INV_DT,xfer_price_without_gst,xfer_price_igst_amount,xfer_price_cgst_amount,xfer_price_sgst_amount,  
     xfer_discount_amount,xfer_freight_amount,xfer_other_charges,xfer_round_off,xfer_gst_cess_amount,loc_pp,challan_source_location_code)      
  SELECT distinct  A.PRODUCT_CODE,A.DEPT_ID,A.XFER_PRICE,A.XFER_PRICE CURRENT_XFER_PRICE,A.RECEIPT_DT,  
       0 AS DISCOUNT_PERCENTAGE,A.RECEIPT_DT FIRST_RECEIPT_DT,A.Inv_no GROUP_INV_NO,A.inv_dt GROUP_INV_DT,  
       a.xfer_price_without_gst,a.xfer_price_igst_amount,a.xfer_price_cgst_amount,a.xfer_price_sgst_amount,  
       0 as xfer_discount_amount,0 as xfer_freight_amount,0 as xfer_other_charges,0 as xfer_round_off,a.xfer_gst_cess_amount,a.loc_pp,  
                         a.challan_source_location_code  
  FROM @TMPSKUXFPPUR A   
  WHERE SR=1  
    
  
    
  
 end  
 else   
 begin  

    
	   INSERT INTO @TMPSKUXFP(DEPT_ID,PRODUCT_CODE,ROW_ID,xn_type,mrr_id,receipt_dt,SRNo)  
	   SELECT D.location_Code  AS DEPT_ID ,C.PRODUCT_CODE,C.ROW_ID,  
			  XN_TYPE='GRPPUR',d.mrr_id ,d.receipt_dt ,1 as SRNo 
	   FROM IND01106  C (NOLOCK)   
	   JOIN INM01106 INM (NOLOCK) ON INM.INV_ID =c.INV_ID   
	   JOIN PIM01106 D (NOLOCK) ON C.INV_ID =D.INV_ID  
	   WHERE D.INV_MODE=2 AND D.CANCELLED=0 and isnull(c.invoice_quantity,0)<>0 and inm.CANCELLED =0  
	   AND ISNULL(c.PRODUCT_CODE,'')<>''   


	 ;WITH CTE_MRR_PARTY AS
	 (
      SELECT A.MRR_ID ,A.RECEIPT_DT ,A.LOCATION_CODE
	  FROM PIM01106 A (NOLOCK)
	  WHERE A.CANCELLED =0 AND A.INV_MODE =1 AND A.RECEIPT_DT <>''
	  )

	   INSERT INTO @TMPSKUXFP(DEPT_ID,PRODUCT_CODE,ROW_ID,XN_TYPE,MRR_ID,RECEIPT_DT,SRNO )  
	   SELECT A.LOCATION_CODE  AS DEPT_ID ,B.PRODUCT_CODE,B.ROW_ID,  
			  XN_TYPE='PUR',A.MRR_ID ,A.RECEIPT_DT   ,2 AS SRNO
	   FROM CTE_MRR_PARTY A
	   JOIN PID01106 B (nolock) ON A.MRR_ID =B.MRR_ID 
	   WHERE ISNULL(B.PRODUCT_CODE,'')<>''  AND ISNULL(B.INVOICE_QUANTITY,0)<>0   
	 
	 ;WITH CTE_TMP_PUR AS   
	  (  
	  SELECT DEPT_ID,PRODUCT_CODE,ROW_ID,MRR_ID,XN_TYPE ,  SRNO ,
			 ROW_NUMBER () OVER (PARTITION BY DEPT_ID ,PRODUCT_CODE ORDER BY RECEIPT_DT DESC,SRNO  )  AS SR   
	  FROM @TMPSKUXFP   
	   )  
   
	   UPDATE  CTE_TMP_PUR SET SRNO=SR  WHERE SR=1

   
  
        
     insert into @TMPSKUXFPPUR  (DEPT_ID  ,PRODUCT_CODE ,RECEIPT_DT  ,INV_NO ,INV_DT ,XFER_PRICE ,XFER_PRICE_WITHOUT_GST ,XFER_PRICE_IGST_AMOUNT ,  
        XFER_PRICE_CGST_AMOUNT ,XFER_PRICE_SGST_AMOUNT ,XFER_GST_CESS_AMOUNT ,PARTY_PAN_NO ,LOC_PAN_NO ,LOC_PP  ,CHALLAN_SOURCE_LOCATION_CODE  
        )  
       SELECT a.DEPT_ID ,B.PRODUCT_CODE ,a.Receipt_dt,a.inv_no,a.inv_dt,  
         XFER_PRICE= (B.net_rate -(B.net_rate*A.DISCOUNT_PERCENTAGE/100)    
          +(CASE WHEN A.BILL_LEVEL_TAX_METHOD=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.item_TAX_AMOUNT ,0))/B.INVOICE_QUANTITY) ELSE 0 END))    ,  
        xfer_price_without_gst =round(b.xn_value_without_gst/b.invoice_quantity,2)  ,  
	   xfer_price_igst_amount =round(b.igst_amount/b.invoice_quantity,2) ,  
	   xfer_price_cgst_amount =round(b.cgst_amount/b.invoice_quantity,2) ,  
	   xfer_price_sgst_amount =round(b.sgst_amount/b.invoice_quantity,2) ,  
      xfer_gst_cess_amount=b.Gst_Cess_Amount,  
      Party_Pan_No=LM.PAN_NO,  
      Loc_Pan_No=loc.PAN_NO ,  
      loc_pp=CAST(round(b.xn_value_without_gst/b.invoice_quantity,2)  AS NUMERIC(18,2)),a.challan_source_location_code  
    FROM @TMPSKUXFP TMP  
    JOIN IND01106  B (NOLOCK) ON tmp.row_id=B.row_id   
    JOIN pim01106  a (NOLOCK) ON tmp.mrr_id  =A.mrr_id     
    JOIN LOCATION LOC (NOLOCK) ON LOC.DEPT_ID =A.DEPT_ID   
    JOIN LMP01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE   
    where tmp.xn_type ='GRPPUR'  and tmp.SRNo =1
      
      insert into @TMPSKUXFPPUR  (DEPT_ID  ,PRODUCT_CODE ,RECEIPT_DT  ,INV_NO ,INV_DT ,XFER_PRICE ,XFER_PRICE_WITHOUT_GST ,XFER_PRICE_IGST_AMOUNT ,  
        XFER_PRICE_CGST_AMOUNT ,XFER_PRICE_SGST_AMOUNT ,XFER_GST_CESS_AMOUNT ,PARTY_PAN_NO ,LOC_PAN_NO ,LOC_PP  ,CHALLAN_SOURCE_LOCATION_CODE  
        )  
        SELECT A.DEPT_ID ,B.PRODUCT_CODE ,a.Receipt_dt,a.inv_no,a.inv_dt,  
         XFER_PRICE= (B.PURCHASE_PRICE-(B.PURCHASE_PRICE*A.DISCOUNT_PERCENTAGE/100)    
           +(CASE WHEN A.BILL_LEVEL_TAX_METHOD=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.TAX_AMOUNT ,0))/B.INVOICE_QUANTITY) ELSE 0 END))   ,  
       xfer_price_without_gst =round(b.xn_value_without_gst/b.invoice_quantity,2)  ,  
       xfer_price_igst_amount =round(b.igst_amount/b.invoice_quantity,2) ,  
       xfer_price_cgst_amount =round(b.cgst_amount/b.invoice_quantity,2) ,  
       xfer_price_sgst_amount =round(b.sgst_amount/b.invoice_quantity,2) ,  
       xfer_gst_cess_amount=b.Gst_Cess_Amount,  
       Party_Pan_No=LM.PAN_NO,  
      Loc_Pan_No=loc.PAN_NO ,  
      loc_pp=CAST(round(b.xn_value_without_gst/b.invoice_quantity,2)  AS NUMERIC(18,2)),a.DEPT_ID    
    FROM PIM01106 A (NOLOCK)    
    JOIN PID01106 B (NOLOCK) ON A.MRR_ID=B.MRR_ID    
    JOIN @TMPSKUXFP TMP ON TMP.ROW_ID =B.ROW_ID    
    JOIN LOCATION LOC (NOLOCK) ON LOC.DEPT_ID =A.DEPT_ID   
    JOIN LMP01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE   
    WHERE A.CANCELLED=0  AND ISNULL(A.RECEIPT_DT,'')<>'' AND A.INV_MODE=1     
    AND ISNULL(B.PRODUCT_CODE,'')<>'' and tmp.xn_type <>'GRPPUR'  and tmp.SRNo =1
      
    ;with Dup_mrr  as  
    (  
      select *,  
             SRNo=ROW_NUMBER() over(partition  by dept_id ,product_code order by receipt_dt desc)  
      from @TMPSKUXFPPUR  
    )  
      
    delete from Dup_mrr where SRNo>1  
   
  
	 UPDATE A  SET loc_pp=B.PURCHASE_PRICE  
	 FROM @TMPSKUXFPPUR A   
	 JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE  
	 WHERE ISNULL(PARTY_PAN_NO,'')=ISNULL(LOC_PAN_NO,'')  
  
    
    INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,GROUP_INV_NO,GROUP_INV_DT,xfer_price_without_gst,xfer_price_igst_amount,xfer_price_cgst_amount,xfer_price_sgst_amount,  
       xfer_discount_amount,xfer_freight_amount,xfer_other_charges,xfer_round_off,xfer_gst_cess_amount,loc_pp,challan_source_location_code)      
    SELECT   A.PRODUCT_CODE,A.DEPT_ID,A.XFER_PRICE,A.XFER_PRICE CURRENT_XFER_PRICE,A.RECEIPT_DT,  
                  0 AS DISCOUNT_PERCENTAGE,A.RECEIPT_DT FIRST_RECEIPT_DT,A.Inv_no GROUP_INV_NO,A.inv_dt GROUP_INV_DT,  
      a.xfer_price_without_gst,a.xfer_price_igst_amount,a.xfer_price_cgst_amount,a.xfer_price_sgst_amount,  
                  0 as xfer_discount_amount,0 as xfer_freight_amount,0 as xfer_other_charges,0 as xfer_round_off,a.xfer_gst_cess_amount,a.loc_pp,  
                  a.challan_source_location_code  
  
    FROM @TMPSKUXFPPUR A    
    LEFT OUTER JOIN sku_xfp c (NOLOCK) ON c.product_code=a.product_code AND c.dept_id=a.dept_id  
    WHERE c.dept_id IS NULL    
 end  
      
      
 --WHERE  C.PRODUCT_CODE=B.PRODUCT_CODE AND LEFT(B.MRR_ID,2)=LEFT(D.MRR_ID,2) AND D.INV_MODE=2 AND D.CANCELLED=0  
 --AND ISNULL(D.RECEIPT_DT,'')<>'' ORDER BY RECEIPT_DT DESC  
   
  IF OBJECT_ID ('TEMPDB..#TMP_ops_sku_xfp','U') IS NOT NULL  
     drop table #TMP_ops_sku_xfp  
       
 PRINT 'Insert Xfer price from OPS table'   
   
 SELECT  DISTINCT  a.PRODUCT_CODE, A.DEPT_ID,a.XFER_PRICE,a.CURRENT_XFER_PRICE  
   ,a. RECEIPT_DT  
   ,a.DISCOUNT_PERCENTAGE ,a.FIRST_RECEIPT_DT As FIRST_RECEIPT_DT  
   ,a.group_inv_no,  
   a.group_inv_dt,  
   sr =ROW_NUMBER () over (partition by a.PRODUCT_CODE, A.DEPT_ID order by a.receipt_dt desc),  
   a.loc_pp  
 into #TMP_ops_sku_xfp  
 FROM ops_sku_xfp  A (NOLOCK)  
 LEFT OUTER JOIN sku_xfp c (NOLOCK) ON c.product_code=a.product_code AND c.dept_id=a.dept_id  
 WHERE c.dept_id IS NULL    
  
   INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,loc_pp,challan_source_location_code, xfer_price_without_gst )    
 select PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,loc_pp,dept_id,XFER_PRICE  
 from #TMP_ops_sku_xfp   
 where sr=1  
      
   
  IF OBJECT_ID ('TEMPDB..#TMPSKUXFP_ops','U') IS NOT NULL  
     drop table #TMPSKUXFP_ops  
       
 PRINT 'Insert Xfer price from OPS table'   
   
 SELECT  DISTINCT  a.PRODUCT_CODE, A.DEPT_ID,  
         CASE WHEN isnull(A.XFER_PRICE,0) <>0 THEN A.XFER_PRICE ELSE  B.PURCHASE_PRICE END  AS XFER_PRICE,  
   CASE WHEN isnull(A.XFER_PRICE,0) <>0 THEN A.XFER_PRICE ELSE  B.PURCHASE_PRICE END  AS CURRENT_XFER_PRICE  
   ,case when isnull(A.RECEIPT_DT,'')='' then  b.RECEIPT_DT  
    else A.RECEIPT_DT END AS RECEIPT_DT  
   ,0 AS DISCOUNT_PERCENTAGE ,b.RECEIPT_DT As FIRST_RECEIPT_DT  
   ,(case when xn_no='' then 'ops' else xn_no end) as group_inv_no,  
   xn_dt as group_inv_dt,  
   sr =ROW_NUMBER () over (partition by B.PRODUCT_CODE, A.DEPT_ID order by a.receipt_dt desc),  
   case when @cHoPanNo =  
      (case when  SUBSTRING (loc.loc_gst_no ,3,10)<>'' THEN  SUBSTRING (loc.loc_gst_no,3,10) ELSE loc.PAN_NO  END) then sku.purchase_price   
      else a.xfer_price end loc_pp,a.dept_id as challan_source_location_code  
 into #TMPSKUXFP_ops  
 FROM OPS01106 A (NOLOCK)  
 JOIN sku b (NOLOCK) ON a.product_code=b.product_code  
 join location loc (nolock) on loc.dept_id =a.DEPT_ID   
 left join LMp01106 lm (nolock) on lm.AC_CODE =b.ac_code   
 join sku  (nolock) on sku.product_Code =a.product_code   
 LEFT OUTER JOIN sku_xfp c (NOLOCK) ON c.product_code=b.product_code AND c.dept_id=a.dept_id  
 WHERE c.dept_id IS NULL    
  
   INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,loc_pp,challan_source_location_code,xfer_price_without_gst)    
 select PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,loc_pp,challan_source_location_code,  
        XFER_PRICE  
 from #TMPSKUXFP_ops   
 where sr=1  
   
   
 print 'insert from SPlit & combined'  
   
 ;WITH CTE AS  
 (  
 SELECT c.DEPT_ID,A.PRODUCT_CODE,c.RECEIPT_DT  AS RECEIPT_DT,c.MEMO_NO  AS XN_NO,  
        sr =ROW_NUMBER () over (partition by A.PRODUCT_CODE, c.DEPT_ID order by c.RECEIPT_DT desc)  
 FROM snc_barcode_det  A  
 JOIN snc_det  B ON A.REFROW_ID  =B.ROW_ID   
 join SNC_MST c (nolock) on B.MEMO_ID =c.MEMO_ID   
 LEFT OUTER JOIN sku_xfp d (NOLOCK) ON d.product_code=A.product_code AND c.dept_id=d.dept_id  
 WHERE c.CANCELLED =0 AND isnull(c.wip,0)=0 AND d.product_code IS NULL  
 )  
  
 INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,loc_pp,challan_source_location_code)    
 SELECT  DISTINCT  a.PRODUCT_CODE, A.DEPT_ID,B.PURCHASE_PRICE AS XFER_PRICE,B.PURCHASE_PRICE AS CURRENT_XFER_PRICE  
   ,case when isnull(A.RECEIPT_DT,'')='' then  b.RECEIPT_DT  
    else A.RECEIPT_DT END AS RECEIPT_DT  
   ,0 AS DISCOUNT_PERCENTAGE ,b.RECEIPT_DT As FIRST_RECEIPT_DT  
   ,xn_no as group_inv_no,  
   A.RECEIPT_DT as group_inv_dt,  
   sku.purchase_price loc_pp,a.dept_id as challan_source_location_code  
 FROM CTE A (NOLOCK)  
 JOIN sku b (NOLOCK) ON a.product_code=b.product_code  
 join location loc (nolock) on loc.dept_id =a.DEPT_ID   
 left join LMp01106 lm (nolock) on lm.AC_CODE =b.ac_code   
 join sku  (nolock) on sku.product_Code =a.product_code  
 WHERE SR=1  
  
--end of Split & combined  
   
  
 ;WITH CTE AS  
 (  
 SELECT B.DEPT_ID,A.PRODUCT_CODE,CNC_MEMO_DT AS RECEIPT_DT,B.cnc_memo_no AS XN_NO,  
        sr =ROW_NUMBER () over (partition by A.PRODUCT_CODE, B.DEPT_ID order by B.CNC_MEMO_DT desc)  
 FROM ICD01106 A  
 JOIN ICM01106 B ON A.CNC_MEMO_ID =B.CNC_MEMO_ID  
 LEFT OUTER JOIN sku_xfp c (NOLOCK) ON c.product_code=A.product_code AND c.dept_id=b.dept_id  
 WHERE B.CANCELLED =0 AND B.CNC_TYPE=2 AND C.product_code IS NULL  
 )  
  
 INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,loc_pp,challan_source_location_code,xfer_price_without_gst)    
 SELECT  DISTINCT  a.PRODUCT_CODE, A.DEPT_ID,B.PURCHASE_PRICE AS XFER_PRICE,B.PURCHASE_PRICE AS CURRENT_XFER_PRICE  
   ,case when isnull(A.RECEIPT_DT,'')='' then  b.RECEIPT_DT  
    else A.RECEIPT_DT END AS RECEIPT_DT  
   ,0 AS DISCOUNT_PERCENTAGE ,b.RECEIPT_DT As FIRST_RECEIPT_DT  
   ,xn_no as group_inv_no,  
   A.RECEIPT_DT as group_inv_dt,  
   sku.purchase_price loc_pp,a.dept_id as challan_source_location_code,  
   sku.purchase_price  
 FROM CTE A (NOLOCK)  
 JOIN sku b (NOLOCK) ON a.product_code=b.product_code  
 join location loc (nolock) on loc.dept_id =a.DEPT_ID   
 left join LMp01106 lm (nolock) on lm.AC_CODE =b.ac_code   
 join sku  (nolock) on sku.product_Code =a.product_code  
 WHERE SR=1  
  
  
    Declare @TMPSKUXFPCNM table ( DEPT_ID varchar(5),PRODUCT_CODE varchar(100),ROW_ID varchar(100),mrr_id varchar(50),xn_type varchar(50) )  
  
  ;WITH CTE AS  
  (  
   SELECT LEFT(D.cn_id,2) AS DEPT_ID ,C.PRODUCT_CODE,C.ROW_ID,  
   SR=ROW_NUMBER () OVER (PARTITION BY LEFT(D.cn_id,2) ,C.PRODUCT_CODE ORDER BY RECEIPT_DT DESC)  
   FROM cnd01106 C (NOLOCK)   
   JOIN cnm01106 D (NOLOCK) ON C.cn_id=D.cn_id  
   WHERE D.mode=2 AND D.CANCELLED=0 and isnull(c.invoice_quantity,0)<>0  
  )  
  INSERT INTO @TMPSKUXFPCNM(DEPT_ID,PRODUCT_CODE,ROW_ID)  
  SELECT a.DEPT_ID,a.PRODUCT_CODE,a.ROW_ID  FROM CTE a  
  left join SKU_XFP b on a.DEPT_ID =b.dept_id and a.product_code=b.product_code  
  WHERE SR=1 and b.product_code is null  
  
  if exists (select top 1 'u'  from @TMPSKUXFPCNM)  
  begin  
  
   IF OBJECT_ID ('TEMPDB..#TMPSKUXFP_wsr','U') IS NOT NULL  
      drop table #TMPSKUXFP_wsr  
    
   
   SELECT  DISTINCT  B.PRODUCT_CODE, tmp.DEPT_ID  
     ,(B.net_rate  
         +(CASE WHEN b.BILL_LEVEL_TAX_METHOD=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.item_tax_amount ,0))/B.INVOICE_QUANTITY) ELSE 0 END)) AS XFER_PRICE  
     , (B.net_rate  
         +(CASE WHEN b.BILL_LEVEL_TAX_METHOD=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0)+ISNULL(B.item_tax_amount ,0))/B.INVOICE_QUANTITY) ELSE 0 END)) AS CURRENT_XFER_PRICE  
     ,A.RECEIPT_DT,  
       0  AS DISCOUNT_PERCENTAGE ,  
     A.RECEIPT_DT as FIRST_RECEIPT_DT,  
     a.manual_dn_no as group_inv_no,  
     a.manual_dn_dt as group_inv_dt,  
     xfer_price_without_gst =round(b.xn_value_without_gst/b.invoice_quantity,2)  ,  
     xfer_price_igst_amount =round(b.igst_amount/b.invoice_quantity,2) ,  
     xfer_price_cgst_amount =round(b.cgst_amount/b.invoice_quantity,2) ,  
     xfer_price_sgst_amount =round(b.sgst_amount/b.invoice_quantity,2) ,  
     isnull(b.discount_amount,0)+isnull(b.CNMDISCOUNTAMOUNT,0) xfer_discount_amount,  
     0 as xfer_depreciation,  
     0 as xfer_freight_amount,  
     0 xfer_other_charges,  
     0 xfer_round_off,  
     b.Gst_Cess_Amount  xfer_gst_cess_amount,  
     sr =ROW_NUMBER () over (partition by B.PRODUCT_CODE, tmp.DEPT_ID order by a.receipt_dt desc),  
     a.ac_code ,a.challan_source_location_code  
   into #TMPSKUXFP_wsr  
   FROM cnm01106 A (NOLOCK)  
   JOIN cnd01106 B (NOLOCK) ON A.cn_id=B.cn_id  
   JOIN @TMPSKUXFPCNM TMP ON TMP.ROW_ID =B.ROW_ID  
   WHERE A.CANCELLED=0  AND ISNULL(A.RECEIPT_DT,'')<>'' AND A.mode=2   
   AND ISNULL(B.PRODUCT_CODE,'')<>''  
    
   INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,group_inv_dt,xfer_price_without_gst,xfer_price_igst_amount,xfer_price_cgst_amount,xfer_price_sgst_amount,  
   xfer_discount_amount,xfer_depreciation,xfer_freight_amount,xfer_other_charges,xfer_round_off,xfer_gst_cess_amount,loc_pp,challan_source_location_code)    
          
   SELECT a.PRODUCT_CODE,a.DEPT_ID,a.XFER_PRICE,a.CURRENT_XFER_PRICE,a.RECEIPT_DT,a.DISCOUNT_PERCENTAGE,a.FIRST_RECEIPT_DT,a.group_inv_no,a.group_inv_dt,a.xfer_price_without_gst,a.xfer_price_igst_amount,a.xfer_price_cgst_amount,a.xfer_price_sgst_amount, 
 
   a.xfer_discount_amount,a.xfer_depreciation,xfer_freight_amount,a.xfer_other_charges,a.xfer_round_off,a.xfer_gst_cess_amount ,  
   case when   
   case when  SUBSTRING (LM.AC_GST_NO,3,10)<>'' THEN  SUBSTRING (LM.AC_GST_NO,3,10) ELSE LM.PAN_NO  END=  
   case when  SUBSTRING (loc.loc_gst_no ,3,10)<>'' THEN  SUBSTRING (loc.loc_gst_no,3,10) ELSE loc.PAN_NO  END then sku.purchase_price   
   else a.xfer_price_without_gst end loc_pp,a.challan_source_location_code  
  
    
   FROM #TMPSKUXFP_wsr A  
   join location loc (nolock) on loc.dept_id =a.DEPT_ID   
   join LMp01106 lm (nolock) on lm.AC_CODE =a.ac_code   
   join sku  (nolock) on sku.product_Code =a.product_code   
   WHERE SR=1  
  
  
  end  
  
  
  
  ;WITH CTE AS  
  (  
  SELECT  B.location_Code  as DEPT_ID,A.PRODUCT_CODE,cm_dt AS RECEIPT_DT,B.cm_no AS XN_NO,  
      sr =ROW_NUMBER () over (partition by A.PRODUCT_CODE, B.location_Code  order by B.cm_dt desc),  
      a.row_id ,c.loc_pp  
  FROM cmd01106 A  
  JOIN cmm01106 B ON A.cm_id =B.cm_id  
  LEFT OUTER JOIN sku_xfp c (NOLOCK) ON c.product_code=A.product_code AND c.dept_id=B.location_Code   
  WHERE B.CANCELLED =0  AND C.product_code IS NULL and a.QUANTITY<0  
  )  
  
   
 INSERT SKU_XFP(PRODUCT_CODE,DEPT_ID,XFER_PRICE,CURRENT_XFER_PRICE,RECEIPT_DT,DISCOUNT_PERCENTAGE,FIRST_RECEIPT_DT,group_inv_no,  
 group_inv_dt,loc_pp,xfer_price_without_gst,xfer_price_igst_amount,xfer_price_cgst_amount,xfer_price_sgst_amount,xfer_discount_amount,xfer_depreciation,xfer_freight_amount  
 ,xfer_other_charges,xfer_round_off,xfer_gst_cess_amount,challan_source_location_code  
 )    
 SELECT distinct  B.PRODUCT_CODE, cte.DEPT_ID  
     ,abs((B.net +(CASE WHEN b.tax_method=2 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0))/B.QUANTITY) ELSE 0 END)))  
       AS XFER_PRICE  
     ,abs( (B.net +(CASE WHEN b.tax_method=1 THEN ((ISNULL(B.IGST_AMOUNT,0)+ISNULL(B.CGST_AMOUNT,0)+ISNULL(B.SGST_AMOUNT,0))/B.QUANTITY) ELSE 0 END)) )  
     AS CURRENT_XFER_PRICE   
     ,A.cm_dt  RECEIPT_DT,  
     0AS DISCOUNT_PERCENTAGE ,  
     A.cm_dt   FIRST_RECEIPT_DT,  
     b.ref_sls_memo_no as group_inv_no,  
     b.ref_sls_memo_dt as group_inv_dt,sku.purchase_price loc_pp,  
     xfer_price_without_gst =abs(round(b.xn_value_without_gst/b.QUANTITY,2) ) ,  
     xfer_price_igst_amount =abs(round(b.igst_amount/b.QUANTITY,2)) ,  
     xfer_price_cgst_amount =abs(round(b.cgst_amount/b.QUANTITY,2)) ,  
     xfer_price_sgst_amount =abs(round(b.sgst_amount/b.QUANTITY,2)) ,  
     0 xfer_discount_amount,  
     0 as xfer_depreciation,  
     0 as xfer_freight_amount,  
     0 xfer_other_charges,  
     0 xfer_round_off,  
     abs(b.Gst_Cess_Amount)  xfer_gst_cess_amount,  
     cte.dept_id as challan_source_location_code  
 FROM cmm01106 A (NOLOCK)  
 JOIN cmd01106 b (NOLOCK) ON a.cm_id=b.cm_id  
 join CTE  on b.ROW_ID =cte.row_id   
 join location loc (nolock) on loc.dept_id =cte.DEPT_ID   
 join sku  (nolock) on sku.product_Code =b.product_code  
 WHERE SR=1  
  
  
END  