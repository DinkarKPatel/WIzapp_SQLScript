IF NOT EXISTS (SELECT TOP 1 AGENCY_CODE FROM PRD_AGENCY_MST WHERE AGENCY_CODE='00000') 
	 INSERT PRD_AGENCY_MST	( AC_CODE, INACTIVE, REMARKS, AGENCY_CODE, AGENCY_NAME )  
	 SELECT '0000000000' AS AC_CODE,0 AS INACTIVE,'' AS REMARKS, '00000' AS AGENCY_CODE,'' AS AGENCY_NAME
