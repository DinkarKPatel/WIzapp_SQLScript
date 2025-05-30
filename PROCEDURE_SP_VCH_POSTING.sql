CREATE PROCEDURE SP_VCH_POSTING
@NQUERYID	NUMERIC(3,0),
@CMEMOID	VARCHAR(22),
@CWHERE		VARCHAR(200),
@CFINYEAR	VARCHAR(10),
@CDEPTID	VARCHAR(5),
@DFROM		DATETIME = '',
@DTO		DATETIME = ''
--WITH ENCRYPTION

AS
BEGIN
DECLARE @CCMD NVARCHAR(4000)
IF @NQUERYID = 1
GOTO LBLSUPPLIERP
ELSE 
IF @NQUERYID = 2
GOTO LBLCUSTOMERP
ELSE 
IF @NQUERYID = 3
GOTO LBLACCOUNTSP
ELSE 
IF @NQUERYID = 4
GOTO LBLACCOUNTSCONTRAP
ELSE 
IF @NQUERYID = 5
GOTO LBLACCOUNTSJOURNALP
ELSE 
IF @NQUERYID = 6
GOTO LBLNARRATIONP
ELSE 
IF @NQUERYID = 7
GOTO LBLVM01106S
ELSE 
IF @NQUERYID = 8
GOTO LBLVD01106P
ELSE 
IF @NQUERYID = 9
GOTO LBLLOCATION1P
ELSE 
IF @NQUERYID = 10
GOTO LBLVDD
ELSE 
IF @NQUERYID = 11
GOTO LBLVDNP
ELSE 
IF @NQUERYID = 12
GOTO LBLVDAP
ELSE 
IF @NQUERYID = 13
GOTO LBLVMMRR
ELSE
IF @NQUERYID = 14
GOTO LBLPOSTING


DECLARE @CHEADCODE VARCHAR(4000) ,@CHEADCODE1 VARCHAR(4000)


LBLSUPPLIERP:--1
        SET @CHEADCODE=DBO.FN_ACT_TRAVTREE('0000000021') 
        SELECT AC_CODE, AC_NAME FROM LMV01106 
        WHERE CHARINDEX(HEAD_CODE,@CHEADCODE)>0 
        OR ALLOW_CREDITOR_DEBTOR = 1 AND AC_NAME<>'' AND ISNULL(INACTIVE,0)=0 
        ORDER BY AC_NAME
GOTO LAST

LBLCUSTOMERP:--2
        SET @CHEADCODE=DBO.FN_ACT_TRAVTREE('0000000018') 
		SELECT AC_CODE, AC_NAME FROM LMV01106 
        WHERE CHARINDEX(HEAD_CODE,@CHEADCODE)>0 
        OR ALLOW_CREDITOR_DEBTOR = 1 AND AC_NAME<>''  AND ISNULL(INACTIVE,0)=0 
        ORDER BY AC_NAME
GOTO LAST

