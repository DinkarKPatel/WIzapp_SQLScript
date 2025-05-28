CREATE PROCEDURE SP_PPC_APPROVED_LIST
 (
  @CFINYEAR VARCHAR(5)='01119'
 )
 AS
 BEGIN
     
     EXEC SPPPC_FILTER_PPC_BUYER_ORDER 1,'','','','','','','','','',@CFINYEAR,0
 
     EXEC SPPC_PO 1,'',0,'',@CFINYEAR,0,0
     
     EXEC SPPPC_FG_PENDING_BAROCDE 3,'','','','','','',0,0,'','','',@CFINYEAR
     
     EXEC SPPPC_FG_ISSUE_BAROCDE_NEW 4,'','','','','','',0,'',@CFINYEAR,''
 
 
 END
