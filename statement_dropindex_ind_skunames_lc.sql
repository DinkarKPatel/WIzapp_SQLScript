if exists (select name from sys.indexes where name='ind_skunames_lc')
	drop index sku_names.ind_skunames_lc
