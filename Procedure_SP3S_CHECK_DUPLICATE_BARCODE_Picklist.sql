CREATE Procedure SP3S_CHECK_DUPLICATE_BARCODE_Picklist--(LocId 3 digit change only increased the parameter width by Sanjay:04-11-2024)
(
    @csp_id varchar(50)='',
	@CUSERCODE varchar(10)='',
	@cdept_id varchar(4)='',
	@nmode numeric(1,0)=1,
	@BMULTIPLEMRP bit Output 

)
as
begin

      

	  SELECT A.MEMO_ID PICK_LIST_ID ,A.ORD_ROW_ID AS BO_DET_ROW_ID,PMT.PRODUCT_CODE  ,
	        PMT.BO_ORDER_ID,PMT.DEPT_ID,PMT.BIN_ID,PMT.BO_ORDER_ID AS ORDER_ID,
	        pmt.quantity_in_stock,a.ROW_ID as pick_list_row_id
	       INTO #TMPPMT01106
	  FROM PLD01106 A (NOLOCK)
	  JOIN PLM01106 B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID
	  JOIN WSL_ORDER_ID C ON A.MEMO_ID =C.ORDER_ID 
	  JOIN PMT01106 PMT (NOLOCK) ON A.PLD_PRODUCT_CODE=PMT.PRODUCT_CODE AND A.MEMO_ID =PMT.PICK_LIST_ID
	  WHERE C.SP_ID =@CSP_ID AND QUANTITY_IN_STOCK >0 AND ISNULL( C.ORDER_ID,'')<>''


    	
IF @nmode=1
   GOTO lblBarcodeDuplicate --(user Import only Barcode )
Else IF @nmode=2 
   GOTO lblBarcodeMrpDuplicate--(user Import only Barcode,mrp )
Else IF @nmode=3 
   GOTO lblBarcodebinDuplicate--(user Import only Barcode,bin )
