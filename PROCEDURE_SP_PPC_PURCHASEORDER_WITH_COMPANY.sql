CREATE PROCEDURE SP_PPC_PURCHASEORDER_WITH_COMPANY          
(          
 @CQUERYID  NUMERIC(2),          
 @CWHERE   VARCHAR(100)='',          
 @CFINYEAR  VARCHAR(5)='',          
 @CDEPTID  VARCHAR(2)='',          
 @NNAVMODE  NUMERIC(2)=1,          
 @CWHERECLAUSE   VARCHAR(500)=''          
)         
----WITH ENCRYPTION        
         
AS          
BEGIN          
DECLARE @CCMD NVARCHAR(MAX)          
SET @CCMD=''          
 IF @CQUERYID=2          
  GOTO LBLMST                
 ELSE               
  GOTO LAST          
                     
           
LBLMST:          
          
 SELECT A.ORDER_TYPE, BILL.BILL_NO, CONVERT(VARCHAR,PO_DT,105) AS PO_DT1, A.*, CR.USERNAME CR_CREATED_BY, AP.USERNAME AP_APPROVED_BY,0.00 AS TOTAL_QTY,          
   B.AC_NAME
   , C.DEPT_NAME
   ,C.DEPT_ID 
   ,[ADDRESS]= B.ADDRESS0+', '+ B.ADDRESS1+', '+  B.ADDRESS2+', '+ B.AREA_NAME
   , B.CITY
   , B.PINCODE, B.STATE, B.SST_NO,            
   B.SST_DT, B.TIN_NO, B.TIN_DT,D.USERNAME,E.USERNAME AS EDT_USERNAME ,          
   (C.ADDRESS1 +' '+ C.ADDRESS2) AS STORE_ADDRESS  
   ,PM.TERM_NAME,PM.MEMO_ID  --ADD BY JAI RAM KUMAR   
   ,CP.COMPANY_NAME
   ,COMPANY_ADDRESS=CP.ADDRESS1+' '+CP.ADDRESS2
   , CP.CITY AS COMPANY_CITY,CP.[STATE] COMPANY_STATE,CP.PIN AS COMPANY_PIN,AR.AREA_NAME AS COMPANY_AREA ,
   CP.LOGO_PATH,
   'GST NO: '+ISNULL(CP.GST_NO,'')  AS GST_NO,
   'GST NO: '+ISNULL(B.AC_GST_NO,'')  AS AC_GST_NO
   FROM PPC_POM01106 A             
   JOIN LMV01106 B ON A.AC_CODE = B.AC_CODE             
   JOIN USERS D ON A.USER_CODE = D.USER_CODE             
   JOIN USERS E ON A.EDT_USER_CODE = E.USER_CODE    
   LEFT JOIN USERS CR ON A.CREATED_BY=CR.USER_CODE
   LEFT JOIN USERS AP ON A.APPROVED_BY=AP.USER_CODE
   LEFT JOIN DBO.PPC_TERM_CONDITION_MST PM ON A.TERMS_MEMO_ID = PM.MEMO_ID   --ADD BY JAI RAM KUMAR        
   JOIN LOCATION C ON A.DEPT_ID = C.DEPT_ID 
   LEFT JOIN COMPANY CP ON CP.COMPANY_CODE='01'
   LEFT JOIN AREA AR ON AR.AREA_CODE=CP.AREA_CODE        
   LEFT JOIN  
 (  
  SELECT D.BILL_NO ,A.PO_ID   FROM PPC_POD01106 A  
  JOIN PPC_BO_ART_BOM B ON BO_BOM_ROW_ID =B.ROW_ID   
  JOIN PPC_BUYER_ORDER_DET  C ON C.ROW_ID  =B.REF_ROW_ID  
  JOIN PPC_BUYER_ORDER_MST D ON C.ORDER_ID =D.ORDER_ID   
  GROUP BY D.BILL_NO ,A.PO_ID   
 ) BILL ON BILL.PO_ID =A .PO_ID           
   WHERE A.PO_ID = @CWHERE               
            
    GOTO LAST          
              
LAST:          
END
