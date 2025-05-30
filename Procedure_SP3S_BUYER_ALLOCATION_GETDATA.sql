create PROCEDURE SP3S_BUYER_ALLOCATION_GETDATA
(
 @NQUERYID INT=0,    
 @CAC_CODE VARCHAR(10)='',    
 @CORDER_ID VARCHAR(50)=''


)
AS
BEGIN

      
	  

IF @NQUERYID=1    
   GOTO LBLBUYER       
ELSE IF @NQUERYID=2    
   GOTO LBLORDER  
ELSE IF @NQUERYID IN(3,4)
   GOTO LBLDQRQDET 
ELSE
   GOTO END_PROC    


    LBLBUYER:    
          
      SELECT A.AC_CODE,AC_NAME     
      FROM BUYER_ORDER_MST  A    
	  JOIN LM01106 B ON A.AC_CODE=B.AC_CODE    
	  WHERE A.CANCELLED =0 and isnull(a.Short_close,0)=0
      GROUP BY A.AC_CODE,AC_NAME    
	  ORDER BY B.AC_NAME 
       
   GOTO END_PROC    
       
   LBLORDER:    
      
	    
		       
      SELECT A.ORDER_ID ,A.REF_NO ,A.ORDER_NO ,A.ORDER_DT    
      FROM BUYER_ORDER_MST  A    
	  JOIN LM01106 B ON A.AC_CODE=B.AC_CODE    
	  WHERE A.CANCELLED =0
	  and isnull(a.Short_close,0)=0
	  AND (@CAC_CODE='' OR A.AC_CODE =@CAC_CODE)
      GROUP BY A.ORDER_ID ,A.REF_NO ,A.ORDER_NO ,A.ORDER_DT    
	  ORDER BY A.ORDER_ID 
       
       
       
   GOTO END_PROC    


   LBLDQRQDET:


          IF OBJECT_ID ('TEMPDB..#TMPMATERIALREQ','U') IS NOT NULL
		     DROP TABLE #TMPMATERIALREQ

		   SELECT BUYER_ORDER_MST.DEPT_ID , BUYER_ORDER_MST.ORDER_NO,BUYER_ORDER_MST.ORDER_DT, BUYER_ORDER_MST.AC_CODE, 
		          OD.ORDER_ID AS REF_ORDER_ID,BUYER_ORDER_MST.REF_NO ,
				  MEMO_ID=CAST('LATER' AS VARCHAR(25)) ,
				--  T1.ARTICLE_CODE,FGART.ARTICLE_NO AS FG_ARTICLE_NO,
				  T.ARTICLE_CODE AS BOM_ARTICLE_CODE  
				  --,T.AVG_QUANTITY ,T.ADD_AVG_QUANTITY ,
				  ,ART.ARTICLE_NO ,ART.ARTICLE_NAME ,UOM.UOM_NAME ,BU.CONVERSION_UOM_NAME ,
				  CAST('LATER'+CAST(NEWID() AS VARCHAR(40)) AS VARCHAR(40)) AS ROW_ID ,
				  SUM(T1.QUANTITY ) AS BO_QTY,
				  CONVERT(NUMERIC(14,3),SUM( CASE WHEN ISNULL(UC.CONVERSION_VALUE,0) =0 THEN ISNULL(t.QUANTITY,0)
				  ELSE (ISNULL(t.QUANTITY,0))/ISNULL(UC.CONVERSION_VALUE,0) END ) ) AS    AvailableQtyinBom ,--
				  Cast(0 as Numeric(10,3)) as Allocate_qty,
				  Cast(0 as Numeric(10,3)) as Quantity,
				  Cast(0 as Numeric(10,3)) as Assignable_qty,
				  art.sub_section_code ,
				  cast('000' as varchar(7)) as bin_id
		    INTO #TMPMATERIALREQ
		    FROM ORD_PLAN_BOM_DET T (NOLOCK)    
			JOIN ORD_PLAN_DET T1 (NOLOCK) ON  T.MEMO_ID=T1.MEMO_ID  AND T.REF_ROW_ID =T1.ROW_ID
			JOIN ORD_PLAN_MST T2 (NOLOCK) ON  T1.MEMO_ID=T2.MEMO_ID  
			JOIN BUYER_ORDER_DET OD (NOLOCK) ON OD.ROW_ID =T1.WOD_ROW_ID
			JOIN BUYER_ORDER_MST  (NOLOCK) ON OD.ORDER_ID =BUYER_ORDER_MST.ORDER_ID
			join article art (nolock) on art.article_code =t.ARTICLE_CODE 
			--join article FGART (nolock) on FGART.article_code =T1.ARTICLE_CODE 
			JOIN UOM  (NOLOCK) ON UOM.UOM_CODE = art.UOM_CODE      
			LEFT OUTER JOIN UOM_CONVERSION UC ON UC.UOM_CODE=UOM.UOM_CODE
		    LEFT OUTER JOIN BOM_UOM BU ON BU.CONVERSION_UOM_CODE=UC.CONVERSION_UOM_CODE
			WHERE BUYER_ORDER_MST.ORDER_ID =@CORDER_ID
			GROUP BY BUYER_ORDER_MST.DEPT_ID , BUYER_ORDER_MST.ORDER_NO,BUYER_ORDER_MST.ORDER_DT,BUYER_ORDER_MST.AC_CODE,OD.ORDER_ID,BUYER_ORDER_MST.REF_NO ,
			 T.ARTICLE_CODE, ART.ARTICLE_NO ,ART.ARTICLE_NAME ,UOM.UOM_NAME ,BU.CONVERSION_UOM_NAME,art.sub_section_code 


			
			if @NQUERYID=4
			begin
			    
				IF OBJECT_ID ('TEMPDB..#TMPSTOCKdlq','U') IS NOT NULL
				    DROP TABLE #TMPSTOCKdlq

				SELECT A.BOM_ARTICLE_CODE ,B.PRODUCT_CODE ,PMT.QUANTITY_IN_STOCK  ,PMT.bo_ORDER_ID as ORDER_ID
			    	INTO #TMPSTOCKdlq
				FROM #TMPMATERIALREQ A
				JOIN SKU B ON A.BOM_ARTICLE_CODE =B.ARTICLE_CODE 
				JOIN PMT01106 PMT (NOLOCK) ON B.PRODUCT_CODE =PMT.PRODUCT_CODE AND A.DEPT_ID =PMT.DEPT_ID 
				WHERE PMT .QUANTITY_IN_STOCK >0 
				AND ISNULL(PMT.BO_ORDER_ID,'') =@CORDER_ID

				UPDATE A SET Allocate_qty=b.QUANTITY_IN_STOCK
				FROM #TMPMATERIALREQ A
				JOIN
				(
				  SELECT BOM_ARTICLE_CODE,
				          SUM( QUANTITY_IN_STOCK ) AS QUANTITY_IN_STOCK
				  FROM #TMPSTOCKdlq
				  GROUP BY BOM_ARTICLE_CODE
				  ) B ON A.BOM_ARTICLE_CODE=B.BOM_ARTICLE_CODE


				SELECT cast(0 as bit) as CHK, sm.section_name,sd.sub_section_name,
				Cast(QUANTITY_IN_STOCK as Numeric(10,3)) as Assignable_qty,
				A.*,
				Req_Qty =Allocate_qty,
				B.DEPT_ID ,B.BIN_ID ,B.PRODUCT_CODE,B.QUANTITY_IN_STOCK  ,NEWID() AS UNQ_ID
				FROM #TMPMATERIALREQ A
				join sectionD sd (nolock) on a.sub_section_code =sd.sub_section_code 
				join sectionm sm (nolock) on sm.section_code =sd.section_code 
				JOIN
				(
				 SELECT A.BO_ORDER_ID AS ORDER_ID,A.PRODUCT_CODE ,A.DEPT_ID ,A.BIN_ID ,B.ARTICLE_CODE ,
						SUM(A.QUANTITY_IN_STOCK) AS QUANTITY_IN_STOCK
				 FROM PMT01106 A (NOLOCK)
				 JOIN SKU B ON A.PRODUCT_CODE =B.PRODUCT_CODE 
				 WHERE  ISNULL(bo_order_id,'')<>''
				 AND A.quantity_in_stock >0
				 GROUP BY A.BO_ORDER_ID ,A.PRODUCT_CODE ,A.DEPT_ID ,A.BIN_ID ,B.ARTICLE_CODE
				) B ON A.REF_ORDER_ID =B.ORDER_ID AND A.BOM_ARTICLE_CODE =B.ARTICLE_CODE
			
				ORDER BY A.ARTICLE_NO 


			end
			ELSE
			BEGIN
			    

				
				IF OBJECT_ID ('TEMPDB..#TMPSTOCK','U') IS NOT NULL
				    DROP TABLE #TMPSTOCK

				SELECT A.BOM_ARTICLE_CODE ,B.PRODUCT_CODE ,PMT.QUANTITY_IN_STOCK  ,PMT.bo_ORDER_ID as ORDER_ID
			    	INTO #TMPSTOCK
				FROM #TMPMATERIALREQ A
				JOIN SKU B ON A.BOM_ARTICLE_CODE =B.ARTICLE_CODE 
				JOIN PMT01106 PMT (NOLOCK) ON B.PRODUCT_CODE =PMT.PRODUCT_CODE AND A.DEPT_ID =PMT.DEPT_ID 
				WHERE PMT .QUANTITY_IN_STOCK >0 
				AND ISNULL(PMT.BO_ORDER_ID,'') IN(@CORDER_ID,'')

	
				UPDATE A SET Assignable_qty=B.QUANTITY_IN_STOCK ,
				            Allocate_qty=b.Allocate_qty
				FROM #TMPMATERIALREQ A
				JOIN
				(
				  SELECT BOM_ARTICLE_CODE,
				          SUM(CASE WHEN ISNULL(ORDER_ID,'')='' THEN QUANTITY_IN_STOCK ELSE 0 END ) AS QUANTITY_IN_STOCK,
						  SUM(CASE WHEN ISNULL(ORDER_ID,'')<>'' THEN QUANTITY_IN_STOCK ELSE 0 END ) AS Allocate_qty
				       
				  FROM #TMPSTOCK
				  GROUP BY BOM_ARTICLE_CODE
				  ) B ON A.BOM_ARTICLE_CODE=B.BOM_ARTICLE_CODE


				 
				 
			SELECT  cast(0 as bit) as CHK, sm.section_name,sd.sub_section_name,TMP.DEPT_ID,TMP.ORDER_NO,TMP.ORDER_DT,TMP.AC_CODE,TMP.REF_ORDER_ID,TMP.REF_NO,
					TMP.MEMO_ID,TMP.BOM_ARTICLE_CODE,TMP.ARTICLE_NO,TMP.ARTICLE_NAME,
					TMP.UOM_NAME,TMP.CONVERSION_UOM_NAME,
					TMP.ROW_ID,TMP.BO_QTY,
					TMP.AvailableQtyinBom,
					TMP.Allocate_qty,
					Req_Qty =isnull(AvailableQtyinBom,0)-isnull(Allocate_qty,0),
					TMP.Assignable_qty AS Assignable_qty ,
					TMP.Quantity ,
					TMP.DEPT_ID ,tmp.bin_id ,A.PRODUCT_CODE,A.QUANTITY_IN_STOCK  ,NEWID() AS UNQ_ID
			FROM #TMPSTOCK A (NOLOCK)
			JOIN #TMPMATERIALREQ TMP (NOLOCK) ON A.BOM_ARTICLE_CODE =TMP.BOM_ARTICLE_CODE 
			join sectionD sd (nolock) on TMP.sub_section_code =sd.sub_section_code 
			join sectionm sm (nolock) on sm.section_code =sd.section_code 
			WHERE isnull(AvailableQtyinBom,0)-isnull(Allocate_qty,0)>0
			AND TMP.Assignable_qty>0
			ORDER BY tmp.ARTICLE_NO 
			

			END
			


   GOTO END_PROC

  
    END_PROC: 

END


