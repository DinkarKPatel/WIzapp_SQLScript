CREATE PROCEDURE [DBO].[SP3S_INV_JOBCARD_ISSUE_1]          
(          
  @IMODE INT ,          
  @CWHERE VARCHAR(MAX)='',      
  @CAGENCYCODE VARCHAR(20)='',      
  @FINYEAR VARCHAR(10)=''  ,    
  @DEPTID VARCHAR(10)='' ,
  @NRETURNMODE INT=0
          
)      
----WITH ENCRYPTION
AS          
          
BEGIN        
 DECLARE @CCMD NVARCHAR(MAX) 

--LBLLOOKUP: 1        
    
  SELECT ISSUE_ID FROM BOM_ISSUE_MST (NOLOCK)    
  WHERE FIN_YEAR=@FINYEAR AND location_code=@CWHERE     
    
  END
