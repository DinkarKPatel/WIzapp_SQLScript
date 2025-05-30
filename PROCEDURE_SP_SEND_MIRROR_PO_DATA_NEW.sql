CREATE PROCEDURE SP_SEND_MIRROR_PO_DATA_NEW
(	
	 @CUPLOADEDXNID VARCHAR(50)
	,@CCURLOCID VARCHAR(5)	
	,@BACKNOWLEDGE BIT=0
	,@CERRMSG VARCHAR(1000) OUTPUT
)	
--WITH ENCRYPTION
AS
/*
	SP_SEND_MIRROR_PO_DATA_NEW_208_01_02_14 : THIS PROCEDURE WILL SEND PURCHASE ORDER DATA FROM LOCATION TO HO.
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
/*POM01106,POD01106,POM01106_AUDIT,POD01106_AUDIT,FORM,LM01106,LMP01106,HD01106,AREA,CITY,STATE,ARTICLE,SECTIOND
,SECTIONM,PARA1,PARA2,PARA3,PARA4,PARA5,PARA6,SKU,SKU_OH,ART_ATTR,ATTRM,ATTR_KEY*/
	
	---- SEND THE PO MEMO MASTER TABLE
	SELECT DISTINCT 'PO_POM01106_UPLOAD' AS TARGET_TABLENAME,A.* ,@CMEMOID AS XN_ID FROM POM01106(NOLOCK) A 
    WHERE A.PO_ID=@CMEMOID  
	
	SET @CSTEP=230
	---- SEND THE PO MEMO DETAIL TABLE
	 SELECT DISTINCT 'PO_POD01106_UPLOAD' AS TARGET_TABLENAME,A.* FROM POD01106(NOLOCK) A WHERE A.PO_ID=@CMEMOID  
   
	
	SET @CSTEP=240
	---- SEND THE DEBITNOTE MEMO SKU TABLE
	 SELECT DISTINCT 'PO_SKU_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS PO_MEMO_ID FROM SKU A  (NOLOCK)
	 JOIN POD01106 POD (NOLOCK) ON A.PRODUCT_CODE=POD.PRODUCT_CODE 
	 WHERE POD.PO_ID=@CMEMOID  
   
	
	SET @CSTEP=250
	---- SEND THE SKU_OH RELATED TO GIVEN PO MEMO
	 SELECT DISTINCT 'PO_SKU_OH_UPLOAD' AS TARGET_TABLENAME,A.* ,@CMEMOID AS PO_MEMO_ID FROM SKU_OH A  (NOLOCK)
	 JOIN POD01106 POD (NOLOCK) ON A.PRODUCT_CODE=POD.PRODUCT_CODE 
	 WHERE POD.PO_ID=@CMEMOID  
	

	
	SET @CSTEP=340
	---- SEND THE ARTICLE RELATED TO GIVEN PO MEMO

	IF OBJECT_ID ('TEMPDB..#TMPARTICLE','U') IS NOT NULL
	   DROP TABLE #TMPARTICLE

	SELECT A.ARTICLE_CODE INTO #TMPARTICLE FROM POD01106 A (NOLOCK)
	WHERE A.PO_ID=@CMEMOID
	UNION
	SELECT B.ARTICLE_CODE  FROM POD01106 A (NOLOCK)
	JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE
	WHERE A.PO_ID=@CMEMOID

	SELECT DISTINCT 'PO_ARTICLE_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS PO_MEMO_ID FROM ARTICLE A  (NOLOCK)
	JOIN #TMPARTICLE B ON A.ARTICLE_CODE =B.ARTICLE_CODE 
	

	SELECT DISTINCT 'PO_UOM_UPLOAD' AS TARGET_TABLENAME,UOM.*,@CMEMOID AS PO_MEMO_ID FROM #TMPARTICLE A
	JOIN ARTICLE B (NOLOCK) ON A.article_code =B.ARTICLE_CODE 
	JOIN UOM  (NOLOCK) ON UOM.UOM_CODE =B.UOM_CODE 
	
	
	SET @CSTEP=350
	---- SEND THE SECTIOND RELATED TO GIVEN PO MEMO
	SELECT DISTINCT 'PO_SECTIOND_UPLOAD' AS TARGET_TABLENAME,SECTIOND.*,@CMEMOID AS PO_MEMO_ID FROM #TMPARTICLE A
	JOIN ARTICLE B (NOLOCK) ON A.article_code =B.ARTICLE_CODE 
	JOIN SECTIOND  (NOLOCK) ON SECTIOND.sub_section_code =B.sub_section_code 
	
	
	SET @CSTEP=360
	---- SEND THE SECTIONM RELATED TO GIVEN PO MEMO
	SELECT DISTINCT 'PO_SECTIONM_UPLOAD' AS TARGET_TABLENAME,SECTIONM.*,@CMEMOID AS PO_MEMO_ID FROM #TMPARTICLE A
	JOIN ARTICLE B (NOLOCK) ON A.article_code =B.ARTICLE_CODE 
	JOIN SECTIOND  (NOLOCK) ON SECTIOND.sub_section_code =B.sub_section_code 
	JOIN SECTIONM  (NOLOCK) ON sectionM.section_code =SECTIOND.section_code 
	
		IF OBJECT_ID ('TEMPDB..#TMPPARA','U') IS NOT NULL
	       DROP TABLE #TMPPARA

		   SELECT PARA1_CODE ,PARA2_CODE,PARA3_CODE,PARA4_CODE ,PARA5_CODE,PARA6_CODE 
		   INTO #TMPPARA
		   FROM POD01106 (NOLOCK) WHERE PO_ID=@CMEMOID
		   UNION
		   SELECT B.PARA1_CODE ,B.PARA2_CODE,B.PARA3_CODE,B.PARA4_CODE ,B.PARA5_CODE,B.PARA6_CODE 
		   FROM POD01106 A (NOLOCK)
	       JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE
	       WHERE A.PO_ID=@CMEMOID

	SET @CSTEP=370
	---- SEND THE PARA1 RELATED TO GIVEN PO MEMO

    SELECT DISTINCT 'PO_PARA1_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS PO_MEMO_ID FROM PARA1 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA1_CODE  =B.PARA1_CODE 

	SET @CSTEP=380
	---- SEND THE PARA2 RELATED TO GIVEN PO MEMO

	SELECT DISTINCT 'PO_PARA2_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS PO_MEMO_ID FROM PARA2 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA2_CODE  =B.PARA2_CODE 

	SET @CSTEP=390
	---- SEND THE PARA3 RELATED TO GIVEN PO MEMO
	SELECT DISTINCT 'PO_PARA3_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS PO_MEMO_ID FROM PARA3 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA3_CODE  =B.PARA3_CODE 

	SET @CSTEP=400
	---- SEND THE PARA4 RELATED TO GIVEN PO MEMO
	SELECT DISTINCT 'PO_PARA4_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS PO_MEMO_ID FROM PARA4 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA4_CODE  =B.PARA4_CODE 

	SET @CSTEP=410
	---- SEND THE PARA5 RELATED TO GIVEN PO MEMO
	SELECT DISTINCT 'PO_PARA5_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS PO_MEMO_ID FROM PARA5 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA5_CODE  =B.PARA5_CODE 

	SET @CSTEP=420
	---- SEND THE PARA6 RELATED TO GIVEN PO MEMO
	SELECT DISTINCT 'PO_PARA6_UPLOAD' AS TARGET_TABLENAME,A.*,@CMEMOID AS PO_MEMO_ID FROM PARA6 A
	JOIN #TMPPARA B (NOLOCK) ON A.PARA6_CODE  =B.PARA6_CODE 

	
	SET @CSTEP=430
	---- SEND THE ART_ATTR RELATED TO GIVEN PO MEMO
	
	
	SELECT  DISTINCT 'PO_ARTICLE_FIX_ATTR_MIRROR' AS TARGET_TABLENAME,@CMEMOID AS PO_MEMO_ID,A.* FROM ARTICLE_FIX_ATTR A (NOLOCK)  
	 JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE  
	 JOIN SKU C (NOLOCK) ON C.ARTICLE_CODE=B.ARTICLE_CODE  
	 JOIN POD01106 D (NOLOCK) ON D.PRODUCT_CODE=C.PRODUCT_CODE  
	 WHERE PO_ID=@CMEMOID  
   
   
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
	   JOIN POD01106 D (NOLOCK) ON D.PRODUCT_CODE=C.PRODUCT_CODE  
	   WHERE PO_ID='''+@CMEMOID+''' AND  
	   ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST.attr'+RTRIM(LTRIM(RTRIM(LTRIM(STR(@BLOOP)))))+'_key_code <> ''0000000'' )  
		SELECT  DISTINCT ''PO_ATTR'+RTRIM(LTRIM(RTRIM(LTRIM(STR(@BLOOP)))))+'_MST_MIRROR'' AS TARGET_TABLENAME,'''+@CMEMOID+''' AS PO_MEMO_ID,ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST.*   
		FROM ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST(NOLOCK)  
		JOIN ARTICLE_FIX_ATTR A (NOLOCK) ON ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST.attr'+RTRIM(LTRIM(STR(@BLOOP)))+'_key_code=A.attr'+RTRIM(LTRIM(STR(@BLOOP)))+'_key_code  
		JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE  
		JOIN SKU C (NOLOCK) ON C.ARTICLE_CODE=B.ARTICLE_CODE  
		JOIN POD01106 D (NOLOCK) ON D.PRODUCT_CODE=C.PRODUCT_CODE  
		WHERE PO_ID='''+@CMEMOID+'''  
		and  ATTR'+RTRIM(LTRIM(STR(@BLOOP)))+'_MST.attr'+RTRIM(LTRIM(RTRIM(LTRIM(STR(@BLOOP)))))+'_key_code <> ''0000000'' '  
      
		 PRINT  @CCMD  
		 EXEC SP_EXECUTESQL @CCMD  
          
		 SET @BLOOP=@BLOOP +1  
     
	 END  
  
    SET @CSTEP=450

	SELECT 'PO_XN_AUDIT_TRIAL_DET_MIRROR' AS TARGET_TABLENAME,A.*,@CMEMOID AS PO_MEMO_ID FROM XN_AUDIT_TRIAL_DET A WHERE XN_TYPE ='PO' AND XN_ID=@CMEMOID


	
	GOTO END_PROC

END TRY
BEGIN CATCH
	SET @CERRMSG='P: SP_SEND_MIRROR_PO_DATA_NEW, STEP:'+@CSTEP+', MESSAGE:'+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH 		
END_PROC:
	
END
---END OF PROCEDURE - SP_SEND_MIRROR_PO_DATA_NEW
