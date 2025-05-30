create VIEW VW_WSR_PRINT_MST

AS
	SELECT '' AS FORM_NAME , USERS.USERNAME,  C.AC_NAME AS SUPP_NAME, 
           C.ADDRESS1 + ' ' + C.ADDRESS2 + ', ' + C.AREA_NAME + ' ' + C.CITY + ' ' + C.STATE AS 'SUPP_ADDRESS',
           CNM01106.*, CONVERT(CHAR(10),CASE WHEN CN_DT='' THEN NULL ELSE CN_DT END ,105)  AS CN_DT1
    FROM CNM01106  
    JOIN USERS ON CNM01106.USER_CODE = USERS.USER_CODE 
    JOIN LMV01106 C ON CNM01106.AC_CODE = C.AC_CODE
