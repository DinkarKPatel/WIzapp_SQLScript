CREATE PROCEDURE UPLOAD_CUSTOMER
(
	@cCustomerCode VARCHAR(20)
)
AS
BEGIN
	SELECT B.pincode as PIN,* FROM CUSTDYM A
	JOIN area B ON B.area_code=A.area_code
	JOIN CITY C ON c.CITY_CODE=B.city_code
	JOIN state D ON D.state_code=C.state_code
	Left outer JOIN COUNTRY E ON E.COUNTRY_CODE=D.region_code
	WHERE CUSTOMER_CODE=@cCustomerCode
END