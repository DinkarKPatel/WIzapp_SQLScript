CREATE VIEW VW_PUR_PRINT_MST

AS
	SELECT D.USERNAME AS 'CREATED_USERNAME', E.USERNAME AS 'MODIFIED_USERNAME',   
	   C.AC_NAME AS SUPP_NAME, C.ADDRESS1 + ' ' + C.ADDRESS2 + ', ' + C.AREA_NAME +   
	   ' ' + C.CITY + ' ' + C.STATE AS 'SUPP_ADDRESS',  A.*   
	FROM PIM01106 A  
	JOIN LMV01106 C (NOLOCK) ON A.AC_CODE = C.AC_CODE  
	JOIN USERS D (NOLOCK) ON A.USER_CODE = D.USER_CODE  
	JOIN USERS E (NOLOCK) ON A.EDT_USER_CODE = E.USER_CODE
