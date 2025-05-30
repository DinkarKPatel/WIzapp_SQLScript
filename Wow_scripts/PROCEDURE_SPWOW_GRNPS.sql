CREATE PROCEDURE SPWOW_GRNPS    
(
	@NQUERYID	NUMERIC(2,0),    
	@CWHERE		NVARCHAR(MAX),    
	@cLocId		CHAR(2)='',
	@cBINId		VARCHAR(100)='',
	@dtFrom		DATETIME='',
	@dtTo		DATETIME=''
)    
AS    
BEGIN    
 
DECLARE @CCMD NVARCHAR(MAX),@CERRMSG NVARCHAR(MAX),@CCURLOCID CHAR(2), @IMAXLEVEL INT ,@CXN_TYPE VARCHAR(100),
@AC_CODE VARCHAR(15),@cPOId VARCHAR(50),@cDBNAME VARCHAR(100)

SET @cDBNAME=DB_NAME()+'_IMAGE'


IF @NQUERYID = 1    
GOTO LBLSUPPLIERSLOV    

ELSE 
IF @NQUERYID = 2    
GOTO LBLGETMST    

ELSE IF @NQUERYID = 3    
GOTO LBLGETDETAILS 

ELSE IF @NQUERYID = 4    
GOTO LBLBINLIST 

ELSE IF @NQUERYID=5 
GOTO LBLPLIST

ELSE IF @NQUERYID=6
GOTO LBLPENDINGPRODUCTCODE

ELSE IF @NQUERYID=7
GOTO LBLGRNLIST  
ELSE IF @NQUERYID=71
GOTO LBLGRNLISTSUMMARY  
ELSE IF @NQUERYID=72
GOTO LBLGRNRACKDETAIL 
ELSE IF @NQUERYID=99
GOTO LBLCOLUMNLIST

ELSE    
GOTO LAST    

LBLBINLIST:
--EXEC SP_GETBINUSERS @CUSERCODE=@CWHERE, @CDEPT_ID=@cLocId
IF @CWHERE<>'0000000'
	BEGIN
		SELECT DISTINCT A.BIN_ID AS binId,A.BIN_NAME as binName,A.BIN_ALIAS AS binAlias,@CWHERE AS userCode, A.MAJOR_BIN_ID as majorBinId
		FROM BIN A (NOLOCK)
		JOIN BIN_LOC C (NOLOCK) ON C.BIN_ID=A.BIN_ID OR C.BIN_ID=A.major_bin_id
		JOIN BINUSERS B (NOLOCK) ON B.BIN_ID=A.BIN_ID OR B.BIN_ID=A.major_bin_id
		JOIN LOCATION D(NOLOCK) ON C.DEPT_ID= D.DEPT_ID
		WHERE /*A.BIN_ID= A.MAJOR_BIN_ID AND */ A.INACTIVE=0 AND B.USER_CODE =@CWHERE AND C.DEPT_ID=@cLocId  AND ISNULL(D.ENABLE_BIN,0)=1
		UNION 
		SELECT '000' AS BIN_ID,'DEFAULT BIN' AS BIN_NAME,'DB' AS BIN_ALIAS,@CWHERE AS [USER_CODE] ,'000' AS MAJOR_BIN_ID
		FROM LOCATION(NOLOCK) WHERE DEPT_ID=@cLocId AND ISNULL(ENABLE_BIN,0)=0
	END		
	ELSE
	BEGIN
		SELECT DISTINCT A.BIN_ID  AS binId,A.BIN_NAME  as binName,A.BIN_ALIAS  AS binAlias,@CWHERE AS userCode ,A.major_bin_id  as majorBinId
		FROM BIN A (NOLOCK)
		LEFT OUTER JOIN BIN_LOC C (NOLOCK) ON (C.BIN_ID=A.BIN_ID  OR C.BIN_ID=A.major_bin_id) AND C.DEPT_ID=@cLocId
		LEFT OUTER JOIN LOCATION D(NOLOCK) ON C.DEPT_ID= D.DEPT_ID
		WHERE /*A.BIN_ID= A.MAJOR_BIN_ID AND*/ A.INACTIVE=0 AND A.BIN_ID=(CASE WHEN C.DEPT_ID IS NULL THEN '000' ELSE A.BIN_ID END)
		AND ISNULL(C.DEPT_ID,@cLocId)=@cLocId AND ISNULL(D.ENABLE_BIN,0)=1
		UNION 
		SELECT '000' AS BIN_ID,'DEFAULT BIN' AS BIN_NAME,'DB' AS BIN_ALIAS,@CWHERE AS [USER_CODE] ,'000' AS MAJOR_BIN_ID
		FROM LOCATION (NOLOCK) WHERE DEPT_ID=@cLocId AND ISNULL(ENABLE_BIN,0)=0
		
	END

