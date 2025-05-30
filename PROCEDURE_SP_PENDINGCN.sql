CREATE PROCEDURE SP_PENDINGCN
(
	@CCUSTOMERCODE	VARCHAR(40),
	@CCURCMID		VARCHAR(40),
	@CTYPE			VARCHAR(40),
	@XN_TYPE VARCHAR(10),
	@CPARTYACCODE CHAR(10)='',
	@CIGNOREMEMOID	VARCHAR(MAX),
	@CLOCID        VARCHAR(5)='',
	@CMEMONO		VARCHAR(MAX)='%'
	
)
--WITH ENCRYPTION
AS
BEGIN
	DECLARE @cCutoffDate VARCHAR(10),@cCmd NVARCHAR(MAX)
	
	SELECT TOP 1 @cCutoffDate=value FROM config(NOLOCK) WHERE config_option='CUTOFF_DATE_FOR_PENDING_ADV_CN_CR'


	DECLARE @cCustDetails TABLE(CUSTOMER_CODE VARCHAR(50),USER_CUSTOMER_CODE VARCHAR(50), MOBILE VARCHAR(50))


	CREATE TABLE #tmpIgnore (memo_id varchar(40))
	Create table #DetailTable([TYPE] VARCHAR(10), MEMO_NO VARCHAR(100),MEMO_ID VARCHAR(50), NET_AMOUNT NUMERIC(14,2),[MEMO_DT] DATETIME, REF_NO VARCHAR(100),ADJ_LOCATION_CODE VARCHAR(10))
	CREATE TABLE #CREDITNOTES(ADJ_MEMO_ID VARCHAR(50),ADJ_AMOUNT NUMERIC(14,2))
	CREATE TABLE #CREDITNOTES_SUM(ADJ_MEMO_ID VARCHAR(50),ADJ_AMOUNT NUMERIC(14,2))
	CREATE TABLE #ADVANCES(ADJ_MEMO_ID VARCHAR(50),ADJ_AMOUNT NUMERIC(14,2))
	CREATE TABLE #ADVANCES_SUM(ADJ_MEMO_ID VARCHAR(50),ADJ_AMOUNT NUMERIC(14,2))


	IF @CCUSTOMERCODE NOT IN ('','000000000000')
	BEGIN
		INSERT INTO @cCustDetails(CUSTOMER_CODE,USER_CUSTOMER_CODE,MOBILE)
		SELECT CUSTOMER_CODE,USER_CUSTOMER_CODE,MOBILE
		FROM CUSTDYM (NOLOCK)
		WHERE CUSTOMER_CODE=@CCUSTOMERCODE 

		INSERT INTO @cCustDetails(CUSTOMER_CODE,USER_CUSTOMER_CODE,MOBILE)
		SELECT A.CUSTOMER_CODE,A.USER_CUSTOMER_CODE,A.MOBILE
		FROM CUSTDYM A (NOLOCK)
		LEFT OUTER JOIN @cCustDetails B ON B.CUSTOMER_CODE=A.customer_code
		WHERE B.CUSTOMER_CODE IS NULL 
		AND ISNULL(A.USER_CUSTOMER_CODE,'')=@CCUSTOMERCODE 

		INSERT INTO @cCustDetails(CUSTOMER_CODE,USER_CUSTOMER_CODE,MOBILE)
		SELECT A.CUSTOMER_CODE,A.USER_CUSTOMER_CODE,A.MOBILE
		FROM CUSTDYM A (NOLOCK)
		left join @cCustDetails c on a.customer_code =c.CUSTOMER_CODE 
		WHERE ISNULL(A.MOBILE,'') =@CCUSTOMERCODE  AND C.CUSTOMER_CODE IS NULL

		--INSERT INTO @cCustDetails(CUSTOMER_CODE,USER_CUSTOMER_CODE,MOBILE)
		--SELECT A.CUSTOMER_CODE,A.USER_CUSTOMER_CODE,A.MOBILE
		--FROM CUSTDYM A (NOLOCK)
		--JOIN @cCustDetails B ON B.USER_CUSTOMER_CODE=A.user_customer_code
		--WHERE B.CUSTOMER_CODE<>A.customer_code
		--AND ISNULL(B.USER_CUSTOMER_CODE,'') <>''

		--INSERT INTO @cCustDetails(CUSTOMER_CODE,USER_CUSTOMER_CODE,MOBILE)
		--SELECT A.CUSTOMER_CODE,A.USER_CUSTOMER_CODE,A.MOBILE
		--FROM CUSTDYM A (NOLOCK)
		--JOIN @cCustDetails B ON B.MOBILE=A.mobile
		--left join @cCustDetails c on a.customer_code =c.CUSTOMER_CODE 
		--WHERE B.CUSTOMER_CODE<>A.customer_code
		--AND ISNULL(B.MOBILE,'') <>'' AND C.CUSTOMER_CODE IS NULL
		--group by A.CUSTOMER_CODE,A.USER_CUSTOMER_CODE,A.MOBILE
	END	
	ELSE
	BEGIN
		--- No need to process the data if Customer Code is blank
		GOTO END_PROC
	END
	--select * from @cCustDetails
	IF ISNULL(@CIGNOREMEMOID,'')<>''
	BEGIN
		SET @cCmd=N'SELECT cm_id FROM cmm01106 (NOLOCK) WHERE cm_id in ('+@CIGNOREMEMOID+')
					UNION 
					SELECT adv_rec_id FROM arc01106 (NOLOCK) WHERE ADV_REC_id in ('+@CIGNOREMEMOID+')
					'
		PRINT @cCmd	
		INSERT #tmpIgnore
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cCutoffDate=ISNULL(@cCutoffDate,'')


	

	INSERT INTO #CREDITNOTES(ADJ_MEMO_ID ,ADJ_AMOUNT)
	SELECT P.ADJ_MEMO_ID,SUM(P.AMOUNT) AS ADJ_AMOUNT       
	FROM PAYMODE_XN_DET P (NOLOCK)     
	JOIN CMM01106 Q (NOLOCK) ON P.MEMO_ID = Q.CM_ID  
	JOIN @cCustDetails CD ON    CD.CUSTOMER_CODE=Q.customer_code 
	WHERE P.PAYMODE_CODE = '0000001'      
	AND   Q.CANCELLED = 0      
	AND   Q.CM_ID <> @CCURCMID   --AND  Q.CUSTOMER_CODE =@CCUSTOMERCODE
	GROUP BY P.ADJ_MEMO_ID

	INSERT INTO #CREDITNOTES(ADJ_MEMO_ID ,ADJ_AMOUNT)
	SELECT P.ADJ_MEMO_ID,SUM(P.AMOUNT) AS ADJ_AMOUNT              
	FROM PAYMODE_XN_DET P (NOLOCK)     
	JOIN ARC01106 Q (NOLOCK) ON P.MEMO_ID = Q.ADV_REC_ID  
	JOIN @cCustDetails CD ON    CD.CUSTOMER_CODE=Q.customer_code     
	WHERE P.PAYMODE_CODE = '0000001'      
	AND   Q.CANCELLED = 0      
	AND   Q.ADV_REC_ID <> @CCURCMID  --AND   Q.CUSTOMER_CODE =@CCUSTOMERCODE
	GROUP BY P.ADJ_MEMO_ID
	
	INSERT INTO #CREDITNOTES_SUM(ADJ_MEMO_ID ,ADJ_AMOUNT)
	SELECT ADJ_MEMO_ID,SUM(ADJ_AMOUNT) AS ADJ_AMOUNT
	FROM  #CREDITNOTES
	GROUP BY ADJ_MEMO_ID

	

	INSERT INTO #ADVANCES(ADJ_MEMO_ID ,ADJ_AMOUNT)
	SELECT P.ADJ_MEMO_ID,SUM(P.AMOUNT) AS ADJ_AMOUNT       
	FROM PAYMODE_XN_DET P (NOLOCK)     
	JOIN CMM01106 Q (NOLOCK) ON P.MEMO_ID = Q.CM_ID 
	JOIN @cCustDetails CD ON     CD.CUSTOMER_CODE=Q.customer_code      
	WHERE P.PAYMODE_CODE = '0000002'      
	AND   Q.CANCELLED = 0      
	AND   Q.CM_ID <> @CCURCMID  AND XN_TYPE='SLS' 
	AND (@CPARTYACCODE IN ('','0000000000') OR Q.AC_CODE=@CPARTYACCODE) 
	--AND( @CCUSTOMERCODE='' OR Q.CUSTOMER_CODE=   @CCUSTOMERCODE)  
	GROUP BY P.ADJ_MEMO_ID
	INSERT INTO #ADVANCES(ADJ_MEMO_ID ,ADJ_AMOUNT)
	SELECT P.ADJ_MEMO_ID,SUM(P.AMOUNT) AS ADJ_AMOUNT       
	FROM PAYMODE_XN_DET P   (NOLOCK)   
	JOIN ARC01106 Q (NOLOCK) ON P.MEMO_ID = Q.ADV_REC_ID 
	JOIN @cCustDetails CD ON     CD.CUSTOMER_CODE=Q.customer_code           
	WHERE P.PAYMODE_CODE = '0000002'      
	AND   Q.CANCELLED = 0      
	AND   Q.ADV_REC_ID <> @CCURCMID 
	AND (@CPARTYACCODE IN ('','0000000000') OR Q.AC_CODE=@CPARTYACCODE)
	--AND(   @CCUSTOMERCODE='' OR Q.CUSTOMER_CODE=   @CCUSTOMERCODE)   
	GROUP BY P.ADJ_MEMO_ID
	INSERT INTO #ADVANCES(ADJ_MEMO_ID ,ADJ_AMOUNT)
	SELECT P.ADJ_MEMO_ID,SUM(P.AMOUNT) AS ADJ_AMOUNT       
	FROM PAYMODE_XN_DET P   (NOLOCK)   
	JOIN INM01106 Q (NOLOCK) ON P.MEMO_ID = Q.INV_ID      
	WHERE P.PAYMODE_CODE = '0000002'  AND XN_TYPE='WSL' AND Q.AC_CODE=   @CPARTYACCODE  
	AND   Q.CANCELLED = 0      
	AND   Q.INV_ID <> @CCURCMID GROUP BY P.ADJ_MEMO_ID 

	INSERT INTO #ADVANCES_SUM(ADJ_MEMO_ID ,ADJ_AMOUNT)
	SELECT ADJ_MEMO_ID,SUM(ADJ_AMOUNT) AS ADJ_AMOUNT
	FROM #ADVANCES
	GROUP BY  ADJ_MEMO_ID
	
	
	INSERT INTO #DetailTable([TYPE] , MEMO_NO ,MEMO_ID , NET_AMOUNT ,[MEMO_DT] , REF_NO,ADJ_LOCATION_CODE )
    SELECT   '0000001' AS TYPE, B.CM_NO AS MEMO_NO, B.CM_ID AS MEMO_ID, 
		ABS(A.AMOUNT)-ABS(ISNULL(X.ADJ_AMOUNT,0)) AS NET_AMOUNT ,B.CM_DT AS [MEMO_DT] , B.REF_NO,ISNULL(B.location_Code,LEFT(B.CM_ID,2)) AS ADJ_LOCATION_CODE
	 FROM PAYMODE_XN_DET A  (NOLOCK)     
	 JOIN CMM01106 B (NOLOCK) ON A.MEMO_ID = B.CM_ID
	 JOIN @cCustDetails CD ON    CD.CUSTOMER_CODE=b.customer_code       
	 LEFT OUTER JOIN #CREDITNOTES_SUM X ON B.CM_ID = X.ADJ_MEMO_ID      
	 LEFT OUTER JOIN #tmpIgnore i on i.memo_id=b.cm_id
	 WHERE b.CM_DT>=@cCutoffDate --AND ( B.CUSTOMER_CODE =@CCUSTOMERCODE) 
	 AND SUBSTRING(B.CM_NO,LEN(B.LOCATION_CODE)+3,1)='N' 
	 AND A.PAYMODE_CODE = '0000004'      
	 AND B.CANCELLED = 0  
	 AND A.AMOUNT < 0      
	 AND ABS(A.AMOUNT)-ABS(ISNULL(X.ADJ_AMOUNT,0))>0
	 AND X.ADJ_MEMO_ID IS NULL
	 AND '0000001'=@CTYPE  
	 AND i.Memo_ID is null
	 AND (LTRIM(RTRIM(B.CM_NO)) LIKE @CMEMONO OR LTRIM(RTRIM(ISNULL( B.REF_NO,''))) LIKE @CMEMONO) 

	 INSERT INTO #DetailTable([TYPE] , MEMO_NO ,MEMO_ID , NET_AMOUNT ,[MEMO_DT] , REF_NO,ADJ_LOCATION_CODE )
	 SELECT  '0000002' AS TYPE, ADV_REC_NO AS MEMO_NO, ADV_REC_ID AS MEMO_ID, 
	-- ABS(NET_AMOUNT) AS AMOUNT,
	  ABS(A.AMOUNT)-ABS(ISNULL(X.ADJ_AMOUNT,0)) AS AMOUNT,
	 A.ADV_REC_DT AS [MEMO_DT] ,a.ref_no  AS REF_NO    ,ISNULL(A.location_Code,LEFT(A.ADV_REC_ID,2)) AS ADJ_LOCATION_CODE
	 FROM ARC01106 A (NOLOCK)  
	 JOIN @cCustDetails CD ON     CD.CUSTOMER_CODE=a.customer_code    
	 LEFT OUTER JOIN #ADVANCES_SUM X ON A.ADV_REC_ID = X.ADJ_MEMO_ID      
	 LEFT OUTER JOIN #tmpIgnore i on i.memo_id=a.adv_rec_id
	 WHERE   a.adv_rec_dt>=@cCutoffDate --AND 
	 AND (A.ARC_TYPE = 1 AND A.ARCT = 2)  
	 AND   A.CANCELLED = 0      
	 AND ABS(A.AMOUNT)-ABS(ISNULL(X.ADJ_AMOUNT,0))>0
	 AND '0000002'=@CTYPE
	 AND i.memo_id is null
	 AND  A.ADV_REC_NO LIKE @CMEMONO

END_PROC:
	 SELECT * FROM #DetailTable
END
