create PROCEDURE Savetran_online_Sale --(LocId 3 digit change by Sanjay:06-11-2024)  
(
  @CORDER_ID		varchar(50),
  @CFINYEAR		    VARCHAR(10),
  @CLOCATIONID		VARCHAR(4)='',
  @cCUSTOMER_CODE   varchar(20),
  @DCM_DT           DATETIME,
  @CUSER_CODE       varchar(10),
  @CPARTYSTATECODE  varCHAR(4),
  @NSPID varchar(50)=''
)
AS                          
BEGIN      
       
	   Declare @NSAVETRANLOOP BIT,@cStep varchar(10),@CUSERALIAS varchar(5),@CKEYSTABLE varchar(50),
	           @CMEMONOPREFIX	VARCHAR(50),@cPartyGstno varchar(15),@cErrormsg varchar(1000),
			   @CCMD nvarchar(max),@CMEMONOVAL	VARCHAR(50),
			   @CMEMONO	VARCHAR(20),@NMEMONOLEN	NUMERIC(20,0),@CKEYFIELDVAL1 VARCHAR(50),@cpaymode_code varchar(10),
			   @CMASTERTABLENAME varchar(20),@NET_AMOUNT NUMERIC(14,2),@CROUNDBILLLEVEL VARCHAR(5),@NROUND_OFF numeric(5,2),
		       @GST_ROUND_OFF NUMERIC(5,2),@NBONET NUMERIC(14,2),@NBOQTY NUMERIC(10,3),
			   @NSLSNET NUMERIC(10,2),@NSLSQTY NUMERIC(14,2)

			   


                       
