IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMTRANPO')
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMTRANPO','PURCHASE ORDER',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMTRANPURCHASEINVOICE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMTRANPURCHASEINVOICE','PARTY / GROUP PURCHASE',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMTRANPURCHASERETURN')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMTRANPURCHASERETURN','PARTY / DEBIT NOTE',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMWSLINVOICE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMWSLINVOICE','PARTY / GROUP INVOICE',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMWSCRNOTE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMWSCRNOTE','PARTY / GROUP CREDIT NOTE',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMSALE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMSALE','RETAIL SALE',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='PACKSLIP')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'PACKSLIP','RETAIL PACKSLIP',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMDEBINOTEPACKSLIP-G')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMDEBINOTEPACKSLIP-G','GROUP WHOLESALE PACKSLIP',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMINVOICEPACKSLIP')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMINVOICEPACKSLIP','PARTY WHOLESALE PACKSLIP',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMDEBINOTEPACKSLIP-G')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMDEBINOTEPACKSLIP-G','GROUP DEBIT NOTE PACKSLIP',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMDEBINOTEPACKSLIP')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMDEBINOTEPACKSLIP','PARTY  DEBIT NOTE PACKSLIP',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMCASHIERMODULE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMCASHIERMODULE','CASHIER MODULE',GETDATE())

IF EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMBOOKINWARDSUPPLIERS' AND XN_DESC='BOOK INWARD SUPPLY')
   DELETE FROM DFM_XNTYPE WHERE XN_TYPE='FRMBOOKINWARDSUPPLIERS' AND XN_DESC='BOOK INWARD SUPPLY'

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMBOOKINWARDSUPPLIERS')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMBOOKINWARDSUPPLIERS','BOOK INWARD SUPPLIES/EXPENSES',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMBUYERSORDER')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMBUYERSORDER','RETAIL BUYER ORDER',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMBUYERSORDER_WSL')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMBUYERSORDER_WSL','WHOLESALE BUYER ORDER',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMADVREC')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMADVREC','CUSTOMER RECEIPT / PAYMENT',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMAPPROVALSALE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMAPPROVALSALE','APPROVAL ISSUE',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMAPPROVALRETURNNEW')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMAPPROVALRETURNNEW','APPROVAL RETURN',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMPCEXPENSE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMPCEXPENSE','PETTY CASH EXPENSE',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMPCOUT')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMPCOUT','PETTY CASH OUT',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMRATEREVISION')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMRATEREVISION','ITEM RATE REVISION',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMITMCNC')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMITMCNC','ITEM CANCELLATION',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='SPLITNCOMBINE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'SPLITNCOMBINE','SPLIT & COMBINE',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMJOBWORKISSUE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMJOBWORKISSUE','JOB WORK ISSUE',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMJOBWORKRECEIVE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMJOBWORKRECEIVE','JOB WORK RECEIPT',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHENTRY')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHENTRY','VOUCHER ENTRY',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHPOSTING')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHPOSTING','VOUCHER POSTING',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMPARCEL')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMPARCEL','PARCEL ENTRY',GETDATE())

IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHENTRY_JOURNAL')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHENTRY_JOURNAL','VOUCHER ENTRY(JOURNAL)',GETDATE())
IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHENTRY_PAYMENT')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHENTRY_PAYMENT','VOUCHER ENTRY(PAYMENT)',GETDATE())
IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHENTRY_RECEIPT')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHENTRY_RECEIPT','VOUCHER ENTRY(RECEIPT)',GETDATE())
IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHENTRY_CREDIT NOTE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHENTRY_CREDIT NOTE','VOUCHER ENTRY(CREDIT NOTE)',GETDATE())
IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHENTRY_DEBIT NOTE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHENTRY_DEBIT NOTE','VOUCHER ENTRY(DEBIT NOTE)',GETDATE())
IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHENTRY_PURCHASE')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHENTRY_PURCHASE','VOUCHER ENTRY(PURCHASE)',GETDATE())
IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHENTRY_SALES')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHENTRY_SALES','VOUCHER ENTRY(SALES)',GETDATE())
IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHENTRY_CONTRA')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHENTRY_CONTRA','VOUCHER ENTRY(CONTRA)',GETDATE())
IF NOT EXISTS(SELECT XN_TYPE FROM DFM_XNTYPE WHERE XN_TYPE='FRMVCHENTRY_CASH_ON_HAND')	
INSERT DFM_XNTYPE ( XN_TYPE, XN_DESC, LAST_UPDATE )  VALUES ( 'FRMVCHENTRY_CASH_ON_HAND','VOUCHER ENTRY(CASH ACCOUNT ENTRIES)',GETDATE())
