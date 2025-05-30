CREATE VIEW VW_EMPDETAILS_REP 
--WITH ENCRYPTION
AS
SELECT 
A.CO_ALIAS,
A.EMP_ID,
A.REF_ID,
A.EMP_FNAME + ' ' + A.EMP_LNAME AS EMPNAME,
A.PARENT_NAME,    
B.DEPARTMENT_ID,
B.DEPARTMENT_NAME,
C.DESIG_ID,
C.DESIG_NAME,
LOC.DEPT_ID,
LOC.DEPT_NAME,
LOC.DEPT_ALIAS,
E.PAY_ID,
E.PAY_NAME,
E.PAY_TYPE,    
E.PAY_ORDER,
D.ALIAS,
A.BASIC_SALARY,
D.EXPRESSION,
ISNULL(D.AMOUNT,0) AS AMOUNT,
D.ROW_ID,
CASE 
	WHEN E.PAY_TYPE=1 THEN 'DEDUCTION' 
	WHEN E.PAY_TYPE=2 THEN 'ADDITION' 
END AS PTNAME,
A.PF_ENABLED,
A.ESI_ENABLED,
A.PF_AMOUNT,
A.DATE_OF_JOINING,
A.MODE_OF_PAYMENT,
CASE 
	WHEN A.MODE_OF_PAYMENT = 0 THEN 'CHEQUE' 
	WHEN A.MODE_OF_PAYMENT = 1 THEN 'SELF CHEQUE' 
	WHEN A.MODE_OF_PAYMENT = 3 THEN 'CASH'
	WHEN A.MODE_OF_PAYMENT = 4 THEN 'BANK' 
	ELSE '' 
END AS MOP,
EMP_STATUS,E.DONOT_DEDUCT_IN_GROSS_SALARY
FROM EMP_MST A    
INNER JOIN EMP_DEPARTMENT B ON A.DEPARTMENT_ID=B.DEPARTMENT_ID    
INNER JOIN EMP_DESIG C ON A.DESIG_ID=C.DESIG_ID    
INNER JOIN LOCATION LOC ON A.DEPT_ID=LOC.DEPT_ID    
LEFT OUTER JOIN EMP_SALARY_PROFILE D ON A.EMP_ID=D.EMP_ID    
LEFT OUTER JOIN EMP_PAY E ON D.PAY_ID=E.PAY_ID
