create Procedure sp3s_PickList_AllocateBIn
(
 @NSPID varchar(100)='',
 @CSOURCETRANSACTIONTABLENAME1 varchar(100),
 @CDEPT_ID varchar(5),
 @CERRMSG varchar(1000) output,
 @cac_code varchar(10)=''
)
as
begin
       
	 DECLARE @CSTEP NUMERIC(5,0),@caccodefilter varchar(100)
     BEGIN TRY        

	 set @CSTEP=10
	 set @CERRMSG=''
	 set @caccodefilter=''

	 if @cac_code<>''
	 set @caccodefilter=' and  c.ac_code='''+@cac_code+''' '



     DECLARE @CCONFIGCOLS VARCHAR(MAX),@DTSQL NVARCHAR(MAX),@cColList varchar(max),@NbeforePLQTY NUMERIC(14,3),
	         @NafterPLQTY NUMERIC(14,3)
	 
	SET @DTSQL =N' select @NbeforePLQTY=sum(quantity) from '+@CSOURCETRANSACTIONTABLENAME1+' c where sp_id='''+@NSPID+''''+@caccodefilter
	Print @DTSQL
	exec Sp_executesql @DTSQL,N' @NbeforePLQTY NUMERIC(14,3) OUTPUT',@NbeforePLQTY output 

     IF EXISTS (SELECT TOP 1 column_name FROM CONFIG_BUYERORDER (NOLOCK) WHERE isnull(open_key,0)=1  
     and column_name='PARA7_NAME')  
    SET @cConfigCols='   a.PARA7_NAME=SN.PARA7_NAME'  
     ELSE IF EXISTS (SELECT TOP 1 column_name FROM CONFIG_BUYERORDER (NOLOCK) WHERE isnull(open_key,0)=1  
     and column_name='PRODUCT_CODE')  
    SET @cConfigCols=' AND a.product_code=sku_names.product_code'    
    ELSE  
    SELECT @cConfigCols = coalesce(@cConfigCols+' and','')+' a.'+COLUMN_NAME +'=SN.'+COLUMN_NAME from CONFIG_BUYERORDER (NOLOCK)   
    WHERE isnull(open_key,0)=1 AND COLUMN_NAME  <>'MRP_FROM_TO'  
 
   DECLARE @CCOLNAME VARCHAR(1000),@CTMPTABLE VARCHAR(100)  
   SELECT @CCOLNAME=coalesce(@CCOLNAME+',','')+'A.'+COLUMN_NAME +' AS ['+COLUMN_NAME+']' FROM CONFIG_BUYERORDER (NOLOCK) WHERE isnull(open_key,0)=1  

   

 SELECT	cast('' as varchar(100)) as MEMO_ID,
        cast('' as varchar(100)) as Row_id,
        cast('' as varchar(100)) as ORD_ROW_ID,
		b.quantity_in_stock PL_qty,b.quantity_in_stock stock_qty,
		CONVERT(VARCHAR(200),'') ARTICLE_NO,CONVERT(VARCHAR(200),'') ARTICLE_NAME,CONVERT(VARCHAR(200),'') product_code,
		CONVERT(VARCHAR(200),'') section_name,CONVERT(VARCHAR(200),'') sub_section_name,
		para1_name,para2_name,para3_name,para4_name,para5_name,para6_name,
		SR_NO=cast(0 as numeric (5,0)),
		cast('' as varchar(max)) as UNQID,
		cast('' as varchar (100)) as Order_id
	 INTO #PENDINGBUYERORDER_stock	
  FROM sku_names a
  JOIN pmt01106 b (NOLOCK) ON 1=1
  WHERE 1=2
	
  SELECT @cColList=isnull(@cColList,'')+
		(CASE WHEN charindex('product_code',@cConfigCols)>0 THEN  ',b.product_code' ELSE '' END)+
		(CASE WHEN charindex('SECTION_NAME',@cConfigCols)>0 THEN  ',sm.section_name' ELSE '' END)+
		(CASE WHEN charindex('SUB_SECTION_NAME',@cConfigCols)>0 THEN  ',sd.sub_section_name ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_NO',@cConfigCols)>0 THEN  ',art.article_no ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_NAME',@cConfigCols)>0 THEN  ',art.article_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ',p1.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ',p2.para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ',p3.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ',p4.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ',p5.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ',p6.para6_name ' ELSE '' END)
	

	 set @DTSQL=N' insert into #PENDINGBUYERORDER_stock(Order_id,MEMO_ID,Row_id,ORD_ROW_ID,PL_qty'+@cColList+',UNQID )
	    select b.order_id, pld.memo_id,  pld.ROW_ID ,pld.ORD_ROW_ID ,pld.QUANTITY '+@cColList+','+Replace(@cColList,',','+')+'
		FROM '+@CSOURCETRANSACTIONTABLENAME1+' pld (nolock)
		join BUYER_ORDER_DET B (nolock) on pld.ORD_ROW_ID=b.row_id
		JOIN BUYER_ORDER_MST C (nolock) ON C.ORDER_ID=B.ORDER_ID  
		JOIN ARTICLE ART ON ART.ARTICLE_CODE=B.ARTICLE_CODE  
		JOIN SECTIOND SD ON ART.SUB_SECTION_CODE =SD.SUB_SECTION_CODE  
		JOIN SECTIONM SM ON SD.section_code  =SM.SECTION_CODE  
		LEFT JOIN PARA1 P1 ON P1.PARA1_CODE=B.PARA1_CODE  
		LEFT JOIN PARA2 P2 ON P2.PARA2_CODE=B.PARA2_CODE  
		LEFT JOIN PARA3 P3 ON P3.PARA3_CODE=B.PARA3_CODE  
		LEFT JOIN PARA4 P4 ON P4.PARA4_CODE=B.PARA4_CODE  
		LEFT JOIN PARA5 P5 ON P5.PARA5_CODE=B.PARA5_CODE  
		LEFT JOIN PARA6 P6 ON P6.PARA6_CODE=B.PARA6_CODE   
		where sp_id='''+@NSPID+'''
		 '+@caccodefilter
		print @DTSQL
		exec sp_executesql @DTSQL



  IF OBJECT_ID ('TEMPDB..#TMPPMT01106','U') IS NOT NULL  
     DROP TABLE #TMPPMT01106  

	 select a.product_code , BIN_ID,quantity_in_stock,
	       cast('' as varchar(max)) as UNQID,
			SRNO=cast(0 as numeric(5,0)),
			RUNNINGTOTAL=CAST(0 AS NUMERIC (5,0))
	 into #TMPPMT01106 
	 from pmt01106 a
	 where 1=2

	 set @cColList=''
	 SELECT @cColList=isnull(@cColList,'')+
		(CASE WHEN charindex('product_code',@cConfigCols)>0 THEN  ',a.product_code' ELSE '' END)+
		(CASE WHEN charindex('SECTION_NAME',@cConfigCols)>0 THEN  ',a.section_name' ELSE '' END)+
		(CASE WHEN charindex('SUB_SECTION_NAME',@cConfigCols)>0 THEN  ',a.sub_section_name ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_NO',@cConfigCols)>0 THEN  ',a.article_no ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_NAME',@cConfigCols)>0 THEN  ',a.article_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ',a.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ',a.para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ',a.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ',a.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ',a.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ',a.para6_name ' ELSE '' END)
	
	 set @cColList=SUBSTRING(@cColList,2,len(@cColList))

	  select MEMO_ID ,row_id ,ORD_ROW_ID ,QUANTITY ,LAST_UPDATE ,bin_id ,PLD_PRODUCT_CODE,pl_inv_qty
	    into #TMPPLD 
	  from PLD01106 
	  where 1=2

	Declare @bALLOCATE_BARCODE varchar(10)
    select  Top 1 @bALLOCATE_BARCODE=value  from config where config_option='ALLOCATE_BARCODE_IN_PICKLIST'


   if isnull(@bALLOCATE_BARCODE,'')='1'
	begin

     set @DTSQL=N' insert into #TMPPMT01106(PRODUCT_CODE,BIN_ID,QUANTITY_IN_STOCK,UNQID)
              SELECT a.PRODUCT_CODE, isnull(a.bin_id,'''') as bin_id,
              sum(isnull(a.quantity_in_stock,0)) as quantity_in_stock,
			  UNQID='+Replace(@cColList,',','+')+'
	   from   
       (  
        SELECT SN.*,PMT.quantity_in_stock,PMT.DEPT_ID ,PMT.BIN_ID   
        FROM sku_names SN (NOLOCK)   
        JOIN PMT01106 PMT (NOLOCK) ON SN.PRODUCT_CODE =PMT.PRODUCT_CODE   
		JOIN BIN (NOLOCK) ON pmt.BIN_ID=BIN.BIN_ID
		join
		(
		  select '+@cColList+'
		  from #PENDINGBUYERORDER_stock a
		  group by '+@cColList+'
		) a on 1=1 and '+@cConfigCols+'
		 WHERE  QUANTITY_IN_STOCK >0 AND pmt.BIN_ID<>''999''  
		 and isnull(pmt.bo_order_id,'''')=''''  
		 AND PMT.DEPT_ID='''+@CDEPT_ID+'''  
       ) a  
       group by  a.PRODUCT_CODE, a.bin_id,'+@cColList+'
       '    
  
    PRINT @DTSQL  
    EXEC SP_EXECUTESQL @DTSQL  





	end
	Else
	begin
	     
			set @DTSQL=N' insert into #TMPPMT01106(PRODUCT_CODE,BIN_ID,QUANTITY_IN_STOCK,UNQID)
				  SELECT '''' as PRODUCT_CODE, isnull(a.bin_id,'''') as bin_id,
				  sum(isnull(a.quantity_in_stock,0)) as quantity_in_stock,
				  UNQID='+Replace(@cColList,',','+')+'
		   from   
		   (  
			SELECT SN.*,PMT.quantity_in_stock,PMT.DEPT_ID ,PMT.BIN_ID   
			FROM sku_names SN (NOLOCK)   
			JOIN PMT01106 PMT (NOLOCK) ON SN.PRODUCT_CODE =PMT.PRODUCT_CODE   
			JOIN BIN (NOLOCK) ON pmt.BIN_ID=BIN.BIN_ID
			join
			(
			  select '+@cColList+'
			  from #PENDINGBUYERORDER_stock a
			  group by '+@cColList+'
			) a on 1=1 and '+@cConfigCols+'
			 WHERE  QUANTITY_IN_STOCK >0 AND pmt.BIN_ID<>''999''  
			 and isnull(pmt.bo_order_id,'''')=''''  
			 AND PMT.DEPT_ID='''+@CDEPT_ID+'''  
		   ) a  
		   group by  a.bin_id,'+@cColList+'
		   '    
  
		PRINT @DTSQL  
		EXEC SP_EXECUTESQL @DTSQL  

	end
	

	
	
	declare @CRow_id varchar(100),@nplqty numeric(10,3),@cunqid varchar(100),
	        @NCALQTY numeric(10,3),@cmemo_id varchar(50),@cORD_ROW_ID varchar(100)

	while exists (select top 1 'u' from #PENDINGBUYERORDER_stock)
	begin
	    
		select top 1 @CRow_id=row_id,@nplqty=PL_qty,@cunqid=UNQID,@cmemo_id=memo_id,@cORD_ROW_ID=ORD_ROW_ID   
		from #PENDINGBUYERORDER_stock


		 IF OBJECT_ID('TEMPDB..#TMPPRODUCTCODE','U')   IS NOT NULL
		    DROP TABLE #TMPPRODUCTCODE
					  
			SELECT   @nplqty AS PL_QTY, @CROW_ID AS ROW_ID ,a.UNQID ,a.product_code  ,A.BIN_ID,A.QUANTITY_IN_STOCK,
			        PRODUCTSR=ROW_NUMBER () over (order by A.QUANTITY_IN_STOCK desc)
                  INTO #TMPPRODUCTCODE
             FROM #TMPPMT01106 A (NOLOCK)
			 WHERE A.unqid =@cunqid 

			

			 SELECT @NCALQTY=SUM(QUANTITY_IN_STOCK)
             FROM #TMPPRODUCTCODE A



		         
			IF ISNULL(@nplqty,0)>ISNULL(@NCALQTY,0)  
			BEGIN
				set @CERRMSG= 'Stock Going Negative'
				select a.PL_qty ,ISNULL(@NCALQTY,0)  As Stock_qty,@CERRMSG As Errmsg, a.* 
				from #PENDINGBUYERORDER_stock A
				where a.Row_id =@CROW_ID
			    GOTO END_PROC
			END
					
			IF OBJECT_ID('TEMPDB..#TMPPRODUCTCODELIST','U')   IS NOT NULL
			   DROP TABLE #TMPPRODUCTCODELIST
		              
			        
				SELECT A.ROW_ID,A.PRODUCT_CODE, A.BIN_ID ,a.unqid ,A.PL_QTY ,A.QUANTITY_IN_STOCK ,
						SUM(B.QUANTITY_IN_STOCK ) AS RUNNINGTOTAL
						INTO #TMPPRODUCTCODELIST
                FROM #TMPPRODUCTCODE A 
				CROSS JOIN #TMPPRODUCTCODE B 
                WHERE A.PRODUCTSR>=B.PRODUCTSR 
				GROUP BY  A.PRODUCT_CODE,A.ROW_ID,A.BIN_ID ,a.unqid ,A.PL_QTY,A.QUANTITY_IN_STOCK ,A.PRODUCTSR


			
						
				DELETE  FROM #TMPPRODUCTCODELIST
				WHERE RUNNINGTOTAL>(SELECT TOP 1 RUNNINGTOTAL FROM #TMPPRODUCTCODELIST WHERE RUNNINGTOTAL >=@nplqty ORDER BY RUNNINGTOTAL)
		            
		            
				UPDATE  #TMPPRODUCTCODELIST
				SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK+(PL_QTY  -RUNNINGTOTAL)
				WHERE RUNNINGTOTAL >@nplqty
		            
				UPDATE A 
				SET QUANTITY_IN_STOCK =A.QUANTITY_IN_STOCK -C.QUANTITY_IN_STOCK
				FROM #TMPPMT01106 A
				JOIN #TMPPRODUCTCODELIST C ON A.UNQID  =C.UNQID 
				AND A.BIN_ID =C.BIN_ID and isnull(a.product_code,'')=c.product_code 
				
			   insert into #TMPPLD( MEMO_ID ,row_id ,ORD_ROW_ID ,QUANTITY ,LAST_UPDATE ,bin_id,pld_product_code )
			   select @cmemo_id   MEMO_ID ,LEFT(NEWID(),100) row_id ,@cORD_ROW_ID  ORD_ROW_ID ,a.quantity_in_stock QUANTITY ,getdate() LAST_UPDATE ,bin_id ,
			          a.product_code
			   FROM #TMPPRODUCTCODELIST A
			   WHERE ISNULL(A.QUANTITY_IN_STOCK,0)<>0
				
			  DELETE FROM #PENDINGBUYERORDER_stock WHERE ROW_ID =@CRow_id			
		
	end
	
	
	 delete a from PLM_PLD01106_UPLOAD a (nolock) where sp_id=@NSPID and a.AC_CODE=@cac_code
	 declare @cinsertstr varchar(max)
	 select @cinsertstr=insertstr  from mirrorxnsinfo where tablename ='pld01106'

      SET @DTSQL=N' INSERT INTO '+@CSOURCETRANSACTIONTABLENAME1+' ('+@CINSERTSTR+',sp_id,ac_code)
	  SELECT '+@CINSERTSTR+','''+@NSPID+''' as sp_id,'''+@cac_code+''' as AC_code FROM #TMPPLD '
	  PRINT @DTSQL
	  EXEC  SP_EXECUTESQL @DTSQL 

	SET @DTSQL =N' select @NafterPLQTY=sum(quantity) from '+@CSOURCETRANSACTIONTABLENAME1+' c  where sp_id='''+@NSPID+''' '+@caccodefilter
	Print @DTSQL
	exec Sp_executesql @DTSQL,N' @NafterPLQTY NUMERIC(14,3) OUTPUT',@NafterPLQTY output 


	IF ISNULL(@NbeforePLQTY ,0)<>ISNULL(@NafterPLQTY ,0) 
	BEGIN
	   SET @CERRMSG='Quntity Mismatch at the time of Get Item Details Please check'+STR(ISNULL(@NbeforePLQTY,0))+' '+STR(ISNULL(@NafterPLQTY,0))
	   GOTO END_PROC
	END


	
   					
 END TRY        
 BEGIN CATCH
  PRINT 'CATCH START'       
  SET @CERRMSG='P:sp3s_PickList_AllocateBIn, STEP:'+LTRIM(RTRIM(STR(@CSTEP)))+', MESSAGE:'+ERROR_MESSAGE()        
  GOTO END_PROC
 END CATCH        
        
END_PROC:   



END