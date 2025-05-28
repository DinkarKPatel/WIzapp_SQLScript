create PROCEDURE SP_RETAILSALE_5
(  
	 @CQUERYID			NUMERIC(2),  
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
	 @cCustCode			VARCHAR(15)=''
) 
AS  
BEGIN  
 DECLARE @T1 NUMERIC(10)  ,@nFound NUMERIC(5,0),@nLoop INT ,@CCUSTOMER_CODE VARCHAR(MAX)
 SET @CWHERE=(CASE WHEN ISNULL(@CWHERE,'')='' THEN '000000000000' ELSE @CWHERE END)
 
 CREATE TABLE #tCUstomerCode(Customer_code CHAR(12))
 --DECLARE #tCUstomerCode TABLE (Customer_code CHAR(12))
 
 PRINT @CWHERE
 --SELECT TOP 1 @CCUSTOMER_CODE=user_customer_code  FROM custdym (NOLOCK) WHERE card_no=@CWHERE
 
 --IF ISNULL(@CCUSTOMER_CODE,'')=''
 --SELECT TOP 1 @CCUSTOMER_CODE=user_customer_code  FROM custdym (NOLOCK) WHERE user_customer_code=@CWHERE
 

 --IF ISNULL(@CCUSTOMER_CODE,'')=''
 --SELECT TOP 1 @CCUSTOMER_CODE=user_customer_code  FROM custdym (NOLOCK) WHERE customer_code=@CWHERE
 
 
 ----select @CCUSTOMER_CODE
 --IF ISNULL(@CCUSTOMER_CODE,'')<>''
-- --SET @CWHERE=@CCUSTOMER_CODE
 
