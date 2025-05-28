create PROC [DBO].SP_JOBWORK_RECIEVE_3  
@NQUERYID INT,                        
@CWHERE NVARCHAR(4000)='',          
@NMODE INT=0,  
@BWIP BIT=0,  
@NISSUE_MODE BIT=0,  
@cLocID VARCHAR(5)=''  
AS                        
BEGIN     
 --(dinkar) Replace  left(memoid,2) to Location_code 
 SELECT ISSUE_NO,ISSUE_ID FROM JOBWORK_ISSUE_MST WHERE CANCELLED = 0   AND location_Code =@cLocID                      
                   
END 
