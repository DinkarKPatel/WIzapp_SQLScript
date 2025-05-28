CREATE PROCEDURE SP3S_UPDATE_CUSTOMER_DETAILS_FROMHO
(
	@SP_ID VARCHAR(50),
	@customer_code VARCHAR(50)
)
AS
BEGIN
	--cus_gst_no

	UPDATE A SET A.cus_gst_no=B.cus_gst_no
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.cus_gst_no,'')='' AND ISNULL(B.cus_gst_no,'')<>'' 

	UPDATE A SET A.user_customer_code=B.user_customer_code
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.user_customer_code,'')='' AND ISNULL(B.user_customer_code,'')<>'' 

	UPDATE A SET A.customer_fname=B.customer_fname
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.customer_fname,'')='' AND ISNULL(B.customer_fname,'')<>'' 

	UPDATE A SET A.customer_lname=B.customer_lname
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.customer_lname,'')='' AND ISNULL(B.customer_lname,'')<>'' 

	UPDATE A SET A.address1=B.address1
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.address1,'')='' AND ISNULL(B.address1,'')<>'' 

	UPDATE A SET A.address2=B.address2
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.address2,'')='' AND ISNULL(B.address2,'')<>'' 

	UPDATE A SET A.address0=B.address0
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.address0,'')='' AND ISNULL(B.address0,'')<>'' 

	UPDATE A SET A.address9=B.address9
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.address9,'')='' AND ISNULL(B.address9,'')<>'' 

	--UPDATE A SET A.ref_user_customer_code=B.ref_user_customer_code
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.ref_user_customer_code,'')='' AND ISNULL(B.ref_user_customer_code,'')<>'' 

	--UPDATE A SET A.ref_customer_code=B.ref_customer_code
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.ref_customer_code,'')='' AND ISNULL(B.ref_customer_code,'')<>'' 

	--UPDATE A SET A.ref_address=B.ref_address
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.ref_address,'')='' AND ISNULL(B.ref_address,'')<>'' 

	--tin_no

	UPDATE A SET A.tin_no=B.tin_no
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.tin_no,'')='' AND ISNULL(B.tin_no,'')<>'' 

	--form_no

	UPDATE A SET A.form_no=B.form_no
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.form_no,'')='' AND ISNULL(B.form_no,'')<>'' 

	--company_name

	UPDATE A SET A.company_name=B.company_name
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.company_name,'')='' AND ISNULL(B.company_name,'')<>'' 

	----Prefix_name

	--UPDATE A SET A.Prefix_name=B.Prefix_name
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.Prefix_name,'')='' AND ISNULL(B.Prefix_name,'')<>'' 

	--Prefix_code

	UPDATE A SET A.Prefix_code=B.Prefix_code
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.Prefix_code,'')='' AND ISNULL(B.Prefix_code,'')<>'' 

	--area_code

	UPDATE A SET A.area_code=B.area_code
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.area_code,'')='' AND ISNULL(B.area_code,'')<>'' 

	--area_name

	--UPDATE A SET A.area_name=B.area_name
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.area_name,'')='' AND ISNULL(B.area_name,'')<>'' 

	----city

	--UPDATE A SET A.city=B.city
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.city,'')='' AND ISNULL(B.city,'')<>'' 

	----state

	--UPDATE A SET A.state=B.state
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.state,'')='' AND ISNULL(B.state,'')<>'' 

	----pincode

	--UPDATE A SET A.pincode=B.pincode
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.pincode,'')='' AND ISNULL(B.pincode,'')<>'' 

	--phone1

	UPDATE A SET A.phone1=B.phone1
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.phone1,'')='' AND ISNULL(B.phone1,'')<>'' 

	--phone2

	UPDATE A SET A.phone2=B.phone2
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.phone2,'')='' AND ISNULL(B.phone2,'')<>'' 
	--mobile

	UPDATE A SET A.mobile=B.mobile
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.mobile,'')='' AND ISNULL(B.mobile,'')<>'' 

	--email

	UPDATE A SET A.email=B.email
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.email,'')='' AND ISNULL(B.email,'')<>'' 

	--email2

	UPDATE A SET A.email2=B.email2
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.email2,'')='' AND ISNULL(B.email2,'')<>'' 

	--card_no

	UPDATE A SET A.card_no=B.card_no
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.card_no,'')='' AND ISNULL(B.card_no,'')<>'' 

	--FLAT_DISC_PERCENTAGE

	UPDATE A SET A.FLAT_DISC_PERCENTAGE=B.FLAT_DISC_PERCENTAGE
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.FLAT_DISC_PERCENTAGE,0)=0 AND ISNULL(B.FLAT_DISC_PERCENTAGE,0)<>0 

	--flat_disc_percentage_during_sales

	UPDATE A SET A.flat_disc_percentage_during_sales=B.flat_disc_percentage_during_sales
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.flat_disc_percentage_during_sales,0)=0 AND ISNULL(B.flat_disc_percentage_during_sales,0)<>0

	----Discounted_Card_Type

	--UPDATE A SET A.Discounted_Card_Type=B.Discounted_Card_Type
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.Discounted_Card_Type,'')='' AND ISNULL(B.Discounted_Card_Type,'')<>'' 

	--card_code

	UPDATE A SET A.card_code=B.card_code
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.card_code,'')='' AND ISNULL(B.card_code,'')<>'' 

	----gst_state_name

	--UPDATE A SET A.gst_state_name=B.gst_state_name
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.gst_state_name,'')='' AND ISNULL(B.gst_state_name,'')<>'' 

	--cus_gst_state_code

	UPDATE A SET A.cus_gst_state_code=B.cus_gst_state_code
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.cus_gst_state_code,'')='' AND ISNULL(B.cus_gst_state_code,'')<>'' 

	--custdym_export_gst_percentage

	UPDATE A SET A.custdym_export_gst_percentage=B.custdym_export_gst_percentage
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.custdym_export_gst_percentage,0)=0 AND ISNULL(B.custdym_export_gst_percentage,0)<>0 

	--CUST_BAL


	UPDATE A SET A.CUST_BAL=B.CUST_BAL
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.CUST_BAL,0)=0 AND ISNULL(B.CUST_BAL,0)<>0 

	--CUST_CREDIT_LIMIT

	UPDATE A SET A.CUST_CREDIT_LIMIT=B.CUST_CREDIT_LIMIT
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.CUST_CREDIT_LIMIT,0)=0 AND ISNULL(B.CUST_CREDIT_LIMIT,0)<>0


	--dt_birth
	UPDATE A SET A.dt_birth=B.dt_birth
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.dt_birth,'')='' AND ISNULL(B.dt_birth,'')<>'' 

	--dt_Anniversary
	UPDATE A SET A.dt_Anniversary=B.dt_Anniversary
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.dt_Anniversary,'')='' AND ISNULL(B.dt_Anniversary,'')<>'' 

	----inactive
	--UPDATE A SET A.inactive=B.inactive
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.inactive,'')='' AND ISNULL(B.inactive,'')<>'' 

	----custdym_export_gst_percentage_Applicable
	--UPDATE A SET A.custdym_export_gst_percentage_Applicable=B.custdym_export_gst_percentage_Applicable
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.custdym_export_gst_percentage_Applicable,'')='' AND ISNULL(B.custdym_export_gst_percentage_Applicable,'')<>'' 

	--dt_card_issue
	UPDATE A SET A.dt_card_issue=B.dt_card_issue
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.dt_card_issue,'')='' AND ISNULL(B.dt_card_issue,'')<>'' 

	--dt_card_expiry
	UPDATE A SET A.dt_card_expiry=B.dt_card_expiry
	FROM CUS_custdym_UPLOAD A
	JOIN CUSTDYM B ON B.customer_code=A.customer_code
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.dt_card_expiry,'')='' AND ISNULL(B.dt_card_expiry,'')<>'' 

	----International_customer
	--UPDATE A SET A.International_customer=B.International_customer
	--FROM CUS_custdym_UPLOAD A
	--JOIN CUSTDYM B ON B.customer_code=A.customer_code
	--WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID AND ISNULL(A.International_customer,'')='' AND ISNULL(B.International_customer,'')<>'' 
	
	
	SELECT A.* ,AREA.AREA_NAME ,CITY.CITY,STATE.STATE,REGIONM.REGION_NAME,(CASE WHEN ISNULL(AREA.PINCODE,'')='' THEN A.PIN ELSE AREA.PINCODE END) AS PINCODE,P.PREFIX_NAME,
	(CASE WHEN ISNULL(A.ADDRESS9,'')='' THEN ISNULL(A.ADDRESS1,'')+' '+ISNULL(A.ADDRESS2,'') ELSE ISNULL(A.ADDRESS9,'') END) AS ALLADDRESS,
	A1.USER_CUSTOMER_CODE AS [REF_USER_CUSTOMER_CODE],
	A1.CUSTOMER_TITLE+' ' +ISNULL(A1.CUSTOMER_FNAME,'')+' '+ISNULL(A1.CUSTOMER_LNAME,'')+' '+
	(CASE WHEN ISNULL(A1.ADDRESS9,'')='' THEN ISNULL(A1.ADDRESS1,'')+' '+ISNULL(A1.ADDRESS2,'') ELSE ISNULL(A1.ADDRESS9,'') END) AS REF_ADDRESS,
	GST.GST_STATE_CODE + ' ' + GST.GST_STATE_NAME AS GST_STATE_NAME,
	BM.CARD_NAME AS DISCOUNTED_CARD_TYPE,CT.COUNTRY_CODE,CT.COUNTRY_NAME
	FROM CUS_custdym_UPLOAD A 
	LEFT JOIN AREA ON AREA.AREA_CODE=A.AREA_CODE
	LEFT JOIN CITY ON CITY.CITY_CODE=AREA.CITY_CODE
	LEFT JOIN STATE ON STATE.STATE_CODE=CITY.STATE_CODE
	LEFT JOIN REGIONM ON REGIONM.REGION_CODE=STATE.REGION_CODE
	LEFT OUTER JOIN PREFIX P ON P.PREFIX_CODE = A.PREFIX_CODE
	LEFT JOIN CUS_custdym_UPLOAD A1 ON A1.CUSTOMER_CODE=A.REF_CUSTOMER_CODE
	LEFT JOIN AREA AR1 ON AR1.AREA_CODE=A1.AREA_CODE
	LEFT JOIN CITY C1 ON C1.CITY_CODE=AR1.CITY_CODE
	LEFT JOIN STATE S1 ON S1.STATE_CODE=C1.STATE_CODE
	LEFT JOIN REGIONM R1 ON R1.REGION_CODE=S1.REGION_CODE
	LEFT OUTER JOIN PREFIX P1 ON P1.PREFIX_CODE = A1.PREFIX_CODE
	LEFT OUTER JOIN GST_STATE_MST GST ON GST.GST_STATE_CODE = A.CUS_GST_STATE_CODE
	LEFT OUTER JOIN BWD_MST BM ON BM.MEMO_ID=A.CARD_CODE
	LEFT OUTER JOIN COUNTRY CT ON CT.COUNTRY_CODE=R1.COUNTRY_CODE
	WHERE A.CUSTOMER_CODE=@customer_code AND A.SP_ID=@SP_ID 


END