LBLACCOUNTSP:--3
        SELECT AC_CODE,AC_NAME,BILL_BY_BILL,ISNULL(CREDIT_DAYS,0) AS CR_DAYS,
        ISNULL(DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE 
        FROM LMV01106 WHERE AC_NAME<>'' AND  ISNULL(INACTIVE,0)=0  ORDER BY AC_NAME
GOTO LAST

LBLACCOUNTSCONTRAP:--4
		SET @CHEADCODE=DBO.FN_ACT_TRAVTREE('0000000013') 
		SET @CHEADCODE1=DBO.FN_ACT_TRAVTREE('0000000014') 
		SELECT AC_CODE, AC_NAME,BILL_BY_BILL FROM LMV01106 
		WHERE (CHARINDEX(HEAD_CODE,@CHEADCODE)>0 
		OR CHARINDEX( HEAD_CODE, @CHEADCODE1)>0 )  AND  ISNULL(INACTIVE,0)=0  
		ORDER BY AC_NAME
GOTO LAST

LBLACCOUNTSJOURNALP:--5
        SET @CHEADCODE=DBO.FN_ACT_TRAVTREE('0000000013') 
        SET @CHEADCODE1=DBO.FN_ACT_TRAVTREE('0000000014') 
        SELECT AC_CODE, AC_NAME,BILL_BY_BILL FROM LMV01106 
        WHERE NOT (CHARINDEX(HEAD_CODE,@CHEADCODE)>0 
        OR CHARINDEX( HEAD_CODE, @CHEADCODE1)>0 )  AND  ISNULL(INACTIVE,0)=0  
        ORDER BY AC_NAME
GOTO LAST

LBLNARRATIONP:--6
     SELECT NRM_ID, NARRATION FROM NRM WHERE NRM_ID <> '0000000' ORDER BY NARRATION
GOTO LAST

LBLVM01106S:--7
     SET @CCMD = N'SELECT A.*,A.DEPT_ID + '' '' + B.DEPT_NAME AS DEPT_NAME,C.VOUCHER_TYPE 
     FROM VM01106 A 
     JOIN LOCATION B ON A.DEPT_ID = B.DEPT_ID
     JOIN VCHTYPE C ON A.VOUCHER_CODE=C.VOUCHER_CODE 
     WHERE A.FIN_YEAR='''+@CFINYEAR+''' '+ CASE WHEN @CWHERE <> '' THEN ' AND VM_ID='''+ @CWHERE +'''' ELSE ' AND 1=2' END  +' '
     PRINT @CCMD	
	 EXEC SP_EXECUTESQL @CCMD
GOTO LAST

LBLVD01106P:--8
	SET @CCMD = N'SELECT A.VD_ID,A.VM_ID,D.VOUCHER_DT,A.AC_CODE,A.NARRATION, 
    CASE WHEN CONVERT(VARCHAR(14),A.CREDIT_AMOUNT)  = ''0.00'' THEN '''' ELSE CONVERT(VARCHAR(14),A.CREDIT_AMOUNT) END AS CREDIT_AMOUNT, 
    CASE WHEN CONVERT(VARCHAR(14),A.DEBIT_AMOUNT) =''0.00'' THEN '''' ELSE CONVERT(VARCHAR(14),A.DEBIT_AMOUNT) END AS DEBIT_AMOUNT, 
    A.X_TYPE,A.VS_AC_CODE,A.CHK_RECON,A.RECON_DT,A.LAST_UPDATE, A.COMPANY_CODE,D.FIN_YEAR,A.AUTOENTRY,B.AC_NAME,B.BILL_BY_BILL,VAT_ENTRY 
    ,A.COST_CENTER_AC_CODE
    FROM VD01106 A 
    JOIN LMV01106 B ON A.AC_CODE = B.AC_CODE 
    JOIN VM01106 D ON A.VM_ID = D.VM_ID 
    WHERE D.FIN_YEAR='''+@CFINYEAR+'''  '+ CASE WHEN @CWHERE <> '' THEN ' AND A.VM_ID='''+ @CWHERE +'''' ELSE ' AND 1=2' END  +' '
    PRINT @CCMD	
	EXEC SP_EXECUTESQL @CCMD
GOTO LAST

LBLLOCATION1P:--9
    SELECT DEPT_ID,DEPT_ID  + ' ' +  DEPT_NAME AS  DEPT_NAME,PUR_LOC 
    FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID --AND ACCOUNTS_POSTING_DEPT_ID=@CWHERE 
    
GOTO LAST

LBLVDD:--10
	SET @CCMD = N'SELECT  A.VD_ID, A.VDN_ID,  B.AC_CODE, (CASE WHEN A.ON_ACCOUNT=0 THEN ''NEW'' ELSE ''ONACCOUNT'' END) AS REF_TYPE, 
	A.REF_NO AS BILL_NO, A.INV_AMT AS BILL_AMOUNT,
    0 AS AMOUNT_ADJUSTABLE, ''DR'' AS BILL_TYPE, A.NX_TYPE AS NBILL_TYPE, 0 AS ADJ_BILL_AMOUNT, 
    A.CR_DAYS,(A.REF_DATE+A.CR_DAYS) AS DUE_DATE, SPACE(20) AS VDDID, 0 AS FREEZEEDITING, 
    A.REF_DATE, A.VDN_ID AS ROW_ID, A.DISCOUNT_PERCENTAGE, 
    C.AC_CODE,C.AC_NAME,ISNULL(A.INV_AMT*(A.DISCOUNT_PERCENTAGE/100),0.00) AS DISC_AMT,A.INV_AMT  AS FEEDED_AMOUNT,
    (A.INV_AMT-ISNULL(A.INV_AMT*(A.DISCOUNT_PERCENTAGE/100),0.00)) AS NET_AMOUNT ,A.ON_ACCOUNT ,'''' AS VDN_TEMP
    FROM VDN01106 A 
    JOIN VD01106 B ON A.VD_ID = B.VD_ID 
    JOIN LMV01106 C ON C.AC_CODE=B.AC_CODE
    WHERE '+ CASE WHEN @CWHERE <> '' THEN ' B.VM_ID='''+ @CWHERE +'''' ELSE ' 1=2' END  +' 
	UNION ALL 
    SELECT  A.VD_ID, C.VDN_ID,  B.AC_CODE, ''ADJUST'' AS REF_TYPE, C.REF_NO AS BILL_NO, C.INV_AMT AS BILL_AMOUNT,
    0 AS AMOUNT_ADJUSTABLE, ''DR'' AS BILL_TYPE, A.X_TYPE AS NBILL_TYPE, A.AMOUNT AS ADJ_BILL_AMOUNT,
    C.CR_DAYS,(C.REF_DATE+C.CR_DAYS) AS DUE_DATE, SPACE(20) AS VDDID, 0 AS FREEZEEDITING,
    C.REF_DATE, A.ROW_ID, A.DISCOUNT_PERCENTAGE, 
    D.AC_CODE,D.AC_NAME,A.DISCOUNT_AMOUNT AS DISC_AMT,A.AMOUNT  AS FEEDED_AMOUNT,
    ISNULL(A.AMOUNT-A.DISCOUNT_AMOUNT,0) AS NET_AMOUNT,0 AS ON_ACCOUNT,'''' AS VDN_TEMP  
    FROM VDA01106 A 
    JOIN VD01106 B ON A.VD_ID = B.VD_ID 
    JOIN VDN01106 C ON A.VDN_ID = C.VDN_ID 
    JOIN LMV01106 D ON D.AC_CODE=B.AC_CODE 
    WHERE '+ CASE WHEN @CWHERE <> '' THEN ' B.VM_ID='''+ @CWHERE +'''' ELSE ' 1=2' END  +' '
	PRINT @CCMD	
	EXEC SP_EXECUTESQL @CCMD
GOTO LAST

LBLVDNP:--11
    SET @CCMD = N'SELECT  A.*,B.AC_CODE FROM VDN01106 A JOIN VD01106 B ON B.VD_ID=A.VD_ID 
    WHERE '+ CASE WHEN @CWHERE <> '' THEN ' A.VD_ID='''+ @CWHERE +'''' ELSE ' 1=2' END  +' '
    PRINT @CCMD	
	EXEC SP_EXECUTESQL @CCMD
GOTO LAST

LBLVDAP:--12
	SET @CCMD = N'SELECT  A.*,B.AC_CODE FROM VDA01106 A JOIN VD01106 B ON B.VD_ID=A.VD_ID 
	WHERE '+ CASE WHEN @CWHERE <> '' THEN ' A.VD_ID='''+ @CWHERE +'''' ELSE ' 1=2' END  +''
	PRINT @CCMD	
	EXEC SP_EXECUTESQL @CCMD
GOTO LAST

LBLVMMRR:--13
	SELECT VM_ID,MRR_ID FROM VM_MRR WHERE 1=2
GOTO LAST

LBLPOSTING:
	SELECT CONVERT(BIT,0) AS  CHK
		,CONVERT(NVARCHAR(500),'') AS  PARTY_NAME
		,CONVERT(NUMERIC(14,2),'0.00') AS NET_AMOUNT
		,CONVERT(NVARCHAR(50),'') AS BILL_STATUS
		,CONVERT(NVARCHAR(50),'') AS VOUCHER_TYPE
		,CONVERT(NVARCHAR(500),'') AS DEPT_NAME, *,CAST(0 AS BIT) AS ERROR_FLAG ,CAST('' AS VARCHAR(MAX)) AS ERROR_DESC,CAST('' AS VARCHAR(10)) AS DEBUG_STR
		,CAST(0 AS BIT) OPTIMIZED,CAST('' AS VARCHAR(100)) AS SP_ID
	FROM VM01106 WHERE 1=2
	
	SELECT VM_ID,VD_ID,AC_CODE,NARRATION,DEBIT_AMOUNT,CREDIT_AMOUNT,X_TYPE,VS_AC_CODE,VAT_ENTRY
		,CONVERT(NVARCHAR(50),'') AS REF_BILL_NO
		,CONVERT(NVARCHAR(500),'') AS AC_NAME
		,CONVERT(NUMERIC(14,2),'0.00') AS CREDIT_DAYS
		,CONVERT(NUMERIC(14,2),'0.00') AS CR_DISCOUNT_PERCENTAGE,COST_CENTER_DEPT_ID  
	FROM VD01106 WHERE 1=2
	
	SELECT BILL_TYPE AS XN_TYPE,BILL_NO AS XN_NO,BILL_DT AS XN_DT,DRTOTAL AS XN_AMOUNT
	,CONVERT(NVARCHAR(50),'') AS XN_AC,CONVERT(NVARCHAR(500),'') AS ERR_DESC 
	FROM VM01106 WHERE 1=2
	
GOTO LAST


	
LAST:
END
