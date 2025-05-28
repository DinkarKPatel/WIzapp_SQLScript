create Procedure sp3s_onlineorder_status  
(  
   @RefNo varchar(100),  
   @SaleReturnType int,  
   @MODE INT=1  
)  
as  
begin  
  
   if @MODE=1  
      GOTO  LBLORDSLS  
    ELSE  
   GOTO  LBLCHKORDER  
  
   LBLORDSLS: 
   
    Declare @EINVOICE_PREFIX varchar(10)
    select @EINVOICE_PREFIX=value from CONFIG where config_option='EINVOICE_PREFIX'

	 if object_id ('tempdb..#tmpcmm','u') is not null
	    drop table #tmpcmm

	  SELECT CM_NO,CM_DT,REF_ORDER_ID ,EINV_IRN_NO, IRN_QR_CODE ,ACH_NO ,ACH_DT,SignedInvoice ,cmm.Party_Gst_No ,
	        loc.Enable_EInvoice 
			into #tmpcmm
      FROM CMM01106 CMM (NOLOCK)   
      JOIN CMD01106 CMD ON CMM.CM_ID =CMD.CM_ID   
      join BUYER_ORDER_MST mst on mst.order_id =cmd.REF_ORDER_ID  
	  join location loc (nolock) on loc.dept_id =CMM.location_Code 
      WHERE CMM.CANCELLED =0  
      and  mst.REF_NO = @REFNO AND mst.SALERETURNTYPE = @SALERETURNTYPE  
      GROUP BY CM_NO,CM_DT,REF_ORDER_ID ,EINV_IRN_NO, IRN_QR_CODE,ACH_NO ,ACH_DT,SignedInvoice ,cmm.Party_Gst_No ,loc.Enable_EInvoice  

	  Delete from #tmpcmm where Party_Gst_No <>'' and Enable_EInvoice =1 and isnull(EINV_IRN_NO,'')=''
  
  ;with cte as  
  (  
   SELECT top 1  ( CASE  WHEN A.CANCELLED=1 THEN 'CANCELLED'   
                   WHEN isnull(CMM.CM_NO,'')<>'' then 'INVOICED'   
       WHEN isnull(ONLINEORDERSTATUS,'')='' then 'ORDER_GENERATED'   
            ELSE ISNULL(ONLINEORDERSTATUS,'') END) AS STATUS ,  
    (CASE WHEN  LEFT(CMM.CM_NO,1)='0' THEN isnull(@EINVOICE_PREFIX,'') ELSE '' END)+ RTRIM(LTRIM(CMM.CM_NO))   [Bill No],  
     convert(varchar,cmm.cm_dt,105) as [Bill Date],   
     cmm.EINV_IRN_NO [IRN No],   
     CMM.IRN_QR_CODE [QR CODE],  
     CMM.ACH_NO  [ACK NUMBER],  
    -- convert(varchar, CMM.ACH_DT,105) as  [ACK DATE],    
	 CONVERT(VARCHAR(20), CMM.ACH_DT, 121)  as [ACK DATE],
     CMM.SignedInvoice [SIGNED INVOICE]  
   FROM BUYER_ORDER_MST (NOLOCK)  A  
   LEFT JOIN  #tmpcmm cmm ON CMM.REF_ORDER_ID =A.ORDER_ID  
   WHERE  A.REF_NO = @REFNO AND SALERETURNTYPE = @SALERETURNTYPE  
   order by last_update desc
  )  
  
  
  SELECT STATUS,[BILL NO],[BILL DATE],[IRN NO],[QR CODE], [ACK NUMBER], [ACK DATE], [SIGNED INVOICE]  
  FROM CTE   
  --where (STATUS<>'INVOICED' OR ISNULL([BILL NO],'')<>'')  
  
  GOTO END_PROC  
        
  
LBLCHKORDER:  
  
   SELECT ORDER_ID ,REF_NO ,SaleReturnType,ORDER_NO,ORDER_DT ,CANCELLED   
   FROM BUYER_ORDER_MST A (NOLOCK)  
   WHERE  A.REF_NO = @REFNO AND SALERETURNTYPE = @SALERETURNTYPE  
   and CANCELLED =0  
  
  
  END_PROC:  
  
end  
  
  