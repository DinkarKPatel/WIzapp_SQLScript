 INSERT SOR_FDNFCN_LINK	( refFcnMemoId, refFdnMemoId, sorMemoId )  
 SELECT null  refFcnMemoId,rm_id refFdnMemoId,a.memo_id sorMemoId FROM eosssorm a
 join rmm01106 b on a.ref_fdnfcn_memoid='FDN'+b.rm_id
 left join SOR_FDNFCN_LINK c on c.sorMemoId=a.MEMO_ID
 where b.CANCELLED=0 and c.sorMemoId is null


  INSERT SOR_FDNFCN_LINK	( refFcnMemoId, refFdnMemoId, sorMemoId )  
 SELECT cn_id  refFcnMemoId,null refFdnMemoId,a.memo_id sorMemoId FROM eosssorm a
 join cnm01106 b on a.ref_fdnfcn_memoid='FCN'+b.cn_id
 left join SOR_FDNFCN_LINK c on c.sorMemoId=a.MEMO_ID
 where b.CANCELLED=0 and c.sorMemoId is null

 
