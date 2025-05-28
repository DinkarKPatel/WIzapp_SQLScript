CREATE PROCEDURE VALIDATEXN_SLS_AFTERSAVE
@NUPDATEMODE NUMERIC(1,0),
@NSPID VARCHAR(40)='',
@BDEBUGMODE BIT,
@CCMID VARCHAR(40)='',
@BGSTBILL BIT,
@CERRORMSG VARCHAR(MAX) OUTPUT,
@BCALLEDFORPRINT BIT=0,
@CDEPT_ID VARCHAR(5)/**//*Rohit 07-11-2024*/=''
AS
BEGIN
	DECLARE @BDONOTCALCULATEGST BIT ,@cStep VARCHAR(5),@cDiffPc VARCHAR(100),@nStoredVal NUMERIC(10,3),
	@nCalcVal NUMERIC(10,3)
		
	BEGIN TRY
		
		SET @CSTEP='V-5'
		EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@NSPID,1	
		
		SET @CERRORMSG=''

		IF @NUPDATEMODE=5
			GOTO lblPaymodeValidation
		
		IF @BCALLEDFORPRINT=1
		BEGIN
			/*SET @CDEPT_ID=LEFT(@cCmId,2)*//*Rohit 07-11-2024*/
			SELECT @CDEPT_ID=LOCATION_CODE FROM CMM01106(NOLOCK) WHERE CM_ID=@CCMID
		END

		DECLARE @cOtherCmno VARCHAR(40),@dOtherCmdt datetime,@cPsNo VARCHAR(40)	
		SELECT TOP 1 @cOtherCmno=d.cm_no,@dOtherCmdt=d.cm_dt,@cPsNo=b.cm_no
		from rps_det a (NOLOCK) JOIN rps_mst b (NOLOCK) ON a.cm_id=b.cm_id
		JOIN SLS_cmd01106_UPLOAD c (NOLOCK) ON c.PACK_SLIP_ID=a.cm_id
		JOIN cmm01106 d (NOLOCK) ON d.cm_id=b.ref_cm_id
		WHERE c.sp_id=@nSpId AND b.ref_cm_id<>c.cm_id AND ISNULL(b.ref_cm_id,'')<>''	 

		IF isnull(@cOtherCmno,'')<>''
		BEGIN
			SET @cErrormsg='Bill no. :'+@cOtherCmno+' Dated: '+convert(varchar,@dOtherCmdt,105)+'
						    already generated for Pack Slip no. :'+@cPsNo+'.....Cannot Save'
			GOTO END_PROC
		END				    	
		
		IF @CCMID<>''
		BEGIN
			DECLARE @nTotQty numeric(10,2),@nCmdQty NUMERIC(10,2),@nTotAmt NUMERIC(10,2),@nPaymodeAmt NUMERIC(10,2)

			SET @CSTEP='V-10'
			EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@NSPID,1	
			SELECT @nTotQty=total_quantity,@nTotAmt=NET_AMOUNT from  CMM01106 (nolock) where CM_ID=@cCmId

			SELECT @nCmdQty=SUM(quantity) FROM  cmd01106 (NOLOCK) WHERE cm_id=@cCmId

			IF ISNULL(@nTotqty,0)<>ISNULL(@nCmdQty,0)
			BEGIN
				SET @CERRORMSG='Bill Total quantity :'+ltrim(rtrim(str(@nTotQty,10,2)))+' is not matching with Detail Qty :'+
				ltrim(rtrim(str(@nCmdQty,10,2)))
				GOTO END_PROC
			END

			SET @CSTEP='V-15'
			EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@NSPID,1	

		END
