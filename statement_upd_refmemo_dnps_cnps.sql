update a set prt_rm_id=c.rm_id FROM  dnps_mst a
JOIN rmd01106 b on a.ps_id=b.ps_id
join rmm01106 c on c.rm_id=b.rm_id
where c.cancelled=0 and entry_mode=2
AND isnull(prt_rm_id,'')=''

update a set wsr_cn_id=c.cn_id FROM  cnps_mst a
JOIN cnd01106 b on a.ps_id=b.ps_id
join cnm01106 c on c.cn_id=b.cn_id
where c.cancelled=0 and entry_mode=2
AND isnull(wsr_cn_id,'')=''