Else IF @nmode=4 
   GOTO lblBarcodemrpbinDuplicate--(user Import  Barcode,bin,mrp )



   lblBarcodeDuplicate:
          
		    INSERT INTO #TMPMULTIPLEMRP(PRODUCT_CODE,BATCH_BARCODE,MRP,BIN_ID,SRNO,quantity_in_stock,pick_list_id,order_id,bo_det_row_id,pick_list_row_id)

			 SELECT A.PRODUCT_CODE,b.PRODUCT_CODE as BATCH_BARCODE ,D.MRP,B.BIN_ID,
					 SR=dense_rank() OVER(partition  by a.PRODUCT_CODE ORDER BY A.PRODUCT_CODE,d.mrp,b.bin_id),
					 b.quantity_in_stock,
					 b.pick_list_id,b.bo_order_id,b.bo_det_row_id,b.pick_list_row_id
			 FROM WSL_ITEM_DETAILS A (NOLOCK)
			 JOIN #TMPPMT01106 B (NOLOCK) ON A.PRODUCT_CODE=LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE )))
			 JOIN SKU D (NOLOCK) ON D.PRODUCT_CODE=B.PRODUCT_CODE	
			 JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID
			 JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@CUSERCODE
			 WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND B.QUANTITY_IN_STOCK >0  AND B.DEPT_ID= @CDEPT_ID
			 AND CHARINDEX('@',A.PRODUCT_CODE)=0 AND B.BIN_ID<>'999' and isnull(b.pick_list_id,'')<>''

		

			 IF EXISTS (SELECT TOP 1'U' FROM WSL_ITEM_DETAILS A (NOLOCK)  WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND CHARINDEX('@',A.PRODUCT_CODE)>0)
			 BEGIN
			      INSERT INTO #TMPMULTIPLEMRP(PRODUCT_CODE,BATCH_BARCODE,MRP,BIN_ID,SRNO,quantity_in_stock,pick_list_id,order_id,bo_det_row_id,pick_list_row_id)
				 SELECT A.PRODUCT_CODE,b.PRODUCT_CODE as BATCH_BARCODE ,D.MRP,B.BIN_ID,
						 SR=dense_rank() OVER(partition  by a.PRODUCT_CODE ORDER BY A.PRODUCT_CODE,d.mrp,b.bin_id),
						 b.quantity_in_stock,
						  b.pick_list_id,b.bo_order_id,b.bo_det_row_id,b.pick_list_row_id
				 FROM WSL_ITEM_DETAILS A (NOLOCK)
				 JOIN #TMPPMT01106 B (NOLOCK) ON A.PRODUCT_CODE=b.product_code
				 JOIN SKU D (NOLOCK) ON D.PRODUCT_CODE=B.PRODUCT_CODE	
				 JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID
				 JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@CUSERCODE
				 WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND B.QUANTITY_IN_STOCK >0  AND B.DEPT_ID= @CDEPT_ID
				  AND CHARINDEX('@',A.PRODUCT_CODE)<>0 AND B.BIN_ID<>'999' and isnull(b.pick_list_id,'')<>''

			 END


		    IF EXISTS (SELECT TOP 1 'U' FROM #TMPMULTIPLEMRP WHERE SRNO>1)
			 BEGIN
				  SET @BMULTIPLEMRP=1
				  GOTO END_PROC
			 END

			 UPDATE A SET BIN_ID =B.BIN_ID ,MRP=B.MRP ,QUANTITY_IN_STOCK=B.QUANTITY_IN_STOCK,ORDER_ID =B.ORDER_ID,PRODUCT_CODE=B.BATCH_BARCODE,
			             BO_DET_ROW_ID=B.BO_DET_ROW_ID,pick_list_row_id=b.pick_list_row_id
			 FROM WSL_ITEM_DETAILS A (NOLOCK)
			 JOIN #TMPMULTIPLEMRP B ON A.PRODUCT_CODE=B.PRODUCT_CODE


       
   GOTO END_PROC


    lblBarcodeMrpDuplicate:

	       
		     INSERT INTO #TMPMULTIPLEMRP(PRODUCT_CODE,BATCH_BARCODE,MRP,BIN_ID,SRNO ,quantity_in_stock,pick_list_id,order_id,bo_det_row_id,pick_list_row_id)
			 SELECT A.PRODUCT_CODE,b.PRODUCT_CODE as BATCH_BARCODE ,D.MRP,a.BIN_ID,
					 SR=dense_rank() OVER(PARTITION BY A.PRODUCT_CODE,a.bin_id ORDER BY A.PRODUCT_CODE,a.bin_id,d.mrp),
					 b.quantity_in_stock,
					 b.pick_list_id,b.bo_order_id,b.bo_det_row_id,b.pick_list_row_id
			 FROM WSL_ITEM_DETAILS A (NOLOCK)
			 JOIN #TMPPMT01106 B (NOLOCK) ON A.PRODUCT_CODE=LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE )))
			               and a.BIN_ID=b.BIN_ID
			 JOIN SKU D (NOLOCK) ON D.PRODUCT_CODE=B.PRODUCT_CODE	
			 JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID
			 JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@CUSERCODE
			 WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND B.QUANTITY_IN_STOCK >0  AND B.DEPT_ID= @CDEPT_ID
			 AND CHARINDEX('@',A.PRODUCT_CODE)=0 AND B.BIN_ID<>'999' and isnull(b.pick_list_id,'')<>''



			 IF EXISTS (SELECT TOP 1'U' FROM WSL_ITEM_DETAILS A (NOLOCK)  WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND CHARINDEX('@',A.PRODUCT_CODE)>0)
			 BEGIN
			     
				INSERT INTO #TMPMULTIPLEMRP(PRODUCT_CODE,BATCH_BARCODE,MRP,BIN_ID,SRNO,quantity_in_stock,pick_list_id,order_id,pick_list_row_id)
				 SELECT A.PRODUCT_CODE,b.PRODUCT_CODE as BATCH_BARCODE ,D.MRP,a.BIN_ID,
						 SR=dense_rank() OVER(PARTITION BY A.PRODUCT_CODE,a.bin_id ORDER BY A.PRODUCT_CODE,a.bin_id,d.mrp),
						 b.quantity_in_stock,
						 b.pick_list_id,b.bo_order_id,pick_list_row_id
				 FROM WSL_ITEM_DETAILS A (NOLOCK)
				 JOIN #TMPPMT01106 B (NOLOCK) ON A.PRODUCT_CODE=b.product_code
							   and a.BIN_ID=b.BIN_ID
				 JOIN SKU D (NOLOCK) ON D.PRODUCT_CODE=B.PRODUCT_CODE	
				 JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID
				 JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@CUSERCODE
				 WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND B.QUANTITY_IN_STOCK >0  AND B.DEPT_ID= @CDEPT_ID
				 AND CHARINDEX('@',A.PRODUCT_CODE)<>0 AND B.BIN_ID<>'999' and isnull(b.pick_list_id,'')<>''


			 END

		    IF EXISTS (SELECT TOP 1 'U' FROM #TMPMULTIPLEMRP WHERE SRNO>1)
			 BEGIN
				  SET @BMULTIPLEMRP=1
				  GOTO END_PROC
			 END

			 Update a set mrp=b.MRP ,QUANTITY_IN_STOCK=b.quantity_in_stock,ORDER_ID =b.ORDER_ID,PRODUCT_CODE=b.BATCH_BARCODE,bo_det_row_id=b.bo_det_row_id,
			              pick_list_row_id=b.pick_list_row_id
			 from WSL_ITEM_DETAILS a (nolock)
			 join #TMPMULTIPLEMRP b on a.PRODUCT_CODE=b.product_code

			

    GOTO END_PROC


    lblBarcodebinDuplicate:

	         INSERT INTO #TMPMULTIPLEMRP(PRODUCT_CODE,BATCH_BARCODE,MRP,BIN_ID,SRNO,quantity_in_stock,pick_list_id,order_id,bo_det_row_id,pick_list_row_id)
			 SELECT A.PRODUCT_CODE,b.PRODUCT_CODE as BATCH_BARCODE ,D.MRP,a.BIN_ID,
					 SR=dense_rank() OVER(PARTITION BY A.PRODUCT_CODE,a.bin_id ORDER BY a.PRODUCT_CODE,a.bin_id,d.mrp),b.quantity_in_stock,
					 b.pick_list_id,b.bo_order_id,b.bo_det_row_id,b.pick_list_row_id
			 FROM WSL_ITEM_DETAILS A (NOLOCK)
			 JOIN #TMPPMT01106 B (NOLOCK) ON A.PRODUCT_CODE=LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE )))
			 JOIN SKU D (NOLOCK) ON D.PRODUCT_CODE=B.PRODUCT_CODE	and a.mrp =d.mrp
			 JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID
			 JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@CUSERCODE
			 WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND B.QUANTITY_IN_STOCK >0  AND B.DEPT_ID= @CDEPT_ID
			 AND CHARINDEX('@',A.PRODUCT_CODE)=0 AND B.BIN_ID<>'999' and isnull(b.pick_list_id,'')<>''

			 IF EXISTS (SELECT TOP 1'U' FROM WSL_ITEM_DETAILS A (NOLOCK)  WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND CHARINDEX('@',A.PRODUCT_CODE)>0)
			 BEGIN
			     
				INSERT INTO #TMPMULTIPLEMRP(PRODUCT_CODE,BATCH_BARCODE,MRP,BIN_ID,SRNO,quantity_in_stock,pick_list_id,order_id,bo_det_row_id,pick_list_row_id)
				 SELECT A.PRODUCT_CODE,b.PRODUCT_CODE as BATCH_BARCODE ,D.MRP,a.BIN_ID,
						 SR=dense_rank() OVER(PARTITION BY A.PRODUCT_CODE,a.bin_id ORDER BY a.PRODUCT_CODE,a.bin_id,d.mrp),b.quantity_in_stock,
						 b.pick_list_id,b.bo_order_id,b.bo_det_row_id,b.pick_list_row_id
				 FROM WSL_ITEM_DETAILS A (NOLOCK)
				 JOIN #TMPPMT01106 B (NOLOCK) ON A.PRODUCT_CODE=b.product_code
				 JOIN SKU D (NOLOCK) ON D.PRODUCT_CODE=B.PRODUCT_CODE	and a.mrp =d.mrp
				 JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID
				 JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@CUSERCODE
				 WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND B.QUANTITY_IN_STOCK >0  AND B.DEPT_ID= @CDEPT_ID
				 AND CHARINDEX('@',A.PRODUCT_CODE)<>0 AND B.BIN_ID<>'999' and isnull(b.pick_list_id,'')<>''

			 END

		    IF EXISTS (SELECT TOP 1 'U' FROM #TMPMULTIPLEMRP WHERE SRNO>1)
			 BEGIN
				  SET @BMULTIPLEMRP=1
				  GOTO END_PROC
			 END

			 Update a set BIN_ID=b.BIN_ID ,QUANTITY_IN_STOCK=b.quantity_in_stock,ORDER_ID =b.ORDER_ID,PRODUCT_CODE=b.BATCH_BARCODE,
			          bo_det_row_id=b.bo_det_row_id,pick_list_row_id=b.pick_list_row_id
			 from WSL_ITEM_DETAILS a (nolock)
			 join #TMPMULTIPLEMRP b on a.PRODUCT_CODE=b.product_code



   GOTO END_PROC


   lblBarcodemrpbinDuplicate:

       
	    INSERT INTO #TMPMULTIPLEMRP(PRODUCT_CODE,BATCH_BARCODE,MRP,BIN_ID,SRNO,quantity_in_stock,pick_list_id,order_id,bo_det_row_id,pick_list_row_id)
			 SELECT A.PRODUCT_CODE,b.PRODUCT_CODE as BATCH_BARCODE ,a.MRP,a.BIN_ID,
					 SR=dense_rank() OVER(PARTITION BY A.PRODUCT_CODE,a.mrp,a.bin_id ORDER BY A.PRODUCT_CODE,a.mrp,a.bin_id),b.quantity_in_stock,
					 b.pick_list_id,b.bo_order_id,b.bo_det_row_id,b.pick_list_row_id
			 FROM WSL_ITEM_DETAILS A (NOLOCK)
			 JOIN #TMPPMT01106 B (NOLOCK) ON A.PRODUCT_CODE=LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE ))) and a.BIN_ID =b.BIN_ID
			 JOIN SKU D (NOLOCK) ON D.PRODUCT_CODE=B.PRODUCT_CODE	and a.mrp =d.mrp
			 JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID
			 JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@CUSERCODE
			 WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND B.QUANTITY_IN_STOCK >0  AND B.DEPT_ID= @CDEPT_ID
			 AND CHARINDEX('@',A.PRODUCT_CODE)=0 AND B.BIN_ID<>'999' and isnull(b.pick_list_id,'')<>''

			 IF EXISTS (SELECT TOP 1'U' FROM WSL_ITEM_DETAILS A (NOLOCK)  WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND CHARINDEX('@',A.PRODUCT_CODE)>0)
			 BEGIN
			     
				INSERT INTO #TMPMULTIPLEMRP(PRODUCT_CODE,BATCH_BARCODE,MRP,BIN_ID,SRNO,quantity_in_stock,pick_list_id,order_id,bo_det_row_id,pick_list_row_id)
				 SELECT A.PRODUCT_CODE,b.PRODUCT_CODE as BATCH_BARCODE ,D.MRP,a.BIN_ID,
						 SR=dense_rank() OVER(PARTITION BY A.PRODUCT_CODE,a.mrp,a.bin_id ORDER BY A.PRODUCT_CODE,a.mrp,a.bin_id),b.quantity_in_stock,
						 b.pick_list_id,b.bo_order_id,b.bo_det_row_id,b.pick_list_row_id
				 FROM WSL_ITEM_DETAILS A (NOLOCK)
				 JOIN #TMPPMT01106 B (NOLOCK) ON A.PRODUCT_CODE=b.product_code and a.BIN_ID =b.BIN_ID
				 JOIN SKU D (NOLOCK) ON D.PRODUCT_CODE=B.PRODUCT_CODE	and a.mrp =d.mrp
				 JOIN BIN  (NOLOCK) ON BIN.BIN_ID=B.BIN_ID
				 JOIN BINUSERS C ON C.BIN_ID=BIN.MAJOR_BIN_ID AND C.USER_CODE =@CUSERCODE
				 WHERE A.SP_ID=RTRIM(LTRIM(@csp_id))  AND B.QUANTITY_IN_STOCK >0  AND B.DEPT_ID= @CDEPT_ID
				 AND CHARINDEX('@',A.PRODUCT_CODE)<>0 AND B.BIN_ID<>'999' and isnull(b.pick_list_id,'')<>''

			 END

		    IF EXISTS (SELECT TOP 1 'U' FROM #TMPMULTIPLEMRP WHERE SRNO>1)
			 BEGIN
				  SET @BMULTIPLEMRP=1
				  GOTO END_PROC
			 END

			 Update a set QUANTITY_IN_STOCK=b.quantity_in_stock,ORDER_ID =b.ORDER_ID,PRODUCT_CODE=b.BATCH_BARCODE,bo_det_row_id=b.bo_det_row_id,
			             pick_list_row_id=b.pick_list_row_id
			 from WSL_ITEM_DETAILS a (nolock)
			 join #TMPMULTIPLEMRP b on a.PRODUCT_CODE=b.product_code


   GOTO END_PROC


   end_proc:


end