--VALIDATEION#11 ( FOR GST )
	
		IF @CCMID<>'' AND @BGSTBILL=1
		BEGIN
			SET @CSTEP='V-85'
			EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@NSPID,1	
		     
			IF ISNULL(@BCALLEDFORPRINT,0)=1
			BEGIN

				IF EXISTS (SELECT TOP 1 'U' FROM CMD01106 (NOLOCK) WHERE CM_ID =@CCMID AND ISNULL(GST_PERCENTAGE,0)=0 AND (NET-ISNULL(CMM_DISCOUNT_AMOUNT,0))<>0) 
				BEGIN

  				    SET @BDONOTCALCULATEGST=0

					IF EXISTS (  SELECT TOP 1 'U' FROM CMM01106 A (NOLOCK)
					JOIN CUSTDYM B (NOLOCK) ON A.CUSTOMER_CODE=B.CUSTOMER_CODE
					WHERE A.CM_ID =@CCMID AND ISNULL(B.CUSTDYM_EXPORT_GST_PERCENTAGE_APPLICABLE,0)=1
					AND ISNULL(B.CUSTDYM_EXPORT_GST_PERCENTAGE,0)=0	)
					SET @BDONOTCALCULATEGST=1

						IF ISNULL(@BDONOTCALCULATEGST,0)=0
						BEGIN

							EXEC SP3S_CMD_ZERO_GST_CAL @CCMID,@CERRORMSG=@CERRORMSG OUTPUT
							IF ISNULL(@CERRORMSG,'')<>''
								GOTO END_PROC
						END
				END

			END
			
			EXEC SP3S_VALIDATE_GSTCALC		
			@XN_TYPE='SLS',
			@CMEMO_ID=@CCMID,
			@CERRMSG=@CERRORMSG OUTPUT,
			@CDEPT_ID=@CDEPT_ID
			IF ISNULL(@CERRORMSG,'')<>''
				GOTO END_PROC
		END

		DECLARE @CROUNDITEMLEVEL varchar(2),@CPickRoundITEMLEVELFromLoc varchar(2),@nRoundupto NUMERIC(2,0)

		SELECT TOP 1 @CPickRoundITEMLEVELFromLoc = VALUE  FROM CONFIG WHERE  CONFIG_OPTION='Pick_SLS_ROUND_OFF_fromloc'

		if isnull(@CPickRoundITEMLEVELFromLoc,'')<>'1'
			SELECT TOP 1 @CROUNDITEMLEVEL = VALUE  FROM CONFIG WHERE  CONFIG_OPTION='SLS_ROUND_ITEM_NET'
		ELSE
			SELECT TOP 1 @CROUNDITEMLEVEL = sls_round_item_level  FROM location (NOLOCK) WHERE dept_id=@CDEPT_ID

		SET @CROUNDITEMLEVEL=ISNULL(@CROUNDITEMLEVEL,'')


		--Removed these validations as per issue came at TheBigshop Ranchi reported by Arun/Rohit and Rohit said that Sir had
		-- asked to remove this validation on discount component if we are already calculating it at APplication level (Date:24-04-2024)
		--SET @nRoundupto = (CASE WHEN @CROUNDITEMLEVEL='1' then 0 else 2 end)
		------Needed to put this validation as per Whatsapp msg by Sir on 22-10-2022 reported at a client
		------These validations are already being shifted to Application but not being applied (Sanjay : 25-10-2022)
		--IF EXISTS (SELECT TOP 1 row_id FROM cmd01106 (NOLOCK) WHERE cm_id=@CCMID AND 
		--		   ABS(round(mrp*quantity*discount_percentage/100,@nRoundupto)-discount_amount)>1.02
		--		   AND ISNULL(manual_discount,0)=0)
		--BEGIN
		--	SELECT TOP 1 @cDiffPc=product_code,@nCalcVal=round(mrp*quantity*discount_percentage/100,@nRoundupto),
		--	@nStoredVal=discount_amount
		--	FROM cmd01106 (NOLOCK) WHERE cm_id=@CCMID AND ABS(round(mrp*quantity*discount_percentage/100,@nRoundupto)-discount_amount)>1.02
		--    AND ISNULL(manual_discount,0)=0

		--	SET @CERRORMSG='Mismatch found in Discount calculation for Item Code :'+@cDiffPc+' calculated :'+ltrim(rtrim(str(@nCalcVal,10,2)))+
		--		' stored :'+ltrim(rtrim(str(@nStoredVal,10,2)))

		--	GOTO END_PROC
		--END

		--IF EXISTS (SELECT TOP 1 row_id FROM cmd01106 (NOLOCK) WHERE cm_id=@CCMID AND ABS(round(mrp*quantity*basic_discount_percentage/100,@nRoundupto)-basic_discount_amount)>1.02
		--		   AND ISNULL(manual_discount,0)=0)
		--BEGIN
		--	SELECT TOP 1 @cDiffPc=product_code,@nCalcVal=round(mrp*quantity*basic_discount_percentage/100,@nRoundupto),
		--	@nStoredVal=basic_discount_amount
		--	FROM cmd01106 (NOLOCK) WHERE cm_id=@CCMID AND ABS(round(mrp*quantity*basic_discount_percentage/100,@nRoundupto)-
		--	basic_discount_amount)>1.02
		--    AND ISNULL(manual_discount,0)=0

		--	SET @CERRORMSG='Mismatch found in Basic discount calculation for Item Code :'+@cDiffPc+' calculated :'+ltrim(rtrim(str(@nCalcVal,10,2)))+
		--		' stored :'+ltrim(rtrim(str(@nStoredVal,10,2)))
		--	GOTO END_PROC
		--END

		--IF EXISTS (SELECT TOP 1 row_id FROM cmd01106 (NOLOCK) WHERE cm_id=@CCMID AND 
		--		  ABS(ROUND(((BASIC_DISCOUNT_AMOUNT+
		--		   (CASE WHEN @CROUNDITEMLEVEL='1' THEN (ROUND(MRP*QUANTITY*BASIC_DISCOUNT_PERCENTAGE/100,2)-ROUND(MRP*QUANTITY*BASIC_DISCOUNT_PERCENTAGE/100,0))
		--		         ELSE 0 END))
		--		   /(MRP*QUANTITY))*100,2)-BASIC_DISCOUNT_PERCENTAGE)>0.2
		--		   AND ISNULL(MANUAL_DP,0)=0)
		--BEGIN
		--	SELECT TOP 1 @cDiffPc=product_code,@nCalcVal=ROUND(((BASIC_DISCOUNT_AMOUNT+
		--					   (CASE WHEN @CROUNDITEMLEVEL='1' AND ISNULL(manual_discount,0)=0 THEN (ROUND(MRP*QUANTITY*BASIC_DISCOUNT_PERCENTAGE/100,2)-ROUND(MRP*QUANTITY*BASIC_DISCOUNT_PERCENTAGE/100,0))
		--		                     ELSE 0 END))/(MRP*QUANTITY))*100,2),
		--	@nStoredVal=basic_discount_percentage
		--	FROM cmd01106 (NOLOCK) WHERE cm_id=@CCMID AND ABS(ROUND(((BASIC_DISCOUNT_AMOUNT+
		--					   (CASE WHEN @CROUNDITEMLEVEL='1' AND ISNULL(manual_discount,0)=0 THEN (ROUND(MRP*QUANTITY*BASIC_DISCOUNT_PERCENTAGE/100,2)-ROUND(MRP*QUANTITY*BASIC_DISCOUNT_PERCENTAGE/100,0))
		--		         ELSE 0 END))/(MRP*QUANTITY))*100,2)-BASIC_DISCOUNT_PERCENTAGE)>0.2
		--    AND ISNULL(MANUAL_DP,0)=0

		--	SET @CERRORMSG='Mismatch found in Basic discount %age calculation for Item Code :'+@cDiffPc+' calculated :'+ltrim(rtrim(str(@nCalcVal,10,2)))+
		--		' stored :'+ltrim(rtrim(str(@nStoredVal,10,2)))
			
		--	GOTO END_PROC
		--END

		--IF EXISTS (SELECT TOP 1 row_id FROM cmd01106 (NOLOCK) WHERE cm_id=@CCMID AND 
		--		   ABS(ROUND(((DISCOUNT_AMOUNT+(CASE WHEN @CROUNDITEMLEVEL='1' AND ISNULL(manual_discount,0)=0 THEN (ROUND(MRP*QUANTITY*BASIC_DISCOUNT_PERCENTAGE/100,2)-ROUND(MRP*QUANTITY*BASIC_DISCOUNT_PERCENTAGE/100,0))
		--		                     ELSE 0 END))/(MRP*QUANTITY))*100,2)-DISCOUNT_PERCENTAGE)>0.2
		--		   AND ISNULL(MANUAL_DP,0)=0)
		--BEGIN
		--	SELECT TOP 1 @cDiffPc=product_code,@nCalcVal=round((discount_amount/(mrp*quantity))*100,2),
		--	@nStoredVal=discount_percentage
		--	FROM cmd01106 (NOLOCK) WHERE cm_id=@CCMID AND ABS(ROUND(((DISCOUNT_AMOUNT+(CASE WHEN @CROUNDITEMLEVEL='1' AND 
		--	ISNULL(manual_discount,0)=0 THEN (ROUND(MRP*QUANTITY*BASIC_DISCOUNT_PERCENTAGE/100,2)-ROUND(MRP*QUANTITY*BASIC_DISCOUNT_PERCENTAGE/100,0))
		--		                     ELSE 0 END))/(MRP*QUANTITY))*100,2)-DISCOUNT_PERCENTAGE)>0.2
		--		   AND ISNULL(MANUAL_DP,0)=0

		--	SET @CERRORMSG='Mismatch found in Discount Percent calculation for Item Code :'+@cDiffPc+' calculated :'+ltrim(rtrim(str(@nCalcVal,10,2)))+
		--		' stored :'+ltrim(rtrim(str(@nStoredVal,10,2)))
		--	GOTO END_PROC
		--END

