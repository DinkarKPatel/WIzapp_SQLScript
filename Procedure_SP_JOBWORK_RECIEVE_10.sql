create PROC [DBO].SP_JOBWORK_RECIEVE_10                      
@NQUERYID INT,                        
@CWHERE NVARCHAR(4000)='',          
@NMODE INT=0,  
@BWIP BIT=0,  
@NISSUE_MODE BIT=0,  
@cLocID VARCHAR(5)=''  
AS                        
BEGIN     
 --(dinkar) Replace  left(memoid,2) to Location_code 
  
declare @SHOW_PRODUCT_CODE_IN_PRD varchar(10)
select @SHOW_PRODUCT_CODE_IN_PRD=value  from config where config_option='SHOW_PRODUCT_CODE_IN_PRD'
  SELECT  MST.AGENCY_CODE ,
	        CAST('LATER'+B.ARTICLE_CODE +B.PARA1_CODE +B.PARA2_CODE AS VARCHAR(40)) AS ROW_ID,
	        A.JOB_RATE ,CAST('' AS DATETIME) AS DUE_DT ,B.ARTICLE_CODE ,B.PARA1_CODE ,B.PARA2_CODE ,A.JOB_RATE AS RATE,
			A.JOB_CODE ,SUM(QUANTITY) AS REC_QTY,CAST('' AS VARCHAR(40)) AS SP_ID,CAST('' AS VARCHAR(40)) AS JOBCARD_ID
	       
	FROM JOBWORK_receipt_DET A (nolock)
	JOIN JOBWORK_receipt_mst MST (NOLOCK) ON MST.receipt_id =A.receipt_id 
	JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE 
	WHERE A.receipt_id =@CWHERE AND MST.CANCELLED =0
	and isnull(@SHOW_PRODUCT_CODE_IN_PRD,'')<>'1'
	GROUP BY MST.AGENCY_CODE ,A.JOB_RATE  ,B.ARTICLE_CODE ,B.PARA1_CODE ,B.PARA2_CODE ,A.JOB_RATE ,
			A.JOB_CODE 
 
                
END 
