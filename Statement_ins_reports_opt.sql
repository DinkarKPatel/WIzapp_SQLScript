
 INSERT reports_opt	( advsetting, for_email, g_report_file, inactive, last_update, lbl, module_name, page_no, printer_name, report_name, report_no, report_type, row_id, SubFolderName, XTab )  
 SELECT 	  A.advsetting, ISNULL(A.for_email,''), A.g_report_file,0 inactive, A.last_update, A.lbl, A.module_name, A.page_no,null printer_name,A. report_name, A.report_no, 
 CASE WHEN A.LBL =1 THEN 3 ELSE 1 END report_type, newid() row_id,null SubFolderName, A.XTab 
 FROM reports A
 LEFT JOIN reports_opt B ON A.g_report_file =B.g_report_file AND A.module_name =B.module_name AND A.g_report_file =B.g_report_file 
 WHERE B.g_report_file IS NULL
 

 INSERT reports_opt	( advsetting, for_email, g_report_file, inactive, last_update, lbl, module_name, page_no, printer_name, report_name, report_no, report_type, row_id, SubFolderName, XTab )  
 SELECT A.advsetting, ISNULL(A.for_email,''), A.g_report_file, A.inactive, A.last_update, A.lbl, A.module_name, A.page_no, A.printer_name, A.report_name, 0 report_no, 
 CASE WHEN A.LBL =1 THEN 3 ELSE 1 END report_type, newid() row_id, A.SubFolderName,A. XTab 
 FROM
 (
 SELECT 0 AS ADVSETTING,0 AS  FOR_EMAIL,FILE_NAME AS G_REPORT_FILE,0 AS INACTIVE,GETDATE() AS LAST_UPDATE,0 AS LBL,
 CASE WHEN XN_TYPE='WSL' THEN 'FRMWSLINVOICE' 
      WHEN XN_TYPE='ARC' THEN 'FRMADVREC' 
	  WHEN XN_TYPE='POSCASHIER' THEN 'POSCASHIER' 
	  WHEN XN_TYPE='PRT' THEN 'FRMTRANPURCHASERETURN' 
	  WHEN XN_TYPE='PUR' THEN 'FRMTRANPURCHASEINVOICE' 
	  WHEN XN_TYPE='SLS' THEN 'FRMSALE' 
	  WHEN XN_TYPE='WSR' THEN 'FRMWSCRNOTE' 
 ELSE 'FIXREPORTS' END  AS MODULE_NAME, 
 1 AS PAGE_NO,  A.PRINTER_NAME,A.REPORT_NAME,
         1 AS REPORT_TYPE,ROW_ID,NULL AS SUBFOLDERNAME,0 AS XTAB
 FROM GST_REPORT_CONFIG A
 ) A
 LEFT JOIN reports_opt B ON A.g_report_file =B.g_report_file AND A.module_name =B.module_name AND A.g_report_file =B.g_report_file 
 WHERE B.g_report_file IS NULL


UPDATE  A  SET A.G_REPORT_FILE=  B.D_REPORT_FILE 
FROM  REPORTS_OPT  A JOIN REPORTS B ON A.REPORT_NAME = B.REPORT_NAME
WHERE   B.LBL= 1 and  ISNULL(A.G_REPORT_FILE,'')=''

