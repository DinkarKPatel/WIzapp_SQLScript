CREATE PROCEDURE SP3S_PROCESS_CASHMEMO_ADJ
(
  @CSPID varchar(50),
  @CLOCATIONID VARCHAR(4)=''
)
AS
BEGIN
     

 DECLARE @CERRORMSG VARCHAR(MAX),@NSTEP NUMERIC(5,0) ,@CCMD NVARCHAR(MAX),@CMEMONO VARCHAR(20),@CMEMONOVAL VARCHAR(50),
         @CKEYSTABLE VARCHAR(100),@CUSERALIAS VARCHAR(10),@CMEMONOPREFIX VARCHAR(25),@CMASTERTABLENAME VARCHAR(100),@NMEMONOLEN	NUMERIC(20,0),
		 @NSAVETRANLOOP	BIT,@CKEYFIELDVAL1	VARCHAR(50),@DCMDT DATETIME,@dlastdtmonth datetime

		
		   
 BEGIN TRY   
  BEGIN TRAN  
 


  IF ISNULL(@CLOCATIONID,'')=''  
		SELECT @CLOCATIONID =DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
  ELSE  
		SELECT @CLOCATIONID = @CLOCATIONID  

  IF ISNULL(@CLOCATIONID,'')=''
	 BEGIN
		SET @CERRORMSG ='1. LOCATION ID CAN NOT BE BLANK  '  
		GOTO END_PROC    
	 END
	
	   SET @NSTEP=00


	   if not exists (select  top 1 'u' from CASHMEMO_ADJ_DET_UPLOAD where sp_id=@CSPID)
	   begin
	       SET @CERRORMSG ='no item found for bill adjustment '  
	    	GOTO END_PROC   

	   end
	           
			   IF OBJECT_ID ('TEMPDB..#TMPCMMADJ','U') IS NOT NULL
			       DROP TABLE #TMPCMMADJ

				  SELECT CM_ID ,isnull(ReduceMrp,0) ReduceMrp
				  into #TMPCMMADJ
				  FROM CASHMEMO_ADJ_DET_UPLOAD (nolock)
				  WHERE SP_ID=@CSPID
				  GROUP BY CM_ID,isnull(ReduceMrp,0)


				  update a set
						   OLD_MRP =A.MRP ,
						   OLD_NET =A.NET ,
						   old_discount_percentage=a.discount_percentage,
						   old_discount_amount=a.discount_amount,
						   old_cmm_discount_amount=a.cmm_discount_amount,
						   old_gst_percentage=a.gst_percentage,
						   old_gst_Amount=isnull(a.igst_amount,0)+isnull(a.Cgst_amount,0)+isnull(a.Sgst_amount,0),
						   old_xn_value_without_gst=a.xn_value_without_gst,
						   old_xn_value_with_gst=a.xn_value_with_gst,
						   old_igst_Amount=isnull(a.igst_amount,0),
						   old_cgst_Amount= isnull(a.Cgst_amount,0),
						   old_Sgst_Amount=isnull(a.Sgst_amount,0)
				  from cmd01106 a with (nolock)
				  join cmm01106 cmm (nolock) on a.cm_id =cmm.cm_id 
				  join #TMPCMMADJ  tmp on tmp.cm_id=a.cm_id  
				  where  isnull(cmm.patchup_run,0) =0
				  
				  update cmm set 
				       Old_subtotal_r=cmm.subtotal_r,
                       Old_DISCOUNT_PERCENTAGE=cmm.DISCOUNT_PERCENTAGE,
                       Old_DISCOUNT_AMOUNT=cmm.DISCOUNT_AMOUNT,
					   Old_NET_AMOUNT=cmm.NET_AMOUNT,
					   Old_round_off=cmm.round_off,
					   Old_subtotal=cmm.subtotal

				  from cmm01106 cmm (nolock) 
				  join #TMPCMMADJ  tmp on tmp.cm_id=cmm.cm_id  
				  where  isnull(cmm.patchup_run,0) =0


				  update p set OLd_amount =amount
				  from cmm01106 cmm (nolock) 
				  join #TMPCMMADJ  tmp on tmp.cm_id=cmm.cm_id  
				  join paymode_xn_det p (nolock)  on cmm.cm_id=p.memo_id 
				  where  isnull(cmm.patchup_run,0) =0
				

				
		SET @NSTEP=20
				  UPDATE A  SET MRP=b.NEW_MRP ,
								CARD_DISCOUNT_PERCENTAGE=0 ,
								CARD_DISCOUNT=0,
								basic_discount_percentage =b.NEW_DISCOUNT_PERCENTAGE,
							    basic_discount_amount =b.NEW_DISCOUNT_AMOUNT,
								DISCOUNT_PERCENTAGE=B.NEW_DISCOUNT_PERCENTAGE ,
								DISCOUNT_AMOUNT=B.NEW_DISCOUNT_AMOUNT ,
								cmm_discount_amount=b.cmm_discount_amount,
								Realize_sale=(isnull(B.OLD_NET,0)-isnull(b.cmm_discount_amount,0))
				  FROM CMD01106 A (NOLOCK)
				  JOIN CASHMEMO_ADJ_DET_UPLOAD B (NOLOCK) ON A.ROW_ID =B.ROW_ID 
				  WHERE B.SP_ID = @CSPID

				  update a set NET=(a.MRP*a.quantity)-a.DISCOUNT_AMOUNT
				  FROM CMD01106 A (NOLOCK)
				  JOIN CASHMEMO_ADJ_DET_UPLOAD B (NOLOCK) ON A.ROW_ID =B.ROW_ID 
				  WHERE B.SP_ID = @CSPID

		
                SET @NSTEP=30

		        UPDATE A SET SUBTOTAL =CASE WHEN B.NET>0 THEN B.NET ELSE 0 END,
                               SUBTOTAL_R =CASE WHEN B.NET<0 THEN B.NET ELSE 0 END
		        FROM CMM01106 A (NOLOCK)
				JOIN
				(
				SELECT a.cm_id  ,
					   SUM(NET) AS NET
				FROM cmd01106  A (nolock)
				join #TMPCMMADJ b on a.cm_id=b.cm_id 
				GROUP BY a.cm_id
				) B ON A.CM_ID =B.cm_id
				
				
				
			  --donot update discount percentage  in Reduce mrp bill level  

				SET @NSTEP=40
				UPDATE A SET   DISCOUNT_PERCENTAGE=CASE WHEN SUBTOTAL +SUBTOTAL_R=0 THEN 0 ELSE  ABS(ROUND((DISCOUNT_AMOUNT/(SUBTOTAL +SUBTOTAL_R ))*100,2)) END	
				FROM  CMM01106 A
				JOIN #TMPCMMADJ B ON A.CM_ID =B.CM_ID
				WHERE ( A.SUBTOTAL +SUBTOTAL_R )>A.DISCOUNT_AMOUNT 
				AND A.DISCOUNT_AMOUNT <>0 and  isnull(ReduceMrp,0)=0
				
	
		
		
				SET @NSTEP=50
				UPDATE A SET  DISCOUNT_AMOUNT =ROUND(SUBTOTAL *DISCOUNT_PERCENTAGE /100,2)
				FROM  CMM01106 A (nolock)
				JOIN  #TMPCMMADJ B ON A.CM_ID =B.CM_ID
				WHERE  A.DISCOUNT_AMOUNT <>0


                SET @NSTEP=60


			    UPDATE A SET 
			    CMM_DISCOUNT_AMOUNT =ROUND((CASE WHEN CMM.SUBTOTAL=0 THEN 0 ELSE ( NET*cmm.DISCOUNT_AMOUNT)/Stotal END),2)
				FROM CMD01106 A (nolock)
				join
				(
				  select cm_id ,SUM(CASE WHEN NET>0 THEN NET ELSE 0 END ) AS Stotal
				  from CMD01106 cmd (nolock)
				  GROUP BY cm_id
				) CMD ON A.cm_id=CMD.CM_ID
				JOIN #TMPCMMADJ B ON A.CM_ID   =B.cm_id
				JOIN CMM01106 CMM (NOLOCK) ON A.CM_ID =CMM.CM_ID 
				WHERE  net >0

				UPDATE A SET 
			    CMM_DISCOUNT_AMOUNT =ROUND((CASE WHEN CMM.subtotal_r=0 THEN 0 ELSE (NET*cmm.DISCOUNT_AMOUNT)/Stotal_R END),2)
				FROM CMD01106 A (nolock)
				join
				(
				  select cm_id ,SUM(CASE WHEN NET<0 THEN NET ELSE 0 END ) AS Stotal_R
				  from CMD01106 cmd (nolock)
				  GROUP BY cm_id
				) CMD ON A.cm_id=CMD.CM_ID
				JOIN #TMPCMMADJ B ON A.CM_ID   =B.cm_id
				JOIN CMM01106 CMM (NOLOCK) ON A.CM_ID =CMM.CM_ID 
				WHERE net <0

     
	DELETE A FROM GST_TAXINFO_CALC A (NOLOCK) WHERE SP_ID=@CSPID   

	SET @NSTEP=100

          	INSERT GST_TAXINFO_CALC	( PRODUCT_CODE, SP_ID ,NET_VALUE,TAX_METHOD,ROW_ID,QUANTITY,
					LOC_STATE_CODE ,LOC_GSTN_NO,LOCREGISTERED,PARTY_STATE_CODE ,PARTY_GSTN_NO,PARTYREGISTERED,LOCALBILL,MEMO_DT,MRP,SOURCE_DEPT_ID )  
					SELECT PRODUCT_CODE,@CSPID AS SP_ID,(NET-ISNULL(CMM_DISCOUNT_AMOUNT,0)) AS NET_VALUE,
					CASE WHEN A.TAX_METHOD=1 THEN 2 ELSE 1 END  AS TAX_METHOD, ROW_ID,QUANTITY,SLOC.GST_STATE_CODE AS LOC_STATE_CODE,SLOC.LOC_GST_NO AS LOC_GSTN_NO,
					SLOC.REGISTERED_GST AS LOCREGISTERED,B.PARTY_STATE_CODE,
					(CASE WHEN ISNULL(B.AC_CODE,'0000000000') NOT IN ('','0000000000') THEN LM.AC_GST_NO ELSE '' END) AS 	PARTY_GSTN_NO,
					(CASE WHEN ISNULL(B.AC_CODE,'0000000000') NOT IN ('','0000000000') THEN LM.REGISTERED_GST_DEALER ELSE 0 END) AS PARTYREGISTERED,
					1 AS LOCALBILL ,
						  B.CM_DT,A.MRP,b.location_Code 
					FROM CMD01106 A  (nolock)
					JOIN CMM01106 B (nolock) ON A.CM_ID=B.CM_ID
					join #TMPCMMADJ tmp on a.cm_id =tmp.cm_id  
					JOIN LOCATION SLOC (nolock) ON SLOC.DEPT_ID=b.location_Code 
					JOIN CUSTDYM CUS (nolock) ON CUS.CUSTOMER_CODE=B.CUSTOMER_CODE
					LEFT OUTER JOIN LMP01106 LM (nolock) ON LM.AC_CODE=B.AC_CODE
					


               SET @NSTEP=110
					EXEC SP3S_GST_TAX_CAL_BATCH
					@CXN_TYPE='SLS',
					@NSPID=@CSPID,
					@CERRMSG=@CERRORMSG OUTPUT,
					@cLoginDeptId=@CLOCATIONID
					

				
					IF ISNULL(@CERRORMSG,'')<>''
						GOTO END_PROC
                 
				 SET @NSTEP=120
					
					UPDATE CMD01106 SET TAX_AMOUNT=0,TAX_PERCENTAGE=0,
					HSN_CODE=B.HSN_CODE,GST_PERCENTAGE=B.GST_PERCENTAGE,IGST_AMOUNT=B.IGST_AMOUNT,
					CGST_AMOUNT=B.CGST_AMOUNT,SGST_AMOUNT=B.SGST_AMOUNT,
					XN_VALUE_WITHOUT_GST=B.XN_VALUE_WITHOUT_GST,XN_VALUE_WITH_GST=B.XN_VALUE_WITH_GST,
					CESS_AMOUNT =ISNULL(b.CESS_AMOUNT,0)
					FROM GST_TAXINFO_CALC B WHERE B.ROW_ID=CMD01106.ROW_ID AND B.SP_ID=@CSPID

		        
	             SET @NSTEP=130

				UPDATE A SET  NET_AMOUNT=SUBTOTAL+SUBTOTAL_R+ATD_CHARGES+ISNULL(EXCLTAX,0)-DISCOUNT_AMOUNT +
				 +(CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0) end )
				FROM CMM01106 A (NOLOCK)
				JOIN
				(
				SELECT a.cm_id  ,
					   SUM(CASE WHEN TAX_METHOD=2 THEN ISNULL(TAX_AMOUNT,0)+ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0) ELSE 0 END 
					   ) AS EXCLTAX
				FROM CMD01106 A
				JOIN #TMPCMMADJ B ON A.cm_id   =B.cm_id
				GROUP BY a.cm_id
				) B ON A.CM_ID =B.cm_id 

		
		        declare @CROUNDBILLLEVEL varchar(10)
					
				SELECT TOP 1 @CROUNDBILLLEVEL=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='SLS_ROUND_BILL_LEVEL' 


				UPDATE A SET ROUND_OFF= (CASE WHEN ISNULL(@CROUNDBILLLEVEL,'')='2' THEN ROUND(NET_AMOUNT/5,0)*5-NET_AMOUNT
				WHEN ISNULL(@CROUNDBILLLEVEL,'')='3' THEN CEILING(NET_AMOUNT/5)*5-NET_AMOUNT  ELSE ROUND(NET_AMOUNT,0)-NET_AMOUNT  END)
				FROM CMM01106 A (NOLOCK) 
				JOIN #TMPCMMADJ B ON A.CM_ID =B.cm_id

			
	
				SET @NSTEP=150			
				UPDATE a SET NET_AMOUNT=NET_AMOUNT+ROUND_OFF 	
				FROM CMM01106 A (NOLOCK) 
				JOIN #TMPCMMADJ B ON A.CM_ID =B.cm_id

				UPDATE A SET AMOUNT =CMM.NET_AMOUNT 
				FROM PAYMODE_XN_DET A (NOLOCK) 
				JOIN CMM01106 CMM (NOLOCK) ON A.MEMO_ID= CMM.CM_ID 
				JOIN #TMPCMMADJ B ON A.memo_id  =B.cm_id
				WHERE A.XN_TYPE ='SLS'


			SET @NSTEP=160
			    UPDATE A SET TOTAL_QUANTITY =B.TOTAL_QTY ,HO_SYNCH_LAST_UPDATE  ='',
				PATCHUP_RUN=1
		        FROM CMM01106 A (NOLOCK)
				JOIN
				(
				SELECT A.CM_ID  ,
					   SUM(QUANTITY) AS TOTAL_QTY
				FROM CMD01106 A
				JOIN #TMPCMMADJ B ON A.CM_ID =B.CM_ID
				GROUP BY A.CM_ID 
				) B ON A.CM_ID =B.CM_ID


				UPDATE A  SET RFNET = NET-CMM_DISCOUNT_AMOUNT+(CASE WHEN TAX_METHOD=2 THEN TAX_AMOUNT+
	                ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(GST_CESS_AMOUNT,0) ELSE 0 END)
				FROM CMD01106 A
				JOIN #TMPCMMADJ B ON A.CM_ID =B.CM_ID 

              UPDATE A  SET TAX_ROUND_OFF=(RFNET-XN_VALUE_WITH_GST)
			  FROM CMD01106 A
			  JOIN #TMPCMMADJ B ON A.CM_ID =B.CM_ID 


          SET @NSTEP=170
				IF EXISTS (SELECT TOP 1'U' FROM   #TMPCMMADJ A
				JOIN CMD01106 B (NOLOCK) ON A.CM_ID=B.CM_ID 
				WHERE ABS(((B.MRP*quantity)-B.DISCOUNT_AMOUNT)-NET)>1)
				BEGIN

				   SET @CERRORMSG ='MISMATCH IN MRP - DISCOUNT & Item Net  '  
		           GOTO END_PROC    

				END

				IF EXISTS (SELECT TOP 1 'U'   FROM CMM01106 A (NOLOCK)
				JOIN 
				(
				 SELECT  A.CM_ID ,
				         SUM(B.NET) AS ITEN_NET
				FROM  #TMPCMMADJ A
				JOIN CMD01106 B (NOLOCK) ON A.CM_ID=B.CM_ID 
				GROUP BY A.CM_ID 
				) B ON A.CM_ID=B.CM_ID 
				WHERE ITEN_NET-ABS(A.SUBTOTAL+A.SUBTOTAL_R)>.5)
				BEGIN
				      SET @CERRORMSG ='MISMATCH IN SUBTOTAL - CALCULATIVE SUBTOTAL '  
		              GOTO END_PROC    

				END
		
		       
		       
END TRY      
BEGIN CATCH      
     SET @CERRORMSG='ERROR IN SP3S_PROCESS_CASHMEMO_ADJ,STEP-'+LTRIM(STR(@NSTEP))+'SQL ERROR: #'+LTRIM(STR(ERROR_NUMBER())) + '  ' + ERROR_MESSAGE()      
END CATCH           
      
END_PROC:      


      
IF @@TRANCOUNT>0        
BEGIN      
      
           IF ISNULL(@CERRORMSG,'')=''     
		   begin
		      
              commit         

		   end
           ELSE      
             ROLLBACK      
                 
 END     
 
 SELECT  @CERRORMSG AS ERRMSG  

 IF ISNULL(@CERRORMSG,'')=''
 DELETE FROM CASHMEMO_ADJ_UPLOAD WHERE SP_ID=@CSPID

 DELETE FROM CASHMEMO_ADJ_DET_UPLOAD WHERE SP_ID=@CSPID

END

