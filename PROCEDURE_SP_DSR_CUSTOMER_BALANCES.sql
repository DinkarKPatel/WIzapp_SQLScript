create PROCEDURE SP_DSR_CUSTOMER_BALANCES--CHANGE
(											--PARAMETERS
	@DFROMDT		DATETIME,				--1. REPORT FROM DT
	@DTODT			DATETIME,				--2. REPORT TO DT
	@CWITHDETAILS	BIT,					--3. 0. SUMMARY; 1. SUMMARY WITH DETAILS
	@BESTIMATEENABLED BIT = 1,				--CHANGE
	@CDEPT_ID VARCHAR(4)=''
)
--WITH ENCRYPTION
AS
BEGIN 
--(dinkar) Replace  left(memoid,2) to Location_code 
		DECLARE @CCMD NVARCHAR(MAX)
	
		SET @CCMD= N'SELECT A.CUSTOMER_CODE, A.USER_CUSTOMER_CODE, A.CUSTOMER_TITLE, A.CUSTOMER_FNAME, A.CUSTOMER_LNAME, 
			 B.ADDRESS1, B.ADDRESS2, --B.AREA, B.CITY, B.PIN, 
			 '''' AS [XN_TYPE], CONVERT(DATETIME,'''') AS [XN_DT], '''' AS [XN_NO], '''' AS ADJ_BILL_NO, 0 AS ITEM_DR_AMOUNT, 0 AS ITEM_CR_AMOUNT,0 AS ITEM_AMOUNT, 
			 '''' AS NARRATION, 1 AS GRP, 
			 SUM( CASE WHEN XN_DT < ''' + CONVERT(VARCHAR(20), @DFROMDT) + ''' THEN (DR_AMOUNT-CR_AMOUNT) ELSE 0 END ) AS OP_BAL, 
			 SUM( CASE WHEN XN_DT BETWEEN  ''' + CONVERT(VARCHAR(20), @DFROMDT) + ''' AND ''' + CONVERT(VARCHAR(20), @DTODT) + ''' THEN (DR_AMOUNT) ELSE 0 END ) AS DR_AMOUNT, 
			 SUM( CASE WHEN XN_DT BETWEEN  ''' + CONVERT(VARCHAR(20), @DFROMDT) + ''' AND ''' + CONVERT(VARCHAR(20), @DTODT) + ''' THEN (CR_AMOUNT) ELSE 0 END ) AS CR_AMOUNT, 
			 SUM(DR_AMOUNT-CR_AMOUNT) AS CL_BAL ,'''' AS SALESPERSON
			 FROM CUSTDBXN A 
			 JOIN CUSTDYM B ON A.CUSTOMER_CODE = B.CUSTOMER_CODE 
			 WHERE A.XN_DT <= ''' +  CONVERT(VARCHAR(20), @DTODT) + '''
			 AND (A.MEMO_TYPE = 1 OR A.MEMO_TYPE = 0 OR '+CONVERT(NVARCHAR(2), @BESTIMATEENABLED)+' = 1)  --CHANGE
			 '+(CASE WHEN @CDEPT_ID='' THEN '' ELSE 'AND A.DEPT_ID='''+@CDEPT_ID+'''' END)+' GROUP BY A.CUSTOMER_CODE, A.USER_CUSTOMER_CODE, A.CUSTOMER_TITLE, A.CUSTOMER_FNAME, A.CUSTOMER_LNAME, 
			 B.ADDRESS1, B.ADDRESS2--, B.AREA, B.CITY, B.PIN 
			 HAVING SUM(DR_AMOUNT-CR_AMOUNT) <> 0 '
			--SET @CCMD= @CCMD + N' ORDER BY A.CUSTOMER_FNAME, A.CUSTOMER_LNAME, A.USER_CUSTOMER_CODE, XN_DT, XN_NO '

			 PRINT @CCMD
			 --EXEC SP_EXECUTESQL @CCMD
		IF @CWITHDETAILS=1
				SET @CCMD= @CCMD + N' UNION ALL 
				SELECT A.CUSTOMER_CODE, A.USER_CUSTOMER_CODE, A.CUSTOMER_TITLE, 
				 A.CUSTOMER_FNAME, A.CUSTOMER_LNAME,  '''' AS ADDRESS1, '''' AS ADDRESS2,  
				 --'''' AS AREA, '''' AS CITY, '''' AS PIN,  
				 A.XN_TYPE, A.XN_DT, A.XN_NO, A.ADJ_BILL_NO,  
				 A.DR_AMOUNT AS ITEM_DR_AMOUNT, A.CR_AMOUNT AS ITEM_CR_AMOUNT, 
				 (CASE WHEN A.DR_AMOUNT>0 THEN A.DR_AMOUNT WHEN A.CR_AMOUNT<>0 THEN -A.CR_AMOUNT END)  AS ITEM_AMOUNT, 
				 A.NARRATION, 2 AS GRP, 0 AS OP_BAL, 0 AS DR_AMOUNT, 0 AS CR_AMOUNT, 0 AS CL_BAL,A.SALESPERSON  
				 FROM CUSTDBXN A 
				 WHERE XN_DT BETWEEN  ''' + CONVERT(VARCHAR(20),@DFROMDT) + ''' AND ''' + CONVERT(VARCHAR(20),@DTODT) + '''
				 AND (A.MEMO_TYPE = 1 OR A.MEMO_TYPE = 0  OR '+CONVERT(NVARCHAR(2),@BESTIMATEENABLED)+' = 1)  --CHANGE
				 AND A.CUSTOMER_CODE IN ( SELECT CUSTOMER_CODE FROM CUSTDBXN  
									 WHERE XN_DT <= ''' + CONVERT(VARCHAR(20),@DTODT) + ''' AND (MEMO_TYPE = 1 OR A.MEMO_TYPE = 0  OR '+CONVERT(NVARCHAR(2),@BESTIMATEENABLED)+' = 1)  --CHANGE
				'+(CASE WHEN @CDEPT_ID='' THEN '' ELSE 'AND A.DEPT_ID='''+@CDEPT_ID+'''' END)+'
				GROUP BY CUSTOMER_CODE HAVING SUM(DR_AMOUNT-CR_AMOUNT) <> 0 )'
									   
		SET @CCMD= @CCMD + N' ORDER BY A.CUSTOMER_FNAME, A.CUSTOMER_LNAME, A.USER_CUSTOMER_CODE, XN_DT, XN_NO '
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
	
END
--******************************************* END OF PROCEDURE SP_DSR_CUSTOMER_BALANCES
