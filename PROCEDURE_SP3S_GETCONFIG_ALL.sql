CREATE PROCEDURE SP3S_GETCONFIG_ALL
AS
BEGIN
	DECLARE @cdept_id VARCHAR(5)

	SELECT @cdept_id=VALUE FROM CONFIG (NOLOCK) WHERE  config_option='LOCATION_ID'
	SELECT config_option,value,NULL AS dept_id 
	FROM config (NOLOCK)
	GROUP BY config_option,value--,dept_id 
	ORDER BY config_option,value--,dept_id 
END