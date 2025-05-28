CREATE PROCEDURE SP3S_Reporting_expressions_cols
AS
BEGIN



	truncate table xtreme_reports_exp_COLS

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE)  
	SELECT 'FCO' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'DCO_QTY' AS  MASTER_COL,'Inter Bin Transfer Out','Quantity','FLOOR_ST_MST'
	UNION 
	SELECT 'FCOM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'DCO_QTY' AS  MASTER_COL,'Inter Bin Transfer Out','Value at RSP','FLOOR_ST_MST'
	UNION 
	SELECT 'FCOP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'DCO_QTY' AS  MASTER_COL ,'Inter Bin Transfer Out','Value at PP','FLOOR_ST_MST'
	UNION
	SELECT 'FCI' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'DCI_QTY' AS  MASTER_COL ,'Inter Bin Transfer In','Quantity','FLOOR_ST_MST'
	UNION 
	SELECT 'FCIM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'DCI_QTY' AS  MASTER_COL ,'Inter Bin Transfer In','Value at RSP','FLOOR_ST_MST'
	UNION 
	SELECT 'FCIP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'DCI_QTY' AS  MASTER_COL,'Inter Bin Transfer In','Value at PP','FLOOR_ST_MST'
		 

	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE)  
	SELECT 'FCO Val at PP(W/O DEP.)' as col_header,'FCPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'DCO_QTY' AS  MASTER_COL ,'Inter Bin Transfer Out','Value at PP(W/O DEP.)','FLOOR_ST_MST'
	UNION 
	SELECT 'FCI Val at PP(W/O DEP.)' as col_header, 'FCIPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'DCI_QTY' AS  MASTER_COL,'Inter Bin Transfer In','Value at PP(W/O DEP.)','FLOOR_ST_MST'
	      		 

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
	SELECT 'PPQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'PUR_QTY' AS  MASTER_COL    ,'Gross Purchase','Quantity','PIM01106',5
	UNION
	SELECT 'PPP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PUR_QTY' AS  MASTER_COL    ,'Gross Purchase','Value at PP','PIM01106' ,5
	UNION
	SELECT 'PPM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PUR_QTY' AS  MASTER_COL   ,'Gross Purchase','Value at RSP','PIM01106'  ,5
	UNION
	SELECT 'PPW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'PUR_QTY' AS  MASTER_COL   ,'Gross Purchase','Value at WSP','PIM01106'  ,5
	UNION
	SELECT 'PUTAXA' AS calculative_col,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR,'PUR_QTY' AS  MASTER_COL  ,'Gross Purchase','Tax/GST','PIM01106',5
	UNION
	SELECT 'PURGSTCESS' AS calculative_col,'SUM(a.gst_cess_amount)' as COL_EXPR,'PUR_QTY' AS  MASTER_COL  ,'Gross Purchase','','PIM01106',5
	UNION
	SELECT 'PPLC' AS calculative_col,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'PUR_QTY' AS  MASTER_COL ,'Gross Purchase','Value at LC','PIM01106',5


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
	SELECT 'PUR Val at PP(W/O DEP.)' as col_header,'PPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'PUR_QTY' AS  MASTER_COL ,'Gross Purchase','Value at PP(W/O DEP.)','PIM01106',5
   

   INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'PUR Transaction Value' as col_header,'PURTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst)' as COL_EXPR,'PUR_QTY' AS  MASTER_COL ,'Gross Purchase','Transaction Value','PIM01106',5
   UNION
   SELECT 'PUR Transaction Value (W/O GST)' as col_header,'PURTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst)' as COL_EXPR,'PUR_QTY' AS  MASTER_COL ,'Gross Purchase','Transaction Value(W/O GST)','PIM01106',5
    


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER) 
	SELECT 'POQTY' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'PO_QTY' AS  MASTER_COL   ,'Purchase Order','Quantity','POM01106'  ,5
	UNION    
	SELECT 'POVP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PO_QTY' AS  MASTER_COL     ,'Purchase Order','Value at PP','POM01106'  ,5
	UNION    
	SELECT 'POVM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PO_QTY' AS  MASTER_COL     ,'Purchase Order','Value at RSP','POM01106'  ,5

	UNION
	SELECT 'POTAXA' AS calculative_col,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR,'PO_QTY' AS  MASTER_COL  ,'Purchase Order','Tax/GST','POM01106',5


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
	SELECT 'PO Val at PP(W/O DEP.)' as col_header,'POWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'PO_QTY' AS  MASTER_COL ,'Purchase Order','Value at PP(W/O DEP.)','POM01106',5
   

   INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'PO Transaction Value' as col_header,'POTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst)' as COL_EXPR,'PO_QTY' AS  MASTER_COL ,'Purchase Order','Transaction Value','POM01106',5
   UNION
   SELECT 'PO Transaction Value (W/O GST)' as col_header,'POTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst)' as COL_EXPR,'PO_QTY' AS  MASTER_COL ,'Purchase Order','Transaction Value(W/O GST)','POM01106',5
    

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER) 
	SELECT 'CPQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'CHI_QTY' AS  MASTER_COL     ,'Challan In','Quantity','PIM01106'  ,20
	UNION
	SELECT 'CPXP' AS calculative_col,'SUM(a.quantity*(SKU_XFP.XFER_PRICE))' as COL_EXPR,'CHI_QTY' AS  MASTER_COL ,'Challan In','Value at Xfer','PIM01106'  ,20
	UNION
	SELECT 'CPXPC' AS calculative_col,'SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))' as COL_EXPR,'CHI_QTY' AS  MASTER_COL ,'Challan In','Value at Current Xfer','PIM01106'   ,20  
	UNION
	SELECT 'CPP1' AS calculative_col,'SUM(a.quantity*(sku_names.pp))' as COL_EXPR,'CHI_QTY' AS  MASTER_COL   ,'Challan In','Value at PP','PIM01106'  ,20
	UNION
	SELECT 'CPM' AS calculative_col,'SUM(a.quantity*(sku_names.mrp))' as COL_EXPR,'CHI_QTY' AS  MASTER_COL    ,'Challan In','Value at RSP','PIM01106' ,20
	UNION
	SELECT 'CHIWSP' AS calculative_col,'SUM(a.quantity*(sku_names.ws_price))' as COL_EXPR,'CHI_QTY' AS  MASTER_COL  ,'Challan In','Value at WSP','PIM01106' ,20
	UNION
	SELECT 'CPLC' AS calculative_col,'SUM(a.quantity*(sku_names.lc))' as COL_EXPR,'CHI_QTY' AS  MASTER_COL    ,'Challan In','Value at LC','PIM01106' ,20
	UNION
	SELECT 'CPTAXAMT' AS calculative_col,'SUM(a.igst_amount+a.cgst_amount+a.sgst_amount)' as COL_EXPR,'CHI_QTY' AS  MASTER_COL  ,'Challan In','Tax/GST','PIM01106'   ,20
	UNION
	SELECT 'CPXPWGST' AS calculative_col,'SUM(a.quantity*(SKU_XFP.xfer_price_without_gst))' as COL_EXPR,'CHI_QTY' AS  MASTER_COL ,'Challan In','Value at Xfer(W/O GST)','PIM01106'   ,20  
	UNION
	SELECT 'CPXFPWDP' AS calculative_col,'SUM(a.quantity*(isnull(SKU_XFP.xfer_depreciation,0)+ isnull(SKU_XFP.xfer_price_without_gst,0)))' as COL_EXPR,'CHI_QTY' AS  MASTER_COL ,'Challan In','Value at Xfer(W/O DEP)','PIM01106'   ,20  
	  
		
	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
	SELECT 'CHI Val at PP(W/O DEP.)' as col_header,'CHIPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'CHI_QTY' AS  MASTER_COL ,'Challan In','Value at PP(W/O DEP.)','PIM01106',20
   

    INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'CHI Transaction Value' as col_header,'CHITRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst)' as COL_EXPR,'CHI_QTY' AS  MASTER_COL ,'Challan In','Transaction Value','PIM01106',20
   UNION
   SELECT 'CHI Transaction Value (W/O GST)' as col_header,'CHITRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst)' as COL_EXPR,'CHI_QTY' AS  MASTER_COL ,'Challan In','Transaction Value(W/O GST)','PIM01106',20
    


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE)   
	SELECT 'GRNPSINQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'GRNPSIN_QTY' AS  MASTER_COL     ,'GRNPS In','Quantity','GRN_PS_MST'   
	UNION
	SELECT 'GRNINMRPV' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'GRNPSIN_QTY' AS  MASTER_COL   ,'GRNPS In','Value at RSP','GRN_PS_MST'  
	UNION
	SELECT 'GRNPVIN' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'GRNPSIN_QTY' AS  MASTER_COL   ,'GRNPS In','Value at PP','GRN_PS_MST'  


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE)  
	SELECT 'GRNPS IN Val at PP(W/O DEP.)' as col_header,'GRNIPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'GRNPSIN_QTY' AS  MASTER_COL ,'GRNPS In','Value at PP(W/O DEP.)','GRN_PS_MST'
   

  


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE)    
	SELECT 'GRNPSOUTQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'GRNPSOUT_QTY' AS  MASTER_COL    ,'GRNPS Out','Quantity','GRN_PS_MST'    
	UNION
	SELECT 'GRNOUTMRPV' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'GRNPSOUT_QTY' AS  MASTER_COL   ,'GRNPS Out','Value at RSP','GRN_PS_MST'  
	UNION
	SELECT 'GRNOUTPV' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'GRNPSOUT_QTY' AS  MASTER_COL  ,'GRNPS Out','Value at PP','GRN_PS_MST' 


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE)  
	SELECT 'GRNPS OUT Val at PP(W/O DEP.)' as col_header,'GRNOPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'GRNPSOUT_QTY' AS  MASTER_COL ,'GRNPS Out','Value at PP(W/O DEP.)','GRN_PS_MST'
   


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)     
	SELECT 'PRQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'PRT_QTY' AS  MASTER_COL   ,'Purchase Return','Quantity','RMM01106'    ,10
	UNION
	SELECT 'PRM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PRT_QTY' AS  MASTER_COL  ,'Purchase Return','Value at RSP','RMM01106'  ,10
	UNION

	SELECT 'PRW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'PRT_QTY' AS  MASTER_COL  ,'Purchase Return','Value at WSP','RMM01106'  ,10
	UNION

	SELECT 'PRP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PRT_QTY' AS  MASTER_COL   ,'Purchase Return','Value at PP','RMM01106'   ,10
	UNION
	SELECT 'PRTAXA' AS calculative_col,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR,'PRT_QTY' AS  MASTER_COL  ,'Purchase Return','Tax/GST','RMM01106'    ,10 
	UNION
	SELECT 'PRTGSTCESS' AS calculative_col,'SUM(a.gst_cess_amount)' as COL_EXPR,'PRT_QTY' AS  MASTER_COL  ,'Purchase Return','','RMM01106'    ,10 
	UNION		
	SELECT 'PRLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'PRT_QTY' AS  MASTER_COL  ,'Purchase Return','Value at LC','RMM01106'  ,10   


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
	SELECT 'PRT Val at PP(W/O DEP.)' as col_header,'PRTPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'PRT_QTY' AS  MASTER_COL ,'Purchase Return','Value at PP(W/O DEP.)','RMM01106',10
   

    INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'PRT Transaction Value' as col_header,'PRTTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst)' as COL_EXPR,'PRT_QTY' AS  MASTER_COL ,'Purchase Return','Transaction Value','RMM01106',10
   UNION
   SELECT 'PRT Transaction Value (W/O GST)' as col_header,'PRTTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst)' as COL_EXPR,'PRT_QTY' AS  MASTER_COL ,'Purchase Return','Transaction Value(W/O GST)','RMM01106',10
    


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'NPQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'NET_PUR_QTY' AS  MASTER_COL   ,'Net Purchase','Quantity','PIM01106'  ,  15  
	UNION
	SELECT 'NPM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'NET_PUR_QTY' AS  MASTER_COL   ,'Net Purchase','Value at RSP','PIM01106' ,15     
	UNION

	SELECT 'NPW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'NET_PUR_QTY' AS  MASTER_COL   ,'Net Purchase','Value at WSP','PIM01106' ,15     
	UNION

	SELECT 'NPP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'NET_PUR_QTY' AS  MASTER_COL  ,'Net Purchase','Value at PP','PIM01106' ,15      
	UNION
	SELECT 'NPTAXAMT' AS calculative_col,'SUM(isnull(A.igst_amount,0)+isnull(a.sgst_amount,0)+isnull(a.cgst_amount,0)+ isnull(a.tax_amount,0))' as COL_EXPR,'NET_PUR_QTY' AS  MASTER_COL   ,'Net Purchase','Tax/GST','PIM01106'     ,15 
	UNION

	SELECT 'NPGSTCESS' AS calculative_col,'SUM(a.gst_cess_amount)' as COL_EXPR,'NET_PUR_QTY' AS  MASTER_COL   ,'Net Purchase','','PIM01106'     ,15 
	UNION

	SELECT 'NPLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'NET_PUR_QTY' AS  MASTER_COL ,'Net Purchase','Value at LC','PIM01106'    ,15


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'Net PUR Val at PP(W/O DEP.)' as col_header,'NPUPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'NET_PUR_QTY' AS  MASTER_COL ,'Net Purchase','Value at PP(W/O DEP.)','PIM01106',15
   

   INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'Net PUR Transaction Value' as col_header,'NPTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst)' as COL_EXPR,'NET_PUR_QTY' AS  MASTER_COL ,'Net Purchase','Transaction Value','PIM01106',15
   UNION
   SELECT 'Net PUR Transaction Value (W/O GST)' as col_header,'NPTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst)' as COL_EXPR,'NET_PUR_QTY' AS  MASTER_COL ,'Net Purchase','Transaction Value(W/O GST)','PIM01106',15
    




	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)    
	SELECT 'NPQ' AS calculative_col,'SUM(A.QUANTITY) * -1' as COL_EXPR_2,'NET_PUR_QTY' AS MASTER_COL    ,'Net Purchase','Quantity','PIM01106'      ,15 
	UNION
	SELECT 'NPM' AS calculative_col,'SUM(a.quantity*sku_names.mrp) * -1' as COL_EXPR_2,'NET_PUR_QTY' AS  MASTER_COL    ,'Net Purchase','Value at RSP','PIM01106'  ,15     
	UNION

	SELECT 'NPW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)* -1' as COL_EXPR_2,'NET_PUR_QTY' AS  MASTER_COL   ,'Net Purchase','Value at WSP','PIM01106' ,15     
	UNION

	SELECT 'NPP1' AS calculative_col,'SUM(a.quantity*sku_names.pp) * -1' as COL_EXPR_2,'NET_PUR_QTY' AS  MASTER_COL    ,'Net Purchase','Value at PP','PIM01106'     ,15  
	UNION
	SELECT 'NPTAXAMT' AS calculative_col,'SUM(isnull(A.igst_amount,0)+isnull(a.sgst_amount,0)+isnull(a.cgst_amount,0)+ isnull(a.item_tax_amount,0))*-1' as COL_EXPR_2,'NET_PUR_QTY' AS  MASTER_COL    ,'Net Purchase','Tax/GST','PIM01106'     ,15  
	UNION
	SELECT 'NPGSTCESS' AS calculative_col,'SUM(a.gst_cess_amount) * -1' as COL_EXPR_2,'NET_PUR_QTY' AS  MASTER_COL    ,'Net Purchase','','PIM01106'     ,15  
	UNION
	SELECT 'NPLC' AS calculative_col,'SUM(a.quantity*sku_names.lc) * -1' as COL_EXPR_2,'NET_PUR_QTY' AS  MASTER_COL ,'Net Purchase','Value at LC','PIM01106'      ,15
	

	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)    
	SELECT 'Net PUR Val at PP(W/O DEP.)' AS col_header,'NPUPWD' as calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP) * -1' as COL_EXPR_2,'NET_PUR_QTY' AS  MASTER_COL    ,'Net Purchase','Value at PP(W/O DEP.)','PIM01106'     ,15  
	   

   INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'Net PUR Transaction Value' as col_header,'NPTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst) *-1' as COL_EXPR_2,'NET_PUR_QTY' AS  MASTER_COL ,'Net Purchase','Transaction Value','PIM01106',15
   UNION
   SELECT 'Net PUR Transaction Value (W/O GST)' as col_header,'NPTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst) *-1' as COL_EXPR_2,'NET_PUR_QTY' AS  MASTER_COL ,'Net Purchase','Transaction Value(W/O GST)','PIM01106',15
    


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)    
	SELECT 'CRQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'CHO_QTY' AS MASTER_COL ,'Challan Out','Quantity','INM01106'  ,25   
	UNION
	SELECT 'CRM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'CHO_QTY' AS  MASTER_COL   ,'Challan Out','Value at RSP','INM01106'  ,25
	UNION
	SELECT 'CRP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'CHO_QTY' AS  MASTER_COL    ,'Challan Out','Value at PP','INM01106' ,25
	UNION
	SELECT 'CRTAXAMT' AS calculative_col,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR,'CHO_QTY' AS  MASTER_COL  ,'Challan Out','Tax/GST','INM01106'   ,25
	UNION
	SELECT 'CRLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'CHO_QTY' AS  MASTER_COL,'Challan Out','Value at LC','INM01106' ,25
	UNION
	SELECT 'CRXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR,'CHO_QTY' AS  MASTER_COL,'Challan Out','Value at Xfer','INM01106' ,25
	UNION
	SELECT 'CRXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR,'CHO_QTY' AS  MASTER_COL,'Challan Out','Value at Current Xfer','INM01106' ,25
	UNION
	SELECT 'CRW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'CHO_QTY' AS  MASTER_COL,'Challan Out','Value at WSP','INM01106' ,25
	UNION
	SELECT 'CRXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)' as COL_EXPR,'CHO_QTY' AS  MASTER_COL,'Challan Out','Value at Xfer(W/O GST)','INM01106' ,25
	
		
	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'CHO Val at PP(W/O DEP.)' as col_header,'CHVPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Value at PP(W/O DEP.)','INM01106',25
   


   INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'CHO Transaction Value' as col_header,'CHOTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst) ' as COL_EXPR,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Transaction Value','INM01106',25
   UNION
   SELECT 'CHO Transaction Value (W/O GST)' as col_header,'CHOTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst) ' as COL_EXPR,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Transaction Value(W/O GST)','INM01106',25
    


	INSERT xtreme_reports_exp_COLS	(calculative_col,COL_EXPR,MASTER_COL,COL_HEADER,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)     
	SELECT 'SPQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS Qty' AS col_header  ,'Gross Sale','Quantity','CMM01106'   ,35
	UNION
	SELECT 'SPG' AS calculative_col,'SUM(a.quantity*a.mrp)' as COL_EXPR,'SLS_QTY'AS MASTER_COL,'Gross SLS Val at MRP' AS COL_HEADER     ,'Gross Sale','Value at RSP','CMM01106' ,35
	UNION

	SELECT 'SALECOMM' AS calculative_col,'SUM(A.COMMISSION_AMOUNT)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Commission Amount' as col_header    ,'Net Sale' ,'Sale Commission','CMM01106'    ,45  
	
	UNION
	SELECT 'SPWP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'SLS_QTY'AS MASTER_COL,'Gross SLS Val at WSP' AS COL_HEADER     ,'Gross Sale','Value at WSP','CMM01106' ,35

	UNION
	SELECT 'SPGOLD' AS calculative_col,'SUM(a.quantity*a.old_mrp)' as COL_EXPR,'SLS_QTY' AS  MASTER_COL,'Gross SLS Val at Old MRP' as col_header  ,'Gross Sale','Value at Old RSP','CMM01106'  ,35  
	UNION
	SELECT 'SPBASICP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS Val at Basic Pur Price' AS COL_HEADER   ,'Gross Sale','Value at Basic PP','CMM01106' ,35  
	UNION
	SELECT 'SPP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS Val at PP' AS COL_HEADER    ,'Gross Sale','Value at PP','CMM01106'  ,35
	UNION
	SELECT 'SPCGST' AS calculative_col,'SUM(a.cgst_amount)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS CGST Amt' AS COL_HEADER ,'Gross Sale','CGST','CMM01106' ,35
	UNION
	SELECT 'SPSGST' AS calculative_col,'SUM(a.sgst_amount)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS SGST Amt' AS COL_HEADER ,'Gross Sale','SGST','CMM01106' ,35
	UNION
	SELECT 'SPIGST' AS calculative_col,'SUM(a.igst_amount)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS IGST Amt' AS COL_HEADER ,'Gross Sale','IGST','CMM01106' ,35
	UNION
	SELECT 'SPGST' AS calculative_col,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS GST Amt' AS COL_HEADER     ,'Gross Sale','Tax/GST','CMM01106' ,35
	UNION

	SELECT 'SLSGSTCESS' AS calculative_col,'SUM(a.Gst_Cess_Amount)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS GST Amt' AS COL_HEADER     ,'Gross Sale','','CMM01106' ,35
	UNION

	SELECT 'SPLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS Val at LC' AS COL_HEADER ,'Gross Sale','Value at LC','CMM01106' ,35
	UNION
	SELECT 'SPXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS Val at XFP' AS COL_HEADER  ,'Gross Sale','Value at Xfer','CMM01106' ,35
	UNION
	SELECT 'SPXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross SLS Val at Current XFP' AS COL_HEADER ,'Gross Sale','Value at Current Xfer','CMM01106' ,35
	UNION
	SELECT 'SLSDISAMT' AS calculative_col,'SUM(A.discount_amount+a.cmm_discount_amount)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'SLS Total Discount' AS COL_HEADER ,'Gross Sale','Total Discount','CMM01106' ,35
	UNION
	SELECT 'GBASICDMT' AS calculative_col,'SUM(a.basic_discount_amount)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross Sale Item Discount Amount' AS COL_HEADER ,'Gross Sale','Item Discount','CMM01106' ,35
	UNION
	SELECT 'GCARDDMT' AS calculative_col,'SUM(a.card_discount_amount)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross Sale Card Discount Amt' AS COL_HEADER ,'Gross Sale','Card Discount','CMM01106' ,35
	UNION
	SELECT 'SLSBILLDISAMT' AS calculative_col,'SUM(A.CMM_DISCOUNT_AMOUNT)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross Sale Bill Disc Amt' AS COL_HEADER  ,'Gross Sale','Bill Discount','CMM01106'   ,35
	UNION
	SELECT 'SLSDISPER' AS calculative_col,'(ROUND((SUM(A.discount_amount+a.cmm_discount_amount)/SUM(a.quantity*a.mrp))*100,2))' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'Gross Sale Disc %' AS COL_HEADER  ,'Gross Sale','Sale Disc %','CMM01106'   ,35    
	
	UNION
	SELECT 'SPXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'' AS COL_HEADER ,'Gross Sale','Value at Xfer(W/O GST)','CMM01106' ,35


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'Gross SLS Val at PP(W/O DEP.)' as col_header,'GSVPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'SLS_QTY' AS  MASTER_COL ,'Gross Sale','Value at PP(W/O DEP.)','CMM01106',35
   	

	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'Gross SLS Transaction Value' as col_header,'GSTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst) ' as COL_EXPR,'SLS_QTY' AS  MASTER_COL ,'Gross Sale','Transaction Value','CMM01106',35
   UNION
   SELECT 'Gross SLS Transaction Value (W/O GST)' as col_header,'GSTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst) ' as COL_EXPR,'SLS_QTY' AS  MASTER_COL ,'Gross Sale','Transaction Value(W/O GST)','CMM01106',35
    




	--OLD SLS

	--INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
 --   SELECT 'Gross SLS Old Bill Discount Amount' as col_header,'old_cmm_discount_amount' AS calculative_col,'SUM(a.old_cmm_discount_amount)' as COL_EXPR,'SLS_QTY' AS  MASTER_COL ,'Gross Sale','Transaction Value','CMM01106',35
 --   UNION
	--SELECT 'Gross SLS Old GST Amount' as col_header,'old_gst_Amount' AS calculative_col,'SUM(a.old_gst_Amount)' as COL_EXPR,'SLS_QTY' AS  MASTER_COL ,'Gross Sale','Transaction Value','CMM01106',35
 --   UNION
	--SELECT 'Gross SLS Old Transaction Value with GST' as col_header,'old_xn_value_with_gst' AS calculative_col,'SUM(a.old_xn_value_with_gst)' as COL_EXPR,'SLS_QTY' AS  MASTER_COL ,'Gross Sale','Transaction Value','CMM01106',35
	--UNION
	--SELECT 'Gross SLS Old Taxable Value' as col_header,'old_xn_value_without_gst' AS calculative_col,'SUM(a.old_xn_value_without_gst)' as COL_EXPR,'SLS_QTY' AS  MASTER_COL ,'Gross Sale','Transaction Value','CMM01106',35
	--UNION
	--SELECT 'Gross SLS  Old Discount Amount' as col_header,'old_discount_amount' AS calculative_col,'SUM(a.old_discount_amount)' as COL_EXPR,'SLS_QTY' AS  MASTER_COL ,'Gross Sale','Transaction Value','CMM01106',35
	--UNION
	--SELECT 'Gross SLS  Old Net Amount' as col_header,'OLD_NET' AS calculative_col,'SUM(a.OLD_NET)' as COL_EXPR,'SLS_QTY' AS  MASTER_COL ,'Gross Sale','Transaction Value','CMM01106',35
	




	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,col_header,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)       
	SELECT 'SRQ' AS calculative_col,'SUM(A.QUANTITY)*-1' as COL_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Qty' as col_header   ,'Sale Return','Quantity','CMM01106'   ,40
	UNION
	SELECT 'SRG' AS calculative_col,'SUM(a.quantity*a.mrp)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Val at MRP' AS COL_HEADER  ,'Sale Return','Value at RSP','CMM01106'  ,40  

	UNION
	SELECT 'SRWP' AS calculative_col,'SUM(a.quantity*Sku_NAMES.Ws_price)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Val at WSP' AS COL_HEADER  ,'Sale Return','Value at WSP','CMM01106'  ,40  


	UNION
	SELECT 'SRGOLD' AS calculative_col,'SUM(a.quantity*a.old_mrp)' as COL_EXPR,'SLS_QTY' AS MASTER_COL,'SLR Val at Old MRP' AS COL_HEADER ,'Sale Return','Value at Old RSP','CMM01106'    ,40
	UNION
	SELECT 'SRBASICP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Val at Basic Pur Price' AS COL_HEADER  ,'Sale Return','Value at Basic PP','CMM01106'   ,40
	UNION
	SELECT 'SRP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Val at PP' AS COL_HEADER    ,'Sale Return','Value at PP','CMM01106' ,40
	UNION
	SELECT 'SRGST' AS calculative_col,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR GST Amt' AS COL_HEADER  ,'Sale Return','Tax/GST','CMM01106'   ,40
	UNION

	SELECT 'SLRGSTCESS' AS calculative_col,'SUM(a.Gst_Cess_Amount)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR GST Amt' AS COL_HEADER  ,'Sale Return','','CMM01106'   ,40
	UNION


	SELECT 'SRCGST' AS calculative_col,'SUM(a.cgst_amount)*-1' as COL_EXPR,'SLR_QTY' AS MASTER_COL,'SLR CGST Amt' AS COL_HEADER ,'Sale Return','CGST','CMM01106'  ,40
	UNION
	SELECT 'SRSGST' AS calculative_col,'SUM(a.sgst_amount)*-1' as COL_EXPR,'SLR_QTY' AS MASTER_COL,'SLR SGST Amt' AS COL_HEADER,'Sale Return','SGST','CMM01106'  ,40
	UNION
	SELECT 'SRIGST' AS calculative_col,'SUM(a.igst_amount)*-1' as COL_EXPR,'SLR_QTY' AS MASTER_COL,'SLR IGST Amt' AS COL_HEADER,'Sale Return','IGST','CMM01106'  ,40
	UNION
	SELECT 'SRLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Val at LC' AS COL_HEADER  ,'Sale Return','Value at LC','CMM01106' ,40
	UNION
	SELECT 'SRXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Val at XFP' AS COL_HEADER  ,'Sale Return','Value at Xfer','CMM01106' ,40
	UNION
	SELECT 'SRXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Val at Current XFP' AS COL_HEADER ,'Sale Return','Value at Current Xfer','CMM01106' ,40
	UNION
	SELECT 'SLRDISAMT' AS calculative_col,'SUM(A.discount_amount+a.cmm_discount_amount)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Total Discount' AS COL_HEADER ,'Sale Return','Total Discount','CMM01106'  ,40
	UNION
	SELECT 'SLRBASICDMT' AS calculative_col,'SUM(a.basic_discount_amount)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Item Discount' AS COL_HEADER,'Sale Return','Item Discount','CMM01106' ,40
	UNION
	SELECT 'SLRCARDDMT' AS calculative_col,'SUM(a.card_discount_amount)*-1' as col_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Card Discount' AS COL_HEADER ,'Sale Return','Card Dsicount','CMM01106' ,40
	UNION
	SELECT 'SLRDISPER' AS calculative_col,'(ROUND((SUM(A.discount_amount+a.cmm_discount_amount)/SUM(a.quantity*a.mrp))*100,2))' as COL_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Discount %'    ,'Sale Return','Sale Disc %','CMM01106' ,40
	UNION
	SELECT 'SLRBILLDISAMT' AS calculative_col,'SUM(A.CMM_DISCOUNT_AMOUNT)' as COL_EXPR,'SLR_QTY' AS MASTER_COL,'SLR Bill Disc Amt'   ,'Sale Return','Bill Discount','CMM01106'     ,40
	
	UNION
	SELECT 'SLRXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst) *-1' as COL_EXPR,'SLR_QTY' AS MASTER_COL,'' AS COL_HEADER ,'Gross Sale','Value at Xfer(W/O GST)','CMM01106' ,35


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)       
	SELECT 'SLR Val at PP(W/O DEP.)' as col_header,'SRPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)*-1' as COL_EXPR,'SLR_QTY' AS  MASTER_COL ,'Sale Return','Value at PP(W/O DEP.)','CMM01106',40
   	
	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'SLR Transaction Value' as col_header,'SRTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst)*-1 ' as COL_EXPR,'SLR_QTY' AS  MASTER_COL ,'Sale Return','Transaction Value','CMM01106',40
   UNION
   SELECT 'SLR Transaction Value (W/O GST)' as col_header,'SRTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst)*-1 ' as COL_EXPR,'SLR_QTY' AS  MASTER_COL ,'Sale Return','Transaction Value(W/O GST)','CMM01106',40
    



	--OLD SLR

	--INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
 --   SELECT 'SLR Old Bill Discount Amount' as col_header,'old_slr_cmm_discount_amount' AS calculative_col,'SUM(a.old_cmm_discount_amount)' as COL_EXPR,'SLR_QTY' AS  MASTER_COL ,'Sale Return','Transaction Value','CMM01106',40
 --   UNION
	--SELECT 'SLR Old GST Amount' as col_header,'old_slr_gst_Amount' AS calculative_col,'SUM(a.old_gst_Amount)' as COL_EXPR,'SLR_QTY' AS  MASTER_COL ,'Sale Return','Transaction Value','CMM01106',40
 --   UNION
	--SELECT 'SLR Old Transaction Value with GST' as col_header,'old_slr_xn_value_with_gst' AS calculative_col,'SUM(a.old_xn_value_with_gst)' as COL_EXPR,'SLR_QTY' AS  MASTER_COL ,'Sale Return','Transaction Value','CMM01106',40
	--UNION
	--SELECT 'SLR Old Taxable Value' as col_header,'old_slr_xn_value_without_gst' AS calculative_col,'SUM(a.old_xn_value_without_gst)' as COL_EXPR,'SLR_QTY' AS  MASTER_COL ,'Sale Return','Transaction Value','CMM01106',40
	--UNION
	--SELECT 'SLR  Old Discount Amount' as col_header,'old_slr_discount_amount' AS calculative_col,'SUM(a.old_discount_amount)' as COL_EXPR,'SLR_QTY' AS  MASTER_COL ,'Sale Return','Transaction Value','CMM01106',40
	--UNION
	--SELECT 'SLR  Old Net Amount' as col_header,'OLD_slr_NET' AS calculative_col,'SUM(a.OLD_NET)' as COL_EXPR,'SLR_QTY' AS  MASTER_COL ,'Sale Return','Transaction Value','CMM01106',40
	








	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,col_header,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)       
	SELECT 'NSQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Qty' AS COL_HEADER  ,'Net Sale' ,'Quantity','CMM01106'    ,45 
	UNION
	SELECT 'NSG' AS calculative_col,'SUM(a.quantity*a.mrp)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Val at Gross MRP' AS COL_HEADER    ,'Net Sale' ,'Value at RSP','CMM01106' ,45     

	UNION
	SELECT 'NSWP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Val at WSP' AS COL_HEADER    ,'Net Sale' ,'Value at WSP','CMM01106' ,45     

	UNION
	SELECT 'NSM' AS calculative_col,'sum(a.net-a.cmm_discount_amount-isnull(A.item_round_off,0))' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Realized Value' AS COL_HEADER  ,'Net Sale' ,'Value at Realized','CMM01106'    ,45    
	
	
	UNION
	SELECT 'NSP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Val at PP' AS COL_HEADER    ,'Net Sale' ,'Value at PP','CMM01106'    ,45  
	UNION
	SELECT 'NSGOLD' AS calculative_col,'SUM(a.quantity*a.old_mrp)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Val at Old Mrp' AS COL_HEADER ,'Net Sale' ,'Value at Old RSP','CMM01106'   ,45      
	UNION
	SELECT 'NSBASICP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Val at Basic  PP' AS COL_HEADER  ,'Net Sale' ,'Value at Basic PP','CMM01106'       ,45 
	UNION
	SELECT 'NSGST' AS calculative_col,'SUM(isnull(a.igst_amount,0)+isnull(a.sgst_amount,0)+isnull(a.cgst_amount,0)+ + isnull(a.tax_amount,0))' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS GST' AS COL_HEADER    ,'Net Sale' ,'Tax/GST','CMM01106'   ,45   
	UNION

	SELECT 'NETSGSTCESS' AS calculative_col,'SUM(a.Gst_Cess_Amount)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS GST' AS COL_HEADER    ,'Net Sale' ,'','CMM01106'   ,45   
	UNION



	SELECT 'NSCGST' AS calculative_col,'SUM(a.cgst_amount)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS CGST Amt' AS COL_HEADER,'Net Sale' ,'CGST','CMM01106'     ,45 
	UNION
	SELECT 'NSSGST' AS calculative_col,'SUM(a.sgst_amount)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS SGST Amt' AS COL_HEADER,'Net Sale' ,'SGST','CMM01106'   ,45   
	UNION
	SELECT 'NSIGST' AS calculative_col,'SUM(a.igst_amount)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS IGST Amt' AS COL_HEADER,'Net Sale' ,'IGST','CMM01106'   ,45   
	UNION
	SELECT 'NSLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Val at LC' AS COL_HEADER,'Net Sale' ,'Value at LC','CMM01106'    ,45  
	UNION
	SELECT 'NSXFP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Val at XFP' AS COL_HEADER,'Net Sale' ,'Value at Xfer','CMM01106'  ,45    
	UNION
	SELECT 'NSCXFP' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Val at Current XFP' AS COL_HEADER,'Net Sale' ,'Value at Current Xfer','CMM01106'    ,45  
	UNION
	SELECT 'NSDISAMT' AS calculative_col,'SUM(A.discount_amount+a.cmm_discount_amount)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Total Discount' AS COL_HEADER,'Net Sale' ,'Total Discount','CMM01106'   ,45   
	UNION
	SELECT 'NETSBASICDMT' AS calculative_col,'SUM(a.basic_discount_amount)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Item Discount' AS COL_HEADER,'Net Sale' ,'Item Discount','CMM01106'     ,45 
	UNION
	SELECT 'NETSCARDDMT' AS calculative_col,'SUM(a.card_discount_amount)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Card Discount' AS COL_HEADER,'Net Sale' ,'Card Discount','CMM01106'     ,45 
	UNION
	SELECT 'BILLVALUEAVG' AS calculative_col,'(SUM(A.RFNET)/SUM(WeightedQtyBillCount))' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Average Bill Value' as col_header    ,'Net Sale' ,'Avg Bill value','CMM01106'  ,45    
	UNION
	SELECT 'UNITPRICEAVG' AS calculative_col,'(SUM(RFNET)/SUM(quantity))' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Average Unit Price' as col_header  ,'Net Sale' ,'Avg Unit price','CMM01106'    ,45    
	UNION
	SELECT 'AVGSALEDAYS' AS calculative_col,'Round((SUM(A.QUANTITY *isnull(selling_days,0))/SUM(A.QUANTITY + 0.0001)),0)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Average Sale Days' as col_header  ,'Net Sale' ,'Avg Sale Days','CMM01106'    ,45    
		
	UNION
	SELECT 'BASKETSIZE' AS calculative_col,'(SUM(A.quantity)/SUM(WeightedQtyBillCount)) ' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Basket Size' as col_header    ,'Net Sale' ,'Basket Size','CMM01106'    ,45  
	UNION
	SELECT 'COUNTBILL' AS calculative_col,'SUM(WeightedQtyBillCount)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Bill Count' as col_header    ,'Net Sale' ,'Bill Count','CMM01106'     ,45 
	UNION
	SELECT 'NSDISPER' AS calculative_col,'(ROUND((SUM(abs(A.DISCOUNT_AMOUNT)+abs(A.CMM_DISCOUNT_AMOUNT))/SUM(Abs(A.QUANTITY*A.MRP)+0.0001))*100,2))' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net Sls Disc%' as col_header  ,'Net Sale' ,'Sale Disc %','CMM01106'       ,45 
	UNION
	SELECT 'NVWOGST' AS calculative_col,'SUM(A.xn_value_without_gst)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net Sls Taxable Value' as col_header    ,'Net Sale' ,'Sale Taxable Value','CMM01106'     ,45 
	UNION
	SELECT 'NSPURGST' AS calculative_col,'SUM(A.quantity*sku_oh.tax_amount)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net SLS Pur Tax/GST Amt' as col_header    ,'Net Sale' ,'SLS PUR TAX/GST','CMM01106'    ,45  
	UNION
	SELECT 'NSPSQFPD' AS calculative_col,'(SUM(A.rfnet)/(CASE WHEN LOC_VIEW.AREA_COVERED<=0 THEN 1 ELSE LOC_VIEW.AREA_COVERED END))/
	(datediff(day,''dFromDt'', ''dToDt'')+1)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Sale PSFPD' as col_header   ,'Net Sale' ,'Sale PSFPD','CMM01106'   ,45    
	UNION
	SELECT 'NSLSBILLDISAMT' AS calculative_col,'SUM(A.CMM_DISCOUNT_AMOUNT)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net Sls Bill Discount' as col_header    ,'Net Sale' ,'Bill Discount','CMM01106'   ,45   
	UNION
	SELECT 'NETTHAAN' AS calculative_col,'SUM(1)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Total Thaan' as col_header    ,'Net Sale' ,'Thaan','CMM01106'    ,45  
	--UNION
	--SELECT 'COMMISSION_AMOUNT' AS calculative_col,'SUM(A.COMMISSION_AMOUNT*A.QUANTITY)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Commission Amount' as col_header    ,'Net Sale' ,'Sale Commission','CMM01106'    ,45  


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)       
	SELECT 'Net SLS Val at PP(W/O DEP.)' as col_header,'NSPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'NET_SLS_QTY' AS  MASTER_COL ,'Net Sale','Value at PP(W/O DEP.)','CMM01106',45
   	

	
	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'Net SLS Transaction Value' as col_header,'NSTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst) ' as COL_EXPR,'NET_SLS_QTY' AS  MASTER_COL ,'Net Sale','Transaction Value','CMM01106',45
   UNION
   SELECT 'Net SLS Transaction Value (W/O GST)' as col_header,'NSTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst) ' as COL_EXPR,'NET_SLS_QTY' AS  MASTER_COL ,'Net Sale','Transaction Value(W/O GST)','CMM01106',45
    
    UNION
	SELECT 'NSDISAMTOLD' AS calculative_col,'SUM(ROUND((A.QUANTITY*A.OLD_MRP)-A.Realize_sale,2) )' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net Old Discount Amt' AS COL_HEADER    ,'Net Sale' ,'','CMM01106' ,45     
	UNION
	SELECT 'NSGREAL' AS calculative_col,'SUM(A.Realize_sale)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net Old Realize Sale' AS COL_HEADER    ,'Net Sale' ,'','CMM01106' ,45     



	--NET SLS	
	

	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
    SELECT 'Net SLS Old Bill Discount Amount' as col_header,'old_SLS_cmm_discount_amount' AS calculative_col,'SUM(a.old_cmm_discount_amount)' as COL_EXPR,'NET_SLS_QTY' AS  MASTER_COL ,'Net Sale','Transaction Value','CMM01106',45
    UNION
	SELECT 'Net SLS Old GST Amount' as col_header,'old_sls_gst_Amount' AS calculative_col,'SUM(a.old_gst_Amount)' as COL_EXPR,'NET_SLS_QTY' AS  MASTER_COL ,'Net Sale','Transaction Value','CMM01106',45
    UNION
	SELECT 'Net SLS Old Transaction Value with GST' as col_header,'old_sls_xn_value_with_gst' AS calculative_col,'SUM(a.old_xn_value_with_gst)' as COL_EXPR,'NET_SLS_QTY' AS  MASTER_COL ,'Net Sale','Transaction Value','CMM01106',45
	UNION
	SELECT 'Net SLS Old Taxable Value' as col_header,'old_sls_xn_value_without_gst' AS calculative_col,'SUM(a.old_xn_value_without_gst)' as COL_EXPR,'NET_SLS_QTY' AS  MASTER_COL ,'Net Sale','Transaction Value','CMM01106',45
	UNION
	SELECT 'Net SLS  Old Discount Amount' as col_header,'old_sls_discount_amount' AS calculative_col,'SUM(a.old_discount_amount)' as COL_EXPR,'NET_SLS_QTY' AS  MASTER_COL ,'Net Sale','Transaction Value','CMM01106',45
	UNION
	SELECT 'Net SLS  Old Net Amount' as col_header,'OLD_sls_NET' AS calculative_col,'SUM(a.OLD_NET)' as COL_EXPR,'SLR_QTY' AS  MASTER_COL ,'Net Sale','Transaction Value','CMM01106',45
	






	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)     

	SELECT 'APQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'APP_QTY' AS MASTER_COL   ,'Gross Approval','Quantity','APM01106'    ,50 
	UNION
	SELECT 'APP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'APP_QTY' AS  MASTER_COL     ,'Gross Approval','Value at PP','APM01106'   ,50 
	UNION
	SELECT 'APPVM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'APP_QTY' AS  MASTER_COL  ,'Gross Approval','Value at RSP','APM01106'    ,50   
	UNION
	SELECT 'APPLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'APP_QTY' AS  MASTER_COL     ,'Gross Approval','Value at LC','APM01106'   ,50 
	

	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)       
	SELECT 'APP Val at PP(W/O DEP.)' as col_header,'APPPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'APP_QTY' AS  MASTER_COL ,'Gross Approval','Value at PP(W/O DEP.)','APM01106',50
   	

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'ARQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'APR_QTY' AS MASTER_COL   ,'Approval Return','Quantity','APPROVAL_RETURN_MST'      ,55
	UNION
	SELECT 'ARP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'APR_QTY' AS  MASTER_COL    ,'Approval Return','Value at PP','APPROVAL_RETURN_MST'    ,55  
	UNION
	SELECT 'ARM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'APR_QTY' AS  MASTER_COL     ,'Approval Return','Value at RSP','APPROVAL_RETURN_MST'   ,55  
	UNION
	SELECT 'CMALC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'APR_QTY' AS  MASTER_COL   ,'Approval Return','Value at LC','APPROVAL_RETURN_MST'    ,55   

	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)       
	SELECT 'APR Val at PP(W/O DEP.)' as col_header,'APRPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'APR_QTY' AS  MASTER_COL ,'Approval Return','Value at PP(W/O DEP.)','APPROVAL_RETURN_MST',55
   	




	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'NAQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'PENDING_APP_QTY' AS MASTER_COL     ,'Net Approval','Quantity','APPROVAL_RETURN_MST'   ,60  
	UNION
	SELECT 'NAP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PENDING_APP_QTY' AS  MASTER_COL      ,'Net Approval','Value at PP','APPROVAL_RETURN_MST'  ,60      
	UNION
	SELECT 'NAPMRP' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PENDING_APP_QTY' AS  MASTER_COL    ,'Net Approval','Value at RSP','APPROVAL_RETURN_MST'     ,60  
	
	UNION
	SELECT 'NAPWSP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'PENDING_APP_QTY' AS  MASTER_COL    ,'Net Approval','Value at WSP','APPROVAL_RETURN_MST'  ,60  
	UNION
	SELECT 'NAPDISC' AS calculative_col,'SUM((a.mrp*a.quantity)-a.rfnet)' as COL_EXPR,'PENDING_APP_QTY' AS  MASTER_COL       ,'Net Approval','Total Discount','APPROVAL_RETURN_MST'      ,60  
	UNION
	SELECT 'NAPLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'PENDING_APP_QTY' AS  MASTER_COL     ,'Net Approval','Value at LC','APPROVAL_RETURN_MST'    ,60     
		

	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'Net APP Val at PP(W/O DEP.)' as col_header,'NAPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'PENDING_APP_QTY' AS  MASTER_COL      ,'Net Approval','Value at PP(W/O DEP.)','APPROVAL_RETURN_MST'  ,60      
	  	

	
	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'NAQ' AS calculative_col,'SUM(A.QUANTITY)*-1' as COL_EXPR_2,'PENDING_APP_QTY' AS MASTER_COL    ,'Net Approval','Quantity','APPROVAL_RETURN_MST'   ,60       
	         
	UNION
	SELECT 'NAP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR_2,'PENDING_APP_QTY' AS  MASTER_COL    ,'Net Approval','Value at PP','APPROVAL_RETURN_MST'   ,60       
	UNION
	SELECT 'NAPMRP' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR_2,'PENDING_APP_QTY' AS  MASTER_COL    ,'Net Approval','Value at RSP','APPROVAL_RETURN_MST'   ,60     
	  
	UNION
	SELECT 'NAPWSP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)*-1' as COL_EXPR_2,'PENDING_APP_QTY' AS  MASTER_COL      ,'Net Approval','Value at WSP','APPROVAL_RETURN_MST'      ,60  

	UNION
	SELECT 'NAPDISC' AS calculative_col,'SUM((a.mrp*a.quantity)-a.rfnet)*-1' as COL_EXPR_2,'PENDING_APP_QTY' AS  MASTER_COL      ,'Net Approval','Total Discount','APPROVAL_RETURN_MST'     ,60  
	UNION
	SELECT 'NAPLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)*-1' as COL_EXPR,'PENDING_APP_QTY' AS  MASTER_COL     ,'Net Approval','Value at LC','APPROVAL_RETURN_MST'   ,60   


    INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'Net APP Val at PP(W/O DEP.)' as col_header,'NAPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP) *-1' as COL_EXPR_2,'PENDING_APP_QTY' AS  MASTER_COL      ,'Net Approval','Value at PP(W/O DEP.)','APPROVAL_RETURN_MST'  ,60      
	  	


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)    
	SELECT 'CNQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'CNC_QTY' AS MASTER_COL     ,'Cancellation','Quantity','ICM01106'    ,65
	UNION
	SELECT 'CNP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'CNC_QTY' AS  MASTER_COL  ,'Cancellation','Value at PP','ICM01106' ,65      
	UNION
	SELECT 'CNCVM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'CNC_QTY' AS  MASTER_COL    ,'Cancellation','Value at RSP','ICM01106',65
	UNION
	SELECT 'CNLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'CNC_QTY' AS  MASTER_COL    ,'Cancellation','Value at LC','ICM01106',65


	
    INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'CNC Val at PP(W/O DEP.)' as col_header,'CNPPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'CNC_QTY' AS  MASTER_COL      ,'Cancellation','Value at PP(W/O DEP.)','ICM01106'  ,65      
	  





	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)  
	SELECT 'UNQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'UNC_QTY' AS MASTER_COL     ,'UnCancellation','Quantity','ICM01106'     ,70
	UNION
	SELECT 'UNP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'UNC_QTY' AS  MASTER_COL      ,'UnCancellation','Value at PP','ICM01106'   ,70 
	UNION
	SELECT 'UNM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'UNC_QTY' AS  MASTER_COL   ,'UnCancellation','Value at RSP','ICM01106'    ,70  
	UNION
	SELECT 'UNLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'UNC_QTY' AS  MASTER_COL   ,'UnCancellation','Value at LC','ICM01106'   ,70     


	 INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'UNC Val at PP(W/O DEP.)' as col_header,'UNCPPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'UNC_QTY' AS  MASTER_COL      ,'UnCancellation','Value at PP(W/O DEP.)','ICM01106'  ,70      
	 



	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'NQC' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'NET_CNC_QTY' AS MASTER_COL     ,'Net Cancellation','Quantity','ICM01106'  ,75   
	UNION
	SELECT 'NQP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'NET_CNC_QTY' AS  MASTER_COL     ,'Net Cancellation','Value at PP','ICM01106'   ,75    
	UNION
	SELECT 'NQM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'NET_CNC_QTY' AS  MASTER_COL  ,'Net Cancellation','Value at RSP','ICM01106' ,75
	UNION
	SELECT 'NQLC' AS calculative_col,'SUM((a.quantity*sku_names.lc)' as COL_EXPR,'NET_CNC_QTY' AS  MASTER_COL   ,'Net Cancellation','Value at LC','ICM01106'  ,75

	 INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'NCN Val at PP(W/O DEP.)' as col_header ,'NCNPPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'NET_CNC_QTY' AS  MASTER_COL      ,'Net Cancellation','Value at PP(W/O DEP.)','ICM01106'  ,75      
	 


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)    
	SELECT 'NQC' AS calculative_col,'SUM(A.QUANTITY)*-1' as COL_EXPR_2,'NET_CNC_QTY' AS MASTER_COL    ,'Net Cancellation','Quantity','ICM01106'    ,75
	UNION
	SELECT 'NQP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR_2,'NET_CNC_QTY' AS  MASTER_COL     ,'Net Cancellation','Value at PP','ICM01106'  ,75       
	UNION
	SELECT 'NQM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR_2,'NET_CNC_QTY' AS  MASTER_COL     ,'Net Cancellation','Value at RSP','ICM01106'  ,75       
	UNION
	SELECT 'NQLC' AS calculative_col,'SUM((a.quantity*sku_names.lc)*-1' as COL_EXPR_2,'NET_CNC_QTY' AS  MASTER_COL     ,'Net Cancellation','Value at LC','ICM01106'    ,75     

	 INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'NCN Val at PP(W/O DEP.)' as col_header,'NCNPPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)*-1' as COL_EXPR_2,'NET_CNC_QTY' AS  MASTER_COL      ,'Net Cancellation','Value at PP(W/O DEP.)','ICM01106'  ,75      
	


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)     
	SELECT 'WPQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'WSL_QTY' AS MASTER_COL     ,'Gross Wholesale','Quantity','INM01106'    ,80
	UNION
	SELECT 'WPM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL   ,'Gross Wholesale','Value at RSP','INM01106'     ,80
	UNION
	SELECT 'GWSLNETRATE' AS calculative_col,'SUM(a.rfnet)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL      ,'Gross Wholesale','Value at Rate','INM01106'    ,80 
	UNION
	SELECT 'WPP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL    ,'Gross Wholesale','Value at PP','INM01106'    ,80   
	UNION
	SELECT 'WPLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL  ,'Gross Wholesale','Value at LC','INM01106'    ,80 
	UNION
	SELECT 'WSLRXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL   ,'Gross Wholesale','Value at Xfer','INM01106'    ,80 
	UNION
	SELECT 'WSLCRXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL ,'Gross Wholesale','Value at Current Xfer','INM01106'     ,80
	UNION
	SELECT 'WPNW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL ,'Gross Wholesale','Value at WSP','INM01106'     ,80
	UNION
	SELECT 'WSLTAXAMT' AS calculative_col,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL  ,'Gross Wholesale','Tax/GST','INM01106'    ,80 
	UNION
	SELECT 'WSLGSTCESS' AS calculative_col,'SUM(A.Gst_Cess_Amount)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL  ,'Gross Wholesale','','INM01106'    ,80 
	UNION
	
	SELECT 'GWSLSPROFITAMT' AS calculative_col,'SUM(a.quantity*(((a.rfnet)/a.quantity)-sku_names.pp))' as COL_EXPR,'WSL_QTY' AS  MASTER_COL  ,'Gross Wholesale','','INM01106'     ,80
	UNION
	SELECT 'GWSLSPROFITPER' AS calculative_col,'(SUM(((a.rfnet)/a.quantity)-sku_names.pp)/SUM(sku_names.pp))*100' as COL_EXPR,'WSL_QTY' AS  MASTER_COL ,'Gross Wholesale','','INM01106'  ,80
	
	UNION
	SELECT 'WSLCRXPWGSTC' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL ,'Gross Wholesale','Value at Xfer(W/O GST)','INM01106'     ,80


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'WSL Val at PP(W/O DEP.)' as col_header,'WSLPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'WSL_QTY' AS  MASTER_COL      ,'Gross Wholesale','Value at PP(W/O DEP.)','INM01106'  ,80      
	

	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'WSL Transaction Value' as col_header,'WSLTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst) ' as COL_EXPR,'WSL_QTY' AS  MASTER_COL ,'Gross Wholesale','Transaction Value','INM01106',80
   UNION
   SELECT 'WSL Transaction Value (W/O GST)' as col_header,'WSLTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst) ' as COL_EXPR,'WSL_QTY' AS  MASTER_COL ,'Gross Wholesale','Transaction Value(W/O GST)','INM01106',80
    UNION
   SELECT 'WO Qty' as col_header,'WOQ' AS calculative_col,'SUM(a.quantity) ' as COL_EXPR,'WBO_QTY' AS  MASTER_COL ,'','','INM01106',80
    
	

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)  
	SELECT 'APOQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'APO_QTY' AS MASTER_COL   
	
	

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)
	SELECT 'CRQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR_2,'CHO_QTY' AS MASTER_COL     ,'Challan Out','Quantity','INM01106'  ,25
	UNION
	SELECT 'CRM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL     ,'Challan Out','Value at RSP','INM01106' ,25 
	UNION
	SELECT 'CRDIS' AS calculative_col,'SUM(a.discount_amount+a.inmdiscountamount)' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL     ,'Challan Out','','INM01106'  ,25
	UNION
	SELECT 'CRP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL     ,'Challan Out','Value at PP','INM01106' ,25 
	UNION
	SELECT 'CRLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Value at LC','INM01106'  ,25
	UNION
	SELECT 'CRXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Value at Xfer','INM01106',25  
	UNION
	SELECT 'CRXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Value at Current Xfer','INM01106' ,25 
	UNION
	SELECT 'CRW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Value at WSP','INM01106'  ,25
	UNION
	SELECT 'CRTAXAMT' AS calculative_col,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Tax/GST','INM01106'  ,25
	
	UNION
	SELECT 'CRXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Value at Xfer(W/O GST)','INM01106' ,25 
	

	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'CHO Val at PP(W/O DEP.)' as col_header,'CHVPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Value at PP(W/O DEP.)','INM01106',25
   

   INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'CHO Transaction Value' as col_header,'CHOTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst) ' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Transaction Value','INM01106',25
   UNION
   SELECT 'CHO Transaction Value (W/O GST)' as col_header,'CHOTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst) ' as COL_EXPR_2,'CHO_QTY' AS  MASTER_COL ,'Challan Out','Transaction Value(W/O GST)','INM01106',25
    




	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)  
	SELECT 'NCQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'NET_CHI_QTY' AS MASTER_COL   ,'Net Challan','Quantity','INM01106'  ,30  
	UNION
	SELECT 'NCM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL   ,'Net Challan','Value at RSP','INM01106'    ,30
	UNION
	SELECT 'NCHRDISC' AS calculative_col,'SUM(a.discount_amount+a.pimdiscountamount)' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL  ,'Net Challan','','INM01106'   ,30 
	UNION
	SELECT 'NCP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL   ,'Net Challan','Value at PP','INM01106'      ,30
	UNION
	SELECT 'NCLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at LC','INM01106'    ,30
	UNION
	SELECT 'NCXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at Xfer','INM01106' ,30   
	UNION
	SELECT 'NCXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL,'Net Challan','Value at Current Xfer','INM01106'  ,30 
	UNION
	SELECT 'NCHRW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at WSP','INM01106'  ,30 
	UNION
	SELECT 'NCHRTAXAMT' AS calculative_col,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Tax/GST','INM01106'  ,30 

	UNION
	SELECT 'NCXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL,'Net Challan','Value at Xfer(W/O GST)','INM01106'  ,30 


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'Net CH Val at PP(W/O DEP.)' as col_header,'NCPVWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at PP(W/O DEP.)','INM01106',30
   
   
	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'Net CH Transaction Value' as col_header,'NCTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst) ' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Transaction Value','INM01106',30
   UNION
   SELECT 'Net CH Transaction Value (W/O GST)' as col_header,'NCTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst) ' as COL_EXPR,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Transaction Value(W/O GST)','INM01106',30
    



	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)  
	SELECT 'NCQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR_2,'NET_CHI_QTY' AS MASTER_COL   ,'Net Challan','Quantity','INM01106'   ,30    
	UNION
	SELECT 'NCM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL      ,'Net Challan','Value at RSP','INM01106'    ,30
	UNION
	SELECT 'NCHRDISC' AS calculative_col,'SUM(a.discount_amount+a.CNMDISCOUNTAMOUNT)' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL   ,'Net Challan','','INM01106'  ,30    
	UNION
	SELECT 'NCP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL   ,'Net Challan','Value at PP','INM01106'   ,30   
	UNION
	SELECT 'NCLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at LC','INM01106'   ,30 
	UNION
	SELECT 'NCXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at Xfer','INM01106'   ,30 
	UNION
	SELECT 'NCXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL,'Net Challan','Value at Current Xfer','INM01106'  ,30
	UNION
	SELECT 'NCHRW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL,'Net Challan','Value at WSP','INM01106'  ,30
	UNION
	SELECT 'NCHRTAXAMT' AS calculative_col,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL,'Net Challan','Tax/GST','INM01106'  ,30

	UNION
	SELECT 'NCXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL,'Net Challan','Value at Xfer(W/O GST)','INM01106'  ,30



	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'Net CH Val at PP(W/O DEP.)' as col_header,'NCPVWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at PP(W/O DEP.)','INM01106',30
   
   INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'Net CH Transaction Value' as col_header,'NCTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst) ' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Transaction Value','INM01106',30
   UNION
   SELECT 'Net CH Transaction Value (W/O GST)' as col_header,'NCTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst) ' as COL_EXPR_2,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Transaction Value(W/O GST)','INM01106',30
    


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_3, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)    
	SELECT 'NCQ' AS calculative_col,'SUM(A.QUANTITY)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS MASTER_COL    ,'Net Challan','Quantity','INM01106'  ,30     
	UNION
	SELECT 'NCM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL, 'Net Challan','Value at RSP','INM01106' ,30      
	UNION
	SELECT 'NCHRDISC' AS calculative_col,'SUM(a.discount_amount+a.RMMDISCOUNTAMOUNT)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL , 'Net Challan','','INM01106'  ,30  
	UNION
	SELECT 'NCP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL    ,'Net Challan','Value at PP','INM01106'  ,30
	UNION
	SELECT 'NCLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL,'Net Challan','Value at LC','INM01106'  ,30
	UNION
	SELECT 'NCXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at Xfer','INM01106'   ,30 
	UNION
	SELECT 'NCXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL,'Net Challan','Value at Current Xfer','INM01106'  ,30  
	UNION
	SELECT 'NCHRW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL,'Net Challan','Value at WSP','INM01106'    ,30
	UNION
	SELECT 'NCHRTAXAMT' AS calculative_col,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','TAX/GST','INM01106'   ,30 

	UNION
	SELECT 'NCXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL,'Net Challan','Value at Xfer(W/O GST)','INM01106'  ,30  
	


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_3, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'Net CH Val at PP(W/O DEP.)' as col_header,'NCPVWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)*-1' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at PP(W/O DEP.)','INM01106',30
   
   INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_3, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'Net CH Transaction Value' as col_header,'NCTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst)*-1 ' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Transaction Value','INM01106',30
   UNION
   SELECT 'Net CH Transaction Value (W/O GST)' as col_header,'NCTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst)*-1 ' as COL_EXPR_3,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Transaction Value(W/O GST)','INM01106',30
    


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_4, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)  
	SELECT 'NCQ' AS calculative_col,'SUM(A.QUANTITY)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS MASTER_COL   ,'Net Challan','Quantity','INM01106' ,30    
	UNION
	SELECT 'NCM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL   ,'Net Challan','Value at RSP','INM01106'  ,30 
	UNION
	SELECT 'NCHRDISC' AS calculative_col,'SUM(a.discount_amount+a.INMDISCOUNTAMOUNT)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL    ,'Net Challan','','INM01106',30  
	UNION
	SELECT 'NCP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL    ,'Net Challan','Value at PP','INM01106' ,30
	UNION
	SELECT 'NCLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at LC','INM01106' ,30
	UNION
	SELECT 'NCXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at Xfer','INM01106' ,30
	UNION
	SELECT 'NCXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at Current Xfer','INM01106' ,30
	UNION
	SELECT 'NCHRW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at WSP','INM01106' ,30
	UNION
	SELECT 'NCHRTAXAMT' AS calculative_col,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Tax/GST','INM01106' ,30

	UNION
	SELECT 'NCXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at Xfer(W/O GST)','INM01106' ,30
	

	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_4, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'Net CH Val at PP(W/O DEP.)' as col_header,'NCPVWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)*-1' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Value at PP(W/O DEP.)','INM01106',30
   

   INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_4, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'Net CH Transaction Value' as col_header,'NCTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst)*-1 ' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Transaction Value','INM01106',30
   UNION
   SELECT 'Net CH Transaction Value (W/O GST)' as col_header,'NCTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst)*-1 ' as COL_EXPR_4,'NET_CHI_QTY' AS  MASTER_COL ,'Net Challan','Transaction Value(W/O GST)','INM01106',30
    




	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)  
	SELECT 'GITQ' AS calculative_col,'SUM(A.QUANTITY)*-1' as COL_EXPR,'GIT_QTY' AS MASTER_COL ,'','Quantity','INM01106' ,35
	UNION
	SELECT 'GITM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR,'GIT_QTY' AS  MASTER_COL   ,'','Value at RSP','INM01106' ,35  
	UNION
	SELECT 'GITP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR,'GIT_QTY' AS  MASTER_COL   ,'','Value at PP','INM01106' ,35  
	UNION
	SELECT 'GITLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)*-1' as COL_EXPR,'GIT_QTY' AS  MASTER_COL ,'','Value at LC','INM01106' ,35
	UNION
	SELECT 'GITXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)*-1' as COL_EXPR,'GIT_QTY' AS  MASTER_COL ,'','Value at Xfer','INM01106' ,35
	UNION
	SELECT 'GITXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)*-1' as COL_EXPR,'GIT_QTY' AS  MASTER_COL ,'','Value at Current Xfer','INM01106' ,35
	
	UNION
	SELECT 'GITXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)*-1' as COL_EXPR,'GIT_QTY' AS  MASTER_COL ,'','Value at Xfer(W/O GST)','INM01106' ,35


	UNION
	SELECT 'GITWSP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)*-1' as COL_EXPR,'GIT_QTY' AS  MASTER_COL   ,'','Value at WSP','INM01106' ,35  



	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'GIT Val at PP(W/O DEP.)' as col_header,'GITPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)*-1' as COL_EXPR,'GIT_QTY' AS  MASTER_COL ,'','Value at PP(W/O DEP.)','INM01106',35
   



	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'GITQ' AS calculative_col,'SUM(A.QUANTITY)*-1' as COL_EXPR_2,'GIT_QTY' AS MASTER_COL    ,'','Quantity','INM01106' ,35
	UNION
	SELECT 'GITM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR_2,'GIT_QTY' AS  MASTER_COL    ,'','Value at RSP','INM01106' ,35   
	UNION
	SELECT 'GITP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR_2,'GIT_QTY' AS  MASTER_COL     ,'','Value at PP','INM01106' ,35  
	UNION
	SELECT 'GITLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)*-1' as COL_EXPR_2,'GIT_QTY' AS  MASTER_COL ,'','Value at LC','INM01106' ,35
	UNION
	SELECT 'GITXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)*-1' as COL_EXPR_2,'GIT_QTY' AS  MASTER_COL ,'','Value at Xfer','INM01106' ,35
	UNION
	SELECT 'GITXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)*-1' as COL_EXPR_2,'GIT_QTY' AS  MASTER_COL ,'','Value at Current Xfer','INM01106' ,35

	UNION
	SELECT 'GITWSP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)*-1' as COL_EXPR_2,'GIT_QTY' AS  MASTER_COL     ,'','Value at WSP','INM01106' ,35  

	UNION
	SELECT 'GITXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)*-1' as COL_EXPR_2,'GIT_QTY' AS  MASTER_COL ,'','Value at Xfer(W/O GST)','INM01106' ,35




	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'GIT Val at PP(W/O DEP.)' as col_header,'GITPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)*-1' as COL_EXPR_2,'GIT_QTY' AS  MASTER_COL ,'','Value at PP(W/O DEP.)','INM01106',35
   




	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_3, MASTER_COL ,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)     
	SELECT 'GITQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR_3,'GIT_QTY' AS MASTER_COL    ,'','Quantity','INM01106' ,35 
	UNION
	SELECT 'GITM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR_3,'GIT_QTY' AS  MASTER_COL      ,'','Value at RSP','INM01106' ,35   
	UNION
	SELECT 'GITP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR_3,'GIT_QTY' AS  MASTER_COL      ,'','Value at PP','INM01106' ,35  
	UNION
	SELECT 'GITLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR_3,'GIT_QTY' AS  MASTER_COL  ,'','Value at LC','INM01106' ,35
	UNION
	SELECT 'GITXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR_3,'GIT_QTY' AS  MASTER_COL ,'','Value at Xfer','INM01106' ,35
	UNION
	SELECT 'GITXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR_3,'GIT_QTY' AS  MASTER_COL ,'','Value at Current Xfer','INM01106' ,35

	UNION
	SELECT 'GITWSP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR_3,'GIT_QTY' AS  MASTER_COL      ,'','Value at WSP','INM01106' ,35  
	
	UNION
	SELECT 'GITXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)' as COL_EXPR_3,'GIT_QTY' AS  MASTER_COL ,'','Value at Xfer(W/O GST)','INM01106' ,35
	


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_3, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'GIT Val at PP(W/O DEP.)' as col_header,'GITPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR_3,'GIT_QTY' AS  MASTER_COL ,'','Value at PP(W/O DEP.)','INM01106',35
   




	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_4, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'GITQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR_4,'GIT_QTY' AS MASTER_COL     ,'','Quantity','INM01106' ,35 
	UNION
	SELECT 'GITM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR_4,'GIT_QTY' AS  MASTER_COL      ,'','Value at RSP','INM01106' ,35    
	UNION
	SELECT 'GITP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR_4,'GIT_QTY' AS  MASTER_COL       ,'','Value at PP','INM01106' ,35  
	UNION
	SELECT 'GITLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR_4,'GIT_QTY' AS  MASTER_COL ,'','Value at LC','INM01106' ,35
	UNION
	SELECT 'GITXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR_4,'GIT_QTY' AS  MASTER_COL ,'','Value at Xfer','INM01106' ,35
	UNION
	SELECT 'GITXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR_4,'GIT_QTY' AS  MASTER_COL ,'','Value at Current Xfer','INM01106' ,35

	UNION
	SELECT 'GITWSP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR_4,'GIT_QTY' AS  MASTER_COL      ,'','Value at WSP','INM01106' ,35  
	
	UNION
	SELECT 'GITXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)' as COL_EXPR_4,'GIT_QTY' AS  MASTER_COL ,'','Value at Xfer(W/O GST)','INM01106' ,35

	   
	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_4, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'GIT Val at PP(W/O DEP.)' as col_header,'GITPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR_4,'GIT_QTY' AS  MASTER_COL ,'','Value at PP(W/O DEP.)','INM01106',35
   



	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_5, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)       
	SELECT 'GITQ' AS calculative_col,'SUM(A.git_qty)' as COL_EXPR_5,'GIT_QTY' AS MASTER_COL     ,'','Quantity','INM01106' ,35 
	UNION
	SELECT 'GITM' AS calculative_col,'SUM(a.git_qty*sku_names.mrp)' as COL_EXPR_5,'GIT_QTY' AS  MASTER_COL     ,'','Value at RSP','INM01106' ,35    
	UNION
	SELECT 'GITP1' AS calculative_col,'SUM(a.git_qty*sku_names.pp)' as COL_EXPR_5,'GIT_QTY' AS  MASTER_COL     ,'','Value at PP','INM01106' ,35  
	UNION
	SELECT 'GITLC' AS calculative_col,'SUM(a.git_qty*sku_names.lc)' as COL_EXPR_5,'GIT_QTY' AS  MASTER_COL,'','Value at LC','INM01106' ,35
	UNION
	SELECT 'GITXP' AS calculative_col,'SUM(a.git_qty*SKU_XFP.XFER_PRICE)' as COL_EXPR_5,'GIT_QTY' AS  MASTER_COL,'','Value at Xfer','INM01106' ,35
	UNION
	SELECT 'GITXPC' AS calculative_col,'SUM(a.git_qty*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR_5,'GIT_QTY' AS  MASTER_COL ,'','Value at Current Xfer','INM01106' ,35

	UNION
	SELECT 'GITWSP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR_5,'GIT_QTY' AS  MASTER_COL      ,'','Value at WSP','INM01106' ,35  
	
	UNION
	SELECT 'GITXPWGST' AS calculative_col,'SUM(a.git_qty*SKU_XFP.xfer_price_without_gst)' as COL_EXPR_5,'GIT_QTY' AS  MASTER_COL ,'','Value at Xfer(W/O GST)','INM01106' ,35
	   


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_5, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'GIT Val at PP(W/O DEP.)' as col_header,'GITPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR_5,'GIT_QTY' AS  MASTER_COL ,'','Value at PP(W/O DEP.)','INM01106',35
   



	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)        
	SELECT 'GITQ' AS calculative_col,'SUM(A.git_qty)' as COL_EXPR,'GIT_QTY_OPT' AS MASTER_COL     ,'GIT','Quantity','INM01106' ,35  
	UNION
	SELECT 'GITM' AS calculative_col,'SUM(a.git_qty*sku_names.mrp)' as COL_EXPR,'GIT_QTY_OPT' AS  MASTER_COL   ,'GIT','Value at RSP','INM01106' ,35     
	UNION
	SELECT 'GITP1' AS calculative_col,'SUM(a.git_qty*sku_names.pp)' as COL_EXPR,'GIT_QTY_OPT' AS  MASTER_COL     ,'GIT','Value at PP','INM01106' ,35  
	UNION
	SELECT 'GITLC' AS calculative_col,'SUM(a.git_qty*sku_names.lc)' as COL_EXPR,'GIT_QTY_OPT' AS  MASTER_COL,'GIT','Value at LC','INM01106' ,35
	UNION
	SELECT 'GITXP' AS calculative_col,'SUM(a.git_qty*SKU_XFP.XFER_PRICE)' as COL_EXPR,'GIT_QTY_OPT' AS  MASTER_COL,'GIT','Value at Xfer','INM01106' ,35
	UNION
	SELECT 'GITXPC' AS calculative_col,'SUM(a.git_qty*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR,'GIT_QTY_OPT' AS  MASTER_COL ,'GIT','Value at Current Xfer','INM01106' ,35
	UNION
	SELECT 'GITWSP' AS calculative_col,'SUM(a.git_qty*sku_names.ws_price)' as COL_EXPR,'GIT_QTY_OPT' AS  MASTER_COL     ,'GIT','Value at WSP','INM01106' ,35   


	UNION
	SELECT 'GITXPWGST' AS calculative_col,'SUM(a.git_qty*SKU_XFP.xfer_price_without_gst)' as COL_EXPR,'GIT_QTY_OPT' AS  MASTER_COL ,'GIT','Value at Xfer(W/O GST)','INM01106' ,35




	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'GIT Val at PP(W/O DEP.)' as col_header,'GITPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'GIT_QTY_OPT' AS  MASTER_COL ,'GIT','Value at PP(W/O DEP.)','INM01106',35
   

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_HEADER)  
	SELECT 'PAPPQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'PENDING_APPROVALS_qty_opt' AS MASTER_COL, 'Pending App Qty'   
	UNION
	SELECT 'PAPPM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PENDING_APPROVALS_qty_opt' AS  MASTER_COL, 'Pending App Val at Mrp'    
	UNION
	SELECT 'PAPPP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PENDING_APPROVALS_qty_opt' AS  MASTER_COL, 'Pending App Val at PP'    
	UNION
	SELECT 'PAPPLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'PENDING_APPROVALS_qty_opt' AS  MASTER_COL, 'Pending App Val at LC'
	UNION
	SELECT 'PAPPWSP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'PENDING_APPROVALS_qty_opt' AS  MASTER_COL, 'Pending App Val at WSP'    

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_HEADER)  
	SELECT 'PJWQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'PENDING_JOBWORK_TRADING_opt' AS MASTER_COL, 'Pending JWI Qty'    
	UNION
	SELECT 'PJWVAL' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PENDING_JOBWORK_TRADING_opt' AS  MASTER_COL, 'Pending JWI Val at PP'    

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_HEADER)  
	SELECT 'PWIPQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'wip_qty_opt' AS MASTER_COL, 'Pending WIP Qty'   
	UNION
	SELECT 'PWIPVAL' AS calculative_col,'SUM(a.value)' as COL_EXPR,'wip_qty_opt' AS  MASTER_COL, 'Pending WIP Val'    

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_HEADER)  
	SELECT 'PRPSQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'PENDING_RPS_qty_opt' AS MASTER_COL, 'Pending RPS Qty'    
	UNION
	SELECT 'PRPSM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PENDING_RPS_qty_opt' AS  MASTER_COL, 'Pending RPS Val at MRP'    
	UNION
	SELECT 'PRPSP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PENDING_RPS_qty_opt' AS  MASTER_COL, 'Pending RPS Val at PP'        
	UNION
	SELECT 'PRPSLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'PENDING_RPS_qty_opt' AS  MASTER_COL, 'Pending RPS Val at LC'    

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_HEADER)  
	SELECT 'PWPSQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'PENDING_WPS_qty_opt' AS MASTER_COL, 'Pending WPS Qty'        
	UNION
	SELECT 'PWPSM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PENDING_WPS_qty_opt' AS  MASTER_COL, 'Pending WPS Val at MRP'        
	UNION
	SELECT 'PWPSP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PENDING_WPS_qty_opt' AS  MASTER_COL, 'Pending WPS Val at PP'        
	UNION
	SELECT 'PWPSLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'PENDING_WPS_qty_opt' AS  MASTER_COL, 'Pending WPS Val at LC'        
	UNION
	SELECT 'PWPSW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'PENDING_WPS_qty_opt' AS  MASTER_COL, 'Pending WPS Val at WSP'        

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_HEADER)  
	SELECT 'PDNPSQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'PENDING_DNPS_qty_opt' AS MASTER_COL, 'Pending DNPS Qty'
	UNION
	SELECT 'PDNPSP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PENDING_DNPS_qty_opt' AS  MASTER_COL, 'Pending DNPS Val at PP'            
	UNION
	SELECT 'PDNPSLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'PENDING_DNPS_qty_opt' AS  MASTER_COL, 'Pending DNPS Val at PP'        

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_HEADER)  
	SELECT 'PCNPSQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'PENDING_CNPS_qty_opt' AS MASTER_COL, 'Pending CNPS Qty'
	UNION
	SELECT 'PCNPSM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PENDING_CNPS_qty_opt' AS  MASTER_COL,'Pending CNPS Val at MRP'            
	UNION
	SELECT 'PCNPSW' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'PENDING_CNPS_qty_opt' AS  MASTER_COL, 'Pending CNPS Val at WSP'        


	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)  
	SELECT 'WPSQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'wpi_qty' AS MASTER_COL    
	UNION
	SELECT 'WPSM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'wpi_qty' AS  MASTER_COL    
	UNION
	SELECT 'WPSP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'wpi_qty' AS  MASTER_COL    
	UNION
	SELECT 'WPSW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'wpi_qty' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)  
	SELECT 'WPSTQR' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'wpr_qty' AS MASTER_COL    
	UNION
	SELECT 'WPSRM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'wpr_qty' AS  MASTER_COL    
	UNION
	SELECT 'WPSRP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'wpr_qty' AS  MASTER_COL    
	UNION
	SELECT 'WPRW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'wpr_qty' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)  
	SELECT 'NWPSWQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'PENDING_WPS_QTY' AS MASTER_COL    
	UNION
	SELECT 'NWPSWM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PENDING_WPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NWPSWP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PENDING_WPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NWPSWP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'PENDING_WPS_QTY' AS  MASTER_COL
	UNION
	SELECT 'NWPSLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'PENDING_WPS_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL)  
	SELECT 'NWPSWQ' AS calculative_col,'SUM(A.quantity)*-1' as COL_EXPR_2,'PENDING_WPS_QTY' AS MASTER_COL    
	UNION
	SELECT 'NWPSWM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR_2,'PENDING_WPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NWPSWP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR_2,'PENDING_WPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NWPSWP' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)*-1' as COL_EXPR_2,'PENDING_WPS_QTY' AS  MASTER_COL
	UNION
	SELECT 'NWPSLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)*-1' as COL_EXPR_2,'PENDING_WPS_QTY' AS  MASTER_COL	  

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)  
	SELECT 'NDNPSQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'PENDING_DNPS_QTY' AS MASTER_COL    
	UNION
	SELECT 'NDNPSM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PENDING_DNPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NDNPSPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PENDING_DNPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NDNPSW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'PENDING_DNPS_QTY' AS  MASTER_COL
	UNION
	SELECT 'NDNPILC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'PENDING_DNPS_QTY' AS  MASTER_COL	  

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL)  
	SELECT 'NDNPSQ' AS calculative_col,'SUM(A.quantity)*-1' as COL_EXPR_2,'PENDING_DNPS_QTY' AS MASTER_COL    
	UNION
	SELECT 'NDNPSM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR_2,'PENDING_DNPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NDNPSPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR_2,'PENDING_DNPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NDNPSW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)*-1' as COL_EXPR_2,'PENDING_DNPS_QTY' AS  MASTER_COL
	UNION
	SELECT 'NDNPILC' AS calculative_col,'SUM(a.quantity*sku_names.lc)*-1' as COL_EXPR_2,'PENDING_DNPS_QTY' AS  MASTER_COL	  

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)  
	SELECT 'NCNPSQ' AS calculative_col,'SUM(A.quantity)' as COL_EXPR,'PENDING_CNPS_QTY' AS MASTER_COL    
	UNION
	SELECT 'NCNPSW' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'PENDING_CNPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NCNPSPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PENDING_CNPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NCNPSW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'PENDING_CNPS_QTY' AS  MASTER_COL
	UNION
	SELECT 'NCNPLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'PENDING_CNPS_QTY' AS  MASTER_COL	  

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL)  
	SELECT 'NCNPSQ' AS calculative_col,'SUM(A.quantity)*-1' as COL_EXPR_2,'PENDING_CNPS_QTY' AS MASTER_COL    
	UNION
	SELECT 'NCNPSW' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR_2,'PENDING_CNPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NCNPSPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR_2,'PENDING_CNPS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NCNPSW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)*-1' as COL_EXPR_2,'PENDING_CNPS_QTY' AS  MASTER_COL
	UNION
	SELECT 'NCNPLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)*-1' as COL_EXPR_2,'PENDING_CNPS_QTY' AS  MASTER_COL	  

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)     
	SELECT 'WRQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'WSR_QTY' AS MASTER_COL   ,'WholeSale Return','Quantity','CNM01106'    ,85
	UNION
	SELECT 'WRM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL     ,'WholeSale Return','Value at RSP','CNM01106'  ,85   
	UNION
	SELECT 'GWSRNETRATE' AS calculative_col,'SUM(a.rfnet)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL     ,'WholeSale Return','Value at Rate','CNM01106'  ,85
	UNION
	SELECT 'WRP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL    ,'WholeSale Return','Value at PP','CNM01106'   ,85
	UNION
	SELECT 'WRLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL ,'WholeSale Return','Value at LC','CNM01106'  ,85
	UNION
	SELECT 'WSRRXP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL  ,'WholeSale Return','Value at Xfer','CNM01106'  ,85
	UNION
	SELECT 'WSRCRXPC' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL ,'WholeSale Return','Value at Current Xfer','CNM01106'  ,85
	UNION
	SELECT 'WRNW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL  ,'WholeSale Return','Value at RSP','CNM01106'  ,85
	UNION
	SELECT 'WSRTAXAMT' AS calculative_col,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL ,'WholeSale Return','Tax/GST','CNM01106'  ,85
	UNION
	SELECT 'WSRGSTCESS' AS calculative_col,'SUM(A.Gst_Cess_Amount)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL ,'WholeSale Return','','CNM01106'  ,85

	UNION
	SELECT 'WSRCRXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL ,'WholeSale Return','Value at Xfer(W/O GST)','CNM01106'  ,85
	


	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'WSR Val at PP(W/O DEP.)' as col_header,'WSRPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'WSR_QTY' AS  MASTER_COL ,'WholeSale Return','Value at PP(W/O DEP.)','CNM01106',85
   
	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'WSR Transaction Value' as col_header,'WSRTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst) ' as COL_EXPR,'WSR_QTY' AS  MASTER_COL ,'WholeSale Return','Transaction Value','CNM01106',85
   UNION
   SELECT 'WSR Transaction Value (W/O GST)' as col_header,'WSRTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst) ' as COL_EXPR,'WSR_QTY' AS  MASTER_COL ,'WholeSale Return','Transaction Value(W/O GST)','CNM01106',85
    



	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'NWQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'NET_WSL_QTY' AS MASTER_COL  ,'Net WholeSale','Quantity','INM01106'    ,90
	UNION
	SELECT 'NWM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL   ,'Net WholeSale','Value at RSP','INM01106'  ,90  
	UNION
	SELECT 'NWSLNETRATE' AS calculative_col,'SUM(a.rfnet)' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL    ,'Net WholeSale','Value at Rate','INM01106' ,90
	UNION
	SELECT 'NWP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL    ,'Net WholeSale','Value at PP','INM01106' ,90
	UNION

	SELECT 'NWPTWAX' AS calculative_col,'SUM(a.quantity*(sku_names.pp+sku_oh.tax_amount))' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL    ,'Net WholeSale','Value at PP(TAX)','INM01106' ,90
	UNION


	SELECT 'NWLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Value at LC','INM01106' ,90
	UNION
	SELECT 'NWXFP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Value at Xfer','INM01106' ,90
	UNION
	SELECT 'NWCXFP' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Value at Current Xfer','INM01106' ,90
	UNION
	SELECT 'NWNW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL ,'Net WholeSale','Value at WSP','INM01106' ,90
	UNION
	SELECT 'NWTAXAMT' AS calculative_col,'SUM(isnull(A.igst_amount,0)+isnull(a.sgst_amount,0)+isnull(a.cgst_amount,0)+isnull(item_tax_amount,0))' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Tax/GST','INM01106' ,90
	UNION
	SELECT 'NETWSGSTCESS' AS calculative_col,'SUM(A.Gst_Cess_Amount)' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','','INM01106' ,90
	
	UNION
	SELECT 'NWSLPROFITAMT' AS calculative_col,'SUM(A.QUANTITY*((a.rfnet/a.quantity)-(sku_names.pp+C.tax_amount)))' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL ,'Net WholeSale','','INM01106' ,90

	UNION
	SELECT 'NWCXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Value at Xfer(W/O GST)','INM01106' ,90

	






	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'Net WSL Val at PP(W/O DEP.)' as col_header,'NWSLPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL ,'Net WholeSale','Value at PP(W/O DEP.)','INM01106',90
   
   INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'Net WSL Transaction Value' as col_header,'NWSLTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst) ' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL ,'Net WholeSale','Transaction Value','INM01106',90
   UNION
   SELECT 'Net WSL Transaction Value (W/O GST)' as col_header,'NWSLTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst) ' as COL_EXPR,'NET_WSL_QTY' AS  MASTER_COL ,'Net WholeSale','Transaction Value(W/O GST)','INM01106',90
    



	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)   
	SELECT 'NWQ' AS calculative_col,'SUM(A.QUANTITY)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS MASTER_COL    ,'Net WholeSale','Quantity','INM01106',90
	UNION
	SELECT 'NWM' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL  ,'Net WholeSale','Value at RSP','INM01106'  ,90 
	UNION
	SELECT 'NWSLNETRATE' AS calculative_col,'SUM(a.rfnet)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL    ,'Net WholeSale','Value at Rate','INM01106' ,90
	UNION
	SELECT 'NWP1' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL   ,'Net WholeSale','Value at PP','INM01106'  ,90
	UNION

	SELECT 'NWPTWAX' AS calculative_col,'SUM(a.quantity*(sku_names.pp+sku_oh.tax_amount))*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL   ,'Net WholeSale','Value at PP(TAX)','INM01106'  ,90
	UNION



	SELECT 'NWLC' AS calculative_col,'SUM(a.quantity*sku_names.lc)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Value at LC','INM01106' ,90
	UNION
	SELECT 'NWXFP' AS calculative_col,'SUM(a.quantity*SKU_XFP.XFER_PRICE)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Value at Xfer','INM01106',90
	UNION
	SELECT 'NWCXFP' AS calculative_col,'SUM(a.quantity*SKU_XFP.CURRENT_XFER_PRICE)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Value at Current Xfer','INM01106',90
	UNION
	SELECT 'NWNW' AS calculative_col,'SUM(a.quantity*sku_names.ws_price)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Value at Xfer','INM01106',90
	UNION
	SELECT 'NWTAXAMT' AS calculative_col,'SUM(isnull(A.igst_amount,0)+isnull(a.sgst_amount,0)+isnull(a.cgst_amount,0)+isnull(item_tax_amount,0))*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Tax/GST','INM01106',90

	UNION
	SELECT 'NETWSGSTCESS' AS calculative_col,'SUM(A.Gst_Cess_Amount)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','','INM01106',90


	UNION
	SELECT 'NWSLPROFITAMT' AS calculative_col,'SUM(A.QUANTITY*((a.rfnet/a.quantity)-(sku_names.pp+C.tax_amount)))*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','','INM01106',90
	
	UNION
	SELECT 'NWCXPWGST' AS calculative_col,'SUM(a.quantity*SKU_XFP.xfer_price_without_gst)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL,'Net WholeSale','Value at Xfer(W/O GST)','INM01106',90
	
	

	
	INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,Col_type_order)      
	SELECT 'Net WSL Val at PP(W/O DEP.)' as col_header,'NWSLPWD' AS calculative_col,'SUM(a.quantity*sku_names.PP_WO_DP)*-1' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL ,'Net WholeSale','Value at PP(W/O DEP.)','INM01106',90
   
    INSERT xtreme_reports_exp_COLS	(col_header,calculative_col, COL_EXPR_2, MASTER_COL,COL_TYPE,COL_VALUE_TYPE,MASTER_TABLE,COL_TYPE_ORDER)  
   SELECT 'Net WSL Transaction Value' as col_header,'NWSLTRANVALUE' AS calculative_col,'SUM(a.xn_value_with_gst)*-1 ' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL ,'Net WholeSale','Transaction Value','INM01106',90
   UNION
   SELECT 'Net WSL Transaction Value (W/O GST)' as col_header,'NWSLTRANWOGST' AS calculative_col,'SUM(a.xn_value_without_gst)*-1 ' as COL_EXPR_2,'NET_WSL_QTY' AS  MASTER_COL ,'Net WholeSale','Transaction Value(W/O GST)','INM01106',90
    
		

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'PFIQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'PFI_QTY' AS MASTER_COL    
	UNION
	SELECT 'PFIPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'PFI_QTY' AS  MASTER_COL    
	UNION
	SELECT 'PFIMRP' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'PFI_QTY' AS  MASTER_COL    

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'SCFQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'SCF_QTY' AS MASTER_COL    
	UNION
	SELECT 'SCFPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'SCF_QTY' AS  MASTER_COL    
	UNION
	SELECT 'SCFMRP' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'SCF_QTY' AS  MASTER_COL    

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'CIPQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'CIP_QTY' AS MASTER_COL    
	UNION
	SELECT 'CIPPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'CIP_QTY' AS  MASTER_COL    
	UNION
	SELECT 'CIPMRP' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'CIP_QTY' AS  MASTER_COL    

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'SCCQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'SCC_QTY' AS MASTER_COL    
	UNION
	SELECT 'SCCPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'SCC_QTY' AS  MASTER_COL    
	UNION
	SELECT 'SCCMRP' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'SCC_QTY' AS  MASTER_COL    

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'JWIOQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'JWI_QTY' AS MASTER_COL    
	UNION
	SELECT 'JWIOP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'JWI_QTY' AS  MASTER_COL    
	UNION
	SELECT 'JWIOM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'JWI_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'JWROQ' AS calculative_col,'SUM(D.QUANTITY)' as COL_EXPR,'JWR_QTY' AS MASTER_COL    
	UNION
	SELECT 'JWRSQ' AS calculative_col,'SUM(D.SHRINK_QTY)' as COL_EXPR,'JWR_QTY' AS  MASTER_COL   
	UNION
	SELECT 'JWROP' AS calculative_col,'SUM(D.quantity*sku_names.pp)' as COL_EXPR,'JWR_QTY' AS  MASTER_COL    
	UNION
	SELECT 'JWROM' AS calculative_col,'SUM(D.quantity*sku_names.mrp)' as COL_EXPR,'JWR_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'NJWOQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'NET_JWI_QTY' AS MASTER_COL    
	UNION
	SELECT 'NJWOP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'NET_JWI_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NJWOM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'NET_JWI_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL)
	SELECT 'NJWOQ' AS calculative_col,'SUM(D.QUANTITY+ isnull(D.SHRINK_QTY,0))*-1' as COL_EXPR_2,'NET_JWI_QTY' AS MASTER_COL    
	UNION
	SELECT 'NJWOP' AS calculative_col,'SUM(d.quantity*sku_names.pp)*-1' as COL_EXPR_2,'NET_JWI_QTY' AS  MASTER_COL    
	UNION
	SELECT 'NJWOM' AS calculative_col,'SUM(d.quantity*sku_names.mrp)*-1' as COL_EXPR_2,'NET_JWI_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL)
	SELECT 'SCFQ' AS calculative_col,'SUM(CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)' as COL_EXPR_2,'SCF_QTY' AS MASTER_COL    
	UNION
	SELECT 'SCFPP' AS calculative_col,'SUM((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)*sku_names.pp)' as COL_EXPR_2,'SCF_QTY' AS  MASTER_COL    
	UNION
	SELECT 'SCFMRP' AS calculative_col,'SUM((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)*sku_names.mrp)' as COL_EXPR_2,'SCF_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL)
	SELECT 'SCCQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'SCC_QTY' AS MASTER_COL    
	UNION
	SELECT 'SCCPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'SCC_QTY' AS  MASTER_COL    
	UNION
	SELECT 'SCCMRP' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'SCC_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'TTMQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'TTM_QTY' AS MASTER_COL    
	UNION
	SELECT 'TTMPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'TTM_QTY' AS  MASTER_COL    
	UNION
	SELECT 'TTMMRP' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'TTM_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'DNPIQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'DNPI_QTY' AS MASTER_COL    
	UNION
	SELECT 'DNPIPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'DNPI_QTY' AS  MASTER_COL    
	UNION
	SELECT 'DNPIM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'DNPI_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'DNPSQR' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'DNPR_QTY' AS MASTER_COL    
	UNION
	SELECT 'DNPRPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'DNPR_QTY' AS  MASTER_COL    
	UNION
	SELECT 'DNPSRM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'DNPR_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'MISQP' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'MIS_QTY' AS MASTER_COL    
	UNION
	SELECT 'MISQPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'MIS_QTY' AS  MASTER_COL    
	UNION
	SELECT 'MISQM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'MIS_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'MIRQP' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'MIR_QTY' AS MASTER_COL    
	UNION
	SELECT 'MIRQPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'MIR_QTY' AS  MASTER_COL    
	UNION
	SELECT 'MIRQM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'MIR_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'WTDXNWSLWQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'WTD_WSL' AS MASTER_COL    
	UNION
	SELECT 'WTDXNWSLWQPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'WTD_WSL' AS  MASTER_COL    
	UNION
	SELECT 'WTDXNWSLWQM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'WTD_WSL' AS  MASTER_COL




	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'MTDXNWSLMQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'MTD_WSL' AS MASTER_COL    
	UNION
	SELECT 'MTDXNWSLMQPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'MTD_WSL' AS  MASTER_COL    
	UNION
	SELECT 'MTDXNWSLMQM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'MTD_WSL' AS  MASTER_COL


	   	  
	--Ani

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'YTDXNSYQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'YTD_SLS' AS MASTER_COL   
	
	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'YTDXNSYM' AS calculative_col,'sum(a.net-a.cmm_discount_amount)' as COL_EXPR,'YTD_SLS' AS MASTER_COL    
		
		

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'YTDXNWSLMQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'YTD_WSL' AS MASTER_COL    
	UNION
	SELECT 'YTDXNWSLMQPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'YTD_WSL' AS  MASTER_COL    
	UNION
	SELECT 'YTDXNWSLMQM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'YTD_WSL' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'WTDXNWSRWQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'WTD_WSR' AS MASTER_COL    
	UNION
	SELECT 'WTDXNWSRWQPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'WTD_WSR' AS  MASTER_COL    
	UNION
	SELECT 'WTDXNWSRWQM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'WTD_WSR' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'MTDXNWSRMQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'MTD_WSR' AS MASTER_COL    
	UNION
	SELECT 'MTDXNWSRMQPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'MTD_WSR' AS  MASTER_COL    
	UNION
	SELECT 'MTDXNWSRMQM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'MTD_WSR' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'YTDXNWSRMQ' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'YTD_WSR' AS MASTER_COL    
	UNION
	SELECT 'YTDXNWSRMQPP' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'YTD_WSR' AS  MASTER_COL    
	UNION
	SELECT 'YTDXNWSRMQM' AS calculative_col,'SUM(A.quantity*sku_names.mrp)' as COL_EXPR,'YTD_WSR' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'SLSWSLQTY' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR,'NET_SLS_WSL_QTY' AS MASTER_COL    
	UNION
	SELECT 'SLSMWSLMQTY' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'NET_SLS_WSL_QTY' AS  MASTER_COL    
	UNION
	SELECT 'SLSRWSLRQTY' AS calculative_col,'SUM(a.rfnet)' as COL_EXPR,'NET_SLS_WSL_QTY' AS  MASTER_COL    
	UNION
	SELECT 'SLSPWSLPQTY' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'NET_SLS_WSL_QTY' AS  MASTER_COL    
	UNION
	SELECT 'TSPPER' AS calculative_col,'(SUM(((a.net-a.cmm_discount_amount)/a.quantity)-(sku_names.pp+c.tax_amount))/SUM((sku_names.pp+c.tax_amount)))*100' as COL_EXPR,'NET_SLS_WSL_QTY' AS  MASTER_COL
	UNION
	SELECT 'TSALEPPTAX' AS calculative_col,'SUM(a.quantity*(sku_names.pp+c.tax_amount))' as COL_EXPR,'NET_SLS_WSL_QTY' AS  MASTER_COL
	UNION
	SELECT 'SLSTWSLGST' AS calculative_col,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR,'NET_SLS_WSL_QTY' AS  MASTER_COL
	UNION
	SELECT 'TSWPMT' AS calculative_col,' SUM(a.quantity*(((a.net-a.cmm_discount_amount)/a.quantity)-(sku_names.pp+c.tax_amount)))' as COL_EXPR,'NET_SLS_WSL_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL)
	SELECT 'SLSWSLQTY' AS calculative_col,'SUM(A.QUANTITY)' as COL_EXPR_2,'NET_SLS_WSL_QTY' AS MASTER_COL    
	UNION
	SELECT 'SLSMWSLMQTY' AS calculative_col,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR_2,'NET_SLS_WSL_QTY' AS  MASTER_COL    
	UNION
	SELECT 'SLSRWSLRQTY' AS calculative_col,'SUM(a.rfnet)' as COL_EXPR_2,'NET_SLS_WSL_QTY' AS  MASTER_COL    
	UNION
	SELECT 'SLSPWSLPQTY' AS calculative_col,'SUM(a.quantity*sku_names.pp)' as COL_EXPR_2,'NET_SLS_WSL_QTY' AS  MASTER_COL    
	UNION
	SELECT 'TSPPER' AS calculative_col,'(SUM(((a.net-a.inmdiscountamount)/a.quantity)-(sku_names.pp+c.tax_amount))/SUM((sku_names.pp+c.tax_amount)))*100' as COL_EXPR_2,'NET_SLS_WSL_QTY' AS  MASTER_COL
	UNION
	SELECT 'TSALEPPTAX' AS calculative_col,'SUM(a.quantity*(sku_names.pp+c.tax_amount))' as COL_EXPR_2,'NET_SLS_WSL_QTY' AS  MASTER_COL
	UNION
	SELECT 'SLSTWSLGST' AS calculative_col,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as COL_EXPR_2,'NET_SLS_WSL_QTY' AS  MASTER_COL
	UNION
	SELECT 'TSWPMT' AS calculative_col,' SUM(a.quantity*(((a.net_rate-a.INMDISCOUNTAMOUNT)/a.quantity)-(sku_names.pp+c.tax_amount)))' as COL_EXPR_2,'NET_SLS_WSL_QTY' AS  MASTER_COL

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_3, MASTER_COL)
	SELECT 'SLSWSLQTY' AS calculative_col,'SUM(A.QUANTITY)*-1' as COL_EXPR_3,'NET_SLS_WSL_QTY' AS MASTER_COL    
	UNION
	SELECT 'SLSMWSLMQTY' AS calculative_col,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR_3,'NET_SLS_WSL_QTY' AS  MASTER_COL    
	UNION
	SELECT 'SLSRWSLRQTY' AS calculative_col,'SUM(a.rfnet)*-1' as COL_EXPR_3,'NET_SLS_WSL_QTY' AS  MASTER_COL    
	UNION
	SELECT 'SLSPWSLPQTY' AS calculative_col,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR_3,'NET_SLS_WSL_QTY' AS  MASTER_COL    
	UNION
	SELECT 'TSPPER' AS calculative_col,'(SUM(((a.net-a.CNMDISCOUNTAMOUNT)/a.quantity)-(sku_names.pp+c.tax_amount))/SUM((sku_names.pp+c.tax_amount)))*100*-1' as COL_EXPR_3,'NET_SLS_WSL_QTY' AS  MASTER_COL
	UNION
	SELECT 'TSALEPPTAX' AS calculative_col,'SUM(a.quantity*(sku_names.pp+c.tax_amount))*-1' as COL_EXPR_3,'NET_SLS_WSL_QTY' AS  MASTER_COL
	UNION
	SELECT 'SLSTWSLGST' AS calculative_col,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)*-1' as COL_EXPR_3,'NET_SLS_WSL_QTY' AS  MASTER_COL
	UNION
	SELECT 'TSWPMT' AS calculative_col,' SUM(a.quantity*(((a.net_rate-a.CNMDISCOUNTAMOUNT)/a.quantity)-(sku_names.pp+c.tax_amount)))*-1' as COL_EXPR_3,'NET_SLS_WSL_QTY' AS  MASTER_COL

	
	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,col_header)
	SELECT 'NSWCLPRV' AS calculative_col,'SUM(CASE WHEN ISNULL(ecoupon_id,'''')<>'''' THEN rfnet ELSE 0 END)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net WizClip Realized Value' as col_header    
	UNION ALL
	SELECT 'NSWCLCONPER' AS calculative_col,'ROUND((SUM(CASE WHEN ISNULL(ecoupon_id,'''')<>'''' THEN rfnet ELSE 0 END)/SUM(rfnet))*100,2)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'WizClip Contribution %' as col_header    
	UNION ALL
	SELECT 'NSWCD' AS calculative_col,'SUM(rfnet+(CASE WHEN ISNULL(ecoupon_id,'''') = '''' THEN 0 ELSE cmm_discount_amount   END))' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Realized Value Without Coupon Disc' as col_header    
	UNION ALL
	SELECT 'ECPNDA' AS calculative_col,'SUM(CASE WHEN ISNULL(ecoupon_id,'''')<>'''' THEN cmm_discount_amount ELSE 0 END)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Wizclip Discount' as col_header    
	UNION ALL
	SELECT 'NETTAXROND' AS calculative_col,'SUM(tax_round_off)' as COL_EXPR,'NET_SLS_QTY' AS MASTER_COL,'Net Tax Round Off' as col_header    
	

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'GSLSPROFITAMT' AS calculative_col,'SUM(a.quantity*(((a.rfnet)/a.quantity )-sku_names.pp))' as COL_EXPR,'SLS_QTY' AS  MASTER_COL  
	UNION
	SELECT 'GSLSPROFITPER' AS calculative_col,'(SUM(((a.rfnet)/a.quantity)-sku_names.pp)/SUM(sku_names.pp+0.001))*100' as COL_EXPR,'SLS_QTY' AS  MASTER_COL 	
	
	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL)
	SELECT 'NSLSPROFITAMT' AS calculative_col,'SUM(a.quantity*(((a.rfnet)/a.quantity)-sku_names.pp))' as COL_EXPR,'NET_SLS_QTY' AS  MASTER_COL  
	UNION
	SELECT 'NSLSPROFITPER' AS calculative_col,'(SUM(((a.rfnet)/a.quantity)-sku_names.pp)/SUM(sku_names.pp+0.001))*100' as COL_EXPR,'NET_SLS_QTY' AS  MASTER_COL 	
	



	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR, MASTER_COL,col_header)
	SELECT 'NETWSLITEMDISC' AS calculative_col,'SUM(a.discount_amount)' as COL_EXPR,'NET_WSL_QTY' AS MASTER_COL,'Net WSL Item Discount' AS COL_HEADER

	INSERT xtreme_reports_exp_COLS	(calculative_col, COL_EXPR_2, MASTER_COL,col_header)
	SELECT 'NETWSLITEMDISC' AS calculative_col,'SUM(a.discount_amount)' as COL_EXPR_2,'NET_WSL_QTY' AS MASTER_COL,'Net WSL Item Discount' AS COL_HEADER

	DECLARE @tCols TABLE (col_type VARCHAR(10))

	INSERT @tCols (col_type)
	SELECT 'MTD_'
	UNION
	SELECT 'YTD_'
	UNION
	SELECT 'WTD_'

	DELETE FROM reporttypedetails WHERE xn_type IN ('SALES','PENDINGDOCS') AND rep_code='Z001'

	INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, col_width, cols_Name, 
	div_factor, rep_code, subtotal, xn_type )  
	SELECT 	a.master_col AS BASIC_COL,1 as CalCulated,a.calculative_col as col_expr,a.Col_header,314 as col_Order,1 as col_repeat,
	1 as col_width,a.calculative_col as cols_Name,1 as div_factor,'Z001' AS rep_code,1 as subtotal,
	(CASE WHEN left(a.master_col,7)='PENDING' THEN 'PENDINGDOCS' ELSE  'Sales' END) AS xn_type 
	FROM xtreme_reports_exp_COLS a
	LEFT OUTER JOIN reporttypedetails b ON a.calculative_col=b.cols_Name AND b.rep_code='Z001'
	WHERE a.col_header<>'' AND b.rep_code IS NULL

	INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, col_width, cols_Name, 
	div_factor, rep_code, subtotal, xn_type )  
	SELECT 	(b.col_type+a.master_col) AS BASIC_COL,1 as CalCulated,(b.col_type+left(a.calculative_col,1)+'XX'+SUBSTRING(a.calculative_col,2,len(a.calculative_col))) as col_expr,
	left(b.col_type,3)+' '+a.Col_header,314 as col_Order,1 as col_repeat,
	1 as col_width,(b.col_type+left(a.calculative_col,1)+'XX'+SUBSTRING(a.calculative_col,2,len(a.calculative_col))) as cols_Name,1 as div_factor,'Z001' AS rep_code,1 as subtotal,'Sales' AS xn_type 
	FROM xtreme_reports_exp_COLS a
	JOIN @tCols b ON  1=1
	LEFT OUTER JOIN reporttypedetails c ON (b.col_type+left(a.calculative_col,1)+'XX'+SUBSTRING(a.calculative_col,2,len(a.calculative_col)))
	=c.cols_Name AND c.rep_code='Z001'
	WHERE a.col_header<>'' AND c.rep_code IS NULL AND left(a.master_col,7)<>'PENDING'

	

	update  xtreme_reports_exp_cols  set col_type=  'Job work Issue' , col_value_type= 'Value at RSP',
	master_table= 'jobwork_issue_mst',COL_TYPE_ORDER ='95'
	where master_col in ('JWI_QTY')   and calculative_col = 'JWIOM' 

	update  xtreme_reports_exp_cols  set col_type=  'Job work Issue' , col_value_type= 'Value at PP',
	master_table= 'jobwork_issue_mst',COL_TYPE_ORDER ='95'
	where master_col in ('JWI_QTY')   and calculative_col = 'JWIOP' 

	update  xtreme_reports_exp_cols  set col_type=  'Job work Issue' , col_value_type= 'Quantity',
	master_table= 'jobwork_issue_mst',COL_TYPE_ORDER ='95'
	where master_col in ('JWI_QTY')   and calculative_col = 'JWIOQ' 

	update  xtreme_reports_exp_cols  set col_type=  'Job work Receive' , col_value_type= 'Value at RSP',
	master_table= 'jobwork_issue_mst',COL_TYPE_ORDER ='95'
	where master_col in ('JWR_QTY')   and calculative_col = 'JWROM' 

	update  xtreme_reports_exp_cols  set col_type=  'Job work Receive' , col_value_type= 'Value at PP',
	master_table= 'jobwork_issue_mst',COL_TYPE_ORDER ='95'
	where master_col in ('JWR_QTY')   and calculative_col = 'JWROP' 

	update  xtreme_reports_exp_cols  set col_type=  'Job work Receive' , col_value_type= 'Quantity',
	master_table= 'jobwork_issue_mst',COL_TYPE_ORDER ='95'
	where master_col in ('JWR_QTY')   and calculative_col = 'JWROQ' 


	update  xtreme_reports_exp_cols  set col_type=  'Net Job work Issue' , col_value_type= 'Value at RSP',
	master_table= 'jobwork_issue_mst',COL_TYPE_ORDER ='95'
	where master_col in ('NET_JWI_QTY')   and calculative_col = 'NJWOM' 

	update  xtreme_reports_exp_cols  set col_type=  'Net Job work Issue' , col_value_type= 'Value at PP',
	master_table= 'jobwork_issue_mst',COL_TYPE_ORDER ='95'
	where master_col in ('NET_JWI_QTY')   and calculative_col = 'NJWOP' 

	update  xtreme_reports_exp_cols  set col_type=  'Net Job work Issue' , col_value_type= 'Quantity',
	master_table= 'jobwork_issue_mst',COL_TYPE_ORDER ='95'
	where master_col in ('NET_JWI_QTY')   and calculative_col = 'NJWOQ' 


	
  Delete From reporttypedetails Where Rep_code= 'Z001' and Cols_name like '%GSTCESS%'


 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
 SELECT 	Top 1  BASIC_COL, CalCulated, '' as col_expr, 'Pur Gst Cess Amt' Col_header, 43 col_Order, col_repeat, COL_VALUE_TYPE, col_width, 
 'PURGSTCESS'cols_Name, div_factor, rep_code, 
 subtotal, xn_type FROM reporttypedetails where  rep_code= 'Z001'  and COLS_NAME = 'PUTAXA'

 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
 SELECT 	Top 1  BASIC_COL, CalCulated, '' as col_expr, 'Prt Gst Cess Amt' Col_header, 67 col_Order, col_repeat, COL_VALUE_TYPE, col_width, 
 'PRTGSTCESS'cols_Name, div_factor, rep_code, 
 subtotal, xn_type FROM reporttypedetails where  rep_code= 'Z001'  and COLS_NAME = 'PRTAXA'

 

 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
 SELECT 	Top 1  BASIC_COL, CalCulated, '' as col_expr, 'Net Pur Gst Cess Amt' Col_header, 83 col_Order, col_repeat, COL_VALUE_TYPE, col_width, 
 'NPGSTCESS'cols_Name, div_factor, rep_code, 
 subtotal, xn_type FROM reporttypedetails where  rep_code= 'Z001'  and COLS_NAME = 'NPTAXAMT'


 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
 SELECT 	Top 1  BASIC_COL, CalCulated, '' as col_expr, 'WSL Gst Cess Amt' Col_header, 453 col_Order, col_repeat, COL_VALUE_TYPE, col_width, 
 'WSLGSTCESS'cols_Name, div_factor, rep_code, 
 subtotal, xn_type FROM reporttypedetails where  rep_code= 'Z001'  and COLS_NAME = 'WSLTAXAMT'

 
 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
 SELECT 	Top 1  BASIC_COL, CalCulated, '' as col_expr, 'WSR Gst Cess Amt' Col_header, 516 col_Order, col_repeat, COL_VALUE_TYPE, col_width, 
 'WSRGSTCESS'cols_Name, div_factor, rep_code, 
 subtotal, xn_type FROM reporttypedetails where  rep_code= 'Z001'  and COLS_NAME = 'WSRTAXAMT'

 
 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
 SELECT 	Top 1  BASIC_COL, CalCulated, '' as col_expr, 'Net WSL Gst Cess Amt' Col_header, 572 col_Order, col_repeat, COL_VALUE_TYPE, col_width, 
 'NETWSGSTCESS'cols_Name, div_factor, rep_code, 
 subtotal, xn_type FROM reporttypedetails where  rep_code= 'Z001'  and COLS_NAME = 'NWTAXAMT'

 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
 SELECT 	Top 1  BASIC_COL, CalCulated, '' as col_expr, 'SLS Gst Cess Amt' Col_header, 315 col_Order, col_repeat, COL_VALUE_TYPE, col_width, 
 'SLSGSTCESS'cols_Name, div_factor, rep_code, 
 subtotal, xn_type FROM reporttypedetails where  rep_code= 'Z001'  and COLS_NAME = 'SPGST'

 
 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
 SELECT 	Top 1  BASIC_COL, CalCulated, '' as col_expr, 'SLR Gst Cess Amt' Col_header, 316 col_Order, col_repeat, COL_VALUE_TYPE, col_width, 
 'SLRGSTCESS'cols_Name, div_factor, rep_code, 
 subtotal, xn_type FROM reporttypedetails where  rep_code= 'Z001'  and COLS_NAME = 'SRGST'

 
 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
 SELECT 	Top 1  BASIC_COL, CalCulated, '' as col_expr, 'Net SLS Gst Cess Amt' Col_header, 317 col_Order, col_repeat, COL_VALUE_TYPE, col_width, 
 'NETSGSTCESS'cols_Name, div_factor, rep_code, 
  subtotal, xn_type FROM reporttypedetails where  rep_code= 'Z001'  and COLS_NAME = 'NSGST'


  Delete From reporttypedetails Where Rep_code= 'Z001' and Cols_name like '%JWRSQ%'


  INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
 SELECT 	Top 1  BASIC_COL, CalCulated, '' as col_expr, 'JWR Shrink Qty' Col_header, 1000 col_Order, col_repeat, COL_VALUE_TYPE, col_width, 
 'JWRSQ'cols_Name, div_factor, rep_code, 
  subtotal, xn_type FROM reporttypedetails where  rep_code= 'Z001'  and COLS_NAME = 'JWROQ'



 Delete From reporttypedetails Where Rep_code= 'Z001' and COL_VALUE_TYPE like '%Value at PP(W/O DEP.)%'

 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, 
 col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
