--DECLARE @cHoLocId CHAR(2)

--SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'

--IF NOT EXISTS (SELECT TOP 1 a.pan_no FROM loc_accounting_company a (NOLOCK)
--               LEFT JOIN location b (NOLOCK) ON a.pan_no=b.PAN_NO AND b.dept_id=@cHoLocId
--			   LEFT JOIN location c (NOLOCK) ON a.pan_no=substring(c.loc_gst_no,3,10) AND c.dept_id=@cHoLocId
--			   WHERE b.pan
--			   )
--	INSERT INTO loc_accounting_company(pan_no,company_name,registered_ADDRESS1,registered_ADDRESS2,registered_area_code)
--	SELECT (CASE WHEN A.LOC_GST_NO<>'' THEN SUBSTRING(A.LOC_GST_NO,3,10) ELSE a.PAN_NO END) pan_no,
--	a.dept_name,A.ADDRESS1,A.ADDRESS2,a.area_code 
--	FROM location a (NOLOCK) WHERE dept_id=@cHoLocId