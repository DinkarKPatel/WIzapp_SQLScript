create PROC [DBO].SP_JOBWORK_RECIEVE_5  
@NQUERYID INT,                        
@CWHERE NVARCHAR(4000)='',          
@NMODE INT=0,  
@BWIP BIT=0,  
@NISSUE_MODE BIT=0,  
@cLocID VARCHAR(5)=''  
AS                        
BEGIN     
 
 SELECT * FROM JOBWORK_RECEIPT_MST(NOLOCK) A                        
 JOIN JOBWORK_RECEIPT_DET(NOLOCK) B ON A.RECEIPT_ID=B.RECEIPT_ID                        
 JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=B.PRODUCT_CODE          
 JOIN ARTICLE ART (NOLOCK) ON SKU.ARTICLE_CODE = ART.ARTICLE_CODE              
 JOIN SECTIOND SD (NOLOCK) ON ART.SUB_SECTION_CODE = SD.SUB_SECTION_CODE            
 JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE            
 JOIN PARA1 P1 (NOLOCK) ON SKU.PARA1_CODE = P1.PARA1_CODE              
 JOIN PARA2 P2 (NOLOCK) ON SKU.PARA2_CODE = P2.PARA2_CODE              
 JOIN PARA3 P3 (NOLOCK)ON SKU.PARA3_CODE = P3.PARA3_CODE              
 JOIN PARA4 P4 (NOLOCK)ON SKU.PARA4_CODE = P4.PARA4_CODE              
 JOIN PARA5 P5 (NOLOCK)ON SKU.PARA5_CODE = P5.PARA5_CODE              
 JOIN PARA6 P6 (NOLOCK)ON SKU.PARA6_CODE = P6.PARA6_CODE              
 JOIN UOM E (NOLOCK)ON ART.UOM_CODE = E.UOM_CODE           
 JOIN JOBS (NOLOCK) D ON D.JOB_CODE=A.JOB_CODE                        
 WHERE A.RECEIPT_ID=@CWHERE      
END 
