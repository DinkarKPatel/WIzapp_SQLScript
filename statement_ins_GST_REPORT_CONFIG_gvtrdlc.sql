if not exists (select [File_Name] from GST_REPORT_CONFIG (NOLOCK) WHERE [File_Name]='GVT.RDLC')
 INSERT GST_REPORT_CONFIG	( Default1, File_Name, For_Email, lbl, OPEN_FORMAT, PRINTER_NAME, Report_Name, ROW_ID, XN_Type )
  SELECT 	0 Default1,'GVT.RDLC' File_Name,null For_Email,null lbl,null OPEN_FORMAT, 
  '' PRINTER_NAME, 'THERMAL-3INCH-GV RECEIPT' Report_Name,'5BE6FD2A-FC4C-4A24-90B6-845ECD49DE83' ROW_ID,
   'arc' XN_Type 