GOTO LAST    

LBLCOLUMNLIST:
	SELECT * FROM wow_map_Columns WHERE tablename = @CWHERE
GOTO LAST

LBLGRNLISTSUMMARY:
--;WITH ALL_BIN
--AS
--(
--	SELECT MEMO_ID,'' AS BIN_ID,'ALL BIN' BIN_NAME,NULL rack_category_code,null maxStock,SUM(QUANTITY) AS Quantity 
--	FROM GRN_PS_DET A (NOLOCK) 
--	WHERE MEMO_ID=@CWHERE 
--	GROUP BY MEMO_ID
--),
;WITH BINs
AS
(
--select * from Bin
--select * from rack_management_category_config
--SP_COLUMNS null,null,null,'rack_category_code',null
--select * from loc_delivery_racks
	SELECT MEMO_ID,A.BIN_ID as rackID,BIN_NAME,B.rack_category_code,B.maxStock, SUM(QUANTITY) AS Quantity,B.major_bin_id as zoneID,SUM(ISNULL(PMT.quantity_in_stock,0)) AS quantityInStock
	FROM GRN_PS_DET A (NOLOCK) 
	JOIN BIN B (NOLOCK) ON B.BIN_ID=A.BIN_ID
	LEFT OUTER JOIN PMT01106 PMT(NOLOCK) ON PMT.BIN_ID=A.BIN_ID AND PMT.DEPT_ID=LEFT(@CWHERE,2) AND A.PRODUCT_CODE=PMT.product_code
	WHERE MEMO_ID=@CWHERE 
	GROUP BY MEMO_ID,A.BIN_ID,B.BIN_NAME,B.rack_category_code,B.maxStock,B.major_bin_id
	--UNION ALL
	--SELECT MEMO_ID,BIN_ID,BIN_NAME,rack_category_code,maxStock, Quantity 
	--FROM ALL_BIN
),
BIN_CAT
AS
(
	SELECT A.SECTION_CODE as rack_category_code,A.SECTION_NAME as categoryName
	FROM sectionM A
	JOIN rack_management_category_config B ON 1=1
	WHERE baseTable='SectionM'AND selected = 1
	UNION ALL
	SELECT SUB_SECTION_CODE as rack_category_code,SUB_SECTION_NAME as categoryName
	FROM sectiond A
	JOIN rack_management_category_config B ON 1=1
	WHERE baseTable='SectionD'AND selected = 1

),
BIN_ZONE
AS
(
	Select  z.bin_id as zoneId,z.bin_name  as Zone
	From  bin z 
	where  (z.major_bin_id = z.BIN_ID)  or( z.rack_bin =1 )
)
SELECT A.MEMO_ID as grnPsId,A.MEMO_NO AS grnPsNo,A.MEMO_DT AS grnPsDt,A.CANCELLED as cancelled,A.REMARKS AS Remarks,A.TAT_DAYS AS tatDays,B.gate_entry_no AS refNo,X.BIN_NAME as binName,X.Quantity,X.rackId
,b.bilty_no as biltyNo,X.rack_category_code,X.maxStock,bc.categoryName,Z.Zone,Z.zoneID,X.quantityInStock
FROM GRN_PS_MST A (NOLOCK)
JOIN BINS X ON X.MEMO_ID=A.MEMO_ID
LEFT OUTER JOIN BIN_ZONE z on X.zoneid= z.zoneId
LEFT OUTER JOIN BIN_CAT BC ON BC.rack_category_code=X.rack_category_code
LEFT JOIN PARCEL_DET pd (NOLOCK) ON pd.row_id=A.REF_PARCEL_ROW_ID
LEFT JOIN PARCEL_MST B (NOLOCK) ON B.PARCEL_MEMO_ID =pd.PARCEL_MEMO_ID 

