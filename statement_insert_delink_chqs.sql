declare @cBankheads  varchar(max)

set @cBankheads=dbo.FN_ACT_TRAVTREE('0000000013')

select a.vd_id, voucher_dt,replace(narration,'Paid by Chq # ','') chq_no,a.NARRATION 
into #delink_chqs from vd01106  a (nolock) left join vd_chqbook b (nolock) on a.vd_id=b.vd_id 
join vm01106 c  (nolock) on c.vm_id=a.vm_id
join  lm01106 d (nolock) on d.ac_code=a.ac_code
where c.cancelled=0 and a.narration like '%paid by chq%'
and b.vd_id is  null and charindex(head_code,@cBankheads)>0
order by c.voucher_dt desc



 INSERT vd_chqbook	( chqbook_row_id, ref_row_id, vd_id )  
 SELECT  b.row_id chqbook_row_id,b.row_id ref_row_id, a.vd_id 
 from #delink_chqs a join ChqBook_D b on a.chq_no=b.chq_leaf_no
left join 
(select chqbook_row_id from   vd_chqbook a 
 join vd01106 b on a.vd_id=b.vd_id
 join  vm01106 c on c.vm_id=b.vm_id
 join ChqBook_D d on d.row_id=a.chqbook_row_id
 join #delink_chqs e on e.chq_no=d.chq_leaf_no
 where c.cancelled=0) c on c.chqbook_row_id=b.row_id
 where c.chqbook_row_id is  null

