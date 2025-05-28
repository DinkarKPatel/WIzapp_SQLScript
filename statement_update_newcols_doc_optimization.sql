DECLARE @cHoLocId VARCHAR(4),@cLocId VARCHAR(4)

SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'
SELECT TOP 1 @cLocId=value FROM config (NOLOCK) WHERE config_option='location_id'

IF @cHoLocId<>@cLocId
	RETURN

update a set  docwsl_parcel_memo_id=b.parcel_memo_id FRom inm01106 a 
JOIN parcel_det b ON a.inv_id=b.REF_MEMO_ID
JOIN parcel_mst c ON c.parcel_memo_id=b.parcel_memo_id
WHERE inv_mode=2 AND c.xn_type='WSL' AND c.cancelled=0

update a set  docprt_parcel_memo_id=b.parcel_memo_id FRom rmm01106 a 
JOIN parcel_det b ON a.rm_id=b.REF_MEMO_ID
JOIN parcel_mst c ON c.parcel_memo_id=b.parcel_memo_id
WHERE a.mode=2 AND c.xn_type='PRT' AND c.cancelled=0

UPDATE a SET barcodes_generated=1 FROM irm01106 a 
JOIN ird01106 b ON a.irm_memo_id=b.irm_memo_id
WHERE new_product_code<>''


