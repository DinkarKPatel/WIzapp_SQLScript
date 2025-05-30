CREATE VIEW VW_LOANADVANCE                
--WITH ENCRYPTION
AS                              
	SELECT	T0.LOAN_ID			AS MST_LOAN_ID,     
		T0.LOAN_ID			AS MST_MEMO_NO,    
		T1.REF_ID			AS MST_REF_ID,    
		T1.EMP_FNAME		AS MST_EMP_FNAME,    
		T1.EMP_LNAME		AS MST_EMP_LNAME,    
		T0.LOAN_DATE		AS MST_LOAN_DATE,    
		T0.TENURE			AS MST_TENURE,    
		T1.EMP_ID,    
		T0.LOAN_ID,    
		T0.LOAN_AMOUNT		AS MST_LOAN_AMOUNT,    
		T0.INTEREST_RATE	AS MST_INTEREST_RATE,    
		T0.EMI_AMOUNT		AS MST_EMI_AMOUNT,     
		T2.DESIG_NAME		AS MST_DESIG_NAME,    
		T3.DEPARTMENT_NAME AS MST_DEPARTMENT_NAME,    
		T1.COMPANY_CODE,     
		T1.EMAIL1			AS MST_EMAIL1,     
		T1.MOBILE1			AS MST_MOBILE1,          
		T1.PAN_NO			AS MST_PAN_NO,    
		T1.ID_PROOF_DOC_NO AS MST_ID_PROOF_DOC_NO,    
		T1.PHONES_H		AS MST_PHONES_H,
		T1.IMG_NAME,
		CASE     
		WHEN T0.LOAN_TYPE = 1 THEN 'LOAN'                               
		ELSE 'ADVANCE'     
		END				AS MST_LOAN_TYPE,    
		CASE     
		WHEN T0.SETTLEMENT_TYPE = 1 THEN 'ONE TIME'     
		ELSE 'EMI'     
		END				AS MST_SETTLEMENT_TYPE,    
		CASE     
		WHEN T1.ID_PROOF_DOC_TYPE = 0 THEN 'DRIVING LICENCE'     
		WHEN T1.ID_PROOF_DOC_TYPE = 1 THEN 'PASSPORT'     
		WHEN T1.ID_PROOF_DOC_TYPE = 2 THEN 'VOTER ID CARD'     
		ELSE 'OTHERS'     
		END				AS MST_ID_PROOF_DOC_TYPE,
		T0.APPROVED_AMOUNT AS MST_APPROVED_AMOUNT  
		,T0.LOAN_STATUS  
	FROM EMP_LOAN_MST T0                              
	JOIN EMP_MST T1			(NOLOCK) ON T0.EMP_ID = T1.EMP_ID                              
	JOIN EMP_DESIG T2		(NOLOCK) ON T2.DESIG_ID = T1.DESIG_ID                              
	JOIN EMP_DEPARTMENT T3	(NOLOCK) ON T3.DEPARTMENT_ID = T1.DEPARTMENT_ID
