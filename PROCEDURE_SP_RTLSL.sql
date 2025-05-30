CREATE PROCEDURE SP_RTLSL  --(LocId 3 digit change by Sanjay:30-10-2024)
(  
	 @CQUERYID				NUMERIC(2),  
	 @CWHERE				VARCHAR(max)='',  
	 @CFINYEAR				VARCHAR(5)='',  
	 @CDEPTID				VARCHAR(4)='',  
	 @NNAVMODE				NUMERIC(2)=1,  
	 @CWIZAPPUSERCODE		VARCHAR(10)='',  
	 @CREFMEMOID			VARCHAR(40)='',  
	 @CREFMEMODT			DATETIME='',  
	 @BINCLUDEESTIMATE		BIT=1,
	 @NQUANTITY				NUMERIC(10,3)=0 
)
--WITH ENCRYPTION
AS  
BEGIN  
DECLARE @CCMD NVARCHAR(MAX)  
SET @CCMD=''  
    IF @CQUERYID=1  
  GOTO LBLCMMLU  
    
 ELSE IF @CQUERYID=3  
  GOTO LBLRPS_MST  
 ELSE IF @CQUERYID=4  
  GOTO LBLRPS_DET   
 ELSE IF @CQUERYID=6  
  GOTO LBLEMPLOYEE  
 ELSE IF @CQUERYID=7  
  GOTO LBLPRODUCTINFO   
 ELSE IF @CQUERYID=9  
  GOTO LBLADJCNLIST  
 ELSE IF @CQUERYID=10  
  GOTO LBLSKU  
 ELSE IF @CQUERYID=11  
  GOTO LBLMEMOPRINT_MST  
 ELSE IF @CQUERYID=12  
  GOTO LBLMEMOPRINT_DET   
 ELSE IF @CQUERYID=19  
  GOTO LBLSCHEMEDETAILS  
 ELSE IF @CQUERYID=20
 GOTO  LBLCHKSTOCK
 ELSE IF @CQUERYID=27 
 GOTO LBLPACKSLIPREF
 ELSE IF @CQUERYID=28 
 GOTO LBLLASTEMP
 ELSE   
  GOTO LAST  
    
LBLCMMLU:   
  EXECUTE SP_NAVIGATE 'RPS_MST',@NNAVMODE,@CREFMEMOID,@CFINYEAR,'CM_NO','CM_DT','CM_ID',@CWHERE,@BINCLUDEESTIMATE  
  --EXEC SP_NAVIGATE 'ITEM_CNC_MST',@NNAVMODE,@CWHERE,@CFINYEAR,'MEMO_NO','MEMO_DT','MEMO_ID'  
  -- @NMODE :  1 - TOP RECORD  
  --    2 - NEXT RECORD (@CREFMEMOID AND @CREFMEMODT IS MANDATORY)  
  --    3 - PREVIOUS RECORD (@CREFMEMOID AND @CREFMEMODT IS MANDATORY)  
  --    4 - LAST RECORD  
  GOTO LAST  
   
