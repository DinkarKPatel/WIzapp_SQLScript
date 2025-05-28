
IF OBJECT_ID('unq_parcel_mst','uq') IS NOT NULL	
ALTER TABLE parcel_mst DROP CONSTRAINT unq_parcel_mst

IF OBJECT_ID('CK_Unq_parcel','C') IS NOT NULL	
ALTER TABLE parcel_mst DROP CONSTRAINT CK_Unq_parcel

