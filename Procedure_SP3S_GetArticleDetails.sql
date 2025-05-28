create Procedure SP3S_GetArticleDetails  
(  
  @ArticleNo varchar(30)=''  
)  
with recompile  
as  
begin  
  
       
  DECLARE @CCOLNAME VARCHAR(MAX),@DTSQL NVARCHAR(MAX),@cImageCol VARCHAR(400)  
  
   DECLARE @IMG_SECTION BIT,@IMG_SUB_SECTION BIT,@IMG_ARTICLE BIT,@IMG_PARA1 BIT,@IMG_PARA2 BIT,@IMG_PARA3 BIT,@IMG_PARA4 BIT,@IMG_PARA5 BIT,@IMG_PARA6 BIT,@IMG_PRODUCT BIT,  
         @IMG_ENABLE BIT  
  SELECT @IMG_SECTION=SECTION,@IMG_SUB_SECTION=SUB_SECTION,@IMG_ARTICLE=ARTICLE          
  ,@IMG_PARA1=PARA1 ,@IMG_PARA2=PARA2, @IMG_PARA3=PARA3,@IMG_PARA4=PARA4          
  ,@IMG_PARA5=PARA5 ,@IMG_PARA6=PARA6, @IMG_PRODUCT=PRODUCT          
  FROM DBO.IMAGE_INFO_CONFIG WITH(NOLOCK)    
 
 
  SET @IMG_ENABLE=0  
  
  SET  @cImageCol=''

  if (ISNULL(@IMG_SECTION,0)=1 or ISNULL(@IMG_SUB_SECTION,0)=1 or ISNULL(@IMG_ARTICLE,0)=1)  
  begin
    set @IMG_ENABLE=1
    SET  @cImageCol=',cast('+(CASE WHEN @IMG_ENABLE=1 THEN 'IMG.PROD_IMAGE ' ELSE '''' END)+
	'  AS VARBINARY(max)) AS  PROD_IMAGE '
  end		
  
 set @DTSQL=N' select ART.Article_No [Article NO],ART.Article_Name [Article Name],ART.Alias [Article Alias],  
         sm.section_name [Secion Name],sd.sub_section_name [Sub Section Name] ,art.MRP'+@cImageCol+  
  ' FROM ARTICLE ART (NOLOCK)  
  JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE =ART.SUB_SECTION_CODE  
  JOIN SECTIONM SM (NOLOCK) ON SM.SECTION_CODE =SD.SECTION_CODE '  
   
 if (@IMG_ENABLE=1)  
       SET @DTSQL=@DTSQL+N'LEFT OUTER JOIN ' + DB_NAME()+ '_IMAGE..IMAGE_INFO IMG (NOLOCK) ON 1=1 ' +  
                            (CASE WHEN @IMG_SECTION = 1 THEN 'AND IMG.SECTION_CODE=SM.SECTION_CODE' ELSE ''  END) +  
                            (CASE WHEN @IMG_SUB_SECTION = 1 THEN ' AND IMG.SUB_SECTION_CODE=SD.SUB_SECTION_CODE' ELSE '' END) +  
                            (CASE WHEN @IMG_ARTICLE = 1 THEN ' AND IMG.ARTICLE_CODE=ART.ARTICLE_CODE' ELSE '' END)   
                            +' WHERE art.article_no ='''+@ArticleNo+''''         
 ELSE  
     SET @DTSQL=@DTSQL+'where art.article_no ='''+@ArticleNo+''' '  

	 
  
  print @dtsql
   EXEC sp_EXECUTESQL  @DTSQL  
        
 SELECT SN.ARTICLE_NO,B.DEPT_ALIAS as [Location Alias] , PARA1_NAME Color ,PARA2_NAME ,  
   SUM(A.QUANTITY_IN_STOCK) AS STOCK_QTY   
  into #TMP_ARTSTOCK  
  FROM PMT01106 A  (NOLOCK)   
  JOIN LOCATION  B (NOLOCK)  ON  B.DEPT_ID= A.DEPT_ID    
  JOIN SKU_NAMES SN (NOLOCK) ON SN.PRODUCT_CODE =A.PRODUCT_CODE   
  WHERE   A.QUANTITY_IN_STOCK<>0 AND BIN_ID<>'999'  
  and sn.article_no =@ArticleNo  
  GROUP BY SN.ARTICLE_NO,B.DEPT_ALIAS ,PARA1_NAME ,PARA2_NAME   
  
  
   SELECT @CCOLNAME=COALESCE(@CCOLNAME+',','')+' ['+Para2_name +']'   
  from   
    (  
        select a.para2_name ,MAX(para2_order) as para2_order    
     FROM #TMP_ARTSTOCK A  
     join PARA2 p2 (nolock)  on a.para2_name =p2.para2_name   
     group by  a.para2_name     
         
    ) a  
  order by para2_order  
    
    
    SET @DTSQL=N'SELECT Color ,[Location Alias],'+@CCOLNAME+'  
       FROM #TMP_ARTSTOCK   
       pivot (sum(STOCK_QTY) for Para2_name in('+@CCOLNAME+')) as PVT  
       order by Color ,[Location Alias]  
       '  
  PRINT @DTSQL  
  EXEC SP_EXECUTESQL @DTSQL  
  
  
      
  
  
end  