BEGIN TRY                                      
BEGIN TRANSACTION                   
            
			IF @NSPID=''
			SET @NSPID=NEWID()

			SET @CMASTERTABLENAME='CMM01106'
			SET @CMEMONO	= 'CM_NO'
	        SET @NMEMONOLEN	= 12

			select @cPartyGstno=ISNULL(cus_gst_no,'')
			from custdym (nolock) where customer_code =@cCUSTOMER_CODE

           SET @cStep=10 

		   SET @NSAVETRANLOOP=0
			WHILE @NSAVETRANLOOP=0
			BEGIN

				SET @cStep = 20	
				EXEC SP_CHKXNSAVELOG 'SLS_OL',@cStep,0,@NSPID,1
				
				SELECT TOP 1 @CUSERALIAS=USER_ALIAS FROM USERS A (NOLOCK) WHERE USER_CODE=@CUSER_CODE

				SET @CKEYSTABLE='KEYS_CMM_'+LTRIM(RTRIM(@CUSERALIAS))
				
				SET @CMEMONOPREFIX=''
				SET @CMEMONOPREFIX=@CLOCATIONID+@CUSERALIAS
				
								
				SET @cStep = 30
				DECLARE @cOutputMemoPrefix VARCHAR(25)

				EXEC SP3S_GETENINVOICE_MEMOPREFIX
				@cXnType='SLS',
				@cPartyGstNo=@cPartyGstno,
				@cSourceLocId=@CLOCATIONID,
				@cFinyear=@cFinyear,
				@cInputMemoPrefix=@CMEMONOPREFIX,
				@nSpId=@nSpId,
				@cErrormsg=@cErrormsg OUTPUT,
				@cOutputMemoPrefix=@cOutputMemoPrefix OUTPUT
				
				IF ISNULL(@cErrormsg,'')<>''
					GOTO END_PROC

				SET @CMEMONOPREFIX=@cOutputMemoPrefix+(CASE WHEN RIGHT(@cOutputMemoPrefix,1)<>'-' THEN '-' ELSE '' END)

				SET @cStep = 40	
				EXEC SP_CHKXNSAVELOG 'SLS_OL',@cStep,0,@NSPID,1
				

				EXEC GETNEXTKEY_OPT @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMONOPREFIX, 1,
								@CFINYEAR,0, @CKEYSTABLE,@CMEMONOVAL OUTPUT   
								
				
				PRINT @CMEMONOVAL
				SET @CCMD=N'IF EXISTS ( SELECT '+@CMEMONO+' FROM ['+@CMASTERTABLENAME+']  (NOLOCK) 
										WHERE '+@CMEMONO+'='''+@CMEMONOVAL+''' 
										AND FIN_YEAR = '''+@CFINYEAR+''' )
								SET @NLOOPOUTPUT=0
							ELSE
								SET @NLOOPOUTPUT=1'
				PRINT @CCMD
				EXEC SP_EXECUTESQL @CCMD, N'@NLOOPOUTPUT BIT OUTPUT',@NLOOPOUTPUT=@NSAVETRANLOOP OUTPUT

			END

			SET @CKEYFIELDVAL1 = @CLOCATIONID + @CFINYEAR+ REPLICATE('0', 17-len(@cLocationId)-LEN(LTRIM(RTRIM(@CMEMONOVAL)))) + LTRIM(RTRIM(@CMEMONOVAL))
			--SET @CKEYFIELDVAL1 = @CLOCATIONID + RIGHT(@CFINYEAR,2)+REPLICATE('0', (22-LEN(@CLOCATIONID + RIGHT(@CFINYEAR,2)))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))
                     
                            
 LBLIMPORTSLS:                          
                        
  PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)                          
      
	  SET @cStep = 50
      
	   declare @cAUTO_ALLOCATE_ONLINE_ORDERS varchar(5)
	   select @cAUTO_ALLOCATE_ONLINE_ORDERS=value  from config where config_option='AUTO_ALLOCATE_ONLINE_ORDERS'
	
	
	 IF ISNULL(@CAUTO_ALLOCATE_ONLINE_ORDERS,'')<>'1'
	  BEGIN
	          
		  EXEC SP3S_PENDING_ONLINEORDER 
		  @NMODE =1,
		  @CDEPT_ID =@CLOCATIONID,
		  @CORDER_ID =@CORDER_ID,
		  @CSPID =@NSPID
	
	 END

	  IF NOT EXISTS (SELECT TOP 1 'U' FROM SLS_IMPORT_DATA (NOLOCK) WHERE SP_ID=@NSPID )
	  begin
	      SET @CERRORMSG='NO RECORD FOUND'
		  GOTO END_PROC 
	  end

	   IF  EXISTS (SELECT TOP 1 'U' FROM SLS_IMPORT_DATA (NOLOCK) WHERE SP_ID=@NSPID and isnull(errormsg,'')<>'' )
	  begin
	      SELECT @CERRORMSG=errormsg  FROM SLS_IMPORT_DATA (NOLOCK) WHERE SP_ID=@NSPID and isnull(errormsg,'')<>''
		  GOTO END_PROC 
	  end

	  declare @cSHIPPING_MOBILE varchar(20)

	  SELECT @cSHIPPING_MOBILE=SHIPPING_MOBILE  FROM BUYER_ORDER_MST (nolock) WHERE ORDER_ID =@CORDER_ID

	  set @cSHIPPING_MOBILE=isnull(@cSHIPPING_MOBILE,'')

	  IF NOT EXISTS (SELECT TOP 1 'U' FROM custdym a (nolock) where customer_code =@cCUSTOMER_CODE
	         AND (MOBILE=@CSHIPPING_MOBILE OR USER_CUSTOMER_CODE =@CSHIPPING_MOBILE )) AND ISNULL(@CSHIPPING_MOBILE,'')<>''
		begin

		     SET @CERRORMSG='Mobile is difference from order booking mobile.'
		     GOTO END_PROC 

		end
	 

	   SET @cStep = 60
	  --SELECT @cpaymode_code= b.paymode_code 
	  --FROM BUYER_ORDER_MST A
	  --join paymode_mst b on a.Tendermode =b.paymode_name 
	  --WHERE A.ORDER_ID =@CORDER_ID

	  --if isnull(@cpaymode_code,'')=''
	  --   set @cpaymode_code='0000000'

		 SET @cStep = 70

				INSERT SLS_GST_TAXINFO_CALC	WITH (ROWLOCK)(MEMO_DT,SOURCE_DEPT_ID,PRODUCT_CODE, SP_ID ,NET_VALUE,TAX_METHOD,ROW_ID,QUANTITY ,MRP)  
				SELECT @DCM_DT,@CLOCATIONID AS DEPT_ID,a.PRODUCT_CODE,@NSPID AS SP_ID,
				( a.NET-ISNULL(a.CMM_DISCOUNT_AMOUNT,0)) AS NET_VALUE,2 AS TAX_METHOD,a.ROW_ID,a.QUANTITY,a.MRP
				FROM SLS_IMPORT_DATA  A
				WHERE a.SP_ID=@NSPID  
		

			SET @CSTEP = 80
			EXEC SP_CHKXNSAVELOG 'SLS_OL',@CSTEP,0,@NSPID,1	

			IF EXISTS (SELECT TOP 1 PRODUCT_CODE FROM SLS_GST_TAXINFO_CALC WITH (NOLOCK) WHERE SP_ID=@NSPID)
			BEGIN 			
		
				SET @CSTEP = 90
				EXEC SP_CHKXNSAVELOG 'SLS_OL',@CSTEP,0,@NSPID,1
	
		
				EXEC SP3S_GST_TAX_CAL_SLS
				@CXN_TYPE='SLS',
				@CMEMO_ID='',
				@DMEMO_DT=@DCM_DT ,
				@NSPID=@NSPID,
				@CPARTYSTATE_CODE=@CPARTYSTATECODE,
				@BLOCALBILL= 0,
				@CPARTY_GSTN_NO=@cPartyGstno,
				@CLOCATIONID=@CLOCATIONID,
				@CERRMSG=@CERRORMSG OUTPUT


				IF ISNULL(@CERRORMSG,'')<>''
					GOTO END_PROC
		
		--alter table SLS_IMPORT_DATA add XN_VALUE_WITH_GST numeric(14,2)
		--alter table SLS_IMPORT_DATA add GST_CESS_PERCENTAGE numeric(6,2)
		--alter table SLS_IMPORT_DATA add GST_CESS_AMOUNT numeric(10,2)
				SET @CSTEP = 100
						UPDATE A SET GST_PERCENTAGE=B.GST_PERCENTAGE,
										IGST_AMOUNT=B.IGST_AMOUNT,
										CGST_AMOUNT=B.CGST_AMOUNT,
										SGST_AMOUNT=B.SGST_AMOUNT,
										XN_VALUE_WITHOUT_GST=B.XN_VALUE_WITHOUT_GST,
										XN_VALUE_WITH_GST=B.XN_VALUE_WITH_GST,
										HSN_CODE=B.HSN_CODE,	
										GST_CESS_PERCENTAGE=B.GST_CESS_PERCENTAGE,
										GST_CESS_AMOUNT=B.GST_CESS_AMOUNT
						FROM SLS_IMPORT_DATA A WITH (ROWLOCK)
						JOIN SLS_GST_TAXINFO_CALC B WITH (NOLOCK) ON B.PRODUCT_CODE=A.PRODUCT_CODE AND B.ROW_ID=A.ROW_ID AND B.SP_ID=A.SP_ID
						WHERE B.SP_ID=@NSPID
			end


	 declare @SHIPPING_GSTIN varchar(20),@NOTHER_CHARGES NUMERIC(14,2),@REF_NO varchar(100)

	 SELECT @SHIPPING_GSTIN=SHIPPING_GSTIN ,@NOTHER_CHARGES=A.OTHER_CHARGES,@REF_NO=A.REF_NO 
	 FROM BUYER_ORDER_MST A (NOLOCK)
	 WHERE ORDER_ID=@CORDER_ID



      
		SELECT @NET_AMOUNT=SUM(NET) FROM SLS_IMPORT_DATA (NOLOCK)
	    WHERE SP_ID=@NSPID 

		if isnull(@NOTHER_CHARGES,0)<>0
		   set @NET_AMOUNT=@NET_AMOUNT+@NOTHER_CHARGES
			
		DECLARE @CPICKROUNDITEMLEVELFROMLOC VARCHAR(4)
		SELECT TOP 1 @CPICKROUNDITEMLEVELFROMLOC = VALUE  FROM CONFIG WHERE  CONFIG_OPTION='PICK_SLS_ROUND_OFF_FROMLOC'
	
		IF ISNULL(@CPICKROUNDITEMLEVELFROMLOC,'')<>'1'
			SELECT TOP 1 @CROUNDBILLLEVEL=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='SLS_ROUND_BILL_LEVEL' 
		ELSE
			SELECT TOP 1 @CROUNDBILLLEVEL = SLS_ROUND_BILL_LEVEL  FROM LOCATION (NOLOCK) WHERE DEPT_ID=@CLOCATIONID
	
	SET @CSTEP = 110
	EXEC SP_CHKXNSAVELOG 'SLS_OL',@CSTEP,0,@NSPID,1

	SET @NROUND_OFF= (CASE WHEN ISNULL(@CROUNDBILLLEVEL,'')='4' THEN 0
	WHEN ISNULL(@CROUNDBILLLEVEL,'')='2' THEN ROUND(@NET_AMOUNT/5,0)*5-@NET_AMOUNT
	WHEN ISNULL(@CROUNDBILLLEVEL,'')='3' THEN CEILING(@NET_AMOUNT/5)*5-@NET_AMOUNT  
	ELSE ROUND(@NET_AMOUNT,0)-@NET_AMOUNT  END)
	
	SET @NET_AMOUNT=@NET_AMOUNT+@NROUND_OFF 	
	
			
	DECLARE @nTotalCmdwithGst NUMERIC(14,2)
	SELECT @nTotalCmdwithGst=SUM( isnull(XN_VALUE_WITHOUT_GST,0)+isnull(IGST_AMOUNT,0)+isnull(CGST_AMOUNT,0)+isnull(SGST_AMOUNT,0)+isnull(GST_CESS_AMOUNT,0)) 
	FROM SLS_IMPORT_DATA A (NOLOCK)  WHERE A.SP_ID=@NSPID

     SET @cStep = 120
	EXEC SP_CHKXNSAVELOG 'SLS_after',@cStep,0,@NSPID,1

	 SET @GST_ROUND_OFF=(@NET_AMOUNT-(@NROUND_OFF+@nTotalCmdwithGst+isnull(@NOTHER_CHARGES,0))) 

	
	
	SET @cStep = 125
	  INSERT cmm01106 ( REMARKS, SENT_FOR_RECON, PARTY_TYPE, AC_CODE, MANUAL_DISCOUNT, MANUAL_ROUNDOFF                                  
	   , BIN_ID, PATCHUP_RUN, SUBTOTAL_R, PASSPORT_NO, TICKET_NO, FLIGHT_NO, MRP_WSP                                  
	   , MANUAL_BILL, FC_RATE, POSTEDINAC, CM_NO, CM_DT, CM_MODE, SUBTOTAL, DT_CODE                                  
	   , DISCOUNT_PERCENTAGE, DISCOUNT_AMOUNT, NET_AMOUNT, CUSTOMER_CODE, CANCELLED, USER_CODE                                  
	   , LAST_UPDATE, EXEMPTED,  SENT_TO_HO, CM_TIME, CM_ID, REF_CM_ID, FIN_YEAR                                  
	   , COPIES_PTD, ROUND_OFF, MEMO_TYPE, PAY_MODE, SMS_SENT, AUTOENTRY, CASH_TENDERED                                  
	   , PAYBACK, ECOUPON_ID, CAMPAIGN_GC_OTP, SALESSETUPINEFFECT, EDT_USER_CODE, GV_AMOUNT                                  
	   , SENT_FOR_GR,xn_item_type,oh_tax_method ,party_state_code,gst_round_off,TOTAL_QUANTITY 
	   ,Party_Gst_No ,atd_charges ,ref_no ,SUPPLY_TYPE_CODE,location_Code 
	   )    
   
	  SELECT 'Online SALE' AS REMARKS,0 AS SENT_FOR_RECON,1 AS PARTY_TYPE,'0000000000' AS AC_CODE                                  
		,0 AS MANUAL_DISCOUNT,0 AS MANUAL_ROUNDOFF, '000' BIN_ID,0 AS PATCHUP_RUN                                  
		,0 AS SUBTOTAL_R,'' AS PASSPORT_NO,'' AS TICKET_NO,'' AS FLIGHT_NO,                                  
		0 AS MRP_WSP,0 AS MANUAL_BILL,0 AS FC_RATE                                  
		,0 AS POSTEDINAC,@CMEMONOVAL CM_NO ,@DCM_DT CM_DT,1 AS CM_MODE                                  
		,SUM(NET) AS SUBTOTAL                                  
		,'0000000' AS DT_CODE,0 AS DISCOUNT_PERCENTAGE,SUM(ISNULL(CMM_DISCOUNT_AMOUNT,0)) AS DISCOUNT_AMOUNT                                  
		,@NET_AMOUNT AS NET_AMOUNT                             
		,@cCUSTOMER_CODE AS CUSTOMER_CODE,0 CANCELLED,@CUSER_CODE AS USER_CODE,GETDATE() AS LAST_UPDATE                                  
		,0 AS EXEMPTED,0 AS SENT_TO_HO,GETDATE() AS CM_TIME,@CKEYFIELDVAL1 CM_ID,'' AS REF_CM_ID                                  
		,@CFINYEAR FIN_YEAR,0 AS COPIES_PTD,@NROUND_OFF AS ROUND_OFF,1 AS MEMO_TYPE,1 AS PAY_MODE,0 AS SMS_SENT        
		,1 AS AUTOENTRY,0 AS CASH_TENDERED                                  
		,0 AS PAYBACK,'' AS ECOUPON_ID,'' AS CAMPAIGN_GC_OTP                                  
		,0 AS SALESSETUPINEFFECT,@CUSER_CODE AS EDT_USER_CODE,0 AS GV_AMOUNT                                  
		,0 AS SENT_FOR_GR  , 1 as xn_item_type ,1 as oh_tax_method, @CPARTYSTATECODE party_state_code  ,
		@GST_ROUND_OFF AS gst_round_off,sum(quantity) as TOTAL_QUANTITY,
		@SHIPPING_GSTIN SHIPPING_GSTIN,@NOTHER_CHARGES OTHER_CHARGES,@REF_NO REF_NO ,
		CASE WHEN @SHIPPING_GSTIN<>'' THEN 'B2B' ELSE 'B2C' END AS SUPPLY_TYPE_CODE,@CLOCATIONID as dept_id
	  FROM SLS_IMPORT_DATA
	  where sp_id=@NSPID 
      
	  SET @cStep = 60

	 DECLARE @NTOTABSQTY NUMERIC(10,2),@NTOTABSRFNET NUMERIC(10,2)

	SELECT @NTOTABSQTY=SUM(ABS(QUANTITY)),@NTOTABSRFNET=SUM(ABS(A.NET-isnull(CMM_DISCOUNT_AMOUNT,0)))   FROM SLS_IMPORT_DATA A                                  
    where sp_id=@NSPID 

   UPDATE A SET WEIGHTEDQTYBILLCOUNT=CONVERT(NUMERIC(6,2),CONVERT(NUMERIC(10,2),ABS(QUANTITY)) /CONVERT(NUMERIC(10,2),@NTOTABSQTY)) ,
              WEIGHTEDNRVBILLCOUNT=(CASE WHEN @NTOTABSRFNET=0 THEN 0 ELSE  CONVERT(NUMERIC(6,2),CONVERT(NUMERIC(10,2),ABS(a.net-isnull(CMM_DISCOUNT_AMOUNT,0) )) / CONVERT(NUMERIC(10,2),@NTOTABSRFNET)) END) 
   FROM SLS_IMPORT_DATA A                                  
   where sp_id=@NSPID 

    declare @ncalWEIGHTEDQTYBILLCOUNT numeric(6,2)
	select @ncalWEIGHTEDQTYBILLCOUNT=sum(WEIGHTEDQTYBILLCOUNT) from SLS_IMPORT_DATA A (NOLOCK) WHERE  sp_id=@NSPID 

	 if @ncalWEIGHTEDQTYBILLCOUNT<>1
	 begin
	      declare @crow_id varchar(50)
		  select top 1 @crow_id=row_id from SLS_IMPORT_DATA  where sp_id=@NSPID 
		  update A set WEIGHTEDQTYBILLCOUNT=WEIGHTEDQTYBILLCOUNT+(1-@ncalWEIGHTEDQTYBILLCOUNT) 
		  FROM SLS_IMPORT_DATA A (NOLOCK) where row_id =@crow_id

	 end


	 INSERT cmd01106 ( PRODUCT_CODE, QUANTITY, MRP, NET, BASIC_DISCOUNT_PERCENTAGE, DISCOUNT_PERCENTAGE,BASIC_DISCOUNT_AMOUNT, DISCOUNT_AMOUNT, ROW_ID, LAST_UPDATE                                  
   , TAX_PERCENTAGE, TAX_AMOUNT, EMP_CODE, SLSDET_ROW_ID, BIN_ID, OLD_MRP, REF_SLS_MEMO_ID                                  
   , REALIZE_SALE, CM_ID, RFNET, TAX_TYPE, TAX_METHOD, EAN, EMP_CODE1, EMP_CODE2, ITEM_DESC                                  
   , WEIGHTED_AVG_DISC_PCT, WEIGHTED_AVG_DISC_AMT, MANUAL_DISCOUNT, FIX_MRP, SR_NO, HOLD_FOR_ALTER                                  
   , PACK_SLIP_ID, XN_TYPE, REPEAT_PUR_ORDER, DEPT_ID, REF_ORDER_ID, FOC_QUANTITY, CMM_DISCOUNT_AMOUNT                                  
   , NRM_ID ,HSN_CODE   ,gst_percentage ,igst_amount ,cgst_amount,sgst_amount ,NET_SALE,pack_slip_row_id                        
   ,xn_value_without_gst,xn_value_with_gst,Gst_Cess_Percentage,Gst_Cess_Amount,ref_sls_memo_no,ref_sls_memo_dt
   ,WEIGHTEDQTYBILLCOUNT,WEIGHTEDNRVBILLCOUNT)                               

  SELECT    A.PRODUCT_CODE, A.QUANTITY, ISNULL(A.MRP,0),isnull(A.NET,0) AS NET,                                     
  ISNULL(A.CMD_DISCOUNT_PERCENTAGE,0) AS BASIC_DISCOUNT_PERCENTAGE                        
  ,ISNULL(a.CMD_DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE                        
  ,CMD_DISCOUNT_AMOUNT AS BASIC_DISCOUNT_AMOUNT,CMD_DISCOUNT_AMOUNT  AS DISCOUNT_AMOUNT                            
    ,A.DEPT_ID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,GETDATE() AS LAST_UPDATE                                  
    ,0 AS TAX_PERCENTAGE,0 AS TAX_AMOUNT,'0000000' AS EMP_CODE,'' AS SLSDET_ROW_ID,                                  
    a.BIN_ID AS BIN_ID,0 AS OLD_MRP,'' AS REF_SLS_MEMO_ID,0 AS REALIZE_SALE                                  
    ,@CKEYFIELDVAL1  CM_ID,A.NET AS RFNET,1 AS TAX_TYPE,1 AS TAX_METHOD,'' AS EAN,'0000000' AS EMP_CODE1                                  
    ,'0000000' AS EMP_CODE2,'' AS ITEM_DESC,0 AS WEIGHTED_AVG_DISC_PCT                                  
    ,0 AS WEIGHTED_AVG_DISC_AMT,                        
   0 AS MANUAL_DISCOUNT,0 AS FIX_MRP,0 AS SR_NO,0 AS HOLD_FOR_ALTER,'' AS PACK_SLIP_ID                                  
    ,'' AS XN_TYPE,0 AS REPEAT_PUR_ORDER,A.DEPT_ID,@CORDER_ID AS REF_ORDER_ID                                  
    ,0 AS FOC_QUANTITY,0 AS CMM_DISCOUNT_AMOUNT,'' AS NRM_ID,A.HSN_CODE   ,A.gst_percentage ,        
 isnull(A.igst_amount,0) as igst_amount ,isnull(A.cgst_amount,0) as cgst_amount,isnull(A.sgst_amount,0) as  sgst_amount                              
 ,A.NET AS NET_SALE,'' as pack_slip_row_id,A.xn_value_without_gst ,                  
 ISNULL(A.XN_VALUE_WITH_GST,0) ,Gst_Cess_Percentage,Gst_Cess_Amount,@CORDER_ID as ref_sls_memo_no,convert(dateTime,memo_dt,105) as ref_sls_memo_dt ,

  A.WEIGHTEDQTYBILLCOUNT,
  A.WEIGHTEDNRVBILLCOUNT
 FROM SLS_IMPORT_DATA A                                  
 where sp_id=@NSPID 

            
 PRINT 'PROCESSING STEP #'+@CSTEP+'#'+CONVERT(VARCHAR,GETDATE(),113)                                  
                                 
    SET @cStep = 70
	Declare @nPaymodeAmt Numeric(14,2)

	select @nPaymodeAmt= sum(Amount) from SLS_paymode_xn_det_UPLOAD A
	where a.sp_id =@CORDER_ID 

	if isnull(@nPaymodeAmt,0)<>@NET_AMOUNT
	begin

	   	SET @CERRORMSG='Bill Total Amount :'+ltrim(rtrim(str(@NET_AMOUNT,10,2)))+' is not matching with Paymode Total :'+
		ltrim(rtrim(str(@nPaymodeAmt,10,2)))
		GOTO END_PROC

	end

	
   INSERT paymode_xn_det( MEMO_ID, XN_TYPE, PAYMODE_CODE, ROW_ID, AMOUNT, LAST_UPDATE, REF_NO                                  
   , ADJ_MEMO_ID, CURRENCY_CONVERSION_RATE, REMARKS, GV_SRNO, GV_SCRATCH_NO)                                    
   SELECT    @CKEYFIELDVAL1  AS MEMO_ID,'SLS' AS XN_TYPE,a.paymode_code   PAYMODE_CODE                                  
   ,@CLOCATIONID+CONVERT(VARCHAR(40),NEWID()) AS ROW_ID,
   a.amount AS AMOUNT,GETDATE() AS LAST_UPDATE,a.ref_no AS REF_NO,a.adj_memo_id AS ADJ_MEMO_ID                                  
   ,1 AS CURRENCY_CONVERSION_RATE,'Online Sale' AS REMARKS,'' AS GV_SRNO,'' AS GV_SCRATCH_NO                                   
    from SLS_paymode_xn_det_UPLOAD A
	where a.sp_id =@CORDER_ID --In spid column passed with orderid

	DELETE A FROM SAVETRAN_BARCODE_NETQTY A (NOLOCK) WHERE SP_ID=@NSPID
	IF ISNULL(@cAUTO_ALLOCATE_ONLINE_ORDERS,'')<>'1'
	BEGIN

		INSERT SAVETRAN_BARCODE_NETQTY(SP_ID,PRODUCT_CODE,DEPT_ID,BIN_ID,XN_QTY,new_entry,xn_bo_order_id)
		SELECT @nSpId AS sp_id,CD.PRODUCT_CODE,@CLOCATIONID,CD.BIN_ID,
		(CD.QUANTITY+ISNULL(CD.FOC_QUANTITY,0)) AS XN_QTY,1 as new_entry,ISNULL(cd.REF_ORDER_ID,'') xn_bo_order_id
		FROM CMM01106 CM (NOLOCK)
		JOIN cmd01106 CD (NOLOCK) ON CM.cm_id=CD.cm_id
		WHERE CM.cm_id=@CKEYFIELDVAL1 

    END
	ELSE 
	BEGIN

	    INSERT SAVETRAN_BARCODE_NETQTY(SP_ID,PRODUCT_CODE,DEPT_ID,BIN_ID,XN_QTY,new_entry,xn_bo_order_id)
		SELECT @nSpId AS sp_id,CD.PRODUCT_CODE,@CLOCATIONID,CD.BIN_ID,
		(CD.QUANTITY+ISNULL(CD.FOC_QUANTITY,0)) AS XN_QTY,1 as new_entry,'' xn_bo_order_id
		FROM CMM01106 CM (NOLOCK)
		JOIN cmd01106 CD (NOLOCK) ON CM.cm_id=CD.cm_id
		WHERE CM.cm_id=@CKEYFIELDVAL1 

	END

	EXEC SP_CHKXNSAVELOG 'SLS_OL',@cStep,0,@NSPID,1	  
	
	declare @BALLOWNEGSTOCK bit,@BNEGSTOCKFOUND BIT

	SELECT @BALLOWNEGSTOCK =VALUE FROM USER_ROLE_DET A (NOLOCK)
	JOIN USERS B (NOLOCK) ON A.ROLE_ID=B.ROLE_ID 
	WHERE USER_CODE=@CUSER_CODE 
	AND FORM_NAME='FRMSALE' 
	AND FORM_OPTION='ALLOW_NEG_STOCK'		
	
	IF @CUSER_CODE='0000000'
	SET @BALLOWNEGSTOCK=0

	SET @BALLOWNEGSTOCK =ISNULL(@BALLOWNEGSTOCK,0)

			EXEC SP3S_UPDATE_PMTSTOCK_SLS
			@nUpdatemode=1,
			@bREvertFlag=0,
			@BALLOWNEGSTOCK=@BALLOWNEGSTOCK,
			@nSpId=@nSpId,
			@CERRORMSG=@CERRORMSG OUTPUT,
			@BNEGSTOCKFOUND=@BNEGSTOCKFOUND OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
		 
		 DECLARE @STR VARCHAR(MAX)
		 SET @STR=NULL
	

      	SELECT  @STR =  COALESCE(@STR +  '/ ', ' ' ) + (''+C.UOM_NAME+': '+CAST(SUM(QUANTITY) AS VARCHAR) +' ')  
		 FROM CMD01106 A  (NOLOCK)
		 JOIN SKU S (NOLOCK) ON S.PRODUCT_CODE=A.PRODUCT_CODE
		 JOIN ARTICLE B (NOLOCK) ON S.ARTICLE_CODE=B.ARTICLE_CODE
		 JOIN UOM C (NOLOCK) ON C.UOM_CODE=B.UOM_CODE
		WHERE a.cm_id=@NSPID GROUP BY C.UOM_NAME ,CM_ID

        UPDATE CMM01106 WITH (ROWLOCK) SET TOTAL_QUANTITY_STR =@STR,HO_SYNCH_LAST_UPDATE ='' WHERE cm_id=@CKEYFIELDVAL1

   SELECT @NBOQTY= SUM(CASE WHEN B.SaleReturnType =2 THEN -1 ELSE 1 END* QUANTITY),@NBONET= SUM(CASE WHEN B.SaleReturnType =2 THEN -1 ELSE 1 END* (WS_PRICE*a.quantity)) 
   FROM BUYER_ORDER_DET A (NOLOCK) 
   join BUYER_ORDER_MST b (NOLOCK)  on a.order_id =b.order_id
   WHERE A.order_id =@CORDER_ID 

   SELECT @NSLSQTY = SUM(QUANTITY),@NSLSNET = SUM(NET) 
   FROM CMD01106 (NOLOCK) WHERE CM_ID=@CKEYFIELDVAL1

   IF ISNULL(@NBOQTY,0)<>ISNULL(@NSLSQTY,0)
   BEGIN
        
	 SET @cErrormsg='Qty mismatch Bo Qty: ' +RTRIM(LTRIM(STR(@NBOQTY)))+ ' Sale Qty: '+RTRIM(LTRIM(STR(@NSLSQTY)))        
     GOTO END_PROC  

   END

    IF ABS(ISNULL(@NBONET,0)-ISNULL(@NSLSNET,0))>.5
   BEGIN
        
	 SET @cErrormsg='net mismatch Bo Net: ' +RTRIM(LTRIM(STR(@NBONET)))+ ' Sale Net '+RTRIM(LTRIM(STR(@NSLSNET)))        
     GOTO END_PROC  

   END

  EXEC  UPDATERFNET 'SLS',@CKEYFIELDVAL1      
  
  --select * from CMM01106 where cm_id='03011230000301-0000050'
  
  --select * from CMd01106 where cm_id='03011230000301-0000050'
  
  --select * from paymode_xn_det where memo_id='03011230000301-0000050'
                  
  GOTO END_PROC                          
                            
END TRY                          
                           
BEGIN CATCH                         
  PRINT 'ENTER CATCH BLOCK'                       
  SET @cErrormsg='Savetran_online_Sale  : AT STEP - '+@CSTEP+', MESSAGE - '+ERROR_MESSAGE()                    
  PRINT   @cErrormsg                    
  GOTO END_PROC                           
END CATCH                          
                           
END_PROC:                          
                
                 
                 
  IF @@TRANCOUNT>0                          
  BEGIN                   
                  
    IF ISNULL(@cErrormsg,'')=''  and isnull(@BNEGSTOCKFOUND,0)=0                          
    BEGIN    
	    PRINT 'COMMIT'                          
		commit 
		                
                      
    END                           
    ELSE                          
    BEGIN   
	
        PRINT 'ROLLBACK TRANSACTION'                          
		ROLLBACK           
    
    END                          
                   
  END                       
      	SELECT @CERRORMSG as Errmsg,ISNULL(@CKEYFIELDVAL1,'')	as MEMO_ID 
		DELETE A  FROM SLS_PAYMODE_XN_DET_UPLOAD A (NOLOCK) WHERE A.SP_ID =@CORDER_ID  
        DELETE A FROM SAVETRAN_BARCODE_NETQTY A (NOLOCK) WHERE SP_ID=@NSPID
                           
END 