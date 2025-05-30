CREATE PROCEDURE SP_CUSTOMER_EXCEL_COLS
--WITH ENCRYPTION

AS          
BEGIN 
SELECT 'USER CUSTOMER CODE' AS MASTER_COL,'USER_CUSTOMER_CODE' AS MASTER_COL_EXPR,'' AS MAPPED_COL         
UNION ALL         
SELECT 'CUSTOMER TITLE' AS MASTER_COL,'PREFIX_NAME' AS MASTER_COL_EXPR,'' AS MAPPED_COL            
UNION ALL  
SELECT 'CUSTOMER FIRST NAME' AS MASTER_COL,'CUSTOMER_FNAME' AS MASTER_COL_EXPR,'' AS MAPPED_COL            
UNION ALL           
SELECT 'CUSTOMER LAST NAME' AS MASTER_COL,'CUSTOMER_LNAME' AS MASTER_COL_EXPR,'' AS MAPPED_COL            
UNION ALL     
SELECT 'ADDRESS 1' AS MASTER_COL,'ADDRESS1' AS MASTER_COL_EXPR,'' AS MAPPED_COL            
UNION ALL              
SELECT 'ADDRESS 2' AS MASTER_COL,'ADDRESS2' AS MASTER_COL_EXPR,'' AS MAPPED_COL            
UNION ALL        
SELECT 'ADDRESS 3' AS MASTER_COL,'ADDRESS3' AS MASTER_COL_EXPR,'' AS MAPPED_COL            
UNION ALL        
SELECT 'ADDRESS 4' AS MASTER_COL,'ADDRESS4' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'AREA' AS MASTER_COL,'AREA' AS MASTER_COL_EXPR,'' AS MAPPED_COL

UNION ALL        
SELECT 'CITY' AS MASTER_COL,'CITY' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'PINCODE' AS MASTER_COL,'PIN' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'STATE' AS MASTER_COL,'STATE' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'DATE OF BIRTH' AS MASTER_COL,'DOB' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'DATE OF ANNIVERSARY' AS MASTER_COL,'DOA' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'PHONE NO (R)' AS MASTER_COL,'PHONE_H' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'PHONE NO (O)' AS MASTER_COL,'PHONE_O' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'EMAIL' AS MASTER_COL,'EMAIL' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'CARD NO' AS MASTER_COL,'CARDNO' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'CARD ISSUE DATE' AS MASTER_COL,'CARDISSUEDT' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'CARD EXPIRY DATE' AS MASTER_COL,'CARDEXPIRYDT' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'FLAT DISCOUNT CUSTOMER' AS MASTER_COL,'FLAT_DISC_CUSTOMER' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'FLAT DISCOUNT %' AS MASTER_COL,'FLAT_DISC_PERCENTAGE' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'MOBILE' AS MASTER_COL,'MOBILE' AS MASTER_COL_EXPR,'' AS MAPPED_COL
UNION ALL        
SELECT 'REFERED BY' AS MASTER_COL,'REF_CUSTOMER_CODE' AS MASTER_COL_EXPR,'' AS MAPPED_COL
END
