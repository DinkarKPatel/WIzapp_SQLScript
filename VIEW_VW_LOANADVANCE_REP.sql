CREATE VIEW VW_LOANADVANCE_REP      
--WITH ENCRYPTION
AS                                  
	SELECT          
   T0.LOAN_ID   AS MST_MEMO_NO,        
   T1.REF_ID   AS MST_REF_ID,        
   T1.EMP_FNAME +' ' +T1.EMP_LNAME  AS EMP_NAME,      
   CONVERT(DATETIME,T0.LOAN_DATE,105) AS MST_XN_DT,        
   T0.TENURE   AS MST_TENURE_MONTHS,        
   T0.LOAN_AMOUNT  AS CAL_LOAN_AMOUNT,    
   T0.APPROVED_AMOUNT AS CAL_APPROVED_AMOUNT,      
   T0.EMI_AMOUNT  AS CAL_EMI_AMOUNT,        
   T2.DESIG_NAME  AS MST_DESIG_NAME,        
   T3.DEPARTMENT_NAME AS MST_DEPARTMENT_NAME,        
   T1.EMAIL1   AS MST_EMAIL1,         
   T1.MOBILE1   AS MST_MOBILE1,        
   T1.PAN_NO   AS MST_PAN_NO,        
   T1.ID_PROOF_DOC_NO AS MST_ID_PROOF_DOC_NO,        
   CASE         
   WHEN T1.ID_PROOF_DOC_TYPE = 0 THEN 'DRIVING LICENCE'         
   WHEN T1.ID_PROOF_DOC_TYPE = 1 THEN 'PASSPORT'         
   WHEN T1.ID_PROOF_DOC_TYPE = 2 THEN 'VOTER ID CARD'         
   ELSE 'OTHERS'         
   END     AS MST_ID_PROOF_DOC_TYPE,        
   CASE         
   WHEN T0.LOAN_TYPE = 1 THEN 'LOAN'                                     
   ELSE 'ADVANCE'         
   END     AS MST_LOAN_TYPE,        
   CASE         
   WHEN T0.SETTLEMENT_TYPE = 1 THEN 'ONE TIME'         
   ELSE 'EMI'         
   END     AS MST_SETTLEMENT_TYPE        
 FROM EMP_LOAN_MST T0                                    
 JOIN EMP_MST T1   (NOLOCK) ON T0.EMP_ID = T1.EMP_ID                                    
 JOIN EMP_DESIG T2  (NOLOCK) ON T2.DESIG_ID = T1.DESIG_ID                                    
 JOIN EMP_DEPARTMENT T3 (NOLOCK) ON T3.DEPARTMENT_ID = T1.DEPARTMENT_ID
