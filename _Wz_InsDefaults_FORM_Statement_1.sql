IF (NOT EXISTS (SELECT FORM_ID FROM FORM WHERE FORM_ID = '0000000'))
BEGIN
	INSERT INTO FORM (FORM_ID,FORM_NAME,PURCHASE_AC_CODE,SALE_AC_CODE,
					  TAX_AC_CODE, LAST_UPDATE, TAX_PERCENTAGE,PUR_RETURN_AC_CODE,SALE_RETURN_AC_CODE,
					  POST_TAX_SEPARATELY,PHYSICAL_FORM,EXCISE_ACCESSIBLE_PERCENTAGE
					  ,EXCISE_DUTY_PERCENTAGE,EXCISE_EDU_CESS_PERCENTAGE,EXCISE_HEDU_CESS_PERCENTAGE,
					  EXCISE_EDU_CESS_AC_CODE,EXCISE_HEDU_CESS_AC_CODE,EXCISE_DUTY_AC_CODE,INACTIVE)
			VALUES ('0000000','','0000000000','0000000000','0000000000',GETDATE(),0,'0000000000','0000000000'
			,0,0,0,0,0,0,'0000000000','0000000000','0000000000',0)
END
