update a set parcel_ac_code=b.ac_code from  parcel_mst a 
join parcel_det b on a.parcel_memo_id=b.parcel_memo_id
where isnull(a.parcel_ac_code,'') in ('','0000000000')

update a set total_amount=b.total_amount from  parcel_mst a 
join (select parcel_memo_id,sum(amount) total_amount from  parcel_det 
		where amount<>PARTY_INV_AMT and isnull(amount,0)<>0
	  group by parcel_memo_id)  b on a.parcel_memo_id=b.parcel_memo_id
where a.total_amount=0