select master_col,1,'' as col_expr,col_header,318,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at PP(W/O DEP.)%'

 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, 
 col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
select 'OPS_QTY',1,'' as col_expr,'OBS Val at PP(W/O DEP.)'col_header,6,1,'Value at PP(W/O DEP.)',12, 'OBPWD',1,'Z001',1,'Stock'                                     
from reporttypedetails where cols_name= 'OBP1' and rep_code= 'Z001'

 INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, 
 col_width, cols_Name, 
 div_factor, rep_code, subtotal, xn_type )  
select 'OPS_QTY',1,'' as col_expr,'CBS Val at PP(W/O DEP.)'col_header,9993,1,'Value at PP(W/O DEP.)',12, 'CBPWD',1,'Z001',1,'Stock'                                     
from reporttypedetails where cols_name= 'CBP1' and rep_code= 'Z001'



Delete From reporttypedetails Where Rep_code= 'Z001' and COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' 
 and cols_name not in ('CBXPWG','OBXPWG')

INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, 
 col_width, cols_Name,  div_factor, rep_code, subtotal, xn_type )  
select top 1master_col,1,'' as col_expr,'CHI Val at XFP (W/O GST)' col_header,800,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' and master_col=  'CHI_QTY'
union
select top 1master_col,1,'' as col_expr,'CHO Val at XFP (W/O GST)' col_header,800,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' and master_col=  'CHO_QTY'
union
select top 1master_col,1,'' as col_expr,'Net CHI Val at XFP (W/O GST)' col_header,800,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' and master_col=  'NET_CHI_QTY'
union
select top 1master_col,1,'' as col_expr,'GIT Val at XFP (W/O GST)' col_header,800,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' and master_col=  'GIT_QTY'
union
select top 1master_col,1,'' as col_expr,'GIT Val at XFP (W/O GST)' col_header,800,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' and master_col=  'GIT_QTY_OPT'
union
select top 1master_col,1,'' as col_expr,'SLS Val at XFP (W/O GST)' col_header,800,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' and master_col=  'SLS_QTY'
union
select top 1master_col,1,'' as col_expr,'SLR Val at XFP (W/O GST)' col_header,800,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' and master_col=  'SLR_QTY'
union
select top 1master_col,1,'' as col_expr,'WSL Val at XFP (W/O GST)' col_header,800,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' and master_col=  'WSL_QTY'
union
select top 1master_col,1,'' as col_expr,'WSL Val at XFP (W/O GST)' col_header,800,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' and master_col=  'WSR_QTY'
union
select top 1master_col,1,'' as col_expr,'Net WSL Val at XFP (W/O GST)' col_header,800,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Value at Xfer(W/O GST)%' and master_col=  'NET_WSL_QTY'


