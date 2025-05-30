CREATE PROCEDURE SP3S_RETURN_STOCK_RECON_DET
(
	 @DFROM_DATE DATETIME
	,@DTO_DATE	DATETIME
	,@CMEMO_ID VARCHAR(30)
	,@NMODE NUMERIC(1) 
	,@CREPID VARCHAR(10)
)
--WITH ENCRYPTION 
AS
BEGIN
	DECLARE @CCOL_LIST VARCHAR(MAX),@CGROUP_COLS VARCHAR(MAX)
			,@CHAVING_COLS VARCHAR(MAX),@CTABLE_LIST VARCHAR(MAX)
			,@CCMD NVARCHAR(MAX),@CFROM_DATE VARCHAR(30),@CTO_DATE VARCHAR(30)
	
	SET @CFROM_DATE=CONVERT(VARCHAR,@DFROM_DATE,110)+' 00:00:00'
	SET @CTO_DATE=CONVERT(VARCHAR,@DTO_DATE,110)+' 23:59:59'


	DECLARE @IMG_SECTION BIT,@IMG_SUB_SECTION BIT,@IMG_ARTICLE BIT,@IMG_PARA1 BIT,@IMG_PARA2 BIT,@IMG_PARA3 BIT,@IMG_PARA4 BIT,@IMG_PARA5 BIT,@IMG_PARA6 BIT,@IMG_PRODUCT BIT
		SELECT @IMG_SECTION=SECTION,@IMG_SUB_SECTION=SUB_SECTION,@IMG_ARTICLE=ARTICLE        
		,@IMG_PARA1=PARA1 ,@IMG_PARA2=PARA2, @IMG_PARA3=PARA3,@IMG_PARA4=PARA4        
		,@IMG_PARA5=PARA5 ,@IMG_PARA6=PARA6, @IMG_PRODUCT=PRODUCT        
		FROM DBO.IMAGE_INFO_CONFIG WITH(NOLOCK)  

		declare @cCmdIMG varchar(max)

	set @cCmdIMG=''
	IF EXISTS (SELECT TOP 1 'U' FROM   STKRECON_COLLIST WHERE COLEXP='IMAGE' and REP_ID= @CREPID)
	begin
	   
       SET @cCmdIMG=N' LEFT OUTER JOIN ' + DB_NAME()+ '_IMAGE..IMAGE_INFO IMG (NOLOCK) ON 1=1 ' +
                            (CASE WHEN @IMG_SECTION = 1 THEN 'AND IMG.SECTION_CODE=sm.SECTION_CODE' ELSE ''  END) +
                            (CASE WHEN @IMG_SUB_SECTION = 1 THEN ' AND IMG.SUB_SECTION_CODE=sd.SUB_SECTION_CODE' ELSE '' END) +
                            (CASE WHEN @IMG_ARTICLE = 1 THEN ' AND IMG.ARTICLE_CODE=art.ARTICLE_CODE' ELSE '' END) +
                            (CASE WHEN @IMG_PARA1 = 1 THEN ' AND IMG.PARA1_CODE=sk.PARA1_CODE' ELSE '' END) +
                            (CASE WHEN @IMG_PARA2 = 1 THEN ' AND IMG.PARA2_CODE=sk.PARA2_CODE' ELSE '' END) +
                            (CASE WHEN @IMG_PARA3 = 1 THEN ' AND IMG.PARA3_CODE=sk.PARA3_CODE' ELSE '' END) +
                            (CASE WHEN @IMG_PARA4 = 1 THEN  ' AND IMG.PARA4_CODE=sk.PARA4_CODE' ELSE '' END) +
                            (CASE WHEN @IMG_PARA5 = 1 THEN  ' AND IMG.PARA5_CODE=sk.PARA5_CODE' ELSE '' END) +
                            (CASE WHEN @IMG_PARA6 = 1 THEN  ' AND IMG.PARA6_CODE=sk.PARA6_CODE' ELSE '' END) +
                            (CASE WHEN @IMG_PRODUCT = 1 THEN  'AND IMG.PRODUCT_CODE=sk.PRODUCT_CODE' ELSE '' END)
	end
	
	
	IF @NMODE=1
		GOTO LBL_GET_SCAN_DET
	ELSE IF @NMODE=2	
		GOTO LBL_GET_RECON_DET
	ELSE
		GOTO LBL_END_PROC	

