create Procedure Sp3s_SalesOrderProcessing_Wbo
(
  @nUpdateMode numeric(1,0),
  @cmemoid varchar(30)='',
  @SalesOrderXnType varchar(20)='',
  @CERRORMSG varchar(1000) output
)
as
begin

 Declare @CSTEP varchar(10)

BEGIN TRY 

    set @CSTEP=10

     if @nUpdateMode=3
	    goto LblUpdate

		;with cte_SalesOrder as
		(
	     select a.XnType ,A.Memoid,A.RefMemoid,  a.ArticleCode,a.Para1Code ,a.Para2Code ,a.Para3Code
		 from SalesOrderProcessing a (nolock)
		 where a.Memoid=@cmemoid and a.xntype=@SalesOrderXnType
		 group by a.XnType ,A.Memoid,A.RefMemoid,  a.ArticleCode,a.Para1Code ,a.Para2Code ,a.Para3Code
		)

		 INSERT INTO SalesOrderProcessing(XnType,Memoid,RefMemoid,ArticleCode ,Para1Code ,Para2Code ,Para3Code,Qty)
		 SELECT a.XnType ,A.Memoid,A.RefMemoid,  a.ArticleCode,a.Para1Code ,a.Para2Code ,a.Para3Code ,0 as Qty
		 FROM #tmpSalesOrderProcessing A
		 LEFT OUTER JOIN cte_SalesOrder B (nolock) ON  a.XnType=b.XnType and A.Memoid=b.Memoid and A.RefMemoid=b.RefMemoid
			and A.ArticleCode=B.ArticleCode AND A.Para1Code=B.Para1Code and a.Para2Code=b.Para2Code AND A.Para3Code =B.Para3Code
		 WHERE B.ArticleCode is null
	

	 set @CSTEP=20

	 LblUpdate:

	 if @nUpdateMode=3
	 begin
          
		  
		 UPDATE A SET QTY=A.QTY+ISNULL(B.QTY,0)
		 FROM SALESORDERPROCESSING A  (NOLOCK)
		 LEFT JOIN #TMPSALESORDERPROCESSING B ON   A.XNTYPE=B.XNTYPE AND A.MEMOID=B.MEMOID AND A.REFMEMOID=B.REFMEMOID AND 
		 A.ARTICLECODE=B.ARTICLECODE AND A.PARA1CODE=B.PARA1CODE AND A.PARA2CODE=B.PARA2CODE AND A.PARA3CODE =B.PARA3CODE 
		 WHERE A.MEMOID=@CMEMOID 
		 AND A.XNTYPE=@SALESORDERXNTYPE 


	 end
     else 
	 begin
	     
	    

		 Update a set QTY=isnull(b.QTY,0)
		 FROM SalesOrderProcessing A  (nolock)
		 left join #tmpSalesOrderProcessing b on   a.XnType=b.XnType and A.Memoid=b.Memoid and A.RefMemoid=b.RefMemoid and 
		 A.ARTICLECODE=B.ARTICLECODE AND A.Para1Code=B.Para1Code and a.para2code=b.para2code AND A.PARA3CODE =B.PARA3CODE 
		 where a.memoid=@cmemoid 
		 and a.XnType=@SalesOrderXnType and a.Qty <>isnull(b.QTY,0)


	 end
	 
	 if @nUpdateMode <>1
	 begin
	      
	      
	     
	       ;with cte_order_inv as 
	        (
	          select a.RefMemoId ,a.ArticleCode ,a.para1Code  ,a.Para2Code ,a.Para3Code,
	                 sum(qty) as InvQty 
	          from SalesOrderProcessing A
	          where a.RefMemoId =@cmemoid and a.XnType <>'Order'
	          group by a.RefMemoId ,a.ArticleCode ,a.para1Code  ,a.Para2Code ,a.Para3Code
	        )
	        
	        select a.RefMemoId ,a.ArticleCode ,a.Para1Code ,a.Para2Code ,a.Para3Code ,
	               a.InvQty ,b.QTY 
	        into #tmporderInvError
	        from cte_order_inv A
	        join #tmpSalesOrderProcessing b on  A.RefMemoid=b.RefMemoid and 
		    A.ARTICLECODE=B.ARTICLECODE AND A.Para1Code=B.Para1Code and a.para2code=b.para2code AND A.PARA3CODE =B.PARA3CODE
		    where a.InvQty >b.QTY
		    
		    IF EXISTS (SELECT TOP 1 'U' FROM #TMPORDERINVERROR)
		    begin
		        
		        set @CERRORMSG='order has been allocate in Invoice Please check'
		        
		        select a.refmemoId,b.article_no,p1.para1_name,p2.para2_name,a.Qty,a.InvQty  ,@CERRORMSG As Errmsg
		        from #TMPORDERINVERROR A
		        join article b (nolock) on a.ArticleCode =b.article_code 
		        join Para1 p1 (nolock) on a.para1code =p1.para1_code 
		        join Para2 p2 (nolock) on a.para2code =p2.para2_code 
		        join Para3 p3 (nolock) on a.para3code =p3.para3_code 
		    
		    end
	     
	 ENd




END TRY  
  
BEGIN CATCH  
	 SET @CERRORMSG ='ERROR IN PROCEDURE Sp3s_SalesOrderProcessing_Wbo STEP#'+@CSTEP+' '+ ERROR_MESSAGE()  
	 PRINT 'ENTER CATCH BLOCK OF Sp3s_SalesOrderProcessing_Wbo'  
	   
	 GOTO PROC_END   
END CATCH  
    
PROC_END:    
end