  
create PROCEDURE SP3S_UPLOADINV_FORAPI  
(  
  @CAPIKEY VARCHAR(20)='',  
  @CPARA6_NAME VARCHAR(100)='' ,
  @nmode numeric(1,0)=1--1 for full 2 for incremental 
)  
AS  
BEGIN  
  
  
  DECLARE @CCMD NVARCHAR(MAX), @val Varchar(MAX),@val2 VARCHAR(MAX),@val3 varchar(MAX),  
      @CERRORMSG varchar(max),@bincremental bit,@UPLOADING_METHOD int,@CCBSQTY VARCHAR(40),  
      @NLESSPERCENTAGE NUMERIC(10,2),@Nminqty NUMERIC(10,2),@CSTOCKFILTER VARCHAR(1000),  
      @CSTOCKQTY AS VARCHAR(1000),@CINCREMENTALFILTER VARCHAR(1000),@CPARA6_NAMEFILTER varchar(1000)  ,
      @CADD_GITQTY_IN_ONLINESTOCK VARCHAR(10)
  
  Declare @tblerror table (Descriptions varchar(1000),Errmsg varchar(1000))  
  
  SET @CPARA6_NAMEFILTER=''  

  SELECT  @CADD_GITQTY_IN_ONLINESTOCK=VALUE FROM CONFIG WHERE CONFIG_OPTION ='ADD_GITQTY_IN_ONLINESTOCK'

  SELECT  @VAL=ISNULL(@VAL + ',','') +  (CASE WHEN COL_VALUE='PRODUCT_CODE' THEN 'LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))'   
  WHEN COL_VALUE='DEPT_ID' THEN 'LOC_VIEW.DEPT_ID' ELSE COL_VALUE END )  
   + ' AS [' + CASE WHEN ISNULL(USER_COL_NAME,'')='' THEN COL_VALUE ELSE USER_COL_NAME END  +']',  
  
   @VAL2=ISNULL(@VAL2 + ',','') +  (CASE WHEN COL_VALUE='PRODUCT_CODE' THEN 'LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))'   
  WHEN COL_VALUE='DEPT_ID' THEN 'LOC_VIEW.DEPT_ID' ELSE COL_VALUE END )  
  FROM INV_UPLOAD_COL_LIST A  (NOLOCK)   
  JOIN INV_UPLOAD_MST B (NOLOCK) ON A.UPLOADING_ID=B.UPLOADING_ID  
  WHERE   COL_VALUE <> 'QUANTITY_IN_STOCK'  
  AND  ISNULL(B.API_KEY,'') =@CAPIKEY  
  

 
   
  
  SELECT TOP 1  @CCBSQTY=QUOTENAME(USER_COL_NAME )  
  FROM INV_UPLOAD_COL_LIST A  (NOLOCK)   
  JOIN INV_UPLOAD_MST B (NOLOCK) ON A.UPLOADING_ID=B.UPLOADING_ID   
  WHERE COL_VALUE = 'QUANTITY_IN_STOCK' AND  ISNULL(B.API_KEY,'') =@CAPIKEY  
  
  
  
    
   if isnull(@CCBSQTY,'')in('','[]')  
   set @CCBSQTY=' [Stock Qty]'  
   
      
    if @CPARA6_NAME <>''  
       set @CPARA6_NAMEFILTER=' and  A.PARA6_NAME='''+@CPARA6_NAME+''''  
  
  
  Select @val3=  ISNULL(Filter,''),@bincremental=incremental,@UPLOADING_METHOD=UPLOADING_METHOD ,  
      @NLESSPERCENTAGE=ISNULL(STOCK_QTY_PER,0),  @Nminqty=ISNULL(MIN_STOCK_QTY,0)  
     From INV_UPLOAD_MST   
  where isnull(API_KEY,'') =@CAPIKEY  

  set @val2=isnull(@val2,'')  
  set @val=isnull(@val,'')  

  if @nmode =2
  set @bincremental=1
  
  
 IF ISNULL(@val3,'')=''   
 BEGIN  
 SET @val3= '1=1'  
 END  
  
  
--*************for description-----------------  
  
 DECLARE @CDESCR VARCHAR(MAX),@CCOLUMNSEPARATOR VARCHAR(5),@CGroupDESCR VARCHAR(MAX)  
 SELECT @CCOLUMNSEPARATOR=SEPARATOR_KEY FROM INV_UPLOAD_MST WHERE API_KEY  =@CAPIKEY  
  
  
 IF ISNULL(@CCOLUMNSEPARATOR,'')=''  
    SET @CCOLUMNSEPARATOR=''  
  
  
  set @CDESCR=' PARA7_NAME '
  
 --SELECT  @CDESCR=ISNULL(@CDESCR +'+'+''''+@CCOLUMNSEPARATOR+'''+','') +  (CASE WHEN COL_VALUE='PRODUCT_CODE' THEN 'LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))'   
 --  WHEN COL_VALUE='DEPT_ID' THEN 'LOC_VIEW.DEPT_ID' ELSE COL_VALUE END )    
 --FROM INV_SKU_COL_LIST a  
 --WHERE ISNULL(FOR_SKU ,0)=1  
 --order by isnull(sku_order,0)  
  
 set @CGroupDESCR=''  
   
  
 IF ISNULL (@CDESCR,'')<>''  
 begin  
    set @CGroupDESCR=+','+@CDESCR  
    SET @CDESCR=+','+@CDESCR+' AS SKU'  
  
 end  
 ELSE  
 SET @CDESCR=''  
  
   
