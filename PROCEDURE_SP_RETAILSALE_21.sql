CREATE PROCEDURE SP_RETAILSALE_21--(LocId 3 digit change by Sanjay:30-10-2024)
(  
	 @CQUERYID			NUMERIC(2)=0,  
	 @CWHERE			VARCHAR(MAX)='',  
	 @CFINYEAR			VARCHAR(5)='',  
	 @CDEPTID			VARCHAR(4)='',  
	 @NNAVMODE			NUMERIC(2)=1,  
	 @CWIZAPPUSERCODE	VARCHAR(10)='',  
	 @CREFMEMOID		VARCHAR(40)='',  
	 @CREFMEMODT		DATETIME='',  
	 @BINCLUDEESTIMATE	BIT=1,  
	 @CFROMDT			DATETIME='',  
	 @CTODT				VARCHAR(50)='',
	 @bCardDiscount		BIT=0,
	 @cCustCode			VARCHAR(15)='',
	 @bCalledFromRPS	BIT=0
) 
AS  
BEGIN  


	DECLARE @DISCOUNT_PICKMODE_SLR VARCHAR(10),@NPICKLASTSLSDISC int,@cLocationId VARCHAR(4)
	SET @NPICKLASTSLSDISC=1       

	select @cLocationId=@CDEPTID 
	SELECT TOP 1 @DISCOUNT_PICKMODE_SLR=ISNULL(DISCOUNT_PICKMODE_SLR,1) from location WHERE dept_id=@CLOCATIONID

	IF ISNULL( @DISCOUNT_PICKMODE_SLR,0 )=3 --- No need to Pick Last sale discount if Current Scheme discount is marked 
		SET @NPICKLASTSLSDISC=0				--- in Location master for Return discount picking method

	DECLARE @CCMD NVARCHAR(MAX)=''
	DECLARE @dtable TABLE (DBNAME VARCHAR(100),CHECKED BIT)
	DECLARE @dtable_20 TABLE (CM_ID VARCHAR(100))
	DECLARE @dtable_21 TABLE (CMM_CM_ID VARCHAR(100),CMD_PRODUCT_CODE VARCHAR(100))
	DECLARE @dbNAME VARCHAR(100),@BALLOWNEGSTOCK VARCHAR(5)

	SELECT @BALLOWNEGSTOCK =VALUE FROM USER_ROLE_DET A (NOLOCK)--ADDED
		JOIN USERS B (NOLOCK)--ADDED
		ON A.ROLE_ID=B.ROLE_ID 
		WHERE USER_CODE=@CWIZAPPUSERCODE 
		AND FORM_NAME='FRMSALE' 
		AND FORM_OPTION='ALLOW_NEG_STOCK'		

	 SELECT  SR_NO AS 'SRNO',CAST(0   AS BIT) AS BILLCHECK,b.discount_percentage as last_sls_discount_percentage,
	 A.CM_NO,A.CM_DT,A.CM_ID,A.CM_ID AS REF_SLS_MEMO_ID,A.CM_NO as ref_sls_memo_no,A.CM_DT as ref_sls_memo_dt,B.PRODUCT_CODE,AR.ARTICLE_NO,B.QUANTITY,E.UOM_NAME,  
	 b.MRP,B.OLD_MRP,B.basic_DISCOUNT_PERCENTAGE,b.basic_DISCOUNT_AMOUNT, b.net,  
	 EMP.EMP_NAME,A.DISCOUNT_PERCENTAGE AS DISC_PERMM,A.DISCOUNT_AMOUNT AS DISC_AMTMM,A.NET_AMOUNT AS AMTM,  AR.ARTICLE_CODE ,
	 C.PARA1_CODE,C.PARA1_NAME, D.PARA2_CODE, D.PARA2_NAME, F.PARA3_CODE, F.PARA3_NAME, B.DEPT_ID,   
	 sku.barcode_CODING_SCHEME as CODING_SCHEME,  AR.INACTIVE, ISNULL(P.QUANTITY_IN_STOCK,0) AS QUANTITY_IN_STOCK,SKU.PURCHASE_PRICE,  
	 SKU.WS_PRICE,     weighted_avg_disc_pct,manual_dp,b.manual_discount,
	 SM.SECTION_NAME, SD.SUB_SECTION_NAME,G.PARA4_CODE,H.PARA5_CODE,I.PARA6_CODE,PARA4_NAME,PARA5_NAME,  
	 PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],AR.DT_CREATED AS [ART_DT_CREATED],  
	 F.DT_CREATED AS [PARA3_DT_CREATED],SKU.DT_CREATED AS [SKU_DT_CREATED],AR.STOCK_NA,  
	 CONVERT (BIT,(CASE WHEN B.QUANTITY <0 THEN 1 ELSE 0 END)) AS SALERETURN ,CAST(0 AS BIT) AS CREDIT_REFUND,  
	 '' AS HOLD_ID,'' AS CMD_HOLD_ROW_ID,EMP.EMP_CODE ,SKU.PRODUCT_NAME, 
	  EMP1.EMP_CODE AS EMP_CODE1,EMP1.EMP_NAME AS EMP_NAME1 ,EMP2.EMP_CODE AS EMP_CODE2,EMP2.EMP_NAME AS EMP_NAME2  ,(CASE WHEN ISNULL(SKU.FIX_MRP,0)=0 THEN SKU.mrp ELSE SKU.FIX_MRP END) AS [FIX_MRP],
	 'N' AS [HOLD_FOR_ALTER_TXT],AR.ALIAS AS ARTICLE_ALIAS ,b.tax_percentage,b.tax_method,b.tax_amount,
	 B.CARD_DISCOUNT_AMOUNT  AS card_discount_amount,
	 B.card_discount_percentage as card_discount_percentage,b.scheme_name last_applied_scheme_name,
	 B.DISCOUNT_AMOUNT AS DISCOUNT_AMOUNT,B.discount_percentage,  
	 b.hsn_code,'Exclusive' As Tax_method_type,B.GST_PERCENTAGE,b.OLD_NET ,a.PATCHUP_RUN,b.old_cmm_discount_amount,convert(numeric(1,0),0) scenarioype,
	 B.PCS_QUANTITY,B.MTR_QUANTITY,B.manual_discount_amount,B.manual_discount_percentage,b.weighted_avg_disc_amt,b.cmm_discount_amount,CONVERT(VARCHAR(10),'') ecouponCampaignCode,AR.ARTICLE_PACK_SIZE
	 INTO #tmpLastSls FROM CMD01106 B (NOLOCK)   
	 JOIN CMM01106 A (NOLOCK) ON B.CM_ID=A.CM_ID   
	 LEFT OUTER JOIN PMT01106 P (NOLOCK) ON P.PRODUCT_CODE=B.PRODUCT_CODE AND b.BIN_ID=p.BIN_ID AND a.location_Code=P.DEPT_ID 
	 JOIN  SKU (NOLOCK) ON SKU.PRODUCT_CODE=b.PRODUCT_CODE   
	 JOIN  ARTICLE AR (NOLOCK) ON SKU.ARTICLE_CODE =AR.ARTICLE_CODE   
	 JOIN SECTIOND SD (NOLOCK) ON AR.SUB_SECTION_CODE = SD.SUB_SECTION_CODE   
	 JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE   
	 JOIN PARA1 C (NOLOCK) ON SKU.PARA1_CODE = C.PARA1_CODE   
	 JOIN PARA2 D (NOLOCK) ON SKU.PARA2_CODE = D.PARA2_CODE   
	 JOIN PARA3 F (NOLOCK) ON SKU.PARA3_CODE = F.PARA3_CODE   
	 JOIN PARA4 G (NOLOCK) ON SKU.PARA4_CODE = G.PARA4_CODE   
	 JOIN PARA5 H (NOLOCK) ON SKU.PARA5_CODE = H.PARA5_CODE   
	 JOIN PARA6 I (NOLOCK) ON SKU.PARA6_CODE = I.PARA6_CODE   
	 JOIN  UOM E (NOLOCK) ON AR.UOM_CODE = E.UOM_CODE   
	 LEFT OUTER JOIN EMPLOYEE EMP (NOLOCK) ON EMP.EMP_CODE=B.EMP_CODE
	 LEFT OUTER JOIN EMPLOYEE EMP1  (NOLOCK) ON B.EMP_CODE1 = EMP1.EMP_CODE     
	 LEFT OUTER JOIN EMPLOYEE EMP2  (NOLOCK) ON B.EMP_CODE2 = EMP2.EMP_CODE 
	 WHERE 1=2
	
	--Commented this line because we need not to run dynamic statement in case of current database query
	--as it is giving some error of syntax in dynamic statement (Date:13-07-2023 , Sanjay)
	--INSERT INTO @dtable(DBNAME,CHECKED)
	--SELECT DB_NAME() AS NAME,CAST(0 AS INT) AS CHECKED 
	INSERT INTO @dtable(DBNAME,CHECKED)
	SELECT NAME, CAST(0 AS INT) AS CHECKED 
	FROM SYS.DATABASES 
	WHERE (NAME LIKE DB_NAME()+'[_]011[0-9][0-9]')
	ORDER BY CAST(RIGHT(NAME,3) AS INT) DESC
	--SELECT * FROM @dtable
	/*Rohit : 13-09-2024
	Taiga : #479 Reg : Nagarmal : New Cashmemo
	When scan return barcode show popup for multiple bill details, need searching option against bill no. in this window.
	IF ISNULL(@CREFMEMOID,'')<>''
	BEGIN
		SET @cCMD=N'SELECT CM_ID,PRODUCT_CODE 
		FROM CMD01106 
		WHERE QUANTITY>0 AND CM_ID LIKE ''%'+ISNULL(@CREFMEMOID,'') +''''
		
		print @CCMD

		INSERT INTO @dtable_21(CMM_CM_ID, CMD_PRODUCT_CODE)
		EXEC SP_EXECUTESQL @cCMD

	END
	*/
	INSERT INTO @dtable_21(CMM_CM_ID, CMD_PRODUCT_CODE)
	SELECT DISTINCT CM_ID,PRODUCT_CODE
	FROM
	(
		SELECT B.CM_ID,B.PRODUCT_CODE
		FROM CMD01106 B
		WHERE (B.PRODUCT_CODE=@CWHERE or B.PRODUCT_CODE like @CWHERE+'@%')
		 and b.QUANTITY>0 AND b.cm_id<>'XXXXXXXXXX'
		 AND ISNULL(@CWHERE,'')<>'' AND ISNULL(@CREFMEMOID,'')=''
		UNION
		SELECT CM_ID,PRODUCT_CODE 
		FROM CMD01106 
		WHERE CM_ID=ISNULL(@CREFMEMOID,'') and QUANTITY>0
	)X
	left outer join @dtable_21 b on b.CMM_CM_ID=X.cm_id
	WHERE b.CMM_CM_ID IS NULL

		INSERT INTO #tmpLastSls (SRNO,BILLCHECK,CM_NO,CM_DT,CM_ID,REF_SLS_MEMO_ID,ref_sls_memo_no,ref_sls_memo_dt,
		PRODUCT_CODE,ARTICLE_NO,QUANTITY,MRP,OLD_MRP,basic_DISCOUNT_PERCENTAGE,basic_DISCOUNT_AMOUNT,
		NET,EMP_NAME,DISC_PERMM,DISC_AMTMM,AMTM,ARTICLE_CODE ,PARA1_CODE,PARA1_NAME,PARA2_CODE,PARA2_NAME,PARA3_CODE,PARA3_NAME, 
		UOM_NAME,DEPT_ID,CODING_SCHEME,INACTIVE,QUANTITY_IN_STOCK,PURCHASE_PRICE,WS_PRICE,     
		SECTION_NAME,SUB_SECTION_NAME,PARA4_CODE,PARA5_CODE,PARA6_CODE,PARA4_NAME,PARA5_NAME,  
		PARA6_NAME,UOM_CODE,[UOM_TYPE],ART_DT_CREATED,[PARA3_DT_CREATED],SKU_DT_CREATED,STOCK_NA,  
		SALERETURN ,CREDIT_REFUND,HOLD_ID,CMD_HOLD_ROW_ID,EMP_CODE ,PRODUCT_NAME, 
		EMP_CODE1,EMP_NAME1 ,EMP_CODE2,EMP_NAME2,[FIX_MRP],[HOLD_FOR_ALTER_TXT],ARTICLE_ALIAS,
		tax_percentage,tax_method,tax_amount,card_discount_amount,card_discount_percentage,
		DISCOUNT_AMOUNT,discount_percentage,last_sls_discount_percentage,last_applied_scheme_name,HSN_CODE,
		Tax_method_type,gst_percentage,OLD_NET ,PATCHUP_RUN,old_cmm_discount_amount,PCS_QUANTITY,MTR_QUANTITY,manual_discount_amount,manual_discount_percentage,
		manual_discount,manual_dp,weighted_avg_disc_pct,weighted_avg_disc_amt,cmm_discount_amount,ecouponCampaignCode,ARTICLE_PACK_SIZE )
		
		SELECT  SR_NO AS 'SRNO',CAST((CASE WHEN B.PRODUCT_CODE=@CWHERE THEN 1 ELSE  0 END)  AS BIT) AS BILLCHECK,
		 A.CM_NO,A.CM_DT,A.CM_ID,A.CM_ID AS REF_SLS_MEMO_ID,A.CM_NO as ref_sls_memo_no,A.CM_DT as ref_sls_memo_dt,
		 B.PRODUCT_CODE,AR.ARTICLE_NO,B.QUANTITY,
		 (CASE WHEN ISNULL(X.VALUE,'0')='1' THEN B.MRP WHEN B.OLD_MRP = 0 THEN B.MRP ELSE B.OLD_MRP END) AS MRP,B.OLD_MRP,
		  CASE WHEN @NPICKLASTSLSDISC=1 THEN  B.basic_DISCOUNT_PERCENTAGE+isnull(b.manual_discount_percentage,0) ELSE 0 END  AS basic_DISCOUNT_PERCENTAGE,
		  CASE WHEN @NPICKLASTSLSDISC=1 THEN  (CASE WHEN isnull(b.old_mrp,0)=0 or b.old_mrp=b.mrp THEN B.basic_DISCOUNT_AMOUNT+isnull(b.manual_discount_amount,0) ELSE ((B.QUANTITY * B.OLD_MRP) *
		  (B.basic_DISCOUNT_PERCENTAGE+isnull(b.manual_discount_percentage,0)))/100  END) ELSE 0 END  AS basic_DISCOUNT_AMOUNT,
		 (CASE WHEN isnull(b.old_mrp,0)=0 or b.old_mrp=b.mrp THEN B.NET ELSE ((B.QUANTITY * B.OLD_MRP)-((B.QUANTITY * B.OLD_MRP) * B.DISCOUNT_PERCENTAGE)/100 ) END) AS NET,  
		 EMP.EMP_NAME,A.DISCOUNT_PERCENTAGE AS DISC_PERMM,A.DISCOUNT_AMOUNT AS DISC_AMTMM,A.NET_AMOUNT AS AMTM,   AR.ARTICLE_CODE ,
		 C.PARA1_CODE,C.PARA1_NAME, D.PARA2_CODE, D.PARA2_NAME, F.PARA3_CODE, F.PARA3_NAME, E.UOM_NAME,B.DEPT_ID,   
		 sku.barcode_CODING_SCHEME as CODING_SCHEME,  AR.INACTIVE, ISNULL(P.QUANTITY_IN_STOCK,0) AS QUANTITY_IN_STOCK,
		 SKU.PURCHASE_PRICE,  SKU.WS_PRICE,     
		 SM.SECTION_NAME, SD.SUB_SECTION_NAME,G.PARA4_CODE,H.PARA5_CODE,I.PARA6_CODE,PARA4_NAME,PARA5_NAME,  
		 PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],AR.DT_CREATED AS [ART_DT_CREATED],  
		 F.DT_CREATED AS [PARA3_DT_CREATED],SKU.DT_CREATED AS [SKU_DT_CREATED],AR.STOCK_NA,  
		 CONVERT (BIT,(CASE WHEN B.QUANTITY <0 THEN 1 ELSE 0 END)) AS SALERETURN ,CAST(0 AS BIT) AS CREDIT_REFUND,  
		 '' AS HOLD_ID,'' AS CMD_HOLD_ROW_ID,EMP.EMP_CODE ,SKU.PRODUCT_NAME, 
		  EMP1.EMP_CODE AS EMP_CODE1,EMP1.EMP_NAME AS EMP_NAME1 ,EMP2.EMP_CODE AS EMP_CODE2,EMP2.EMP_NAME AS EMP_NAME2  ,
		  (CASE WHEN ISNULL(SKU.FIX_MRP,0)=0 THEN SKU.mrp ELSE SKU.FIX_MRP END) AS [FIX_MRP],
		 (CASE WHEN ISNULL(B.hold_for_alter,0)=0 THEN 'N' ELSE 'Y' END) AS [HOLD_FOR_ALTER_TXT],
		 AR.ALIAS AS ARTICLE_ALIAS ,b.tax_percentage,b.tax_method,b.tax_amount,
		 B.CARD_DISCOUNT_AMOUNT  AS card_discount_amount,
		 B.card_discount_percentage as card_discount_percentage,
		 B.DISCOUNT_AMOUNT AS DISCOUNT_AMOUNT,
		 B.discount_percentage as discount_percentage,
  
		convert(numeric(10,2),0) AS last_sls_discount_percentage,b.scheme_name last_applied_scheme_name,
			ISNULL(b.hsn_code,'0000000000') as HSN_CODE,
			(case when b.tax_method= 2 then 'Exclusive' Else 'Inclusive' End) As Tax_method_type,
			B.GST_PERCENTAGE,OLD_NET ,PATCHUP_RUN,b.old_cmm_discount_amount,B.PCS_QUANTITY,B.MTR_QUANTITY,B.manual_discount_amount,B.manual_discount_percentage,
			b.manual_discount,b.Manual_DP,b.weighted_avg_disc_pct, b.weighted_avg_disc_amt,b.cmm_discount_amount,cri.campaign_code,Ar.ARTICLE_PACK_SIZE
		 FROM CMD01106 B (NOLOCK)   
		 JOIN CMM01106 A (NOLOCK) ON B.CM_ID=A.CM_ID
		 JOIN @dtable_21 T21 ON T21.CMM_CM_ID=B.cm_id AND T21.CMD_PRODUCT_CODE=B.PRODUCT_CODE
		 LEFT OUTER JOIN PMT01106 P (NOLOCK) ON P.PRODUCT_CODE=B.PRODUCT_CODE AND b.BIN_ID=p.BIN_ID AND a.location_Code=P.DEPT_ID 
		 LEFT OUTER JOIN 
		 (
				--SELECT  TOP 1 cm_id,campaign_code 
				--FROM coupon_redemption_info (NOLOCK) 
				--WHERE cm_id=@CREFMEMOID AND campaign_code='00009'
				/*	Rohit 08-04-2025 : 	
					pankajraswant 1:27 PM
					DATABASE-PITAMBARI_LB
					UPDATE-13.03.2025
					2410PT4341
					NEW CASH MEMO CASHMEMO NO-LBHO-0000449 DATE-04-04-2025 KO SALE KIYA DISCOUNT 50% AND CUPON DICOUNT BILL LEVEL PAR HAI 56.840% , Weightage disc Percentage mein bhe 50% a  araha hai
					JAB IS PCS KO RETURN LE RHE HAI TO DISCOUTN 78% KE ASPAS PICK KAR RHA HAI
					Your ID: 96426570
					Password: 60367
					MOB-MOB- 8084390600 ADITYA JI 
				*/
				SELECT  TOP 1 cm_id,campaign_code 
				FROM coupon_redemption_info CR (NOLOCK)   
				JOIN @dtable_21 T211 ON T211.CMM_CM_ID=CR.cm_id
				WHERE  campaign_code='00009'  
		) cri ON cri.cm_id=a.cm_id 
		 JOIN  SKU (NOLOCK) ON SKU.PRODUCT_CODE=b.PRODUCT_CODE   
		 JOIN  ARTICLE AR (NOLOCK) ON SKU.ARTICLE_CODE =AR.ARTICLE_CODE   
		 JOIN SECTIOND SD (NOLOCK) ON AR.SUB_SECTION_CODE = SD.SUB_SECTION_CODE   
		 JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE   
		 JOIN PARA1 C (NOLOCK) ON SKU.PARA1_CODE = C.PARA1_CODE   
		 JOIN PARA2 D (NOLOCK) ON SKU.PARA2_CODE = D.PARA2_CODE   
		 JOIN PARA3 F (NOLOCK) ON SKU.PARA3_CODE = F.PARA3_CODE   
		 JOIN PARA4 G (NOLOCK) ON SKU.PARA4_CODE = G.PARA4_CODE   
		 JOIN PARA5 H (NOLOCK) ON SKU.PARA5_CODE = H.PARA5_CODE   
		 JOIN PARA6 I (NOLOCK) ON SKU.PARA6_CODE = I.PARA6_CODE   
		 JOIN  UOM E (NOLOCK) ON AR.UOM_CODE = E.UOM_CODE   
		 LEFT OUTER JOIN EMPLOYEE EMP (NOLOCK) ON EMP.EMP_CODE=B.EMP_CODE
		 LEFT OUTER JOIN EMPLOYEE EMP1  (NOLOCK) ON B.EMP_CODE1 = EMP1.EMP_CODE     
		 LEFT OUTER JOIN EMPLOYEE EMP2  (NOLOCK) ON B.EMP_CODE2 = EMP2.EMP_CODE 
		 LEFT OUTER JOIN
		 (
			SELECT TOP 1 VALUE FROM CONFIG (NOLOCK) WHERE  CONFIG_OPTION='PICK_MRP_OF_BARCODE_SLR'
		 )X ON 1=1    

		 WHERE a.CANCELLED=0 AND a.cm_id<>'XXXXXXXXXX'
		 --(B.cm_id= @CREFMEMOID  
		 --AND (B.PRODUCT_CODE=@CWHERE or B.PRODUCT_CODE like @CWHERE+'@%')) 
		 and b.QUANTITY>0  
		 ORDER BY B.sr_no 

	--if @@spid=153
		--select 'check tmplastsls',basic_discount_amount,basic_discount_percentage,last_sls_discount_percentage, * from #tmpLastSls

	IF  EXISTS (SELECT TOP 1 * FROM #tmpLastSls)
		GOTO lblLast
	

	--select @NPICKLASTSLSDISC,DBNAME,checked FROM @dtable

	WHILE EXISTS (SELECT TOP 1 DBNAME FROM @dtable WHERE CHECKED=0)
	BEGIN
		SELECT TOP 1 @dbNAME= DBNAME FROM @dtable WHERE CHECKED=0
	
		SET @cCMD=N'
		USE '+@dbNAME+';
		SELECT CM_ID FROM CMM01106 (NOLOCK) WHERE CM_ID='''+@CREFMEMOID+''''
		PRINT @cCMD
		 INSERT INTO @dtable_20(CM_ID)
		 EXEC SP_EXECUTESQL @cCMD
		IF @@ROWCOUNT=1
		BEGIN
			UPDATE @dtable SET CHECKED=1 
			SET @cCMD=N'
			USE '+@dbNAME+';
			SELECT  SR_NO AS ''SRNO'',CAST((CASE WHEN B.PRODUCT_CODE='''+@CWHERE +''' THEN 1 ELSE  0 END)  AS BIT) AS BILLCHECK,
			A.CM_NO,A.CM_DT,A.CM_ID,A.CM_ID AS REF_SLS_MEMO_ID,A.CM_NO as ref_sls_memo_no,A.CM_DT as ref_sls_memo_dt,
			B.PRODUCT_CODE,AR.ARTICLE_NO,B.QUANTITY,E.UOM_NAME,(CASE WHEN ISNULL(X.VALUE,''0'')=''1'' THEN B.MRP WHEN isnull(b.old_mrp,0)=0 or b.old_mrp=b.mrp THEN B.MRP ELSE B.OLD_MRP END) AS MRP,
			B.OLD_MRP,CASE WHEN '+CAST(@NPICKLASTSLSDISC AS VARCHAR(10))+'=1 THEN  
			CONVERT(NUMERIC(14,3),(CASE WHEN b.old_mrp<>b.mrp AND ISNULL(b.Old_mrp,0)<>0 
			THEN (100-(((b.old_mrp-(b.old_mrp*(ISNULL(b.basic_discount_percentage,0)+isnull(b.manual_discount_percentage,0))/100))
			-((b.old_mrp-(b.old_mrp*(ISNULL(b.basic_discount_percentage,0)+isnull(b.manual_discount_percentage,0))/100))*(CASE WHEN cri.cm_id IS NULL THEN a.discount_percentage ELSE 0 END)/100))/b.old_mrp)*100) 
			WHEN weighted_avg_disc_pct<>0  THEN ((weighted_avg_disc_amt+
			(CASE WHEN cri.cm_id IS NULL AND ISNULL(a.patchup_run,0)=0 
			      THEN (b.mrp-(weighted_avg_disc_amt/quantity))*a.discount_percentage*quantity/100 ELSE 0 END))/(b.MRP*QUANTITY))*100
			ELSE (100-((((b.mrp-(b.mrp*(ISNULL(b.basic_discount_percentage,0)+isnull(b.manual_discount_percentage,0))/100))-
			(CASE WHEN cri.cm_id IS NULL AND ISNULL(a.patchup_run,0)=0 
			      THEN ((b.mrp-(weighted_avg_disc_amt/quantity))*a.discount_percentage*quantity/100)/b.QUANTITY ELSE 0 END)))/b.mrp)*100) END)) 
			 ELSE 0 END  AS basic_DISCOUNT_PERCENTAGE,
			CASE WHEN '+CAST(@NPICKLASTSLSDISC AS VARCHAR(10))+'=1 THEN  
			(CASE WHEN isnull(b.old_mrp,0)=0 or b.old_mrp=b.mrp THEN B.basic_DISCOUNT_AMOUNT+isnull(b.manual_discount_amount,0) ELSE ((B.QUANTITY * B.OLD_MRP) * (B.basic_DISCOUNT_PERCENTAGE+isnull(b.manual_discount_percentage,0))/100)  END) ELSE 0 END  AS basic_DISCOUNT_AMOUNT,
			(CASE WHEN isnull(b.old_mrp,0)=0 or b.old_mrp=b.mrp THEN B.NET ELSE ((B.QUANTITY * B.OLD_MRP)-((B.QUANTITY * B.OLD_MRP) * B.DISCOUNT_PERCENTAGE)/100 ) END) AS NET,  
			EMP.EMP_NAME,A.DISCOUNT_PERCENTAGE AS DISC_PERMM,A.DISCOUNT_AMOUNT AS DISC_AMTMM,A.NET_AMOUNT AS AMTM, AR.ARTICLE_CODE,  
			C.PARA1_CODE,C.PARA1_NAME, D.PARA2_CODE, D.PARA2_NAME, F.PARA3_CODE, F.PARA3_NAME, B.DEPT_ID,   
			sku.barcode_CODING_SCHEME as CODING_SCHEME,  AR.INACTIVE, ISNULL(P.QUANTITY_IN_STOCK,0) AS QUANTITY_IN_STOCK,SKU.PURCHASE_PRICE,  SKU.WS_PRICE,     
			SM.SECTION_NAME, SD.SUB_SECTION_NAME,G.PARA4_CODE,H.PARA5_CODE,I.PARA6_CODE,PARA4_NAME,PARA5_NAME,  
			PARA6_NAME,E.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],AR.DT_CREATED AS [ART_DT_CREATED],  
			F.DT_CREATED AS [PARA3_DT_CREATED],SKU.DT_CREATED AS [SKU_DT_CREATED],AR.STOCK_NA,  
			CONVERT (BIT,(CASE WHEN B.QUANTITY <0 THEN 1 ELSE 0 END)) AS SALERETURN ,CAST(0 AS BIT) AS CREDIT_REFUND,  
			'''' AS HOLD_ID,'''' AS CMD_HOLD_ROW_ID,EMP.EMP_CODE ,SKU.PRODUCT_NAME, 
			EMP1.EMP_CODE AS EMP_CODE1,EMP1.EMP_NAME AS EMP_NAME1 ,EMP2.EMP_CODE AS EMP_CODE2,EMP2.EMP_NAME AS EMP_NAME2  ,
			(CASE WHEN ISNULL(SKU.FIX_MRP,0)=0 THEN SKU.mrp ELSE SKU.FIX_MRP END) AS [FIX_MRP],
			(CASE WHEN ISNULL(B.hold_for_alter,0)=0 THEN ''N'' ELSE ''Y'' END) AS [HOLD_FOR_ALTER_TXT],
			AR.ALIAS AS ARTICLE_ALIAS ,b.tax_percentage,b.tax_method,b.tax_amount,
			B.CARD_DISCOUNT_AMOUNT  AS card_discount_amount,
			B.card_discount_percentage as card_discount_percentage,B.DISCOUNT_AMOUNT AS DISCOUNT_AMOUNT,B.discount_percentage as discount_percentage,
			CONVERT(NUMERIC(14,3),0) AS last_sls_discount_percentage,b.scheme_name last_applied_scheme_name,
			ISNULL(SKU.hsn_code,''0000000000'') as HSN_CODE,
			(case when b.tax_method= 2 then ''Exclusive'' Else ''Inclusive'' End) As Tax_method_type,
			B.GST_PERCENTAGE,b.OLD_NET ,a.PATCHUP_RUN,b.old_cmm_discount_amount,B.PCS_QUANTITY,B.MTR_QUANTITY,B.manual_discount_amount,B.manual_discount_percentage,
			b.manual_discount,b.manual_dp,b.weighted_avg_disc_pct,b.weighted_avg_disc_amt,b.cmm_discount_amount,cri.campaign_code ecouponCampaignCode,AR.ARTICLE_PACK_SIZE
			FROM CMD01106 B (NOLOCK)   
			JOIN CMM01106 A (NOLOCK) ON B.CM_ID=A.CM_ID   
			LEFT OUTER JOIN PMT01106 P (NOLOCK) ON P.PRODUCT_CODE=B.PRODUCT_CODE AND b.BIN_ID=p.BIN_ID AND a.location_code=P.DEPT_ID 
			LEFT OUTER JOIN (SELECT  TOP 1 cm_id,campaign_code FROM coupon_redemption_info (NOLOCK) 
						  WHERE cm_id='''+@CREFMEMOID +''' AND campaign_code=''00009'') cri ON cri.cm_id=a.cm_id 
			JOIN  SKU (NOLOCK) ON SKU.PRODUCT_CODE=b.PRODUCT_CODE   
			JOIN  ARTICLE AR (NOLOCK) ON SKU.ARTICLE_CODE =AR.ARTICLE_CODE   
			JOIN SECTIOND SD (NOLOCK) ON AR.SUB_SECTION_CODE = SD.SUB_SECTION_CODE   
			JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE   
			JOIN PARA1 C (NOLOCK) ON SKU.PARA1_CODE = C.PARA1_CODE   
			JOIN PARA2 D (NOLOCK) ON SKU.PARA2_CODE = D.PARA2_CODE   
			JOIN PARA3 F (NOLOCK) ON SKU.PARA3_CODE = F.PARA3_CODE   
			JOIN PARA4 G (NOLOCK) ON SKU.PARA4_CODE = G.PARA4_CODE   
			JOIN PARA5 H (NOLOCK) ON SKU.PARA5_CODE = H.PARA5_CODE   
			JOIN PARA6 I (NOLOCK) ON SKU.PARA6_CODE = I.PARA6_CODE   
			JOIN  UOM E (NOLOCK) ON AR.UOM_CODE = E.UOM_CODE   
			LEFT OUTER JOIN EMPLOYEE EMP (NOLOCK) ON EMP.EMP_CODE=B.EMP_CODE
			LEFT OUTER JOIN EMPLOYEE EMP1  (NOLOCK) ON B.EMP_CODE1 = EMP1.EMP_CODE     
			LEFT OUTER JOIN EMPLOYEE EMP2  (NOLOCK) ON B.EMP_CODE2 = EMP2.EMP_CODE 
			LEFT OUTER JOIN
			(
			SELECT TOP 1 VALUE FROM CONFIG (NOLOCK) WHERE  CONFIG_OPTION=''PICK_MRP_OF_BARCODE_SLR''
			)X ON 1=1    
			WHERE B.cm_id='''+ @CREFMEMOID  +'''
			AND (B.PRODUCT_CODE='''+@CWHERE+''' or B.PRODUCT_CODE like '''+ @CWHERE+'@%'') 
			and b.QUANTITY>0 AND a.CANCELLED=0 AND a.cm_id<>''XXXXXXXXXX''
			ORDER BY B.sr_no'
			print @cCmd
			
			INSERT INTO #tmpLastSls (SRNO,BILLCHECK,CM_NO,CM_DT,CM_ID,REF_SLS_MEMO_ID,ref_sls_memo_no,ref_sls_memo_dt,
			PRODUCT_CODE,ARTICLE_NO,QUANTITY,UOM_NAME,MRP,OLD_MRP,basic_DISCOUNT_PERCENTAGE,basic_DISCOUNT_AMOUNT,
			NET,EMP_NAME,DISC_PERMM,DISC_AMTMM,AMTM,ARTICLE_CODE ,PARA1_CODE,PARA1_NAME,PARA2_CODE,PARA2_NAME,PARA3_CODE,PARA3_NAME, 
			DEPT_ID,CODING_SCHEME,INACTIVE,QUANTITY_IN_STOCK,PURCHASE_PRICE,WS_PRICE,     
			SECTION_NAME,SUB_SECTION_NAME,PARA4_CODE,PARA5_CODE,PARA6_CODE,PARA4_NAME,PARA5_NAME,  
			 PARA6_NAME,UOM_CODE,[UOM_TYPE],ART_DT_CREATED,[PARA3_DT_CREATED],SKU_DT_CREATED,STOCK_NA,  
			 SALERETURN ,CREDIT_REFUND,HOLD_ID,CMD_HOLD_ROW_ID,EMP_CODE ,PRODUCT_NAME, 
			 EMP_CODE1,EMP_NAME1 ,EMP_CODE2,EMP_NAME2,[FIX_MRP],[HOLD_FOR_ALTER_TXT],ARTICLE_ALIAS,
			 tax_percentage,tax_method,tax_amount,card_discount_amount,card_discount_percentage,
			 DISCOUNT_AMOUNT,discount_percentage,last_sls_discount_percentage,last_applied_scheme_name,
			 HSN_CODE,Tax_method_type,gst_percentage,OLD_NET ,PATCHUP_RUN,old_cmm_discount_amount,PCS_QUANTITY,MTR_QUANTITY,manual_discount_amount,
			 manual_discount_percentage,manual_discount,manual_dp,weighted_avg_disc_pct,weighted_avg_disc_amt,cmm_discount_amount,ecouponCampaignCode,ARTICLE_PACK_SIZE)
			EXEC SP_EXECUTESQL @cCMD
		END	
		ELSE
		BEGIN
			UPDATE @dtable SET CHECKED=1 WHERE DBNAME=@dbNAME
			SET @cCMD=''
		END
	END

	 --if @@spid=84
		--select 'check discounts-1', card_discount_percentage,basic_discount_percentage,last_sls_discount_percentage
		--from #tmpLastSls

lblLast:
	 --if @@spid=275
		--select 'check discounts', card_discount_percentage,basic_discount_percentage,last_sls_discount_percentage
		--from #tmpLastSls

		IF EXISTS (SELECT TOP 1 'U' FROM #TMPLASTSLS WHERE ISNULL(OLD_MRP,0)<>0 AND ISNULL(OLD_NET,0)<>0 AND ISNULL(PATCHUP_RUN,0)<>0)
		BEGIN
		    UPDATE A SET card_discount_amount =0 ,card_discount_percentage =0,
			              last_sls_discount_percentage =
						  ((((A.OLD_MRP*a.quantity)-A.OLD_NET)*100)/(A.OLD_MRP*a.quantity)),
						  net=OLD_NET ,basic_discount_percentage=0,basic_discount_amount=0
			from #tmpLastSls A (NOLOCK)
			WHERE ISNULL(OLD_MRP,0)<>0 AND ISNULL(OLD_NET,0)<>0 AND ISNULL(PATCHUP_RUN,0)<>0
		END
		ELSE
		BEGIN
		--SELECT weighted_avg_disc_pct,ISNULL(manual_discount,0), ISNULL(manual_dp,0),isnull(manual_discount_amount,0) ,* FROM #tmpLastSls
			UPDATE #tmpLastSls SET scenarioype=(CASE WHEN /*Rohit 08-04-2025*/ ISNULL(ecouponCampaignCode,'')<>'00009'  AND weighted_avg_disc_pct<>0 AND  NOT (ISNULL(manual_discount,0)=1 OR ISNULL(manual_dp,0)=1 OR isnull(manual_discount_amount,0)<>0)
			THEN 1 when isnull(cmm_Discount_amount,0)=0 and isnull(manual_discount_percentage,0)=0 and ISNULL(card_discount_percentage,0)=0 then 2 else 3 end)
			
			UPDATE #tmpLastSls SET last_sls_discount_percentage= ((weighted_avg_disc_amt+isnull(manual_discount_amount,0)+ISNULL(cmm_discount_amount,0)+ISNULL(card_discount_amount,0))/(MRP*QUANTITY))*100
			where scenarioype=1

			UPDATE #tmpLastSls SET last_sls_discount_percentage=  basic_discount_percentage where scenarioype=2

			UPDATE #tmpLastSls SET net= (mrp-(mrp*ISNULL(basic_discount_percentage,0)/100))
			where scenarioype=3
			
			UPDATE #tmpLastSls SET net=net-(net*card_discount_percentage/100)
			where scenarioype=3

			--select 'check #tmpLastSls',scenarioype,net,cmm_discount_amount,basic_discount_percentage,card_discount_percentage,manual_discount_percentage,last_sls_discount_percentage, * from #tmpLastSls

		    UPDATE #tmpLastSls SET net=net-(CASE WHEN isnull(ecouponCampaignCode,'')<>'00009' THEN cmm_Discount_amount/QUANTITY ELSE 0 END)
		    where scenarioype=3
			

			UPDATE #tmpLastSls SET last_sls_discount_percentage=((mrp-net)/mrp)*100 WHERE scenarioype=3
			
		END

		--(CASE WHEN b.old_mrp<>b.mrp AND ISNULL(b.Old_mrp,0)<>0 THEN (100-(((b.old_mrp-(b.old_mrp*(ISNULL(b.basic_discount_percentage,0)+isnull(b.manual_discount_percentage,0))/100))
		--	-((b.old_mrp-(b.old_mrp*(ISNULL(b.basic_discount_percentage,0)/100)+isnull(b.manual_discount_percentage,0)))*(CASE WHEN cri.cm_id IS NULL THEN a.discount_percentage ELSE 0 END)/100))/b.old_mrp)*100) 
		--	WHEN weighted_avg_disc_pct<>0 AND NOT (ISNULL(b.manual_discount,0)=1 OR ISNULL(b.manual_dp,0)=1 OR isnull(b.manual_discount_amount,0)<>0)  
		--	THEN ((weighted_avg_disc_amt+isnull(b.manual_discount_percentage,0)+(CASE WHEN cri.cm_id IS NULL AND ISNULL(a.patchup_run,0)=0 
		--		  THEN (b.mrp-(weighted_avg_disc_amt/quantity))*a.discount_percentage*quantity/100 ELSE 0 END))/(b.MRP*QUANTITY))*100
		--	ELSE (100-((((b.mrp-(b.mrp*(ISNULL(b.basic_discount_percentage,0)+isnull(b.manual_discount_percentage,0))/100))-
		--	(CASE WHEN cri.cm_id IS NULL AND ISNULL(a.patchup_run,0)=0 
		--		  THEN b.cmm_Discount_amount/b.QUANTITY ELSE 0 END)))/b.mrp)*100) END)) 

	 UPDATE #tmpLastSls SET basic_discount_percentage=last_sls_discount_percentage,
	 basic_discount_amount=mrp*quantity*last_sls_discount_percentage/100
	 WHERE ISNULL(last_sls_discount_percentage,0)<>0 AND ISNULL(card_discount_percentage,0)=0

	 SELECT *,last_applied_scheme_name scheme_name FROM  #tmpLastSls
END