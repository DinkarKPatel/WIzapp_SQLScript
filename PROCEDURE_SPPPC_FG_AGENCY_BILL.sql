CREATE PROCEDURE SPPPC_FG_AGENCY_BILL  
(  
 @NQUERYID INT=0,
 @CAC_CODE VARCHAR(10)=''
)
 AS
 BEGIN
 IF @NQUERYID=1
    GOTO LBLFIRSTISSUEBILL
 ELSE 
    GOTO END_PROC
    
    LBLFIRSTISSUEBILL:
    
	 SELECT DISTINCT BM.BILL_NO
	 FROM PPC_AGENCY_ISSUE_FG_FIRST_MST  A
	 JOIN PPC_AGENCY_ISSUE_FG_FIRST_DET B ON A.MEMO_ID =B.MEMO_ID 
	 JOIN PPC_FG_SKU C ON C.PRODUCT_CODE =B.PRODUCT_CODE 
	 JOIN PPC_FGBCG_DET DET ON DET.ROW_ID =C.PPC_FGBCG_DET_ROW_ID 
	 JOIN PPC_FGBCG_MST MST ON MST.MEMO_ID =DET.MEMO_ID 
	 JOIN PPC_BUYER_ORDER_DET BD ON BD.ROW_ID =DET.BO_DET_ROW_ID 
	 JOIN PPC_BUYER_ORDER_MST BM ON BM.ORDER_ID =BD.ORDER_ID 
	 WHERE (@CAC_CODE='' OR A.AC_CODE =@CAC_CODE)
	 
	 GOTO END_PROC
	 END_PROC:
 END
