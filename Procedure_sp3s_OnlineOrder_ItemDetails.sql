create Procedure sp3s_OnlineOrder_ItemDetails
(
 @CDEPT_ID varchar(5)='',
 @CERRMSG varchar(1000) output  
)
As
begin
     
	 declare @DTSQL nvarchar(max),@CSTEP varchar(10),@CCOLNAME varchar(1000)

	 set @CCOLNAME=''
	  BEGIN TRY     

	  Set @CSTEP=00

	   set @CCOLNAME=' SM.SECTION_NAME, SD.SUB_SECTION_NAME,ART.ARTICLE_NO '
	 

	 
		;with QTYcte as
		(
		  select row_id, Order_qty ,1 as srNo
		  from #TMPORDER
		  union all
		  select row_id,Order_qty ,SrNo=srNo+1
		  from QTYcte
		  where SrNo <Order_qty
		)

		select * into #tmpNormalize from QTYcte



	  Set @CSTEP=02

		set @DTSQL=N'SELECT cast(0 as bit) as chk, A.ORDER_ID ,A.ROW_ID,'+@CCOLNAME+', A.PARA7_NAME,A.ORDER_QTY, 
		            cast('''' as varchar(100)) as product_code ,'+@CDEPT_ID+' dept_id ,
		            ''000'' BIN_ID , '''' BIN_NAME, 0 as quantity_in_stock,  
					PRODUCTSR=b.srNo,  
					cast(0 as numeric(10,3)) as Allocate_Qty,  
					CAST('''' AS VARCHAR(1000)) AS ERRMSG 
		   FROM #TMPORDER A  
		   join #tmpNormalize b on a.row_id=b.row_id 
		   join Article Art on art.article_no=a.article_no
		   join sectiond Sd on sd.sub_section_code=art.sub_section_code
		   join sectionm sm on sm.section_code=sd.section_code

		   '    
		PRINT @DTSQL  
		EXEC SP_EXECUTESQL @DTSQL  
  
END TRY          
 BEGIN CATCH  
  PRINT 'CATCH START'         
  SET @CERRMSG='P:sp3s_OnlineOrder_Stock, STEP:'+LTRIM(RTRIM(STR(@CSTEP)))+', MESSAGE:'+ERROR_MESSAGE()      
  GOTO EXIT_PROC  
 END CATCH          
          
EXIT_PROC: 
	
end