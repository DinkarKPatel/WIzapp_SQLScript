create Procedure SP3S_Getpara3Details  
(  
  @Para3Name varchar(30)=''  
)  
with recompile  
as  
begin  
  set nocount on
       
  DECLARE @CCOLNAME VARCHAR(MAX),@DTSQL NVARCHAR(MAX) ,@PROD_IMAGE varchar(1000) ,
          @cimageJoin varchar(1000)


   DECLARE @IMG_PARA3 BIT,@IMG_ENABLE BIT   ,@PROD_IMAGE_group varchar(100)
  
  SELECT  @IMG_PARA3=PARA3     
  FROM DBO.IMAGE_INFO_CONFIG WITH(NOLOCK)    
  
  SET @IMG_ENABLE=0  
  set @PROD_IMAGE_group=''

  IF EXISTS ( SELECT TOP 1 'U' FROM DBO.IMAGE_INFO_CONFIG WITH(NOLOCK)   WHERE  
             ISNULL(article,0)=0 and  ISNULL(PARA1,0)=0 AND ISNULL(PARA2,0)=0  AND ISNULL(PARA4,0)=0 AND ISNULL(PARA5,0)=0 AND ISNULL(PARA6,0)=0 AND ISNULL(PRODUCT,0)=0)
  BEGIN

       IF (@IMG_PARA3=1 )  
        SET @IMG_ENABLE=1  

  END
  
  
	IF @IMG_ENABLE=1
	begin
      SET @PROD_IMAGE='IMG.PROD_IMAGE'
	  set @PROD_IMAGE_group=',IMG.PROD_IMAGE'
	end
  ELSE
       SET @PROD_IMAGE='NULL'


SELECT sn.section_name,sn.sub_section_name,sn.mrp, SN.para3_name  ARTICLE_NO, SN.para3_name  ARTICLE_name ,sn.para3_alias as Alias,
       B.DEPT_ALIAS as [Location Alias] , PARA1_NAME Color ,PARA2_NAME ,SUM(A.QUANTITY_IN_STOCK) AS STOCK_QTY ,
	   cast('' as varchar(10)) as Para3_code
  into #TMP_Details 
  FROM SKU_NAMES SN  (NOLOCK)     
  left JOIN PMT01106 A (NOLOCK) ON SN.PRODUCT_CODE =A.PRODUCT_CODE  
  left JOIN LOCATION  B (NOLOCK)  ON  B.DEPT_ID= A.DEPT_ID  
  WHERE isnull(a.BIN_ID,'')<>'999'  
  and sn.para3_name  =@Para3Name  
  GROUP BY sn.section_name,sn.sub_section_name,sn.mrp, SN.para3_name  , SN.para3_name   ,sn.para3_alias,
  B.DEPT_ALIAS  , PARA1_NAME  ,PARA2_NAME

  update a set Para3_code =p3.para3_code  from #TMP_Details a
  join para3 p3 (nolock) on a.ARTICLE_NO =p3.para3_name 
             
 
 SET @CIMAGEJOIN=''
 if (@IMG_PARA3=1 )  
       SET @cimageJoin=N'LEFT OUTER JOIN ' + DB_NAME()+ '_IMAGE..IMAGE_INFO IMG (NOLOCK) ON 1=1 ' +  
          (CASE WHEN @IMG_PARA3 = 1 THEN 'AND IMG.para3_code=art.para3_code ' ELSE ''  END)  
                                  
  
 set @DTSQL=N' select ART.Article_No [Article NO],ART.Article_Name [Article Name],ART.Alias [Article Alias],  
         section_name [Secion Name],sub_section_name [Sub Section Name] ,art.MRP,  
   CAST('+@PROD_IMAGE+'  AS VARBINARY(max)) AS PROD_IMAGE  
  FROM #TMP_Details ART (NOLOCK)  '+@cimageJoin+'
  group by ART.Article_No ,ART.Article_Name,ART.Alias ,  
         section_name ,sub_section_name  ,art.MRP 
   '  +@PROD_IMAGE_group
   print @DTSQL
   EXEC sp_EXECUTESQL  @DTSQL  
        
  
 SELECT a.ARTICLE_NO,[Location Alias] as [Location Alias] ,  Color ,PARA2_NAME ,  
   SUM(isnull(a.STOCK_QTY,0)) AS STOCK_QTY   
  into #TMP_ARTSTOCK   
  FROM #TMP_Details A  (NOLOCK)   
  GROUP BY a.ARTICLE_NO,[Location Alias] ,  Color ,PARA2_NAME  
  having SUM(isnull(a.STOCK_QTY,0))>0
  


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