--  SELECT CUSTOMER_CODE, USER_CUSTOMER_CODE, ISNULL(prx.prefix_name,'') AS CUSTOMER_TITLE, 
--  CUSTOMER_FNAME, CUSTOMER_LNAME,     
--  ISNULL(ST.STATE,'') AS [STATE],ADDRESS1, ADDRESS2,ISNULL(AR.AREA_NAME,'') AS  AREA,    
--  ISNULL(CI.CITY,'') AS CITY,ISNULL(AR.PINCODE,'') AS PINCODE, PHONE1,     
--  PHONE2, MOBILE, EMAIL,A.AREA_CODE,ADDRESS9,A.CARD_NO,A.INACTIVE ,A.Privilege_customer,
--  A.DT_CARD_ISSUE,A.DT_CARD_EXPIRY,  A.dt_birth,A.flat_disc_customer,A.ref_customer_code,A.location_id,
--  bm.card_name as discounted_card_type,A.flat_disc_percentage,A.dt_anniversary,
--  isnull(not_downloaded_from_wizclip,0) AS not_downloaded_from_wizclip,ST.STATE_CODE,
--  A.CUS_GST_STATE_CODE,GST.GST_STATE_NAME,A.CUS_GST_NO,A.Form_no,A.card_code,
--  ISNULL(prx.prefix_name,'') +' '+ CUSTOMER_FNAME+' '+ CUSTOMER_LNAME AS CUSTOMER_NAME
--  ,(CASE WHEN A.DT_BIRTH='' THEN '' ELSE CONVERT(VARCHAR(20),A.DT_BIRTH ,105) END) AS DOB
--  ,(CASE WHEN A.dt_anniversary='' THEN '' ELSE CONVERT(VARCHAR(20),A.dt_anniversary ,105) END) AS DOA
--  ,CAST(0 AS INT) AS total_visits
--  ,(CASE WHEN ''='' THEN '' ELSE CONVERT(VARCHAR(20),CAST('' AS DATETIME) ,105) END) AS FIRST_VISIT
--  ,(CASE WHEN ''='' THEN '' ELSE CONVERT(VARCHAR(20),CAST('' AS DATETIME) ,105) END) AS LAST_VISIT
--  ,(CASE WHEN A.inactive=1 THEN 'InActive' ELSE 'Active' END) AS [STATUS]
--  ,(CASE WHEN A.DT_CARD_EXPIRY='' THEN '' 
--		 WHEN DATEDIFF(d,A.DT_CARD_EXPIRY,GETDATE())>0 
--		 THEN 'InActive, Expire On :'+CONVERT(VARCHAR(20),A.DT_CARD_EXPIRY,105) 
--		 ELSE 'Active, Expire On :'+CONVERT(VARCHAR(20),A.DT_CARD_EXPIRY,105) END) AS [CARD_STATUS]
--,A.BILL_BY_BILL,A.custdym_export_gst_percentage_Applicable,A.custdym_export_gst_percentage
--  INTO #tmpCust 
--  FROM CUSTDYM A   (NOLOCK)
--  LEFT OUTER JOIN prefix prx (NOLOCK) ON prx.prefix_code=A.prefix_code
--  LEFT OUTER JOIN AREA AR  (NOLOCK) ON AR.AREA_CODE=A.AREA_CODE    
--  LEFT OUTER JOIN CITY CI  (NOLOCK) ON CI.CITY_CODE=AR.CITY_CODE    
--  LEFT OUTER JOIN STATE ST  (NOLOCK) ON ST.STATE_CODE=CI.STATE_CODE
--  LEFT OUTER JOIN GST_STATE_MST GST  (NOLOCK) ON A.CUS_GST_STATE_CODE=GST.GST_STATE_CODE
--  JOIN BWD_MST bm on bm.MEMO_ID=a.card_code
--  WHERE 1=2
  		  		  	  
 SET @nLoop=1
  
	--INSERT INTO #tCUstomerCode
 --  SELECT CUSTOMER_CODE 
 --  FROM CUSTDYM (nolock) 
	--WHERE (USER_CUSTOMER_CODE=@CWHERE )
	
	--INSERT INTO #tCUstomerCode
	-- SELECT CUSTOMER_CODE
	-- FROM CUSTDYM (nolock) 
	-- WHERE (CUSTOMER_CODE=@CWHERE )
	 
	-- INSERT INTO #tCUstomerCode
	-- SELECT CUSTOMER_CODE 
	-- FROM CUSTDYM (nolock) 
	-- WHERE (CARD_NO=@CWHERE )

 -- select @T1=SUM(t1) from
 -- (
	-- SELECT COUNT(CUSTOMER_CODE) as t1  FROM CUSTDYM (nolock) 
	-- WHERE (USER_CUSTOMER_CODE=@CWHERE )
	-- union all
	-- SELECT COUNT(CUSTOMER_CODE) FROM CUSTDYM (nolock) 
	-- WHERE (CUSTOMER_CODE=@CWHERE )
	-- union all
	-- SELECT COUNT(CUSTOMER_CODE) FROM CUSTDYM (nolock) 
	-- WHERE (CARD_NO=@CWHERE )
 --) a
 ----WHERE (USER_CUSTOMER_CODE=@CWHERE  OR CUSTOMER_CODE=@CWHERE OR CARD_NO=@CWHERE)
 
 --select @T1=COUNT(*) from #tCUstomerCode
 
 --WHILE @nLoop<=2
 --BEGIN
	 --IF ISNULL(@T1,0)>0
	 --BEGIN   
		--  INSERT #tmpCust 
		--  SELECT A.CUSTOMER_CODE, USER_CUSTOMER_CODE, ISNULL(prx.prefix_name,'') AS CUSTOMER_TITLE, CUSTOMER_FNAME, CUSTOMER_LNAME,     
		--  ISNULL(ST.STATE,'') AS [STATE],ADDRESS1, ADDRESS2,ISNULL(AR.AREA_NAME,'') AS  AREA,    
		--  ISNULL(CI.CITY,'') AS CITY,ISNULL(AR.PINCODE,'') AS PINCODE, PHONE1,     
		--  PHONE2, MOBILE, EMAIL,A.AREA_CODE,ADDRESS9,A.CARD_NO,A.INACTIVE ,A.Privilege_customer,
		--  A.DT_CARD_ISSUE,A.DT_CARD_EXPIRY,  A.dt_birth,A.flat_disc_customer,A.ref_customer_code,A.location_id,
		--  ISNULL(WC.card_status,ISNULL(bm.card_name,'')) as discounted_card_type,ISNULL(WC.discount_percentage, A.flat_disc_percentage ) AS flat_disc_percentage,A.dt_anniversary,isnull(not_downloaded_from_wizclip,0) 
		--  AS not_downloaded_from_wizclip,ST.STATE_CODE,
		--  A.CUS_GST_STATE_CODE,GST.GST_STATE_NAME,A.CUS_GST_NO,A.Form_no,A.card_code,
		--ISNULL(prx.prefix_name,'') +' '+ CUSTOMER_FNAME+' '+ CUSTOMER_LNAME AS CUSTOMER_NAME
		--,(CASE WHEN A.DT_BIRTH='' THEN '' ELSE CONVERT(VARCHAR(20),A.DT_BIRTH ,105) END) AS DOB
		--,(CASE WHEN A.dt_anniversary='' THEN '' ELSE CONVERT(VARCHAR(20),A.dt_anniversary ,105) END) AS DOA
		--,CAST(0 AS INT) AS total_visits
		--,(CASE WHEN ''='' THEN '' ELSE CONVERT(VARCHAR(20),CAST('' AS DATETIME) ,105) END) AS FIRST_VISIT
		--,(CASE WHEN ''='' THEN '' ELSE CONVERT(VARCHAR(20),CAST('' AS DATETIME) ,105) END) AS LAST_VISIT
		--,(CASE WHEN A.inactive=1 THEN 'InActive' ELSE 'Active' END) AS [STATUS]
		--,(CASE WHEN A.DT_CARD_EXPIRY='' THEN '' 
		-- WHEN DATEDIFF(d,A.DT_CARD_EXPIRY,GETDATE())>0 
		-- THEN 'InActive, Expire On :'+CONVERT(VARCHAR(20),A.DT_CARD_EXPIRY,105) 
		-- ELSE 'Active, Expire On :'+CONVERT(VARCHAR(20),A.DT_CARD_EXPIRY,105) END) AS [CARD_STATUS]
		-- ,ISNULL(A.BILL_BY_BILL,0) AS BILL_BY_BILL,A.custdym_export_gst_percentage_Applicable,A.custdym_export_gst_percentage
		--  FROM CUSTDYM A   (NOLOCK)
		--  JOIN #tCUstomerCode CC ON CC.Customer_code=A.customer_code
		--  LEFT OUTER JOIN prefix prx (NOLOCK) ON prx.prefix_code=A.prefix_code
		--  LEFT OUTER JOIN AREA AR  (NOLOCK) ON AR.AREA_CODE=A.AREA_CODE    
		--  LEFT OUTER JOIN CITY CI  (NOLOCK) ON CI.CITY_CODE=AR.CITY_CODE    
		--  LEFT OUTER JOIN STATE ST  (NOLOCK) ON ST.STATE_CODE=CI.STATE_CODE
		--  LEFT OUTER JOIN GST_STATE_MST GST  (NOLOCK) ON A.CUS_GST_STATE_CODE=GST.GST_STATE_CODE    
		--  LEFT OUTER JOIN BWD_MST bm on bm.MEMO_ID=a.card_code
		--	LEFT OUTER JOIN WIZCLIP_CUSTDYM_POINTS  WC (NOLOCK) ON WC.customer_code=A.customer_code
		--  WHERE isnull(not_downloaded_from_wizclip,0)=0 AND (@nLoop=2 OR  A.INACTIVE=0) 
		--  --AND (A.USER_CUSTOMER_CODE=@CWHERE    
		--  --OR A.CUSTOMER_CODE=@CWHERE OR CARD_NO=@CWHERE)
	 --END  
	 --ELSE  
	 BEGIN  
		--TRUNCATE TABLE #tCUstomerCode

		INSERT INTO #tCUstomerCode
	   SELECT CUSTOMER_CODE 
	   FROM CUSTDYM (nolock) 
		WHERE USER_CUSTOMER_CODE LIKE @CWHERE+'%'
	
		INSERT INTO #tCUstomerCode
		 SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTOMER_CODE LIKE @CWHERE+'%'
		 --LEFT OUTER JOIN #tCUstomerCode B ON B.Customer_code=CUSTDYM.customer_code
		 --WHERE B.Customer_code IS NULL AND  CUSTDYM.CUSTOMER_CODE LIKE @CWHERE+'%'
	 
		 INSERT INTO #tCUstomerCode
		 SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CARD_NO LIKE @CWHERE+'%'
		 --LEFT OUTER JOIN #tCUstomerCode B ON B.Customer_code=CUSTDYM.customer_code
		 --WHERE B.Customer_code IS NULL AND  CUSTDYM.CARD_NO LIKE @CWHERE+'%'

		 INSERT INTO #tCUstomerCode
		 SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.CUSTOMER_FNAME LIKE @CWHERE+'%' 
		 --LEFT OUTER JOIN #tCUstomerCode B ON B.Customer_code=CUSTDYM.customer_code
		 --WHERE B.Customer_code IS NULL AND  CUSTDYM.CUSTOMER_FNAME LIKE @CWHERE+'%' 
		 
		 INSERT INTO #tCUstomerCode
		 SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.CUSTOMER_LNAME LIKE @CWHERE+'%' 
		 --LEFT OUTER JOIN #tCUstomerCode B ON B.Customer_code=CUSTDYM.customer_code
		 --WHERE B.Customer_code IS NULL AND  CUSTDYM.CUSTOMER_LNAME LIKE @CWHERE+'%'     
		  
		  INSERT INTO #tCUstomerCode
		 SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.MOBILE LIKE @CWHERE+'%' 
		 --LEFT OUTER JOIN #tCUstomerCode B ON B.Customer_code=CUSTDYM.customer_code
		 --WHERE B.Customer_code IS NULL AND  CUSTDYM.MOBILE LIKE @CWHERE+'%' 
		 
		 INSERT INTO #tCUstomerCode
		 SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.PHONE1 LIKE @CWHERE+'%' 
		 --LEFT OUTER JOIN #tCUstomerCode B ON B.Customer_code=CUSTDYM.customer_code
		 --WHERE B.Customer_code IS NULL AND  CUSTDYM.PHONE1 LIKE @CWHERE+'%' 
		 
		 INSERT INTO #tCUstomerCode
		 SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.PHONE2 LIKE @CWHERE+'%' 
		 --LEFT OUTER JOIN #tCUstomerCode B ON B.Customer_code=CUSTDYM.customer_code
		 --WHERE B.Customer_code IS NULL AND  CUSTDYM.PHONE2 LIKE @CWHERE+'%' 
		 
		 INSERT INTO #tCUstomerCode
		 SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.EMAIL LIKE @CWHERE+'%' 
		 --LEFT OUTER JOIN #tCUstomerCode B ON B.Customer_code=CUSTDYM.customer_code
		 --WHERE B.Customer_code IS NULL AND  CUSTDYM.EMAIL LIKE @CWHERE+'%' 

		 --SELECT * FROM #tCUstomerCode
		 -- INSERT #tmpCust	 
		 ;WITH CC
		 AS
		 (
			SELECT DISTINCT CUSTOMER_CODE FROM #tCUstomerCode
		 )
		  SELECT A.CUSTOMER_CODE, USER_CUSTOMER_CODE, ISNULL(prx.prefix_name,'') AS  CUSTOMER_TITLE, CUSTOMER_FNAME, CUSTOMER_LNAME,     
		  ISNULL(ST.STATE,'') AS [STATE],ADDRESS1, ADDRESS2,ISNULL(AR.AREA_NAME,'') AS  AREA,    
		  ISNULL(CI.CITY,'') AS CITY,ISNULL(AR.PINCODE,'') AS PINCODE, PHONE1,     
		  PHONE2, MOBILE, EMAIL,A.AREA_CODE,ADDRESS9,A.CARD_NO,A.INACTIVE ,A.Privilege_customer,
		  A.DT_CARD_ISSUE,A.DT_CARD_EXPIRY,  A.dt_birth,A.flat_disc_customer ,A.ref_customer_code ,A.location_id ,
		  ISNULL(WC.card_status,ISNULL(bm.card_name,'')) as discounted_card_type,ISNULL(WC.discount_percentage, A.flat_disc_percentage ) AS flat_disc_percentage,A.dt_anniversary, 
		  isnull(not_downloaded_from_wizclip,0) AS not_downloaded_from_wizclip,ST.STATE_CODE,
		  A.CUS_GST_STATE_CODE,GST.GST_STATE_NAME,A.CUS_GST_NO,A.Form_no,A.card_code,
		  ISNULL(prx.prefix_name,'') +' '+ CUSTOMER_FNAME+' '+ CUSTOMER_LNAME AS CUSTOMER_NAME
		  ,(CASE WHEN A.DT_BIRTH='' THEN '' ELSE CONVERT(VARCHAR(20),A.DT_BIRTH ,105) END) AS DOB
		  ,(CASE WHEN A.dt_anniversary='' THEN '' ELSE CONVERT(VARCHAR(20),A.dt_anniversary ,105) END) AS DOA
		  ,CAST(0 AS INT) AS total_visits
		  ,(CASE WHEN ''='' THEN '' ELSE CONVERT(VARCHAR(20),CAST('' AS DATETIME) ,105) END) AS FIRST_VISIT
		  ,(CASE WHEN ''='' THEN '' ELSE CONVERT(VARCHAR(20),CAST('' AS DATETIME) ,105) END) AS LAST_VISIT
		  ,(CASE WHEN A.inactive=1 THEN 'InActive' ELSE 'Active' END) AS [STATUS]
		  ,(CASE WHEN A.DT_CARD_EXPIRY='' THEN '' 
		 WHEN DATEDIFF(d,A.DT_CARD_EXPIRY,GETDATE())>0 
		 THEN 'InActive, Expire On :'+CONVERT(VARCHAR(20),A.DT_CARD_EXPIRY,105) 
		 ELSE 'Active, Expire On :'+CONVERT(VARCHAR(20),A.DT_CARD_EXPIRY,105) END) AS [CARD_STATUS]
		 		 ,ISNULL(A.BILL_BY_BILL,0) AS BILL_BY_BILL,A.custdym_export_gst_percentage_Applicable,A.custdym_export_gst_percentage
				 ,ISNULL(International_customer,0) AS International_customer ,
				 A.countryCode,cp.countryname,a.USER_CODE, A.edt_user_code 
		  FROM CUSTDYM A   (NOLOCK) 
		  JOIN CC ON CC.Customer_code=A.customer_code
		  LEFT OUTER JOIN prefix prx (NOLOCK) ON prx.prefix_code=A.prefix_code 
		  LEFT OUTER JOIN AREA AR  (NOLOCK) ON AR.AREA_CODE=A.AREA_CODE    
		  LEFT OUTER JOIN CITY CI  (NOLOCK) ON CI.CITY_CODE=AR.CITY_CODE    
		  LEFT OUTER JOIN STATE ST  (NOLOCK) ON ST.STATE_CODE=CI.STATE_CODE  
		  LEFT OUTER JOIN GST_STATE_MST GST  (NOLOCK) ON A.CUS_GST_STATE_CODE=GST.GST_STATE_CODE      
		  LEFT OUTER JOIN BWD_MST bm (NOLOCK) on bm.MEMO_ID=a.card_code
		  LEFT OUTER JOIN WIZCLIP_CUSTDYM_POINTS  WC (NOLOCK) ON WC.customer_code=A.customer_code
		  LEFT OUTER JOIN countryPhoneCode CP (NOLOCK) ON A.countryCode = cp.phoneCode
		  WHERE isnull(not_downloaded_from_wizclip,0)=0 AND (@nLoop=2 OR  A.INACTIVE=0) AND A.CUSTOMER_CODE<>'000000000000' 
		  --AND     
		  --(USER_CUSTOMER_CODE LIKE @CWHERE+'%'
		  --OR CUSTOMER_FNAME LIKE @CWHERE+'%' OR CUSTOMER_LNAME LIKE @CWHERE+'%' OR    
		  --MOBILE LIKE @CWHERE+'%' OR PHONE1 LIKE @CWHERE+'%' OR PHONE2 LIKE @CWHERE+'%' OR EMAIL LIKE @CWHERE+'%'     
		  --OR CARD_NO LIKE @CWHERE+'%' )    
	 END  
	 
	 SET @nLoop=@nLoop+1
	 
	 --SELECT @nFound=COUNT(customer_code) FROM #tmpCust
	 
	-- IF ISNULL(@nFound,0)>0
	--	BREAK
		
 --END 
 
 --SELECT * FROM #tmpCust      

end