LBLRPS_MST:  
  SELECT CMM.CM_NO AS REF_SLS_MEMO_NO,CMM.CM_DT AS REF_SLS_MEMO_DT,  A.*, C.USERNAME,ISNULL(X.EMP_CODE,'0000000') AS [EMP_CODE],
  ISNULL(X.EMP_CODE1,'0000000')  AS [EMP_CODE1],ISNULL(X.EMP_CODE2,'0000000') AS [EMP_CODE2],
   ISNULL(X.EMP_NAME,'') AS [EMP_NAME],ISNULL(X.EMP_NAME1,'') AS [EMP_NAME1],
   ISNULL(X.EMP_NAME2,'') AS [EMP_NAME2]   ,ISNULL(BIN.BIN_NAME,'')  AS [BIN_NAME]
   ,CAST(ISNULL(TAX,0) AS NUMERIC(14,2)) AS [TOTAL_TAX] ,CUST.*, '' AS CUSTOMER_NAME,'' AS ADDRESS,
   CAST('' AS VARCHAR(40)) AS SP_ID,CAST(0 AS NUMERIC(14,2)) AS SUBTOTAL_R,A.SUBTOTAL AS SUBTOTAL_T,CAST(0 AS BIT ) AS dp_changed
  FROM RPS_MST A    
  JOIN USERS C ON C.USER_CODE=A.USER_CODE  
  LEFT OUTER JOIN
  (
	SELECT TOP 1 CM_ID,E1.EMP_CODE,E2.EMP_CODE  AS [EMP_CODE1],E3.EMP_CODE AS [EMP_CODE2],E1.EMP_NAME AS [EMP_NAME]
	,E2.EMP_NAME AS [EMP_NAME1],E3.EMP_NAME AS [EMP_NAME2]
	FROM RPS_DET A (NOLOCK)
	JOIN EMPLOYEE E1 (NOLOCK) ON E1.EMP_CODE=A.EMP_CODE
	JOIN EMPLOYEE E2 (NOLOCK) ON E2.EMP_CODE=A.EMP_CODE1
	JOIN EMPLOYEE E3 (NOLOCK) ON E3.EMP_CODE=A.EMP_CODE2
	WHERE A.CM_ID=@CWHERE AND (A.EMP_CODE<>'0000000' OR A.EMP_CODE2<>'0000000' OR A.EMP_CODE2<>'0000000')
  )X ON X.CM_ID=A.CM_ID
  LEFT OUTER JOIN
  (
	SELECT SUM(TAX_AMOUNT) AS [TAX] ,CM_ID	FROM RPS_DET A (NOLOCK)
	WHERE TAX_METHOD=2 AND CM_ID=@CWHERE 
	GROUP BY CM_ID
  )X1 ON X1.CM_ID=A.CM_ID  
  LEFT OUTER JOIN BIN ON BIN.BIN_ID=A.BIN_ID
  LEFT OUTER JOIN CUSTDYM  CUST ON A.CUSTOMER_CODE=CUST.CUSTOMER_CODE
  LEFT OUTER JOIN CMM01106 CMM  (NOLOCK) ON CMM.CM_ID= A.ref_cm_id
  WHERE  A.CM_ID=@CWHERE  
        GOTO LAST  
LBLRPS_DET:  
	SELECT  CMM.CM_NO AS REF_SLS_MEMO_NO,CMM.CM_DT AS REF_SLS_MEMO_DT, A.*,ROW_NUMBER() OVER (ORDER BY A.TS) AS SRNO,    
			EMP.EMP_NAME, A.PRODUCT_CODE, B.ARTICLE_CODE, B.ARTICLE_NO, B.ARTICLE_NAME, S.PARA1_CODE,  
			SN.PARA1_NAME, S.PARA2_CODE, SN.PARA2_NAME, S.PARA3_CODE, SN.PARA3_NAME, E.UOM_NAME,     
			A.DEPT_ID, S.BARCODE_CODING_SCHEME AS CODING_SCHEME,  B.INACTIVE, ISNULL(P.QUANTITY_IN_STOCK,0) AS QUANTITY_IN_STOCK,  
			S.PURCHASE_PRICE,  S.MRP,S.WS_PRICE,  '' AS SCHEME_ID, SN.SECTION_NAME, SN.SUB_SECTION_NAME,  
			S.PARA4_CODE,S.PARA5_CODE,S.PARA6_CODE,  
			PARA4_NAME,PARA5_NAME,PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],  
			B.DT_CREATED AS [ART_DT_CREATED],'' AS [PARA3_DT_CREATED],S.DT_CREATED AS [SKU_DT_CREATED],  
			B.STOCK_NA,    
			CONVERT (BIT,(CASE WHEN A.QUANTITY <0 THEN 1 ELSE 0 END)) AS SALERETURN ,CAST(0 AS BIT) AS CREDIT_REFUND,
			 A.MRP AS [LOCSKU_MRP],S.PRODUCT_NAME,  
		   EMP1.EMP_NAME AS EMP_NAME1 ,EMP2.EMP_NAME AS EMP_NAME2  ,
		   (CASE WHEN ISNULL(S.FIX_MRP,0)=0 THEN S.MRP ELSE S.FIX_MRP END) AS [FIX_MRP],
		   (CASE WHEN ISNULL(A.HOLD_FOR_ALTER,0)=0 THEN 'N' ELSE 'Y' END) AS [HOLD_FOR_ALTER_TXT] ,
		   ISNULL(BIN.BIN_NAME,'')  AS [BIN_NAME],B.ALIAS AS ARTICLE_ALIAS  ,'' SUB_SECTION_CODE,'' SECTION_CODE,
		   ISNULL(S1.SLS_TITLE,'') AS [SLS_TITLE] ,CAST('' AS VARCHAR(40)) AS SP_ID,
		   (CASE WHEN ISNULL(A.REF_APPROVAL_MEMO_ID,'')='' THEN '' ELSE RIGHT(A.REF_APPROVAL_MEMO_ID,10 ) END) AS REF_APPROVAL_MEMO_NO
		   ,CAST(0 AS NUMERIC(14,2)) AS manual_discount_percentage,
