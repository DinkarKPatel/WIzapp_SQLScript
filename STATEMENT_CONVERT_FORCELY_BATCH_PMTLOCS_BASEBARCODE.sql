
declare @ctablename varchar(100),@dtsql nvarchar(max),@cdbname varchar(50),
        @cproduct_suffix varchar(5),@chodept_id varchar(5)/*Rohit 01-11-2024*/

SET @CDBNAME=DB_NAME()+'_pmt'

select @chodept_id=value  from config where config_option ='Ho_location_id'

set @cproduct_suffix='@'+@chodept_id+'01'
IF OBJECT_ID ('TEMPDB..#tmptablename','U') is not null
	    drop table #tmptablename
	    
create table #tmptablename(tblname varchar(100))

if db_id(@CDBNAME) is not null
begin

	set @dtsql=' select name  from '+@CDBNAME+'.sys.tables where name like ''pmtlocs%'''
	insert into #tmptablename(tblname)
	exec sp_executesql @dtsql
	
	IF OBJECT_ID ('TEMPDB..#TMPPMT','U') is not null
	    drop table #TMPPMT
	
		 SELECT A.PRODUCT_CODE AS ORG_PRODUCT_CODE, A.DEPT_ID,A.BIN_ID, product_code=product_code ,A.quantity_in_stock cbs_qty
	                   	INTO #TMPPMT 
		  from pmt01106 a (NOLOCK) where 1=2


	while exists (select top 1 'U' from #tmptablename)
	begin
    
		select top 1 @ctablename=tblname from #tmptablename

		SET @DTSQL =N'INSERT INTO #TMPPMT(ORG_PRODUCT_CODE,DEPT_ID,BIN_ID,product_code,cbs_qty)
		             SELECT A.PRODUCT_CODE AS ORG_PRODUCT_CODE, A.DEPT_ID,A.BIN_ID, product_code=substring(a.product_code,1,len(a.product_code)-5) ,A.cbs_qty
		            from '+@CDBNAME+'.dbo.'+@ctablename+' A (nolock)
		            where product_code like ''%@%'' and right(product_code,5)='''+@cproduct_suffix+'''

				  if exists (select top 1 ''u'' from #TMPPMT)
				  begin
					
					IF  ( 	SELECT count(*) as totalRow   FROM  '+@CDBNAME+'.dbo.'+@ctablename+' A (nolock)
					 JOIN #TMPPMT B ON A.DEPT_ID=B.DEPT_ID AND A.PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID=B.BIN_ID  )=0
					BEGIN
					    
						 Update a set product_code=substring(a.product_code,1,len(a.product_code)-5) 
		                                 from '+@CDBNAME+'.dbo.'+@ctablename+' A (nolock)
		                                 where product_code like ''%@%'' and right(product_code,5)='''+@cproduct_suffix+''' 

					END
					ELSE
					BEGIN
					     
						 ;WITH CTE_REMOVE AS
						 (
					      SELECT  B.ORG_PRODUCT_CODE ,A.DEPT_ID,A.BIN_ID      FROM  '+@CDBNAME+'.dbo.'+@ctablename+' A (nolock)
					      JOIN #TMPPMT B ON A.DEPT_ID=B.DEPT_ID AND A.PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID=B.BIN_ID
						  )

						  DELETE A FROM     '+@CDBNAME+'.dbo.'+@ctablename+' A (nolock)
						  JOIN CTE_REMOVE B ON A.DEPT_ID=B.DEPT_ID AND A.PRODUCT_CODE =B.ORG_PRODUCT_CODE AND A.BIN_ID=B.BIN_ID

						   uPDATE A SET cbs_qty=A.cbs_qty+B.cbs_qty    FROM  '+@CDBNAME+'.dbo.'+@ctablename+' A (nolock)
					       JOIN #TMPPMT B ON A.DEPT_ID=B.DEPT_ID AND A.PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID=B.BIN_ID
						  


						 Update a set product_code=substring(a.product_code,1,len(a.product_code)-5) 
		                  from '+@CDBNAME+'.dbo.'+@ctablename+' A (nolock)
		                  where product_code like ''%@%'' and right(product_code,5)='''+@cproduct_suffix+''' 

					END
			       end 				
				 '
		print @DTSQL
		exec sp_executesql @DTSQL
		
	
		
		TRUNCATE TABLE #TMPPMT

		delete from #tmptablename where tblname =@ctablename

	end

end 