Delete From reporttypedetails Where Rep_code= 'Z001' and COL_VALUE_TYPE like '%Transaction Value%'   and  cols_Name not like 'OLD_%'

INSERT reporttypedetails	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, 
col_width, cols_Name,  div_factor, rep_code, subtotal, xn_type )  
select  Distinct master_col,1,'' as col_expr, col_header,810,1,COL_VALUE_TYPE,12, calculative_col,1,'Z001',1,'Miscellaneous'                                     
from xtreme_reports_exp_COLS where COL_VALUE_TYPE like '%Transaction Value%'    and  calculative_col not like 'OLD_%'

delete from  xtreme_reports_exp WHERE MASTER_COL in ( 'IN_QTY','OUT_QTY')
delete from  xtreme_reports_exp_coLS WHERE MASTER_COL  in ( 'IN_QTY','OUT_QTY','NETQTY')


INSERT xtreme_reports_exp	( base_expr, bin_join_col, bin_join_col_2, bin_join_col_3, bin_join_col_4, 
bin_join_col_5, custom_col, loc_join_col, loc_join_col_2, loc_join_col_3, loc_join_col_4, loc_join_col_5,
master_col, product_code_col, XN_dt_COL, XN_dT_COL_2, XN_DT_COL_3,
XN_DT_COL_4, XN_DT_COL_5, XN_NO_COL, XN_NO_COL_2, XN_NO_COL_3, XN_NO_COL_4,
XN_NO_COL_5, xnparty_join_col, xnparty_join_col_2, xnparty_join_col_3, xnparty_join_col_4 )  
SELECT 	  base_expr, bin_join_col, bin_join_col_2, bin_join_col_3, bin_join_col_4, bin_join_col_5,
custom_col, loc_join_col, loc_join_col_2, loc_join_col_3, loc_join_col_4, loc_join_col_5, 
'IN_QTY' AS master_col, product_code_col, XN_dt_COL, XN_dT_COL_2, XN_DT_COL_3, XN_DT_COL_4,
XN_DT_COL_5, XN_NO_COL, XN_NO_COL_2, XN_NO_COL_3, XN_NO_COL_4, XN_NO_COL_5,
xnparty_join_col, xnparty_join_col_2, xnparty_join_col_3, xnparty_join_col_4 
FROM xtreme_reports_exp where master_col in
 (
   'APR_QTY','CHI_QTY','CHI_QTY_HO','DCI_QTY','DNPR_QTY','GRNPSIN_QTY',
   'JWI_QTY','MIR_QTY','PFI_QTY','PUR_QTY','SCF_QTY','SLR_QTY','TTM_QTY',
   'UNC_QTY','wpr_qty','WSR_QTY'
)


