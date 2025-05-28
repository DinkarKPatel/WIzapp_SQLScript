CREATE PROCEDURE SP_EOSSOR_FILTER
(

 @FM_ORDER_DT VARCHAR(20)='', --ORDER_FMDT
 @TO_ORDER_DT VARCHAR(20)='',--ORDER_TODT
 @AC_CODE CHAR(10)='',--AC_CODE
 @CANCELLED NUMERIC(1)=2,--0 UN-CANCELLED 1 CANCELLED 2 ALL 
 @APPROVED INT=0,
 @TERMID VARCHAR(100)='',
 @LOC VARCHAR(4)='',
 @nPostingStatus numeric(1,0)=2              

)
AS
BEGIN
--(dinkar) Replace  left(memoid,2) to Location_code 

	DECLARE @CCMD NVARCHAR(MAX),@FILTER VARCHAR(2000),@CFILTER1 VARCHAR(2000)
   
	SET @FILTER=' memo_dt between '''+CONVERT(varchar,@FM_ORDER_DT,110)+''' AND '''+CONVERT(varchar,@TO_ORDER_DT,110)+''''                  

	IF @AC_CODE<>''
		SET @FILTER=@FILTER+' AND a.ac_code='''+@AC_CODE+''''                      	
         
	IF @CANCELLED<>2
		SET @FILTER=@FILTER+' AND a.cancelled='+str(@CANCELLED)

	IF @loc<>''
		SET @FILTER=@FILTER+' AND a.party_dept_id='''+@loc+''''

	IF @APPROVED<>2
		SET @FILTER=@FILTER+(CASE WHEN @APPROVED=0 THEN ' AND isnull(a.approvedlevelno,0)<>99' ELSE ' AND isnull(a.approvedlevelno,0)=99' END)

	IF @TERMID<>''
		SET @FILTER=@FILTER+' AND a.id='''+@TERMID+''''

	IF @nPostingStatus<>2
		SET @FILTER=@FILTER+' AND a.cancelled=0 AND '+(CASE WHEN @nPostingStatus=0 THEN ' post.vm_id is null ' else 'post.vm_id is not null' END) 
					                           
	SET @CCMD=N'	SELECT A.memo_id,B.Ac_name,memo_no, CONVERT(VARCHAR,memo_dt,106) as memo_dt,
	CONVERT(VARCHAR,A.PERIOD_FROM,106) AS PERIOD_FROM  ,	CONVERT(VARCHAR,A.PERIOD_TO,106)  AS PERIOD_TO ,
	ISNULL(TE.NAME,'''') AS T_NAME,
	TE.D_FILTER,
	A.remarks,(CASE WHEN A.cancelled=1 then ''YES'' ELSE ''No'' END) as cancelled,
	(CASE WHEN post.vm_id is not null then ''YES'' ELSE ''No'' END) as posted,C.USERNAME,
	ISNULL(LCT.DEPT_NAME,'''') AS DEPT_NAME,
	ISNULL(RMM.RM_NO,CNM.CN_NO) AS REF_NO,	
	(CASE WHEN isnull(rmm.rm_id,'''')<>'''' THEN ''PRT'' ELSE ''WSR'' END) AS xn_type	,
	cast(0 as bit) As CREATE_FD,cast(0 as bit) as SEND_MAIL,
	(CASE WHEN ISNULL(a.approvedlevelno,0)=99 then ''Approved'' ELSE STR(ISNULL(a.approvedlevelno,0)) END) AS approvedlevelno,
	a.payment_mode,isnull(rmm.total_amount,cnm.total_amount) as fdn_fcn_amount,
	a.memo_no+convert(varchar,memo_dt,112) AS ref_no_bank,BF_AC_NAME,ACCOUNT_NO,IFSC_CODE,vendor_amount,
	payment_date,bank_payment_excel_file,
	A.payment_advice_amount,A.advance_adjusted,
	CONVERT(NUMERIC(10,2),ROUND(x.RATEDIFF,2)) AS RATEDIFF
	FROM EOSSSORM A	(nolock)
	JOIN 
	(
	    SELECT MEMO_ID,	SUM(rate_diff) AS ratediff
		FROM EOSSSORD (nolock) GROUP BY MEMO_ID
	)X ON X.MEMO_ID=A.MEMO_ID
	JOIN LM01106 B ON B.AC_CODE=A.AC_CODE
	JOIN LMP01106 B1 ON B.AC_CODE=B1.AC_CODE
	JOIN USERS C ON C.USER_CODE=B.USER_CODE
	LEFT JOIN LOCATION LCT(NOLOCK) ON A.party_DEPT_ID=LCT.DEPT_ID
	 LEFT JOIN SOR_FDNFCN_LINK sl (NOLOCK) ON sl.sorMemoId=a.MEMO_ID
	 LEFT OUTER JOIN RMM01106 RMM ON  sl.refFdnMemoId=rmm.rm_id  AND rmm.cancelled=0  
	 LEFT OUTER JOIN CNM01106 CNM ON  sl.refFcnMemoId=cnm.cn_id   AND cnm.cancelled=0  

	LEFT OUTER JOIN TBL_EOSS_DISC_SHARE_MST TE ON TE.ID=A.ID
	LEFT OUTER JOIN 
	(SELECT a.vm_id,a.memo_id as posted_memo_id FROM postact_voucher_link a (NOLOCK)
	 JOIN  vm01106 b (NOLOCK) ON  a.vm_id=b.vm_id
	 WHERE xn_type=''EOSSSOR'' AND cancelled=0
    ) post ON post.posted_memo_id=a.memo_id
	LEFT OUTER JOIN lm_bank_detail d (NOLOCK) ON d.ac_code=ISNULL(a.ac_code,lct.dept_ac_code)
	WHERE '+@Filter
		
	PRINT @CCMD					
	EXEC SP_EXECUTESQL @CCMD
		                     
                          
END