CAST(0 AS NUMERIC(14,2)) AS manual_discount_amount,CAST(0 AS BIT) AS ManualDA_changed,CAST(0 AS VARCHAR(100)) AS DET_REMARKS,CAST(0 AS BIT) AS  manual_mrp
,CAST(CASE WHEN CHARINDEX('@',A.PRODUCT_CODE)=0 THEN '' ELSE 
   (SUBSTRING(A.PRODUCT_CODE,CHARINDEX('@',A.PRODUCT_CODE)+1,15)) END AS VARCHAR(100))  AS BATCH_LOT_NO,
   S.BATCH_NO,S.EXPIRY_DT,CAST('' AS DATETIME) AS [rps_last_update],S.er_flag
	,CAST(0 AS BIT) AS barcodebased_flatdisc_applied,CAST(0 AS BIT) AS bngn_not_applied,CAST(0 AS BIT) AS happy_hours_applied,SN.sku_item_type AS  ITEM_TYPE,'' as scheme_name,SN.*
	FROM  RPS_DET  A (NOLOCK)  
	JOIN RPS_MST MST(NOLOCK) ON MST.cm_id=A.cm_id
	LEFT OUTER JOIN PMT01106 P (NOLOCK) ON A.PRODUCT_CODE = P.PRODUCT_CODE AND A.BIN_ID = P.BIN_ID   and mst.location_Code= P.dept_id
	LEFT OUTER JOIN BIN (NOLOCK) ON BIN.BIN_ID = A.BIN_ID   
	JOIN SKU S (NOLOCK) ON S.PRODUCT_CODE=A.PRODUCT_CODE  
  LEFT JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
	JOIN ARTICLE B (NOLOCK) ON S.ARTICLE_CODE = B.ARTICLE_CODE      
	JOIN UOM   E (NOLOCK) ON B.UOM_CODE = E.UOM_CODE   
	JOIN EMPLOYEE EMP (NOLOCK) ON A.EMP_CODE = EMP.EMP_CODE	
	LEFT OUTER JOIN EMPLOYEE EMP1  (NOLOCK) ON A.EMP_CODE1= EMP1.EMP_CODE     
	LEFT OUTER JOIN EMPLOYEE EMP2  (NOLOCK) ON A.EMP_CODE2= EMP2.EMP_CODE     
    LEFT OUTER JOIN SLSDET S1 (NOLOCK) ON S1.ROW_ID= A.SLSDET_ROW_ID 
	 LEFT OUTER JOIN CMM01106 CMM  (NOLOCK) ON CMM.CM_ID= MST.ref_cm_id   
	WHERE A.CM_ID=@CWHERE     
	ORDER BY  ROW_NUMBER() OVER (ORDER BY A.TS)      
	GOTO LAST  
   
