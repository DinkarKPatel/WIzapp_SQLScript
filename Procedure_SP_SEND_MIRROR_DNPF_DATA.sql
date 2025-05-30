CREATE PROCEDURE SP_SEND_MIRROR_DNPF_DATA
(	
	 @CUPLOADEDXNID VARCHAR(50)
	,@CCURLOCID VARCHAR(5)	
	,@BACKNOWLEDGE BIT=0
	,@CERRMSG VARCHAR(1000) OUTPUT
)	
--WITH ENCRYPTION
AS
/*
	SP_SEND_MIRROR_DNPF_DATA : THIS PROCEDURE WILL SEND Debit note Proforma from ho to Location.
*/
BEGIN
	DECLARE @DTSQL NVARCHAR(MAX),@NSPID INT,@CTEMPTABLE VARCHAR(500),@CMEMOID VARCHAR(50),
	@CTEMPEMPLOYEETABLE VARCHAR(200),@DMEMOLASTUPDATE DATETIME,@CTABLENAME VARCHAR(100),
	@BRECFOUND BIT,@CSTEP VARCHAR(5),@CFILTERCONDITION VARCHAR(MAX),
	@CTEMPMASTERTABLE VARCHAR(200),@CTEMPDETAILTABLE VARCHAR(200),@CTEMPLMTABLE VARCHAR(200),
	@CTEMPLMPTABLE VARCHAR(200),@CTEMPAREATABLE VARCHAR(200),@CTEMPCITYTABLE VARCHAR(200),
	@CTEMPSKUTABLE VARCHAR(200),@CTEMPARTTABLE VARCHAR(200),@CTEMPSDTABLE VARCHAR(200),
	@CTEMPARTATTRTABLE VARCHAR(200),@CTEMPUOMTABLE VARCHAR(200)
	

	DECLARE @TXNSSENDINFO TABLE (ORG_TABLENAME VARCHAR(50),TMP_TABLENAME VARCHAR(50),XN_ID VARCHAR(40))  	
BEGIN TRY 	
	---- CALL ACKNOWLEDGEMENT OF MEMO SUCCESSFUL MERGING AT MIRRORING SERVER
	DECLARE @CTEMPDBNAME VARCHAR(40)
	SET @CTEMPDBNAME=''

	 SET @CMEMOID=@CUPLOADEDXNID
	
	SET @CSTEP=40
	---- IF NO MEMO FOUND , JUST END THE PROCESS
	IF ISNULL(@CMEMOID,'')=''
		GOTO END_PROC
