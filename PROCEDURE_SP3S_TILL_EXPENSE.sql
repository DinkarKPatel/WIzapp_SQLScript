CREATE PROCEDURE SP3S_TILL_EXPENSE
(
	 @NQUERYID NUMERIC(2)
	,@CMEMOID VARCHAR(100)=''
	,@CUSERCODE VARCHAR(10)=''

)
--WITH ENCRYPTION
AS 
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	     

IF @NQUERYID=1
	GOTO LBL_GETMASTER
IF @NQUERYID=2
	GOTO LBL_GETDETAIL
IF @NQUERYID=3
	GOTO LBL_GETLMV
	
ELSE 
	GOTO END_PROC
	
LBL_GETMASTER:
	
SELECT 	
A.*,C.USERNAME
FROM TILL_EXPENSE_MST A
JOIN TILL_SHIFT_MST B ON A.SHIFT_ID=B.SHIFT_ID
JOIN USERS C ON A.USER_CODE=C.USER_CODE	
WHERE A.MEMO_ID=@CMEMOID
	
GOTO END_PROC
	
LBL_GETDETAIL:
	
	SELECT A.*,B.AC_NAME ,
	(CASE WHEN XN_TYPE= 'CR' THEN 'RECEIPT' ELSE 'PAYMENT' END ) AS DISPLAY_XN_TYPE
	FROM TILL_EXPENSE_DET A
	JOIN LMV01106 B ON B.AC_CODE=A.AC_CODE
	WHERE MEMO_ID=@CMEMOID
	ORDER BY AC_NAME 
	
	GOTO END_PROC			
						
			
		
LBL_GETLMV:

 DECLARE @CHEAD_CODE VARCHAR(MAX)     
 SET @CHEAD_CODE=''    
 SELECT @CHEAD_CODE=@CHEAD_CODE+DBO.FN_ACT_TRAVTREE(HEAD_CODE)        
 FROM PETTY_CASH_AC (NOLOCK)    
 SELECT AC_CODE,AC_NAME        
 FROM LMV01106         
 WHERE (CHARINDEX(HEAD_CODE,@CHEAD_CODE)>0 OR @CHEAD_CODE='' ) 
 AND  INACTIVE=0 AND AC_CODE<>'0000000000'
 GOTO END_PROC	    
        

END_PROC:	
END
--END OF PROCEDURE - SP3S_TILL_EXPENSE