LBLEMPLOYEE:  
  --SELECT EMP_CODE, EMP_NAME, EMP_NAME AS EMP_NAME_ORG,0 AS ALIASENTRY  
  --FROM EMPLOYEE   
  --      WHERE INACTIVE = 0   AND EMP_TYPE IN (1,3) 
  --      UNION   
  --      SELECT EMP_CODE, EMP_ALIAS AS EMP_NAME, EMP_NAME AS EMP_NAME_ORG,1 AS ALIASENTRY    
  --      FROM EMPLOYEE   
  --      WHERE INACTIVE = 0 AND EMP_ALIAS <>''   AND EMP_TYPE IN (1,3)
  --      ORDER BY EMP_NAME   
  --      GOTO LAST  
  SELECT A.EMP_CODE, EMP_NAME, EMP_NAME AS EMP_NAME_ORG,0 AS ALIASENTRY   
       FROM EMPLOYEE  A(NOLOCK) 
        JOIN EMP_GRP_LINK B (NOLOCK) ON A.emp_code=B.EMP_CODE 
        Join EMPLOYEE_GRP C on B.EMP_GRP_CODE = C.EMP_GRP_CODE 
        WHERE A.INACTIVE = 0    AND EMP_TYPE in (1,3) AND C.dept_id = @CWHERE 
        UNION   
        SELECT A.EMP_CODE, EMP_ALIAS AS EMP_NAME, EMP_NAME AS EMP_NAME_ORG,1 AS ALIASENTRY    
        FROM EMPLOYEE  A(NOLOCK) 
        JOIN EMP_GRP_LINK B (NOLOCK) ON A.emp_code=B.EMP_CODE  
        Join EMPLOYEE_GRP C on B.EMP_GRP_CODE = C.EMP_GRP_CODE 
        WHERE A.INACTIVE = 0 AND EMP_TYPE in (1,3) AND EMP_ALIAS <>''   AND C.dept_id = @CWHERE 
        ORDER BY EMP_NAME   
        GOTO LAST  
LBLPRODUCTINFO:  
  SELECT A.*,ARTICLE_NO,ARTICLE_NAME,B.UOM_NAME,P1.PARA1_NAME,P2.PARA2_NAME,P3.PARA3_NAME,   
        P4.PARA4_NAME,P5.PARA5_NAME,P6.PARA6_NAME,SD.SUB_SECTION_NAME,SM.SECTION_NAME,
        ART.ALIAS AS ARTICLE_ALIAS    
        FROM SKU A ---PMTVIEW A   --- OPTIMIZATION AFTER REMOVING VIEWS
        JOIN PARA1 P1 ON P1.PARA1_CODE=A.PARA1_CODE  
        JOIN PARA2 P2 ON P2.PARA2_CODE=A.PARA2_CODE  
        JOIN PARA3 P3 ON P3.PARA3_CODE=A.PARA3_CODE  
        JOIN PARA4 P4 ON P4.PARA4_CODE=A.PARA4_CODE  
        JOIN PARA5 P5 ON P5.PARA5_CODE=A.PARA5_CODE  
        JOIN PARA6 P6 ON P6.PARA6_CODE=A.PARA6_CODE  
        JOIN ARTICLE ART ON ART.ARTICLE_CODE=A.ARTICLE_CODE  
        JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=ART.SUB_SECTION_CODE  
        JOIN SECTIONM SM ON SM.SECTION_CODE=SD.SECTION_CODE  
        JOIN UOM B ON B.UOM_CODE=ART.UOM_CODE  
        WHERE A.PRODUCT_CODE=@CWHERE  
        GOTO LAST  
   
LBLADJCNLIST:   
        SELECT 1 AS SELECTED, A.CM_DT,A.CM_ID , A.CM_NO , 0 AS AMOUNT, C.CM_ID   AS [REF_CM_ID]
        FROM RPS_MST   A (NOLOCK) 
        JOIN CMM01106 C (NOLOCK) ON C.CM_ID=A.REF_CM_ID
        WHERE C.CM_ID=@CWHERE  AND A.CANCELLED = 0    
        GOTO LAST  
