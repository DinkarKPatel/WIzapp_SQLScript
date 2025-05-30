INSERT LM_BROKER_DETAILS	( AC_CODE, BROKER_AC_CODE, BROKER_COMM_PERCENT, LAST_UPDATE )  
SELECT 	  A.AC_CODE, CASE WHEN LM.AC_CODE IS NULL THEN '0000000000' ELSE  A.BROKER_AC_CODE END, A.BROKER_COMM_PERCENT,GETDATE() LAST_UPDATE 
FROM LMV01106 A (NOLOCK)
LEFT OUTER JOIN LM_BROKER_DETAILS B (NOLOCK) ON B.AC_CODE=A.AC_CODE
LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.BROKER_AC_CODE 
WHERE ISNULL(THROUGH_BROKER,0) =1 AND B.AC_CODE IS NULL
