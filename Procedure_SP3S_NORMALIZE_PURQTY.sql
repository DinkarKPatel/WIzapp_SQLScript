create PROCEDURE SP3S_NORMALIZE_PURQTY    
(    
@CTARGETTABLE VARCHAR(30),    
@NSPID VARCHAR(50)='',    
@CERRORMSG VARCHAR(1000) OUTPUT    
)    
AS    
BEGIN     
         
  Declare @CSTEP varchar(20),@DTSQL NVARCHAR(MAX),@ntotalqty_Beforedistribute numeric(18,3),    
          @ntotalqty_Afterdistribute numeric(18,3)    
       
   BEGIN TRY    
    
             
     SET @CSTEP=10    
    
       SET @DTSQL=N' SELECT @ntotalqty_Beforedistribute=sum(cast(INVOICE_QUANTITY as numeric(10,3))) FROM '+@CTARGETTABLE+' A  '      
     EXEC SP_EXECUTESQL @DTSQL, N'@ntotalqty_Beforedistribute numeric(18,3) output ',@ntotalqty_Beforedistribute=@ntotalqty_Beforedistribute OUTPUT      
     PRINT @DTSQL    
       
	 
   IF OBJECT_ID('TEMPDB..#TMPPOQTY','U') IS NOT NULL    
      DROP TABLE #TMPPOQTY    
    
    SELECT ART.ARTICLE_NO ,P1.PARA1_NAME ,P2.PARA2_NAME, B.ROW_ID ,    
     P3.PARA3_NAME ,P4.PARA4_NAME ,P5.PARA5_NAME ,P6.PARA6_NAME,    
     (b.INVOICE_QUANTITY + ROUND(b.INVOICE_QUANTITY *b.TOLERANCE_PERCENTAGE /100,0))-ISNULL(B.PI_QTY ,0) as INVOICE_QUANTITY,    
     SR=ROW_NUMBER () OVER (PARTITION BY ART.ARTICLE_NO ,P1.PARA1_NAME ,P2.PARA2_NAME,  
     P3.PARA3_NAME ,P4.PARA4_NAME ,P5.PARA5_NAME ,P6.PARA6_NAME   
     ORDER BY B.PO_ID, ART.ARTICLE_NO ,P1.PARA1_NAME ,P2.PARA2_NAME, B.ROW_ID ,    
     P3.PARA3_NAME ,P4.PARA4_NAME ,P5.PARA5_NAME ,P6.PARA6_NAME      
     , (b.INVOICE_QUANTITY + ROUND(b.INVOICE_QUANTITY *b.TOLERANCE_PERCENTAGE /100,0)-ISNULL(B.PI_QTY ,0)) DESC),    
     CUMM_QTY=CAST(0 AS NUMERIC(10,3))    
    INTO #TMPPOQTY    
    FROM  PIM_POID_UPLOAD A    
    JOIN POD01106 B ON A.PO_ID =B.PO_ID    
 JOIN ARTICLE ART (NOLOCK) ON B.ARTICLE_CODE =ART.ARTICLE_CODE  
 JOIN PARA1 P1 (NOLOCK) ON P1.PARA1_CODE =B.PARA1_CODE  
 JOIN PARA2 P2 (NOLOCK) ON P2.PARA2_CODE =B.PARA2_CODE  
 JOIN PARA3 P3 (NOLOCK) ON P3.PARA3_CODE =B.PARA3_CODE  
 JOIN PARA4 P4 (NOLOCK) ON P4.PARA4_CODE =B.PARA4_CODE  
 JOIN PARA5 P5 (NOLOCK) ON P5.PARA5_CODE =B.PARA5_CODE  
 JOIN PARA6 P6 (NOLOCK) ON P6.PARA6_CODE =B.PARA6_CODE  
 WHERE (b.INVOICE_QUANTITY + ROUND(b.INVOICE_QUANTITY *b.TOLERANCE_PERCENTAGE /100,0))-ISNULL(PI_QTY,0)>0 
 AND A.SP_ID =@NSPID    
    
 
       
    
     SET @CSTEP=20  
	 
	 create Index IX_IND_TMPPOQTY ON #TMPPOQTY(article_no,PARA1_name,PARA2_NAME,PARA3_NAME,PARA4_NAME,PARA5_NAME,PARA6_NAME)
      
    UPDATE a SET CUMM_QTY= (SELECT SUM(INVOICE_QUANTITY) FROM #TMPPOQTY B where a.article_no =b.article_no AND A.PARA1_name =B.PARA1_name     
      AND A.PARA2_name =B.PARA2_name AND A.PARA3_name =B.PARA3_name AND A.PARA4_name =B.PARA4_name AND A.PARA5_name =B.PARA5_name     
      AND A.PARA6_name =B.PARA6_name and b.sr <=a.sr   )     
    from #TMPPOQTY a    

   
    
    SET @CSTEP=30    
       
   if object_id('tempdb..#TMPPURQTY','u') is not null    
      drop table #TMPPURQTY    
    
      SELECT b.product_code,b.ARTICLE_NO ,b.PARA1_NAME ,b.PARA2_NAME,   
      b.PARA3_NAME ,b.PARA4_NAME ,b.PARA5_NAME ,b.PARA6_NAME,  
      cast(0 as numeric(10,3)) INVOICE_QUANTITY ,cast('' as varchar(100))  row_id      
       into #TMPPURQTY    
      FROM sku_names  B WHERE 1=2    
    
      SET @CSTEP=40    
    
   SET @DTSQL =N'SELECT  B.PRODUCT_CODE,B.ARTICLE_NO,B.para1_name ,B.PARA2_name,     
     B.PARA3_name ,B.PARA4_name ,B.PARA5_name ,B.para6_name,b.INVOICE_QUANTITY ,b.ROW_ID     
   FROM '+@CTARGETTABLE+' b   '    
   print @DTSQL    
   INSERT INTO #TMPPURQTY(PRODUCT_CODE,ARTICLE_NO,para1_name ,PARA2_name,     
     PARA3_name ,PARA4_name ,PARA5_name ,para6_name,INVOICE_QUANTITY ,ROW_ID )    
   EXEC SP_EXECUTESQL @DTSQL    
    
       
	 
  --  select * from #TMPPOQTY a where a.article_no ='MACT-01BB-030' and a.para1_name='DARK BLUE'  
  --order by a.article_no,a.para1_name,a.para2_name,a.sr   
       
  -- select * from #TMPPURQTY a where a.article_no ='MACT-01BB-030' and a.para1_name='DARK BLUE'  
  --order by a.article_no,a.para1_name,a.para2_name  
  
  --return  
   DELETE b FROM #TMPPOQTY A    
   JOIN #TMPPURQTY B ON A.ARTICLE_NO =B.ARTICLE_NO AND A.para1_name =B.para1_name AND A.PARA2_name =B.PARA2_name     
   AND A.PARA3_name =B.PARA3_name AND A.PARA4_name =B.PARA4_name AND A.PARA5_name =B.PARA5_name     
   AND A.para6_name =B.para6_name     
   WHERE A.INVOICE_QUANTITY >=B.INVOICE_QUANTITY    
    

	 
        
  if object_id('tempdb..#TMPPURQTY_final','u') is not null    
     drop table #TMPPURQTY_final    
    
   select b.product_code,b.para1_name ,b.para2_name,  a.article_no,a.sr,a.invoice_quantity as Org_pur_qty  ,a.CUMM_QTY ,b.invoice_quantity as Pur_qty,b.row_id ,    
           newid() as New_row_id    
   into #TMPPURQTY_final    
   FROM #TMPPOQTY A    
   JOIN #TMPPURQTY B ON A.ARTICLE_NO =B.ARTICLE_NO AND A.para1_name =B.para1_name AND A.PARA2_name =B.PARA2_name     
   AND A.PARA3_name =B.PARA3_name AND A.PARA4_name =B.PARA4_name AND A.PARA5_name =B.PARA5_name     
   AND A.para6_name =B.para6_name    
   order by a.article_no,a.para1_name,a.PARA2_name,a.sr    
    
 
    
   DELETE A  FROM #TMPPURQTY_FINAL A    
   JOIN    
   (    
    SELECT ROW_ID ,MIN(SR) AS SR     
    FROM #TMPPURQTY_FINAL WHERE CUMM_QTY >= PUR_QTY    
    GROUP BY ROW_ID    
   ) B ON A.ROW_ID=B.ROW_ID AND A.SR >B.SR     
    
  
      
   update   #TMPPURQTY_final set Org_pur_qty =Pur_qty-(cumm_qty -Org_Pur_qty) where cumm_qty > Pur_qty    
    
    
        SET @DTSQL=N'IF EXISTS ( SELECT TOP 1 ''U''  FROM '+@CTARGETTABLE+' A    
      JOIN    
      (    
      SELECT ROW_ID ,SUM(ORG_PUR_QTY) AS ORG_PUR_QTY  FROM #TMPPURQTY_FINAL    
      GROUP BY ROW_ID    
      ) B ON A.ROW_ID=B.ROW_ID    
      WHERE A.INVOICE_QUANTITY>B.ORG_PUR_QTY     
      )      
      SET @CERRORMSG=''SHORTAGE PO QTY FOUND''       
     ELSE      
      SET @CERRORMSG='''' '      
     EXEC SP_EXECUTESQL @DTSQL, N'@CERRORMSG varchar(1000) OUTPUT',@CERRORMSG=@CERRORMSG OUTPUT      
    
      
      
   IF ISNULL(@CERRORMSG,'')<>''    
   BEGIN    
      
     --, A.ARTICLE_NO,A.PARA1_NAME,A.PARA2_NAME,A.PARA3_NAME,A.PARA4_NAME,A.PARA6_NAME,    
    SET @DTSQL =N'SELECT 15 AS SORTORDER, A.PRODUCT_CODE,
	            a.article_no,a.para1_name,a.para2_name,a.para3_name,a.para4_name,a.para5_name,a.para6_name,
	''Po Shoratage'' AS TYPE,    
        ''PUR_QTY:'' +rtrim(ltrim(STR( A.INVOICE_QUANTITY))) +''AVAILABLE_PO_QTY''+ rtrim(ltrim(STR(B.ORG_PUR_QTY))) AS VALUE,    
        ''SHORTAGE PO QTY FOUND'' AS MESSAGE    
     FROM '+@CTARGETTABLE+' A    
     JOIN    
     (    
     SELECT ROW_ID ,SUM(ORG_PUR_QTY) AS ORG_PUR_QTY  FROM #TMPPURQTY_FINAL    
     GROUP BY ROW_ID    
     ) B ON A.ROW_ID=B.ROW_ID    
    WHERE A.INVOICE_QUANTITY>B.ORG_PUR_QTY '    
    PRINT @DTSQL    
       EXEC SP_EXECUTESQL @DTSQL    
    goto end_proc    
    
   END    
       
   declare @CCOLNAME varchar(max),@CALIASCOLNAME varchar(max),@CNEWCOLNAME varchar(1000),    
           @ccmd varchar(max)    
        
   SELECT @CCOLNAME=ISNULL(@CCOLNAME+',','')+(COLUMN_NAME),    
       @CALIASCOLNAME=ISNULL(@CALIASCOLNAME+',','')+('A.'+COLUMN_NAME )    
   FROM INFORMATION_SCHEMA.COLUMNS     
   WHERE TABLE_NAME=@CTARGETTABLE    
   AND COLUMN_NAME NOT IN('row_id','invoice_quantity','ts')    
            ORDER BY COLUMN_NAME    
    
      
            SET @CNEWCOLNAME='ROW_ID,INVOICE_QUANTITY,'    
            SET @CCOLNAME=@CNEWCOLNAME+@CCOLNAME    
                
    
    SET @ccmd=N' INSERT '+@CTARGETTABLE+' ('+@CCOLNAME+')    
       select b.new_ROW_ID as row_id,b.ORG_PUR_QTY as INVOICE_QUANTITY, '+@CALIASCOLNAME+'      
    from '+@CTARGETTABLE+' a    
    join #TMPPURQTY_FINAL b on a.row_id=b.row_id    
    '    
    PRINT @ccmd    
    EXEC (@ccmd)    
    
    
    
      SET @DTSQL=N'     
       delete a     
    from '+@CTARGETTABLE+' a    
    join #TMPPURQTY_FINAL b on a.row_id=b.row_id     
    
    '    
    PRINT @DTSQL    
    EXEC SP_EXECUTESQL @DTSQL    
    
       
            SET @DTSQL=N' SELECT @ntotalqty_Afterdistribute=sum(cast(INVOICE_QUANTITY as numeric(10,3))) FROM '+@CTARGETTABLE+' A  '      
   EXEC SP_EXECUTESQL @DTSQL, N'@ntotalqty_Afterdistribute numeric(18,3) output',@ntotalqty_Afterdistribute=@ntotalqty_Afterdistribute OUTPUT      
    
       
   if isnull(@ntotalqty_Afterdistribute,0)<>isnull(@ntotalqty_Beforedistribute,0)    
   begin    
         SET @CERRORMSG= 'Mismatch in Purchase Qty Normalization '  + rtrim(ltrim(str(isnull(@ntotalqty_Afterdistribute,0))))+'/'
		 + rtrim(ltrim(str(isnull(@ntotalqty_Beforedistribute,0)  ))) 
         goto end_proc    
   end    
    
       
    
   END TRY    
     
 BEGIN CATCH    
  SET @CERRORMSG = 'PROCEDURE SP_PROCESS_IMPORTDATA : STEP- ' +@CSTEP+ ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()    
      
      
  GOTO END_PROC    
 END CATCH    
     
END_PROC:    
    
END
