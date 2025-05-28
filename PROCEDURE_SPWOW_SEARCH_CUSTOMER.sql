CREATE PROCEDURE SPWOW_SEARCH_CUSTOMER
(  
	 @CWHERE			VARCHAR(MAX)='',
	 @nMode				NUMERIC(1)=2
) 
AS  
BEGIN  
 DECLARE @cCMD NVARCHAR(MAX)

 SET @CWHERE=(CASE WHEN ISNULL(@CWHERE,'')='' THEN '000000000000' ELSE @CWHERE END)
 
 CREATE TABLE #tCustomerCode(Customer_code CHAR(12))
 
 
 PRINT @CWHERE
 
		
	SET @cCMD=N'SELECT CUSTOMER_CODE 
	   FROM CUSTDYM (nolock) 
		WHERE USER_CUSTOMER_CODE LIKE '''+@CWHERE+'%'''
		PRINT @cCMD
		INSERT INTO #tCustomerCode
		EXEC SP_EXECUTESQL @cCMD

		
		SET @cCMD=N' SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTOMER_CODE LIKE '''+@CWHERE+'%'''
		 PRINT @cCMD
		INSERT INTO #tCustomerCode
		EXEC SP_EXECUTESQL @cCMD

		SET @cCMD=N' SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.MOBILE LIKE '''+@CWHERE+'%'''
		 PRINT @cCMD
		INSERT INTO #tCustomerCode
		EXEC SP_EXECUTESQL @cCMD

		if(@nMode=2)
		BEGIN
		 SET @cCMD=N' SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CARD_NO LIKE '''+@CWHERE+'%'''
		 PRINT @cCMD
		INSERT INTO #tCustomerCode
		EXEC SP_EXECUTESQL @cCMD

		 SET @cCMD=N' SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.CUSTOMER_FNAME LIKE '''+@CWHERE+'%'''
		 PRINT @cCMD
		INSERT INTO #tCustomerCode
		EXEC SP_EXECUTESQL @cCMD

		 SET @cCMD=N' SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.CUSTOMER_LNAME LIKE '''+@CWHERE+'%'''
		 PRINT @cCMD
		INSERT INTO #tCustomerCode
		EXEC SP_EXECUTESQL @cCMD

	

		 SET @cCMD=N' SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.PHONE1 LIKE '''+@CWHERE+'%''' 
		 PRINT @cCMD
		INSERT INTO #tCustomerCode
		EXEC SP_EXECUTESQL @cCMD

		 SET @cCMD=N' SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.PHONE2 LIKE '''+@CWHERE+'%'''
		 PRINT @cCMD
		INSERT INTO #tCustomerCode
		EXEC SP_EXECUTESQL @cCMD

		 SET @cCMD=N' SELECT CUSTDYM.CUSTOMER_CODE
		 FROM CUSTDYM (nolock) 
		 WHERE CUSTDYM.EMAIL LIKE '''+@CWHERE+'%'''
		 PRINT @cCMD
		INSERT INTO #tCustomerCode
		EXEC SP_EXECUTESQL @cCMD
		END
		 --SELECT * FROM #tCustomerCode
		 ;WITH CUST
		 AS
		 (
			SELECT DISTINCT CUSTOMER_CODE FROM #tCustomerCode
		 )
		  SELECT A.dt_birth AS dtBirth,A.ref_customer_code AS refCustomerCode,A.prefix_code AS prefixCode,A.flat_disc_customer AS flatDiscCustomer,A.privilege_customer AS privilegeCustomer,
		A.dt_card_issue AS dtCardIssue,A.dt_card_expiry AS dtCardExpiry,A.card_no AS cardNo,A.card_name AS cardName,A.flat_disc_percentage_during_sales AS flatDiscPercentageDuringSales,A.ac_code AS acCode,
		A.dt_created AS dtCreated,A.pin AS pin,A.dt_anniversary AS dtAnniversary,A.sent_to_ho AS sentToHo,A.inactive AS inactive,A.area_code AS areaCode,A.LOCATION_ID AS locationId,
		A.address0 AS address0,A.wizclip_last_update AS wizclipLastUpdate,A.manager_card AS managerCard,A.BILL_BY_BILL AS billByBill,A.form_no AS formNo,A.uploaded_to_ho AS uploadedToHo,
		A.email2 AS email2,A.Tin_No AS tinNo,A.not_downloaded_from_wizclip AS notDownloadedFromWizclip,A.International_customer AS internationalCustomer,A.cus_gst_state_code AS cusGstStateCode,A.cus_gst_no AS cusGstNo,
		A.HO_LAST_UPDATE AS hoLastUpdate,A.card_code AS cardCode,A.old_discount_card_type AS oldDiscountCardType,A.address9 AS address9,A.customer_code AS customerCode,A.user_customer_code AS userCustomerCode,
		ISNULL(prx.prefix_name,'') AS  customerTitle,A.customer_fname AS customerFname,A.customer_lname AS customerLname,A.address1 AS address1,A.address2 AS address2,A.phone1 AS phone1,
		A.phone2 AS phone2,A.mobile AS mobile,A.email AS email,A.OPENING_BALANCE AS openingBalance,A.FirstCardIssueDt AS firstCardIssueDt,A.company_name AS companyName,A.HO_SYNCH_LAST_UPDATE AS hoSynchLastUpdate,
		A.custdym_export_gst_percentage_Applicable AS custdymExportGstPercentageApplicable,A.custdym_export_gst_percentage AS custdymExportGstPercentage,A.CUST_CREDIT_LIMIT AS custCreditLimit,A.CUST_BAL AS custBal,
		A.gender AS gender ,ISNULL(ST.STATE,'') AS [state],ISNULL(AR.AREA_NAME,'') AS  area,ISNULL(CI.CITY,'') AS city,ISNULL(AR.PINCODE,'') AS pincode, 
		ISNULL(WC.card_status,ISNULL(bm.card_name,'')) as discountedCardType,ISNULL(WC.discount_percentage, A.flat_disc_percentage ) AS flatDiscPercentage,GST.GST_STATE_NAME as gstStateName ,
		CONVERT(VARCHAR(20),CAST('' AS DATETIME) ,105) AS firstVisit,CONVERT(VARCHAR(20),CAST('' AS DATETIME) ,105) AS lastVisit
		FROM CUSTDYM A   (NOLOCK) 
		JOIN CUST ON CUST.Customer_code=A.customer_code
		LEFT OUTER JOIN prefix prx (NOLOCK) ON prx.prefix_code=A.prefix_code 
		LEFT OUTER JOIN AREA AR  (NOLOCK) ON AR.AREA_CODE=A.AREA_CODE    
		LEFT OUTER JOIN CITY CI  (NOLOCK) ON CI.CITY_CODE=AR.CITY_CODE    
		LEFT OUTER JOIN STATE ST  (NOLOCK) ON ST.STATE_CODE=CI.STATE_CODE  
		LEFT OUTER JOIN GST_STATE_MST GST  (NOLOCK) ON A.CUS_GST_STATE_CODE=GST.GST_STATE_CODE      
		LEFT OUTER JOIN BWD_MST bm (NOLOCK) on bm.MEMO_ID=a.card_code
		LEFT OUTER JOIN WIZCLIP_CUSTDYM_POINTS  WC (NOLOCK) ON WC.customer_code=A.customer_code
		WHERE isnull(not_downloaded_from_wizclip,0)=0 AND A.INACTIVE=0 AND A.CUSTOMER_CODE<>'000000000000' 
		 
END  

--EXEC SPWOW_SEARCH_CUSTOMER 'ROHIT'
