CREATE PROCEDURE SPPPC_FG_ISSUE_BAROCDE_NEW  
(  
 @NQUERYID INT=0,  
 @CBILL_NO VARCHAR(50)='',  
 @CJOB_CODE CHAR(7) ='',  
 @CAGENCY_CODE VARCHAR(10)='',  
 @CPARA1_CODE VARCHAR(100)='',  
 @CSIZEGROUP_CODE VARCHAR(100)='',  
 @CMEMO_ID VARCHAR(50)='',
 @CPRODUCT_CODE VARCHAR(100)='' ,
 @NRETURN INT=0,
 @CAC_CODE VARCHAR(10)='',
 @CFIN_YEAR VARCHAR(5)='',
 @CORDER_ID VARCHAR(100)=''
  
)  
AS  
BEGIN  
   
 IF @NQUERYID=1  
    GOTO LBLAGENCY 
 ELSE IF @NQUERYID=2  
    GOTO LBLBILL_NO  
 ELSE IF @NQUERYID=3  
    GOTO LBLJOBS         
 ELSE IF @NQUERYID=4  
    GOTO LBLMST  
 ELSE IF @NQUERYID=5  
    GOTO LBLDET  
 ELSE IF @NQUERYID=6  
    GOTO LBLAGENCY_VIEW         
 ELSE IF @NQUERYID=7  
    GOTO LBLBILL_NO_VIEW  
 ELSE IF @NQUERYID=8  
    GOTO LBLMEMO_VIEW  
 ELSE IF @NQUERYID=9  
    GOTO LBLBUYER  
 ELSE IF @NQUERYID=10    
  GOTO LBLBARCODEPRINT_CROSSTAB   
  ELSE IF @NQUERYID=11    
  GOTO LBLBERCODEDET   
 ELSE  
 GOTO END_PROC  
   
   
     LBLBERCODEDET:
           
            IF OBJECT_ID ('TEMPDB..#TMPBARCODE','U') IS NOT NULL
				 DROP TABLE #TMPBARCODE
	          
				 SELECT CAST(1 AS BIT) AS CHK,
					   PR.MEMO_ID,
					   ROW_ID=PR.ROW_ID,
					   ART_ROW_ID=ART.ARTICLE_NO+SG.SIZEGROUP_NAME+P1.PARA1_NAME,
					   A.AC_CODE,LM.AC_NAME ,
					   DET.BILL_NO,
					   DET.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,
					   B.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,
					   B.PARA1_CODE,P1.PARA1_NAME AS COLOR,
					   B.PARA3_CODE,P3.PARA3_NAME BUYER_STYLE_NO,
					   SKU.PARA2_CODE,P2.PARA2_NAME SIZE,
					   PR.JOB_CODE,
					   PR.JOB_NAME,
					   PR.PRODUCT_CODE,
					   PMT.QUANTITY_IN_STOCK AS QUANTITY,
					   DET.ROW_ID AS BO_ROW_ID,
					   REPLACE(CONVERT(VARCHAR(11),DET.DELIVERY_DT,106),' ','-')  AS DELIVERY_DT
					INTO #TMPBARCODE
					FROM PPC_FGBCG_MST A
					JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID 
					JOIN
					(
					  SELECT A.ORDER_ID ,  B.AC_CODE,A.ARTICLE_CODE ,
						ROW_ID,B.BILL_NO,A.DELIVERY_DT  
						FROM PPC_BUYER_ORDER_DET A
						JOIN PPC_BUYER_ORDER_MST B ON A.ORDER_ID=B.ORDER_ID
						WHERE B.CANCELLED=0
					  GROUP BY A.ORDER_ID ,B.AC_CODE,A.ARTICLE_CODE ,ROW_ID,B.BILL_NO,A.DELIVERY_DT 
					) DET ON DET.ROW_ID=B.BO_DET_ROW_ID 
					JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID
					JOIN PPC_FG_PMT PMT ON SKU.PRODUCT_CODE =PMT.PRODUCT_CODE  
					JOIN ARTICLE ART ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE 
					JOIN PARA1 P1 ON P1.PARA1_CODE =SKU.PARA1_CODE 
					JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE 
					JOIN PARA3 P3 ON P3.PARA3_CODE =SKU.PARA3_CODE 
					JOIN PPC_SIZEGROUP SG ON SG.SIZEGROUP_CODE =SKU.SIZEGROUP_CODE 
					JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE 
					JOIN
					(
						SELECT JOBS.JOB_CODE,JOBS.JOB_NAME,A.ROW_ID,
						B.MEMO_ID,B.MEMO_NO,B.MEMO_DT, PRODUCT_CODE,QUANTITY AS QUANTITY
						FROM PPC_AGENCY_ISSUE_FG_DET  A
						JOIN PPC_AGENCY_ISSUE_FG_MST B ON A.MEMO_ID =B.MEMO_ID 
						JOIN JOBS  ON B.JOB_CODE=JOBS.JOB_CODE
						WHERE B.CANCELLED=0 
						AND  A.MEMO_ID =@CMEMO_ID
					) PR ON PR.PRODUCT_CODE =PMT.PRODUCT_CODE	
					
					
           SELECT A.CHK,
				 A.MEMO_ID,
				 A.ROW_ID,
				 ART_ROW_ID,
				 A.AC_CODE,A.AC_NAME ,
				 A.BILL_NO,
				 A.ARTICLE_CODE,A.ARTICLE_NO,A.ARTICLE_NAME,
				 A.SIZEGROUP_CODE,A.SIZEGROUP_NAME ,
				 A.PARA1_CODE,A.COLOR,
				 A.PARA3_CODE,A.BUYER_STYLE_NO,
				 A.PARA2_CODE,A.SIZE,
				 A.JOB_CODE,
				 A.JOB_NAME,
				 A.PRODUCT_CODE,
				 A.QUANTITY,
				 CAST(0 AS NUMERIC(10,0)) AS PHY_QTY,
				 CAST(1 AS NUMERIC(10,0)) AS SCAN_QTY,
				 CAST(0 AS NUMERIC(10,0)) AS BAL_QTY,
				 1 AS QUANTITY_IN_STOCK,
				 BO_ROW_ID,
				 A.DELIVERY_DT
			   FROM #TMPBARCODE A
					
     
     GOTO END_PROC  
     
       LBLBUYER:
        
        SELECT A.AC_CODE,B.AC_NAME 
        FROM PPC_BUYER_ORDER_MST  A
        JOIN LM01106 B ON A.AC_CODE=B.AC_CODE
        WHERE CANCELLED =0
        GROUP BY A.AC_CODE,B.AC_NAME
        
      GOTO END_PROC 
      
     LBLAGENCY:  
         
         
       
        SELECT AM.AC_CODE ,AM.AGENCY_NAME AS AC_NAME
        FROM PPC_BO_ART_JOBS A
        JOIN JOBS B ON A.JOB_CODE =B.JOB_CODE 
        JOIN
        (
         SELECT A.JOB_CODE ,BO_DET_ROW_ID
         FROM PPC_AGENCY_REC_FG_MST A
         JOIN PPC_AGENCY_REC_FG_DET B ON A.MEMO_ID =B.MEMO_ID 
         JOIN PPC_FG_SKU C ON C.PRODUCT_CODE =B.PRODUCT_CODE 
         JOIN PPC_FGBCG_DET DET ON DET.ROW_ID =C.PPC_FGBCG_DET_ROW_ID 
         JOIN PPC_FGBCG_MST MST ON MST.MEMO_ID =DET.MEMO_ID 
         WHERE A.CANCELLED =0 AND MST.CANCELLED =0
         GROUP BY A.JOB_CODE ,BO_DET_ROW_ID
        ) C ON A.REF_ROW_ID  =C.BO_DET_ROW_ID
        JOIN AGENCY_JOBS AJ ON AJ.JOB_CODE =B.JOB_CODE 
        JOIN PRD_AGENCY_MST AM ON AM.AGENCY_CODE =AJ.AGENCY_CODE 
        GROUP BY AM.AC_CODE ,AM.AGENCY_NAME
        ORDER BY AM.AC_CODE ,AM.AGENCY_NAME
    
    GOTO END_PROC 
      
    LBLBILL_NO:  
         
       SELECT BILL_NO AS ORDER_NO   
       FROM PPC_BUYER_ORDER_MST A  
       WHERE CANCELLED=0  
       AND (@CAC_CODE='' OR A.AC_CODE=@CAC_CODE)
       GROUP BY BILL_NO  
         
    GOTO END_PROC  
      
    LBLJOBS: --FOR FIRST TIME  
      
        SELECT A.JOB_CODE ,A.JOB_ORDER ,CAST(B.JOB_NAME + '_ORDER_'+ CAST(A.JOB_ORDER AS VARCHAR(10)) AS VARCHAR(100)) AS JOB_NAME,
               B.JOB_NAME AS ORG_JOB_NAME 
        FROM PPC_BO_ART_JOBS A
        JOIN JOBS B ON A.JOB_CODE =B.JOB_CODE 
        JOIN
        (
         SELECT A.JOB_CODE ,BO_DET_ROW_ID
         FROM PPC_AGENCY_REC_FG_MST A
         JOIN PPC_AGENCY_REC_FG_DET B ON A.MEMO_ID =B.MEMO_ID 
         JOIN PPC_FG_SKU C ON C.PRODUCT_CODE =B.PRODUCT_CODE 
         JOIN PPC_FGBCG_DET DET ON DET.ROW_ID =C.PPC_FGBCG_DET_ROW_ID 
         JOIN PPC_FGBCG_MST MST ON MST.MEMO_ID =DET.MEMO_ID 
         WHERE A.CANCELLED =0 AND MST.CANCELLED =0
         GROUP BY A.JOB_CODE ,BO_DET_ROW_ID
        ) C ON A.REF_ROW_ID  =C.BO_DET_ROW_ID --AND A.JOB_CODE=C.JOB_CODE
        JOIN AGENCY_JOBS AJ ON AJ.JOB_CODE =B.JOB_CODE 
        JOIN PRD_AGENCY_MST AM ON AM.AGENCY_CODE =AJ.AGENCY_CODE 
        WHERE AM.AC_CODE  =@CAGENCY_CODE 
        GROUP BY A.JOB_CODE ,A.JOB_ORDER ,B.JOB_NAME 
        ORDER BY JOB_NAME ,JOB_ORDER 
        
          
    GOTO END_PROC  
      
  
    LBLMST:  
       
       IF OBJECT_ID('TEMPDB..#TMPMST','U') IS NOT NULL
          DROP  TABLE #TMPMST
            
       SELECT  A.MEMO_ID,A.MEMO_NO,CONVERT(VARCHAR,A.MEMO_DT,105) AS MEMO_DT,
              A.LAST_UPDATE,JOBS.JOB_NAME,  
              CASE WHEN A.MEMO_TYPE=1 THEN 'ISSUE' ELSE 'RETURN' END AS MEMO_TYPE,
              A.AC_CODE,LM.AC_NAME,MST.BILL_NO,A.FIN_YEAR,A.CANCELLED,A.APPROVED,
              LM1.AC_NAME AS BUYER_NAME,
              ISNULL(TC.TERM_NAME,'') AS TERM_NAME,
              A.MEMO_DT AS DT,
              MST.ARTICLE_NO,
              MST.ARTICLE_CODE,
              SUM(B.QUANTITY) AS QUANTITY
       INTO #TMPMST
       FROM  PPC_AGENCY_ISSUE_FG_MST A  
       JOIN  PPC_AGENCY_ISSUE_FG_DET B ON A.MEMO_ID=B.MEMO_ID
       JOIN LM01106 LM ON LM.AC_CODE=A.AC_CODE 
       JOIN
       (
        SELECT A.PRODUCT_CODE,MST.BILL_NO ,MST.AC_CODE,ART.ARTICLE_NO,ART.ARTICLE_CODE
        FROM PPC_FG_SKU A
        JOIN PPC_FGBCG_DET B ON A.PPC_FGBCG_DET_ROW_ID=B.ROW_ID
        JOIN PPC_FGBCG_MST C ON C.MEMO_ID=B.MEMO_ID
        JOIN PPC_BUYER_ORDER_DET DET ON DET.ROW_ID=B.BO_DET_ROW_ID
        JOIN PPC_BUYER_ORDER_MST MST ON MST.ORDER_ID=DET.ORDER_ID
        JOIN ARTICLE ART ON ART.ARTICLE_CODE=A.ARTICLE_CODE
        GROUP BY A.PRODUCT_CODE,MST.BILL_NO ,MST.AC_CODE,ART.ARTICLE_NO,ART.ARTICLE_CODE
       ) MST ON MST.PRODUCT_CODE=B.PRODUCT_CODE 
       JOIN LM01106 LM1 ON LM1.AC_CODE=MST.AC_CODE 
       JOIN JOBS  ON JOBS.JOB_CODE=A.JOB_CODE
       LEFT OUTER JOIN PPC_TERM_CONDITION_MST TC ON TC.MEMO_ID=A.TERMS_MEMO_ID
       WHERE  (@CMEMO_ID ='' OR A.MEMO_ID =@CMEMO_ID ) 
       AND (@CBILL_NO ='' OR MST.BILL_NO =@CBILL_NO )  
       AND (@CAGENCY_CODE='' OR A.AC_CODE=@CAGENCY_CODE)  
       AND (@CFIN_YEAR='' OR A.FIN_YEAR=@CFIN_YEAR)
       AND (@CJOB_CODE ='' OR JOBS.JOB_CODE =@CJOB_CODE)
       GROUP BY A.MEMO_ID,A.MEMO_NO,CONVERT(VARCHAR,A.MEMO_DT,105) ,
       A.LAST_UPDATE,JOBS.JOB_NAME,  
       CASE WHEN A.MEMO_TYPE=1 THEN 'ISSUE' ELSE 'RETURN' END ,
       A.AC_CODE,LM.AC_NAME,MST.BILL_NO,A.FIN_YEAR,A.CANCELLED,A.APPROVED,
       LM1.AC_NAME ,ISNULL(TC.TERM_NAME,'') ,
       A.MEMO_DT ,MST.ARTICLE_NO,MST.ARTICLE_CODE
       
       SELECT A.* FROM #TMPMST A
       ORDER BY A.DT DESC,A.MEMO_ID DESC
       
       SELECT DISTINCT BILL_NO 
       FROM #TMPMST
      
       
    GOTO END_PROC  
      
      
    LBLDET:  
         
         IF @CMEMO_ID=''
         BEGIN
             IF @NRETURN=1
             BEGIN
				 IF OBJECT_ID ('TEMPDB..#TMPISSUE','U') IS NOT NULL
				 DROP TABLE #TMPISSUE
	          
				 SELECT CAST(1 AS BIT) AS CHK,
					   CAST('LATER' AS VARCHAR(50)) AS MEMO_ID,
					   ROW_ID=CAST('LATER' AS VARCHAR(40))+CAST(NEWID() AS VARCHAR(100)),
					   ART_ROW_ID=ART.ARTICLE_NO+SG.SIZEGROUP_NAME+P1.PARA1_NAME,
					   A.AC_CODE,LM.AC_NAME ,
					   DET.BILL_NO,
					   DET.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,
					   B.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,
					   B.PARA1_CODE,P1.PARA1_NAME AS COLOR,
					   B.PARA3_CODE,P3.PARA3_NAME BUYER_STYLE_NO,
					   SKU.PARA2_CODE,P2.PARA2_NAME SIZE,
					   PR.JOB_CODE,
					   PR.JOB_NAME,
					   PR.PRODUCT_CODE,
					   PMT.QUANTITY_IN_STOCK AS QUANTITY,
					   DET.ROW_ID AS BO_ROW_ID,
					   REPLACE(CONVERT(VARCHAR(11),DET.DELIVERY_DT,106),' ','-')  AS DELIVERY_DT
					INTO #TMPISSUE
					FROM PPC_FGBCG_MST A
					JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID 
					JOIN
					(
					  SELECT A.ORDER_ID ,  B.AC_CODE,A.ARTICLE_CODE ,
						ROW_ID,B.BILL_NO,A.DELIVERY_DT  
						FROM PPC_BUYER_ORDER_DET A
						JOIN PPC_BUYER_ORDER_MST B ON A.ORDER_ID=B.ORDER_ID
						WHERE B.CANCELLED=0
					  GROUP BY A.ORDER_ID ,B.AC_CODE,A.ARTICLE_CODE ,ROW_ID,B.BILL_NO,A.DELIVERY_DT 
					) DET ON DET.ROW_ID=B.BO_DET_ROW_ID 
					JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID
					JOIN PPC_FG_PMT PMT ON SKU.PRODUCT_CODE =PMT.PRODUCT_CODE  
					JOIN ARTICLE ART ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE 
					JOIN PARA1 P1 ON P1.PARA1_CODE =SKU.PARA1_CODE 
					JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE 
					JOIN PARA3 P3 ON P3.PARA3_CODE =SKU.PARA3_CODE 
					JOIN PPC_SIZEGROUP SG ON SG.SIZEGROUP_CODE =SKU.SIZEGROUP_CODE 
					JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE 
					JOIN
					(
						SELECT JOBS.JOB_CODE,JOBS.JOB_NAME,
						B.MEMO_ID,B.MEMO_NO,B.MEMO_DT, PRODUCT_CODE,QUANTITY AS QUANTITY
						FROM PPC_AGENCY_ISSUE_FG_FIRST_DET  A
						JOIN PPC_AGENCY_ISSUE_FG_FIRST_MST B ON A.MEMO_ID =B.MEMO_ID 
						JOIN JOBS  ON B.JOB_CODE=JOBS.JOB_CODE
						WHERE B.CANCELLED=0 AND B.MEMO_TYPE=1
						AND(@CPRODUCT_CODE='' OR A.PRODUCT_CODE=@CPRODUCT_CODE)
					) PR ON PR.PRODUCT_CODE =PMT.PRODUCT_CODE	
					AND (@CBILL_NO='' OR DET.BILL_NO=@CBILL_NO)
					AND (@CORDER_ID='' OR DET.ORDER_ID =@CORDER_ID)
					WHERE PMT.QUANTITY_IN_STOCK>0
					
				--	SELECT * INTO TMPISSUE FROM #TMPISSUE
					
				
					
			SELECT DISTINCT CAST(1 AS BIT) AS CHK,
				 CAST('LATER' AS VARCHAR(50)) AS MEMO_ID,
				-- ROW_ID=CAST('LATER' AS VARCHAR(40))+CAST(NEWID() AS VARCHAR(100)),
				 B.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,
				 B.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,
				 B.PARA1_CODE,P1.PARA1_NAME AS COLOR,
				 SKU.PARA2_CODE,P2.PARA2_NAME ,
				 CAST(0 AS NUMERIC(10,0)) AS QUANTITY,
				 CAST(0 AS NUMERIC(10,0)) AS MISSING_QTY,
				 TMP.BO_ROW_ID,
				 TMP.DELIVERY_DT
			FROM PPC_FGBCG_MST A
			JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID 
			JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID 
			JOIN PPC_FG_PMT PMT ON PMT.PRODUCT_CODE=SKU.PRODUCT_CODE 
			JOIN ARTICLE ART ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE 
			JOIN PARA1 P1 ON P1.PARA1_CODE =SKU.PARA1_CODE 
			JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE 
			JOIN PPC_SIZEGROUP SG ON SG.SIZEGROUP_CODE =SKU.SIZEGROUP_CODE 
			JOIN #TMPISSUE  TMP ON TMP.ARTICLE_CODE=B.ARTICLE_CODE AND TMP.PARA1_CODE =B.PARA1_CODE AND TMP.SIZEGROUP_CODE =B.SIZEGROUP_CODE
			AND TMP.BO_ROW_ID =B.BO_DET_ROW_ID 
			
			
			
			SELECT CHK,
				 MEMO_ID,
				 ROW_ID,
				 ART_ROW_ID,
				 A.AC_CODE,A.AC_NAME ,
				 A.BILL_NO,
				 A.ARTICLE_CODE,A.ARTICLE_NO,A.ARTICLE_NAME,
				 A.SIZEGROUP_CODE,A.SIZEGROUP_NAME ,
				 A.PARA1_CODE,A.COLOR,
				 A.PARA3_CODE,A.BUYER_STYLE_NO,
				 A.PARA2_CODE,A.SIZE,
				 A.JOB_CODE,
				 A.JOB_NAME,
				 A.PRODUCT_CODE,
				 A.QUANTITY,
				 CAST(0 AS NUMERIC(10,0)) AS PHY_QTY,
				 CAST(1 AS NUMERIC(10,0)) AS SCAN_QTY,
				 CAST(0 AS NUMERIC(10,0)) AS BAL_QTY,
				 1 AS QUANTITY_IN_STOCK,
				 BO_ROW_ID,
				 A.DELIVERY_DT
			  FROM #TMPISSUE  A
					
					
				
				
		    END
		    ELSE
		    BEGIN
		         IF OBJECT_ID ('TEMPDB..#TMPISSUERETURN','U') IS NOT NULL
                 DROP TABLE #TMPISSUERETURN
             
		        SELECT CAST(1 AS BIT) AS CHK,
				   CAST('LATER' AS VARCHAR(50)) AS MEMO_ID,
				   ROW_ID=CAST('LATER' AS VARCHAR(40))+CAST(NEWID() AS VARCHAR(100)),
				   ART_ROW_ID=A.ARTICLE_NO+A.SIZEGROUP_NAME+A.PARA1_NAME+A.PARA2_NAME ,
				   A.AC_CODE,A.AC_NAME ,
				   A.BILL_NO,
				   A.ARTICLE_CODE,A.ARTICLE_NO,A.ARTICLE_NAME,
				   A.SIZEGROUP_CODE,A.SIZEGROUP_NAME ,
				   A.PARA1_CODE,A.PARA1_NAME AS COLOR,
				   A.PARA3_CODE,A.PARA3_NAME BUYER_STYLE_NO,
				   A.PARA2_CODE,A.PARA2_NAME SIZE,
				   A.JOB_CODE,
				   A.JOB_NAME,
				   A.PRODUCT_CODE,
				   A.ISSUE_QTY AS QUANTITY,
				   A.ROW_ID AS BO_ROW_ID,
				   A.DELIVERY_DT
				INTO #TMPISSUERETURN
				FROM
				(
				SELECT SKU.ARTICLE_CODE , BO.BILL_NO, A.AC_CODE , SKU.PRODUCT_CODE ,
				LM.AC_NAME ,ART.ARTICLE_NO,ART.ARTICLE_NAME,SKU.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,
				P1.PARA1_CODE,P1.PARA1_NAME, 
				P2.PARA2_CODE,P2.PARA2_NAME,
				P3.PARA3_CODE,P3.PARA3_NAME,
				J1.JOB_CODE,J1.JOB_NAME ,    
				SUM(C.ISSUE_QTY) AS ISSUE_QTY,
				BO.ROW_ID ,
				REPLACE(CONVERT(VARCHAR(11),BO.DELIVERY_DT,106),' ','-')  AS DELIVERY_DT
				FROM PPC_FGBCG_MST A
				JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID 
				JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID 
				JOIN
				(
				 SELECT ROW_ID,BILL_NO,A.DELIVERY_DT 
				 FROM PPC_BUYER_ORDER_DET A
				 JOIN PPC_BUYER_ORDER_MST B ON A.ORDER_ID =B.ORDER_ID 
				 GROUP BY ROW_ID,BILL_NO,A.DELIVERY_DT 
				) BO ON BO.ROW_ID =B.BO_DET_ROW_ID
				JOIN
				(
					SELECT  B.BILL_NO, B.AC_CODE , B.JOB_CODE, PRODUCT_CODE,A.REF_ROW_ID,
						   SUM(A.QUANTITY)   AS ISSUE_QTY
					FROM PPC_AGENCY_REC_FG_DET  A
					JOIN PPC_AGENCY_REC_FG_MST  B ON A.MEMO_ID =B.MEMO_ID 
					WHERE B.CANCELLED=0 --AND ISNULL(MEMO_TYPE,0)=2
					AND B.AC_CODE=@CAGENCY_CODE
				    AND(@CPRODUCT_CODE='' OR A.PRODUCT_CODE=@CPRODUCT_CODE)
					AND (@CBILL_NO='' OR B.BILL_NO=@CBILL_NO)
					AND (@CJOB_CODE='' OR B.JOB_CODE=@CJOB_CODE)
					GROUP BY  B.JOB_CODE, B.BILL_NO, B.AC_CODE , B.JOB_CODE, PRODUCT_CODE,A.REF_ROW_ID
					
				) C ON SKU.PRODUCT_CODE=C.PRODUCT_CODE
				JOIN PPC_BO_ART_JOBS JOBS ON JOBS .REF_ROW_ID=B.BO_DET_ROW_ID  AND JOBS.JOB_CODE =C.JOB_CODE
				JOIN LM01106 LM ON LM.AC_CODE=A.AC_CODE 
				JOIN ARTICLE ART ON ART.ARTICLE_CODE=SKU.ARTICLE_CODE 
				JOIN PPC_SIZEGROUP SG ON SG.SIZEGROUP_CODE=SKU.SIZEGROUP_CODE
				JOIN PARA1 P1 ON P1.PARA1_CODE =SKU.PARA1_CODE 
				JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE 
				JOIN PARA3 P3 ON P3.PARA3_CODE =SKU.PARA3_CODE 
				JOIN JOBS J1 ON J1.JOB_CODE=J1.JOB_CODE
				WHERE --JOB_ORDER>1 AND
				 (@CJOB_CODE='' OR JOBS.JOB_CODE=@CJOB_CODE)
				AND A.CANCELLED =0
				GROUP BY SKU.ARTICLE_CODE , BO.BILL_NO, A.AC_CODE , SKU.PRODUCT_CODE ,
				LM.AC_NAME ,ART.ARTICLE_NO,ART.ARTICLE_NAME,SKU.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,
				P1.PARA1_CODE,P1.PARA1_NAME, 
				P2.PARA2_CODE,P2.PARA2_NAME,
				P3.PARA3_CODE,P3.PARA3_NAME,
				J1.JOB_CODE,J1.JOB_NAME  ,BO.ROW_ID,
				REPLACE(CONVERT(VARCHAR(11),BO.DELIVERY_DT,106),' ','-') 
				) A
				JOIN
				(
				 SELECT PRODUCT_CODE,B.JOB_CODE,ROW_ID,
						SUM(QUANTITY ) AS RE_ISS_QTY
				 FROM PPC_AGENCY_ISSUE_FG_DET A
				 JOIN PPC_AGENCY_ISSUE_FG_MST B ON A.MEMO_ID =B.MEMO_ID 
				 WHERE B.CANCELLED =0 
				 AND (@CJOB_CODE='' OR B.JOB_CODE=@CJOB_CODE)
				 AND ISNULL(MEMO_TYPE,0)=1
				 AND (@CBILL_NO='' OR B.BILL_NO=@CBILL_NO)
				 AND B.AC_CODE=@CAGENCY_CODE
				 GROUP BY PRODUCT_CODE,B.JOB_CODE,ROW_ID
				 UNION ALL
				  SELECT PRODUCT_CODE,B.JOB_CODE,ROW_ID,
						SUM(QUANTITY ) AS RE_ISS_QTY
				 FROM PPC_AGENCY_ISSUE_FG_FIRST_DET A
				 JOIN PPC_AGENCY_ISSUE_FG_FIRST_MST  B ON A.MEMO_ID =B.MEMO_ID 
				 WHERE B.CANCELLED =0 
				 AND (@CJOB_CODE='' OR B.JOB_CODE=@CJOB_CODE)
				 AND ISNULL(MEMO_TYPE,0)=1
				 AND (@CBILL_NO='' OR B.BILL_NO=@CBILL_NO)
				 AND B.AC_CODE=@CAGENCY_CODE
				 GROUP BY PRODUCT_CODE,B.JOB_CODE,ROW_ID
				) B ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.JOB_CODE=B.JOB_CODE 
				JOIN PPC_FG_PMT PMT ON PMT.PRODUCT_CODE=A.PRODUCT_CODE
				WHERE (@CPRODUCT_CODE='' OR A.PRODUCT_CODE=@CPRODUCT_CODE )
				AND PMT.QUANTITY_IN_STOCK >0
				--AND ISNULL(ISSUE_QTY,0)-ISNULL(RE_ISS_QTY,0)>0
		    
		    
		       
		 SELECT DISTINCT CAST(1 AS BIT) AS CHK,
	         CAST('LATER' AS VARCHAR(50)) AS MEMO_ID,
	        -- ROW_ID=CAST('LATER' AS VARCHAR(40))+CAST(NEWID() AS VARCHAR(100)),
			 B.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,
			 B.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,
			 B.PARA1_CODE,P1.PARA1_NAME AS COLOR,
			 SKU.PARA2_CODE,P2.PARA2_NAME ,
			 CAST(0 AS NUMERIC(10,0)) AS QUANTITY,
			 CAST(0 AS NUMERIC(10,0)) AS MISSING_QTY,
			 TMP.BO_ROW_ID,
			 TMP.DELIVERY_DT
		FROM PPC_FGBCG_MST A
		JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID 
		JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID 
		JOIN PPC_FG_PMT PMT ON PMT.PRODUCT_CODE=SKU.PRODUCT_CODE 
		JOIN ARTICLE ART ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE 
		JOIN PARA1 P1 ON P1.PARA1_CODE =SKU.PARA1_CODE 
		JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE 
		JOIN PPC_SIZEGROUP SG ON SG.SIZEGROUP_CODE =SKU.SIZEGROUP_CODE 
		JOIN #TMPISSUERETURN  TMP ON TMP.ARTICLE_CODE=B.ARTICLE_CODE AND TMP.PARA1_CODE =B.PARA1_CODE AND TMP.SIZEGROUP_CODE =B.SIZEGROUP_CODE
		
		
		
		SELECT CHK,
	         MEMO_ID,
	         ROW_ID,
	         ART_ROW_ID,
	         A.AC_CODE,A.AC_NAME ,
	         A.BILL_NO,
			 A.ARTICLE_CODE,A.ARTICLE_NO,A.ARTICLE_NAME,
			 A.SIZEGROUP_CODE,A.SIZEGROUP_NAME ,
			 A.PARA1_CODE,A.COLOR,
			 A.PARA3_CODE,A.BUYER_STYLE_NO,
			 A.PARA2_CODE,A.SIZE,
			 A.JOB_CODE,
			 A.JOB_NAME,
			 A.PRODUCT_CODE,
		     A.QUANTITY,
		     CAST(0 AS NUMERIC(10,0)) AS PHY_QTY,
		     CAST(1 AS NUMERIC(10,0)) AS SCAN_QTY,
		     CAST(0 AS NUMERIC(10,0)) AS BAL_QTY,
			 1 AS QUANTITY_IN_STOCK,
			 A.BO_ROW_ID,
			 A.DELIVERY_DT
		  FROM #TMPISSUERETURN  A
		    
		    
		    END
           END 
           ELSE
           BEGIN
               
                SELECT CAST(1 AS BIT) AS CHK,
				   PR.MEMO_ID AS MEMO_ID,
				   ROW_ID=PR.ROW_ID,
				   A.AC_CODE,LM.AC_NAME ,
				   DET.BILL_NO,
				   DET.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,
				   B.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,
				   B.PARA1_CODE,P1.PARA1_NAME AS COLOR,
				   B.PARA3_CODE,P3.PARA3_NAME BUYER_STYLE_NO,
				   SKU.PARA2_CODE,P2.PARA2_NAME SIZE,
				   PR.JOB_CODE,
				   PR.JOB_NAME,
				   PR.PRODUCT_CODE,
				   PR.QUANTITY AS QUANTITY
				FROM PPC_FGBCG_MST A
				JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID 
				JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID 
				JOIN
				(
				  SELECT  B.AC_CODE,A.ARTICLE_CODE ,
					ROW_ID,B.BILL_NO FROM PPC_BUYER_ORDER_DET A
					JOIN PPC_BUYER_ORDER_MST B ON A.ORDER_ID=B.ORDER_ID
					WHERE B.CANCELLED=0
				  GROUP BY B.AC_CODE,A.ARTICLE_CODE ,ROW_ID,B.BILL_NO
				) DET ON DET.ROW_ID=B.BO_DET_ROW_ID 
				JOIN ARTICLE ART ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE 
				JOIN PARA1 P1 ON P1.PARA1_CODE =SKU.PARA1_CODE 
				JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE 
				JOIN PARA3 P3 ON P3.PARA3_CODE =SKU.PARA3_CODE 
				JOIN PPC_SIZEGROUP SG ON SG.SIZEGROUP_CODE =SKU.SIZEGROUP_CODE 
				JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE 
				JOIN
				(
					SELECT JOBS.JOB_CODE,JOBS.JOB_NAME,A.ROW_ID,
					B.MEMO_ID,B.MEMO_NO,B.MEMO_DT, PRODUCT_CODE,QUANTITY AS QUANTITY
					FROM PPC_AGENCY_ISSUE_FG_DET  A
					JOIN PPC_AGENCY_ISSUE_FG_MST B ON A.MEMO_ID =B.MEMO_ID 
					JOIN JOBS  ON B.JOB_CODE=JOBS.JOB_CODE
					WHERE B.CANCELLED=0
					AND A.MEMO_ID=@CMEMO_ID
				) PR ON PR.PRODUCT_CODE =SKU.PRODUCT_CODE	
				
           END
  
    GOTO END_PROC  
    
    
     LBLAGENCY_VIEW:  
     
      SELECT DISTINCT A.AC_CODE,B.AC_NAME
      FROM PPC_AGENCY_ISSUE_FG_MST A
      JOIN LM01106 B ON A.AC_CODE=B.AC_CODE
    
    GOTO END_PROC 
      
    LBLBILL_NO_VIEW:  
         
       SELECT BILL_NO AS ORDER_NO   
       FROM PPC_AGENCY_ISSUE_FG_MST A  
       WHERE CANCELLED=0  
       AND (@CAGENCY_CODE='' OR AC_CODE=@CAGENCY_CODE)
       GROUP BY BILL_NO  
         
    GOTO END_PROC  
      
    LBLMEMO_VIEW: --FOR FIRST TIME  
        
       SELECT DISTINCT A.MEMO_NO,A.MEMO_ID  
       FROM PPC_AGENCY_ISSUE_FG_MST A  
       WHERE  (@CBILL_NO ='' OR A.BILL_NO =@CBILL_NO )  
       AND (@CAGENCY_CODE='' OR AC_CODE=@CAGENCY_CODE)  
   
          
    GOTO END_PROC  
 
     LBLBARCODEPRINT_CROSSTAB:
        

        IF OBJECT_ID ('TEMPDB..#TMPALLOTEDPRINT','P') IS NOT NULL
           DROP TABLE #TMPALLOTEDPRINT
           
	
				      
			SELECT PR.ROW_ID, PR.MEMO_ID,A.AC_CODE,LM.AC_NAME,DET.BILL_NO,
				B.ARTICLE_CODE,ART.ARTICLE_NO ,ART.ARTICLE_NAME ,
				SKU.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,
				SKU.PARA1_CODE,P1.PARA1_NAME,
				SKU.PARA2_CODE,P2.PARA2_NAME,
				SKU.PARA3_CODE,P3.PARA3_NAME ,
				SKU.PRODUCT_CODE,
				PR.JOB_CODE,
				PR.JOB_NAME,
				ISNULL(PR.MISSING_PRODUCT_CODE,0) AS MISSING_PRODUCT_CODE,
				CASE WHEN ISNULL(PR.MISSING_PRODUCT_CODE,0)=0 THEN  PR.REC_QTY ELSE 0 END AS REC_QTY,
				CASE WHEN ISNULL(PR.MISSING_PRODUCT_CODE,0)=1 THEN  PR.REC_QTY ELSE 0 END AS MISSING_QTY,
				DET.ROW_ID AS BO_ROW_ID,
				REPLACE(CONVERT(VARCHAR(11),DET.DELIVERY_DT,106),' ','-')  AS DELIVERY_DT
				INTO #TMPALLOTEDPRINT
			FROM PPC_FGBCG_MST A
			JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID 
			JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID 
			JOIN
			(
			  SELECT  B.AC_CODE,A.ARTICLE_CODE ,
				ROW_ID,B.BILL_NO ,A.DELIVERY_DT 
				FROM PPC_BUYER_ORDER_DET A
				JOIN PPC_BUYER_ORDER_MST B ON A.ORDER_ID=B.ORDER_ID
				WHERE B.CANCELLED=0
			  GROUP BY B.AC_CODE,A.ARTICLE_CODE ,ROW_ID,B.BILL_NO,A.DELIVERY_DT 
			) DET ON DET.ROW_ID=B.BO_DET_ROW_ID 
			JOIN ARTICLE ART ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE 
			JOIN PARA1 P1 ON P1.PARA1_CODE =SKU.PARA1_CODE 
			JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE 
			JOIN PARA3 P3 ON P3.PARA3_CODE =SKU.PARA3_CODE 
			JOIN PPC_SIZEGROUP SG ON SG.SIZEGROUP_CODE =SKU.SIZEGROUP_CODE 
			JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE 
		    JOIN
			(
				SELECT ISNULL(A.MISSING_PRODUCT_CODE,0) AS MISSING_PRODUCT_CODE, A.ROW_ID, B.JOB_CODE,JOBS.JOB_NAME, A.MEMO_ID, PRODUCT_CODE,A.QUANTITY AS REC_QTY
				FROM PPC_AGENCY_ISSUE_FG_DET  A
				JOIN PPC_AGENCY_ISSUE_FG_MST B ON A.MEMO_ID =B.MEMO_ID 
				JOIN JOBS ON JOBS.JOB_CODE=B.JOB_CODE
				WHERE B.CANCELLED=0
				AND A.MEMO_ID=@CMEMO_ID
			) PR ON PR.PRODUCT_CODE =SKU.PRODUCT_CODE
			
			
	
			
			SELECT 
				A.AC_CODE,
				A.AC_NAME,
				A.BILL_NO,
				A.ARTICLE_CODE,
				A.ARTICLE_NO,
				A.PARA1_CODE,
				A.PARA1_NAME,
				A.SIZEGROUP_CODE,
				A.SIZEGROUP_NAME,
				A.PARA3_CODE,
				A.PARA3_NAME,
                CAST(SUM(ISNULL(REC_QTY,0)) AS NUMERIC(10,0)) AS REC_QTY,
                CAST(SUM(ISNULL(MISSING_QTY,0)) AS NUMERIC(10,0)) AS MISSING_QTY,
                CAST('' AS VARCHAR(100)) AS IMAGE_1,
                A.BO_ROW_ID ,
                A.DELIVERY_DT
				FROM #TMPALLOTEDPRINT A 
				GROUP BY A.AC_CODE,A.AC_NAME,A.BILL_NO,
				A.PARA1_CODE,A.PARA1_NAME,A.SIZEGROUP_CODE,A.SIZEGROUP_NAME,
				A.PARA3_CODE,A.PARA3_NAME, A.ARTICLE_CODE,
				A.ARTICLE_NO,A.BO_ROW_ID ,A.DELIVERY_DT
			
				
				
		SELECT MEMO_ID,
        ROW_ID=CAST('LATER' AS VARCHAR(40))+CAST(NEWID() AS VARCHAR(100)),
        A.AC_CODE,A.AC_NAME,A.BILL_NO,A.ARTICLE_CODE,
		A.ARTICLE_NO,A.PARA1_CODE,
		A.PARA1_NAME,A.SIZEGROUP_CODE,
		A.SIZEGROUP_NAME,A.PARA3_CODE,A.PARA3_NAME,
        PARA2_CODE,PARA2_NAME,
        CAST(SUM(ISNULL(REC_QTY,0)) AS NUMERIC(10,0)) AS REC_QTY,
        CAST(SUM(ISNULL(MISSING_QTY,0)) AS NUMERIC(10,0)) AS MISSING_QTY,
        A.BO_ROW_ID 
        FROM #TMPALLOTEDPRINT A
        GROUP BY MEMO_ID,PARA2_CODE,PARA2_NAME,A.AC_CODE,A.AC_NAME,A.BILL_NO,A.ARTICLE_CODE,
		A.ARTICLE_NO,A.PARA1_CODE,
		A.PARA1_NAME,A.SIZEGROUP_CODE,
		A.SIZEGROUP_NAME,A.PARA3_CODE,A.PARA3_NAME,A.BO_ROW_ID 
		
    GOTO END_PROC
          
 END_PROC:  
  
  
END
