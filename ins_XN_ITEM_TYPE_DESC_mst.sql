IF NOT EXISTS (SELECT TOP 1 * from XN_ITEM_TYPE_DESC_mst)
	insert into XN_ITEM_TYPE_DESC_mst (xn_item_type,xn_item_type_desc)
	select 1 xn_item_type,'INV'
	union 
	select 2 xn_item_type,'CONS'
	union
	select 3 xn_item_type,'ASSESTS'
	union
	select 4 xn_item_type,'Services'