lblPaymodeValidation:

		SELECT @nPaymodeAmt=sum(amount) FROM paymode_xn_det (NOLOCK) WHERE memo_id=@cCmId and xn_type='SLS'

		IF ISNULL(@nTotAmt,0)<>ISNULL(@nPaymodeAmt,0)
		BEGIN
			SET @CERRORMSG='Bill Total Amount :'+ltrim(rtrim(str(@nTotAmt,10,2)))+' is not matching with Paymode Total :'+
			ltrim(rtrim(str(@nPaymodeAmt,10,2)))
			GOTO END_PROC
		END

		IF EXISTS (SELECT TOP 1 memo_id FROM paymode_xn_det a (NOLOCK) WHERE memo_id=@CCMID AND paymode_code IN ('0000001','0000002')
				   AND (ISNULL(ref_no,'')='' OR ISNULL(a.adj_memo_id,'')=''))
		BEGIN
			DECLARE @cPaymodeCode CHAR(7),@cRefNo VARCHAR(50),@cAdjMemoId VARCHAR(50)

			SELECT TOP 1 @cPaymodeCode=paymode_code,@cRefno=ISNULL(ref_no,''),@cAdjMemoId=ISNULL(adj_memo_id,'')
			FROM paymode_xn_det a (NOLOCK) WHERE memo_id=@CCMID AND paymode_code IN ('0000001','0000002')
			AND (ISNULL(ref_no,'')='' OR ISNULL(a.adj_memo_id,'')='')

			SET @CERRORMSG='Invalid '+(CASE WHEN @cPaymodeCode='0000001' then 'Credit Note' ELSE 'Advance' END)+
			' Reference details found....Cannot Save' 
		END


	END TRY
	
	BEGIN CATCH
		SET @CERRORMSG='ERROR IN PROCEDURE VALIDATEXN_SLS_AFTERSAVE STEP#'+@CSTEP+' '+ERROR_MESSAGE()
		GOTO END_PROC 
	END CATCH

END_PROC:

END