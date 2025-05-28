UPDATE a SET Allow_access_retail_sale_All_users=1   FROM users a
JOIN USER_ROLE_DET b ON a.role_id=b.role_id
 WHERE FORM_NAME='FRMSALE'  AND FORM_OPTION='DISPLAY_BILLS_ALL_USERS'    
 and B.VALUE='1'