LBLSKU:  
	SELECT DISTINCT TOP 50 SKU.PRODUCT_CODE,ARTICLE_CODE,P.QUANTITY_IN_STOCK AS [QUANTITY],P.DEPT_ID
	FROM SKU  (NOLOCK)    
	JOIN PMT01106 P (NOLOCK) ON P.PRODUCT_CODE=SKU.PRODUCT_CODE  
	WHERE 1=2
  
   
  GOTO LAST  
LBLMEMOPRINT_MST:   
  EXEC SP_GETREPORTFORMAT 'PKS',1,@CWHERE,0  
  GOTO LAST  
LBLMEMOPRINT_DET:   
  EXEC SP_GETREPORTFORMAT 'PKS',2,@CWHERE,0  
  GOTO LAST   

LBLSCHEMEDETAILS:    
  SELECT A.* ,CAST(0 AS INT) AS SP_ID FROM CMD_SCHEME_DET A    
  JOIN RPS_DET B ON B.ROW_ID=A.CMD_ROW_ID     
  WHERE B.CM_ID=@CWHERE    
  
  GOTO LAST 

LBLCHKSTOCK:
   
   DECLARE @NPENDINGQTY NUMERIC(10,3),@NSTOCKQTY NUMERIC(10,3),@CERRORMSG VARCHAR(MAX)  
   
   SELECT @NPENDINGQTY=SUM(A.QUANTITY) 
   FROM RPS_DET A 
   JOIN RPS_MST B ON B.CM_ID=A.CM_ID   
   WHERE A.PRODUCT_CODE=@CWHERE 
   AND ISNULL(B.REF_CM_ID,'')=''
   AND  B.CM_ID<>@CREFMEMOID AND B.CANCELLED=0  
   
   SELECT @NSTOCKQTY=QUANTITY_IN_STOCK FROM PMT01106 WHERE PRODUCT_CODE=@CWHERE AND DEPT_ID=@CDEPTID  
   
   IF @NSTOCKQTY-ISNULL(@NPENDINGQTY,0)-@NQUANTITY<0  
		SET @CERRORMSG=' BAR CODE : '+@CWHERE+' QUANTITY IN STOCK IS GOING NEGATIVE'  
   ELSE  
		SET @CERRORMSG=''   
		
   SELECT @CERRORMSG AS ERRMSG  
   
   GOTO LAST	
LBLPACKSLIPREF:
  SELECT REF_CM_ID AS  CM_ID ,CM_ID AS  PACK_SLIP_ID, LAST_UPDATE FROM RPS_MST (NOLOCK) 
  WHERE CM_ID=@CWHERE AND  ISNULL(REF_CM_ID,'')<>''
  GOTO LAST 
  
  
LBLLASTEMP:
    
SELECT TOP 1 A.CM_ID ,A.EMP_CODE,A.EMP_CODE1,A.EMP_CODE2,ISNULL(EMP1.EMP_NAME,'') AS EMP_NAME,
ISNULL(EMP2.EMP_NAME,'') AS EMP_NAME1 ,ISNULL(EMP3.EMP_NAME,'') AS EMP_NAME2
FROM RPS_DET A (NOLOCK)
JOIN RPS_MST B (NOLOCK) ON A.CM_ID= B.CM_ID 
LEFT OUTER JOIN EMPLOYEE EMP1 ON EMP1.EMP_CODE=A.EMP_CODE
LEFT OUTER JOIN EMPLOYEE EMP2 ON EMP2.EMP_CODE=A.EMP_CODE1
LEFT OUTER JOIN EMPLOYEE EMP3 ON EMP3.EMP_CODE=A.EMP_CODE2
WHERE B.CANCELLED=0 AND A.QUANTITY>0 AND A.PRODUCT_CODE = @CWHERE
ORDER BY B.CM_DT DESC
  
  GOTO LAST 
  
LAST:  
  
END
