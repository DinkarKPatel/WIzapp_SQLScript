
create PROCEDURE SP3S_INSUPDATE_ITEM_STATUS
(
 @cxn_type varchar(10)='',
 @cmemo_id varchar(50)='',
 @NMODE INT=0
)
as
begin
       
	   IF @CXN_TYPE='PSHBD'
	   BEGIN

	       DELETE A FROM ITEM_STATUS A (NOLOCK)
           LEFT JOIN HOLD_BACK_DELIVER_DET (NOLOCK) B ON A.HBD_MEMO_ID=B.MEMO_ID AND A.HBD_ROW_ID=B.ROW_ID 
           WHERE A.HBD_MEMO_ID=@CMEMO_ID AND B.ROW_ID IS NULL
           

		    if object_id('tempdb..#tmphbd','u') is not null 
			  drop table ..#tmphbd

		    SELECT D.CM_ID ,C.ROW_ID  AS REF_CMD_ROW_ID,A.MEMO_ID AS HBD_MEMO_ID,B.ROW_ID AS HBD_ROW_ID,
					  B.PRODUCT_CODE,B.QUANTITY  AS HOLD_QTY,
					  B.DELIVERED,
					  B.DELIVERY_DT,isnull(C.EMP_CODE,a.hbd_emp_code) as EMP_CODE,C.EMP_CODE1,C.EMP_CODE2,B.REMARKS  ITEM_REMARKS,C.MRP,
					  '' AS  ISSUE_ID,
					  B.JOB_CODE AS JOB_CODE,
					  0  AS ISSUE_QTY,
					  '' ISSUE_DUE_DT,
					  '' AS  RECEIPT_ID,
					  0  AS REC_QTY,
					  b.JOB_RATE JOB_RATE,(b.JOB_RATE*b.quantity) AMOUNT,
					  '' AS DEL_MEMO_ID,b.Additional_job,b.HBD_STATUS
			    into #tmphbd
			   FROM HOLD_BACK_DELIVER_MST A (NOLOCK)
			   JOIN HOLD_BACK_DELIVER_DET B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID 
			   LEFT JOIN CMD01106 C (NOLOCK) ON B.REF_CMD_ROW_ID =C.ROW_ID 
			   LEFT JOIN CMM01106 D (NOLOCK) ON D.CM_ID =C.CM_ID 
			  -- LEFT OUTER JOIN ITEM_STATUS ST ON ST.HBD_ROW_ID=B.ROW_ID 
			   WHERE A.CANCELLED =0 and A.MEMO_ID=@cmemo_id 
			   --AND ST.HBD_ROW_ID IS NULL

			   UPDATE A SET DELIVERY_DT=b.DELIVERY_DT,ITEM_REMARKS=B.ITEM_REMARKS,DELIVERED=b.DELIVERED,
					  JOB_CODE=B.JOB_CODE,JOB_RATE =b.JOB_RATE ,AMOUNT =b.AMOUNT,
					  Additional_job=b.Additional_job,HBD_STATUS=b.HBD_STATUS
			   FROM ITEM_STATUS A WITH(ROWLOCK)
			   JOIN #TMPHBD B ON A.HBD_ROW_ID =B.HBD_ROW_ID AND A.HBD_MEMO_ID =B.HBD_MEMO_ID 
		
	   
			INSERT INTO ITEM_STATUS(CM_ID,REF_CMD_ROW_ID,HBD_MEMO_ID,HBD_ROW_ID, PRODUCT_CODE,HOLD_QTY,DELIVERED,
										DELIVERY_DT,EMP_CODE,EMP_CODE1,EMP_CODE2,ITEM_REMARKS,MRP,
										ISSUE_ID,JOB_CODE,ISSUE_QTY,ISSUE_DUE_DT,
										RECEIPT_ID, REC_QTY,JOB_RATE,AMOUNT,
										DELIVER_MEMO_ID,Additional_job,HBD_STATUS)
			SELECT b.CM_ID,b.REF_CMD_ROW_ID,b.HBD_MEMO_ID,b.HBD_ROW_ID, b.PRODUCT_CODE,b.HOLD_QTY,b.DELIVERED,
										b.DELIVERY_DT,b.EMP_CODE,b.EMP_CODE1,b.EMP_CODE2,b.ITEM_REMARKS,b.MRP,
										b.ISSUE_ID,b.JOB_CODE,b.ISSUE_QTY,b.ISSUE_DUE_DT,
										b.RECEIPT_ID, b.REC_QTY,b.JOB_RATE,b.AMOUNT,
										b.DEL_MEMO_ID AS DELIVER_MEMO_ID,
										b.Additional_job,b.HBD_STATUS
			FROM #TMPHBD B
			LEFT OUTER JOIN ITEM_STATUS ST ON ST.HBD_ROW_ID=B.HBD_ROW_ID 
			WHERE ST.HBD_ROW_ID IS NULL
 
				

		 END
		 ELSE IF @CXN_TYPE='PSJWI'
		 BEGIN
		     

			 IF @NMODE=1
			 BEGIN
			      

				   UPDATE A SET 
					 ISSUE_ID=  ISNULL(B.ISSUE_ID,'') ,
					JOB_CODE=ISNULL(B.JOB_CODE,'') ,
					ISSUE_QTY= ISNULL(B.QUANTITY,0)  ,
					ISSUE_DUE_DT= B.ISSUE_DUE_DT,
					RECEIPT_ID='' ,
		            REC_QTY=0  ,
		           job_rate= 0,
				   AMOUNT=0
				  FROM ITEM_STATUS A
				  JOIN
				  (

					 SELECT B.REF_HBD_ROW_ID ,C.ISSUE_ID ,C.ISSUE_DT  ,B.JOB_CODE ,B.DUE_DT AS ISSUE_DUE_DT,
							SUM(B.QUANTITY  ) AS QUANTITY
					 FROM   POST_SALES_JOBWORK_ISSUE_DET  B
					 JOIN POST_SALES_JOBWORK_ISSUE_MST C (NOLOCK) ON C.ISSUE_ID =B.ISSUE_ID 
					 WHERE ISNULL(C.CANCELLED,0)=0
					 AND   B.ISSUE_ID =@CMEMO_ID
					 GROUP BY B.REF_HBD_ROW_ID ,C.ISSUE_ID ,C.ISSUE_DT  ,B.JOB_CODE ,B.DUE_DT 
                 ) B ON A.HBD_ROW_ID=B.REF_HBD_ROW_ID 

			 END
			 else
			 begin

				 IF OBJECT_ID ('TEMPDB..#TMPISSUE','U') IS NOT NULL
					DROP TABLE #TMPISSUE

				 SELECT distinct  REF_HBD_ROW_ID 
				 INTO #TMPISSUE
				 FROM POST_SALES_JOBWORK_ISSUE_DET A (NOLOCK)
				 JOIN POST_SALES_JOBWORK_ISSUE_MST B (NOLOCK) ON A.issue_id =B.issue_id 
				 WHERE A.ISSUE_ID =@CMEMO_ID 
				 AND B.cancelled=0

			 
				SELECT A.* ,
				 SR=ROW_NUMBER () OVER (PARTITION BY a.REF_HBD_ROW_ID ORDER BY ISSUE_DT DESC,ISSUE_ID DESC)
				INTO #TMPISSUEUPD
				FROM
				(
					 SELECT A.REF_HBD_ROW_ID ,B.ISSUE_ID,B.ISSUE_DT ,
							C.RECEIPT_ID,
							C.JOB_RATE,  
							A.job_code ,
							a.due_dt as ISSUE_DUE_DT,
							SUM(A.QUANTITY ) AS ISSUE_QTY,
							SUM(C.REC_QTY) AS REC_QTY,
						    SUM(CONVERT(NUMERIC(10,2),(C.JOB_RATE*C.REC_QTY))) AS AMOUNT
					 FROM #TMPISSUE tmp
					 LEFT JOIN POST_SALES_JOBWORK_ISSUE_DET A (NOLOCK) ON A.REF_HBD_ROW_ID =TMP.REF_HBD_ROW_ID 
					 LEFT JOIN POST_SALES_JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID=B.ISSUE_ID and B.CANCELLED=0
					 LEFT JOIN
					 (
					   SELECT A.REF_ROW_ID ,B.RECEIPT_ID  ,
							  A.QUANTITY REC_QTY,
							  A.JOB_RATE 
					   FROM POST_SALES_JOBWORK_RECEIPT_DET A (NOLOCK) 
					   JOIN POST_SALES_JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID =B.RECEIPT_ID 
					   WHERE B.CANCELLED =0

					 ) C ON A.ROW_ID =C.REF_ROW_ID
					 GROUP BY A.REF_HBD_ROW_ID ,B.ISSUE_ID,B.ISSUE_DT ,
							C.RECEIPT_ID,C.JOB_RATE,A.job_code,a.due_dt
				
			  
				 ) A 
         

			 DELETE FROM #TMPISSUEUPD WHERE SR>1

				 UPDATE A SET 
				   ISSUE_ID=  ISNULL(B.ISSUE_ID,'') ,
					JOB_CODE=ISNULL(B.JOB_CODE,'') ,
					ISSUE_QTY= ISNULL(B.ISSUE_QTY,0)  ,
					ISSUE_DUE_DT= B.ISSUE_DUE_DT,
					RECEIPT_ID=ISNULL(B.RECEIPT_ID ,'') ,
		            REC_QTY=ISNULL(B.REC_QTY,0)  ,
		           job_rate= B.job_rate,
				   AMOUNT=B.AMOUNT
				 FROM ITEM_STATUS A
				 LEFT JOIN #TMPISSUEUPD b  on  A.HBD_ROW_ID=B.REF_HBD_ROW_ID 
				 where a.issue_id=@CMEMO_ID	


			 end


		 END
		 ELSE IF @CXN_TYPE='PSJWR'
		 BEGIN
		            
		     IF OBJECT_ID ('TEMPDB..#TMPREC','U') IS NOT NULL
			     DROP TABLE #TMPREC

				 SELECT distinct  REF_HBD_ROW_ID 
				 INTO #TMPREC
				 FROM POST_SALES_JOBWORK_RECEIPT_DET A (NOLOCK)
				 JOIN POST_SALES_JOBWORK_ISSUE_DET B ON A.ref_row_id  =B.row_id 
				 WHERE A.receipt_id  =@CMEMO_ID


				  IF OBJECT_ID ('TEMPDB..#TMPRECUPD','U') IS NOT NULL
			         DROP TABLE #TMPRECUPD
		    
				    SELECT A.* ,
					 SR=ROW_NUMBER () OVER (PARTITION BY a.REF_HBD_ROW_ID ORDER BY ISSUE_DT DESC,ISSUE_ID DESC)
					 into #TMPRECUPD
					 FROM
					(
						 SELECT A.REF_HBD_ROW_ID ,B.ISSUE_ID,B.ISSUE_DT ,
								C.RECEIPT_ID,
								C.JOB_RATE,  
								SUM(C.REC_QTY) AS REC_QTY,
							   SUM(CONVERT(NUMERIC(10,2),(C.JOB_RATE*C.REC_QTY))) AS AMOUNT
						 FROM POST_SALES_JOBWORK_ISSUE_DET A (NOLOCK) 
						 JOIN #TMPREC REC ON A.ref_hbd_row_id  =REC. REF_HBD_ROW_ID
						 JOIN POST_SALES_JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID=B.ISSUE_ID 
						 LEFT JOIN
						 (
						   SELECT A.REF_ROW_ID ,B.RECEIPT_ID  ,
								  A.QUANTITY REC_QTY,
								  A.JOB_RATE 
						   FROM POST_SALES_JOBWORK_RECEIPT_DET A (NOLOCK) 
						   JOIN POST_SALES_JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID =B.RECEIPT_ID 
						   WHERE B.CANCELLED =0

						 ) C ON A.ROW_ID =C.REF_ROW_ID
						 WHERE B.CANCELLED=0 
						 GROUP BY A.REF_HBD_ROW_ID ,B.ISSUE_ID,B.ISSUE_DT ,
								C.RECEIPT_ID,C.JOB_RATE
				
			  
					 ) A

                  DELETE FROM #TMPRECUPD WHERE SR>1

				 UPDATE A SET 
					RECEIPT_ID=ISNULL(B.RECEIPT_ID ,'') ,
		            REC_QTY=ISNULL(B.REC_QTY,0)  ,
		            job_rate= B.job_rate,
				    AMOUNT=B.AMOUNT
				 FROM ITEM_STATUS A
				 JOIN #TMPRECUPD b  on  A.HBD_ROW_ID=B.REF_HBD_ROW_ID 
         



		 END
		 ELSE IF @CXN_TYPE='SLSDLV'
		 BEGIN

		     UPDATE A SET DELIVER_MEMO_ID= CASE WHEN C.CANCELLED=0 THEN C.MEMO_ID ELSE ''  END
			 FROM ITEM_STATUS A
			 JOIN sls_delivery_det B ON A.HBD_ROW_ID=B.ref_hbd_row_id 
			 JOIN sls_delivery_mst C ON B.memo_id =C.memo_id 
			 WHERE C.memo_id =@CMEMO_ID


		 END




   END
