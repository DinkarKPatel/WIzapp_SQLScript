	
--SP_WSLINVSUPP_FILTER 0,0,'2013-01-01','2015-09-22',0,0,0,0,'','','','',2,'',''

CREATE PROC SP_WSLINVSUPP_FILTER
(
@NINV_MODE NUMERIC(1),           /* @NINV_MODE:0 FOR ALL,1 FOR GROUP,2 FOR PARTY*/
@NINV_STATUS NUMERIC(1),         /* @NINV_STATUS:0 FOR ALL,1 FOR BOX,2 FOR PICK SLIP,3 FOR PICK LIST,4 FOR AGAINST ORDER */  
@DFROMDATE DATETIME,			 /* @DFROMDATE:2013-04-20 FOR FILTER FROM MEMO DATE */
@DTODATE DATETIME,				 /* @DTODATE:2014-08-05 FOR FILTER TO MEMO DATE */

@INV_TYPE NUMERIC(1),            --@INV_TYPE:0 FOR ALL, 1 FOR REGULARAND 2 FOR LOT 
@INV_METHOD NUMERIC(1),          --@INV_METHOD:0 FOR ALL , 1 FOR OUTSTANDING AND 2 FOR LOCAL
@TAX_METHOD NUMERIC(1),          --@TAX_METHOD:0 FOR ALL , 1 FOR EXCLUSIVE AND 2 FOR INCLUSIVE  
@TAX_TYPE NUMERIC(1),            --@TAX_TYPE:0 FOR ALL , 1 FOR BLII LEVEL AND 2 FOR ITEM LEVEL 

@CAC_CODE VARCHAR(100),			 /* @CAC_CODE:WHOLESALE FROM AC_CODE */
@CFORM_ID VARCHAR(10)='',         /*ENTER FORM OR BLANK*/
@CDEPT_ID VARCHAR(100),		     /* @CDEPT_ID:WHOLESALE FROM DEPT_ID */
@CAC_BRK_ID VARCHAR(100),		 /* @AC_BRK_ID:WHOLESALE FROM DEPT_ID */
@NCANCELLED NUMERIC(1),           /* @NCANCELLED:0 OR 1 CHECK CANCLE STATUS */
@CCHALLAN_ID VARCHAR(100),         /* @CCHALLAN_ID:'' NO FILTER ELSE FILTER FOR CHALLAN_ID*/
@CSALESPERSON VARCHAR(10),
@CSDEPT_ID VARCHAR(100)=''	     /* @CDEPT_ID:WHOLESALE FROM DEPT_ID */
) 
--WITH ENCRYPTION
AS
BEGIN

	IF OBJECT_ID('TEMPDB..#FILTER_INM','U') IS NOT NULL
		DROP TABLE #FILTER_INM
	
	SELECT DISTINCT INM.INV_ID
	INTO #FILTER_INM
	FROM INMSUPP INM(NOLOCK)
	WHERE (ISNULL(@CFORM_ID,'')='' ) 	
	AND INM.INV_DT BETWEEN  @DFROMDATE AND @DTODATE   
	--FOR GATE PASS ISSUE NO
	
	 IF OBJECT_ID('#TEMPDB..#TMPGPMEMO','U') IS NOT NULL
		DROP TABLE #TMPGPMEMO
	 
	 ;WITH CTE AS
	 (
	 SELECT B.INV_ID,A.MEMO_NO AS GP_ISSUE_NO ,A.MEMO_ID AS GP_ISSUE_ID,A.MEMO_DT ,
			ROW_NUMBER() OVER (PARTITION BY B.INV_ID ORDER BY A.LAST_UPDATE DESC) AS SR
	 FROM TBL_GP_ISSUE_MST A
	 JOIN TBL_GP_ISSUE_DET B ON A.MEMO_ID=B.MEMO_ID
	 JOIN INMSUPP INM ON INM.INV_ID=B.INV_ID 
	 WHERE A.CANCELLED =0 AND INM.INV_DT BETWEEN @DFROMDATE AND @DTODATE
	 )
	 SELECT * INTO #TMPGPMEMO FROM CTE WHERE SR=1
	--
	
	--IF OBJECT_ID('TEMPDB..#FILTER_INM1','U') IS NOT NULL
	--	DROP TABLE #FILTER_INM1
	
	--SELECT INV_ID,EMP_CODE INTO #FILTER_INM1 FROM #FILTER_INM
	--WHERE EMP_CODE = CASE WHEN @CSALESPERSON='' THEN EMP_CODE ELSE @CSALESPERSON END
	
	--;WITH CTE AS
	--(
	--	SELECT INV_ID,EMP_CODE,ROW_NUMBER() OVER(PARTITION BY INV_ID ORDER BY EMP_CODE) AS SLNO FROM #FILTER_INM1
	--)
	--DELETE FROM CTE WHERE SLNO > 1
	

	SELECT CONVERT(VARCHAR,T1.INV_DT,105) AS MEMO_DT,T1.INV_ID AS MEMO_ID,T1.INV_NO AS MEMO_NO, 
	T3.AC_NAME AS CUSTOMER_NAME,T1.DISCOUNT_PERCENTAGE AS DISCOUNT_PERCENTAGE ,				
	(CASE WHEN T1.CANCELLED = 0 THEN T1.DISCOUNT_AMOUNT ELSE 0 END) AS DISCOUNT_AMOUNT ,
	(CASE WHEN T1.CANCELLED = 0 THEN T1.FREIGHT ELSE 0 END) AS FREIGHT,
	(CASE WHEN T1.CANCELLED = 0 THEN T1.INSURANCE ELSE 0 END) AS INSURANCE,
	(CASE WHEN T1.CANCELLED = 0 THEN T1.OTHER_CHARGES ELSE 0 END) AS OTHER_CHARGES,
	(CASE WHEN T1.CANCELLED = 0 THEN T1.NET_AMOUNT ELSE 0 END) AS NET_SALE_VALUE,
	T1.REMARKS,
	(CASE WHEN T1.CANCELLED = 0 THEN T1.OCTROI_AMOUNT ELSE 0 END) AS OCTROI_AMOUNT,
	T1.MANUAL_INV_NO,
	(CASE WHEN T1.CANCELLED = 1 THEN 0 ELSE ISNULL(T1.TOTAL_QUANTITY,0) END) AS TOTAL_QUANTITY,
	(CASE WHEN T1.CANCELLED = 1 THEN 'CANCELLED' ELSE '' END) AS CANCELLED,
    (CASE WHEN T1.CANCELLED = 1 THEN 0 ELSE ISNULL(T1.SUBTOTAL,0)  END)  AS SUBTOTAL,
     (CASE WHEN T1.CANCELLED = 1 THEN 0 ELSE ISNULL(T1.ROUND_OFF,0)   END)AS ROUND_OFF,
	PARCEL_TRANSPORTER_NAME=ISNULL(PARCEL_TRANSPORTER_NAME,''),
	PARCEL_MEMO_NO=ISNULL(PARCEL_MEMO_NO,''),
	PARCEL_MEMO_DT=ISNULL(CONVERT(VARCHAR,PARCEL_MEMO_DT,105),''),
	BILTY_NO=ISNULL(BILTY_NO,''),
	PARCEL_AC_NAME=ISNULL(PARCEL_AC_NAME,''),
	CASE WHEN T1.EXPORTED =0 THEN 'NO' 
	     WHEN T1.EXPORTED =1 THEN 'YES'  ELSE '' END AS EXPORTED,
	--20 MAR 2018
	--CASE WHEN PUR.RECEIPT_DT IS NOT NULL THEN CONVERT(VARCHAR,PUR.RECEIPT_DT,105) ELSE '' END AS RECEIPT_DT,
	''AS RECEIPT_DT,
	--20 MAR 2018
	--CASE WHEN ISNULL(PUR.MEMO_TIME,'1900-01-01')='1900-01-01'  THEN '' ELSE CONVERT(VARCHAR,PUR.MEMO_TIME,120)  END AS MEMO_TIME
	T3.TIN_NO,
	LOC.DEPT_NAME,LOC.DEPT_ID,(CASE WHEN ISNULL(DF.MEMONO,'')='' THEN 'NO' ELSE 'YES' END) AS DOC_ATTACHED,
	ISNULL(GP.GP_ISSUE_NO,'') AS GP_ISSUE_NO,
	ISNULL(GP.GP_ISSUE_ID,'') AS GP_ISSUE_ID,
	ISNULL((LOC.DEPT_ID +'-'+ LOC.DEPT_NAME ),'')AS SOURCE_LOCATION
	,ISNULL((DLOC.DEPT_ID +'-'+ DLOC.DEPT_NAME),'') AS TARGET_LOCATION
	,(CASE WHEN ISNULL(T1.EDIT_COUNT,0)>0 THEN 'EDITED (' + RTRIM(LTRIM(STR(T1.EDIT_COUNT)))+ ')' ELSE '' END ) AS EDIT_COUNT
	--18 NOV 2017
	
	FROM INMSUPP T1 (NOLOCK)
	JOIN #FILTER_INM FT1 (NOLOCK) ON T1.INV_ID=FT1.INV_ID
	JOIN LMV01106 T3 ON T3.AC_CODE = T1.AC_CODE 
	LEFT OUTER JOIN LM01106 T4 ON T4.AC_CODE = T1.BROKER_AC_CODE 
	LEFT OUTER JOIN EMPLOYEE T5 ON T5.EMP_CODE = T1.EMP_CODE 
	LEFT OUTER JOIN LOCATION T6 ON T6.DEPT_ID = T1.PARTY_DEPT_ID  
	--LEFT OUTER JOIN
	--(  
	--  SELECT COUNT(DISTINCT BOX_NO) AS NO_OF_BOXES,INV_ID 
	--  FROM IND01106 (NOLOCK)
	--  GROUP BY INV_ID 
	--) T10 ON T10.INV_ID=T1.INV_ID  
	LEFT JOIN
	(
	  SELECT PM.PARCEL_MEMO_NO,PM.PARCEL_MEMO_DT,LM.AC_NAME AS PARCEL_AC_NAME,ANGM.ANGADIA_NAME AS PARCEL_TRANSPORTER_NAME,PM.BILTY_NO,
	        PB.REF_MEMO_ID
            FROM PARCEL_MST PM (NOLOCK)
            JOIN parcel_det  PB (NOLOCK) ON PM.PARCEL_MEMO_ID =PB.PARCEL_MEMO_ID 
            JOIN ANGM (NOLOCK) ON ANGM.ANGADIA_CODE =PM.ANGADIA_CODE
            JOIN LM01106 LM (NOLOCK)  ON LM.AC_CODE=PM.AC_CODE
            WHERE PM.CANCELLED =0
            GROUP BY PM.PARCEL_MEMO_NO,PM.PARCEL_MEMO_DT,
            PB.REF_MEMO_ID,LM.AC_NAME,BILTY_NO,ANGM.ANGADIA_NAME 
	) ANGM ON ANGM.REF_MEMO_ID=T1.INV_ID
	LEFT OUTER JOIN COMPANY COM ON 1=1 AND COM.COMPANY_CODE='01' 
	LEFT OUTER JOIN LOCATION  L (NOLOCK) ON L.DEPT_ID=CASE WHEN T1.INV_MODE=1 THEN T1.DEPT_ID ELSE T1.PARTY_DEPT_ID END
	--LEFT OUTER JOIN FORM F ON T2.ITEM_FORM_ID = F.FORM_ID
	--20 MAR 2018
	--LEFT JOIN PIM01106 PUR (NOLOCK) ON PUR.INV_ID=T1.INV_ID 
	--20 MAR 2018
	LEFT OUTER JOIN LOCATION LOC ON LEFT(T1.INV_ID,2)= LOC.DEPT_ID
	LEFT OUTER JOIN LOCATION DLOC ON T1.PARTY_DEPT_ID= DLOC.DEPT_ID
	LEFT OUTER JOIN DAILOGFILE DF ON T1.INV_ID= DF.MEMONO AND DF.MODULENAME = 'FRMWSLINVOICE'
	LEFT OUTER JOIN #TMPGPMEMO GP ON GP.INV_ID=T1.INV_ID
	WHERE 
	    (ISNULL(@NINV_MODE, 0)= 0 OR (T1.INV_MODE=@NINV_MODE))	
	AND	(ISNULL(@NINV_STATUS, 0)= 0 OR (ENTRY_MODE=@NINV_STATUS))	  
	AND T1.INV_DT BETWEEN @DFROMDATE AND @DTODATE
	AND (@INV_TYPE=0 OR T1.LOTTYPE=@INV_TYPE)
	AND (@INV_METHOD=0 OR T1.INV_TYPE=@INV_METHOD)	
	AND (@TAX_METHOD=0 OR T1.BILL_LEVEL_TAX_METHOD=@TAX_METHOD)
	AND (@TAX_TYPE=0 OR T1.TAXFORM_STORAGE_MODE=@TAX_TYPE)	
	AND (ISNULL(@CAC_CODE,'')='' OR T3.AC_CODE=@CAC_CODE)
	AND (ISNULL(@CSDEPT_ID,'')='' OR LEFT(T1.INV_ID,2)=@CSDEPT_ID)
	AND (ISNULL(@CDEPT_ID,'')='' OR T1.PARTY_DEPT_ID=@CDEPT_ID)
	AND (ISNULL(@CAC_BRK_ID,'')='' OR T1.BROKER_AC_CODE=@CAC_BRK_ID)	
	--AND (@NCANCELLED=2 OR T1.CANCELLED=@NCANCELLED)	
	AND T1.CANCELLED= CASE WHEN @NCANCELLED=2 THEN T1.CANCELLED 
						   WHEN @NCANCELLED=0 THEN 0
						   WHEN @NCANCELLED=1 THEN 1 		
			          END 
    ORDER BY T1.INV_DT
	--AND (ISNULL(@CCHALLAN_ID,'')='' OR IND.W8_CHALLAN_ID=@CCHALLAN_ID)
END
--END OF PROCEDURE - SP_WSLINVSUPP_FILTER
