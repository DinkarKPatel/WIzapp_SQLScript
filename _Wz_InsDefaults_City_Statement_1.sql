--*** INSERTION OF DEFAULT ENTRY IN CITY MASTER
IF NOT EXISTS ( SELECT CITY_CODE FROM CITY WHERE CITY_CODE = '0000000' )
BEGIN
	INSERT CITY ( CITY_CODE, CITY, LAST_UPDATE, STATE_CODE,INACTIVE,COMPANY_CODE,DISTT_CODE  )
		VALUES  ( '0000000', '', '', '0000000',0,'01','' )
END
