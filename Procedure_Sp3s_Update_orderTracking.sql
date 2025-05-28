create Procedure Sp3s_Update_orderTracking
(
  @nUpdateMode numeric(1,0),
  @CERRORMSG varchar(1000) output
)
as
begin

 Declare @CSTEP varchar(10)

BEGIN TRY 

    set @CSTEP=10

     if @nUpdateMode=3
	    goto LblUpdate

	
	 INSERT INTO WOW_wboTracking(AC_CODE ,ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE,PARA3_CODE,Order_Qty)
	 SELECT A.AC_CODE ,A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE,A.PARA3_CODE,0 as Order_Qty   
	 FROM #tmpWOW_wboTracking A
	 LEFT OUTER JOIN WOW_wboTracking B ON A.ARTICLE_CODE=B.ARTICLE_CODE AND A.PARA1_CODE=B.PARA1_CODE and a.para2_code=b.para2_code AND A.PARA3_CODE =B.PARA3_CODE and a.ac_code=b.Ac_code 
	 WHERE B.ARTICLE_CODE is null
	 GROUP BY A.AC_CODE ,A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE,A.PARA3_CODE   

	 set @CSTEP=20

	 LblUpdate:

	 ;with cte as
	 (
	    SELECT A.AC_CODE ,A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE,A.PARA3_CODE,
		       sum(Order_Qty) as Order_Qty   
	    FROM #tmpWOW_wboTracking A
		group by A.AC_CODE ,A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE,A.PARA3_CODE
	 )

	 Update a set order_qty=isnull(a.order_qty,0)+b.order_qty
	 FROM WOW_wboTracking A  (nolock)
	 join cte b on  A.ARTICLE_CODE=B.ARTICLE_CODE AND A.PARA1_CODE=B.PARA1_CODE and a.para2_code=b.para2_code AND A.PARA3_CODE =B.PARA3_CODE and a.ac_code=b.Ac_code
	





END TRY  
  
BEGIN CATCH  
	 SET @CERRORMSG ='ERROR IN PROCEDURE Sp3s_Update_orderTracking STEP#'+@CSTEP+' '+ ERROR_MESSAGE()  
	 PRINT 'ENTER CATCH BLOCK OF Sp3s_Update_orderTracking'  
	   
	 GOTO PROC_END   
END CATCH  
    
PROC_END:    
end