update a set xn_item_type=b.xn_item_type from pim01106 a join inm01106 b ON a.inv_id=b.inv_id
WHERE isnull(a.xn_item_type,0)<>isnull(b.xn_item_type,0)

update a set xn_item_type=b.xn_item_type from cnm01106 a join rmm01106 b ON a.rm_id=b.rm_id
WHERE isnull(a.xn_item_type,0)<>isnull(b.xn_item_type,0)