INSERT xtreme_reports_exp	( base_expr, bin_join_col, bin_join_col_2, bin_join_col_3, bin_join_col_4, 
bin_join_col_5, custom_col, loc_join_col, loc_join_col_2, loc_join_col_3, loc_join_col_4, loc_join_col_5,
master_col, product_code_col, XN_dt_COL, XN_dT_COL_2, XN_DT_COL_3,
XN_DT_COL_4, XN_DT_COL_5, XN_NO_COL, XN_NO_COL_2, XN_NO_COL_3, XN_NO_COL_4,
XN_NO_COL_5, xnparty_join_col, xnparty_join_col_2, xnparty_join_col_3, xnparty_join_col_4 )  
SELECT 	  base_expr, bin_join_col, bin_join_col_2, bin_join_col_3, bin_join_col_4, bin_join_col_5,
custom_col, loc_join_col, loc_join_col_2, loc_join_col_3, loc_join_col_4, loc_join_col_5, 
'OUT_QTY' AS master_col, product_code_col, XN_dt_COL, XN_dT_COL_2, XN_DT_COL_3, XN_DT_COL_4,
XN_DT_COL_5, XN_NO_COL, XN_NO_COL_2, XN_NO_COL_3, XN_NO_COL_4, XN_NO_COL_5,
xnparty_join_col, xnparty_join_col_2, xnparty_join_col_3, xnparty_join_col_4 
FROM xtreme_reports_exp where master_col in
 (
   'APP_QTY','CHO_QTY','CIP_QTY','CNC_QTY', 'DCO_QTY','DNPI_QTY',
   'GRNPSOUT_QTY','JWR_QTY','MIS_QTY','PRT_QTY','SCC_QTY','SLS_QTY',
  'wpi_qty','WSL_QTY'
  )




  INSERT xtreme_reports_exp_COLS	( calculative_col, COL_EXPR, COL_EXPR_2, COL_EXPR_3, 
  COL_EXPR_4, COL_EXPR_5, col_header, COL_TYPE, COL_TYPE_ORDER, COL_VALUE_TYPE, 
  MASTER_COL, MASTER_TABLE )  
  SELECT top 1 	'OUTQTY'  calculative_col, 'SUM(A.QUANTITY)' AS COL_EXPR, COL_EXPR_2, COL_EXPR_3, COL_EXPR_4, COL_EXPR_5,
  'Total Out Qty' As col_header, 'OUTWARD' COL_TYPE, 333 as COL_TYPE_ORDER,'Quantity' as  COL_VALUE_TYPE,   'OUT_QTY' as MASTER_COL,
 MASTER_TABLE 
  FROM xtreme_reports_exp_COLS
  where master_col = 'WSL_QTY' 



  INSERT xtreme_reports_exp_COLS	( calculative_col, COL_EXPR, COL_EXPR_2, COL_EXPR_3, 
  COL_EXPR_4, COL_EXPR_5, col_header, COL_TYPE, COL_TYPE_ORDER, COL_VALUE_TYPE, 
  MASTER_COL, MASTER_TABLE )  
  SELECT top 1 	'INQTY'  calculative_col, 'SUM(A.QUANTITY)' AS COL_EXPR, COL_EXPR_2, COL_EXPR_3, COL_EXPR_4, COL_EXPR_5,
  'Total In Qty' As col_header, 'INWARD' COL_TYPE, 333 as COL_TYPE_ORDER,'Quantity' as  COL_VALUE_TYPE,   'IN_QTY' as MASTER_COL,
 MASTER_TABLE 
  FROM xtreme_reports_exp_COLS
  where master_col = 'WSL_QTY' 
  
   INSERT xtreme_reports_exp_COLS	( calculative_col, COL_EXPR, COL_EXPR_2, COL_EXPR_3, 
  COL_EXPR_4, COL_EXPR_5, col_header, COL_TYPE, COL_TYPE_ORDER, COL_VALUE_TYPE, 
  MASTER_COL, MASTER_TABLE )  
  SELECT top 1 	'NETQTY'  calculative_col, 'SUM(A.QUANTITY)' AS COL_EXPR, COL_EXPR_2, COL_EXPR_3, COL_EXPR_4, COL_EXPR_5,
  'Net Balance Qty' As col_header, 'Balance' COL_TYPE, 333 as COL_TYPE_ORDER,'Quantity' as  COL_VALUE_TYPE,   'NETQTY' as MASTER_COL,
 MASTER_TABLE 
  FROM xtreme_reports_exp_COLS
  where master_col = 'WSL_QTY' 


END









