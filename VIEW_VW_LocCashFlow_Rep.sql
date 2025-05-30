CREATE VIEW VW_LOCCASHFLOW_REP
--WITH ENCRYPTION  
AS  
SELECT	C.DEPT_ID,C.DEPT_ALIAS, C.DEPT_NAME,D.DEPARTMENT_ID,D.DEPARTMENT_NAME,
		A.PAYSLIP_MONTH, A.PAYSLIP_YEAR,
		SUM(CASE WHEN B.MODE_OF_PAYMENT=3 THEN A.NET_SALARY - A.EMPLOYER_ESI_AMOUNT-A.EMPLOYER_PF_AMOUNT ELSE 0 END) AS CASH,
		SUM(CASE WHEN B.MODE_OF_PAYMENT=1 THEN A.NET_SALARY - A.EMPLOYER_ESI_AMOUNT-A.EMPLOYER_PF_AMOUNT ELSE 0 END) AS SELFCHEQUE,
		SUM(CASE WHEN B.MODE_OF_PAYMENT=0 THEN A.NET_SALARY - A.EMPLOYER_ESI_AMOUNT-A.EMPLOYER_PF_AMOUNT ELSE 0 END) AS CHEQUE, 
		SUM(CASE WHEN B.MODE_OF_PAYMENT=4 THEN A.NET_SALARY - A.EMPLOYER_ESI_AMOUNT-A.EMPLOYER_PF_AMOUNT ELSE 0 END) AS BANK,    		
		B.EMP_STATUS, B.CO_ALIAS
FROM EMP_PAYSLIP_MST A 
JOIN EMP_MST B			ON A.EMP_ID=B.EMP_ID
JOIN LOCATION C			ON B.DEPT_ID=C.DEPT_ID
JOIN EMP_DEPARTMENT D	ON B.DEPARTMENT_ID=D.DEPARTMENT_ID
WHERE A.CANCELLED = 0
GROUP BY C.DEPT_ID,C.DEPT_ALIAS,D.DEPARTMENT_ID,D.DEPARTMENT_NAME, A.PAYSLIP_MONTH, 
		A.PAYSLIP_YEAR, B.EMP_STATUS, B.CO_ALIAS, C.DEPT_NAME
