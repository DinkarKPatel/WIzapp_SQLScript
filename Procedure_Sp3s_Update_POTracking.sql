create Procedure Sp3s_Update_POTracking
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

	
	 INSERT INTO WOW_poTracking(AC_CODE ,ARTICLE_CODE ,PARA1_CODE ,PARA2_CODE,PARA3_CODE,PO_Qty)
	 SELECT A.AC_CODE ,A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE,A.PARA3_CODE,0 as PO_Qty   
	 FROM #tmpWOW_POTracking A
	 LEFT OUTER JOIN WOW_poTracking B ON A.ARTICLE_CODE=B.ARTICLE_CODE AND A.PARA1_CODE=B.PARA1_CODE and a.para2_code=b.para2_code AND A.PARA3_CODE =B.PARA3_CODE and a.ac_code=b.Ac_code 
	 WHERE B.ARTICLE_CODE is null
	 GROUP BY A.AC_CODE ,A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE,A.PARA3_CODE   

	 set @CSTEP=20

	 LblUpdate:

	 ;with cte as
	 (
	    SELECT A.AC_CODE ,A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE,A.PARA3_CODE,
		       sum(PO_Qty) as PO_Qty   
	    FROM #tmpWOW_POTracking A
		group by A.AC_CODE ,A.ARTICLE_CODE ,A.PARA1_CODE ,A.PARA2_CODE,A.PARA3_CODE
	 )

	 Update a set PO_Qty =isnull(a.PO_Qty,0)+b.PO_Qty
	 FROM WOW_poTracking A  (nolock)
	 join cte b on  A.ARTICLE_CODE=B.ARTICLE_CODE AND A.PARA1_CODE=B.PARA1_CODE and a.para2_code=b.para2_code AND A.PARA3_CODE =B.PARA3_CODE and a.ac_code=b.Ac_code


END TRY  
  
BEGIN CATCH  
	 SET @CERRORMSG ='ERROR IN PROCEDURE Sp3s_Update_POTracking STEP#'+@CSTEP+' '+ ERROR_MESSAGE()  
	 PRINT 'ENTER CATCH BLOCK OF Sp3s_Update_POTracking'  
	   
	 GOTO PROC_END   
END CATCH  
    
PROC_END:    
end