--*************end of description-----------------  
  
  
BEGIN TRANSACTION  
BEGIN TRY  

  --  EXEC SP3S_UPDATEPMT_WITHXNSRPT @cDbName='',@cErrormsg=@CERRORMSG output 

	if isnull(@CERRORMSG,'')<>''
	   goto END_PROC

      
  if @nmode=3
       goto LBLSKU
  
 IF OBJECT_ID('SP3S_UPLOADINV_FORAPI_CUSTOM','P') IS NOT NULL AND ISNULL(@CPARA6_NAME,'')=''  
 begin  
        
   EXEC SP3S_UPLOADINV_FORAPI_CUSTOM   
   goto END_PROC  
 end  
  
      
 set @CERRORMSG=''  
 SET @CSTOCKFILTER=''  
 SET @NLESSPERCENTAGE=ISNULL(@NLESSPERCENTAGE,0)  
 SET @Nminqty=ISNULL(@Nminqty,0)  
  
  
 IF ISNULL(@UPLOADING_METHOD,0)<>2  
 BEGIN  
        
   SET @CSTOCKQTY='  (case when  SUM(QUANTITY_IN_STOCK)-( floor(SUM(QUANTITY_IN_STOCK) * '+RTRIM(LTRIM(STR(@NLESSPERCENTAGE)))+'/100)) <'+RTRIM(LTRIM(STR(@Nminqty)))+' then 0 else   
   SUM(QUANTITY_IN_STOCK)-( floor(SUM(QUANTITY_IN_STOCK) * '+RTRIM(LTRIM(STR(@NLESSPERCENTAGE)))+'/100)) end  
   )  '+@CCBSQTY     
  
   IF ISNULL(@BINCREMENTAL,0)=0  
      SET @CSTOCKFILTER=' AND   (SUM(QUANTITY_IN_STOCK)-( FLOOR(SUM(QUANTITY_IN_STOCK) * '+RTRIM(LTRIM(STR(@NLESSPERCENTAGE)))+'/100))>'+RTRIM(LTRIM(STR(@NMINQTY)))+')'   
   ELSE   
    SET @CSTOCKFILTER=' and    (SUM(QUANTITY_IN_STOCK)-( floor(SUM(QUANTITY_IN_STOCK) * '+RTRIM(LTRIM(STR(@NLESSPERCENTAGE)))+'/100))>'+RTRIM(LTRIM(STR(@Nminqty)))+')'   
  -- SET @CSTOCKFILTER=''  
 --  SET @CINCREMENTALFILTER='  (SUM(QUANTITY_IN_STOCK)-( floor(SUM(QUANTITY_IN_STOCK) * '+RTRIM(LTRIM(STR(@NLESSPERCENTAGE)))+'/100)) )'  
  
 END  
 ELSE   
 BEGIN  
   
    set @CSTOCKQTY='SUM(QUANTITY_IN_STOCK) AS ' +@CCBSQTY     
    SET @CSTOCKFILTER=''  
  
  END  
    
   --add Git Qty in Online Stock
   
   select dept_id ,BIN_ID ,product_code ,quantity_in_stock GIT_QTY,bo_order_id 
   into #tmpGITSTOCK
   from pmt01106 a (nolock)
   where 1=2
   
    if ISNULL(@CADD_GITQTY_IN_ONLINESTOCK,'')='1'
      begin
      
         DECLARE @CCUTOFFDATE VARCHAR(100),@DTODT DateTime
         
         SELECT TOP 1 @CCUTOFFDATE=VALUE FROM CONFIG WHERE CONFIG_OPTION='GIT_CUT_OFF_DATE'  
         select  @DTODT=CONVERT(varchar(10), GETDATE() ,121)
         
           
           INSERT INTO #TMPGITSTOCK(DEPT_ID,PRODUCT_CODE,BIN_ID,GIT_QTY)
			SELECT A.PARTY_DEPT_ID AS DEPT_ID,
			     (CASE CHARINDEX('@',IND.PRODUCT_CODE  ) WHEN 0 THEN IND.PRODUCT_CODE ELSE SUBSTRING (IND.PRODUCT_CODE,1, CHARINDEX('@',IND.PRODUCT_CODE)-1) END) PRODUCT_CODE ,
			     A. TARGET_BIN_ID AS BIN_ID,SUM( IND.QUANTITY) AS GIT_QTY
			FROM INM01106 A (NOLOCK)
			JOIN IND01106 IND (NOLOCK) ON A.INV_ID =IND.INV_ID 
			LEFT JOIN PIM01106 B (NOLOCK) ON A.INV_ID=B.INV_ID AND B.CANCELLED=0 AND B.RECEIPT_DT <=@DTODT AND B.RECEIPT_DT <>''
			WHERE A.INV_DT BETWEEN @CCUTOFFDATE AND @DTODT AND A.INV_MODE =2 AND A.CANCELLED =0 AND B.INV_ID IS NULL
			AND A. TARGET_BIN_ID <>'999'
			GROUP BY A.PARTY_DEPT_ID ,(CASE CHARINDEX('@',IND.PRODUCT_CODE  ) WHEN 0 THEN IND.PRODUCT_CODE ELSE SUBSTRING (IND.PRODUCT_CODE,1, CHARINDEX('@',IND.PRODUCT_CODE)-1) END)
			,A. TARGET_BIN_ID 
			HAVING SUM( IND.QUANTITY)<>0
			
			
      
      end
  