LBLTABLEINFO:
	SET @CSTEP=50
	---- POPULATE LIST OF TABLES 

	---- SEND THE DNPF MEMO MASTER TABLE
	SELECT DISTINCT 'DNPF_DEBITNOTE_PROFORMA_MST_UPLOAD' AS TARGET_TABLENAME,A.* ,@CMEMOID AS XN_ID FROM DebitNote_Proforma_MST(NOLOCK) A 
    WHERE A.Memo_Id=@CMEMOID  
	
	SET @CSTEP=230
	---- SEND THE DNPF MEMO DETAIL TABLE
	 SELECT DISTINCT 'DNPF_DEBITNOTE_PROFORMA_DET_UPLOAD' AS TARGET_TABLENAME,A.* FROM DebitNote_Proforma_DET (NOLOCK) A WHERE A.Memo_Id=@CMEMOID  
   
	
	SET @CSTEP=240
	---- SEND THE DEBITNOTE MEMO SKU TABLE
	 SELECT DISTINCT 'DNPF_SKU_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS DNPF_MEMO_ID FROM SKU A  (NOLOCK)
	 JOIN DebitNote_Proforma_DET DNPFDET (NOLOCK) ON A.PRODUCT_CODE=DNPFDET.PRODUCT_CODE 
	 WHERE DNPFDET.memo_id=@CMEMOID  
   
	
	
	SET @CSTEP=340
	---- SEND THE ARTICLE RELATED TO GIVEN DNPF MEMO

	IF OBJECT_ID ('TEMPDB..#TMPARTICLE','U') IS NOT NULL
	   DROP TABLE #TMPARTICLE

	SELECT B.ARTICLE_CODE into #TMPARTICLE  FROM DebitNote_Proforma_DET A (NOLOCK)
	JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE
	WHERE A.memo_id=@CMEMOID
	group by B.ARTICLE_CODE

	SELECT DISTINCT 'DNPF_ARTICLE_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS DNPF_MEMO_ID FROM ARTICLE A  (NOLOCK)
	JOIN #TMPARTICLE B ON A.ARTICLE_CODE =B.ARTICLE_CODE 
	

	SELECT DISTINCT 'DNPF_UOM_UPLOAD' AS TARGET_TABLENAME,UOM.*,@CMEMOID AS DNPF_MEMO_ID FROM #TMPARTICLE A
	JOIN ARTICLE B (NOLOCK) ON A.article_code =B.ARTICLE_CODE 
	JOIN UOM  (NOLOCK) ON UOM.UOM_CODE =B.UOM_CODE 
	
	
	SET @CSTEP=350
	---- SEND THE SECTIOND RELATED TO GIVEN DNPF MEMO
	SELECT DISTINCT 'DNPF_SECTIOND_UPLOAD' AS TARGET_TABLENAME,SECTIOND.*,@CMEMOID AS DNPF_MEMO_ID FROM #TMPARTICLE A
	JOIN ARTICLE B (NOLOCK) ON A.article_code =B.ARTICLE_CODE 
	JOIN SECTIOND  (NOLOCK) ON SECTIOND.sub_section_code =B.sub_section_code 
	
	
	SET @CSTEP=360
	---- SEND THE SECTIONM RELATED TO GIVEN DNPF MEMO
	SELECT DISTINCT 'DNPF_SECTIONM_UPLOAD' AS TARGET_TABLENAME,SECTIONM.*,@CMEMOID AS DNPF_MEMO_ID FROM #TMPARTICLE A
	JOIN ARTICLE B (NOLOCK) ON A.article_code =B.ARTICLE_CODE 
	JOIN SECTIOND  (NOLOCK) ON SECTIOND.sub_section_code =B.sub_section_code 
	JOIN SECTIONM  (NOLOCK) ON sectionM.section_code =SECTIOND.section_code 
	
		IF OBJECT_ID ('TEMPDB..#TMPPARA','U') IS NOT NULL
	       DROP TABLE #TMPPARA


		   SELECT B.PARA1_CODE ,B.PARA2_CODE,B.PARA3_CODE,B.PARA4_CODE ,B.PARA5_CODE,B.PARA6_CODE 
		   into #TMPPARA
		   FROM DebitNote_Proforma_DET A (NOLOCK)
	       JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE
	       WHERE A.Memo_id=@CMEMOID

	SET @CSTEP=370
	---- SEND THE PARA1 RELATED TO GIVEN DNPF MEMO

    SELECT DISTINCT 'DNPF_PARA1_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS DNPF_MEMO_ID FROM PARA1 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA1_CODE  =B.PARA1_CODE 

	SET @CSTEP=380
	---- SEND THE PARA2 RELATED TO GIVEN DNPF MEMO

	SELECT DISTINCT 'DNPF_PARA2_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS DNPF_MEMO_ID FROM PARA2 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA2_CODE  =B.PARA2_CODE 

	SET @CSTEP=390
	---- SEND THE PARA3 RELATED TO GIVEN DNPF MEMO
	SELECT DISTINCT 'DNPF_PARA3_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS DNPF_MEMO_ID FROM PARA3 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA3_CODE  =B.PARA3_CODE 

	SET @CSTEP=400
	---- SEND THE PARA4 RELATED TO GIVEN DNPF MEMO
	SELECT DISTINCT 'DNPF_PARA4_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS DNPF_MEMO_ID FROM PARA4 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA4_CODE  =B.PARA4_CODE 

	SET @CSTEP=410
	---- SEND THE PARA5 RELATED TO GIVEN DNPF MEMO
	SELECT DISTINCT 'DNPF_PARA5_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS DNPF_MEMO_ID FROM PARA5 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA5_CODE  =B.PARA5_CODE 

	SET @CSTEP=420
	---- SEND THE PARA6 RELATED TO GIVEN DNPF MEMO
	SELECT DISTINCT 'DNPF_PARA6_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS DNPF_MEMO_ID FROM PARA6 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA6_CODE  =B.PARA6_CODE 

	
	SET @CSTEP=430
	---- SEND THE ART_ATTR RELATED TO GIVEN DNPF MEMO
	
	
	SELECT  DISTINCT 'DNPF_ARTICLE_FIX_ATTR_MIRROR' AS TARGET_TABLENAME,@CMEMOID AS DNPF_MEMO_ID,A.* FROM ARTICLE_FIX_ATTR A (NOLOCK)  
	 JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE  
	 JOIN SKU C (NOLOCK) ON C.ARTICLE_CODE=B.ARTICLE_CODE  
	 JOIN DebitNote_Proforma_DET D (NOLOCK) ON D.PRODUCT_CODE=C.PRODUCT_CODE  
	 WHERE memo_id=@CMEMOID  
   
   
	SET @CSTEP=440
	
	 DECLARE @NCOUNT INT,@BLOOP INT,@CCMD NVARCHAR(MAX)  
	 SET @NCOUNT=25  
	 SET @BLOOP=1  
	 WHILE (@BLOOP <=@NCOUNT )  
	 BEGIN  
         
       
		 SET @CCMD=N' IF EXISTS(SELECT  TOP 1 ''U''  
	   FROM ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST(NOLOCK)  
	   JOIN ARTICLE_FIX_ATTR A (NOLOCK) ON ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST.attr'+RTRIM(LTRIM(RTRIM(LTRIM(STR(@BLOOP)))))+'_key_code=A.attr'+RTRIM(LTRIM(STR(@BLOOP)))+'_key_code  
	   JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE  
	   JOIN SKU C (NOLOCK) ON C.ARTICLE_CODE=B.ARTICLE_CODE  
	   JOIN DebitNote_Proforma_DET D (NOLOCK) ON D.PRODUCT_CODE=C.PRODUCT_CODE  
	   WHERE memo_id='''+@CMEMOID+''' AND  
	   ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST.attr'+RTRIM(LTRIM(RTRIM(LTRIM(STR(@BLOOP)))))+'_key_code <> ''0000000'' )  
		SELECT  DISTINCT ''DNPF_ATTR'+RTRIM(LTRIM(RTRIM(LTRIM(STR(@BLOOP)))))+'_MST_MIRROR'' AS TARGET_TABLENAME,'''+@CMEMOID+''' AS DNPF_MEMO_ID,ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST.*   
		FROM ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST(NOLOCK)  
		JOIN ARTICLE_FIX_ATTR A (NOLOCK) ON ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST.attr'+RTRIM(LTRIM(STR(@BLOOP)))+'_key_code=A.attr'+RTRIM(LTRIM(STR(@BLOOP)))+'_key_code  
		JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE  
		JOIN SKU C (NOLOCK) ON C.ARTICLE_CODE=B.ARTICLE_CODE  
		JOIN DebitNote_Proforma_DET D (NOLOCK) ON D.PRODUCT_CODE=C.PRODUCT_CODE  
		WHERE memo_id='''+@CMEMOID+'''  
		and  ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST.attr'+RTRIM(LTRIM(RTRIM(LTRIM(STR(@BLOOP)))))+'_key_code <> ''0000000'' '  
      
		 PRINT  @CCMD  
		 EXEC SP_EXECUTESQL @CCMD  
          
		 SET @BLOOP=@BLOOP +1  
     
	 END  
  
 

	
	GOTO END_PROC

END TRY
BEGIN CATCH
	SET @CERRMSG='P: SP_SEND_MIRROR_DNPF_DATA_NEW, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH 		
END_PROC:
	
END
---END OF PROCEDURE - SP_SEND_MIRROR_DNPF_DATA_NEW
