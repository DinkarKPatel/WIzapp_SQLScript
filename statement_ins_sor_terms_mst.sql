IF NOT EXISTS (SELECT TOP 1 * FROM sor_terms_mst)
	insert into sor_terms_mst (sor_terms_code,sor_terms_name)
	select 'NDM','NRV and Discounted Margin'
	union
	select 'NFM','NRV and Fresh Margin'
	union
	select 'MFM','MRP and Fresh Margin'
	union
	select 'TFM','Taxable Value and Fresh Margin'
	union
	select 'TDM','Taxable Value and Discounted Margin'

IF NOT EXISTS (SELECT TOP 1 * FROM sor_terms_mst where sor_terms_code='000')
	insert into sor_terms_mst (sor_terms_code,sor_terms_name)
	select '000',''

IF NOT EXISTS (SELECT TOP 1 * FROM sor_terms_mst where sor_terms_code='NWM')
	INSERT sor_terms_mst	( sor_terms_code, sor_terms_name )  
	SELECT 	'NWM' sor_terms_code,'NRV and Weighted Discount Margin'


IF NOT EXISTS (SELECT TOP 1 * FROM sor_terms_mst where sor_terms_code='NRV')
	insert into sor_terms_mst (sor_terms_code,sor_terms_name)
	select 'NRV','NRV'
	union
	select 'MRP','MRP'
	union
	select 'TAX','Taxable Value'
ELSE
	UPDATE sor_terms_mst SET sor_terms_name=(CASE WHEN sor_terms_code='NRV' THEN 'NRV' WHEN sor_terms_code='MRP' THEN 'MRP' ELSE 'Taxable Value' END)
	where SOR_TERMS_CODE IN ('NRV','MRP','TAX')

IF NOT EXISTS (SELECT TOP 1 * FROM sor_terms_mst where sor_terms_code='EDS')
	insert into sor_terms_mst (sor_terms_code,sor_terms_name)
	select 'EDS','EOSS Discount Sharing'
