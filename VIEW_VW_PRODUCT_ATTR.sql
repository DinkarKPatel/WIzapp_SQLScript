CREATE VIEW VW_PRODUCT_ATTR AS    
SELECT SKU.PRODUCT_CODE,SKU.ARTICLE_CODE,SKU.PARA1_CODE,SKU.PARA2_CODE,SKU.PARA3_CODE,SKU.PARA4_CODE,SKU.PARA5_CODE,SKU.PARA6_CODE    
,SECTIOND.sub_section_code,SECTIOND.SECTION_CODE    
,af.attr1_key_code,af.attr2_key_code,af.attr3_key_code,af.attr4_key_code,af.attr5_key_code,af.attr6_key_code,af.attr7_key_code    
,af.attr8_key_code,af.attr9_key_code,af.attr10_key_code,af.attr11_key_code,af.attr12_key_code,af.attr13_key_code,af.attr14_key_code    
,af.attr15_key_code,af.attr16_key_code,af.attr17_key_code,af.attr18_key_code,af.attr19_key_code,af.attr20_key_code,af.attr21_key_code    
,af.attr22_key_code,af.attr23_key_code,af.attr24_key_code,af.attr25_key_code    
,SECTIONM.ITEM_TYPE,SKU.BARCODE_CODING_SCHEME  
FROM SKU (NOLOCK)     
JOIN ARTICLE (NOLOCK)  ON SKU.ARTICLE_CODE=ARTICLE.ARTICLE_CODE      
JOIN SECTIOND (NOLOCK) ON SECTIOND.sub_section_code=ARTICLE.sub_section_code      
JOIN SECTIONM (NOLOCK) ON SECTIONM.section_code=SECTIOND.section_code      
JOIN ARTICLE_FIX_ATTR AF (NOLOCK)      
ON AF.ARTICLE_CODE=ARTICLE.ARTICLE_CODE

