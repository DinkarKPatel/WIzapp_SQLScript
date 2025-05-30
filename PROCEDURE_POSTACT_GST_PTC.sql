CREATE PROCEDURE POSTACT_GST_PTC--(LocId 3 digit change by Sanjay:26-11-2024 left changes by concerned developer)
(  
 @DTTO DATETIME,  
 @CDEPTID CHAR(4)='' , 
 @NLOOP NUMERIC(1,0),
 @BLOC BIT=0
)  
AS  
BEGIN  
  
  
    DECLARE @CSTEP VARCHAR(10),@BPOSTDISCOUNTSEPARATELY BIT,@CDISCACCODE VARCHAR(10),@BPOSTFREIGHTSEPARATELY BIT  
   ,@CPETTYCASHACCODE VARCHAR(10),@BPOSTOCTROISEPARATELY BIT,@COCTROIACCODE VARCHAR(10),  
   @BPOSTINSURANCESEPARATELY BIT,@CINSURANCEACCODE VARCHAR(10),  
   @BPOSTOTHERCHARGESSEPARATELY BIT,@COTHERCHARGESACCODE VARCHAR(10),@BPOSTROUNDOFFSEPARATELY BIT,@CROUNDOFFACCODE VARCHAR(10)  
   ,@NCTR NUMERIC(10,0),  
   @NSUBTOTAL NUMERIC(14,2),@NTAXAMOUNT NUMERIC(14,2), @CPURACCODE VARCHAR(50),@CTAXACCODE VARCHAR(100),  
   @LPOSTTAXSEPARATELY NUMERIC(14,2),@CPEMMEMOID VARCHAR(50),@LOUTSTATIONPARTY BIT,@TMPDR NUMERIC(14,2),  
   @TMPCR NUMERIC(14,2),@CCURSTATECODE VARCHAR(10),@CVMID VARCHAR(40),@CLOCATIONID CHAR(2),  
   @CLASTBILLNO VARCHAR(40),@DTMPVENDORBILLDT DATETIME,@CRMLIST VARCHAR(300),@NTMPCREDITDAYS NUMERIC(10),  
   @NTMPCRDISCOUNTPERCENTAGE NUMERIC(14,2),@DLASTINVDT DATETIME,@CVOUCHERCODE VARCHAR(10), @cCmd NVARCHAR(MAX), 
   @COLDBILLTYPE VARCHAR(10),@CLASTACCODE VARCHAR(10),@CLASTPARTYNAME VARCHAR(100),@NTOTQUANTITY NUMERIC(14,2),@bMixEntries BIT,  
   @NTOTNETAMOUNT NUMERIC(14,2),@CDEPTNAME VARCHAR(100),@CVOUCHERNO VARCHAR(10),@cHEAD_CODE VARCHAR(MAX),@cHEAD_CODE1 VARCHAR(MAX) 
 
 
   SET @CSTEP=10  
   PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
   DECLARE @CPARTYACCODE VARCHAR(10),@CPARTYSTATECODE VARCHAR(10),@NNETAMOUNT NUMERIC(14,2),  
   @NDISCAMOUNT NUMERIC(14,2),@NFREIGHT NUMERIC(14,2), @NOTHER NUMERIC(14,2),@NROUNDOFF NUMERIC(14,2),  
   @NDRTOTAL NUMERIC(14,2),@NCRTOTAL NUMERIC(14,2),@CCUTOFFDATE VARCHAR(20),@CXNTYPE VARCHAR(10),
   @CAC_CODE VARCHAR(20),@CVDID VARCHAR(40),@CERRORMSG VARCHAR(MAX),@BBLANKACFOUND BIT  ,@NDrCrLOOP int
      
    SET @CPETTYCASHACCODE=''  
    SET @CROUNDOFFACCODE=''  
      
    SET @CSTEP=20  
    --THIS TABLE VARIABLE STORE ERROR OF OF MEMO ID  
    DECLARE @ERRORS TABLE  
 (  
  XN_ID VARCHAR(40),XN_TYPE VARCHAR(30),XN_NO VARCHAR(40),  
  XN_DT DATETIME,XN_AMT NUMERIC(14,2),XN_AC VARCHAR(100),  
  ERR_DESC VARCHAR(500)  
 )     
      
    SET @CSTEP=30
	  PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
      
    DECLARE @VCHC TABLE   
 (  
  AC_CODE CHAR(10),NARRATION VARCHAR(200),XN_NO VARCHAR(30),  vm_id VARCHAR(50),
  XN_DT DATETIME,DEPT_ID CHAR(4),AMOUNT NUMERIC(14,4),XN_ID VARCHAR(50),  
  REF_BILL_NO VARCHAR(50),REF_BILL_DATE DATETIME, ENTRY_ID INT IDENTITY  
  ,CRDAYS NUMERIC(5)  
 )  
   
 SET @CSTEP=40  
 DECLARE @VDC TABLE   
 (  
  VD_ID VARCHAR(50),    VM_ID VARCHAR(40),    AC_CODE CHAR(10),   
  NARRATION VARCHAR(200),   DEBIT_AMOUNT NUMERIC(14,4),  CREDIT_AMOUNT NUMERIC(14,4),  
  X_TYPE CHAR(2),     VS_AC_CODE CHAR(10),    REF_BILL_NO VARCHAR(40),   
  CREDIT_DAYS NUMERIC(10),  CR_DISCOUNT_PERCENTAGE NUMERIC(14,2),    
  ENTRY_Id INT,REF_BILL_DATE DATETIME, AC_NAME VARCHAR(100)  
 )  
   
 SET @CSTEP=50  
   PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
 DECLARE @VMC TABLE  
 (  
  VM_ID VARCHAR(400),    VOUCHER_NO VARCHAR(400),   VOUCHER_DT DATETIME,   
  VOUCHER_CODE CHAR(10),   DEPT_ID CHAR(4),    BILL_TYPE VARCHAR(300),  
  BILL_NO VARCHAR(200),    BILL_ID VARCHAR(220),    BILL_DT DATETIME,   
  BILL_AC_CODE VARCHAR(100),  DRTOTAL NUMERIC(20,2),   CRTOTAL NUMERIC(20,2),   
  CASH_VOUCHER BIT,     SALE_VOUCHER BIT,     QUANTITY NUMERIC(20,2),   
  ANGADIA_CODE CHAR(70),    LR_NO VARCHAR(500),    LR_DT DATETIME,  
  PARTY_NAME VARCHAR(1000),  NET_AMOUNT NUMERIC(20,2),   BILL_STATUS VARCHAR(1000),  
  RM_LIST VARCHAR(3000),   CANCELLED BIT,     DEPT_NAME VARCHAR(100),  
  VOUCHER_TYPE VARCHAR(100)   
 )  
   
 SET @CSTEP=60  
 DECLARE @VLINK TABLE  
 (  
  VM_ID VARCHAR(100),MEMO_ID VARCHAR(100),XN_TYPE VARCHAR(20),LAST_UPDATE DATETIME  
 )  
   
 DECLARE @TBILL_BY_BILL_REF TABLE(VD_ID VARCHAR(40),REF_NO VARCHAR(100),AMOUNT NUMERIC(18,4),LAST_UPDATE DATETIME  
        ,X_TYPE VARCHAR(20),CR_DAYS NUMERIC(5),VM_ID VARCHAR(100))  
   
 SELECT TOP 1 @CCUTOFFDATE=CUTOFFDATE  
 FROM GST_ACCOUNTS_CONFIG_MST  WHERE XN_TYPE='PTC'
   
 SET @CCUTOFFDATE=ISNULL(@CCUTOFFDATE,'')  
   
 SET @CSTEP=70  
   PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
 SET @CVOUCHERCODE = '0000000002'  
  BEGIN TRY  
     
   SET @CSTEP=80  
   IF OBJECT_ID('TEMPDB..#POSTS','U') IS NOT NULL  
    DROP TABLE #POSTS   
     
   SET @CSTEP=90  
     PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
   --THIS TABLE STORE ALL PENDING MEMO_ID   
   CREATE TABLE #POSTS (MEMO_ID VARCHAR(30),MODE VARCHAR(10),dept_id varchar(4))  
     
   IF OBJECT_ID('#APPROVALLOCATION','U') IS NOT NULL  
    DROP TABLE #APPROVALLOCATION  
     
   --GETTING LIST OF LOCATIONS ON WHICH APPROVAL PROCESS IS ENABLED  
   SELECT DISTINCT DEPT_ID   
   INTO #APPROVALLOCATION  
   FROM LOC_XNSAPPROVAL  
   WHERE XN_TYPE='PTC'  
     
   DECLARE @IMAXLEVEL INT  
     
   --GETTING THE MAX LEVEL OF APPROVAL FOR PURCHASE TRANSACTION  
   SELECT @IMAXLEVEL=MAX(LEVEL_NO) FROM XN_APPROVAL_CHECKLIST_LEVELS WHERE XN_TYPE='PTC'   
   	IF EXISTS(SELECT TOP 1 'U' FROM XN_APPROVAL_CHECKLIST_LEVELS  WHERE XN_TYPE='PTC' AND INACTIVE=0 AND ISNULL(AC_POSTING,0)<>0)
	BEGIN
		SELECT @IMAXLEVEL=LEVEL_NO
		FROM XN_APPROVAL_CHECKLIST_LEVELS 
		WHERE XN_TYPE='PTC' AND INACTIVE=0 AND ISNULL(AC_POSTING,0)<>0
	END
			  
     SET @CSTEP=95
     PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
     
   SET @IMAXLEVEL=ISNULL(@IMAXLEVEL,0)  

	SELECT REPLACE(REPLACE(b.memo_id,'Cr',''),'Dr','') memo_id ,B.LAST_UPDATE 
	INTO #postedMemos 
	FROM POSTACT_VOUCHER_LINK B   
    JOIN VM01106 C ON C.VM_ID = B.VM_ID   
    WHERE C.CANCELLED=0 AND B.XN_TYPE = 'PTC'

	--AND NOT EXISTS (
 --   SELECT DISTINCT SUBSTRING(b.memo_id,1,len(b.memo_id)-2)  memo_id
	--FROM POSTACT_VOUCHER_LINK B1   
 --   JOIN VM01106 C1 ON C1.VM_ID = B1.VM_ID   
	--JOIN vm01106 d1 (NOLOCK) ON d1.ref_no=c1.ref_no
	--JOIN POSTACT_VOUCHER_LINK e1 (NOLOCK) ON e1.VM_ID=d1.VM_ID AND SUBSTRING(e1.memo_id,1,len(e1.memo_id)-2)=
	--SUBSTRING(b1.memo_id,1,len(b1.memo_id)-2)
 --   WHERE C1.CANCELLED=0 AND d1.cancelled=1 AND B1.XN_TYPE = 'PTC' AND RIGHT(b1.memo_id,2) IN  ('Cr','Dr')
	--AND e1.XN_TYPE='PTC' AND e1.VM_ID<>c1.vm_id )    
 
   SET @CSTEP=100  
     PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
   /*PETTYCASH EXPENSES FOR LOCATIONS WHERE APPROVAL IS ENABLED*/  
		 INSERT INTO #POSTS (MEMO_ID,MODE,dept_id )  
         SELECT DISTINCT A.PEM_MEMO_ID,'PTC' AS MODE,a.location_code    
         FROM PEM01106 A  
         JOIN LOCATION SL ON SL.DEPT_ID =A.LOCATION_CODE 
		 LEFT JOIN loc_accounting_company lac1 (NOLOCK) ON lac1.pan_no=sl.PAN_NO
		 LEFT JOIN loc_accounting_company lac2 (NOLOCK) ON lac2.pan_no=SUBSTRING(sl.loc_gst_no,3,10)   
		 LEFT OUTER JOIN #postedMemos VM  ON A.PEM_MEMO_ID = VM.MEMO_ID    
         WHERE    
         /*PETTYCASH EXPENSE IS NOT CANCELLED.*/  
         ((A.CANCELLED=1 AND VM.MEMO_ID IS NOT NULL) OR A.CANCELLED=0)     
         /*PETTYCASH EXPENSE INV_DT IS LESS THAN THE SPECIFIED DATE.*/  
         AND A.PEM_MEMO_DT <= @DTTO  
         /*IF CUTOFF DATE IS SPECIFIED, CONSIDER PETTYCASH EXPENSE AFTER THE CUTOFF DATE*/  
         AND (ISNULL(@CCUTOFFDATE,'')='' OR A.PEM_MEMO_DT>@CCUTOFFDATE)  
         /*IF ACCOUNTS_DEPT_ID IS FILLED UP APPLY FILTER TO LOCATION.*/  
         AND (ISNULL(@CDEPTID,'')='' OR A.LOCATION_CODE=@CDEPTID)  
         /*PETTYCASH EXPENSE IS NOT POSTED OR CORRESPONDING VOUCHER IS NOT CANCELLED*/  
         AND (VM.MEMO_ID IS NULL OR VM.LAST_UPDATE <> A.LAST_UPDATE)   
		 AND (lac1.pan_no IS NOT NULL OR lac2.pan_no IS NOT NULL)         

	  IF EXISTS (SELECT TOP 1 * FROM #APPROVALLOCATION)
	  BEGIN
		  SET @CSTEP=110
		  PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
		  DELETE A from #POSTS a 
		  JOIN PED01106 PED ON PED.PEM_MEMO_ID=A.MEMO_ID  
		  JOIN #APPROVALLOCATION AL ON a.dept_id=AL.DEPT_ID  
		   WHERE PED.APPROVEDLEVELNO<@IMAXLEVEL
	 END	
     
	 SET @CSTEP=150  
         --PETTY CASH A/C MUST BE CONFIGURED FOR POSTING   
      SELECT TOP 1 @CPETTYCASHACCODE=VALUE  FROM GST_ACCOUNTS_CONFIG_DET_OTHERS 
      WHERE XN_TYPE ='PTC' AND COLUMNNAME ='PETTY_CASH_AC_CODE'
      
      SET @CPETTYCASHACCODE=ISNULL(@CPETTYCASHACCODE,'')  
        
	--if @@spid=91
	--	select 'check posts',@IMAXLEVEL,@CCUTOFFDATE,* from #posts

   SET @CSTEP = 110  
     PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
   CREATE INDEX IX_TEMP_PTCTABLE_RM_ID ON #POSTS(MEMO_ID)  
           
   --SELECT COUNT(*) FROM #POSTS  
   SET @CSTEP = 120  

     
	  PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
    SELECT   PM.PEM_MEMO_NO  
        , PM.PEM_MEMO_ID  
        , PM.PEM_MEMO_DT  
        , PD.AC_CODE  
        , PD.NARRATION  
        , PD.XN_AMOUNT*(CASE WHEN PD.XN_TYPE='CR' THEN -1 ELSE 1 END) AS XN_AMOUNT  
        , PM.FIN_YEAR  
        , ''  AS PARTY_NAME  
        , PD.REF_NO  
        ,0 AS GST_PERCENTAGE
        ,'' AS SECTION_CODE
        ,'' AS SUB_SECTION_CODE
        ,'PTC' AS XN_TYPE  
        ,'PTC' AS POSTING_XN_TYPE  
        , PM.CANCELLED
	  ,'0000000000' AS IGST_REVENUE_AC_CODE
	  ,'0000000000' AS IGST_TAX_AC_CODE
	  ,CONVERT(NUMERIC(10,2),0) AS IGST_AMOUNT
	  ,'0000000000' AS LGST_REVENUE_AC_CODE
	  ,'0000000000' AS CGST_TAX_AC_CODE
	  ,'0000000000' AS SGST_TAX_AC_CODE
	   ,'0000000000' AS OTHER_CHARGES_IGST_REVENUE_AC_CODE
	   ,'0000000000' AS OTHER_CHARGES_IGST_TAX_AC_CODE
	  ,'0000000000' AS OTHER_CHARGES_LGST_REVENUE_AC_CODE
	  ,'0000000000' AS OTHER_CHARGES_CGST_TAX_AC_CODE
	  ,'0000000000' AS OTHER_CHARGES_SGST_TAX_AC_CODE
      ,0 gst_cess_percentage,'' gst_cess_ac_code 
      ,pm.location_code as Dept_id    
   INTO #V_PROCESS  
   FROM PEM01106 PM   
   JOIN PED01106 PD ON PM.PEM_MEMO_ID=PD.PEM_MEMO_ID  
   JOIN #POSTS PT ON PT.MEMO_ID = PM.PEM_MEMO_ID AND PT.MODE='PTC'  
   WHERE HIDDENFROMAPPROVAL<>1  


 --  if @@spid=91
	--select 'check vprocess',* from #V_PROCESS
	SET @CSTEP = 130     
     PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
   UPDATE A SET NARRATION=(SELECT TOP 1 NARRATION FROM #V_PROCESS B WHERE B.AC_CODE=A.AC_CODE AND B.PEM_MEMO_ID=A.PEM_MEMO_ID)
   FROM #V_PROCESS A 
   JOIN LMP01106 C ON A.AC_CODE=C.AC_CODE
   WHERE C.BILL_BY_BILL=1
     
  CREATE INDEX IX_V_PROCESS_RM_ID ON #V_PROCESS(PEM_MEMO_ID,XN_TYPE)  
   
  IF ISNULL(@CPETTYCASHACCODE,'') IN ('','0000000000')
  BEGIN 
		SET @CSTEP = 140  
  PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
		IF OBJECT_ID('TEMPDB..#V_PROCESS_OTHERS','U') IS NOT NULL
			DROP TABLE #V_PROCESS_OTHERS
			
		SELECT TOP 1 'PTC' AS XN_TYPE,'PETTY_CASH_AC_CODE' AS  COLUMNNAME,'PETTY CASH A/C' AS COLUMNDESC
		INTO #V_PROCESS_OTHERS FROM #V_PROCESS 
		
		
	  SET @CSTEP = 150  
	    PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
      EXEC SP3S_GET_POSTING_BLANKAC
			@CXNTYPE='PTC',
			@NLOOP=@NLOOP,
			@CERRORMSG=@CERRORMSG OUTPUT,
			@BBLANKACFOUND=@BBLANKACFOUND OUTPUT		
		
		IF @BBLANKACFOUND=1 OR @CERRORMSG<>'' OR @NLOOP=0
			GOTO END_PROC

  END
  		    
  SELECT @CPEMMEMOID='',@CXNTYPE='',@CAC_CODE='',@NCTR=1  
  SET @CSTEP = 160  
    PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
  WHILE EXISTS(SELECT TOP 1 'U' FROM #V_PROCESS)  
  BEGIN  
	   SET @CSTEP = 170  
	     PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
	   SELECT TOP 1 @CPEMMEMOID=PEM_MEMO_ID,@CXNTYPE=XN_TYPE,@CAC_CODE=AC_CODE FROM #V_PROCESS  
     
	   SET @CSTEP = 180 
	   SET @NDrCrLOOP=1
	   IF EXISTS (SELECT TOP 1 pem_memo_id FROM #V_PROCESS WHERE pem_memo_id=@cPemMemoId
				  AND xn_amount<0)
		AND EXISTS (SELECT TOP 1 pem_memo_id FROM #V_PROCESS WHERE pem_memo_id=@cPemMemoId
				  AND xn_amount>0)
			SET @NDrCrLOOP=2
		
       SET @bMixEntries=(CASE WHEN @NDrCrLOOP=2 THEN 1 ELSE 0 END)

	 --  if @@spid=91
		--select @bMixEntries,@CPEMMEMOID
		
	   WHILE @NDrCrLOOP>0
	   BEGIN
		
			SET @CSTEP = 190  
			  PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
		   SET @CVMID = ''  
		   SELECT @CVMID = A.VM_ID   
		   FROM POSTACT_VOUCHER_LINK A  
		   JOIN VM01106 B ON A.VM_ID=B.VM_ID  
		   WHERE B.CANCELLED=0 AND 
		   (A.MEMO_ID = @CPEMMEMOID+(CASE WHEN @NDrCrLOOP=2 THEN 'Dr' ELSE 'Cr' END) OR
		    A.MEMO_ID = @CPEMMEMOID AND @nDrCrLoop=1)
		   AND A.XN_TYPE=@CXNTYPE  
			
		   SET @CSTEP = 200  
		   IF ISNULL(@CVMID,'') = ''  
		   BEGIN  
			   IF @NDrCrLOOP=2	
					SET @CVMID = 'LATERPTCDr-'+RTRIM(LTRIM(CONVERT(VARCHAR,@NCTR)))
			   ELSE
					SET @CVMID = 'LATERPTCCr-'+RTRIM(LTRIM(CONVERT(VARCHAR,@NCTR)))

			   SET @NCTR = @NCTR+1  
		   END  

		   SET @CSTEP = 210  
		     PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
		   SET @cCmd=N'SELECT '''+@cVmId+''' vm_id,AC_CODE,SUM(XN_AMOUNT),NARRATION,PEM_MEMO_NO,PEM_MEMO_ID,
		   PEM_MEMO_DT,ISNULL(REF_NO,'''') AS REF_BILL_NO
		   FROM #V_PROCESS  
		   WHERE PEM_MEMO_ID='''+@CPEMMEMOID+'''
		   AND XN_AMOUNT'+(CASE WHEN @bMixEntries=0 THEN '<>0' WHEN  @nDrCrLoop=2 THEN '<0' ELSE '>0' END)+
		   ' GROUP BY AC_CODE,NARRATION,PEM_MEMO_NO,PEM_MEMO_ID,PEM_MEMO_DT,ISNULL(REF_NO,'''') '
		   

		   PRINT @cCmd
		   --EXPENSE ACCOUNT SHOULD BE DEBITED/CREDITED WITH THE RESPECTIVE AMOUNT AS PER THE TRANSACTION  
		   INSERT @VCHC (vm_id, AC_CODE, AMOUNT,NARRATION,XN_NO,XN_ID,XN_DT,REF_BILL_NO )  
		   EXEC SP_EXECUTESQL @cCmd

		   SET @CSTEP = 220  
		   INSERT INTO @VLINK(VM_ID ,MEMO_ID,XN_TYPE,LAST_UPDATE )  
		   SELECT @CVMID,@CPEMMEMOID+(CASE WHEN @NDrCrLOOP=2 THEN 'Dr' ELSE 'Cr' END),@CXNTYPE,LAST_UPDATE FROM PEM01106 WHERE PEM_MEMO_ID = @CPEMMEMOID  

			SET @CSTEP = 225
			  PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
			INSERT @VMC ( VM_ID, VOUCHER_DT, VOUCHER_CODE, DEPT_ID,   
			BILL_TYPE, BILL_NO, BILL_ID, BILL_DT,   
			PARTY_NAME, QUANTITY, NET_AMOUNT, CANCELLED,DRTOTAL,CRTOTAL )  
			SELECT TOP 1 @CVMID,PEM_MEMO_DT,@CVOUCHERCODE,dept_id AS DEPT_ID  
				,@CXNTYPE,PEM_MEMO_NO,PEM_MEMO_ID,PEM_MEMO_DT,'',0,XN_AMOUNT,CANCELLED,@NDRTOTAL,@NCRTOTAL  
			FROM #V_PROCESS  
			WHERE PEM_MEMO_ID=@CPEMMEMOID  

		   SET @CSTEP = 230  
		     PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
		   IF @nDrCrLoop=1
			   INSERT @VchC  (vm_id, AC_CODE, AMOUNT,NARRATION,XN_NO,XN_ID,XN_DT )   
			   SELECT @cVmId vm_id, @CPETTYCASHACCODE,-SUM(XN_AMOUNT)  
				  ,'PETTY EXPENSES FOR DATE : '+LTRIM(RTRIM(CONVERT(VARCHAR,PEM_MEMO_DT,105)))  
				   +' MEMO NO. : '+LTRIM(RTRIM(PEM_MEMO_NO)),PEM_MEMO_NO,PEM_MEMO_ID  ,PEM_MEMO_DT
			   FROM #V_PROCESS   
			   WHERE PEM_MEMO_ID=@CPEMMEMOID AND ((@bMixEntries=1 AND XN_AMOUNT>0) OR (@bMixEntries=0 AND XN_AMOUNT<>0))  
			   GROUP BY PEM_MEMO_DT,PEM_MEMO_NO,PEM_MEMO_NO,PEM_MEMO_ID  
		   ELSE	     
			   --PETTY CASH A/C SHOULD BE DEBITED/CREDITED WITH THE TOTAL AMOUNT  
			   INSERT @VCHC (vm_id, AC_CODE, AMOUNT,NARRATION,XN_NO,XN_ID,XN_DT )  
			   SELECT @cVmId vm_id,@CPETTYCASHACCODE,ABS(SUM(XN_AMOUNT))
				  ,'PETTY CASH RECEIPT FOR DATE : '+LTRIM(RTRIM(CONVERT(VARCHAR,PEM_MEMO_DT,105)))  
				   +' MEMO NO. : '+LTRIM(RTRIM(PEM_MEMO_NO)),PEM_MEMO_NO,PEM_MEMO_ID ,PEM_MEMO_DT 
			   FROM #V_PROCESS   
			   WHERE PEM_MEMO_ID=@CPEMMEMOID AND ((@bMixEntries=1 AND XN_AMOUNT<0) OR (@bMixEntries=0 AND XN_AMOUNT<>0))    
			   GROUP BY PEM_MEMO_DT,PEM_MEMO_NO,PEM_MEMO_NO,PEM_MEMO_ID  

   		 SET @CSTEP = 240  
		   PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
		  SELECT @NDRTOTAL =SUM(case when amount>0 then amount else 0 end),@NCRTOTAL=SUM(case when amount<0 then abs(amount) else 0 end) FROM @VchC
		  WHERE VM_ID = @CVMID  

		  
		UPDate @VMc set drtotal=@NDRTOTAL,crtotal=@NCRTOTAL WHERE vm_id=@cVmId

			SET @NDrCrLOOP=@NDrCrLOOP-1
		 END
	    
        
		  --BILL BY BILL REF  
			SET @cHEAD_CODE  = DBO.FN_ACT_TRAVTREE('0000000018')	----ADD VARIABLE BY GAURI ON 17/4/2019	
			SET @cHEAD_CODE1	= DBO.FN_ACT_TRAVTREE('0000000021')	----ADD VARIABLE BY GAURI ON 17/4/2019	
		

		   SET @CSTEP = 250  
		     PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
		   INSERT @VDC (VM_ID, VD_ID, AC_CODE, NARRATION, DEBIT_AMOUNT, CREDIT_AMOUNT, X_TYPE,   
				CREDIT_DAYS, CR_DISCOUNT_PERCENTAGE,AC_NAME,ENTRY_Id )  
		   SELECT vm_id
			, 'LATERPTC-'+CONVERT(VARCHAR,ROW_NUMBER() OVER(ORDER BY A.AC_CODE)) AS VD_ID  
			, A.AC_CODE  
			,A.NARRATION AS NARRATION  
			,(CASE WHEN SUM(AMOUNT)>0 THEN SUM(AMOUNT) ELSE 0 END) AS DEBIT_AMOUNT  
			,(CASE WHEN SUM(AMOUNT)<0 THEN ABS(SUM(AMOUNT)) ELSE 0 END) AS CREDIT_AMOUNT  
			,(CASE WHEN SUM(AMOUNT) > 0 THEN 'DR' ELSE 'CR' END) AS X_TYPE  
			,A.CRDAYS  
			,0  
			,B.AC_NAME  
			,A.ENTRY_ID   
			 FROM @vchC a
			 JOIN LMV01106 B ON A.AC_CODE = B.AC_CODE  
			 GROUP BY vm_id, A.ENTRY_ID ,A.AC_CODE,A.NARRATION,B.AC_NAME,A.CRDAYS  
		
			INSERT @TBILL_BY_BILL_REF  
		   (VD_ID,REF_NO,AMOUNT,LAST_UPDATE,X_TYPE,CR_DAYS,VM_ID)  
		   SELECT C.VD_ID  
			  ,(CASE WHEN ISNULL(A.REF_BILL_NO,'')='' THEN DBO.FN_GETBILLBYBILL_REFNO(A.AC_CODE,LTRIM(RTRIM(A.XN_NO))
				,A.XN_DT,(CASE WHEN C.DEBIT_AMOUNT<>0 THEN 'DR' ELSE 'CR' END),@CVMID) ELSE A.REF_BILL_NO END)
			  AS REF_NO  
			  ,ABS(SUM(A.AMOUNT)),GETDATE()  
			  ,(CASE WHEN C.DEBIT_AMOUNT<>0 THEN 'DR' ELSE 'CR' END) AS X_TYPE  
			  ,A.CRDAYS   
			  ,C.VM_ID
		   FROM @VCHC A   
		   JOIN LMP01106 B ON A.AC_CODE=B.AC_CODE  
		   JOIN @VDC C ON C.ENTRY_ID =A.ENTRY_ID  
		   JOIN LM01106 D ON A.AC_CODE=D.AC_CODE  
		   WHERE 
		   (B.BILL_BY_BILL=1  OR CHARINDEX(D.HEAD_CODE,@cHEAD_CODE)<>0	----REPLACE VARIABLE FROM FUNCTION BY GAURI ON 17/4/2019
							  OR CHARINDEX(D.HEAD_CODE,@cHEAD_CODE1)<>0) ----REPLACE VARIABLE FROM FUNCTION BY GAURI ON 17/4/2019
		   GROUP BY  A.CRDAYS ,(CASE WHEN ISNULL(A.REF_BILL_NO,'')='' THEN DBO.FN_GETBILLBYBILL_REFNO(A.AC_CODE,LTRIM(RTRIM(A.XN_NO))
				,A.XN_DT,(CASE WHEN C.DEBIT_AMOUNT<>0 THEN 'DR' ELSE 'CR' END),@CVMID) ELSE A.REF_BILL_NO END),
			  C.VD_ID,C.DEBIT_AMOUNT,C.VM_ID  
        
		  SET @CSTEP = 260      
		    PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
			 SET @CVOUCHERNO = ''   
			 SELECT TOP 1 @CVOUCHERNO = VOUCHER_NO FROM VM01106 WHERE VM_ID = @CVMID  
			 IF ISNULL(@CVOUCHERNO,'') = ''  
		SET @CVOUCHERNO = @CVMID  
           
     
		SET @CSTEP = 280  
		DELETE @VCHC  
     
     
        DELETE FROM #V_PROCESS WHERE PEM_MEMO_ID = @CPEMMEMOID AND XN_TYPE=@CXNTYPE  
  END         
  
ENDPROC:  


	DECLARE @nSpId VARCHAR(40)
	
   
  
   SET @CSTEP=282
   set @nSpId=ltrim(rtrim(str(@@spid)))  

	EXEC SP_CHKXNSAVELOG 'PTCPOST',@cStep,1,@nSpId,'',1	 	
	
	DELETE FROM ACT_VM01106_UPLOAD WHERE SP_ID=@NSPID
	DELETE FROM ACT_VD01106_UPLOAD WHERE SP_ID=@NSPID
	DELETE FROM ACT_BILL_BY_BILL_REF_UPLOAD WHERE SP_ID=@NSPID
	DELETE FROM ACT_POSTACT_VOUCHER_LINK_UPLOAD WHERE SP_ID=@NSPID
	
	SET @CSTEP = 284
	EXEC SP_CHKXNSAVELOG 'PTCPOST',@cStep,1,@nSpId,'',1	 		
	PRINT 'START POSTING PTC:'+@CSTEP+' '+CONVERT(VARCHAR,GETDATE(),113)
    INSERT ACT_VM01106_UPLOAD	( ANGADIA_CODE, APPROVED, APPROVEDLEVELNO, ATTACHMENT_FILE, AUDITED_DT, 
    AUDITED_USER_CODE, BILL_AC_CODE, BILL_DT, BILL_ID, BILL_NO, BILL_TYPE, CANCELLED, CASH_VOUCHER, COMPANY_CODE, 
    CRTOTAL, DEPT_ID, DRTOTAL, EDT_USER_CODE, FIN_YEAR, FREEZE, LAST_UPDATE, LR_DT, LR_NO, MEMO, MRR_LIST, OP_ENTRY,
    QUANTITY, REF_NO, REF_VM_ID, REMINDER_DAYS, SALE_VOUCHER, SENT_FOR_RECON, SENT_TO_HO, SMS_SENT, SR_NO, 
    UPLOADED_TO_ACTIVSTREAM, USER_CODE, VM_ID, VM_NO, VOUCHER_CODE, VOUCHER_DT, VOUCHER_NO, SP_ID,TEMP_VM_ID )  
    SELECT 	  ANGADIA_CODE,0 AS APPROVED,0 AS APPROVEDLEVELNO,'' AS ATTACHMENT_FILE,'' AS AUDITED_DT, 
    '' AS AUDITED_USER_CODE, BILL_AC_CODE,BILL_DT, ISNULL(BILL_ID,'') AS BILL_ID,ISNULL( BILL_NO,'') AS BILL_NO,
     BILL_TYPE,CANCELLED, 
    0 AS CASH_VOUCHER, '01' AS COMPANY_CODE, CRTOTAL, DEPT_ID, DRTOTAL,'' AS EDT_USER_CODE,
	('01'+dbo.FN_GETFINYEAR(voucher_dt)) FIN_YEAR, 
    0 AS FREEZE,GETDATE() AS  LAST_UPDATE,'' AS LR_DT,'' AS LR_NO,0 AS MEMO,'' AS MRR_LIST,0 AS  OP_ENTRY,
    QUANTITY, '' AS REF_NO,'' AS REF_VM_ID,0 AS  REMINDER_DAYS,1 AS SALE_VOUCHER,0 AS  SENT_FOR_RECON,0 AS SENT_TO_HO, 
    0 AS SMS_SENT,0 AS SR_NO,0 AS UPLOADED_TO_ACTIVSTREAM,'0000000' AS USER_CODE,
    VM_ID,'' AS VM_NO, VOUCHER_CODE, VOUCHER_DT,VOUCHER_NO, @NSPID AS SP_ID,'' AS TEMP_VM_ID 
    FROM @vmC A 
    
	
	SET @CSTEP = 286
	EXEC SP_CHKXNSAVELOG 'PTCPOST',@cStep,1,@nSpId,'',1	 		

	PRINT 'START POSTING PTC:'+@CSTEP+' '+CONVERT(VARCHAR,GETDATE(),113)
	INSERT ACT_VD01106_UPLOAD	( AC_CODE, AUTOENTRY, CHK_RECON, COMPANY_CODE, CONTROL_AC, COST_CENTER_AC_CODE, COST_CENTER_DEPT_ID, 
	CREDIT_AMOUNT, DEBIT_AMOUNT, LAST_UPDATE, NARRATION, RECON_DT, SECONDARY_NARRATION, VAT_ENTRY, VD_ID, VM_ID, VS_AC_CODE, X_TYPE, SP_ID,TEMP_VD_ID )
	SELECT AC_CODE,0 AS AUTOENTRY,0 AS CHK_RECON,'01' AS COMPANY_CODE,0 AS CONTROL_AC,'0000000000' AS COST_CENTER_AC_CODE, 
	ISNULL(b.Dept_id,@CDEPTID) AS COST_CENTER_DEPT_ID,CREDIT_AMOUNT, DEBIT_AMOUNT,GETDATE() AS LAST_UPDATE,ISNULL(NARRATION,'') AS NARRATION,'' AS RECON_DT, 
	'' AS SECONDARY_NARRATION, 0 AS VAT_ENTRY,VD_ID,A.VM_ID,ISNULL(VS_AC_CODE,'0000000000') AS VS_AC_CODE,
	X_TYPE, @NSPID AS SP_ID,'' AS TEMP_VD_ID 
	FROM @vdC A
	JOIN @vmC B ON A.VM_ID=B.VM_ID
    WHERE (DEBIT_AMOUNT<>0 OR CREDIT_AMOUNT<>0)

	
	SET @CSTEP = 288
	EXEC SP_CHKXNSAVELOG 'PTCPOST',@cStep,1,@nSpId,'',1	 		
	PRINT 'START POSTING PTC:'+@CSTEP+' '+CONVERT(VARCHAR,GETDATE(),113)
	INSERT ACT_BILL_BY_BILL_REF_UPLOAD	( ADJ_REMARKS, AMOUNT, BB_ROW_ID, CR_DAYS, LAST_UPDATE, PAYMENT_ADJ_REF_NO, 
	REF_NO,  REMARKS, VD_ID, X_TYPE, SP_ID ,VM_ID,cd_percentage,cd_base_amount,ignore_cd_base_amount,
	cd_posted,org_bill_amount,org_bill_dt,org_bill_no)  
	SELECT '' AS ADJ_REMARKS,AMOUNT,'' AS BB_ROW_ID,0 AS CR_DAYS,GETDATE() AS LAST_UPDATE,'' AS PAYMENT_ADJ_REF_NO, 
	a.ref_no, '' AS REMARKS,A.VD_ID,A.X_TYPE,@NSPID AS SP_ID,A.VM_ID,
	0 cd_percentage,0 cd_base_amount,0 ignore_cd_base_amount,0 cd_posted,d.net_amount as org_bill_amount,
	d.inv_DT org_bill_dt,d.inv_no org_bill_no FROM @TBILL_BY_BILL_REF A
    JOIN @vdC B ON A.VD_ID=B.VD_ID AND A.VM_ID=B.VM_ID
    JOIN @vmC C ON B.VM_ID=C.VM_ID
	JOIN @vLink v ON v.VM_ID=c.VM_ID
	LEFT JOIN inm01106 d ON d.inv_id=v.MEMO_ID
    WHERE A.AMOUNT<>0
	
	SET @CSTEP = 290
	EXEC SP_CHKXNSAVELOG 'PTCPOST',@cStep,1,@nSpId,'',1	 		
	
	PRINT 'START POSTING PTC:'+@CSTEP+' '+CONVERT(VARCHAR,GETDATE(),113)
	INSERT ACT_POSTACT_VOUCHER_LINK_UPLOAD	( LAST_UPDATE, MEMO_ID, VM_ID, XN_TYPE, SP_ID )  
	SELECT 	LAST_UPDATE, MEMO_ID, A.VM_ID, A.XN_TYPE, @NSPID AS SP_ID 
	FROM @vlink A
    JOIN @vmC B ON A.VM_ID=B.VM_ID
	
    SET @CSTEP = 292  
	  PRINT 'Running Step#'+@cStep+':'+convert(varchar,getdate(),113)
    SELECT @nSpId sp_id, CONVERT(BIT,1) AS CHK,CONVERT(BIT,1) optimized,*,CONVERT(BIT,0) AS ERROR_FLAG,CONVERT(VARCHAR(500),'') AS ERROR_DESC
    FROM @VMC ORDER BY VM_ID  
    
    SELECT * FROM @VDC ORDER BY VM_ID  
    SELECT * FROM @ERRORS WHERE 1=2  
    SELECT * FROM @VLINK ORDER BY VM_ID  
      
	SELECT B.AC_NAME,A.*,A.REF_NO AS BILL_NO FROM @TBILL_BY_BILL_REF A
	JOIN @VDC B ON A.VD_ID=B.VD_ID AND A.VM_ID=B.VM_ID
	JOIN @VLINK C ON B.VM_ID=C.VM_ID
	LEFT OUTER JOIN @ERRORS D ON C.MEMO_ID=D.XN_ID
	WHERE D.ERR_DESC IS NULL
    
END TRY  
BEGIN CATCH  
  SET @CERRORMSG= 'PROCEDURE POSTACT_GST_PTC ERROR AT STEP#'+@CSTEP+' '+ERROR_MESSAGE()
  GOTO END_PROC 
END CATCH  

END_PROC:
	IF ISNULL(@CERRORMSG,'')<>''
		SELECT @CERRORMSG AS ERRMSG           
END 
--END OF PROCEDURE - POSTACT_GST_PTC

