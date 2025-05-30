CREATE PROC SP3S_GETSHIPPINGADDRESS
(
 @CACCODE VARCHAR(10)=''
)
AS
BEGIN
SELECT A.ADDRESS1 
  ,A.ADDRESS2
  ,A.ADDRESS3 	 
  ,A.PIN
  ,A.AREA_CODE
  ,A.AREA_NAME
  ,A.CITY AS CITY_NAME
  ,A.STATE AS STATE_NAME
  ,A.CITY+','+A.STATE+','+A.PIN AS LOCATION
  ,A.ADDRESS1+','+A.ADDRESS2+','+A.ADDRESS3 AS [ADDRESS]	 
  ,CONVERT(VARCHAR(40),NEWID()) AS ROW_ID
FROM LM_SHIPPING_DETAILS A	
--JOIN AREA B ON A.AREA_CODE=B.AREA_CODE
--JOIN CITY C ON B.CITY_CODE=C.CITY_CODE
--JOIN STATE D ON C.STATE_CODE=D.STATE_CODE
WHERE A.AC_CODE=@CACCODE
END
