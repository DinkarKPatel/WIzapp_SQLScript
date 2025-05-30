
CREATE PROC SPSIS_DATASENDING_MEMO
(
 @CPANNO VARCHAR(10)='',
 @CSIS_LINK_LOCATION VARCHAR(5)/*Rohit 01-11-2024*/='',
 @bAutosend bit=0
)
AS   
BEGIN  

		DECLARE @DCUTOFFDATE DATETIME,@CSIS_HO_ID VARCHAR(5)/*Rohit 01-11-2024*/,@cStep VARCHAR(10),@CSECONDRY_PAN_NO varchar(10)
		      
		SET @DCUTOFFDATE=''

		Delete From xntype_merging_errors where ABS(datediff(minute,last_update,getdate()))>60

		DECLARE @TBLXNDETAILS TABLE (XN_TYPE VARCHAR(30),XN_ID VARCHAR(50),TABLENAME VARCHAR(100),
		LASTUPDATE DATETIME,SEND_ORDER NUMERIC(5,0) ,COLUMNNAME VARCHAR(50),SOURCE_DEPT_ID VARCHAR(5)/*Rohit 01-11-2024*/)

		SELECT @DCUTOFFDATE=Cutoff_date,@CSIS_HO_ID=SIS_HO_ID,@CSECONDRY_PAN_NO=SECONDRY_PAN_NO  FROM SISLOCATIONDETAILS A
		WHERE PAN_NO=@CPANNO AND SIS_LINK_LOCATION=@CSIS_LINK_LOCATION

		   SELECT @CPANNO AS PAN_NO INTO #TMPPAN_NO 
		   if isnull(@CSECONDRY_PAN_NO,'')<>''
		       insert into #TMPPAN_NO select @CSECONDRY_PAN_NO

	    

		 IF (ISNULL(@DCUTOFFDATE,'')='' OR ISNULL(@CSIS_HO_ID,'')='')
		    RETURN

          DECLARE @CCURDEPTID VARCHAR(5)/*Rohit 01-11-2024*/,@CHODEPTID VARCHAR(5)/*Rohit 01-11-2024*/
		  SELECT @CCURDEPTID=VALUE  FROM config WHERE CONFIG_OPTION='LOCATION_ID'
		  SELECT @CHODEPTID=VALUE  FROM config WHERE CONFIG_OPTION='HO_LOCATION_ID'

		  IF @CCURDEPTID<>@CHODEPTID
		  RETURN

		  SELECT DEPT_ID into #tmplocation FROM LOCATION WHERE DEPT_ID =@CSIS_LINK_LOCATION


		  IF @CSIS_LINK_LOCATION=@CHODEPTID
		  BEGIN
		        INSERT INTO #TMPLOCATION(DEPT_ID)
				SELECT DEPT_ID FROM LOCATION A
				LEFT JOIN SISLOCATIONDETAILS B ON A.DEPT_ID =B.SIS_LINK_LOCATION
				WHERE B.SIS_LINK_LOCATION IS NULL 
				AND A.DEPT_ID<>@CSIS_LINK_LOCATION

		  END



		SET @cStep=10
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'1.PURCHASE INVOICE'

		SELECT A.MRR_ID,A.LAST_UPDATE,
		           ISNULL(L.SIS_HO_ID,@CHODEPTID) AS SOURCE_DEPT_ID,A.INV_MODE ,A.INV_ID 
		       INTO #TMPMRR
		FROM PIM01106 A (nolock)
		JOIN #TMPLOCATION LOC ON A.DEPT_ID =LOC.DEPT_ID
		LEFT JOIN SISLOCATIONDETAILS L (NOLOCK) ON /*LEFT(A.INV_ID,2)*//*Rohit 01-11-2024*/A.location_Code=L.SIS_LINK_LOCATION  
		WHERE  A.RECEIPT_DT  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		

		CREATE INDEX IX_SISMRRPIM ON #TMPMRR (MRR_ID)

		INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME,SOURCE_DEPT_ID)
		SELECT  'PUR' AS XN_TYPE,A.MRR_ID AS XN_ID,'PIM01106' AS TABLENAME,a.LAST_UPDATE ,40 AS  SEND_ORDER ,'MRR_ID' AS COLUMNNAME ,
		        A.SOURCE_DEPT_ID
		FROM #TMPMRR a (NOLOCK)  
		WHERE MRR_ID IN  (
		SELECT A.MRR_ID  FROM PID01106 B (NOLOCK)
		JOIN #TMPMRR A ON A.mrr_id =B.MRR_ID 
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO) AND INV_MODE=1
		)
		UNION ALL
		SELECT  'PUR' AS XN_TYPE,A.MRR_ID AS XN_ID,'PIM01106' AS TABLENAME,a.LAST_UPDATE ,40 AS  SEND_ORDER ,'MRR_ID' AS COLUMNNAME ,
		        A.SOURCE_DEPT_ID
		FROM #TMPMRR a (NOLOCK)  
		WHERE INV_ID IN  (
		SELECT A.INV_ID  FROM IND01106 B (NOLOCK)
		JOIN #TMPMRR A ON A.INV_ID =B.INV_ID 
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10)IN(SELECT PAN_NO FROM #TMPPAN_NO) AND INV_MODE=2 
		)

		INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME,SOURCE_DEPT_ID)
		SELECT  'PUR' AS XN_TYPE,A.MRR_ID AS XN_ID,'PIM01106' AS TABLENAME,a.LAST_UPDATE ,40 AS  SEND_ORDER ,'MRR_ID' AS COLUMNNAME ,
		        tmp.SOURCE_DEPT_ID
        FROM PIM01106 A (NOLOCK)
		JOIN #TMPMRR TMP ON TMP.MRR_ID =A.MRR_ID 
		LEFT JOIN @TBLXNDETAILS B ON A.MRR_ID =B.XN_ID AND B.XN_TYPE='PUR'
		WHERE   B.XN_ID IS NULL and a.PUMA_HO_SYNCH_LAST_UPDATE is not null
		and @bAutosend=0

		UPDATE A SET PUMA_HO_SYNCH_LAST_UPDATE =A.last_update 
		FROM PIM01106 A (NOLOCK)
		JOIN #TMPMRR TMP ON TMP.MRR_ID =A.MRR_ID 
		LEFT JOIN @TBLXNDETAILS B ON A.MRR_ID =B.XN_ID AND B.XN_TYPE='PUR'
		WHERE   B.XN_ID IS NULL
		





		SET @cStep=20
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'2.APPROVAL SALE '


		SELECT A.memo_id,A.LAST_UPDATE
		       INTO #TMPAPP
		FROM APM01106 A (nolock)
		JOIN #TMPLOCATION LOC ON /*LEFT(A.MEMO_ID,2)*//*Rohit 01-11-2024*/A.location_Code =LOC.DEPT_ID
		WHERE  A.MEMO_DT  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		

		CREATE INDEX IX_SISMEMOAPM ON #TMPAPP (memo_id)

		INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT  'APP' AS XN_TYPE,A.memo_id AS XN_ID,'APM01106' AS TABLENAME,a.LAST_UPDATE ,80 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME 
		FROM #TMPAPP a (NOLOCK)  
		WHERE A.MEMO_ID IN(
		SELECT b.MEMO_ID   FROM APD01106 B (NOLOCK) 
		JOIN #TMPAPP TMP ON B.MEMO_ID =B.MEMO_ID 
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		)

		INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT  'APP' AS XN_TYPE,A.memo_id AS XN_ID,'APM01106' AS TABLENAME,a.LAST_UPDATE ,80 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME 
		FROM apm01106 A (NOLOCK)
		JOIN #TMPAPP TMP ON TMP.memo_id =A.memo_id 
		LEFT JOIN @TBLXNDETAILS B ON A.memo_id =B.XN_ID AND B.XN_TYPE='APP'
		WHERE   B.XN_ID IS NULL and a.PUMA_HO_SYNCH_LAST_UPDATE is not null
		and @bAutosend=0

		UPDATE A SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE
		FROM apm01106 A (NOLOCK)
		JOIN #TMPAPP TMP ON TMP.memo_id =A.memo_id 
		LEFT JOIN @TBLXNDETAILS B ON A.memo_id =B.XN_ID AND B.XN_TYPE='APP'
		WHERE   B.XN_ID IS NULL
		

		
		SET @cStep=30
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'3.APPROVAL RETURN '

		SELECT A.memo_id,A.LAST_UPDATE
		       INTO #TMPAPR
		FROM APPROVAL_RETURN_MST A (nolock)
		JOIN #TMPLOCATION LOC ON /*LEFT(A.MEMO_ID,2)*//*Rohit 01-11-2024*/A.location_Code =LOC.DEPT_ID
		WHERE  A.MEMO_DT  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		

		CREATE INDEX IX_SISMEMOAPR ON #TMPAPR (memo_id)

		INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT  'APR' AS XN_TYPE,A.memo_id AS XN_ID,'APPROVAL_RETURN_MST' AS TABLENAME,a.LAST_UPDATE ,90 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME 
		FROM #TMPAPR a (NOLOCK)  
		WHERE memo_id IN 
		(
		SELECT b.MEMO_ID FROM   APPROVAL_RETURN_DET B (NOLOCK) 
		JOIN #TMPAPR TMP ON B.memo_id=TMP.memo_id
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.APD_PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		)

		INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT  'APR' AS XN_TYPE,A.memo_id AS XN_ID,'APPROVAL_RETURN_MST' AS TABLENAME,a.LAST_UPDATE ,90 AS  SEND_ORDER ,'MEMO_ID' AS COLUMNNAME 
		FROM APPROVAL_RETURN_MST A (NOLOCK)
		JOIN #TMPAPR TMP ON TMP.memo_id =A.memo_id 
		LEFT JOIN @TBLXNDETAILS B ON A.memo_id =B.XN_ID AND B.XN_TYPE='APR'
		WHERE   B.XN_ID IS NULL and a.PUMA_HO_SYNCH_LAST_UPDATE is not null
		and @bAutosend=0

		UPDATE A SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE
		FROM APPROVAL_RETURN_MST A (NOLOCK)
		JOIN #TMPAPR TMP ON TMP.memo_id =A.memo_id 
		LEFT JOIN @TBLXNDETAILS B ON A.memo_id =B.XN_ID AND B.XN_TYPE='APR'
		WHERE   B.XN_ID IS NULL
		

	
		SET @cStep=40
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1

	   PRINT'4.RETAIL PACK SLIP '
	   --Pack splip merging Discarded as Per sanjiv sir 05092022
		--SELECT A.CM_ID,A.LAST_UPDATE
		--       INTO #TMPRPS
		--FROM RPS_MST A (nolock)
		--JOIN #TMPLOCATION LOC ON LEFT(A.CM_ID,2) =LOC.DEPT_ID
		--WHERE  A.CM_DT  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		

		--CREATE INDEX IX_SISCMIDRPS ON #TMPRPS (CM_ID)

		--INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		--SELECT  'RPS' AS XN_TYPE,A.CM_ID AS XN_ID,'RPS_MST' AS TABLENAME,a.LAST_UPDATE ,110 AS  SEND_ORDER ,'CM_ID' AS COLUMNNAME 
		--FROM #TMPRPS a (NOLOCK)  
		--WHERE A.CM_ID IN(
		--SELECT B.CM_ID FROM  RPS_DET B (NOLOCK) 
		--JOIN #TMPRPS TMP ON B.CM_ID=TMP.CM_ID
		--JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		--JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		--WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		--)

		--INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		--SELECT  'RPS' AS XN_TYPE,A.CM_ID AS XN_ID,'RPS_MST' AS TABLENAME,a.LAST_UPDATE ,110 AS  SEND_ORDER ,'CM_ID' AS COLUMNNAME 
		--FROM RPS_MST A (NOLOCK)
		--JOIN #TMPRPS TMP ON TMP.CM_ID =A.CM_ID 
		--LEFT JOIN @TBLXNDETAILS B ON A.CM_ID =B.XN_ID AND B.XN_TYPE='RPS'
		--WHERE   B.XN_ID IS NULL and a.PUMA_HO_SYNCH_LAST_UPDATE is not null
		--and @bAutosend=0

		--UPDATE A SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE
		--FROM RPS_MST A (NOLOCK)
		--JOIN #TMPRPS TMP ON TMP.CM_ID =A.CM_ID 
		--LEFT JOIN @TBLXNDETAILS B ON A.CM_ID =B.XN_ID AND B.XN_TYPE='RPS'
		--WHERE   B.XN_ID IS NULL
		

		SET @cStep=50
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'5.WHOLESALE PACK SLIP '

		--SELECT A.PS_ID,A.LAST_UPDATE
		--       INTO #TMPWPS
		--FROM WPS_MST A (nolock)
		--JOIN #TMPLOCATION LOC ON LEFT(A.PS_ID,2) =LOC.DEPT_ID
		--WHERE  A.PS_DT  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		

		--CREATE INDEX IX_SISPSIDWPS ON #TMPWPS (PS_ID)

		--INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		--SELECT  'WPS' AS XN_TYPE,A.ps_id AS XN_ID,'WPS_MST' AS TABLENAME,a.LAST_UPDATE ,112 AS  SEND_ORDER ,'PS_ID' AS COLUMNNAME 
		--FROM #TMPWPS a (NOLOCK)  
		--WHERE A.PS_ID IN(
		--SELECT B.PS_ID  FROM   WPS_DET B (NOLOCK) 
		--JOIN #TMPWPS TMP ON B.PS_ID=TMP.PS_ID
		--JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		--JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		--WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		--)

		--INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		--SELECT  'WPS' AS XN_TYPE,A.ps_id AS XN_ID,'WPS_MST' AS TABLENAME,a.LAST_UPDATE ,112 AS  SEND_ORDER ,'PS_ID' AS COLUMNNAME 
		--FROM WPS_MST A (NOLOCK)
		--JOIN #TMPWPS TMP ON TMP.ps_id =A.ps_id 
		--LEFT JOIN @TBLXNDETAILS B ON A.ps_id =B.XN_ID AND B.XN_TYPE='WPS'
		--WHERE   B.XN_ID IS NULL and a.PUMA_HO_SYNCH_LAST_UPDATE is not null
		--and @bAutosend=0

		--UPDATE A SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE
		--FROM WPS_MST A (NOLOCK)
		--JOIN #TMPWPS TMP ON TMP.ps_id =A.ps_id 
		--LEFT JOIN @TBLXNDETAILS B ON A.ps_id =B.XN_ID AND B.XN_TYPE='WPS'
		--WHERE   B.XN_ID IS NULL
		

		SET @cStep=60
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'6.WHOLESALE  '


		SELECT A.INV_ID,A.LAST_UPDATE,  ISNULL(L.SIS_HO_ID,@CHODEPTID) AS SOURCE_DEPT_ID
		       INTO #TMPWSL
		FROM INM01106 A (nolock)
		JOIN #TMPLOCATION LOC ON /*LEFT(A.INV_ID,2)*//*Rohit 01-11-2024*/A.location_Code =LOC.DEPT_ID
		LEFT JOIN SISLOCATIONDETAILS L (NOLOCK) ON A.PARTY_DEPT_ID=L.SIS_LINK_LOCATION  
		WHERE  A.INV_DT  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 

		 
		INSERT INTO #TMPWSL(INV_ID,LAST_UPDATE,SOURCE_DEPT_ID)
		SELECT B.inv_id,b.LAST_UPDATE , ISNULL(L.SIS_HO_ID,@CHODEPTID) AS SOURCE_DEPT_ID
		FROM pim01106 A (nolock)
		join INM01106 b (nolock) on a.inv_id =b.inv_id 
		JOIN #TMPLOCATION LOC ON /*LEFT(A.INV_ID,2)*//*Rohit 01-11-2024*/A.location_Code =LOC.DEPT_ID
		LEFT JOIN SISLOCATIONDETAILS L (NOLOCK) ON B.PARTY_DEPT_ID=L.SIS_LINK_LOCATION  
		where a.cancelled=0 and b.cancelled=0
		and a.receipt_dt>=@DCUTOFFDATE
		and a.inv_dt <@DCUTOFFDATE
	    AND ISNULL(B.PUMA_HO_SYNCH_LAST_UPDATE,'')<>B.LAST_UPDATE 

		


		CREATE INDEX IX_SISINVIDWSL ON #TMPWSL (INV_ID)

		INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT  'WSL' AS XN_TYPE,A.INV_ID AS XN_ID,'INM01106' AS TABLENAME,a.LAST_UPDATE ,115 AS  SEND_ORDER ,'INV_ID' AS COLUMNNAME 
		FROM #TMPWSL a (NOLOCK)  
		WHERE A.INV_ID IN(
		SELECT B.INV_ID  FROM IND01106 B (NOLOCK) 
		JOIN #TMPWSL TMP ON B.INV_ID=TMP.INV_ID
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		)

		INSERT INTO @TBLXNDETAILS(XN_TYPE,XN_ID,TABLENAME,LASTUPDATE,SEND_ORDER,COLUMNNAME)
		SELECT  'WSL' AS XN_TYPE,A.INV_ID AS XN_ID,'INM01106' AS TABLENAME,a.LAST_UPDATE ,115 AS  SEND_ORDER ,'INV_ID' AS COLUMNNAME 
		FROM INM01106 A (NOLOCK)
		JOIN #TMPWSL TMP ON TMP.INV_ID =A.INV_ID 
		LEFT JOIN @TBLXNDETAILS B ON A.INV_ID =B.XN_ID AND B.XN_TYPE='WSL'
		WHERE   B.XN_ID IS NULL and a.PUMA_HO_SYNCH_LAST_UPDATE is not  null
		and @bAutosend=0

		UPDATE A SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE
		FROM INM01106 A (NOLOCK)
		JOIN #TMPWSL TMP ON TMP.INV_ID =A.INV_ID 
		LEFT JOIN @TBLXNDETAILS B ON A.INV_ID =B.XN_ID AND B.XN_TYPE='WSL'
		WHERE   B.XN_ID IS NULL
		




	
		SET @cStep=70
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'7.Retail sale'

		SELECT A.CM_ID,A.LAST_UPDATE
		       INTO #TMPCMM
		FROM CMM01106 A (NOLOCK)
		JOIN #TMPLOCATION LOC ON /*LEFT(A.CM_ID,2)*//*Rohit 01-11-2024*/A.location_Code =LOC.DEPT_ID
		WHERE  A.CM_DT  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		

		CREATE INDEX IX_SISCMIDCMM ON #TMPCMM (CM_ID)
	
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		SELECT 'SLS'AS XN_TYPE,a.CM_ID AS XN_ID,'CMM01106' AS TABLENAME,a.LAST_UPDATE ,120 AS  SEND_ORDER ,
		        'CM_ID' AS COLUMNNAME 
		FROM #TMPCMM A (NOLOCK)
		WHERE A.CM_ID IN
		(
		SELECT B.CM_ID FROM  CMD01106 B (NOLOCK)
		JOIN #TMPCMM TMP ON B.CM_ID =TMP.CM_ID 
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		)
		
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		SELECT 'SLS'AS XN_TYPE,a.CM_ID AS XN_ID,'CMM01106' AS TABLENAME,a.LAST_UPDATE ,120 AS  SEND_ORDER ,
		        'CM_ID' AS COLUMNNAME 
       FROM #TMPCMM A (NOLOCK)
		JOIN cmm01106 B (NOLOCK) ON A.CM_ID =B.CM_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.CM_ID =C.XN_ID AND C.XN_TYPE='SLS'
		WHERE C.XN_ID IS NULL and b.PUMA_HO_SYNCH_LAST_UPDATE is not null
		and @bAutosend=0

		UPDATE B SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE 
		FROM #TMPCMM A (NOLOCK)
		JOIN cmm01106 B (NOLOCK) ON A.CM_ID =B.CM_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.CM_ID =C.XN_ID AND C.XN_TYPE='SLS'
		WHERE C.XN_ID IS NULL
		



		SET @cStep=80
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'8.Debit Note'

		SELECT A.rm_id,A.LAST_UPDATE,ISNULL(L.SIS_HO_ID,@CHODEPTID) AS SOURCE_DEPT_ID
		       INTO #TMPRMM
		FROM rmm01106 A (NOLOCK)
		JOIN #TMPLOCATION LOC ON /*LEFT(A.RM_ID,2)*//*Rohit 01-11-2024*/A.location_Code =LOC.DEPT_ID
		LEFT JOIN SISLOCATIONDETAILS L (NOLOCK) ON A.PARTY_DEPT_ID=L.SIS_LINK_LOCATION  
		WHERE  A.rm_dt  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		AND  A.DN_TYPE=1
		
		

		CREATE INDEX IX_SISRMIDPRT ON #TMPRMM (RM_ID)
	
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME,SOURCE_DEPT_ID  )
		SELECT 'PRT'AS XN_TYPE,a.RM_ID AS XN_ID,'RMM01106' AS TABLENAME,a.LAST_UPDATE ,185 AS  SEND_ORDER ,
		        'RM_ID' AS COLUMNNAME ,SOURCE_DEPT_ID
		FROM #TMPRMM A (NOLOCK)
		WHERE A.RM_ID IN(
		SELECT B.RM_ID FROM  rmd01106 B (NOLOCK)   
		JOIN #TMPRMM TMP ON A.RM_ID =TMP.RM_ID 
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		)
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME,SOURCE_DEPT_ID  )
		SELECT 'PRT'AS XN_TYPE,a.RM_ID AS XN_ID,'RMM01106' AS TABLENAME,a.LAST_UPDATE ,185 AS  SEND_ORDER ,
		        'RM_ID' AS COLUMNNAME ,a.SOURCE_DEPT_ID
		 FROM #TMPRMM A (NOLOCK)
		JOIN rmm01106 B (NOLOCK) ON A.RM_ID =B.RM_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.RM_ID =C.XN_ID AND C.XN_TYPE='PRT'
		WHERE C.XN_ID IS NULL and b.PUMA_HO_SYNCH_LAST_UPDATE is not null
		and @bAutosend=0


		UPDATE B SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE 
		FROM #TMPRMM A (NOLOCK)
		JOIN rmm01106 B (NOLOCK) ON A.RM_ID =B.RM_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.RM_ID =C.XN_ID AND C.XN_TYPE='PRT'
		WHERE C.XN_ID IS NULL
		

		SET @cStep=90
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'9.wsl credit note'

		SELECT A.cn_id,A.LAST_UPDATE,ISNULL(L.SIS_HO_ID,@CHODEPTID) AS SOURCE_DEPT_ID
		       INTO #TMPCNM
		FROM cnm01106 A (NOLOCK)
		JOIN #TMPLOCATION LOC ON LEFT(A.CN_ID,2) =LOC.DEPT_ID
		LEFT JOIN SISLOCATIONDETAILS L (NOLOCK) ON /*LEFT(A.cn_id,2)*//*Rohit 01-11-2024*/A.location_Code=L.SIS_LINK_LOCATION --AND L.PAN_NO=@CPANNO 
		WHERE  A.cn_dt  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		

		CREATE INDEX IX_SISCNIDWSR ON #TMPCNM (CN_ID)
	
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME,SOURCE_DEPT_ID  )
		SELECT 'WSR'AS XN_TYPE,a.CN_ID AS XN_ID,'CNM01106' AS TABLENAME,a.LAST_UPDATE ,190 AS  SEND_ORDER ,
		        'CN_ID' AS COLUMNNAME ,A.SOURCE_DEPT_ID
		FROM #TMPCNM A (NOLOCK)
		WHERE A.CN_ID IN(
		SELECT B.CN_ID FROM  CND01106 B (NOLOCK)  
		JOIN #TMPCNM TMP ON A.CN_ID =TMP.CN_ID 
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		)

		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME,SOURCE_DEPT_ID  )
		SELECT 'WSR'AS XN_TYPE,a.CN_ID AS XN_ID,'CNM01106' AS TABLENAME,a.LAST_UPDATE ,190 AS  SEND_ORDER ,
		        'CN_ID' AS COLUMNNAME ,A.SOURCE_DEPT_ID
		FROM #TMPCNM A (NOLOCK)
		JOIN CNM01106 B (NOLOCK) ON A.CN_ID =B.CN_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.CN_ID =C.XN_ID AND C.XN_TYPE='WSR'
		WHERE C.XN_ID IS NULL and b.PUMA_HO_SYNCH_LAST_UPDATE is not null
		and @bAutosend=0

		UPDATE B SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE 
		FROM #TMPCNM A (NOLOCK)
		JOIN CNM01106 B (NOLOCK) ON A.CN_ID =B.CN_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.CN_ID =C.XN_ID AND C.XN_TYPE='WSR'
		WHERE C.XN_ID IS NULL
		
        

		--PRINT'9.FLOOR TRANSFER'

		--SELECT A.MEMO_ID,A.LAST_UPDATE
		--       INTO #TMPBCO
		--FROM FLOOR_ST_MST A (NOLOCK)
		--WHERE  A.MEMO_DT  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 

		--CREATE INDEX IX_SISMEMOIDBCO ON #TMPBCO (MEMO_ID)
	
		--INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		--SELECT 'BCO'AS XN_TYPE,a.MEMO_ID AS XN_ID,'FLOOR_ST_MST' AS TABLENAME,a.LAST_UPDATE ,195 AS  SEND_ORDER ,
		--        'MEMO_ID' AS COLUMNNAME 
		--FROM #TMPBCO A (NOLOCK)
		--JOIN FLOOR_ST_DET B (NOLOCK)  ON A.MEMO_ID =B.MEMO_ID 
		--JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		--JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		--WHERE SUBSTRING(LMP.AC_GST_NO,3,10)=@CPANNO
		--GROUP BY A.MEMO_ID,a.LAST_UPDATE
		
		--UPDATE B SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE 
		--FROM #TMPBCO A (NOLOCK)
		--JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID 
		--LEFT JOIN @TBLXNDETAILS C ON A.MEMO_ID =C.XN_ID AND C.XN_TYPE='BCO'
		--WHERE C.XN_ID IS NULL

		SET @cStep=100
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'10.job work issue'

		SELECT A.ISSUE_ID,A.LAST_UPDATE
		       INTO #TMPJWI
		FROM JOBWORK_ISSUE_MST A (NOLOCK)
		JOIN #TMPLOCATION LOC ON /*LEFT(A.ISSUE_ID,2)*//*Rohit 01-11-2024*/A.location_Code =LOC.DEPT_ID
		WHERE  A.ISSUE_DT  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		

		CREATE INDEX IX_SISISSUEIDJWI ON #TMPJWI (issue_id)
	
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		SELECT 'JWI'AS XN_TYPE,a.ISSUE_ID AS XN_ID,'JOBWORK_ISSUE_MST' AS TABLENAME,a.LAST_UPDATE ,200 AS  SEND_ORDER ,
		        'ISSUE_ID' AS COLUMNNAME 
		FROM #TMPJWI A (NOLOCK)
		WHERE A.issue_id IN
		(
		SELECT B.ISSUE_ID FROM JOBWORK_ISSUE_DET B (NOLOCK) 
		JOIN #TMPJWI TMP ON B.ISSUE_ID =TMP.ISSUE_ID 
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		)
		
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		SELECT 'JWI'AS XN_TYPE,a.ISSUE_ID AS XN_ID,'JOBWORK_ISSUE_MST' AS TABLENAME,a.LAST_UPDATE ,200 AS  SEND_ORDER ,
		        'ISSUE_ID' AS COLUMNNAME 
        FROM #TMPJWI A (NOLOCK)
		JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID =B.ISSUE_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.ISSUE_ID =C.XN_ID AND C.XN_TYPE='JWI'
		WHERE C.XN_ID IS NULL and b.PUMA_HO_SYNCH_LAST_UPDATE is not null
		and @bAutosend=0


		UPDATE B SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE 
		FROM #TMPJWI A (NOLOCK)
		JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID =B.ISSUE_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.ISSUE_ID =C.XN_ID AND C.XN_TYPE='JWI'
		WHERE C.XN_ID IS NULL
		

		SET @cStep=110
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'11.JOB WORK RECEIVE'

		SELECT A.RECEIPT_ID ,A.LAST_UPDATE
		       INTO #TMPJWR
		FROM JOBWORK_RECEIPT_MST  A (NOLOCK)
		JOIN #TMPLOCATION LOC ON /*LEFT(A.RECEIPT_ID,2)*//*Rohit 01-11-2024*/A.location_Code =LOC.DEPT_ID
		WHERE  A.RECEIPT_DT  >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		

		CREATE INDEX IX_SISRECIDJWR ON #TMPJWR (receipt_id)
	
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		SELECT 'JWR'AS XN_TYPE,a.RECEIPT_ID AS XN_ID,'JOBWORK_RECEIPT_MST' AS TABLENAME,a.LAST_UPDATE ,210 AS  SEND_ORDER ,
		        'RECEIPT_ID' AS COLUMNNAME 
		FROM #TMPJWR A (NOLOCK)
		WHERE A.receipt_id IN
		(
		SELECT B.RECEIPT_ID FROM jobwork_RECEIPT_DET B (NOLOCK) 
		JOIN #TMPJWR TMP ON B.receipt_id =TMP.receipt_id 

		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		)

		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		SELECT 'JWR'AS XN_TYPE,a.RECEIPT_ID AS XN_ID,'JOBWORK_RECEIPT_MST' AS TABLENAME,a.LAST_UPDATE ,210 AS  SEND_ORDER ,
		        'RECEIPT_ID' AS COLUMNNAME 
        FROM #TMPJWR A (NOLOCK)
		JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID =B.RECEIPT_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.RECEIPT_ID =C.XN_ID AND C.XN_TYPE='JWR'
		WHERE C.XN_ID IS NULL and b.PUMA_HO_SYNCH_LAST_UPDATE is not null
		and @bAutosend=0

		UPDATE B SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE 
		FROM #TMPJWR A (NOLOCK)
		JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID =B.RECEIPT_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.RECEIPT_ID =C.XN_ID AND C.XN_TYPE='JWR'
		WHERE C.XN_ID IS NULL
		

		SET @cStep=120
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'12.STOCK ADJUSTMENT'

		SELECT A.cnc_memo_id ,A.LAST_UPDATE
		       INTO #TMPCNC
		FROM icm01106  A (NOLOCK)
		JOIN #TMPLOCATION LOC ON /*LEFT(A.cnc_memo_id,2)*//*Rohit 01-11-2024*/A.location_Code =LOC.DEPT_ID
		WHERE  A.cnc_memo_dt   >=@DCUTOFFDATE AND ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,'')<>A.LAST_UPDATE 
		

		CREATE INDEX IX_SISMEMEOCNC ON #TMPCNC (cnc_memo_id)
	
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		SELECT 'CNC'AS XN_TYPE,a.cnc_memo_id AS XN_ID,'ICM01106' AS TABLENAME,a.LAST_UPDATE ,240 AS  SEND_ORDER ,
		        'cnc_memo_ID' AS COLUMNNAME 
		FROM #TMPCNC A (NOLOCK)
		WHERE A.cnc_memo_id IN(
		SELECT B.CNC_MEMO_ID FROM icD01106 B (NOLOCK)  
		JOIN #TMPCNC TMP ON B.cnc_memo_id =B.cnc_memo_id 
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		)

		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		SELECT 'CNC'AS XN_TYPE,a.cnc_memo_id AS XN_ID,'ICM01106' AS TABLENAME,a.LAST_UPDATE ,240 AS  SEND_ORDER ,
		        'cnc_memo_ID' AS COLUMNNAME 
		FROM #TMPCNC A (NOLOCK)
		JOIN icm01106 B (NOLOCK) ON A.cnc_memo_id =B.cnc_memo_id 
		LEFT JOIN @TBLXNDETAILS C ON A.cnc_memo_id =C.XN_ID AND C.XN_TYPE='CNC'
		WHERE C.XN_ID IS NULL and b.PUMA_HO_SYNCH_LAST_UPDATE is not null
		and @bAutosend=0

		UPDATE B SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE 
		FROM #TMPCNC A (NOLOCK)
		JOIN icm01106 B (NOLOCK) ON A.cnc_memo_id =B.cnc_memo_id 
		LEFT JOIN @TBLXNDETAILS C ON A.cnc_memo_id =C.XN_ID AND C.XN_TYPE='CNC'
		WHERE C.XN_ID IS NULL
		

		SET @cStep=130
        EXEC SP_CHKXNSAVELOG 'SISMERGE',@cStep,1,0,'',1
		PRINT'13.GRN PS'

		SELECT A.MEMO_ID ,A.LAST_UPDATE
		       INTO #TMPGRNPS
		FROM GRN_PS_MST  A (NOLOCK)
		JOIN #TMPLOCATION LOC ON /*LEFT(A.MEMO_ID,2)*//*Rohit 01-11-2024*/A.location_Code =LOC.DEPT_ID
		WHERE  A.memo_dt   >=@DCUTOFFDATE AND ISNULL(ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,''),'')<>A.LAST_UPDATE 
		

		CREATE INDEX IX_SISMEMEOGRNPS ON #TMPGRNPS (MEMO_ID)
	
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		SELECT 'GRNPS'AS XN_TYPE,a.MEMO_ID AS XN_ID,'GRN_PS_MST' AS TABLENAME,a.LAST_UPDATE ,640 AS  SEND_ORDER ,
		        'MEMO_ID' AS COLUMNNAME 
		FROM #TMPGRNPS A (NOLOCK)
		WHERE A.MEMO_ID IN(
		SELECT B.MEMO_ID FROM  GRN_PS_DET B (NOLOCK) 
		JOIN #TMPGRNPS TMP ON B.MEMO_ID =B.MEMO_ID 
		JOIN SKU C (NOLOCK) ON C.PRODUCT_CODE=B.PRODUCT_CODE
		JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =C.AC_CODE
		WHERE SUBSTRING(LMP.AC_GST_NO,3,10) IN(SELECT PAN_NO FROM #TMPPAN_NO)
		)
		
		INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )
		SELECT 'GRNPS'AS XN_TYPE,a.MEMO_ID AS XN_ID,'GRN_PS_MST' AS TABLENAME,a.LAST_UPDATE ,640 AS  SEND_ORDER ,
		        'MEMO_ID' AS COLUMNNAME 
		FROM #TMPGRNPS A (NOLOCK)
		JOIN GRN_PS_MST B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.MEMO_ID =C.XN_ID AND C.XN_TYPE='GRNPS'
		WHERE C.XN_ID IS NULL and b.PUMA_HO_SYNCH_LAST_UPDATE is not null
		and @bAutosend=0

		UPDATE B SET PUMA_HO_SYNCH_LAST_UPDATE=A.LAST_UPDATE 
		FROM #TMPGRNPS A (NOLOCK)
		JOIN GRN_PS_MST B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID 
		LEFT JOIN @TBLXNDETAILS C ON A.MEMO_ID =C.XN_ID AND C.XN_TYPE='GRNPS'
		WHERE C.XN_ID IS NULL
		
		IF not  EXISTS (SELECT TOP 1 'U' FROM SIS_CLOSING_STOCK where CLOSING_DT=CONVERT(VARCHAR(10),GETDATE()-1,121))  
		 begin    
        
			EXEC SPSIS_SEND_MIRROR_CLS_DATA @CPANNO,'','',1,''
	 
		END

	  INSERT INTO @TBLXNDETAILS(XN_TYPE ,XN_ID ,TABLENAME ,LASTUPDATE ,SEND_ORDER  ,COLUMNNAME  )  
	   SELECT DISTINCT  'CLS'AS XN_TYPE,CONVERT(VARCHAR(10),GETDATE()-1,121) AS XN_ID,'SIS_CLOSING_STOCK' AS TABLENAME,A.LAST_UPDATE ,650 AS  SEND_ORDER ,  
			  'CLOSING_DT' AS COLUMNNAME   
	   FROM SIS_CLOSING_STOCK A WHERE ISNULL(ISNULL(A.PUMA_HO_SYNCH_LAST_UPDATE,''),'')<>A.LAST_UPDATE   
 
 
		
		
		LBLMEMOLIST:

		SELECT A.XN_TYPE,XN_ID,TABLENAME,convert(varchar,LASTUPDATE,121) as lastupdate,SEND_ORDER,COLUMNNAME ,
		       @CSIS_HO_ID AS SIS_HO_ID,ISNULL(A.SOURCE_DEPT_ID,'') AS SOURCE_DEPT_ID
		FROM @TBLXNDETAILS A
		WHERE DATEDIFF (SS,LASTUPDATE,GETDATE())>15
		ORDER BY SEND_ORDER,a.xn_id


END  
