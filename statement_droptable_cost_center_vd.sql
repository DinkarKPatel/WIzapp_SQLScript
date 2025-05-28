if exists (select * from information_schema.tables (NOLOCK) where table_name='cost_center_vd')
	drop table cost_center_vd

