
DECLARE @CHODEPTID VARCHAR(5)
select @CHODEPTID=value  from config where config_option ='Ho_location_id'

--DROP TABLE  #tmpfixcode

 select a.PRODUCT_CODE 
 into #tmpfixcode 
 from VW_XNSREPS A (nolock)
 where   a.PRODUCT_CODE  like '%@%' 
 and right(PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
 GROUP BY a.PRODUCT_CODE


 insert into #tmpfixcode(product_code)
 select a.product_code from DOCWSL_IND01106_MIRROR a (nolock)
 left join #tmpfixcode c on a.PRODUCT_CODE =c.PRODUCT_CODE 
 where  a.PRODUCT_CODE  like '%@%' and a.PRODUCT_CODE<>'' 
 and right(a.PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
 and c.PRODUCT_CODE is null
 group by a.PRODUCT_CODE
 
 insert into #tmpfixcode(product_code) 
 select a.product_code from DOCprt_rmd01106_MIRROR a (nolock)
 left join #tmpfixcode c on a.PRODUCT_CODE =c.PRODUCT_CODE 
 where  a.PRODUCT_CODE  like '%@%' and a.PRODUCT_CODE<>'' 
 and right(a.PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
 and c.PRODUCT_CODE is null
 group by a.PRODUCT_CODE
 
 
 insert into #tmpfixcode(product_code) 
 select a.product_code from cmd01106  a (nolock)
 left join #tmpfixcode c on a.PRODUCT_CODE =c.PRODUCT_CODE 
 where  a.PRODUCT_CODE  like '%@%' and a.PRODUCT_CODE<>'' 
 and c.PRODUCT_CODE is null and a.QUANTITY <0
 and right(a.PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
 group by a.PRODUCT_CODE
 
  
 insert into #tmpfixcode(product_code) 
 select a.product_code from pid01106  a (nolock)
 left join #tmpfixcode c on a.PRODUCT_CODE =c.PRODUCT_CODE 
 where  a.PRODUCT_CODE  like '%@%' and a.PRODUCT_CODE<>'' 
 and right(a.PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
 and c.PRODUCT_CODE is null 
 group by a.PRODUCT_CODE

 
 insert into #tmpfixcode(product_code) 
 select a.product_code from wps_det   a (nolock)
 left join #tmpfixcode c on a.PRODUCT_CODE =c.PRODUCT_CODE 
 where  a.PRODUCT_CODE  like '%@%' and a.PRODUCT_CODE<>'' 
 and right(a.PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
 and c.PRODUCT_CODE is null 
 group by a.PRODUCT_CODE

 
 insert into #tmpfixcode(product_code) 
 select a.product_code from rmd01106    a (nolock)
 left join #tmpfixcode c on a.PRODUCT_CODE =c.PRODUCT_CODE 
 where  a.PRODUCT_CODE  like '%@%' and a.PRODUCT_CODE<>'' 
 and right(a.PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
 and c.PRODUCT_CODE is null 
 group by a.PRODUCT_CODE

 
 insert into #tmpfixcode(product_code) 
 select a.product_code from RPS_DET     a (nolock)
 left join #tmpfixcode c on a.PRODUCT_CODE =c.PRODUCT_CODE 
 where  a.PRODUCT_CODE  like '%@%' and a.PRODUCT_CODE<>'' 
 and right(a.PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
 and c.PRODUCT_CODE is null 
 group by a.PRODUCT_CODE

 
 --drop table #tmpskubatch
 
 IF EXISTS (SELECT TOP 1 'U' FROM #tmpfixcode)
 BEGIN
 select A.PRODUCT_CODE org_product_code,((substring(A.product_code,1,charindex('@',A.product_code)-1))) product_code
        INTO #tmpskubatch
 from #tmpfixcode a
 

	 Update a set product_code =b.product_code  from pid01106 A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

 
	 Update a set product_code =b.product_code  from IND01106 A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

 
	 Update a set product_code =b.product_code  from rmd01106 A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

 
	 Update a set product_code =b.product_code  from cmd01106 A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

	 
	 Update a set product_code =b.product_code  from RPS_DET  A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

	 
	 Update a set product_code =b.product_code  from slsset_bcdisc  A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

 
	 Update a set product_code =b.product_code  from icd01106 A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

 
	 Update a set product_code =b.product_code  from FLOOR_ST_DET A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 


	 Update a set product_code =b.product_code  from OPS01106 A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

 
	 Update a set product_code =b.product_code  from wps_det A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 
	 
	  Update a set product_code =b.product_code  from dnps_det A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

 
	 Update a set product_code =b.product_code  from ird01106 A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 
	  where new_product_code <>''


	 Update a set new_product_code =b.product_code  from ird01106 A (nolock)
	 join #tmpskubatch b on a.new_product_code =b.org_product_code 
	  where new_product_code <>''


	 Update a set product_code =b.product_code  from SNC_CONSUMABLE_DET A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

 
	 Update a set product_code =b.product_code  from snc_barcode_det A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 



	 Update a set product_code =b.product_code  from docwsl_ind01106_mirror A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

  
 
	 Update a set product_code =b.product_code  from DOCPRT_rmd01106_MIRROR A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 


	 Update a set product_code =b.product_code  from APD01106 A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 
	 
	 
	 Update a set product_code =b.product_code  from CNPS_DET A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

	 Update a set product_code =b.product_code  from CND01106 A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 

	 Update a set APD_product_code =b.product_code  from APPROVAL_RETURN_DET A (nolock)
	 join #tmpskubatch b on a.APD_product_code =b.org_product_code 
	 
	 Update a set product_code =b.product_code  from jobwork_issue_det A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 
	 join jobwork_issue_mst c on a.issue_id=c.issue_id
	 where isnull(issue_mode,0)=0
	 
	 
	 Update a set product_code =b.product_code  from jobwork_receipt_det A (nolock)
	 join #tmpskubatch b on a.product_code =b.org_product_code 
	 join jobwork_receipt_mst c on a.receipt_id=c.receipt_id
	 where isnull(c.Receive_Mode,0)=0 
	 
	 
	 DELETE a FROM PMT01106 A (nolock)
	 JOIN #tmpskubatch B  on a.product_code =b.org_product_code  
		 
     
	 DELETE a FROM SKU_OH A (nolock)
	 JOIN #tmpskubatch B  on a.product_code =b.org_product_code 
     
     
	 DELETE a FROM SKU_NAMES  A (nolock)
	 JOIN #tmpskubatch B  on a.product_code =b.org_product_code 
     
          
	 DELETE a FROM SKU  A (nolock)
	 JOIN #tmpskubatch B  on a.product_code =b.org_product_code 
	 
   	delete A  from  pmt01106 a (nolock)  where product_code like '%@%' and right(PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
	delete a  from  sku_oh a (nolock) where product_code like '%@%' and right(PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
	delete a  from  sku_names a (nolock) where product_code like '%@%' and right(PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
	delete  a from  sku a (nolock) where product_code like '%@%' and right(PRODUCT_CODE,5) ='@'+@CHODEPTID+'01'
    
  

END