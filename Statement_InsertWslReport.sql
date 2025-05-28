  IF NOT EXISTS(select Report_type from reports_opt where report_type=1) 
 Begin 
	 INSERT reports_opt	( g_report_file, lbl, advsetting, last_update, row_id, module_name,
	 page_no, report_no, report_name, for_email, report_type, inactive,xtab )  
	 SELECT  FILE_NAME as  g_report_file,0 as lbl, Default1 as advsetting, getdate() as last_update, 'H1' + cast(newid()as varchar(38))as row_id, 'frmWSLInvoice' as module_name, 1 as page_no,
	 0 as report_no, report_name, 0 as for_email, 1 report_type,0 inactive ,0
	 FROM gst_report_config where  XN_Type='WSl'
	 UNION
	 SELECT   g_report_file, lbl, advsetting, getdate() last_update, 'H1' + cast(newid()as varchar(38)) as row_id, module_name, page_no,
	 report_no, report_name, 0 as for_email,1 report_type, 0 as inactive ,0
	  FROM Reports (NOLOCK) Where module_name='frmWSLInvoice'  
  End