create PROCEDURE SP_GETCASHMEMO_ADJ_NEW_BILLNOWISE
(    
     @NADJUSTMENTMETHOD INT=1  ,--1 Date wise  ,2 Bill wise Reduce
     @NMODE INT=1,
	 @DTFROM		DATETIME =''    
	,@DTTO			DATETIME =''    
	,@CFILTER		VARCHAR(MAX)=''    
	,@CDEPT_ID VARCHAR(4)=''
	,@NREDUCETYPE INT=1 --1 FOR DISCOUNT REDUCE 2 MRP REDUCE  
	,@NFM_DISC_RANGE NUMERIC(5,0)=0
	,@nto_DISC_RANGE NUMERIC(5,0)=0
	,@CSP_ID VARCHAR(50)=''
	
)
AS    
BEGIN    
SET NOCOUNT ON

  /*
    @NADJUSTMENTMETHOD :IT IS USE TO AUTO Bill date oR Bill wise REDUCE user input disc Percenateg  OF SELECTD PERIOD
	@NMODE:1 FOR GET DATA TOTAL SALE CASH & PROCESSABLE AMOUNT - AFETR INSERTING REDUCE AMOUNT CALL 2 FOR GET DATA WITH NEW SALE
	@NREDUCETYPE : IN AUTO MODE 1 FOR DISCOUNT REDUCE , 2 FOR MRP REDUCE ADJUSTMENT 2 ALWAYS BE REDUCE MRP
	@NFM_DISC_RANGE : RANGE WILL BE APPLICABLE OF EACH BILL OF SELECTED PERIOD EX-5,10,15 OF RANGE 5 TO 15 
  */

  
   
	 DECLARE @CCMD01106 VARCHAR(100),@CRPSDET VARCHAR(100)	,@NSTEP numeric(5,0),@CERRORMSG varchar(1000),
	         @MRP_ROUNDING_LEVEL varchar(10)

	 IF OBJECT_ID('TEMPDB..#TABLECM_ID','U') IS NOT NULL
		DROP TABLE #TABLECM_ID
 
  	SELECT @MRP_ROUNDING_LEVEL=VALUE  FROM CONFIG WHERE CONFIG_OPTION='MRP_ROUNDING_LEVEL'
		
	CREATE TABLE #TABLECM_ID(CM_DT DATETIME,CM_ID VARCHAR(50),PROCESS_AMOUNT NUMERIC(10,2),CASH_AMOUNT NUMERIC(10,2),ROW_ID VARCHAR(50),LESS_DISCOUNT NUMERIC(14,2),
	                         cmm_disc_Percentage numeric(10,3))

	DECLARE @CCMD VARCHAR(MAX)



