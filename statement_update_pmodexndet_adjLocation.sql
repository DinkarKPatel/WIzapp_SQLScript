select memo_id INTO #tmpAdjmemo FROM paymode_xn_det (NOLOCK) WHERE isnull(adj_memo_id,'')<>''

update A SET adj_location_Code=left(adj_memo_id,2) FROM paymode_xn_det a WITH (ROWLOCK) JOIN #tmpAdjmemo b ON a.memo_id=b.memo_id
where adj_memo_id is not null and isnull(adj_location_Code,'')=''