IF OBJECT_ID('tempdb..#tmpwps','U') IS NOT NULL
	drop table #tmpwps
	
select distinct ps_id,a.inv_id into #tmpwps from ind01106 a (nolock) 
join inm01106 b (nolock) on a.inv_id=b.inv_id where entry_mode=2 and cancelled=0


update a set wsl_inv_id=isnull(b.inv_id,'') from wps_mst a left join #tmpwps b on b.ps_id=a.ps_id
where a.wsl_inv_id<>isnull(b.inv_id,'')