--if (@UPLOADING_METHOD=2 or ISNULL(@BINCREMENTAL,0)=0)  
--   goto LBLCSV  
  if @nmode=1
     goto LBLCSV  
   
      IF OBJECT_ID('TEMPDB..#TMPSTOCK','U') IS NOT NULL  
      DROP TABLE #TMPSTOCK  
      
      SELECT DEPT_ID ,CASE CHARINDEX('@',a.product_code  ) WHEN 0 THEN a.product_code ELSE SUBSTRING (A.PRODUCT_CODE,1, CHARINDEX('@',A.PRODUCT_CODE)-1) END AS PRODUCT_CODE ,  
      SUM(QUANTITY_IN_STOCK) AS QUANTITY_IN_STOCK ,a.bin_id   
      INTO #TMPSTOCK  
      FROM PMT01106 A (NOLOCK)   
      join sku_names sn (nolock) on a.product_code =sn.product_code  
      WHERE A.product_code <>''   
      AND BIN_ID<>'999' and isnull(a.bo_order_id,'')=''  
      AND ISNULL(SN.STOCK_NA,0)=0  
      AND (@CPARA6_NAME='' OR SN.para6_name  =@CPARA6_NAME)  
      GROUP BY DEPT_ID ,CASE CHARINDEX('@',a.product_code  ) WHEN 0 THEN a. product_code ELSE SUBSTRING (A.PRODUCT_CODE,1, CHARINDEX('@',A.PRODUCT_CODE)-1) END , a.bin_id   
      HAVING SUM(QUANTITY_IN_STOCK)>0  
      
      
      if ISNULL(@CADD_GITQTY_IN_ONLINESTOCK,'')='1'
      begin
      
		  Update b set QUANTITY_IN_STOCK =b.QUANTITY_IN_STOCK +a.GIT_QTY 
          FROM #TMPGITSTOCK A
          JOIN #TMPSTOCK B ON A.DEPT_ID =B.DEPT_ID AND A.PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID  
		
          INSERT INTO #TMPSTOCK(DEPT_ID,PRODUCT_CODE,QUANTITY_IN_STOCK,BIN_ID)
          SELECT A.DEPT_ID ,A.PRODUCT_CODE,A.GIT_QTY ,A.BIN_ID 
          FROM #TMPGITSTOCK A
          LEFT JOIN #TMPSTOCK B ON A.DEPT_ID =B.DEPT_ID AND A.PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID  
          where b.PRODUCT_CODE is null
      
      end

	--  select * from #TMPSTOCK
  
  
     IF OBJECT_ID('TEMPDB..#TMPINCREMENTSTOCK','U') IS NOT NULL  
      DROP TABLE #TMPINCREMENTSTOCK  
  
    --alter table PMTUPLOADED add bin_id varchar(7)  
  
    SELECT DEPT_ID,BIN_ID,PRODUCT_CODE,QUANTITY_IN_STOCK,QUANTITY_IN_STOCK AS  OLD_QUANTITY_IN_STOCK   
       INTO #TMPINCREMENTSTOCK  
    FROM PMT01106 (NOLOCK) WHERE 1=2  
  
     
  
      SET @CCMD=N' INSERT INTO #TMPINCREMENTSTOCK(DEPT_ID,BIN_ID,PRODUCT_CODE,QUANTITY_IN_STOCK, OLD_QUANTITY_IN_STOCK)  
      SELECT ISNULL(A.DEPT_ID,B.DEPT_ID ) AS DEPT_ID ,  
             ISNULL(A.bin_id,B.bin_id ) AS bin_id,  
       ISNULL(A.PRODUCT_CODE,B.PRODUCT_CODE ) AS PRODUCT_CODE,  
       SUM(ISNULL(A.QUANTITY_IN_STOCK,0)) AS QUANTITY_IN_STOCK,  
       SUM(ISNULL(b.QUANTITY_IN_STOCK,0)) AS OLD_QUANTITY_IN_STOCK  
      FROM #TMPSTOCK A  
      FULL OUTER JOIN   
      (  
          SELECT bin_id, PRODUCT_CODE,dept_id,sum(quantity_in_stock) as  quantity_in_stock  
		  FROM PMTUPLOADED A (NOLOCK)  
		  where  ISNULL(API_KEY,'''')='''+@CAPIKEY+'''  
		  group by bin_id,PRODUCT_CODE,dept_id  
      )  B  ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.DEPT_ID =B.DEPT_ID  and a.bin_id=b.bin_id  
      JOIN LOC_VIEW LOC_VIEW (NOLOCK) ON ISNULL(A.DEPT_ID,B.DEPT_ID) = LOC_VIEW.DEPT_ID    
      JOIN SKU_NAMES (NOLOCK) ON SKU_NAMES.PRODUCT_CODE=ISNULL(A.PRODUCT_CODE,B.PRODUCT_CODE)  
      join bin (nolock) on bin.bin_id=ISNULL(A.bin_id,B.bin_id )  
      WHERE  ISNULL(A.PRODUCT_CODE,B.PRODUCT_CODE )<>''''  
      AND '+@val3+'  
      GROUP BY ISNULL(A.DEPT_ID,B.DEPT_ID ),ISNULL(A.PRODUCT_CODE,B.PRODUCT_CODE ),ISNULL(A.bin_id,B.bin_id )   
      '  
      PRINT @CCMD    
      EXEC SP_EXECUTESQL @CCMD  

	     
    SET @CCMD=N'SELECT  '+@val+','+@CSTOCKQTY+' '+@CDESCR+'  
           FROM   
           (  
           SELECT A.*,a.sn_hsn_code as hsn_code,a.sn_article_desc as article_desc   
           FROM SKU_NAMES A  (NOLOCK)  
           ) a  
           JOIN #TMPINCREMENTSTOCK B (NOLOCK) ON A.PRODUCT_CODE = B.PRODUCT_CODE    
           JOIN LOC_VIEW LOC_VIEW (NOLOCK) ON B.DEPT_ID = LOC_VIEW.DEPT_ID    
            join bin (nolock) on bin.bin_id=b.bin_id  
           WHERE  B.product_code <> '''' AND '+@val3+'  
         '+@CPARA6_NAMEFILTER+'  
           GROUP BY '+@val2+@CGroupDESCR+' having ( SUM (isnull(QUANTITY_IN_STOCK,0)) <>SUM(isnull(old_QUANTITY_IN_STOCK,0))  
       
		 ) ORDER BY  '+@val2+' '   
    PRINT @CCMD    
    EXEC SP_EXECUTESQL @CCMD  
  
 
  --  '+ @CSTOCKFILTER +  '
     
  
  IF ISNULL(@BINCREMENTAL,0)=1  
  begin  
     
  
    ;WITH CTE AS  
    (  
    SELECT A.DEPT_ID,A.BIN_ID,A.PRODUCT_CODE,API_KEY,  QUANTITY_IN_STOCK = ISNULL(C.QUANTITY_IN_STOCK,0)  
    FROM PMTUPLOADED A  
    left JOIN #TMPINCREMENTSTOCK C ON A.DEPT_ID=C.DEPT_ID  AND A.PRODUCT_CODE =C.PRODUCT_CODE and a.bin_id=c.bin_id  AND ISNULL(A.API_KEY,'')=@CAPIKEY  
    WHERE A.QUANTITY_IN_STOCK <>ISNULL(C.QUANTITY_IN_STOCK,0)  
	and a.API_KEY =@CAPIKEY 
    )  
  
    UPDATE A SET QUANTITY_IN_STOCK =isnull(C.QUANTITY_IN_STOCK,0) ,LAST_UPDATE =GETDATE()  
    FROM PMTUPLOADED A  
    JOIN CTE C ON A.DEPT_ID=C.DEPT_ID  AND A.PRODUCT_CODE =C.PRODUCT_CODE AND A.BIN_ID=C.BIN_ID  AND ISNULL(A.API_KEY,'')=ISNULL(C.API_KEY,'')  
	where a.API_KEY =@CAPIKEY

	
  
    INSERT PMTUPLOADED ( DEPT_ID, product_code, quantity_in_stock, LAST_UPDATE,API_KEY,bin_id   )    
    SELECT  A.DEPT_ID, A.product_code, A.quantity_in_stock, GETDATE() LAST_UPDATE ,@CAPIKEY,a.bin_id   
    FROM #TMPINCREMENTSTOCK A  
    LEFT JOIN PMTUPLOADED B ON A.PRODUCT_CODE =B.product_code AND A.DEPT_ID =B.DEPT_ID and a.bin_id=b.bin_id  AND ISNULL(B.API_KEY,'')=@CAPIKEY  
    WHERE B.product_code IS NULL  
  
    DELETE A FROM PMTUPLOADED A (NOLOCK) WHERE API_KEY=@CAPIKEY AND QUANTITY_IN_STOCK=0  
  end  
  
  
	   if OBJECT_ID('tempdb..#TMPSTOCK','U') is not null
	       drop table #TMPSTOCK
  
  GOTO END_PROC  
  
  LBLCSV:  
                 
    
	   Delete a from PMTUPLOADED A (nolock) where API_KEY =@CAPIKEY 
	   
	   
	   SELECT A.DEPT_ID,A.BIN_ID,A.PRODUCT_CODE,A.QUANTITY_IN_STOCK 
	         into #tmpallStock
	   FROM PMT01106 A (NOLOCK)
	   WHERE A.QUANTITY_IN_STOCK <>0 AND A.BIN_ID <>'999' AND ISNULL(A.BO_ORDER_ID,'')=''
	   and ISNULL(A.PRODUCT_CODE,'')<>''
	   
	   
	   if ISNULL(@CADD_GITQTY_IN_ONLINESTOCK,'')='1'
      begin
      
		  Update b set QUANTITY_IN_STOCK =b.QUANTITY_IN_STOCK +a.GIT_QTY 
          FROM #TMPGITSTOCK A
          JOIN #tmpallStock B ON A.DEPT_ID =B.DEPT_ID AND A.PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID  
		
          INSERT INTO #tmpallStock(DEPT_ID,PRODUCT_CODE,QUANTITY_IN_STOCK,BIN_ID)
          SELECT A.DEPT_ID ,A.PRODUCT_CODE,A.GIT_QTY  QUANTITY_IN_STOCK ,A.BIN_ID 
          FROM #TMPGITSTOCK A
          LEFT JOIN #tmpallStock B ON A.DEPT_ID =B.DEPT_ID AND A.PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID  
          where b.PRODUCT_CODE is null
      
      end


	
		SET @CCMD=N'SELECT   b.DEPT_ID, 
		               CASE CHARINDEX(''@'',b.product_code  ) WHEN 0 THEN b.product_code ELSE SUBSTRING (b.PRODUCT_CODE,1, CHARINDEX(''@'',b.PRODUCT_CODE)-1) END as product_code, 
						sum(b.quantity_in_stock) as quantity_in_stock, getdate() LAST_UPDATE,'''+@CAPIKEY+''' API_KEY,b.bin_id 
           FROM   
           (  
            SELECT A.*,a.sn_hsn_code as hsn_code,a.sn_article_desc as article_desc FROM SKU_NAMES A  (NOLOCK)  
			where  ISNULL(a.STOCK_NA,0)=0  
           ) A  
		   JOIN #tmpallStock B (NOLOCK) ON A.PRODUCT_CODE = B.PRODUCT_CODE    
		   JOIN LOC_VIEW LOC_VIEW (NOLOCK) ON B.DEPT_ID = LOC_VIEW.DEPT_ID    
           JOIN BIN (NOLOCK) ON BIN.BIN_ID=B.BIN_ID  
		   WHERE  B.PRODUCT_CODE <> '''' AND B.BIN_ID<>''999'' '+@CPARA6_NAMEFILTER+'  
		   AND '+@VAL3+' 
		   group by b.DEPT_ID, CASE CHARINDEX(''@'',b.product_code  ) WHEN 0 THEN b.product_code ELSE SUBSTRING (b.PRODUCT_CODE,1, CHARINDEX(''@'',b.PRODUCT_CODE)-1) END,
		   b.bin_id 
		   having sum(b.quantity_in_stock)>0
           '   
		PRINT @CCMD   
		 INSERT PMTUPLOADED ( DEPT_ID, product_code, quantity_in_stock, LAST_UPDATE,API_KEY,bin_id   )    
		EXEC SP_EXECUTESQL @CCMD  
  
  
  
           SET @CCMD=N'SELECT  '+@VAL+' , '+@CSTOCKQTY+'  '+@CDESCR+'  
           FROM   
           (  
            SELECT A.*,a.sn_hsn_code as hsn_code,a.sn_article_desc as article_desc FROM SKU_NAMES A  (NOLOCK) 
			where  ISNULL(a.STOCK_NA,0)=0 
           ) A  
		   JOIN #tmpallStock B (NOLOCK) ON A.PRODUCT_CODE = B.PRODUCT_CODE    
		   JOIN LOC_VIEW LOC_VIEW (NOLOCK) ON B.DEPT_ID = LOC_VIEW.DEPT_ID    
           JOIN BIN (NOLOCK) ON BIN.BIN_ID=B.BIN_ID  
		   WHERE  B.PRODUCT_CODE <> '''' AND B.BIN_ID<>''999'' '+@CPARA6_NAMEFILTER+'  
		   AND '+@VAL3+' GROUP BY '+@VAL2+@CGroupDESCR+'  
			HAVING SUM(ISNULL(QUANTITY_IN_STOCK,0))>0 '+ @CSTOCKFILTER +  
           ' ORDER BY  '+@VAL2+' '   
		PRINT @CCMD   
		EXEC SP_EXECUTESQL @CCMD  
  
        
        
	   if OBJECT_ID('tempdb..#tmpallStock','U') is not null
	       drop table #tmpallStock
  
  
  goto END_PROC  


  LBLSKU:

        
		  SET @CCMD=N'SELECT  '+@VAL+'  '+@CDESCR+'  
           FROM   
           (  
            SELECT A.*,a.sn_hsn_code as hsn_code,a.sn_article_desc as article_desc FROM SKU_NAMES A  (NOLOCK) 
			where  ISNULL(a.STOCK_NA,0)=0 
           ) A  
		   Left JOIN LOC_VIEW LOC_VIEW (NOLOCK) ON 1=2
		   WHERE  a.PRODUCT_CODE <> '''' 
		   AND '+@VAL3+' GROUP BY '+@VAL2+@CGroupDESCR+'  
           ORDER BY  '+@VAL2+' '   
		PRINT @CCMD   
		EXEC SP_EXECUTESQL @CCMD  


     goto END_PROC  


  
  
 END TRY  
 BEGIN CATCH  
  SET @CERRORMSG = 'P:- SP3S_UPLOADINV_FORAPI STEP- SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()  
  GOTO END_PROC  
 END CATCH  
   
END_PROC:  
     IF ISNULL(@CERRORMSG,'')=''  
  SELECT TOP 1 @CERRORMSG=ERRMSG FROM @TBLERROR  
  
  
  
 IF @@TRANCOUNT>0  
 BEGIN  
  IF ISNULL(@CERRORMSG,'')=''   
   commit TRANSACTION  
  ELSE  
  begin  
   ROLLBACK  
  
   if exists (select top 1'u' from @TBLERROR)  
   begin  
          
     select * from @TBLERROR  
   end  
  
  end  
 END  
  
  
  
END  
  
  
  