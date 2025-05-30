create PROCEDURE SP3S_WSLPRINT_DYNAMIC
(
@cMemoId VARCHAR(40),
@CWHERE NVARCHAR(50)='',
@cuserCode varchar(10)=''
)
AS
BEGIN


	SET NOCOUNT ON
	   DECLARE @cCmdCols NVARCHAR(MAX),@cCmd NVARCHAR(MAX),@cCols NVARCHAR(MAX),@cCmd1 NVARCHAR(MAX),@cCmd2 NVARCHAR(MAX),@cCmd3 NVARCHAR(MAX),@cCmdIMG NVARCHAR(MAX)
	   ,@PARA1 NVARCHAR(10),@PARA2 NVARCHAR(10),@PARA3 NVARCHAR(10),@PARA4 NVARCHAR(10),@PARA5 NVARCHAR(10),@PARA6 NVARCHAR(10),@cnullableCols VARCHAR(max),
	   @GSTINVOICE_WITHOUT_STARS varchar(5)
	   
        SELECT A.PARCEL_MEMO_ID,ANGM.ANGADIA_NAME AS TRANSPORTER_NAME,A.BILTY_NO AS BILTY_NO,                  
			CAST(A.RECEIPT_DT AS DATE) AS BILTY_DATE,SUM(B.BOX_NO) AS BOX_NO,SUM(QTY) AS WGHT,                  
			B.REF_MEMO_ID AS XN_ID,A.VEHICLE_NO,CAST(A.TOT_QTY AS VARCHAR) AS DISP_WEIGHT,  
            CAST(A.TOT_BOXES AS VARCHAR)AS DISP_BOX_NO ,Driver_name ,cash_receipt_no ,gate_entry_no,
            ANLMP.MOBILE AS Transporter_Mobile ,
            ANLMP.Ac_gst_no Transporter_GstNo ,ANLMP.e_mail Transporter_Email
			into #tmpParcel
		   FROM PARCEL_MST A (NOLOCK)                  
		   JOIN PARCEL_DET B (NOLOCK) ON A.PARCEL_MEMO_ID =B.PARCEL_MEMO_ID                             
		   LEFT OUTER JOIN ANGM (NOLOCK) ON ANGM.ANGADIA_CODE =A.ANGADIA_CODE  
		   LEFT JOIN LMP01106 ANLMP (NOLOCK) ON ANLMP.AC_CODE =ANGM.ac_code                  
		   WHERE A.XN_TYPE ='WSL' and a.cancelled=0 AND B.REF_MEMO_ID=@cMemoId               
		   GROUP BY ANGM.ANGADIA_NAME ,A.PARCEL_MEMO_ID ,A.BILTY_NO ,B.REF_MEMO_ID,A.VEHICLE_NO,A.RECEIPT_DT,A.TOT_QTY,A.TOT_BOXES ,
		   Driver_name ,cash_receipt_no ,gate_entry_no,ANLMP.MOBILE, ANLMP.Ac_gst_no,ANLMP.e_mail
			
		IF OBJECT_ID('TEMPDB..#TMPLMV01106','U') IS NOT NULL
		    DROP TABLE #TMPLMV01106

		DECLARE @IMG_SECTION BIT,@IMG_SUB_SECTION BIT,@IMG_ARTICLE BIT,@IMG_PARA1 BIT,@IMG_PARA2 BIT,@IMG_PARA3 BIT,@IMG_PARA4 BIT,@IMG_PARA5 BIT,@IMG_PARA6 BIT,@IMG_PRODUCT BIT
		SELECT @IMG_SECTION=SECTION,@IMG_SUB_SECTION=SUB_SECTION,@IMG_ARTICLE=ARTICLE        
		,@IMG_PARA1=PARA1 ,@IMG_PARA2=PARA2, @IMG_PARA3=PARA3,@IMG_PARA4=PARA4        
		,@IMG_PARA5=PARA5 ,@IMG_PARA6=PARA6, @IMG_PRODUCT=PRODUCT        
		FROM DBO.IMAGE_INFO_CONFIG WITH(NOLOCK)  
		--END: 30 NOV 2019
		
	   SELECT TOP 1 @GSTINVOICE_WITHOUT_STARS =VALUE FROM USER_ROLE_DET A(NOLOCK)    
	   JOIN USERS B(NOLOCK) ON A.ROLE_ID=B.ROLE_ID    
	   WHERE USER_CODE=@CUSERCODE    
	   AND FORM_NAME='Miscellaneous'     
	   AND FORM_OPTION='GSTINVOICE_WITHOUT_STARS' 
	   set @GSTINVOICE_WITHOUT_STARS=ISNULL(@GSTINVOICE_WITHOUT_STARS,'')   
	    
		SELECT ISNULL(LM.AC_GST_NO,'') AS  LMV1AC_GST_NO ,ISNULL(LM.AC_GST_NO,'')AS LMVAC_GST_NO,INV_ID,@GSTINVOICE_WITHOUT_STARS GSTINVOICE_WITHOUT_STARS
		 INTO #TMPLMV01106 
		FROM INM01106 INM (NOLOCK)                                                                                           
	    LEFT JOIN LMP01106 LM (NOLOCK) ON LM.AC_CODE=INM.AC_CODE                                  
		WHERE INM.INV_ID=@cMemoId 
		

		DECLARE @NTAXABLEVALUE NUMERIC(14,2),@NIGST_AMOUNT NUMERIC(14,2),@NCGST_AMOUNT NUMERIC(14,2),@NSGST_AMOUNT NUMERIC(14,2),
		        @nentry_mode numeric(5,0)
		
		SELECT  @NTAXABLEVALUE=ISNULL(IND.XN_VALUE_WITHOUT_GST,0)+ ISNULL(INM.OTHER_CHARGES_TAXABLE_VALUE,0)+ISNULL(INM.FREIGHT_TAXABLE_VALUE,0)+ISNULL(INM.INSURANCE_TAXABLE_VALUE,0)+ISNULL(INM.PACKING_TAXABLE_VALUE,0),
			    @NIGST_AMOUNT=ISNULL(IND.IGST_AMOUNT,0)+ISNULL(INM.OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(INM.FREIGHT_IGST_AMOUNT,0)+ISNULL(INM.INSURANCE_IGST_AMOUNT,0)+ISNULL(INM.PACKING_IGST_AMOUNT,0),
			    @NCGST_AMOUNT=ISNULL(IND.CGST_AMOUNT,0)+ISNULL(INM.OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(INM.FREIGHT_CGST_AMOUNT,0)+ISNULL(INM.INSURANCE_CGST_AMOUNT,0)+ISNULL(INM.PACKING_CGST_AMOUNT,0),
			    @NSGST_AMOUNT=ISNULL(IND.SGST_AMOUNT,0)+ ISNULL(INM.OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(INM.FREIGHT_SGST_AMOUNT,0)+ISNULL(INM.INSURANCE_SGST_AMOUNT,0)+ISNULL(INM.PACKING_SGST_AMOUNT,0),
				@nentry_mode=inm.entry_mode 
		FROM INM01106  INM (NOLOCK)
		JOIN 
		( 
		   SELECT INV_ID ,
		          SUM(XN_VALUE_WITHOUT_GST) AS XN_VALUE_WITHOUT_GST,
				  SUM(IGST_AMOUNT ) AS IGST_AMOUNT,
				  SUM(CGST_AMOUNT ) AS CGST_AMOUNT,
				  SUM(SGST_AMOUNT) AS SGST_AMOUNT
		   FROM IND01106 IND (NOLOCK)
		   WHERE IND.INV_ID=@CMEMOID
		   GROUP BY INV_ID
		 ) IND ON INM.INV_ID =IND.INV_ID 
		 WHERE INM.INV_ID=@cMemoId 


        SELECT TOP 1 @PARA1=VALUE FROM CONFIG WHERE config_option='PARA1_caption' AND ISNULL(VALUE,'') <>''
        SELECT TOP 1 @PARA2=VALUE FROM CONFIG WHERE config_option='PARA2_caption' AND ISNULL(VALUE,'') <>''
        SELECT TOP 1 @PARA3=VALUE FROM CONFIG WHERE config_option='PARA3_caption' AND ISNULL(VALUE,'') <>''
        SELECT TOP 1 @PARA4=VALUE FROM CONFIG WHERE config_option='PARA4_caption' AND ISNULL(VALUE,'') <>''
        SELECT TOP 1 @PARA5=VALUE FROM CONFIG WHERE config_option='PARA5_caption' AND ISNULL(VALUE,'') <>''
        SELECT TOP 1 @PARA6=VALUE FROM CONFIG WHERE config_option='PARA6_caption' AND ISNULL(VALUE,'') <>''
	    SET @PARA1=CASE WHEN ISNULL(@PARA1,'')='' THEN 'Para1' ELSE ISNULL(@PARA1,'') END
	    SET @PARA2=CASE WHEN ISNULL(@PARA2,'')='' THEN 'Para2' ELSE ISNULL(@PARA2,'') END
	    SET @PARA3=CASE WHEN ISNULL(@PARA3,'')='' THEN 'Para3' ELSE ISNULL(@PARA3,'') END
	    SET @PARA4=CASE WHEN ISNULL(@PARA4,'')='' THEN 'Para4' ELSE ISNULL(@PARA4,'') END
	    SET @PARA5=CASE WHEN ISNULL(@PARA5,'')='' THEN 'Para5' ELSE ISNULL(@PARA5,'') END
	    SET @PARA6=CASE WHEN ISNULL(@PARA6,'')='' THEN 'Para6' ELSE ISNULL(@PARA6,'') END
	   
	    SELECT @cCols=COALESCE(@cCols+',','')+column_name+' ['+DISPLAY_COLUMN_NAME+']' 
	    FROM dynamic_print_cols	
	    WHERE LTRIM(RTRIM(xn_type))='wsl' AND selected=1
		and DISPLAY_COLUMN_NAME<>'SizeQtyString'

		SELECT @cnullableCols=COALESCE(@cnullableCols+',','')+'NULL as '+' ['+DISPLAY_COLUMN_NAME+']' 
		FROM dynamic_print_cols	
	    WHERE LTRIM(RTRIM(xn_type))='wsl' AND selected=0
		and DISPLAY_COLUMN_NAME<>'SizeQtyString'


		select  cast('' as varchar(1000)) as boxDetails
		into #tmpboxDetails
		where 1=2

		DECLARE @CboxDetails varchar(max)

		if exists (select top 1'u' FROM dynamic_print_cols (nolock)	WHERE LTRIM(RTRIM(xn_type))='WSL' AND selected=1 and DISPLAY_COLUMN_NAME='boxDetails')
		begin

		     ;with cte as
			 (
		      SELECT CAST(BOX_NO AS VARCHAR(100))+'/'+REPLACE(CAST(SUM(QUANTITY)AS VARCHAR(1000)),'.000','') AS boxDetails 
			  FROM IND01106 (NOLOCK) WHERE INV_ID=@cMemoId
			  GROUP BY CAST(BOX_NO AS VARCHAR(100))
			  )

			   select @CboxDetails=COALESCE(@CboxDetails+',','')+boxDetails  from cte 
			   insert into #tmpboxDetails
			   select @CboxDetails
			 
		end

	  
         DECLARE @CPSNOLIST VARCHAR(MAX) ,@CORDERNOLIST VARCHAR(MAX) 
         DECLARE @TBLPS TABLE  (PS_NO VARCHAR(15),PS_ID VARCHAR(30),ENTRY_MODE INT)


		if @nentry_mode=2
		begin
		     
		     INSERT INTO @TBLPS(PS_NO,PS_ID,ENTRY_MODE)
		     SELECT B.PS_NO ,B.PS_ID ,B.ENTRY_MODE 
		     FROM IND01106 A (NOLOCK)
			 JOIN WPS_MST B (NOLOCK) ON A.PS_ID =B.PS_ID 
			 WHERE ISNULL(A.PS_ID,'') <>'' 
			 AND A.INV_ID=@cMemoId
			 group by B.PS_NO ,B.PS_ID ,B.ENTRY_MODE 
			
			 SELECT @CPSNOLIST=COALESCE(@CPSNOLIST+',','')+rtrim(ltrim(ps_no))
			 FROM @TBLPS A
			 
			 IF EXISTS (SELECT TOP 1 'U' FROM @TBLPS WHERE ENTRY_MODE=3)
			 BEGIN
			     
			      SELECT @CORDERNOLIST =COALESCE(@CORDERNOLIST+',','')+rtrim(ltrim(C.order_no ))
			      FROM @TBLPS a
			      JOIN SalesOrderProcessing B (NOLOCK)  ON A.PS_ID =B.MemoId 
			      JOIN BUYER_ORDER_MST C (NOLOCK) ON B.RefMemoId =C.order_id 
			      WHERE B.XnType in('orderPackSlip')
			      group by C.order_no
			 
			 END
			 ELSE IF EXISTS (SELECT TOP 1 'U' FROM @TBLPS WHERE ENTRY_MODE=4)
			 BEGIN
			     
			      SELECT @CORDERNOLIST =COALESCE(@CORDERNOLIST+',','')+rtrim(ltrim(d.order_no ))
			      FROM @TBLPS a
			      JOIN SalesOrderProcessing B (NOLOCK)  ON A.PS_ID =B.MemoId 
			      JOIN PLM01106 C (nolock) ON B.RefMemoId =C.MEMO_ID 
			      JOIN BUYER_ORDER_MST d (NOLOCK) ON c.order_id =d.order_id 
			      WHERE B.XnType In('plPackSlip')
			      group by d.order_no
			 
			 
			 END
			 
        
		end
		else if @nentry_mode=3
		begin
		
		      SELECT @CORDERNOLIST =COALESCE(@CORDERNOLIST+',','')+rtrim(ltrim(C.order_no ))
			      FROM  SalesOrderProcessing B (NOLOCK)  
			      JOIN BUYER_ORDER_MST C (NOLOCK) ON B.RefMemoId =C.order_id 
			      WHERE B.XnType in('orderinvoice')
			      group by C.order_no
		end
		

		set @CPSNOLIST=isnull(@CPSNOLIST,'')
		set @CORDERNOLIST=isnull(@CORDERNOLIST,'')

	

		SET @cnullableCols=ISNULL(@cnullableCols,'')
		IF ISNULL(@cnullableCols,'')<>''
		   SET @cnullableCols=','+ISNULL(@cnullableCols,'')
		
	   
	   DECLARE @NAME VARCHAR(300)
	   SELECT @NAME=COALESCE(@NAME,'')+ISNULL(M.PAYMODE_NAME,CASE I.PAY_MODE WHEN 4 THEN 'CREDIT ISSUED' WHEN 1 THEN 'INR' END)+':'+CONVERT(VARCHAR,ISNULL(P.amount,I.NET_AMOUNT))+'; '
	   FROM INM01106 I (NOLOCK)
	   LEFT JOIN PAYMODE_XN_DET P (NOLOCK)
	   JOIN PAYMODE_MST M (NOLOCK) ON M.PAYMODE_CODE=ISNULL(P.paymode_code,'0000004') ON I.INV_ID=P.memo_id AND P.xn_type='WSL'
	   WHERE I.INV_ID=@cMemoId

	   SET @NAME=RTRIM(@NAME)
	   IF RIGHT(@NAME,1)=';' SET @NAME=LEFT(@NAME,LEN(@NAME)-1)

	   set @NAME=isnull(@NAME,'')

	   SELECT MST.MEMO_NO ,MST.MEMO_DT ,A.DELIVERY_DT,A.product_code  
	   INTO #TMPHOLDS
	   FROM HOLD_BACK_DELIVER_DET A (NOLOCK)
	   JOIN HOLD_BACK_DELIVER_MST MST (NOLOCK) ON A.memo_id =MST.memo_id 
	   WHERE 1=2

       IF EXISTS (SELECT TOP 1'U' FROM INM01106 (NOLOCK) WHERE INV_ID =@CMEMOID AND XN_ITEM_TYPE =5)
	   BEGIN
	        
			INSERT INTO #TMPHOLDS(MEMO_NO,MEMO_DT,DELIVERY_DT,product_code)
			SELECT MST.MEMO_NO ,MST.MEMO_DT ,A.DELIVERY_DT,A.product_code    
			FROM HOLD_BACK_DELIVER_DET A (NOLOCK)
	        JOIN HOLD_BACK_DELIVER_MST MST (NOLOCK) ON A.memo_id =MST.memo_id 
			JOIN IND01106 IND (NOLOCK) ON IND.PRODUCT_CODE =A.product_code 
			WHERE IND.INV_ID =@CMEMOID
			GROUP BY MST.MEMO_NO ,MST.MEMO_DT ,A.DELIVERY_DT,A.product_code

	   END

	   if object_id('tempdb..#tmpBod','u') Is not null 
	      Drop table #tmpBod
	  
		SELECT ind.ROW_ID AS ind_ROW_ID,  FROM_UOM_NAME,TO_UOM_NAME, 
			   AREA_LENGTH,AREA_WIDTH,AREA_SQARE,AREA_RATE_PP,RATE_AREA_SQUARE
		into #tmpBod
		FROM BUYER_ORDER_DET A (NOLOCK)
		JOIN IND01106 ind (NOLOCK) ON ind.BO_DET_ROW_ID =A.ROW_ID 
		LEFT JOIN STANDARD_UOM SUOM (NOLOCK) ON SUOM.UOM_CODE=A.AREA_UOM_CODE
		where ind.INV_ID=@CMEMOID
		
	
	 DECLARE @CSPID VARCHAR(100),@CTABLENAME VARCHAR(100)

	 SET @CSPID=LTRIM(RTRIM(STR(@@SPID )))
	 SET @CTABLENAME  ='##TMPINVPRINT'+@CSPID

	SET @CCMD = N'IF OBJECT_ID(''TEMPDB..'+@CTABLENAME+''',''U'') IS NOT NULL
		          DROP TABLE '+@CTABLENAME+''
	PRINT @CCMD
    EXEC SP_EXECUTESQL @CCMD

	
	 --select @cCols
	   SET @cCmdCols=N'
	   SELECT '+@cCols+',
	   '''+@para1 +''' AS PARA1_CONFIG,'''+@PARA2 +''' AS PARA2_CONFIG,'''+@PARA3 +''' AS PARA3_CONFIG,
	   '''+@PARA4 +''' AS PARA4_CONFIG,'''+@PARA5 +''' AS PARA5_CONFIG,'''+@PARA6 +''' AS PARA6_CONFIG,
	   DBO.FN_CONVERTAMOUNTINWORDS(INM.NET_AMOUNT) AS  NET_AMOUNT_IN_WORDS,
	   DBO.FN_CONVERTAMOUNTINWORDS(INM.Total_Gst_Amount) GST_AMOUNT_IN_WORDS,
	   cast(NULL AS VARBINARY(MAX)) AS QRCODEIMAGE,cast(NULL AS VARBINARY(MAX)) AS QRCODEIMAGE_MEMODETAILS,
	   '+RTRIM(LTRIM(STR(isnull(@NTAXABLEVALUE,0) ,14,2)))+' as Total_Taxable_value,
	   '+RTRIM(LTRIM(STR(isnull(@NIGST_AMOUNT,0),14,2)))+' as Total_Igst_Amount,
	   '+RTRIM(LTRIM(STR(isnull(@NSGST_AMOUNT,0),14,2)))+' as Total_Sgst_Amount,
	   '+RTRIM(LTRIM(STR(isnull(@NCGST_AMOUNT,0),14,2)))+' as Total_Cgst_amount,
	   '''+@CPSNOLIST +''' AS PSNOLIST,
	   '''+@CORDERNOLIST +''' AS ORDERNOLIST,
	   WPS.PS_NO,WPS.PS_DT,INM.LOCATION_CODE,'''+@NAME+''' PAYMENT_DETAILS '+@cnullableCols
	   +'  INTO '+@CTABLENAME+'  '
	   --select @cCmdCols
	   SET @cCmd=N'  FROM IND01106  (NOLOCK)  
	   JOIN INM01106 INM (NOLOCK) ON inm.inv_id=ind01106.inv_id       
	   JOIN GST_COMPANY_CONFIG COM(NOLOCK) ON 1=1 AND COM.XN_TYPE=''WSL''
	   LEFT JOIN GST_STATE_MST SHP (NOLOCK) ON ISNULL(SHP.GST_STATE_NAME,'''')=ISNULL(INM.SHIPPING_STATE_NAME,'''')    
	   LEFT JOIN LM01106 SHLM (NOLOCK) ON SHLM.AC_CODE =INM.SHIPPING_AC_CODE 
       LEFT JOIN LMP01106 SHLMP (NOLOCK) ON SHLMP.AC_CODE =SHLM.AC_CODE 
       LEFT JOIN AREA SHAR (NOLOCK) ON SHLMP.AREA_CODE=SHAR.AREA_CODE                        
       LEFT JOIN CITY SHCT (NOLOCK) ON SHAR.CITY_CODE=SHCT.CITY_CODE  
       LEFT JOIN GST_STATE_MST SHCS (NOLOCK) ON SHCS.GST_STATE_CODE=SHLMP.AC_GST_STATE_CODE  
       LEFT JOIN USERS  (NOLOCK) ON USERS.USER_CODE=INM.USER_CODE
	   LEFT JOIN COMPANY CMP (NOLOCK) ON CMP.COMPANY_CODE=''01''   
	   LEFT JOIN (SELECT PS_ID,PS_NO,PS_DT FROM WPS_MST ) WPS ON WPS.PS_ID=IND01106.ps_id     
	   LEFT OUTER JOIN LOCATION SL (NOLOCK) ON SL.DEPT_ID =INM.LOCATION_CODE 
	   LEFT JOIN AREA SLA (NOLOCK) ON SL.AREA_CODE=SLA.AREA_CODE                  
	   LEFT JOIN CITY SLC (NOLOCK) ON SLA.CITY_CODE=SLC.CITY_CODE                  
	   LEFT JOIN GST_STATE_MST SLS (NOLOCK) ON SLS.GST_STATE_CODE=SL.GST_STATE_CODE
	   LEFT JOIN STATE SLST (nolock) on SL.gst_state_code =SLST.state_code
	   LEFT JOIN REGIONM SLR (NOLOCK) ON SLST.region_code=SLR.region_code                  
	   LEFT JOIN LMP01106 PRLMP (NOLOCK) ON PRLMP.AC_CODE=INM.AC_CODE                  
	   LEFT JOIN GST_STATE_MST PRS (NOLOCK) ON PRS.GST_STATE_CODE=PRLMP.AC_GST_STATE_CODE                  
	   LEFT JOIN LM01106 PRLM (NOLOCK) ON PRLM.AC_CODE=PRLMP.AC_CODE                  
	   LEFT JOIN AREA PRA (NOLOCK) ON PRLMP.AREA_CODE=PRA.AREA_CODE                  
	   LEFT JOIN CITY PRC (NOLOCK) ON PRA.CITY_CODE=PRC.CITY_CODE 
	   LEFT JOIN STATE PRST(NOLOCK) ON PRC.state_code=PRST.state_code
	   LEFT JOIN REGIONM PRR(NOLOCK) ON PRST.region_code=PRR.region_code   
	   LEFT OUTER JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID=INM.PARTY_DEPT_ID                  
	   LEFT JOIN AREA TLA (NOLOCK) ON TL.AREA_CODE=TLA.AREA_CODE                  
	   LEFT JOIN CITY TLC (NOLOCK) ON TLA.CITY_CODE=TLC.CITY_CODE                  
	   LEFT JOIN GST_STATE_MST TLS (NOLOCK) ON TLS.GST_STATE_CODE=TL.GST_STATE_CODE                  
	   left join state TLST (nolock) on TLST.state_code=TL.gst_state_code
	   left join regionm TLR (nolock) on TLR.region_code=TLST.region_code
	   LEFT JOIN #TMPLMV01106 TMP (NOLOCK) ON TMP.INV_ID=inm.inv_id
	   LEFT JOIN #TMPHOLDS HLDS ON HLDS.PRODUCT_CODE=IND01106.PRODUCT_CODE
	   LEFT JOIN EMPLOYEE ON EMPLOYEE.EMP_CODE=IND01106.EMP_CODE             
       LEFT JOIN EMPLOYEE EMPLOYEE1 ON EMPLOYEE1.EMP_CODE=IND01106.EMP_CODE1             
       LEFT JOIN EMPLOYEE EMPLOYEE2 ON EMPLOYEE2.EMP_CODE=IND01106.EMP_CODE2  
	   '
	   SET @cCmd1=N' LEFT OUTER JOIN #tmpParcel TR ON TR.XN_ID=INM.INV_ID                  
       left join #tmpBod BOD ON BOD.ind_ROW_ID=IND01106.ROW_ID
	   LEFT OUTER JOIN LM01106 BN (NOLOCK) ON INM.BROKER_AC_CODE=BN.AC_CODE'           
       SET @cCmd2=N' JOIN SKU_NAMES SN (NOLOCK) ON SN.PRODUCT_CODE=IND01106.PRODUCT_CODE      '         	
       SET @cCmd3=N'
	   LEFT OUTER JOIN (SELECT TNC_1,TNC_2,TNC_3,TNC_4,TNC_5,TNC_6,TNC_7,TNC_8 FROM GST_TNC WHERE XN_TYPE=''WSL'')GST_TNC  ON 1=1
	   LEFT JOIN #TMPBOXDETAILS tmpbox ON 1=1 
	   WHERE inm.inv_id='''+@cMemoId+''' '
      

	   if ISNULL(@CWHERE,'')<>''
		  SET @cCmdIMG=ISNULL(@cCmdIMG,'') + N' AND ind01106.box_no in ('+@CWHERE+')'
		  
     print 'cCmdCols '+@cCmdCols
       print @cCmd
       PRINT @ccmd1
       PRINT @ccmd2
       PRINT @ccmd3
       PRINT 'IMG '+@cCmdIMG
       EXEC(@cCmdCols+@cCmd+@ccmd1+@ccmd2+@ccmd3+@cCmdIMG)


	   DECLARE  @CERRMSG VARCHAR(100),@CsizeQTY VARCHAR(1000)
	   SET @CsizeQTY=''

	   IF EXISTS (SELECT TOP 1 'U'  FROM dynamic_print_cols	WHERE LTRIM(RTRIM(xn_type))='wsl' AND selected=1 and DISPLAY_COLUMN_NAME='SizeQtyString')
	   BEGIN
	        SET @CsizeQTY=N',(SELECT STUFF((SELECT CASE WHEN ISNULL(para2_name,'''') <> '''' THEN ''  '' ELSE '''' END +para2_name+ ''/''+RTRIM(LTRIM(STR((SUM(QUANTITY)))))  
		     FROM '+@CTABLENAME+'  B  WHERE A.article_no  =B.article_no AND A.para1_name =B.para1_name AND A.RATE=B.RATE
				GROUP BY ARTICLE_no,PARA1_NAME,RATE,CASE WHEN ISNULL(para2_name,'''') <> '''' THEN ''  '' ELSE '''' END +para2_name	 FOR XML PATH('''')),1,2,''''))  	 as [SIZEQTY]'
		END
	
	   
 END_PROC:
       
	   IF ISNULL(@CERRMSG,'')<>'' 
	   BEGIN
		   SELECT @CERRMSG AS ERRMSG 
	   END
	   ELSE 
	   BEGIN
	        
			SET @CCMD = N'SELECT * '+@CsizeQTY+'
			FROM '+@CTABLENAME+' A '
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD    
	   END

	   
		SET @CCMD = N'IF OBJECT_ID(''TEMPDB..'+@CTABLENAME+''',''U'') IS NOT NULL
					  DROP TABLE '+@CTABLENAME+''
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD

SET NOCOUNT OFF
END


/*
exec SP3S_WSLPRINT_DYNAMIC 'JM01120000JM/IS-000006'



*/
