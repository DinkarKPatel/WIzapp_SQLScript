update parcel_mst set bilty_no=left(convert(varchar(38),NEWID()),15) where isnull(bilty_no,'')=''

update parcel_mst set bilty_no=left(convert(varchar(38),NEWID()),15) 
where bilty_no=parcel_memo_no