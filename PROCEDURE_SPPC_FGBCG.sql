CREATE PROC SPPC_FGBCG               
@NMODE NUMERIC(2,0),        
@VNAME VARCHAR(500)            
AS BEGIN               
----1.BIND MEMONO              
IF(@NMODE=1)              
BEGIN              
SELECT MEMO_ID,MEMO_NO FROM PPC_FGBCG_MST              
END              
              
----2.BIND GRID              
IF(@NMODE=2)              
BEGIN              
SELECT TOP 10 BILL_NO,ORDER_ID FROM  PPC_BUYER_ORDER_MST A WHERE A.CANCELLED<>'1' AND A.BILL_NO LIKE '%'+ @VNAME +'%'          
END        
          
              
END
