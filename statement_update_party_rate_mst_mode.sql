update a set party_rate_mode=(CASE WHEN b.memo_id IS NULL THEN 2 ELSE 1 END)
FROM party_rate_mst a 
LEFT JOIN  party_rate_det b ON a.MEMO_ID=b.memo_id
WHERE ISNULL(party_rate_mode,0)=0