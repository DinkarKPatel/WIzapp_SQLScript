CREATE VIEW VW_CHI_PRINT_MST

AS
		SELECT A.*,C.DEPT_ID AS SOURCE_DEPT_ID,(C.DEPT_ID + ' ' + C.DEPT_NAME) AS  SOURCE_DEPT_NAME,
			  T.DEPT_ID AS TARGET_DEPT_ID,(T.DEPT_ID + ' ' + T.DEPT_NAME) AS  TARGET_DEPT_NAME,
			  D.USERNAME,E.FORM_NAME                                 
		FROM CIM01106 A (NOLOCK)          
		LEFT OUTER JOIN LOCATION C (NOLOCK) ON SUBSTRING(CHALLAN_NO,1,2)  = C.DEPT_ID
		LEFT OUTER JOIN LOCATION T (NOLOCK) ON SUBSTRING(CHALLAN_NO,3,2)  = T.DEPT_ID      
		LEFT OUTER JOIN USERS D (NOLOCK) ON A.USER_CODE= D.USER_CODE  
		LEFT OUTER JOIN FORM E (NOLOCK) ON A.FORM_ID= E.FORM_ID
