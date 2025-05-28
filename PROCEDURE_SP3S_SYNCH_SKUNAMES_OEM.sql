CREATE PROCEDURE SP3S_SYNCH_SKUNAMES_OEM
AS
BEGIN
	 IF EXISTS (SELECT TOP 1 * from config (NOLOCK) where config_option='build_pending_skunames_oemSupplier' AND value='1')
			RETURN

	update a set oem_ac_code=b.shipping_from_ac_code,oem_ac_name=lm.ac_name from sku_names a with (rowlock)
	JOIN sku b (NOLOCK) ON b.product_code=a.product_code
	JOIN lm01106 lm (NOLOCK) ON lm.AC_CODE=b.SHIPPING_FROM_AC_CODE
	WHERE isnull(a.oem_AC_CODE,'')<>isnull(b.SHIPPING_FROM_AC_CODE,'')

	  IF NOT EXISTS (SELECT TOP 1 * from config where config_option='build_pending_skunames_oemSupplier')
	  BEGIN
		  INSERT config	( config_option,  Description,  last_update,  row_id,value)  
		  SELECT 'build_pending_skunames_oemSupplier'  config_option,'One time update of newly inserted column Oem supplier' Description, 
				  getdate() last_update,newid() row_id,'1' value
	  END	
	  ELSE
		 UPDATE config SET value='1' where config_option='build_pending_skunames_oemSupplier'

END