LBL_GET_SCAN_DET:

	SELECT @CCOL_LIST=
	ISNULL(@CCOL_LIST,'')
	+(CASE WHEN COLEXP='PRODUCT_CODE' THEN 'SK.PRODUCT_CODE,'
		   WHEN COLEXP='MRP' THEN 'STD.MRP,'
		   WHEN COLEXP='PURCHASE_PRICE' THEN '(SK.PURCHASE_PRICE)  AS PURCHASE_PRICE,'
		   WHEN COLEXP='WS_PRICE' THEN 'SK.WS_PRICE,'
		   WHEN COLEXP='SCAN_QTY' THEN 'SUM(STD.Quantity) AS SCAN_QTY,'
		   WHEN COLEXP='SCAN_VALUE_AT_PP' THEN 'SUM(STD.Quantity*(SK.PURCHASE_PRICE  )) AS SCAN_VALUE_AT_PP,'
		   WHEN COLEXP='SCAN_VALUE_AT_MRP' THEN 'SUM(STD.Quantity*STD.MRP) AS SCAN_VALUE_AT_MRP,'
		   WHEN COLEXP='SCAN_VALUE_AT_WSP' THEN 'SUM(STD.Quantity*SK.WS_PRICE) AS SCAN_VALUE_AT_WSP,'
		   WHEN COLEXP='IMAGE' THEN 'IMG.IMG_ID IMAGE,'
		   ELSE COLEXP+',' END)
	FROM STKRECON_COLLIST WHERE REP_ID= @CREPID
	AND COLEXP NOT IN ('COMPUTER_QTY','SHORTAGE_QTY','EXCESS_QTY','COMPUTER_VALUE_AT_PP','COMPUTER_VALUE_AT_MRP','COMPUTER_VALUE_AT_WSP','SHORTAGE_VALUE_AT_PP','SHORTAGE_VALUE_AT_MRP',
'SHORTAGE_VALUE_AT_WSP','EXCESS_VALUE_AT_PP','EXCESS_VALUE_AT_MRP','EXCESS_VALUE_AT_WSP','EXCESS_QTY_REALIZED'
,'EXCESS_REALIZED_VALUE_AT_PP','EXCESS_REALIZED_VALUE_AT_MRP','EXCESS_REALIZED_VALUE_AT_WSP')
	ORDER BY COLORDER
	
	SET @CCOL_LIST=SUBSTRING(@CCOL_LIST,1,LEN(@CCOL_LIST)-1)

	SELECT @CGROUP_COLS=
	ISNULL(@CGROUP_COLS,'')
	+(CASE WHEN COLEXP='PRODUCT_CODE' THEN 'SK.PRODUCT_CODE,'WHEN COLEXP='MRP' THEN 'STD.MRP,'
		   WHEN COLEXP='PURCHASE_PRICE' THEN '(SK.PURCHASE_PRICE  ) ,'
		   WHEN COLEXP='WS_PRICE' THEN 'SK.WS_PRICE,'
		   WHEN COLEXP IN ('SCAN_QTY','SCAN_VALUE_AT_PP','SCAN_VALUE_AT_MRP','SCAN_VALUE_AT_WSP') THEN ''
		   WHEN COLEXP='IMAGE' THEN 'IMG.IMG_ID,'
		   ELSE COLEXP+',' END)
	FROM STKRECON_COLLIST WHERE REP_ID= @CREPID
	AND COLEXP NOT IN ('COMPUTER_QTY','SHORTAGE_QTY','EXCESS_QTY','COMPUTER_VALUE_AT_PP','COMPUTER_VALUE_AT_MRP','COMPUTER_VALUE_AT_WSP','SHORTAGE_VALUE_AT_PP','SHORTAGE_VALUE_AT_MRP',
'SHORTAGE_VALUE_AT_WSP','EXCESS_VALUE_AT_PP','EXCESS_VALUE_AT_MRP','EXCESS_VALUE_AT_WSP','EXCESS_QTY_REALIZED'
,'EXCESS_REALIZED_VALUE_AT_PP','EXCESS_REALIZED_VALUE_AT_MRP','EXCESS_REALIZED_VALUE_AT_WSP')
	ORDER BY COLORDER
	SET @CGROUP_COLS=SUBSTRING(@CGROUP_COLS,1,LEN(@CGROUP_COLS)-1)

	SET @CHAVING_COLS=' HAVING (SUM(STD.Quantity)<>0) '
	
	
	--SELECT * FROM stld01106 
	SET @CTABLE_LIST=' stlm01106 STM(NOLOCK)
	JOIN STMH01106 STMH(NOLOCK) ON STM.MEMO_ID=STMH.MEMO_ID
	JOIN STLD01106 STD(NOLOCK) ON STM.Lot_no=STD.Lot_no
	JOIN USERS USR(NOLOCK) ON STM.USER_CODE=USR.USER_CODE
	JOIN SKU SK (NOLOCK) ON STD.PRODUCT_CODE=SK.PRODUCT_CODE
	JOIN
	(
	   Select product_code as snProduct,attr1_key_name,attr2_key_name,attr3_key_name,attr4_key_name,attr5_key_name,
	   attr6_key_name,attr7_key_name,attr8_key_name,attr9_key_name,attr10_key_name,attr11_key_name,attr12_key_name,
	   attr13_key_name,attr14_key_name,attr15_key_name,attr16_key_name,attr17_key_name,attr18_key_name,attr19_key_name,
	   attr20_key_name,attr21_key_name,attr22_key_name,attr23_key_name,attr24_key_name,attr25_key_name
	   FROM  SKU_NAMES SN (NOLOCK) 
	) SN ON SK.PRODUCT_CODE=SN.snProduct
	LEFT OUTER JOIN SKU_OH  ON SK.PRODUCT_CODE = SKU_OH.PRODUCT_CODE 
    LEFT OUTER JOIN FORM FF ON SK.FORM_ID = FF.FORM_ID 
	JOIN ARTICLE ART(NOLOCK) ON SK.ARTICLE_CODE=ART.ARTICLE_CODE
	JOIN PARA1 P1(NOLOCK) ON SK.PARA1_CODE=P1.PARA1_CODE
	JOIN PARA2 P2(NOLOCK) ON SK.PARA2_CODE=P2.PARA2_CODE
	JOIN PARA3 P3(NOLOCK) ON SK.PARA3_CODE=P3.PARA3_CODE
	JOIN PARA4 P4(NOLOCK) ON SK.PARA4_CODE=P4.PARA4_CODE
	JOIN PARA5 P5(NOLOCK) ON SK.PARA5_CODE=P5.PARA5_CODE
	JOIN PARA6 P6(NOLOCK) ON SK.PARA6_CODE=P6.PARA6_CODE
	JOIN SECTIOND SD(NOLOCK) ON ART.SUB_SECTION_CODE=SD.SUB_SECTION_CODE
	JOIN SECTIONM SM(NOLOCK) ON SD.SECTION_CODE=SM.SECTION_CODE	  
	JOIN UOM U1(NOLOCK) ON ART.UOM_CODE=U1.UOM_CODE
	JOIN LM01106 LM(NOLOCK) ON LM.AC_CODE=SK.AC_CODE 
	JOIN BIN (NOLOCK) ON BIN.BIN_ID=STD.BIN_ID 
	'
	+@cCmdIMG +' 
	WHERE STD.BIN_ID <> ''999'' AND STM.LAST_UPDATE BETWEEN '''+@CFROM_DATE+''' AND '''+@CTO_DATE+'''
	AND STM.memo_id='''+@CMEMO_ID+''''
	
	SET @CCMD=N'SELECT '+@CCOL_LIST+' FROM '+@CTABLE_LIST+' GROUP BY '+@CGROUP_COLS+@CHAVING_COLS+' ORDER BY '+@CGROUP_COLS
	PRINT @CCMD
	EXECUTE SP_EXECUTESQL @CCMD
	
	GOTO LBL_END_PROC
	--SK.PURCHASE_PRICE
	
