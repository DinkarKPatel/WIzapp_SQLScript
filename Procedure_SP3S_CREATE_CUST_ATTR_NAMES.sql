create PROCEDURE SP3S_CREATE_CUST_ATTR_NAMES
(
	@cCustomerCode VARCHAR(20)=''
)
AS
BEGIN


	IF ISNULL(@cCustomerCode,'')=''
	   TRUNCATE TABLE CUST_ATTR_NAMES
	 ELSE
	   DELETE  A FROM CUST_ATTR_NAMES A (NOLOCK) WHERE A.customer_code =@cCustomerCode

	 
	 INSERT CUST_ATTR_NAMES	(customer_code,cust_attr1_key_name,cust_attr2_key_name,cust_attr3_key_name,cust_attr4_key_name,cust_attr5_key_name,cust_attr6_key_name,cust_attr7_key_name,cust_attr8_key_name,
			cust_attr9_key_name,cust_attr10_key_name,cust_attr11_key_name,cust_attr12_key_name,cust_attr13_key_name,cust_attr14_key_name,cust_attr15_key_name,cust_attr16_key_name,
			cust_attr17_key_name,cust_attr18_key_name,cust_attr19_key_name,cust_attr20_key_name,cust_attr21_key_name,cust_attr22_key_name,cust_attr23_key_name,cust_attr24_key_name,cust_attr25_key_name,
			
			USER_CUSTOMER_CODE,CUSTOMER_TITLE,CUSTOMER_FNAME,CUSTOMER_LNAME,ADDRESS1,ADDRESS2,ADDRESS3,ADDRESS4,AREA,PIN,CITY,STATE,REGION_NAME,PHONE1,PHONE2,MOBILE,EMAIL,OPENING_BALANCE,DT_BIRTH,DT_ANNIVERSARY,INACTIVE,LOCATION_ID,
            ADDRESS9,AGE,PRIVILEGE_CUSTOMER,CARD_NO,REF_CUSTOMER_CODE,PREFIX_CODE,DT_CARD_ISSUE,DT_CARD_EXPIRY,REF_USER_CUSTOMER_CODE,REF_CUSTOMER_NAME,CUS_GST_STATE_CODE,CUS_GST_STATE,CUS_GST_NO
			)
	 
	 
	  	   SELECT    a.customer_code,cust_attr1_key_name,cust_attr2_key_name,cust_attr3_key_name,cust_attr4_key_name,cust_attr5_key_name,cust_attr6_key_name,cust_attr7_key_name,cust_attr8_key_name,
			cust_attr9_key_name,cust_attr10_key_name,cust_attr11_key_name,cust_attr12_key_name,cust_attr13_key_name,cust_attr14_key_name,cust_attr15_key_name,cust_attr16_key_name,
			cust_attr17_key_name,cust_attr18_key_name,cust_attr19_key_name,cust_attr20_key_name,cust_attr21_key_name,cust_attr22_key_name,cust_attr23_key_name,cust_attr24_key_name,cust_attr25_key_name,

			A.USER_CUSTOMER_CODE, (case when A.prefix_code ='00000' then A.customer_title else F.PREFIX_NAME END )AS  CUSTOMER_TITLE,  A.CUSTOMER_FNAME, A.CUSTOMER_LNAME,    
			A.ADDRESS1, A.ADDRESS2,A.ADDRESS0 AS ADDRESS3 ,A.ADDRESS9 AS ADDRESS4, B.AREA_NAME AS AREA, B.PINCODE AS PIN, C.CITY, D.STATE, E.REGION_NAME, A.PHONE1, A.PHONE2, A.MOBILE, 
			A.EMAIL, A.OPENING_BALANCE, A.DT_BIRTH, A.DT_ANNIVERSARY, A.INACTIVE,A.LOCATION_ID,  A.ADDRESS9,  
			(CASE WHEN A.DT_BIRTH = '' THEN 0 ELSE DATEDIFF(YY,A.DT_BIRTH,GETDATE()) END) AS AGE,  
			A.PRIVILEGE_CUSTOMER,A.CARD_NO  ,A.REF_CUSTOMER_CODE,A.PREFIX_CODE,A.DT_CARD_ISSUE,A.DT_CARD_EXPIRY,  
			R.USER_CUSTOMER_CODE AS REF_USER_CUSTOMER_CODE,R.CUSTOMER_FNAME + ' ' +  R.CUSTOMER_LNAME  AS REF_CUSTOMER_NAME,  
			A.CUS_GST_STATE_CODE,GST_STATE_NAME AS CUS_GST_STATE,A.CUS_GST_NO

		FROM  custdym a WITH (NOLOCK)
		JOIN AREA B WITH (NOLOCK) ON A.AREA_CODE = B.AREA_CODE     
		JOIN CITY C WITH (NOLOCK) ON B.CITY_CODE = C.CITY_CODE     
		JOIN STATE D WITH (NOLOCK) ON C.STATE_CODE = D.STATE_CODE    
		JOIN REGIONM E WITH (NOLOCK) ON D.REGION_CODE = E.REGION_CODE  
		LEFT JOIN PREFIX F WITH (NOLOCK) ON A.PREFIX_CODE =F.PREFIX_CODE   
		LEFT OUTER JOIN CUSTDYM R WITH (NOLOCK) ON A.REF_CUSTOMER_CODE= R.CUSTOMER_CODE  
		LEFT OUTER JOIN GST_STATE_MST GST WITH (NOLOCK) ON A.CUS_GST_STATE_CODE= GST.GST_STATE_CODE  
		LEFT JOIN customer_fix_attr af (NOLOCK) ON af.customer_code =A.customer_code 
		LEFT JOIN cust_attr1_mst A1 (NOLOCK) ON A1.cust_ATTR1_KEY_CODE=af.cust_attr1_KEY_CODE      
		LEFT JOIN cust_attr2_mst A2 (NOLOCK) ON A2.cust_ATTR2_KEY_CODE=af.cust_attr2_KEY_CODE      
		LEFT JOIN cust_attr3_mst A3 (NOLOCK) ON A3.cust_ATTR3_KEY_CODE=af.cust_attr3_KEY_CODE      
		LEFT JOIN cust_attr4_mst A4 (NOLOCK) ON A4.cust_ATTR4_KEY_CODE=af.cust_attr4_KEY_CODE      
		LEFT JOIN cust_attr5_mst A5 (NOLOCK) ON A5.cust_ATTR5_KEY_CODE=af.cust_attr5_KEY_CODE      
		LEFT JOIN cust_attr6_mst A6 (NOLOCK) ON A6.cust_ATTR6_KEY_CODE=af.cust_attr6_KEY_CODE      
		LEFT JOIN cust_attr7_mst A7 (NOLOCK) ON A7.cust_ATTR7_KEY_CODE=af.cust_attr7_KEY_CODE      
		LEFT JOIN cust_attr8_mst A8 (NOLOCK) ON A8.cust_ATTR8_KEY_CODE=af.cust_attr8_KEY_CODE      
		LEFT JOIN cust_attr9_mst A9 (NOLOCK) ON A9.cust_ATTR9_KEY_CODE=af.cust_attr9_KEY_CODE      
		LEFT JOIN cust_attr10_mst A10 (NOLOCK) ON A10.cust_ATTR10_KEY_CODE=af.cust_attr10_KEY_CODE   

		LEFT JOIN cust_attr11_mst A11 (NOLOCK) ON A11.cust_ATTR11_KEY_CODE=af.cust_attr11_KEY_CODE
		LEFT JOIN cust_attr12_mst A12 (NOLOCK) ON A12.cust_ATTR12_KEY_CODE=af.cust_attr12_KEY_CODE
		LEFT JOIN cust_attr13_mst A13 (NOLOCK) ON A13.cust_ATTR13_KEY_CODE=af.cust_attr13_KEY_CODE
		LEFT JOIN cust_attr14_mst A14 (NOLOCK) ON A14.cust_ATTR14_KEY_CODE=af.cust_ATTR14_KEY_CODE
		LEFT JOIN cust_attr15_mst A15 (NOLOCK) ON A15.cust_ATTR15_KEY_CODE=af.cust_ATTR15_KEY_CODE
		LEFT JOIN cust_attr16_mst A16 (NOLOCK) ON A16.cust_ATTR16_KEY_CODE=af.cust_ATTR16_KEY_CODE
		LEFT JOIN cust_attr17_mst A17 (NOLOCK) ON A17.cust_ATTR17_KEY_CODE=af.cust_ATTR17_KEY_CODE
		LEFT JOIN cust_attr18_mst A18 (NOLOCK) ON A18.cust_ATTR18_KEY_CODE=af.cust_ATTR18_KEY_CODE
		LEFT JOIN cust_attr19_mst A19 (NOLOCK) ON A19.cust_ATTR19_KEY_CODE=af.cust_ATTR19_KEY_CODE
		LEFT JOIN cust_attr20_mst A20 (NOLOCK) ON A20.cust_ATTR20_KEY_CODE=af.cust_ATTR20_KEY_CODE

		LEFT JOIN cust_attr21_mst A21 (NOLOCK) ON A21.cust_ATTR21_KEY_CODE=af.cust_ATTR21_KEY_CODE
		LEFT JOIN cust_attr22_mst A22 (NOLOCK) ON A22.cust_ATTR22_KEY_CODE=af.cust_ATTR22_KEY_CODE
		LEFT JOIN cust_attr23_mst A23 (NOLOCK) ON a23.cust_ATTR23_KEY_CODE=af.cust_ATTR23_KEY_CODE
		LEFT JOIN cust_attr24_mst A24 (NOLOCK) ON a24.cust_ATTR24_KEY_CODE=af.cust_ATTR24_KEY_CODE
		LEFT JOIN cust_attr25_mst A25 (NOLOCK) ON a25.cust_ATTR25_KEY_CODE=af.cust_ATTR25_KEY_CODE
		WHERE  (A.customer_code =@cCustomerCode OR ISNULL(@cCustomerCode,'')='')
END