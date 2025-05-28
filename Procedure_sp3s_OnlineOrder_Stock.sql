CREATE Procedure sp3s_OnlineOrder_Stock    
(    
 @CORDER_ID varchar(100)='',    
 @CERRMSG varchar(1000) output    
)    
as    
begin    
           
  DECLARE @CSTEP NUMERIC(5,0)    
     BEGIN TRY            
    
  set @CSTEP=10    
    
  IF OBJECT_ID ('TEMPDB..#TMPORDER','U') IS NOT NULL    
     DROP TABLE #TMPORDER    
    
    SELECT B.ORDER_ID , C.ORDER_NO AS [ORDER_NO],C.ORDER_DT AS [ORDER_DT],D.AC_NAME AS [AC_NAME],    
    SKU.ARTICLE_NO AS [ARTICLE_NO],SKU.PARA1_NAME AS [PARA1_NAME],SKU.PARA2_NAME AS [PARA2_NAME],    
    SKU.PARA3_NAME AS [PARA3_NAME],SKU.PARA4_NAME AS [PARA4_NAME],SKU.PARA5_NAME AS [PARA5_NAME],SKU.PARA6_NAME AS [PARA6_NAME],    
    SUM(B.QUANTITY) AS [ORDER_QTY],cast(b.row_id as varchar(40)) as Row_id,    
    CASE WHEN ISNULL(WBO_FOR_DEPT_ID,'')='' THEN C.DEPT_ID ELSE WBO_FOR_DEPT_ID END AS DEPT_ID  ,  
 SKU.SECTION_NAME ,SKU.SUB_SECTION_NAME ,C.SALERETURNTYPE,C.REF_NO,c.AC_code,ISNULL(P7.PARA7_NAME ,'') AS PARA7_NAME,  
 CASE WHEN ISNULL(c.SHIPPING_MOBILE,'')<>'' THEN  c.SHIPPING_MOBILE ELSE c.SHIPPING_EMAIL END As SHIPPING_MOBILE,  
 c.SHIPPING_FNAME,c.SHIPPING_LNAME,c.shipping_pin,SKU.product_code   
    into #TMPORDER    
       FROM BUYER_ORDER_DET B     
    JOIN BUYER_ORDER_MST C ON C.ORDER_ID=B.ORDER_ID    
	JOIN PARA7 P7 ON P7.PARA7_CODE=B.PARA7_CODE     
    LEFT JOIN LM01106 D ON D.AC_CODE=C.AC_CODE    
	JOIN SKU_NAMES SKU ON SKU.para7_name=p7.PARA7_name
 --   JOIN ARTICLE ART ON ART.ARTICLE_CODE=SKU.ARTICLE_CODE    
 --JOIN SECTIOND SD ON ART.SUB_SECTION_CODE =SD.SUB_SECTION_CODE    
 --JOIN SECTIONM SM ON SD.section_code  =SM.SECTION_CODE    
 --   LEFT JOIN PARA1 P1 ON P1.PARA1_CODE=SKU.PARA1_CODE    
 --   LEFT JOIN PARA2 P2 ON P2.PARA2_CODE=SKU.PARA2_CODE    
 --   LEFT JOIN PARA3 P3 ON P3.PARA3_CODE=SKU.PARA3_CODE    
 --   LEFT JOIN PARA4 P4 ON P4.PARA4_CODE=SKU.PARA4_CODE    
 --   LEFT JOIN PARA5 P5 ON P5.PARA5_CODE=SKU.PARA5_CODE    
 --   LEFT JOIN PARA6 P6 ON P6.PARA6_CODE=SKU.PARA6_CODE     
 --LEFT JOIN PARA7 P7 ON P7.PARA7_CODE=B.PARA7_CODE     
    --LEFT OUTER JOIN ARTICLE_FIX_ATTR ATTR  (NOLOCK) ON ART.ARTICLE_CODE = ATTR.ARTICLE_CODE        
    WHERE B.ORDER_ID  =@CORDER_ID    
    GROUP BY B.ORDER_ID , C.ORDER_NO ,C.ORDER_DT ,D.AC_NAME,    
    SKU.ARTICLE_NO ,SKU.PARA1_NAME ,SKU.PARA2_NAME ,    
    SKU.PARA3_NAME ,SKU.PARA4_NAME ,SKU.PARA5_NAME ,SKU.PARA6_NAME ,b.row_id ,    
    CASE WHEN ISNULL(WBO_FOR_DEPT_ID,'')='' THEN C.DEPT_ID ELSE WBO_FOR_DEPT_ID END,b.row_id  ,  
 SKU.SECTION_NAME ,SKU.SUB_SECTION_NAME ,C.SALERETURNTYPE,C.REF_NO,c.AC_code,ISNULL(P7.PARA7_NAME ,'') ,  
 CASE WHEN ISNULL(c.SHIPPING_MOBILE,'')<>'' THEN  c.SHIPPING_MOBILE ELSE c.SHIPPING_EMAIL END ,  
 c.SHIPPING_FNAME,c.SHIPPING_LNAME,c.shipping_pin,sku.product_code   
  
     set @CSTEP=20    
     DECLARE @CCONFIGCOLS VARCHAR(MAX),@DTSQL NVARCHAR(MAX),@NSPID int    
     set @NSPID=@@SPID     
  
  SET @cConfigCols='   a.PARA7_NAME=SN.PARA7_NAME'    
  
  --SELECT * FROM #TMPORDER
  
   -- SET @CSTEP=30    
  
   DECLARE @CCOLNAME VARCHAR(1000),@CDEPT_ID VARCHAR(2),@CTMPTABLE VARCHAR(100)    
    
   set @CCOLNAME=' A.SECTION_NAME, A.SUB_SECTION_NAME,A.ARTICLE_NO '  
  
   SELECT TOP 1 @CDEPT_ID= DEPT_ID FROM #TMPORDER    
   SET @CTMPTABLE='##TMPONLINEORDER'+CAST(@@SPID AS varchar(20))    
    
    SET @DTSQL = N'IF OBJECT_ID(''TEMPDB..'+@CTMPTABLE+''',''U'') IS NOT NULL    
    DROP TABLE '+@CTMPTABLE+''    
   PRINT @DTSQL    
   EXEC SP_EXECUTESQL @DTSQL    
  
    
  
    
   if exists (select top 1 'u' from  #TMPORDER where SaleReturnType in(1))  
   begin  
      
    set @DTSQL=N'SELECT cast(0 as bit) as chk, A.ORDER_ID ,A.ROW_ID,'+@CCOLNAME+', A.PARA7_NAME,A.ORDER_QTY, A.product_code ,SN.dept_id ,SN.BIN_ID , SN.BIN_NAME,   
                        SN.quantity_in_stock,    
                PRODUCTSR=row_number() over(partition by a.row_id order by SN.product_code),    
       cast(0 as numeric(10,3)) as Allocate_Qty,    
       CAST('''' AS VARCHAR(1000)) AS ERRMSG   
       INTO '+@CTMPTABLE+'    
       FROM #TMPORDER A    
       LEFT JOIN     
       (    
        SELECT SN.*,PMT.quantity_in_stock,PMT.DEPT_ID ,PMT.BIN_ID ,bin.bin_name    
        FROM sku_names SN (NOLOCK)     
        LEFT OUTER JOIN PMT01106 PMT (NOLOCK) ON SN.PRODUCT_CODE =PMT.PRODUCT_CODE     
  join bin (nolock) on bin.bin_id=pmt.bin_id  
   WHERE  QUANTITY_IN_STOCK >0 AND pmt.BIN_ID<>''999''    
   and isnull(pmt.bo_order_id,'''')=''''    
   AND PMT.DEPT_ID='''+@CDEPT_ID+'''    
       ) SN ON 1=1 AND '+@cConfigCols+'    
         
       '      
    PRINT @DTSQL    
    EXEC SP_EXECUTESQL @DTSQL    
    
 --   SET @DTSQL=N'SELECT * FROM  '+@CTMPTABLE
	--PRINT @DTSQL    
 --   EXEC SP_EXECUTESQL @DTSQL    
      
    set @DTSQL=N' update a set errmsg=''Order not in stock'' from '+@CTMPTABLE+' a    
    join    
    (    
    SELECT ROW_ID,SUM(QUANTITY_IN_STOCK) AS QUANTITY_IN_STOCK FROM '+@CTMPTABLE+' A    
    group by ROW_ID    
    ) B ON A.ROW_ID =B.ROW_ID     
    where a.ORDER_QTY>isnull(b.QUANTITY_IN_STOCK,0)    
    and a.PRODUCTSR=1'    
          
    PRINT @DTSQL    
    EXEC SP_EXECUTESQL @DTSQL   
   
 end  
 else  
 begin  
      
   
        
  
    SELECT a.product_code,a.REF_ORDER_ID ,a.bin_id,B.location_Code  as Dept_id,CM_NO as ref_sls_memo_no,CM_DT as ref_sls_memo_dt  
         into #TmpSale  
    FROM CMD01106 A  
    JOIN CMM01106 B ON A.CM_ID=B.CM_ID  
    join  
    (  
       
  
    SELECT A.order_id   
    FROM BUYER_ORDER_MST A with (nolock)  
    join #TMPORDER b on CASE WHEN ISNULL(A.SHIPPING_MOBILE,'')<>'' THEN  A.SHIPPING_MOBILE ELSE a.SHIPPING_EMAIL END=b.SHIPPING_MOBILE  
        and a.SHIPPING_FNAME=b.SHIPPING_FNAME and a.SHIPPING_LNAME=b.SHIPPING_LNAME  
        and a.shipping_pin=b.shipping_pin  
    WHERE Mode=3   
    and a.SaleReturnType=1    
    and a.cancelled=0  
    group by A.order_id   
    )  c on a.REF_ORDER_ID=c.Order_id  
    where b.cancelled=0  
  
   
   
         
  --  if @@spid=131  
  --  begin  
  --select 'check #tmpsale',* from #TmpSale  
  -- select 'check #tmporder',* from #Tmporder  
  --     end   
  
     set @DTSQL=N'SELECT cast(0 as bit) as chk, A.ORDER_ID ,A.ROW_ID,'+@CCOLNAME+',A.PARA7_NAME ,A.ORDER_QTY, SN.product_code ,SN.dept_id ,SN.BIN_ID ,    
                         quantity_in_stock,    
                PRODUCTSR=row_number() over(partition by a.row_id order by SN.product_code),    
       cast(0 as numeric(10,3)) as Allocate_Qty,    
       CAST('''' AS VARCHAR(1000)) AS ERRMSG ,REF_SLS_MEMO_NO,REF_SLS_MEMO_DT,SN.BIN_NAME  
       INTO '+@CTMPTABLE+'    
       FROM #TMPORDER A    
       JOIN     
       (    
        SELECT SN.*,PMT.DEPT_ID ,PMT.BIN_ID ,0 as quantity_in_stock,REF_SLS_MEMO_NO,REF_SLS_MEMO_DT,bin.BIN_NAME  
        FROM sku_names SN (NOLOCK)     
        JOIN #TmpSale PMT (NOLOCK) ON SN.PRODUCT_CODE =PMT.PRODUCT_CODE     
  join bin (nolock) on bin.bin_id=pmt.bin_id  
       ) SN ON 1=1 AND '+@cConfigCols+'    
         
       '      
    PRINT @DTSQL    
    EXEC SP_EXECUTESQL @DTSQL    
    
  
  
  
 end  
    
 END TRY            
 BEGIN CATCH    
  PRINT 'CATCH START'           
  SET @CERRMSG='P:sp3s_OnlineOrder_Stock, STEP:'+LTRIM(RTRIM(STR(@CSTEP)))+', MESSAGE:'+ERROR_MESSAGE()            
  GOTO EXIT_PROC    
 END CATCH            
            
EXIT_PROC:       
     SET @DTSQL = N'IF OBJECT_ID(''TEMPDB..'+@CTMPTABLE+''',''U'') is not null     
                   SELECT * FROM  '+@CTMPTABLE+' '    
  EXEC SP_EXECUTESQL  @DTSQL    
      
      
    
    
END  
   
/*
Rohit : 26-05-2025 kvs : 16:04:04
METTLE APPARELS - FYND ORDER -  BARCODE 8909252089073 ONLINE ORDER KE CASE MAIN BLANK DETAILS AA RAHI HAIN IN CASH MEMO ORDER LINK  
LOCATION ID -6Y  
ULTRA 68 852 034 - 47477  
MOB-8580400292 


create Procedure sp3s_OnlineOrder_Stock  
(  
 @CORDER_ID varchar(100)='',  
 @CERRMSG varchar(1000) output  
)  
as  
begin  
         
  DECLARE @CSTEP NUMERIC(5,0)  
     BEGIN TRY          
  
  set @CSTEP=10  
  
  IF OBJECT_ID ('TEMPDB..#TMPORDER','U') IS NOT NULL  
     DROP TABLE #TMPORDER  
  
    SELECT B.ORDER_ID , C.ORDER_NO AS [ORDER_NO],C.ORDER_DT AS [ORDER_DT],D.AC_NAME AS [AC_NAME],  
    ART.ARTICLE_NO AS [ARTICLE_NO],P1.PARA1_NAME AS [PARA1_NAME],P2.PARA2_NAME AS [PARA2_NAME],  
    P3.PARA3_NAME AS [PARA3_NAME],P4.PARA4_NAME AS [PARA4_NAME],P5.PARA5_NAME AS [PARA5_NAME],P6.PARA6_NAME AS [PARA6_NAME],  
    SUM(B.QUANTITY) AS [ORDER_QTY],cast(b.row_id as varchar(40)) as Row_id,  
    CASE WHEN ISNULL(WBO_FOR_DEPT_ID,'')='' THEN C.DEPT_ID ELSE WBO_FOR_DEPT_ID END AS DEPT_ID  ,
	SM.SECTION_NAME ,SD.SUB_SECTION_NAME ,C.SALERETURNTYPE,C.REF_NO,c.AC_code,ISNULL(P7.PARA7_NAME ,'') AS PARA7_NAME,
	CASE WHEN ISNULL(c.SHIPPING_MOBILE,'')<>'' THEN  c.SHIPPING_MOBILE ELSE c.SHIPPING_EMAIL END As SHIPPING_MOBILE,
	c.SHIPPING_FNAME,c.SHIPPING_LNAME,c.shipping_pin,b.product_code 
    into #TMPORDER  
       FROM BUYER_ORDER_DET B   
    JOIN BUYER_ORDER_MST C ON C.ORDER_ID=B.ORDER_ID  
    LEFT JOIN LM01106 D ON D.AC_CODE=C.AC_CODE 	
    JOIN ARTICLE ART ON ART.ARTICLE_CODE=B.ARTICLE_CODE  
	JOIN SECTIOND SD ON ART.SUB_SECTION_CODE =SD.SUB_SECTION_CODE  
	JOIN SECTIONM SM ON SD.section_code  =SM.SECTION_CODE  
    LEFT JOIN PARA1 P1 ON P1.PARA1_CODE=B.PARA1_CODE  
    LEFT JOIN PARA2 P2 ON P2.PARA2_CODE=B.PARA2_CODE  
    LEFT JOIN PARA3 P3 ON P3.PARA3_CODE=B.PARA3_CODE  
    LEFT JOIN PARA4 P4 ON P4.PARA4_CODE=B.PARA4_CODE  
    LEFT JOIN PARA5 P5 ON P5.PARA5_CODE=B.PARA5_CODE  
    LEFT JOIN PARA6 P6 ON P6.PARA6_CODE=B.PARA6_CODE   
	LEFT JOIN PARA7 P7 ON P7.PARA7_CODE=B.PARA7_CODE   
    LEFT OUTER JOIN ARTICLE_FIX_ATTR ATTR  (NOLOCK) ON ART.ARTICLE_CODE = ATTR.ARTICLE_CODE      
    WHERE B.ORDER_ID  =@CORDER_ID  
    GROUP BY B.ORDER_ID , C.ORDER_NO ,C.ORDER_DT ,D.AC_NAME,  
    ART.ARTICLE_NO ,P1.PARA1_NAME ,P2.PARA2_NAME ,  
    P3.PARA3_NAME ,P4.PARA4_NAME ,P5.PARA5_NAME ,P6.PARA6_NAME ,b.row_id ,  
    CASE WHEN ISNULL(WBO_FOR_DEPT_ID,'')='' THEN C.DEPT_ID ELSE WBO_FOR_DEPT_ID END,b.row_id  ,
	SM.SECTION_NAME ,SD.SUB_SECTION_NAME ,C.SALERETURNTYPE,C.REF_NO,c.AC_code,ISNULL(P7.PARA7_NAME ,'') ,
	CASE WHEN ISNULL(c.SHIPPING_MOBILE,'')<>'' THEN  c.SHIPPING_MOBILE ELSE c.SHIPPING_EMAIL END ,
	c.SHIPPING_FNAME,c.SHIPPING_LNAME,c.shipping_pin,b.product_code 

     set @CSTEP=20  
     DECLARE @CCONFIGCOLS VARCHAR(MAX),@DTSQL NVARCHAR(MAX),@NSPID int  
     set @NSPID=@@SPID   

	 SET @cConfigCols='   a.PARA7_NAME=SN.PARA7_NAME'  



   -- SET @CSTEP=30  

   DECLARE @CCOLNAME VARCHAR(1000),@CDEPT_ID VARCHAR(2),@CTMPTABLE VARCHAR(100)  
  
   set @CCOLNAME=' SN.SECTION_NAME, SN.SUB_SECTION_NAME,SN.ARTICLE_NO '

   SELECT TOP 1 @CDEPT_ID= DEPT_ID FROM #TMPORDER  
   SET @CTMPTABLE='##TMPONLINEORDER'+CAST(@@SPID AS varchar(20))  
  
    SET @DTSQL = N'IF OBJECT_ID(''TEMPDB..'+@CTMPTABLE+''',''U'') IS NOT NULL  
    DROP TABLE '+@CTMPTABLE+''  
   PRINT @DTSQL  
   EXEC SP_EXECUTESQL @DTSQL  

  

  
   if exists (select top 1 'u' from  #TMPORDER where SaleReturnType in(1))
   begin
    
    set @DTSQL=N'SELECT cast(0 as bit) as chk, A.ORDER_ID ,A.ROW_ID,'+@CCOLNAME+', A.PARA7_NAME,A.ORDER_QTY, SN.product_code ,SN.dept_id ,SN.BIN_ID , SN.BIN_NAME, 
                        SN.quantity_in_stock,  
                PRODUCTSR=row_number() over(partition by a.row_id order by SN.product_code),  
       cast(0 as numeric(10,3)) as Allocate_Qty,  
       CAST('''' AS VARCHAR(1000)) AS ERRMSG 
       INTO '+@CTMPTABLE+'  
       FROM #TMPORDER A  
       LEFT JOIN   
       (  
        SELECT SN.*,PMT.quantity_in_stock,PMT.DEPT_ID ,PMT.BIN_ID ,bin.bin_name  
        FROM sku_names SN (NOLOCK)   
        JOIN PMT01106 PMT (NOLOCK) ON SN.PRODUCT_CODE =PMT.PRODUCT_CODE   
		join bin (nolock) on bin.bin_id=pmt.bin_id
		 WHERE  QUANTITY_IN_STOCK >0 AND pmt.BIN_ID<>''999''  
		 and isnull(pmt.bo_order_id,'''')=''''  
		 AND PMT.DEPT_ID='''+@CDEPT_ID+'''  
       ) SN ON 1=1 AND '+@cConfigCols+'  
       
       '    
    PRINT @DTSQL  
    EXEC SP_EXECUTESQL @DTSQL  
  
  
    
    set @DTSQL=N' update a set errmsg=''Order not in stock'' from '+@CTMPTABLE+' a  
    join  
    (  
    SELECT ROW_ID,SUM(QUANTITY_IN_STOCK) AS QUANTITY_IN_STOCK FROM '+@CTMPTABLE+' A  
    group by ROW_ID  
    ) B ON A.ROW_ID =B.ROW_ID   
    where a.ORDER_QTY>isnull(b.QUANTITY_IN_STOCK,0)  
    and a.PRODUCTSR=1'  
        
    PRINT @DTSQL  
    EXEC SP_EXECUTESQL @DTSQL 
	
	end
	else
	begin
	   
	
      

	   SELECT a.product_code,a.REF_ORDER_ID ,a.bin_id,B.location_Code  as Dept_id,CM_NO as ref_sls_memo_no,CM_DT as ref_sls_memo_dt
	        into #TmpSale
	   FROM CMD01106 A
	   JOIN CMM01106 B ON A.CM_ID=B.CM_ID
	   join
	   (
	    

	   SELECT A.order_id 
	   FROM BUYER_ORDER_MST A with (nolock)
	   join #TMPORDER b on CASE WHEN ISNULL(A.SHIPPING_MOBILE,'')<>'' THEN  A.SHIPPING_MOBILE ELSE a.SHIPPING_EMAIL END=b.SHIPPING_MOBILE
							 and a.SHIPPING_FNAME=b.SHIPPING_FNAME and a.SHIPPING_LNAME=b.SHIPPING_LNAME
							 and a.shipping_pin=b.shipping_pin
	   WHERE Mode=3 
	   and a.SaleReturnType=1  
	   and a.cancelled=0
	   group by A.order_id 
	   )  c on a.REF_ORDER_ID=c.Order_id
	   where b.cancelled=0

	
	
       
	 --  if @@spid=131
	 --  begin
		--select 'check #tmpsale',* from #TmpSale
		--	select 'check #tmporder',* from #Tmporder
  --     end 

	    set @DTSQL=N'SELECT cast(0 as bit) as chk, A.ORDER_ID ,A.ROW_ID,'+@CCOLNAME+',A.PARA7_NAME ,A.ORDER_QTY, SN.product_code ,SN.dept_id ,SN.BIN_ID ,  
                         quantity_in_stock,  
                PRODUCTSR=row_number() over(partition by a.row_id order by SN.product_code),  
       cast(0 as numeric(10,3)) as Allocate_Qty,  
       CAST('''' AS VARCHAR(1000)) AS ERRMSG ,REF_SLS_MEMO_NO,REF_SLS_MEMO_DT,SN.BIN_NAME
       INTO '+@CTMPTABLE+'  
       FROM #TMPORDER A  
       JOIN   
       (  
        SELECT SN.*,PMT.DEPT_ID ,PMT.BIN_ID ,0 as quantity_in_stock,REF_SLS_MEMO_NO,REF_SLS_MEMO_DT,bin.BIN_NAME
        FROM sku_names SN (NOLOCK)   
        JOIN #TmpSale PMT (NOLOCK) ON SN.PRODUCT_CODE =PMT.PRODUCT_CODE   
		join bin (nolock) on bin.bin_id=pmt.bin_id
       ) SN ON 1=1 AND '+@cConfigCols+'  
       
       '    
    PRINT @DTSQL  
    EXEC SP_EXECUTESQL @DTSQL  
  



	end
  
 END TRY          
 BEGIN CATCH  
  PRINT 'CATCH START'         
  SET @CERRMSG='P:sp3s_OnlineOrder_Stock, STEP:'+LTRIM(RTRIM(STR(@CSTEP)))+', MESSAGE:'+ERROR_MESSAGE()          
  GOTO EXIT_PROC  
 END CATCH          
          
EXIT_PROC:     
     SET @DTSQL = N'IF OBJECT_ID(''TEMPDB..'+@CTMPTABLE+''',''U'') is not null   
                   SELECT * FROM  '+@CTMPTABLE+' '  
  EXEC SP_EXECUTESQL  @DTSQL  
    
    
  
  
END


*/