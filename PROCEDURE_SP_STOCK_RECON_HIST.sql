CREATE PROCEDURE SP_STOCK_RECON_HIST--(LocId 3 digit change by Sanjay:30-10-2024)
(
	@MEMO_ID VARCHAR(100),
	@DEPT_ID VARCHAR(10),
	@USER_CODE VARCHAR(50),
	@C_DATE DATETIME,
	@NSTOPMODE NUMERIC(1)=1
)

AS
BEGIN

 BEGIN TRY

   DECLARE @NSTEP varchar(10),@CERRORMSG varchar(1000),@CFINYEAR varchar(5),
           @NSAVETRANLOOP bit ,@CMEMONOPREFIX varchar(50),@NMEMONOLEN  NUMERIC(5,0),@CMEMONOVAL    VARCHAR(50),
		   @CKEYFIELDVAL1 varchar(50),@CSHORTAGEMEMOID varchar(50),@CEXCESSMEMOID varchar(50),
		   @cPhysicalStock varchar(1000),@cshortageStock varchar(1000),@CEXCESSSTOCK varchar(1000)

	   set @CERRORMSG=''
	   set @NSTEP=10
	   SET @CSHORTAGEMEMOID=''
	   SET @CEXCESSMEMOID=''


	   set @CFINYEAR=(select '01'+ DBO.FN_GETFINYEAR(@C_DATE))


	   select top 1 @DEPT_ID=location_code FROM stmh01106 (NOLOCK) WHERE memo_id=@MEMO_ID

		  SELECT a.product_code  as product_code,a.BIN_ID ,c.mrp ,
		         ISNULL(a.STOCK_RECO_QUANTITY_IN_STOCK,0) as STOCK_RECO_QUANTITY_IN_STOCK,
		         isnull(a.PhysicalScanQty,0) as  SCAN_QTY,
				 (CASE WHEN (ISNULL(a.STOCK_RECO_QUANTITY_IN_STOCK,0) - ISNULL(A.PhysicalScanQty,0)) >0   THEN (ISNULL(a.STOCK_RECO_QUANTITY_IN_STOCK,0) - ISNULL(A.PhysicalScanQty,0))    
		                     ELSE 0 END ) AS SHORTAGE_QTY ,
                  (CASE WHEN (ISNULL(a.PhysicalScanQty,0) - ISNULL(A.STOCK_RECO_QUANTITY_IN_STOCK,0)) >0   THEN (ISNULL(a.PhysicalScanQty,0) - ISNULL(A.STOCK_RECO_QUANTITY_IN_STOCK,0))    
		                     ELSE 0 END ) AS EXCESS_QTY ,b.location_code
			
                INTO #TMPSTKREC
		  FROM  PMT01106 A (NOLOCK)
		  JOIN STMH01106 B (NOLOCK) ON A.REP_ID=B.REP_ID 
		  join sku_names c (nolock) on a.product_code =c.product_Code 
		  WHERE B.MEMO_ID=@MEMO_ID 
		  
		  INSERT INTO STOCKRECONDETAILS(MEMO_ID,DEPT_ID,PRODUCT_CODE,BIN_ID,MRP,COMPUTER_QTY,SCAN_QTY,SHORTAGE_QTY,EXCESS_QTY)
		  SELECT @MEMO_ID MEMO_ID,location_code DEPT_ID,PRODUCT_CODE,BIN_ID,MRP,
		         ISNULL(STOCK_RECO_QUANTITY_IN_STOCK,0) AS  COMPUTER_QTY,
		         SCAN_QTY SCAN_QTY,
		         SHORTAGE_QTY SHORTAGE_QTY,
		         EXCESS_QTY EXCESS_QTY
		  FROM #TMPSTKREC 
          WHERE ( ISNULL(STOCK_RECO_QUANTITY_IN_STOCK,0)<>0 OR  ISNULL(SCAN_QTY,0)<>0 OR ISNULL(SHORTAGE_QTY,0)<>0 OR ISNULL(EXCESS_QTY,0)<>0)
		   
		   print '** now Proces  of  Bin Transfer fo shortage Qty '
		   
		   
		   select @cPhysicalStock=ISNULL(@cPhysicalStock+',','')+ cast(SUM(A.SCAN_QTY ) as varchar(100)) +' '+B.UOM +' '+
					    cast(COUNT (DISTINCT CASE WHEN SCAN_QTY >0 THEN  A.PRODUCT_CODE ELSE NULL END ) as varchar(100))+' THANN',
					    
				  @cshortageStock=ISNULL(@cshortageStock+',','')+ cast(SUM(A.SHORTAGE_QTY  ) as varchar(100)) +' '+B.UOM +' '+
					    cast(COUNT (DISTINCT CASE WHEN SHORTAGE_QTY >0 THEN  A.PRODUCT_CODE ELSE NULL END ) as varchar(100))+' THANN'	,
					    
				 @CEXCESSSTOCK=ISNULL(@CEXCESSSTOCK+',','')+ cast(SUM(A.EXCESS_QTY   ) as varchar(100)) +' '+B.UOM +' '+
					    cast(COUNT (DISTINCT CASE WHEN EXCESS_QTY >0 THEN  A.PRODUCT_CODE ELSE NULL END ) as varchar(100))+' THANN'	
					    	       
		   from #TMPSTKREC A
		   JOIN sku_names B (NOLOCK) ON A.product_code =B.product_Code 
		   GROUP BY B.UOM
		   order  by B.UOM desc
		   
		   
		   UPDATE A SET PhysicalStock =@cPhysicalStock,
		                shortageStock =@cshortageStock,
		                excessStock =@CEXCESSSTOCK,
		                user_code=@USER_CODE
		   FROM STMH01106 A (NOLOCK) WHERE MEMO_ID =@MEMO_ID


      IF @NSTOPMODE=1
         GOTO END_PROC
         
         print ' STOP & SETTLED @NSTOPMODE 2 THEN AUTOMATIC SETTLED OF RECONCILE BARCODE : THROUGH (UNC AND BIN TRANSFER) '

		  if exists (select top 1 'U' from #TMPSTKREC where SHORTAGE_QTY>0)
		  begin
		   
			 set @NSTEP=20

			 SET @CMEMONOPREFIX = @DEPT_ID
             SET @NMEMONOLEN=6+LEN(@CMEMONOPREFIX)

		    SET @NSAVETRANLOOP=0  
			WHILE @NSAVETRANLOOP=0  
			BEGIN  
			
			
				 SET @NSTEP=30  
				 EXEC GETNEXTKEY 'FLOOR_ST_MST', 'MEMO_NO', @NMEMONOLEN, @CMEMONOPREFIX, 1,  
					 @CFINYEAR,0, @CMEMONOVAL OUTPUT     
			       
				 PRINT @CMEMONOVAL  
	
				
				 IF EXISTS ( SELECT memo_no  FROM FLOOR_ST_MST  WITH (NOLOCK)  WHERE memo_no=@CMEMONOVAL  AND FIN_YEAR = @CFINYEAR )  
					 SET @NSAVETRANLOOP=0  
				  ELSE  
					SET @NSAVETRANLOOP=1  
			
			END  
			
		  
			IF @CMEMONOVAL IS NULL  OR @CMEMONOVAL LIKE '%LATER%'
			BEGIN 
			   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING SHORTAGE NEXT MEMO NO....'   
			   GOTO END_PROC      
			END  
		  
			PRINT 'GENERATING NEW KEY... floor st mst START'     
		  
			SET @NSTEP = 40  
			
		  
			-- GENERATING NEW Memo ID  
			SET @CKEYFIELDVAL1 = @DEPT_ID + @CFINYEAR+REPLICATE('0', (22-LEN(@DEPT_ID + @CFINYEAR))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))

			IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'    
			BEGIN  
			   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING SHORTAGE NEXT MEMO ID....'  
			   GOTO END_PROC  
			END  
			
			


				SET @NSTEP = 50  

			   INSERT FLOOR_ST_MST	( location_Code , BIN_ID, CANCELLED, FIN_YEAR, MEMO_DT, MEMO_ID, MEMO_NO, RECEIPT_DT, REMARKS, TARGET_BIN_ID, 
			                           USER_CODE,RECON_ID,LAST_UPDATE,total_quantity  ) 
			                            
			   SELECT @DEPT_ID as location_Code, '000'	 BIN_ID,0 CANCELLED,@CFINYEAR FIN_YEAR,CONVERT(VARCHAR(10),@C_DATE,121) MEMO_DT,@CKEYFIELDVAL1 MEMO_ID,
			          @CMEMONOVAL MEMO_NO,CONVERT(VARCHAR(10),@C_DATE,121) 
					  RECEIPT_DT,'AUTO SETTELEMENT FROM STOCK RECONCILATION ' REMARKS,'000' TARGET_BIN_ID,@USER_CODE USER_CODE ,@MEMO_ID as RECON_ID,
					  '' as LAST_UPDATE,
		              (select SUM(SHORTAGE_QTY)  FROM #TMPSTKREC WHERE SHORTAGE_QTY>0) as total_quantity
				SET @NSTEP = 60
				
				

				INSERT FLOOR_ST_DET	( BOX_NO, FCO_MRP, ITEM_TARGET_BIN_ID, LAST_UPDATE, MEMO_ID, PRODUCT_CODE, QUANTITY, ROW_ID, SOURCE_BIN_ID )  
				SELECT 	1  BOX_NO,mrp FCO_MRP,'777' ITEM_TARGET_BIN_ID,GETDATE() LAST_UPDATE,@CKEYFIELDVAL1 MEMO_ID, PRODUCT_CODE,SHORTAGE_QTY QUANTITY,
				       NEWID() ROW_ID,BIN_ID  SOURCE_BIN_ID 
				FROM #TMPSTKREC WHERE SHORTAGE_QTY>0
				
				
				SELECT b.location_code AS DEPT_ID, A.PRODUCT_CODE ,A.ITEM_TARGET_BIN_ID bin_id ,SUM(A.QUANTITY ) AS STOCK_IN_QTY
				into #tmpstockin
				FROM FLOOR_ST_DET A (NOLOCK)
				JOIN floor_st_mst b (NOLOCK) ON a.MEMO_ID=b.MEMO_ID
				WHERE A.MEMO_ID =@CKEYFIELDVAL1
				GROUP BY b.location_code ,A.PRODUCT_CODE ,A.ITEM_TARGET_BIN_ID
				
				INSERT pmt01106	( BIN_ID, DEPT_ID, last_update, product_code, quantity_in_stock )  
				 SELECT 	  a.BIN_ID, a.DEPT_ID,GETDATE() last_update, a.product_code,a.STOCK_IN_QTY quantity_in_stock
				 FROM #tmpstockin a
				 left join pmt01106 b (nolock) on a.PRODUCT_CODE =b.product_code and a.DEPT_ID =b.DEPT_ID and a.bin_id =b.BIN_ID 
				 where b.product_code is null
                 
                 Update a set quantity_in_stock =b.STOCK_IN_QTY 
				 FROM pmt01106 a
				 join #tmpstockin b (nolock) on a.PRODUCT_CODE =b.product_code and a.DEPT_ID =b.DEPT_ID and a.bin_id =b.BIN_ID 
				 where quantity_in_stock <>b.STOCK_IN_QTY 
			
               SET @CSHORTAGEMEMOID=@CKEYFIELDVAL1
               
               print 'shortage memo'+@CSHORTAGEMEMOID
               
               

		   end


		   


		   print '** now Proces  of  uncancellation fo excess Qty '
		   
		  if exists (select top 1 'U' from #TMPSTKREC where EXCESS_QTY>0)
		  begin
		  
			  set @NSTEP=110

			 SET @CMEMONOPREFIX = @DEPT_ID+'U-'
             SET @NMEMONOLEN=6+LEN(@CMEMONOPREFIX)
             
           

		    SET @NSAVETRANLOOP=0  
			WHILE @NSAVETRANLOOP=0  
			BEGIN  
				 SET @NSTEP=120  
				 EXEC GETNEXTKEY 'Icm01106', 'CNC_MEMO_NO', @NMEMONOLEN, @CMEMONOPREFIX, 1,  
					 @CFINYEAR,0, @CMEMONOVAL OUTPUT     
			       
				 PRINT @CMEMONOVAL  
			       
				 IF EXISTS ( SELECT CNC_MEMO_NO  FROM Icm01106  WITH (NOLOCK)  WHERE CNC_MEMO_NO=@CMEMONOVAL  AND FIN_YEAR = @CFINYEAR )  
					 SET @NSAVETRANLOOP=0  
				  ELSE  
					SET @NSAVETRANLOOP=1  
			
			END  
		  
			IF @CMEMONOVAL IS NULL  OR @CMEMONOVAL LIKE '%LATER%'
			BEGIN 
			   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING EXCESS NEXT MEMO NO....'   
			   GOTO END_PROC      
			END  
		  
			PRINT 'GENERATING NEW KEY... START'     
		  
			SET @NSTEP = 130  
			
		  
			-- GENERATING NEW Memo ID  
			SET @CKEYFIELDVAL1 = @DEPT_ID + @CFINYEAR+REPLICATE('0', (22-LEN(@DEPT_ID + @CFINYEAR))-LEN(LTRIM(RTRIM(@CMEMONOVAL))))  + LTRIM(RTRIM(@CMEMONOVAL))
			IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'    
			BEGIN  
			   SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING EXCESS NEXT MEMO ID....'  
			   GOTO END_PROC  
			END  



               SET @NSTEP = 140  
               
			   INSERT icm01106	( location_Code , BIN_ID, cancelled, cnc_dt, cnc_memo_dt, cnc_memo_id, cnc_memo_no, cnc_time, cnc_type, dept_id, edt_user_code, fin_year,  RECON_DT, recon_id,
			                       REMARKS, user_code, xn_item_type,last_update,total_quantity,total_amount ,Approved  )  

			   SELECT @DEPT_ID as location_Code, 	 '000'  BIN_ID,0 cancelled,CONVERT(VARCHAR(10),@C_DATE,121) cnc_dt,CONVERT(VARCHAR(10),@C_DATE,121) cnc_memo_dt, 
			             @CKEYFIELDVAL1 cnc_memo_id,@CMEMONOVAL cnc_memo_no,@C_DATE cnc_time,2 cnc_type,@DEPT_ID dept_id,@USER_CODE edt_user_code,@CFINYEAR fin_year,  
						 @C_DATE RECON_DT,@MEMO_ID recon_id,'AUTO SETTELEMENT FROM STOCK RECONCILATION '  REMARKS,@USER_CODE user_code,1 xn_item_type,
						 '' as last_update,SUM(EXCESS_QTY) total_quantity,SUM(EXCESS_QTY*mrp ) as total_amount,1 as Approved

                FROM #TMPSTKREC where EXCESS_QTY>0


				 INSERT icd01106	(BIN_ID, cnc_memo_id, cnc_memo_no, dept_id, fin_year, last_update, product_code, quantity, rate, row_id ) 
				 SELECT  BIN_ID,@CKEYFIELDVAL1 cnc_memo_id,@CMEMONOVAL cnc_memo_no,@DEPT_ID dept_id,@CFINYEAR fin_year,'' last_update, 
				        product_code,EXCESS_QTY quantity,mrp rate,NEWID() row_id
				 FROM #TMPSTKREC where EXCESS_QTY>0

			    SET @CEXCESSMEMOID=@CKEYFIELDVAL1
			    
			    print 'shortage memo'+@CEXCESSMEMOID

		   END
		   
	
		   IF @CEXCESSMEMOID<>''
		     UPDATE A SET LAST_UPDATE =GETDATE(),HO_SYNCH_LAST_UPDATE ='' FROM icm01106 a (NOLOCK) WHERE A.cnc_memo_id =@CEXCESSMEMOID
		  
		   IF @CSHORTAGEMEMOID<>''
		     UPDATE A SET LAST_UPDATE =GETDATE(),HO_SYNCH_LAST_UPDATE ='' FROM FLOOR_ST_MST  a (NOLOCK) WHERE A.MEMO_ID  =@CSHORTAGEMEMOID
	
   
 END TRY
	BEGIN CATCH
		SET @CERRORMSG = ' SP_STOCK_RECON_HIST STEP- ' + LTRIM(rtrim(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
		GOTO END_PROC
	END CATCH
	
END_PROC:

select @CERRORMSG



END
--END OF PROCEDURE - SP_STOCK_RECON_HIST
