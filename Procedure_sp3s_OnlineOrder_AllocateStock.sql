create Procedure sp3s_OnlineOrder_AllocateStock
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
				SUM(B.QUANTITY) AS [ORDER_QTY],cast(NEWID() as varchar(40)) as Row_id,
				CASE WHEN ISNULL(WBO_FOR_DEPT_ID,'')='' THEN C.DEPT_ID ELSE WBO_FOR_DEPT_ID END AS DEPT_ID,
				C.location_Code 
				into #TMPORDER
			    FROM BUYER_ORDER_DET B 
				JOIN BUYER_ORDER_MST C ON C.ORDER_ID=B.ORDER_ID
				JOIN LM01106 D ON D.AC_CODE=C.AC_CODE
				JOIN ARTICLE ART ON ART.ARTICLE_CODE=B.ARTICLE_CODE
				JOIN PARA1 P1 ON P1.PARA1_CODE=B.PARA1_CODE
				JOIN PARA2 P2 ON P2.PARA2_CODE=B.PARA2_CODE
				JOIN PARA3 P3 ON P3.PARA3_CODE=B.PARA3_CODE
				JOIN PARA4 P4 ON P4.PARA4_CODE=B.PARA4_CODE
				JOIN PARA5 P5 ON P5.PARA5_CODE=B.PARA5_CODE
				JOIN PARA6 P6 ON P6.PARA6_CODE=B.PARA6_CODE 
				LEFT OUTER JOIN ARTICLE_FIX_ATTR ATTR  (NOLOCK) ON ART.ARTICLE_CODE = ATTR.ARTICLE_CODE    
				WHERE B.ORDER_ID  =@CORDER_ID
				GROUP BY B.ORDER_ID , C.ORDER_NO ,C.ORDER_DT ,D.AC_NAME,C.location_Code,
				ART.ARTICLE_NO ,P1.PARA1_NAME ,P2.PARA2_NAME ,
				P3.PARA3_NAME ,P4.PARA4_NAME ,P5.PARA5_NAME ,P6.PARA6_NAME ,b.row_id ,
				CASE WHEN ISNULL(WBO_FOR_DEPT_ID,'')='' THEN C.DEPT_ID ELSE WBO_FOR_DEPT_ID END
			   

		  set @CSTEP=20
		  DECLARE @CCONFIGCOLS VARCHAR(MAX),@DTSQL NVARCHAR(MAX),@NSPID int
		  set @NSPID=@@SPID 

		  delete from  BATCHWISE_FIXCODE_UPLOAD where sp_id=@NSPID

		  IF EXISTS (SELECT TOP 1 column_name FROM CONFIG_BUYERORDER (NOLOCK) WHERE isnull(open_key,0)=1
			 and column_name='PRODUCT_CODE')
			SET @cConfigCols=' AND a.product_code=sku_names.product_code'
		  ELSE
			SELECT @cConfigCols = coalesce(@cConfigCols+' and','')+' a.'+COLUMN_NAME +'=SN.'+COLUMN_NAME from CONFIG_BUYERORDER (NOLOCK) 
			WHERE isnull(open_key,0)=1 AND COLUMN_NAME  <>'MRP_FROM_TO'

      set @CSTEP=30
	  IF OBJECT_ID('TEMPDB..#TMPPMT01106','U')   IS NOT NULL
		  DROP TABLE #TMPPMT01106

		  SELECT CAST('' AS VARCHAR(50)) as order_id, CAST('' AS VARCHAR(50)) as row_id ,quantity_in_stock as order_qty,product_code ,CAST('' AS VARCHAR(4)) as DEPT_ID ,bin_id ,quantity_in_stock ,
		         cast(0 as numeric(18,0)) as PRODUCTSR
			 into #TMPPMT01106
		  FROM PMT01106 WHERE 1=2
   
	   set @DTSQL=N'SELECT a.order_id, a.row_id,a.order_qty, PMT.product_code ,pmt.dept_id ,pmt.BIN_ID ,pmt.quantity_in_stock,
	               PRODUCTSR=row_number() over(partition by a.row_id order by pmt.product_code)
				   FROM #TMPORDER A
				   JOIN sku_names SN (NOLOCK) ON 1=1 AND '+@cConfigCols+'
				   JOIN PMT01106 PMT (NOLOCK) ON SN.product_Code =PMT.product_code AND A.DEPT_ID=PMT.DEPT_ID 
				   WHERE QUANTITY_IN_STOCK >0 AND pmt.BIN_ID<>''999''	'		
		  PRINT @DTSQL
		  insert into #TMPPMT01106(order_id , row_id,order_qty,product_code,dept_id,BIN_ID,quantity_in_stock,PRODUCTSR)
		  EXEC SP_EXECUTESQL @DTSQL

		  set @CSTEP=40
			  DECLARE @CROW_ID VARCHAR(40),@CDEPT_ID VARCHAR(2),@NORDERQTY NUMERIC(10,3),@NCALQTY NUMERIC(10,3),
			  @CERRORMSG varchar(1000)

				 WHILE  EXISTS(SELECT TOP 1 'U' FROM #TMPORDER)
				 BEGIN

					 SELECT TOP 1 @CROW_ID=ROW_ID ,@CDEPT_ID=location_Code  ,@NorderQTY=ORDER_QTY  
					 FROM #TMPORDER
			    
					 LBLPICKITEM:
			       
						 IF OBJECT_ID('TEMPDB..#TMPPRODUCTCODE','U')   IS NOT NULL
						  DROP TABLE #TMPPRODUCTCODE
					  
					 
		       
						 SELECT a.order_id,   @NORDERQTY AS ORDER_QTY, @CROW_ID AS ROW_ID ,A.PRODUCT_CODE ,A.BIN_ID,A.DEPT_ID,
								  A.QUANTITY_IN_STOCK,a.PRODUCTSR 
						 INTO #TMPPRODUCTCODE
						 FROM #TMPPMT01106 A (NOLOCK)
						 WHERE A.ROW_ID =@CROW_ID 
					
					
		
		
						SELECT @NCALQTY=SUM(QUANTITY_IN_STOCK)
						FROM #TMPPRODUCTCODE A
		            
		            
						IF ISNULL(@NORDERQTY,0)>ISNULL(@NCALQTY,0)  
						BEGIN
							 UPDATE BUYER_ORDER_MST SET CANCELLED =1 WHERE order_id =@CORDER_ID 
							 GOTO EXIT_PROC
						END
			                
	
						IF OBJECT_ID('TEMPDB..#TMPPRODUCTCODELIST','U')   IS NOT NULL
						  DROP TABLE #TMPPRODUCTCODELIST
		              
			        
						SELECT a.order_id, A.ROW_ID,A.PRODUCT_CODE,A.BIN_ID,A.DEPT_ID  ,A.ORDER_QTY,
						A.QUANTITY_IN_STOCK ,
						SUM(B.QUANTITY_IN_STOCK ) AS RUNNINGTOTAL
						INTO #TMPPRODUCTCODELIST
						FROM #TMPPRODUCTCODE A CROSS JOIN #TMPPRODUCTCODE B 
						WHERE A.PRODUCTSR>=B.PRODUCTSR 
						GROUP BY  a.order_id,A.ROW_ID,A.PRODUCT_CODE,A.BIN_ID,A.DEPT_ID  ,A.ORDER_QTY,
						A.QUANTITY_IN_STOCK ,A.PRODUCTSR
					
						
						DELETE  FROM #TMPPRODUCTCODELIST
						WHERE RUNNINGTOTAL>(SELECT TOP 1 RUNNINGTOTAL FROM #TMPPRODUCTCODELIST WHERE RUNNINGTOTAL >=@NorderQTY ORDER BY RUNNINGTOTAL)
		            
		            
		         
						UPDATE  #TMPPRODUCTCODELIST
						SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK+(ORDER_QTY -RUNNINGTOTAL)
						WHERE RUNNINGTOTAL >@NorderQTY
		            
						UPDATE A 
						SET QUANTITY_IN_STOCK =A.QUANTITY_IN_STOCK -C.QUANTITY_IN_STOCK
						FROM #TMPPMT01106 A
						JOIN SKU B ON A.PRODUCT_CODE=B.PRODUCT_CODE 
						JOIN #TMPPRODUCTCODELIST C ON A.PRODUCT_CODE =C.PRODUCT_CODE 
						AND A.BIN_ID =C.BIN_ID AND A.DEPT_ID=C.DEPT_ID 
				
			        
			
						INSERT INTO BATCHWISE_FIXCODE_UPLOAD(ROW_ID,PRODUCT_CODE,QUANTITY,DEPT_ID,BIN_ID,SP_ID,order_id )
						SELECT A.ROW_ID,A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,
						A.DEPT_ID,A.BIN_ID ,@NSPID AS SP_ID,@CORDER_ID as order_id
						FROM #TMPPRODUCTCODELIST A
						WHERE ISNULL(A.QUANTITY_IN_STOCK,0)<>0
					
				
						DELETE FROM #TMPORDER WHERE ROW_ID =@CROW_ID	 
				
				 END
				 set @CSTEP=50
				 

				INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK,bo_order_id  )  
				SELECT 	a.bin_id  BIN_ID,a.dept_id  DEPT_ID,'' DEPT_ID_NOT_STUFFED,getdate() last_update,a. product_code,0 quantity_in_stock,'' rep_id, 0STOCK_RECO_QUANTITY_IN_STOCK ,
						a.order_id 
				FROM  BATCHWISE_FIXCODE_UPLOAD  (NOLOCK)  a
				left join PMT01106 b (nolock) on a.product_code =b.product_code and a.dept_id =b.dept_id and a.bin_id =b.bin_id and isnull(a.order_id,'')=isnull(b.bo_order_id,'')
				WHERE SP_ID=@NSPID  and b.product_code is null
				group by a.PRODUCT_CODE,a.DEPT_ID,a.BIN_ID,a.order_id 

				UPDATE A SET A.quantity_in_stock =A.quantity_in_stock +ISNULL(B.XN_QTY ,0) 
				FROM PMT01106 A 
				join
				(
				  SELECT A.PRODUCT_CODE ,A.DEPT_ID ,A.BIN_ID ,
				         CAST('' AS VARCHAR(50)) AS ORDER_ID,
						 -1*SUM(A.QUANTITY) AS XN_QTY
				  FROM BATCHWISE_FIXCODE_UPLOAD A
				  WHERE SP_ID=@NSPID
				  GROUP BY A.PRODUCT_CODE ,A.DEPT_ID ,A.BIN_ID
				  union ALL
				  SELECT A.PRODUCT_CODE ,A.DEPT_ID ,A.BIN_ID ,
				         A.order_id  AS ORDER_ID,
						 SUM(A.QUANTITY) AS XN_QTY
				  FROM BATCHWISE_FIXCODE_UPLOAD A
				  WHERE SP_ID=@NSPID
				  GROUP BY A.PRODUCT_CODE ,A.DEPT_ID ,A.BIN_ID, A.order_id
				) b on a.product_code =b.product_code and a.dept_id =b.dept_id and a.bin_id =b.bin_id and isnull(b.order_id,'')=isnull(a.bo_order_id,'')
	

   					
 END TRY        
 BEGIN CATCH
  PRINT 'CATCH START'       
  SET @CERRMSG='P:sp3s_OnlineOrder_AllocateStock, STEP:'+LTRIM(RTRIM(STR(@CSTEP)))+', MESSAGE:'+ERROR_MESSAGE()        
  GOTO EXIT_PROC
 END CATCH        
        
EXIT_PROC:   

DELETE FROM BATCHWISE_FIXCODE_UPLOAD WHERE SP_ID=@NSPID

END