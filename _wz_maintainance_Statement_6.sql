

UPDATE A SET A.S_NO=B.S_NO,A.DISPLAY_NAME=B.DISPLAY_NAME,A.DISPLAY_FORM_NAME=B.DISPLAY_FORM_NAME
FROM MODULES A
JOIN 
(
	SELECT * FROM MODULES WHERE USER_CODE='0000000'
)B ON B.FORM_NAME=A.FORM_NAME AND B.FORM_OPTION=A.FORM_OPTION
WHERE A.USER_CODE<>'0000000' 

