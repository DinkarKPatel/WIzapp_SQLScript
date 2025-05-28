  
CREATE VIEW IV_CUST_ATTR_NAMES
WITH SCHEMABINDING
AS
     SELECT  customer_code,cust_attr1_key_name,cust_attr2_key_name,cust_attr3_key_name,cust_attr4_key_name,cust_attr5_key_name,cust_attr6_key_name,
	         cust_attr7_key_name,cust_attr8_key_name,cust_attr9_key_name,cust_attr10_key_name,cust_attr11_key_name,cust_attr12_key_name,
			 cust_attr13_key_name,cust_attr14_key_name,cust_attr15_key_name,cust_attr16_key_name,cust_attr17_key_name,cust_attr18_key_name,
			 cust_attr19_key_name,cust_attr20_key_name,cust_attr21_key_name,cust_attr22_key_name,cust_attr23_key_name,cust_attr24_key_name,
			 cust_attr25_key_name

		FROM  dbo.customer_fix_attr (NOLOCK)
		JOIN dbo.cust_attr1_mst (NOLOCK)  ON customer_fix_attr.cust_ATTR1_KEY_CODE=cust_attr1_mst.cust_attr1_KEY_CODE      
	    JOIN dbo.cust_attr2_mst  (NOLOCK) ON cust_attr2_mst.cust_ATTR2_KEY_CODE=customer_fix_attr.cust_attr2_KEY_CODE      
		JOIN dbo.cust_attr3_mst  (NOLOCK) ON cust_attr3_mst.cust_ATTR3_KEY_CODE=customer_fix_attr.cust_attr3_KEY_CODE      
		JOIN dbo.cust_attr4_mst  (NOLOCK) ON cust_attr4_mst.cust_ATTR4_KEY_CODE=customer_fix_attr.cust_attr4_KEY_CODE      
		JOIN dbo.cust_attr5_mst  (NOLOCK) ON cust_attr5_mst.cust_ATTR5_KEY_CODE=customer_fix_attr.cust_attr5_KEY_CODE      
		JOIN dbo.cust_attr6_mst  (NOLOCK) ON cust_attr6_mst.cust_ATTR6_KEY_CODE=customer_fix_attr.cust_attr6_KEY_CODE      
		JOIN dbo.cust_attr7_mst  (NOLOCK) ON cust_attr7_mst.cust_ATTR7_KEY_CODE=customer_fix_attr.cust_attr7_KEY_CODE      
		JOIN dbo.cust_attr8_mst  (NOLOCK) ON cust_attr8_mst.cust_ATTR8_KEY_CODE=customer_fix_attr.cust_attr8_KEY_CODE      
		JOIN dbo.cust_attr9_mst  (NOLOCK) ON cust_attr9_mst.cust_ATTR9_KEY_CODE=customer_fix_attr.cust_attr9_KEY_CODE      
		JOIN dbo.cust_attr10_mst  (NOLOCK) ON cust_attr10_mst.cust_ATTR10_KEY_CODE=customer_fix_attr.cust_attr10_KEY_CODE   
		JOIN dbo.cust_attr11_mst  (NOLOCK) ON cust_attr11_mst.cust_ATTR11_KEY_CODE=customer_fix_attr.cust_attr11_KEY_CODE
		JOIN dbo.cust_attr12_mst  (NOLOCK) ON cust_attr12_mst.cust_ATTR12_KEY_CODE=customer_fix_attr.cust_attr12_KEY_CODE
		JOIN dbo.cust_attr13_mst  (NOLOCK) ON cust_attr13_mst.cust_ATTR13_KEY_CODE=customer_fix_attr.cust_attr13_KEY_CODE
		JOIN dbo.cust_attr14_mst  (NOLOCK) ON cust_attr14_mst.cust_ATTR14_KEY_CODE=customer_fix_attr.cust_ATTR14_KEY_CODE
		JOIN dbo.cust_attr15_mst  (NOLOCK) ON cust_attr15_mst.cust_ATTR15_KEY_CODE=customer_fix_attr.cust_ATTR15_KEY_CODE
		JOIN dbo.cust_attr16_mst  (NOLOCK) ON cust_attr16_mst.cust_ATTR16_KEY_CODE=customer_fix_attr.cust_ATTR16_KEY_CODE
		JOIN dbo.cust_attr17_mst  (NOLOCK) ON cust_attr17_mst.cust_ATTR17_KEY_CODE=customer_fix_attr.cust_ATTR17_KEY_CODE
		JOIN dbo.cust_attr18_mst  (NOLOCK) ON cust_attr18_mst.cust_ATTR18_KEY_CODE=customer_fix_attr.cust_ATTR18_KEY_CODE
		JOIN dbo.cust_attr19_mst  (NOLOCK) ON cust_attr19_mst.cust_ATTR19_KEY_CODE=customer_fix_attr.cust_ATTR19_KEY_CODE
		JOIN dbo.cust_attr20_mst  (NOLOCK) ON cust_attr20_mst.cust_ATTR20_KEY_CODE=customer_fix_attr.cust_ATTR20_KEY_CODE
		JOIN dbo.cust_attr21_mst  (NOLOCK) ON cust_attr21_mst.cust_ATTR21_KEY_CODE=customer_fix_attr.cust_ATTR21_KEY_CODE
		JOIN dbo.cust_attr22_mst  (NOLOCK) ON cust_attr22_mst.cust_ATTR22_KEY_CODE=customer_fix_attr.cust_ATTR22_KEY_CODE
		JOIN dbo.cust_attr23_mst  (NOLOCK) ON cust_attr23_mst.cust_ATTR23_KEY_CODE=customer_fix_attr.cust_ATTR23_KEY_CODE
		JOIN dbo.cust_attr24_mst  (NOLOCK) ON cust_attr24_mst.cust_ATTR24_KEY_CODE=customer_fix_attr.cust_ATTR24_KEY_CODE
		JOIN dbo.cust_attr25_mst  (NOLOCK) ON cust_attr25_mst.cust_ATTR25_KEY_CODE=customer_fix_attr.cust_ATTR25_KEY_CODE
		