LBL_GET_RECON_DET:


	SELECT @CCOL_LIST=ISNULL(@CCOL_LIST,'')
	+(CASE WHEN COLEXP='PRODUCT_CODE' THEN 'SK.PRODUCT_CODE,'
		   WHEN COLEXP='MRP' THEN 'STD.MRP,'
		   WHEN COLEXP='BIN_ID' THEN 'bin.BIN_ID,'
		   WHEN COLEXP='PURCHASE_PRICE' THEN '(SK.PURCHASE_PRICE ) AS PURCHASE_PRICE,'
		   WHEN COLEXP='WS_PRICE' THEN 'SK.WS_PRICE,'
		   WHEN COLEXP IN ('SCAN_QTY','COMPUTER_QTY','SHORTAGE_QTY','EXCESS_QTY','EXCESS_QTY_REALIZED') 
		   THEN 'SUM(STD.'+COLEXP+') AS '+COLEXP+','
		   
		   WHEN COLEXP='SCAN_VALUE_AT_PP' THEN 'SUM(STD.SCAN_QTY*(SK.PURCHASE_PRICE  )) AS SCAN_VALUE_AT_PP,'
		   WHEN COLEXP='SCAN_VALUE_AT_MRP' THEN 'SUM(STD.SCAN_QTY*STD.MRP) AS SCAN_VALUE_AT_MRP,'
		   WHEN COLEXP='SCAN_VALUE_AT_WSP' THEN 'SUM(STD.SCAN_QTY*SK.WS_PRICE) AS SCAN_VALUE_AT_WSP,'
		   
		   WHEN COLEXP='COMPUTER_VALUE_AT_PP' THEN 'SUM(STD.COMPUTER_QTY*(SK.PURCHASE_PRICE  )) AS COMPUTER_VALUE_AT_PP,'
		   WHEN COLEXP='COMPUTER_VALUE_AT_MRP' THEN 'SUM(STD.COMPUTER_QTY*STD.MRP) AS COMPUTER_VALUE_AT_MRP,'
		   WHEN COLEXP='COMPUTER_VALUE_AT_WSP' THEN 'SUM(STD.COMPUTER_QTY*SK.WS_PRICE) AS COMPUTER_VALUE_AT_WSP,'
		   
		   WHEN COLEXP='SHORTAGE_VALUE_AT_PP' THEN 'SUM(STD.SHORTAGE_QTY*(SK.PURCHASE_PRICE )) AS SHORTAGE_VALUE_AT_PP,'
		   WHEN COLEXP='SHORTAGE_VALUE_AT_MRP' THEN 'SUM(STD.SHORTAGE_QTY*STD.MRP) AS SHORTAGE_VALUE_AT_MRP,'
		   WHEN COLEXP='SHORTAGE_VALUE_AT_WSP' THEN 'SUM(STD.SHORTAGE_QTY*SK.WS_PRICE) AS SHORTAGE_VALUE_AT_WSP,'
		   
		   WHEN COLEXP='EXCESS_VALUE_AT_PP' THEN 'SUM(STD.EXCESS_QTY*(SK.PURCHASE_PRICE   )) AS EXCESS_VALUE_AT_PP,'
		   WHEN COLEXP='EXCESS_VALUE_AT_MRP' THEN 'SUM(STD.EXCESS_QTY*STD.MRP) AS EXCESS_VALUE_AT_MRP,'
		   WHEN COLEXP='EXCESS_VALUE_AT_WSP' THEN 'SUM(STD.EXCESS_QTY*SK.WS_PRICE) AS EXCESS_VALUE_AT_WSP,'
		   
		   WHEN COLEXP='EXCESS_REALIZED_VALUE_AT_PP' THEN 'SUM(STD.EXCESS_QTY_REALIZED*SK.PURCHASE_PRICE) AS EXCESS_REALIZED_VALUE_AT_PP,'
		   WHEN COLEXP='EXCESS_REALIZED_VALUE_AT_MRP' THEN 'SUM(STD.EXCESS_QTY_REALIZED*STD.MRP) AS EXCESS_REALIZED_VALUE_AT_MRP
,'
		   WHEN COLEXP='EXCESS_REALIZED_VALUE_AT_WSP' THEN 'SUM(STD.EXCESS_QTY_REALIZED*SK.WS_PRICE) AS EXCESS_REALIZED_VALUE_AT_WSP,'
		   WHEN COLEXP='IMAGE' THEN 'IMG.IMG_ID,'''' IMAGE,'
		   ELSE COLEXP+',' END)
	FROM STKRECON_COLLIST WHERE REP_ID= @CREPID
	ORDER BY COLORDER
	SET @CCOL_LIST=ISNULL(@CCOL_LIST,'')
	IF RIGHT(@CCOL_LIST,1)=','
	   SET @CCOL_LIST=SUBSTRING(@CCOL_LIST,1,LEN(@CCOL_LIST)-1)
	

	SELECT @CGROUP_COLS=
	ISNULL(@CGROUP_COLS,'')
	+(CASE WHEN COLEXP='PRODUCT_CODE' THEN 'SK.PRODUCT_CODE,'
	       WHEN COLEXP='BIN_ID' THEN 'bin.BIN_ID,'
		   WHEN COLEXP='MRP' THEN 'STD.MRP,'
		   WHEN COLEXP='PURCHASE_PRICE' THEN '(SK.PURCHASE_PRICE  ) ,'
		   WHEN COLEXP='WS_PRICE' THEN 'SK.WS_PRICE,'
		   WHEN COLEXP IN ('SCAN_QTY','SCAN_VALUE_AT_PP','SCAN_VALUE_AT_MRP','SCAN_VALUE_AT_WSP','COMPUTER_QTY','COMPUTER_VALUE_AT_PP','COMPUTER_VALUE_AT_MRP'
						  ,'COMPUTER_VALUE_AT_WSP','SHORTAGE_QTY','SHORTAGE_VALUE_AT_PP','SHORTAGE_VALUE_AT_MRP','SHORTAGE_VALUE_AT_WSP'
						  ,'EXCESS_QTY','EXCESS_VALUE_AT_PP','EXCESS_VALUE_AT_MRP','EXCESS_VALUE_AT_WSP','EXCESS_QTY_REALIZED'
						  ,'EXCESS_REALIZED_VALUE_AT_PP','EXCESS_REALIZED_VALUE_AT_MRP','EXCESS_REALIZED_VALUE_AT_WSP') 
				THEN ''
		   WHEN COLEXP='IMAGE' THEN 'IMG.IMG_ID,'
		   ELSE COLEXP+',' END)
	FROM STKRECON_COLLIST WHERE REP_ID= @CREPID
	SET @CGROUP_COLS=ISNULL(@CGROUP_COLS,'')
	
	
	IF RIGHT(@CGROUP_COLS,1)=','
	   SET @CGROUP_COLS=SUBSTRING(@CGROUP_COLS,1,LEN(@CGROUP_COLS)-1)
	
	
	
	SELECT @CHAVING_COLS=ISNULL(@CHAVING_COLS,'')
	+(CASE WHEN COLEXP IN ('SCAN_QTY','COMPUTER_QTY','SHORTAGE_QTY','EXCESS_QTY','EXCESS_QTY_REALIZED') THEN ' SUM(STD.'+COLEXP+')<>0 OR ' 
	       ELSE '' END)
	FROM STKRECON_COLLIST WHERE REP_ID= @CREPID
	ORDER BY COLORDER
	SET @CHAVING_COLS=ISNULL(@CHAVING_COLS,'')
	IF @CHAVING_COLS>''
	   SET @CHAVING_COLS=' HAVING ('+SUBSTRING(@CHAVING_COLS,1,LEN(@CHAVING_COLS)-2)+') '


	
	SET @CTABLE_LIST='	Stmh01106 STM(NOLOCK)
	JOIN stockReconDetails STD (NOLOCK) ON STM.Memo_Id=STD.Memo_Id
	JOIN USERS USR(NOLOCK) ON STM.USER_CODE=USR.USER_CODE
	JOIN SKU SK(NOLOCK) ON STD.PRODUCT_CODE=SK.PRODUCT_CODE
	JOIN
	(
	   Select product_code as snProduct,attr1_key_name,attr2_key_name,attr3_key_name,attr4_key_name,attr5_key_name,
	   attr6_key_name,attr7_key_name,attr8_key_name,attr9_key_name,attr10_key_name,attr11_key_name,attr12_key_name,
	   attr13_key_name,attr14_key_name,attr15_key_name,attr16_key_name,attr17_key_name,attr18_key_name,attr19_key_name,
	   attr20_key_name,attr21_key_name,attr22_key_name,attr23_key_name,attr24_key_name,attr25_key_name
	   FROM  SKU_NAMES SN (NOLOCK) 
	) SN ON SK.PRODUCT_CODE=SN.snProduct
	LEFT OUTER JOIN SKU_OH  ON SK.PRODUCT_CODE = SKU_OH.PRODUCT_CODE 
    LEFT OUTER JOIN FORM FF ON SK.FORM_ID = FF.FORM_ID 
	JOIN ARTICLE ART(NOLOCK) ON SK.ARTICLE_CODE=ART.ARTICLE_CODE
	JOIN PARA1 P1(NOLOCK) ON SK.PARA1_CODE=P1.PARA1_CODE
	JOIN PARA2 P2(NOLOCK) ON SK.PARA2_CODE=P2.PARA2_CODE
	JOIN PARA3 P3(NOLOCK) ON SK.PARA3_CODE=P3.PARA3_CODE
	JOIN PARA4 P4(NOLOCK) ON SK.PARA4_CODE=P4.PARA4_CODE
	JOIN PARA5 P5(NOLOCK) ON SK.PARA5_CODE=P5.PARA5_CODE
	JOIN PARA6 P6(NOLOCK) ON SK.PARA6_CODE=P6.PARA6_CODE
	JOIN SECTIOND SD(NOLOCK) ON ART.SUB_SECTION_CODE=SD.SUB_SECTION_CODE
	JOIN SECTIONM SM(NOLOCK) ON SD.SECTION_CODE=SM.SECTION_CODE	  
	JOIN UOM U1(NOLOCK) ON ART.UOM_CODE=U1.UOM_CODE
	JOIN LM01106 LM(NOLOCK) ON LM.AC_CODE=SK.AC_CODE 
	JOIN BIN (NOLOCK) ON BIN.BIN_ID=STD.BIN_ID
	'
	+@cCmdIMG +' 
	WHERE STD.BIN_ID <> ''999'' AND STM.memo_id='''+@CMEMO_ID+''''
	
	SET @CCMD=N'SELECT '+@CCOL_LIST+' FROM '+@CTABLE_LIST+' GROUP BY '+@CGROUP_COLS+@CHAVING_COLS+' ORDER BY '+@CGROUP_COLS
	
	EXECUTE SP_EXECUTESQL @CCMD
	print @CCMD
	
	GOTO LBL_END_PROC		

LBL_END_PROC:
END




