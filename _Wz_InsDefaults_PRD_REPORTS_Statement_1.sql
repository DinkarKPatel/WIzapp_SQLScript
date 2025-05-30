DELETE FROM PRD_REPORTS --WHERE REPORT_NAME IN('1.WO PENDING FOR (CO PCS)','2. WO PENDING FOR (CO RM)','3. PENDING SHORT RM CO','4. PENDING SHORT RM ISSUE')

IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='1.PENDING WO PCS FOR CUTTING')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='PWPP.RDLC', D_REPORT_FILE='',  LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(), 
 REPORT_GROUP='1.PENDING', CUSTOM_REPORT='', NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=1, REPORT_NAME='1.PENDING WO PCS FOR CUTTING', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO =0
END
 
IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='2.PENDING RM FOR CUTTING (REPORT-1)')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='PSRM.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(), 
 REPORT_GROUP='1.PENDING', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=2, REPORT_NAME='2.PENDING RM FOR CUTTING (REPORT-1)', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO =0
END 

IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='3.SHORT RAW MATERIAL')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='RMRR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(), 
 REPORT_GROUP='1.PENDING', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=3, REPORT_NAME='3.SHORT RAW MATERIAL', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
END 


IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='4.SHORT RAW MATERIAL FOR AGENCY')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='PSRMI.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='1.PENDING', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=4, REPORT_NAME='4.SHORT RAW MATERIAL FOR AGENCY', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END

--DELETE FROM PRD_REPORTS WHERE REPORT_NAME='5. AGENCY PENDING REPORT RM'
IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='5. AGENCY PENDING REPORT RM')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='APRM.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='1.PENDING', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=4, REPORT_NAME='5. AGENCY PENDING REPORT RM', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END

DELETE FROM PRD_REPORTS WHERE REPORT_NAME='5. AGENCY PENDING REPORT'

IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='6. AGENCY PENDING REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='AJWPS.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='1.PENDING', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=4, REPORT_NAME='6. AGENCY PENDING REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 
IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='7. AGENCY DYING REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='AJDY.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='1.PENDING', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=4, REPORT_NAME='7. AGENCY DYING REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END


IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='8. BUYER PENDING REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='BPR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='1.PENDING', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=4, REPORT_NAME='8. BUYER PENDING REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 


--DELETE  FROM PRD_REPORTS WHERE REPORT_NAME='6. AGENCY PENDING REPORT'




DELETE FROM PRD_REPORTS WHERE REPORT_NAME='1. DAILY RAW MATERIAL ISSUE'

IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='1. DAILY RAW MATERIAL ISSUE')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='DRMIR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='2.DAILY RAW MATERIAL', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=5, REPORT_NAME='1. DAILY RAW MATERIAL ISSUE', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 
 END
 



DELETE FROM PRD_REPORTS WHERE REPORT_NAME='2. DAILY RAW MATERIAL RECEIPT'



IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='2. DAILY RAW MATERIAL RECEIPT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='DRMRR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='2.DAILY RAW MATERIAL', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=2, REPORT_NO=5, REPORT_NAME='2. DAILY RAW MATERIAL RECEIPT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 
 END
 



--DELETE  FROM PRD_REPORTS WHERE REPORT_NAME='1. BARCODE STOCK REPORT'

IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='1. BARCODE STOCK REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='BSR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='3.BARCODE STOCK REPORT', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=5, REPORT_NAME='1. BARCODE STOCK REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 
 END
 


DELETE FROM PRD_REPORTS WHERE REPORT_NAME='2. WIP STOCK REPORT'



IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='2. WIP STOCK REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='WSR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='3.BARCODE STOCK REPORT', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=5, REPORT_NAME='2. WIP STOCK REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 
 END
 




--DELETE FROM PRD_REPORTS WHERE REPORT_NAME='1. NET APPROVAL REPORT'


IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='1. NET APPROVAL REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='NAR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='4.NET APPROVAL REPORT', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=6, REPORT_NAME='1. NET APPROVAL REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 
 END



--DELETE FROM PRD_REPORTS WHERE REPORT_NAME='1. UPC PRODUCTION STATUS '


IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='1. UPC PRODUCTION STATUS ')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='PSRUPC.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='6. UPC PRODUCTION STATUS', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=7, REPORT_NAME='1. UPC PRODUCTION STATUS ', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 
 
 
 
 
--DELETE FROM PRD_REPORTS WHERE REPORT_NAME='2. UPC AGENCY PENDING REPORT '

IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='2. UPC AGENCY PENDING REPORT ')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='UAPR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='6. UPC PRODUCTION STATUS', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=8, REPORT_NAME='2. UPC AGENCY PENDING REPORT ', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 

--DELETE  FROM PRD_REPORTS WHERE REPORT_NAME='3. UPC PRD STATUS WITH WO'
 
IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='3. UPC PRD STATUS WITH WO')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='PSRUPCWO.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='6. UPC PRODUCTION STATUS', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=8, REPORT_NAME='3. UPC PRD STATUS WITH WO', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 
 END


DELETE FROM PRD_REPORTS WHERE REPORT_NAME='3. ORDER PENDING FOR FULFILMENT'




IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='4. ORDER PENDING FOR FULFILMENT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='UPCBPR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='6. UPC PRODUCTION STATUS', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=8, REPORT_NAME='4. ORDER PENDING FOR FULFILMENT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 
 


IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='5. PENDING WSL REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='TTT.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='6. UPC PRODUCTION STATUS', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=8, REPORT_NAME='5. PENDING WSL REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 
 

IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='6. WIP STATUS REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='WIPS.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='6. UPC PRODUCTION STATUS', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=8, REPORT_NAME='6. WIP STATUS REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 
 

IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='7. BARCODE ALLOCATION REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='BAR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='6. UPC PRODUCTION STATUS', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=8, REPORT_NAME='7. BARCODE ALLOCATION REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 
 


IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='1. PRODUCTION STATUS REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='PSR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='5.PRODUCTION STATUS REPORT', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=6, REPORT_NAME='1. PRODUCTION STATUS REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 




 
IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='2. SUMMARY PROD STATUS REPORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='SPSR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='5.PRODUCTION STATUS REPORT', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=6, REPORT_NAME='2. SUMMARY PROD STATUS REPORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 


--DELETE FROM PRD_REPORTS WHERE REPORT_NAME='7. MERCHANT PENDING REPRORT'

 
IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='7. MERCHANT PENDING REPRORT')
BEGIN
 INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
 SELECT 	  G_REPORT_FILE='MSPSR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
 REPORT_GROUP='7. MERCHANT PENDING REPRORT', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA', PAGE_NO=1, REPORT_NO=9, REPORT_NAME='7. MERCHANT PENDING REPRORT', 
 FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
 END
 
 
 IF NOT EXISTS (SELECT TOP 1 'U' FROM PRD_REPORTS WHERE REPORT_NAME='9. AGENCY JOB RATE WISE RECEIVED')
   BEGIN
     INSERT PRD_REPORTS	( G_REPORT_FILE, D_REPORT_FILE, LBL, DRAFT, ADVSETTING, LAST_UPDATE, ROW_ID, REPORT_GROUP, CUSTOM_REPORT, NOOFCOPIES, LPT_NO, MODULE_NAME, PAGE_NO, REPORT_NO, REPORT_NAME, FOR_EMAIL, REPORT_HIDE, XTAB, UDRF, REPORT_GRP_NO )  
     SELECT G_REPORT_FILE='AWJR.RDLC', D_REPORT_FILE='', LBL=0, DRAFT=0, ADVSETTING=0, LAST_UPDATE=GETDATE(), ROW_ID=NEWID(),  
     REPORT_GROUP='1.PENDING', CUSTOM_REPORT=0, NOOFCOPIES=0, LPT_NO=0, MODULE_NAME='PRD_FIXREPORTS_BETA'
     ,PAGE_NO=1, REPORT_NO=4, REPORT_NAME='9. AGENCY JOB RATE WISE RECEIVED', 
     FOR_EMAIL=0, REPORT_HIDE=0, XTAB=0, UDRF=0, REPORT_GRP_NO=0 
   END
