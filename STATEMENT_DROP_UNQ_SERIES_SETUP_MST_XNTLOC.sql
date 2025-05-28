IF EXISTS(SELECT TOP 1 'U' FROM sysobjecTS where name='unq_series_setup_mst_xntloc' )
ALTER TABLE series_setup_mst DROP CONSTRAINT unq_series_setup_mst_xntloc 



