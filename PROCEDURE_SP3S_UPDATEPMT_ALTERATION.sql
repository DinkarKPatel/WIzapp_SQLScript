create PROCEDURE SP3S_UPDATEPMT_ALTERATION  
  @CXN_TYPE VARCHAR(10) ='PSHBD',
  @CXNID VARCHAR(40),  
  @NREVERTFLAG BIT = 0,  
  @NALLOWNEGSTOCK BIT = 0,  
  @CCMD NVARCHAR(4000) OUTPUT  
AS  
BEGIN  
DECLARE @NOUTFLAG INT, @NRETVAL BIT,@CXNTABLE VARCHAR(50),@CEXPR NVARCHAR(500),@CXNIDPARA VARCHAR(50),  
		@BCANCELLED BIT,@NENTRYMODE INT    ,@CUSERCODE VARCHAR(10),@BBIN_TRANSFER BIT
		,@BSLRRECONREQD BIT
   
 SET @NRETVAL = 0  
 SET @CCMD = ''  
 --*** CHECKING FOR NEGATIVE STOCK OF BAR CODES WHICH R REMOVED FROM DETAIL FILE  
 --*** IF USER OPTED NOT TO ALLOW NEGATIVE STOCK   
 
 
  IF @NREVERTFLAG = 1  
		SET @NOUTFLAG =  1  
  ELSE  
		SET @NOUTFLAG = -1  
  

  IF @CXN_TYPE='PSHBD'
  BEGIN

   

	  INSERT PMT01106 (PRODUCT_CODE,  QUANTITY_IN_STOCK, DEPT_ID,BIN_ID, LAST_UPDATE )  
	  SELECT DISTINCT B.PRODUCT_CODE,0 AS QUANTITY_IN_STOCK,a.location_Code  AS DEPT_ID,
	  A.BIN_ID,GETDATE() AS LAST_UPDATE  
	  FROM HOLD_BACK_DELIVER_DET B WITH (NOLOCK)  
	  JOIN HOLD_BACK_DELIVER_MST A WITH (NOLOCK) ON A.MEMO_ID=B.MEMO_ID 
	  LEFT OUTER JOIN PMT01106 PMT WITH (NOLOCK) ON PMT.PRODUCT_CODE = B.PRODUCT_CODE 
	  AND PMT.DEPT_ID = A.location_Code  AND PMT.BIN_ID = A.BIN_ID
	  WHERE A.MEMO_ID = @CXNID AND PMT.PRODUCT_CODE IS NULL 
	  AND ISNULL(DELIVERED,0)=0
  
	
     
	  UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * X.QUANTITY )  
	   FROM   PMT01106 A
	   JOIN
	   ( 
			SELECT B.PRODUCT_CODE, C.location_Code  AS DEPT_ID, C.BIN_ID, 
			SUM(QUANTITY) AS QUANTITY
			--SUM( QUANTITY) AS QUANTITY   
			FROM HOLD_BACK_DELIVER_DET B WITH (NOLOCK)  
			JOIN HOLD_BACK_DELIVER_MST C WITH (NOLOCK) ON B.MEMO_ID = C.MEMO_ID   
			WHERE B.MEMO_ID = @CXNID AND B.PRODUCT_CODE<>'' 
			AND ISNULL(DELIVERED,0)=0
			GROUP BY B.PRODUCT_CODE,C.location_Code , C.BIN_ID  
	   ) X  ON A.PRODUCT_CODE = X.PRODUCT_CODE   
	   AND A.DEPT_ID = X.DEPT_ID  
	   AND A.BIN_ID = X.BIN_ID  



  
	  SET @NRETVAL = 1  --*** SUCCESS  
    
	  SELECT @BCANCELLED=CANCELLED FROM HOLD_BACK_DELIVER_MST WHERE MEMO_ID=@CXNID  
	  ---NEGATIVE STOCK SHOULD NOT BE ALLOWED FOR SUPER USER
  
	  --*** CHECKING FOR NEGATIVE STOCK  
	  --*** IF USER OPTED NOT TO ALLOW NEGATIVE STOCK AND STOCK IS GOING OUT  
	  IF (@NALLOWNEGSTOCK = 0 OR @BCANCELLED=1  )
	  BEGIN  
	   --PRINT 'CHECKING FOR NEGATIVE STOCK'  
		   IF EXISTS ( SELECT A.PRODUCT_CODE FROM PMT01106 A 
					  JOIN  
					  (
						  SELECT B.PRODUCT_CODE,C.location_Code AS DEPT_ID,C.BIN_ID , SUM(B.QUANTITY) AS QUANTITY   
						  FROM HOLD_BACK_DELIVER_DET B WITH (NOLOCK)  
						  JOIN HOLD_BACK_DELIVER_MST C WITH (NOLOCK) ON C.MEMO_ID=B.MEMO_ID   
						  WHERE B.MEMO_ID = @CXNID 
						  GROUP BY B.PRODUCT_CODE,C.location_Code ,C.BIN_ID  
					  ) X ON X.PRODUCT_CODE=A.PRODUCT_CODE AND X.DEPT_ID=A.DEPT_ID AND X.BIN_ID=A.BIN_ID  
					  WHERE A.QUANTITY_IN_STOCK < 0
					 )  
		   BEGIN  
				SET @NRETVAL = 0  --*** UNSUCCESS  
				SET @CCMD = N'SELECT DISTINCT ''HBD'' AS XN_TYPE,X.MEMO_NO,X.MEMO_ID,A.PRODUCT_CODE, A.QUANTITY_IN_STOCK,''FOLLOWING BAR CODES ARE GOING NEGATIVE STOCK'' AS ERRMSG
							  FROM PMT01106 A WITH (NOLOCK)  
							  JOIN  
				  (
					  SELECT C.MEMO_NO AS MEMO_NO,
					         C.MEMO_ID AS MEMO_ID
							 ,B.PRODUCT_CODE,C.LOCATION_CODE AS DEPT_ID,C.BIN_ID, SUM(B.QUANTITY) AS QUANTITY   

					  FROM HOLD_BACK_DELIVER_DET B WITH (NOLOCK)  
					  JOIN HOLD_BACK_DELIVER_MST C WITH (NOLOCK) ON C.MEMO_ID=B.MEMO_ID 
					  WHERE B.MEMO_ID = '''+@CXNID+'''   
					  group by C.MEMO_NO,C.MEMO_ID,B.PRODUCT_CODE,C.LOCATION_CODE  ,C.BIN_ID 
				  ) X ON X.PRODUCT_CODE=A.PRODUCT_CODE AND X.DEPT_ID=A.DEPT_ID AND X.BIN_ID=A.BIN_ID  
				  WHERE A.QUANTITY_IN_STOCK < 0 '  
		   END  
	  END   
 
 END --******* END OF PSHBD*******

 ELSE IF @CXN_TYPE='PSJWI'
 BEGIN

      INSERT PMT01106 (PRODUCT_CODE,  QUANTITY_IN_STOCK, DEPT_ID,BIN_ID, LAST_UPDATE )  
	  SELECT DISTINCT B.PRODUCT_CODE,0 AS QUANTITY_IN_STOCK,A.location_Code  AS DEPT_ID,
	  A.BIN_ID,GETDATE() AS LAST_UPDATE  
	  FROM POST_SALES_JOBWORK_ISSUE_DET B WITH (NOLOCK)  
	  JOIN POST_SALES_JOBWORK_ISSUE_MST A WITH (NOLOCK) ON A.issue_id=B.issue_id 
	  LEFT OUTER JOIN PMT01106 PMT WITH (NOLOCK) ON PMT.PRODUCT_CODE = B.PRODUCT_CODE 
	  AND PMT.DEPT_ID = A.location_Code  AND PMT.BIN_ID = A.BIN_ID
	  WHERE A.issue_id = @CXNID AND PMT.PRODUCT_CODE IS NULL 
  
	
	  UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * X.QUANTITY )  
	   FROM   PMT01106 A
	   JOIN
	   ( 
			SELECT B.PRODUCT_CODE, C.location_Code  AS DEPT_ID, C.BIN_ID, 
			SUM(QUANTITY) AS QUANTITY
			FROM POST_SALES_JOBWORK_ISSUE_DET B WITH (NOLOCK)  
			JOIN POST_SALES_JOBWORK_ISSUE_MST C WITH (NOLOCK) ON B.issue_id = C.issue_id   
			WHERE B.issue_id = @CXNID AND B.PRODUCT_CODE<>'' 
			GROUP BY B.PRODUCT_CODE,C.location_Code , C.BIN_ID  
	   ) X  ON A.PRODUCT_CODE = X.PRODUCT_CODE   
	   AND A.DEPT_ID = X.DEPT_ID  
	   AND A.BIN_ID = X.BIN_ID  


	   
  
	  SET @NRETVAL = 1  --*** SUCCESS  
	  SELECT @BCANCELLED=CANCELLED FROM POST_SALES_JOBWORK_ISSUE_MST WHERE ISSUE_ID=@CXNID  
	  ---NEGATIVE STOCK SHOULD NOT BE ALLOWED FOR SUPER USER

	  IF (@NALLOWNEGSTOCK = 0  OR @BCANCELLED=1  )
	  BEGIN  
	   --PRINT 'CHECKING FOR NEGATIVE STOCK'  
		   IF EXISTS ( SELECT A.PRODUCT_CODE FROM PMT01106 A 
					  JOIN  
					  (
						  SELECT B.PRODUCT_CODE,C.location_Code  AS DEPT_ID,C.BIN_ID , SUM(B.QUANTITY) AS QUANTITY   
						  FROM POST_SALES_JOBWORK_ISSUE_DET B WITH (NOLOCK)  
						  JOIN POST_SALES_JOBWORK_ISSUE_MST C WITH (NOLOCK) ON C.ISSUE_ID=B.ISSUE_ID   
						  WHERE B.ISSUE_ID = @CXNID 
						  GROUP BY B.PRODUCT_CODE,C.location_Code ,C.BIN_ID  
					  ) X ON X.PRODUCT_CODE=A.PRODUCT_CODE AND X.DEPT_ID=A.DEPT_ID AND X.BIN_ID=A.BIN_ID  
					  WHERE A.QUANTITY_IN_STOCK < 0
					 )  
		   BEGIN  
				SET @NRETVAL = 0  --*** UNSUCCESS  
				SET @CCMD = N'SELECT DISTINCT ''PSJWI'' AS XN_TYPE,X.MEMO_NO,X.MEMO_ID,A.PRODUCT_CODE, A.QUANTITY_IN_STOCK,''FOLLOWING BAR CODES ARE GOING NEGATIVE STOCK'' AS ERRMSG
							  FROM PMT01106 A WITH (NOLOCK)  
							  JOIN  
				  (
					  SELECT C.ISSUE_NO AS MEMO_NO,
					         C.ISSUE_ID AS MEMO_ID
							 ,B.PRODUCT_CODE,C.location_Code  AS DEPT_ID,C.BIN_ID, SUM(B.QUANTITY) AS QUANTITY   
					  FROM POST_SALES_JOBWORK_ISSUE_DET B WITH (NOLOCK)  
					  JOIN POST_SALES_JOBWORK_ISSUE_MST C WITH (NOLOCK) ON C.ISSUE_ID=B.ISSUE_ID 
					  WHERE B.ISSUE_ID = '''+@CXNID+'''   
					  group by C.ISSUE_ID ,C.ISSUE_NO,B.PRODUCT_CODE,C.LOCATION_CODE  ,C.BIN_ID 
				  ) X ON X.PRODUCT_CODE=A.PRODUCT_CODE AND X.DEPT_ID=A.DEPT_ID AND X.BIN_ID=A.BIN_ID  
				  WHERE A.QUANTITY_IN_STOCK < 0 '  
		   END  
	  END   

 END --END OF PSJWI

 
 ELSE IF @CXN_TYPE='PSJWR'
 BEGIN
 
       INSERT PMT01106 (PRODUCT_CODE,  QUANTITY_IN_STOCK, DEPT_ID,BIN_ID, LAST_UPDATE )  
		  SELECT DISTINCT B.PRODUCT_CODE,0 AS QUANTITY_IN_STOCK,A.location_Code  AS DEPT_ID,
		  A.BIN_ID,GETDATE() AS LAST_UPDATE  
		  FROM POST_SALES_JOBWORK_RECEIPT_DET B WITH (NOLOCK)  
		  JOIN POST_SALES_JOBWORK_RECEIPT_MST A WITH (NOLOCK) ON A.receipt_id =B.receipt_id 
		  LEFT OUTER JOIN PMT01106 PMT WITH (NOLOCK) ON PMT.PRODUCT_CODE = B.PRODUCT_CODE 
		  AND PMT.DEPT_ID = A.location_Code  AND PMT.BIN_ID = A.BIN_ID
		  WHERE A.receipt_id = @CXNID AND PMT.PRODUCT_CODE IS NULL 
	  
  
	  --total paid to vendor update hold back deliver det
	    update E set TOTAL_PAID_TO_VENDOR= E.TOTAL_PAID_TO_VENDOR - ( @NOUTFLAG * ISNULL(D.job_rate,0) )  
		FROM POST_SALES_JOBWORK_RECEIPT_DET B  (NOLOCK)
		JOIN POST_SALES_JOBWORK_RECEIPT_MST C  (NOLOCK) ON B.RECEIPT_ID = C.RECEIPT_ID   
		JOIN POST_SALES_JOBWORK_ISSUE_DET D	 (NOLOCK) ON B.REF_ROW_ID=D.ROW_ID
		JOIN  HOLD_BACK_DELIVER_DET E (NOLOCK) ON D.REF_HBD_ROW_ID=E.ROW_ID
		 WHERE B.RECEIPT_ID = @CXNID
	  


	  --


	  UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * X.QUANTITY )  
	   FROM   PMT01106 A
	   JOIN
	   ( 
			SELECT B.PRODUCT_CODE, C.location_Code  AS DEPT_ID, C.BIN_ID, 
			SUM(QUANTITY) AS QUANTITY
			FROM POST_SALES_JOBWORK_RECEIPT_DET B WITH (NOLOCK)  
			JOIN POST_SALES_JOBWORK_RECEIPT_MST C WITH (NOLOCK) ON B.RECEIPT_ID = C.RECEIPT_ID   
			WHERE B.RECEIPT_ID = @CXNID AND B.PRODUCT_CODE<>'' 
			GROUP BY B.PRODUCT_CODE,C.location_Code , C.BIN_ID  
	   ) X  ON A.PRODUCT_CODE = X.PRODUCT_CODE   
	   AND A.DEPT_ID = X.DEPT_ID  
	   AND A.BIN_ID = X.BIN_ID  


  
	  SET @NRETVAL = 1  --*** SUCCESS  
	  SELECT @BCANCELLED=CANCELLED FROM POST_SALES_JOBWORK_RECEIPT_MST WHERE RECEIPT_ID=@CXNID  
	  ---NEGATIVE STOCK SHOULD NOT BE ALLOWED FOR SUPER USER

	  IF (@NALLOWNEGSTOCK = 0  OR @BCANCELLED=1  )
	  BEGIN  
	   --PRINT 'CHECKING FOR NEGATIVE STOCK'  
		   IF EXISTS ( SELECT A.PRODUCT_CODE FROM PMT01106 A 
					  JOIN  
					  (
						  SELECT B.PRODUCT_CODE,C.location_Code  AS DEPT_ID,C.BIN_ID , SUM(B.QUANTITY) AS QUANTITY   
						  FROM POST_SALES_JOBWORK_RECEIPT_DET B WITH (NOLOCK)  
						  JOIN POST_SALES_JOBWORK_RECEIPT_MST C WITH (NOLOCK) ON C.RECEIPT_ID=B.RECEIPT_ID   
						  WHERE B.RECEIPT_ID = @CXNID 
						  GROUP BY B.PRODUCT_CODE,C.location_Code ,C.BIN_ID  
					  ) X ON X.PRODUCT_CODE=A.PRODUCT_CODE AND X.DEPT_ID=A.DEPT_ID AND X.BIN_ID=A.BIN_ID  
					  WHERE A.QUANTITY_IN_STOCK < 0
					 )  
		   BEGIN  
				SET @NRETVAL = 0  --*** UNSUCCESS  
				SET @CCMD = N'SELECT DISTINCT ''PSJWR'' AS XN_TYPE,X.MEMO_NO,A.PRODUCT_CODE, A.QUANTITY_IN_STOCK,''FOLLOWING BAR CODES ARE GOING NEGATIVE STOCK'' AS ERRMSG
							  FROM PMT01106 A WITH (NOLOCK)  
							  JOIN  
				  (
					  SELECT C.RECEIPT_NO, AS MEMO_NO
							 ,B.PRODUCT_CODE,C.location_Code  AS DEPT_ID,C.BIN_ID, SUM(B.QUANTITY) AS QUANTITY   
					  FROM POST_SALES_JOBWORK_RECEIPT_DET B WITH (NOLOCK)  
					  JOIN POST_SALES_JOBWORK_RECEIPT_MST C WITH (NOLOCK) ON C.RECEIPT_ID=B.RECEIPT_ID 
					  WHERE B.RECEIPT_ID = '''+@CXNID+'''   
					  group by C.RECEIPT_NO,B.PRODUCT_CODE,C.location_Code   ,C.BIN_ID 
				  ) X ON X.PRODUCT_CODE=A.PRODUCT_CODE AND X.DEPT_ID=A.DEPT_ID AND X.BIN_ID=A.BIN_ID  
				  WHERE A.QUANTITY_IN_STOCK < 0 '  
		   END  
	  END   

 END --END OF PSJWR

 
 ELSE IF @CXN_TYPE='PSDLV'
 BEGIN

      INSERT PMT01106 (PRODUCT_CODE,  QUANTITY_IN_STOCK, DEPT_ID,BIN_ID, LAST_UPDATE )  
	  SELECT DISTINCT B.PRODUCT_CODE,0 AS QUANTITY_IN_STOCK,A.location_Code  AS DEPT_ID,
	  A.BIN_ID,GETDATE() AS LAST_UPDATE  
	  FROM SLS_DELIVERY_DET B WITH (NOLOCK)  
	  JOIN SLS_DELIVERY_MST A WITH (NOLOCK) ON A.MEMO_ID=B.MEMO_ID 
	  LEFT OUTER JOIN PMT01106 PMT WITH (NOLOCK) ON PMT.PRODUCT_CODE = B.PRODUCT_CODE 
	  AND PMT.DEPT_ID = A.location_Code  AND PMT.BIN_ID = A.BIN_ID
	  WHERE A.MEMO_ID = @CXNID AND PMT.PRODUCT_CODE IS NULL 
  
	
	  UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * X.QUANTITY )  
	   FROM   PMT01106 A
	   JOIN
	   ( 
			SELECT B.PRODUCT_CODE, C.location_Code  AS DEPT_ID, C.BIN_ID, 
			SUM(QUANTITY) AS QUANTITY
			FROM SLS_DELIVERY_DET B WITH (NOLOCK)  
			JOIN SLS_DELIVERY_MST C WITH (NOLOCK) ON B.MEMO_ID = C.MEMO_ID   
			WHERE B.MEMO_ID = @CXNID AND B.PRODUCT_CODE<>'' 
			GROUP BY B.PRODUCT_CODE,C.location_Code , C.BIN_ID  
	   ) X  ON A.PRODUCT_CODE = X.PRODUCT_CODE   
	   AND A.DEPT_ID = X.DEPT_ID  
	   AND A.BIN_ID = X.BIN_ID  


	   --Reduce consumable barcode 
	   IF EXISTS (SELECT TOP 1 'U'  FROM SLS_DELIVERY_CONS WHERE MEMO_ID=@CXNID)
	   BEGIN



	   INSERT PMT01106 (PRODUCT_CODE,  QUANTITY_IN_STOCK, DEPT_ID,BIN_ID, LAST_UPDATE )  
		  SELECT DISTINCT B.PRODUCT_CODE,0 AS QUANTITY_IN_STOCK,C.location_Code  AS DEPT_ID,
			  '000' BIN_ID,GETDATE() AS LAST_UPDATE  
		  FROM SLS_DELIVERY_CONS B WITH (NOLOCK) 
		  join sls_delivery_mst C  (NOLOCK) ON B.memo_id = C.memo_id 
		  LEFT OUTER JOIN PMT01106 PMT WITH (NOLOCK) ON PMT.PRODUCT_CODE = B.PRODUCT_CODE 
		  AND PMT.DEPT_ID = C.location_Code 
		  WHERE B.MEMO_ID = @CXNID AND PMT.PRODUCT_CODE IS NULL 
  

	       UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * X.QUANTITY )  
		   FROM   PMT01106 A
		   JOIN
		   ( 
				SELECT B.PRODUCT_CODE, C.location_Code  AS DEPT_ID, '000' BIN_ID, 
				SUM(QUANTITY) AS QUANTITY
				FROM SLS_DELIVERY_CONS B WITH (NOLOCK)  
				JOIN SLS_DELIVERY_MST C WITH (NOLOCK) ON B.MEMO_ID = C.MEMO_ID   
				WHERE B.MEMO_ID = @CXNID AND B.PRODUCT_CODE<>'' 
				GROUP BY B.PRODUCT_CODE,C.location_Code 
		   ) X  ON A.PRODUCT_CODE = X.PRODUCT_CODE   
		   AND A.DEPT_ID = X.DEPT_ID  
		   AND A.BIN_ID = X.BIN_ID  

	   END


	   
  
	  SET @NRETVAL = 1  --*** SUCCESS  
	  SELECT @BCANCELLED=CANCELLED FROM SLS_DELIVERY_MST WHERE MEMO_ID=@CXNID  
	  ---NEGATIVE STOCK SHOULD NOT BE ALLOWED FOR SUPER USER
	  --SET @NALLOWNEGSTOCK = 1
	  IF (@NALLOWNEGSTOCK = 0  OR @BCANCELLED=1  )
	  BEGIN  
	   --PRINT 'CHECKING FOR NEGATIVE STOCK'  
		   IF EXISTS ( SELECT A.PRODUCT_CODE FROM PMT01106 A 
					  JOIN  
					  (
						  SELECT B.PRODUCT_CODE,C.location_Code  AS DEPT_ID,C.BIN_ID , SUM(B.QUANTITY) AS QUANTITY   
						  FROM SLS_DELIVERY_DET B WITH (NOLOCK)  
						  JOIN SLS_DELIVERY_MST C WITH (NOLOCK) ON C.MEMO_ID=B.MEMO_ID   
						  WHERE B.MEMO_ID = @CXNID 
						  GROUP BY B.PRODUCT_CODE,C.location_Code ,C.BIN_ID  
					  ) X ON X.PRODUCT_CODE=A.PRODUCT_CODE AND X.DEPT_ID=A.DEPT_ID AND X.BIN_ID=A.BIN_ID  
					  WHERE A.QUANTITY_IN_STOCK < 0
					 )  
		   BEGIN  
				SET @NRETVAL = 0  --*** UNSUCCESS  
				SET @CCMD = N'SELECT DISTINCT ''PSDLV'' AS XN_TYPE,X.MEMO_NO,X.MEMO_ID,A.PRODUCT_CODE, A.QUANTITY_IN_STOCK,''FOLLOWING BAR CODES ARE GOING NEGATIVE STOCK'' AS ERRMSG
							  FROM PMT01106 A WITH (NOLOCK)  
							  JOIN  
				  (
					  SELECT C.MEMO_NO AS MEMO_NO,
					         C.MEMO_ID AS MEMO_ID
							 ,B.PRODUCT_CODE,C.location_Code  AS DEPT_ID,C.BIN_ID, SUM(B.QUANTITY) AS QUANTITY   
					  FROM SLS_DELIVERY_DET B WITH (NOLOCK)  
					  JOIN SLS_DELIVERY_MST C WITH (NOLOCK) ON C.MEMO_ID=B.MEMO_ID 
					  WHERE B.MEMO_ID = '''+@CXNID+'''   
					  group by C.MEMO_ID ,C.MEMO_NO,B.PRODUCT_CODE,C.location_Code   ,C.BIN_ID 
				  ) X ON X.PRODUCT_CODE=A.PRODUCT_CODE AND X.DEPT_ID=A.DEPT_ID AND X.BIN_ID=A.BIN_ID  
				  WHERE A.QUANTITY_IN_STOCK < 0 '  
		   END  
	  END   

 END --END OF delivery

 
END_PROC:  
   
END