GOTO LAST

LBLGRNRACKDETAIL:


-- Did changes in this procedure due to showing double entry in Grn pack slip detail if same bar code
-- scanned more than once in a Grn . It should not be stored multiple times (Sanjay : 01-06-2023 )
-- and join of the below table in finally query with product code reurning multiple records due to this
-- which I changed to join of row id instead of product_code
CREATE TABLE #IMGDETAIL(row_id VARCHAR(100),barcode_img_id VARCHAR(100),PROD_IMAGE VARBINARY(MAX),PROD_IMAGE_BASE64 NVARCHAR(MAX))

INSERT INTO #IMGDETAIL(row_id ,barcode_img_id,PROD_IMAGE,PROD_IMAGE_BASE64	)
SELECT A.row_id,S.barcode_img_id,NULL,NULL
FROM GRN_PS_DET A (NOLOCK)        
JOIN SKU_NAMES S (NOLOCK)  ON A.PRODUCT_CODE = S.PRODUCT_CODE      
WHERE A.MEMO_ID =@CWHERE    AND (A.BIN_ID=@cBINId OR ISNULL(@cBINId,'')='')

IF DB_ID(@cDBNAME) IS NOT NULL
BEGIN
	SET @CCMD=N' UPDATE A SET A.PROD_IMAGE=B.PROD_IMAGE	,A.PROD_IMAGE_BASE64=CAST(N'''' AS XML).value(
          ''xs:base64Binary(xs:hexBinary(sql:column("B.PROD_IMAGE")))''
        , ''NVARCHAR(MAX)''
    )
		FROM #IMGDETAIL A
		LEFT OUTER JOIN '+@cDBNAME+'..IMAGE_INFO B (NOLOCK) ON B.IMG_ID=A.barcode_img_id'
	PRINT @cCMD
	EXEC SP_EXECUTESQL @CCMD
END


SELECT  A.*,     
S.SN_Uom_type uomType,  S.ARTICLE_NO as articleNo, S.ARTICLE_NAME AS articleName,  S.PARA1_NAME AS para1Name, S.PARA2_NAME AS para2Name, S.UOM uomName, I.AC_CODE,    
S.SUB_SECTION_NAME AS subSectionName, S.basic_purchase_price purchasePrice,     
S.PARA3_NAME AS para3Name, I.AC_NAME AS acName, S.SECTION_NAME sectionName, S.MRP,S.WS_PRICE AS WSP, S.sn_barcode_coding_scheme codingScheme, '' AS BRAND_NAME,     
S.PARA4_NAME AS para4Name, S.PARA5_NAME AS para5Name, S.PARA6_NAME AS para6Name, A.QUANTITY Quantity ,I.CITY AS City ,S.FIX_MRP AS fixMrp,  
S.sku_er_flag erFlag,S.STOCK_NA AS stockNa,S.ARTICLE_ALIAS AS articleAlias,
 CAST(CASE WHEN CHARINDEX('@',A.PRODUCT_CODE)=0 THEN '' ELSE 
(SUBSTRING(A.PRODUCT_CODE,CHARINDEX('@',A.PRODUCT_CODE)+1,15)) END  AS VARCHAR(100)) AS batchLotNo,
   S.BATCH_NO batchNo,S.EXPIRY_DT expiryDt ,ISNULL(BIN.BIN_NAME,'') AS binName,IMG.barcode_img_id,IMG.PROD_IMAGE,IMG.PROD_IMAGE_BASE64
FROM GRN_PS_DET A (NOLOCK)        
JOIN GRN_PS_MST A1 (NOLOCK) ON A1.MEMO_ID=A.MEMO_ID
JOIN SKU_NAMES S (NOLOCK)  ON A.PRODUCT_CODE = S.PRODUCT_CODE      
JOIN LMV01106 I (NOLOCK)  ON A1.AC_CODE = I.AC_CODE    
LEFT OUTER JOIN BIN (NOLOCK) ON BIN.BIN_ID=A.BIN_ID      
LEFT OUTER JOIN #IMGDETAIL IMG (NOLOCK) ON IMG.row_id=A.row_id
WHERE A.MEMO_ID =@CWHERE    AND (A.BIN_ID=@cBINId OR ISNULL(@cBINId,'')='')

GOTO LAST
LBLGRNLIST:
	SELECT A.MEMO_ID as grnPsId,I.AC_NAME as partyName,A.MEMO_NO AS grnPsNo,A.MEMO_DT AS grnPsDt,A.CANCELLED as cancelled,A.REMARKS AS Remarks,
	A.TOTAL_QUANTITY as totalQuantity,A.TAT_DAYS AS tatDays,B.gate_entry_no AS refNo,a.LAST_UPDATE as lastUpdate
	,A.AC_CODE as partyCode,A.ref_gateentry_memo_id AS refGateEntryMemoId,TRANSPORTER.ac_name as transporterName
	FROM GRN_PS_MST A (NOLOCK)
	JOIN LM01106 I (NOLOCK)  ON A.AC_CODE = I.AC_CODE    
	LEFT JOIN PARCEL_DET pd (NOLOCK) ON pd.row_id=A.REF_PARCEL_ROW_ID
	LEFT JOIN PARCEL_MST B (NOLOCK) ON B.PARCEL_MEMO_ID =pd.PARCEL_MEMO_ID 
	LEFT JOIN LM01106 TRANSPORTER (NOLOCK)  ON B.angadia_code = TRANSPORTER.AC_CODE    
	WHERE MEMO_DT BETWEEN @dtFrom AND @dtTo
GOTO LAST

LBLPLIST:
	--SELECT CAST(0 AS BIT) chk, ''  AS grnPsNo  ,A.PARCEL_MEMO_ID as parcelMemoId,PARCEL_MEMO_NO as parcelMemoNo,PARCEL_MEMO_DT as parcelMemoDt,
	--ISNULL(PARTY_INV_NO,'') partyInvNo,ISNULL(PARTY_INV_DT,'') partyInvDt,ISNULL(PARTY_INV_AMT,0) partyInvAmt,
	--(CASE WHEN XN_TYPE='DIR' THEN 'DIRECT' WHEN XN_TYPE='ASN' THEN 'ASN' WHEN XN_TYPE='PO' THEN 'PO(DIRECT)' ELSE '' END) AS refType
	--,A.gate_entry_no AS refNo,A.bilty_no as biltyNo,AN.Angadia_name as transporterName
	--FROM PARCEL_MST A(NOLOCK)
	--JOIN parcel_det   C (NOLOCK) ON C.PARCEL_MEMO_ID=A.PARCEL_MEMO_ID 
	--JOIN ANGM AN(NOLOCK) ON AN.ANGADIA_CODE=A.ANGADIA_CODE
	--LEFT JOIN GRN_PS_MST B(NOLOCK) ON c.row_id=B.REF_PARCEL_ROW_ID AND b.CANCELLED=0
	--WHERE  XN_TYPE IN ('GRN','DIR','ASN','PO') AND A.CANCELLED=0
	-- AND B.REF_PARCEL_ROW_ID IS NULL AND b.AC_CODE =@CWHERE

	SELECT CAST(0 AS BIT) chk, ''  AS grnPsNo ,A.PARCEL_MEMO_ID as parcelMemoId,PARCEL_MEMO_NO as parcelMemoNo,PARCEL_MEMO_DT as parcelMemoDt,
	ISNULL(PARTY_INV_NO,'') partyInvNo,ISNULL(PARTY_INV_DT,'') partyInvDt,ISNULL(PARTY_INV_AMT,0) partyInvAmt,
	(CASE WHEN XN_TYPE='DIR' THEN 'DIRECT' WHEN XN_TYPE='ASN' THEN 'ASN' WHEN XN_TYPE='PO' THEN 'PO(DIRECT)' ELSE '' END) AS refType
	,A.gate_entry_no AS refNo,A.bilty_no as biltyNo,AN.Angadia_name as transporterName,B.REF_PARCEL_ROW_ID
	FROM PARCEL_MST A(NOLOCK)
	JOIN parcel_det   C (NOLOCK) ON C.PARCEL_MEMO_ID=A.PARCEL_MEMO_ID 
	JOIN ANGM AN(NOLOCK) ON AN.ANGADIA_CODE=A.ANGADIA_CODE
	LEFT JOIN GRN_PS_MST B(NOLOCK) ON c.row_id=B.REF_PARCEL_ROW_ID AND b.CANCELLED=0
	WHERE  XN_TYPE IN ('GRN','DIR','ASN','PO') AND A.CANCELLED=0
	 AND B.ref_gateentry_memo_id IS NULL AND a.parcel_AC_CODE =@CWHERE

GOTO LAST

LBLSUPPLIERSLOV:    
	DECLARE @CHEADCODE VARCHAR(MAX),@CHEADCODE1 VARCHAR(MAX),@CHEADCODE2 VARCHAR(4000),@CHEADCODE3 VARCHAR(4000) 
	--SET @CHEADCODE=DBO.FN_ACT_TRAVTREE(@CWHERE)
	SELECT  A.AC_CODE as acCode, A.AC_NAME as acName, ISNULL(A.CREDIT_DAYS, 0) AS creditDays,       
	ISNULL(A.DISCOUNT_PERCENTAGE, 0) AS discountPercentage,      
	A.ADDRESS1 + ' ' + A.ADDRESS2 + ', ' + A.AREA_NAME + ' ' + A.CITY + ' ' +       
	A.STATE AS 'suppAddress', ISNULL(A.ON_HOLD,0) AS onHold     
	FROM LMV01106 A(NOLOCK)       
	WHERE ( CHARINDEX ( HEAD_CODE,@CHEADCODE ) > 0  OR ALLOW_CREDITOR_DEBTOR = 1 )       
	AND INACTIVE = 0 AND A.AC_NAME <> ''     
	UNION ALL      
	SELECT A.AC_CODE, ALIAS, ISNULL(A.CREDIT_DAYS, 0) ,       
	ISNULL(A.DISCOUNT_PERCENTAGE, 0)     ,   
	A.ADDRESS1 + ' ' + A.ADDRESS2 + ', ' + A.AREA_NAME + ' ' + A.CITY + ' ' +       
	A.STATE AS 'SUPP_ADDRESS',ISNULL(A.ON_HOLD,0) AS ON_HOLD     
	FROM LMV01106 A(NOLOCK)       
	WHERE ( CHARINDEX ( HEAD_CODE, @CHEADCODE ) > 0  OR ALLOW_CREDITOR_DEBTOR = 1 )       
	AND INACTIVE = 0 AND A.ALIAS <> ''     
	ORDER BY A.AC_NAME       

GOTO LAST    

LBLGETMST:   


SELECT  USERS.USERNAME as userName,  C.AC_NAME AS acName,     
C.ADDRESS1 + ' ' + C.ADDRESS2 + ', ' + C.AREA_NAME + ' ' + C.CITY + ' ' + C.STATE AS 'suppAddress',    
MST.*, CONVERT(CHAR(10),CASE WHEN MST.MEMO_DT='' THEN NULL ELSE MST.MEMO_DT END ,105)  AS RM_DT1,BIN_NAME,
PO_NO,ASN_MST.MEMO_NO AS ASN_NO,CAST( '' AS VARCHAR(50)) SP_ID ,
ISNULL(pm.parcel_memo_no,PARCEL_MST.PARCEL_MEMO_NO) as parcel_memo_no,CONVERT(BIT,0) AS parcel_closed,
'' as ref_parcel_memo_id,1 as mode ,pm.bilty_no
FROM GRN_PS_MST MST (NOLOCK)        
JOIN USERS (NOLOCK)  ON MST.USER_CODE = USERS.USER_CODE     
JOIN LMV01106 C(NOLOCK) ON MST.AC_CODE = C.AC_CODE  
JOIN BIN (NOLOCK) ON BIN.BIN_ID=MST.BIN_ID
LEFT JOIN POM01106(NOLOCK) ON POM01106.PO_ID=MST.PO_ID
LEFT JOIN ASN_MST(NOLOCK) ON ASN_MST.MEMO_ID=MST.ASN_MEMO_ID
LEFT JOIN PARCEL_DET pd (NOLOCK) ON pd.row_id=MST.REF_PARCEL_ROW_ID
LEFT JOIN PARCEL_MST (NOLOCK) ON PARCEL_MST.PARCEL_MEMO_ID =pd.PARCEL_MEMO_ID 
LEFT JOIN PARCEL_mst pm (NOLOCK) ON pm.parcel_memo_id= pd.parcel_memo_id
WHERE MST.MEMO_ID  =@CWHERE    

GOTO LAST    

LBLGETDETAILS:    

SELECT  A.*,     
RMM.CANCELLED,S.SN_Uom_type UOM_TYPE,  S.ARTICLE_NO, S.ARTICLE_NAME,  S.PARA1_NAME, S.PARA2_NAME, S.UOM UOM_NAME, I.AC_CODE,    
S.SUB_SECTION_NAME, S.basic_purchase_price PURCHASE_PRICE,     
S.PARA3_NAME, I.AC_NAME, S.SECTION_NAME, S.MRP,S.WS_PRICE AS WSP, S.sn_barcode_coding_scheme CODING_SCHEME, '' AS BRAND_NAME,     
S.PARA4_NAME, S.PARA5_NAME, S.PARA6_NAME, A.QUANTITY ,CAST( '' AS VARCHAR(50)) SP_ID,
I.CITY  ,S.FIX_MRP,  
S.sku_er_flag ER_FLAG,S.STOCK_NA,S.ARTICLE_ALIAS,
A.PRODUCT_CODE AS ORG_PRODUCT_CODE, 
 CAST(CASE WHEN CHARINDEX('@',A.PRODUCT_CODE)=0 THEN '' ELSE 
(SUBSTRING(A.PRODUCT_CODE,CHARINDEX('@',A.PRODUCT_CODE)+1,15)) END  AS VARCHAR(100)) AS BATCH_LOT_NO,
   S.BATCH_NO,S.EXPIRY_DT ,CAST (0 AS BIT) AS CHK,CAST( 0 AS NUMERIC(10,2)) AS PENDING_QTY,ISNULL(BIN.BIN_NAME,'') AS BIN_NAME
FROM GRN_PS_DET A (NOLOCK)        
JOIN GRN_PS_MST RMM (NOLOCK) ON A.MEMO_ID  = RMM.MEMO_ID         
JOIN SKU_NAMES S (NOLOCK)  ON A.PRODUCT_CODE = S.PRODUCT_CODE      
JOIN LMV01106 I (NOLOCK)  ON S.AC_CODE = I.AC_CODE    
LEFT OUTER JOIN BIN (NOLOCK) ON BIN.BIN_ID=A.BIN_ID          
WHERE A.MEMO_ID =@CWHERE          
GOTO LAST 
 
LBLPENDINGPRODUCTCODE:

   IF NOT EXISTS(SELECT TOP 1'U' FROM SKU_NAMES(NOLOCK) WHERE PRODUCT_CODE=@CWHERE)
		 SET @CERRMSG='PRODUCT CODE NOT FOUND'

	IF 	 ISNULL(@CERRMSG,'')=''
	BEGIN
	SELECT DISTINCT TOP 1 ISNULL(@CERRMSG,'') AS errmsg,SECTION_NAME as sectionName,SUB_SECTION_NAME as subSectionName,ARTICLE_NO as articleNo,PARA1_NAME as para1Name,PARA2_NAME as para2Name,PARA3_NAME para3Name,PARA4_NAME para4Name,
	PARA5_NAME para5Name,PARA6_NAME as para6Name,PRODUCT_CODE as productCode,sn_barcode_coding_scheme barcodeCodingScheme,sn_barcode_coding_scheme codingScheme,UOM uomName,SN_Uom_type uomType 
	FROM SKU_NAMES(NOLOCK)
	WHERE PRODUCT_CODE=@CWHERE
	END
	ELSE
	 SELECT ISNULL(@CERRMSG,'') AS errmsg

GOTO LAST    


LAST:    
END

/*
EXEC SP_GRNPS 6,'','','PP4AB8A7D0-DCCC-433C-B99A-A9434E2E3775','8960254400028 ',2,'222',0

select po_no, PO_RECEIVING_MODE, a.* from pod01106 a join pom01106 b on a.po_id=b.po_id
WHERE a.po_id='PP01119PP/PO/1819-000004' and product_code='8960254400028'

*/

