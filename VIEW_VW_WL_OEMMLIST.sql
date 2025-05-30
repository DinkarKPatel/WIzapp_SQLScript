CREATE VIEW VW_WL_OEMMLIST  

AS       
SELECT  A.OEM_CODE AS MEMO_ID,
A.OEM_NAME AS OEM_NAME, 
A.OEM_ID AS OEM_ID,  
A.OEM_ADD1+' '+A.OEM_ADD2 + ' ' + A.OEM_ADD3  AS ADDRESS, 

A.OEM_PHONE AS OEM_PHONE,
A.OEM_WEB,OEM_EMAIL,    
 (CASE WHEN A.INACTIVE=0 THEN 'NO' ELSE 'YES' END) AS INACTIVE 
FROM OEM_MST A
