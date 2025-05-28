create Procedure Sp3s_SalesOrderProcessing_PLM
(
  @nUpdateMode numeric(1,0),
  @cmemoid varchar(30)='',
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
		 where a.Memoid=@cmemoid  
		 AND A.XNTYPE IN('OrderPickList','PickList','PLShortClose')
		 group by a.XnType ,A.Memoid,A.RefMemoid,  a.ArticleCode,a.Para1Code ,a.Para2Code ,a.Para3Code
		)


		 INSERT INTO SalesOrderProcessing(XnType,Memoid,RefMemoid,ArticleCode ,Para1Code ,Para2Code ,Para3Code,Qty)
		 SELECT a.XnType ,A.Memoid,A.RefMemoid,  a.ArticleCode,a.Para1Code ,a.Para2Code ,a.Para3Code ,
		 SUM(qty) as Qty
		 FROM #tmpSalesOrderProcessing A
		 LEFT OUTER JOIN cte_SalesOrder B (nolock) ON  a.XnType=b.XnType and A.Memoid=b.Memoid and A.RefMemoid=b.RefMemoid
		 and A.ArticleCode=B.ArticleCode AND A.Para1Code=B.Para1Code and a.Para2Code=b.Para2Code AND A.Para3Code =B.Para3Code
		 WHERE B.ArticleCode is null
		 GROUP BY  a.XnType ,A.Memoid,A.RefMemoid,  a.ArticleCode,a.Para1Code ,a.Para2Code ,a.Para3Code 
	    
		--if enable Edit mode remove End_proc
		GOTO PROC_END


	 set @CSTEP=20

	 LblUpdate:

	 ;with cte as
	 (
	    SELECT a.XnType ,A.Memoid,A.RefMemoid,  a.ArticleCode,a.Para1Code ,a.Para2Code ,a.Para3Code,
		       sum(QTY) as QTY   
	    FROM #tmpSalesOrderProcessing A
		group by a.XnType ,A.Memoid,A.RefMemoid,  a.ArticleCode,a.Para1Code ,a.Para2Code ,a.Para3Code
	 )

	 Update a set QTY=isnull(a.QTY,0)+b.QTY
	 FROM SalesOrderProcessing A  (nolock)
	 join cte b on   a.XnType=b.XnType and A.Memoid=b.Memoid and A.RefMemoid=b.RefMemoid and 
	 A.ARTICLECODE=B.ARTICLECODE AND A.Para1Code=B.Para1Code and a.para2code=b.para2code AND A.PARA3CODE =B.PARA3CODE 
	 where a.memoid=@cmemoid 
	 AND A.XNTYPE IN('OrderPickList','PickList')





END TRY  
  
BEGIN CATCH  
	 SET @CERRORMSG ='ERROR IN PROCEDURE Sp3s_SalesOrderProcessing_PLM STEP#'+@CSTEP+' '+ ERROR_MESSAGE()  
	 PRINT 'ENTER CATCH BLOCK OF Sp3s_SalesOrderProcessing_PLM'  
	   
	 GOTO PROC_END   
END CATCH  
    
PROC_END:    
end