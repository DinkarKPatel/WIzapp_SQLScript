CREATE PROCEDURE SPREG_GET_COMPANY_DETAILS
(
	@cDept_ID	VARCHAR(5)
)
AS
BEGIN
	;WITH COMP
	AS
	(
		SELECT COMPANY_NAME,ALIAS,ADDRESS1,ADDRESS2,CITY,address9
		FROM COMPANY
		WHERE COMPANY_CODE='01'
	)
	,DEPT
	AS
	(
		SELECT b.area_name ,b.pincode ,c.CITY,d.state, d.state_code, 
        a.*,rc.country_code,rc.country_name
        FROM location a 
        join area b on a.area_code = b.area_code 
        join CITY c on b.city_code = c.CITY_CODE 
        join state d on c.state_code = d.state_code 
        Left outer join regionm r on d.region_code = r.region_code 
        Left outer join country rc on r.country_code = rc.country_code 
		WHERE DEPT_ID=@cDept_ID
	)
	SELECT CAST(ISNULL(A.COMPANY_NAME,'') AS VARCHAR(MAX)) AS DETAILS
	FROM COMP A, DEPT B

END