BEGIN TRY  	
	
	--B.OLD_MRP=B.MRP OR 

	-- donot apply discount on return item
	SET @NSTEP=10

	SET @CCMD='SELECT convert(varchar(10),A1.CM_DT,121) as cm_dt, A1.CM_ID,
	          ISNULL(X.AMOUNT,0) AS CASH_SALE,
			  ISNULL(B.NET-b.cmm_discount_amount,0) AS  PROCESS_AMOUNT ,
			  b.ROW_ID,A1.discount_percentage
	FROM CMM01106 A1 (NOLOCK)     
	join custdym cust (nolock) on cust.customer_code=a1.customer_code 
	LEFT JOIN CMD01106 B (NOLOCK) ON B.CM_ID=A1.CM_ID  
	LEFT JOIN SKU_NAMES WITH(NOLOCK)  ON SKU_NAMES.PRODUCT_CODE =B.PRODUCT_CODE
	LEFT JOIN USERS  (NOLOCK) ON USERS.USER_CODE=A1.USER_CODE
	JOIN   
	(    
	  SELECT A.MEMO_ID,B.PAYMODE_GRP_CODE,SUM(A.AMOUNT) AS [AMOUNT]
	  FROM PAYMODE_XN_DET A (NOLOCK)
	  JOIN PAYMODE_MST B (NOLOCK) ON B.PAYMODE_CODE=A.PAYMODE_CODE
	  JOIN PAYMODE_GRP_MST C (NOLOCK) ON C.PAYMODE_GRP_CODE=B.PAYMODE_GRP_CODE
	  WHERE C.PAYMODE_GRP_CODE=''0000001'' AND A.XN_TYPE=''SLS''
	  GROUP BY A.MEMO_ID,B.PAYMODE_GRP_CODE
	)X ON X.MEMO_ID=A1.CM_ID  
	WHERE (ISNULL(A1.PATCHUP_RUN,0)=0) AND A1.NET_AMOUNT=X.AMOUNT     
	AND (A1.MEMO_TYPE = ''0'' OR A1.MEMO_TYPE = ''1'')    
	AND (A1.CM_DT BETWEEN '''+CONVERT(VARCHAR,@DTFROM,110)+''' AND '''+CONVERT(VARCHAR,@DTTO,110)+''')    
	AND A1.CANCELLED=0  
	AND ISNULL(A1.SUBTOTAL_R,0)=0 
	AND B.NET>0
	and isnull(a1.Party_Gst_No,'''')=''''
	and isnull(a1.EINV_IRN_NO,'''')=''''
	AND a1.location_code='''+@CDEPT_ID+''' AND 
	'  + (CASE WHEN @CFILTER='' THEN '1=1 '  ELSE @CFILTER END) +'
	 '

	PRINT @CCMD
	INSERT INTO #TABLECM_ID  (CM_DT,CM_ID ,CASH_AMOUNT,PROCESS_AMOUNT,ROW_ID,cmm_disc_Percentage)  
	EXEC (@CCMD)

	SET @NSTEP=20

	;WITH CTE AS
	(
	SELECT *,SR=ROW_NUMBER() OVER (PARTITION  BY CM_ID ORDER BY CM_ID)
	FROM #TABLECM_ID
	)
	UPDATE CTE SET CASH_AMOUNT=0 WHERE SR>1

	
	 IF OBJECT_ID('TEMPDB..#TMPTOTALAMOUNT','U') IS NOT NULL
		DROP TABLE #TMPTOTALAMOUNT


		SELECT A.CM_DT ,A.CM_ID ,A.CASH_AMOUNT,
		      SUM(A.PROCESS_AMOUNT) AS PROCESS_AMOUNT,
		      CAST(0 AS NUMERIC(14,2)) As Return_amount   
			  into #TMPTOTALAMOUNT
		FROM #TABLECM_ID A
		group by A.CM_DT ,A.CM_ID ,A.CASH_AMOUNT

		      
	  UPDATE A SET RETURN_AMOUNT=  (B.NET-CMM_DISCOUNT_AMOUNT)  FROM #TMPTOTALAMOUNT A  
	  JOIN CMD01106 B (NOLOCK) ON A.CM_ID =B.CM_ID   
	  WHERE (B.NET-isnull(CMM_DISCOUNT_AMOUNT,0)) <0 AND A.CASH_AMOUNT>0  
	    

SET @NSTEP=30
	 IF OBJECT_ID('TEMPDB..#TMPSUMMARY','U') IS NOT NULL
		DROP TABLE #TMPSUMMARY


   SELECT '' AS CURSOR1,CONVERT( VARCHAR(10),A.CM_DT,121) as  CM_DT ,SUM(A.NET_AMOUNT) AS TOTAL_SALE,
              SUM(ISNULL(B.CASH_AMOUNT,0)) AS TOTAL_CASH_SALE,
			  SUM(ISNULL(B.PROCESS_AMOUNT,0)) AS DISCOUNT_APPLY_AMOUNT,
			  CAST(0 AS NUMERIC(14,2)) AS REDUCE_AMOUNT,
			   A.CM_ID,A.CM_NO,A.CUSTOMER_CODE,
			   abs(SUM(ISNULL(B.Return_AMOUNT,0))) As Return_amount  
			
	INTO #TMPSUMMARY
	FROM CMM01106 A
	LEFT JOIN (
	select cm_id ,SUM(ISNULL(CASH_AMOUNT,0)) as CASH_AMOUNT ,
	         SUM(ISNULL(PROCESS_AMOUNT,0)) as PROCESS_AMOUNT ,
	         SUM(ISNULL(Return_AMOUNT,0)) as Return_AMOUNT  
	from #TMPTOTALAMOUNT 
	group by cm_id
	)  B ON A.CM_ID=B.CM_ID 
	WHERE A.CM_DT BETWEEN @DTFROM AND @DTTO
	AND a.location_Code  =@CDEPT_ID and a.CANCELLED =0
	--and A.NET_AMOUNT>0
	GROUP BY CONVERT( VARCHAR(10),A.CM_DT,121),
	 A.CM_ID,A.CM_NO,A.CUSTOMER_CODE
	
	
	


	IF @NMODE=1
	BEGIN
	  
		   	SELECT CAST(0 AS BIT) AS CHK,'' AS CURSOR1,A.CM_DT ,A.TOTAL_SALE ,A.TOTAL_CASH_SALE ,A.DISCOUNT_APPLY_AMOUNT ,
			        A.REDUCE_AMOUNT ,0 AS NEW_SALE , 0 AS AUTO_REDUCE_AMOUNT,DIFF=0 ,cust.mobile  customerMobile, 
					Cust.customer_fname +' '+customer_lname  as customerName ,a.TOTAL_SALE net_amount , 
					cast(0 as numeric(10,2)) as discount_percentage,a.CM_NO,a.CM_ID,0 as Discount_amount,
					a.Return_amount
			FROM #TMPSUMMARY A
			JOIN CUSTDYM CUST (NOLOCK) ON A.CUSTOMER_CODE =CUST.CUSTOMER_CODE 
			where a.TOTAL_SALE>0 and A.TOTAL_CASH_SALE>0
			ORDER BY CM_DT ,CM_NO


		GOTO END_PROC

	END


	SET @NSTEP=40

	  DELETE FROM #TABLECM_ID WHERE ROW_ID IS NULL

	
	 IF OBJECT_ID('TEMPDB..#TMPSUMMARY_DISC','U') IS NOT NULL
		DROP TABLE #TMPSUMMARY_DISC

		
		   SELECT A.CM_DT,a.TOTAL_SALE ,a.TOTAL_CASH_SALE  ,A.DISCOUNT_APPLY_AMOUNT ,B.REDUCE_AMOUNT,
		          DISCADD=CAST( 0 AS NUMERIC(10,2)),
				  CAST(0 AS NUMERIC(14,2)) AS NEW_SALE,isnull(b.CM_ID,'') as CM_ID ,b.Discount_Percentage,b.cm_no,
				  B.Discount_Amount ,A.Return_amount 
		   INTO #TMPSUMMARY_DISC
		   FROM #TMPSUMMARY A
		   JOIN CASHMEMO_ADJ_UPLOAD B ON  a.CM_ID = isnull(b.cm_id ,'')
		   WHERE B.SP_ID=@CSP_ID 
		   and (isnull(b.Discount_Percentage,0)<>0 or isnull(B.Discount_Amount,0) <>0)


	

		   UPDATE #TMPSUMMARY_DISC SET REDUCE_AMOUNT=DISCOUNT_AMOUNT WHERE ISNULL(DISCOUNT_AMOUNT,0)<>0
		   UPDATE #TMPSUMMARY_DISC SET REDUCE_AMOUNT=DISCOUNT_APPLY_AMOUNT*Discount_Percentage/100 WHERE ISNULL(Discount_Percentage ,0)<>0
		   update #TMPSUMMARY_DISC set DISCADD=CAST(ROUND( CASE WHEN DISCOUNT_APPLY_AMOUNT=0 THEN 0 ELSE  REDUCE_AMOUNT*100/DISCOUNT_APPLY_AMOUNT END ,3) AS NUMERIC(10,3))


		   delete from CASHMEMO_ADJ_DET_UPLOAD where sp_id=@CSP_ID
		   

    SET @NSTEP=50
	     
			 INSERT INTO CASHMEMO_ADJ_DET_UPLOAD(CM_ID ,CM_DT,OLD_MRP,OLD_DISCOUNT_PERCENTAGE ,OLD_DISCOUNT_AMOUNT,OLD_NET,NEW_MRP,NEW_DISCOUNT_PERCENTAGE,NEW_DISCOUNT_AMOUNT,NEW_NET,CMM_DISCOUNT_AMOUNT,DISCADD,row_id,
			 QUANTITY,LESS_DISCOUNT,sp_id,CMM_DISC_PERCENTAGE)
		      SELECT B.CM_ID ,B.CM_DT ,
			         A.MRP AS OLD_MRP ,
					 A.DISCOUNT_PERCENTAGE AS OLD_DISCOUNT_PERCENTAGE ,
					 A.DISCOUNT_AMOUNT AS OLD_DISCOUNT_AMOUNT,
					 A.NET AS OLD_NET ,
			         CAST(0 AS NUMERIC(14,2)) AS NEW_MRP,
					 CAST(0 AS NUMERIC(14,3)) AS NEW_DISCOUNT_PERCENTAGE,
					 CAST(A.DISCOUNT_AMOUNT AS NUMERIC(14,2)) AS NEW_DISCOUNT_AMOUNT,
					 CAST(0 AS NUMERIC(14,2)) AS NEW_NET,
					 A.CMM_DISCOUNT_AMOUNT AS CMM_DISCOUNT_AMOUNT ,
					 C.DISCADD AS DISCADD,a.row_id ,A.QUANTITY  ,
					 LESS_DISCOUNT =(A.NET-A.cmm_discount_amount)*C.DISCADD/100,
					 @CSP_ID,b.CMM_DISC_PERCENTAGE
			  FROM CMD01106 A
			  JOIN #TABLECM_ID B ON A.ROW_ID =B.ROW_ID 
			  JOIN #TMPSUMMARY_DISC C ON  a.CM_ID =c.cm_id 
			

		


	 SET @NSTEP=80

	           IF @NREDUCETYPE=1
			   BEGIN
			     
				  PRINT ' 2 CHECK DISCOUNT LESS '   
				 UPDATE A SET NEW_MRP= OLD_MRP ,
				              NEW_DISCOUNT_AMOUNT=A.OLD_DISCOUNT_AMOUNT+ LESS_DISCOUNT
				 FROM CASHMEMO_ADJ_DET_UPLOAD A 
				 where  sp_id=@CSP_ID

				  DECLARE @CPickRoundITEMLEVELFromLoc VARCHAR(2) ,@CROUNDITEMLEVEL VARCHAR(2)

				 SELECT TOP 1 @CPickRoundITEMLEVELFromLoc = VALUE  FROM CONFIG WHERE  CONFIG_OPTION='Pick_SLS_ROUND_OFF_fromloc'
	
				if isnull(@CPickRoundITEMLEVELFromLoc,'')<>'1'
					SELECT TOP 1 @CROUNDITEMLEVEL = VALUE  FROM CONFIG WHERE  CONFIG_OPTION='SLS_ROUND_ITEM_NET'
				ELSE
					SELECT TOP 1 @CROUNDITEMLEVEL = sls_round_item_level  FROM location (NOLOCK) WHERE dept_id=@CDEPT_ID

				SET @CROUNDITEMLEVEL=ISNULL(@CROUNDITEMLEVEL,'')
  
				IF @CROUNDITEMLEVEL='1'
					UPDATE CASHMEMO_ADJ_DET_UPLOAD WITH (ROWLOCK) SET NEW_DISCOUNT_AMOUNT=round(NEW_DISCOUNT_AMOUNT,0)
					WHERE sp_id=@CSP_ID 
		
				 UPDATE A SET NEW_DISCOUNT_PERCENTAGE= CAST(ROUND( A.NEW_DISCOUNT_AMOUNT*100/(A.NEW_MRP*A.QUANTITY ),3) AS NUMERIC(10,3))
				 FROM CASHMEMO_ADJ_DET_UPLOAD A 
				 where sp_id=@CSP_ID
				-- WHERE A.OLD_DISCOUNT_AMOUNT<>0

				 UPDATE A SET NEW_NET= ((NEW_MRP*QUANTITY )-(NEW_DISCOUNT_AMOUNT ))
				 FROM CASHMEMO_ADJ_DET_UPLOAD A 
				 where  sp_id=@CSP_ID


			   END
			   ELSE
			   BEGIN
                 
                
                 
			     PRINT ' 2 CHECK MRP LESS '
				 UPDATE A SET NEW_MRP= (OLD_MRP-(OLD_MRP*DISCADD /100 )),ReduceMrp=1,
				              NEW_DISCOUNT_PERCENTAGE=OLD_DISCOUNT_PERCENTAGE 
				 FROM CASHMEMO_ADJ_DET_UPLOAD A 
				 where  sp_id=@CSP_ID
				 
				
				 UPDATE A SET  NEW_MRP=CASE WHEN ISNULL(@MRP_ROUNDING_LEVEL,'')='0' THEN CEILING(NEW_MRP)
				                     WHEN ISNULL(@MRP_ROUNDING_LEVEL,'')='1' THEN FLOOR(NEW_MRP)
									 ELSE NEW_MRP END   
				 FROM CASHMEMO_ADJ_DET_UPLOAD A 
				 WHERE  SP_ID=@CSP_ID

                  UPDATE A SET NEW_DISCOUNT_AMOUNT = (A.NEW_MRP *A.NEW_DISCOUNT_PERCENTAGE /100   )*QUANTITY
				   FROM CASHMEMO_ADJ_DET_UPLOAD A     
				   WHERE A.OLD_DISCOUNT_AMOUNT<>0    
				   and sp_id=@CSP_ID    
			    
				   UPDATE A SET NEW_NET= ((NEW_MRP*QUANTITY )-(NEW_DISCOUNT_AMOUNT ))    
				   FROM CASHMEMO_ADJ_DET_UPLOAD A     
				   where  sp_id=@CSP_ID   
			     
			  
				   IF @CROUNDITEMLEVEL='1'  
				   UPDATE CASHMEMO_ADJ_DET_UPLOAD WITH (ROWLOCK) SET NEW_NET=round(NEW_NET,0)  
				   WHERE sp_id=@CSP_ID   
				   
				   UPDATE A SET CMM_DISCOUNT_AMOUNT=ROUND( (NEW_NET *a.CMM_DISC_PERCENTAGE /100),2)
				   FROM CASHMEMO_ADJ_DET_UPLOAD  A WITH (NOLOCK)
				   WHERE SP_ID=@CSP_ID   
				



				


			  END

			  --NOW REMOVE NEGATIVE AMOUNT BILL
        
			;WITH CTE_NEGATIVEBILL AS
			(
			SELECT CM_ID ,SUM(NEW_NET) AS NEW_NET
			FROM CASHMEMO_ADJ_DET_UPLOAD A (NOLOCK)
			where  sp_id=@CSP_ID  
			GROUP BY CM_ID
			)
	      
			SELECT A.cm_id ,SUM(A.NET )+isnull(B.NEW_NET,0) AS netAmt
				into #tmpNegativebill
			FROM CMD01106 a (NOLOCK)
			JOIN CTE_NEGATIVEBILL  B ON A.cm_id =B.CM_ID 
			WHERE A.NET <0
			group by A.cm_id,isnull(B.NEW_NET,0)
			having (SUM(A.NET )+isnull(B.NEW_NET,0))<0
			
			DELETE A 
			FROM CASHMEMO_ADJ_DET_UPLOAD A(NOLOCK)
			JOIN #TMPNEGATIVEBILL B ON A.CM_ID =B.CM_ID 
			WHERE A.SP_ID =@CSP_ID
			
			
			--end of remove sale
		
		      SET @NSTEP=90
			  UPDATE A SET NEW_SALE =B.NEW_NET 
			  FROM #TMPSUMMARY_DISC A
			  JOIN
			  (
			     SELECT CM_DT ,SUM(NEW_NET-CMM_DISCOUNT_AMOUNT ) AS NEW_NET
				 FROM CASHMEMO_ADJ_DET_UPLOAD
				 where  sp_id=@CSP_ID 
				 GROUP BY CM_DT
			  ) B ON A.CM_DT =B.CM_DT
			
			   
	    	SET @NSTEP=100	 

			 DELETE FROM CASHMEMO_ADJ_DET_UPLOAD WHERE SP_ID =@CSP_ID AND ISNULL(LESS_DISCOUNT,0)=0

	    	GOTO END_PROC







	       
END TRY      
BEGIN CATCH      
     SET @CERRORMSG='ERROR IN SP_GETCASHMEMO_ADJ_NEW,STEP-'+LTRIM(STR(@NSTEP))+'SQL ERROR: #'+LTRIM(STR(ERROR_NUMBER())) + '  ' + ERROR_MESSAGE()      
END CATCH           
      
END_PROC:   	
	
	IF @NMODE<>1
	BEGIN
	  IF ISNULL(@CERRORMSG,'')<>''
	      SELECT @CERRORMSG AS ERRMSG
	  ELSE 
	  begin
	   
			   UPDATE a SET NEW_SALE=(A.TOTAL_SALE-a.REDUCE_AMOUNT)
			   FROM #TMPSUMMARY_DISC A
			   join CASHMEMO_ADJ_UPLOAD b on a.cm_id =b.cm_id 
			   WHERE b.SP_ID=@CSP_ID and isnull(b.Discount_Percentage,0)<>0

			   --UPDATE B SET REDUCE_AMOUNT =A.REDUCE_AMOUNT
			   --FROM #TMPSUMMARY_DISC A
			   --join CASHMEMO_ADJ_UPLOAD b on a.cm_id =b.cm_id 
			   --WHERE b.SP_ID=@CSP_ID and isnull(b.Discount_Percentage,0)<>0
	

	   		    SELECT cast(1 as bit) as chk,  A.CM_DT ,A.TOTAL_SALE ,A.TOTAL_CASH_SALE ,A.DISCOUNT_APPLY_AMOUNT ,A.REDUCE_AMOUNT ,
						A.TOTAL_SALE-A.REDUCE_AMOUNT  AS  NEW_SALE,
						A.REDUCE_AMOUNT   AS AUTO_REDUCE_AMOUNT,
						DIFF=0,@CSP_ID AS SP_ID  ,cust.mobile  customerMobile, 
					   Cust.customer_fname +' '+customer_lname  as customerName ,a.cm_no,a.cm_ID,a.Discount_amount,a.Discount_Percentage ,
					  A.Return_amount   
				 FROM #TMPSUMMARY_DISC A
				 left join cmm01106 cmm (nolock) on a.cm_ID =cmm.cm_id 
				 left JOIN CUSTDYM CUST (NOLOCK) ON cmm.CUSTOMER_CODE =CUST.CUSTOMER_CODE 
				 ORDER BY CM_DT 
            
			
		end
	END


END
