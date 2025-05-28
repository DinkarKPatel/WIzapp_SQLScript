CREATE PROCEDURE SP3S_WWI_VALIDATE_USER   
(  
@USER_NAME  VARCHAR(30),  
@PASSWD  VARCHAR(15)=''  
)  
AS  
BEGIN  
              
            DECLARE @CERRMSG NVARCHAR(MAX)  
              
            IF NOT EXISTS( SELECT TOP 1  'U' FROM USERS WHERE USERNAME=RTRIM(LTRIM (@USER_NAME)))   
            BEGIN  
                SET @CERRMSG='INVALID USERNAME'   
                GOTO END_PROC  
            END  
              
  
             IF NOT EXISTS( SELECT TOP 1  'U' FROM USERS WHERE PASSWD=RTRIM(LTRIM (@PASSWD)) AND USERNAME=RTRIM(LTRIM (@USER_NAME)))   
             BEGIN  
                SET @CERRMSG='INVALID PASSWORD'  
                GOTO END_PROC  
             END  
                
  
                 SELECT A.USER_CODE,USERNAME,PASSWD, A.AC_CODE ,  
                        CONVERT(NUMERIC(10,0),@@SPID) AS SP_ID,  
                        '01119' AS FIN_YEAR ,ISNULL(AC_NAME ,'') AC_NAME,
                        CONVERT(VARCHAR,GETDATE(),103) AS LOGINDATE
                 FROM USERS A
                 LEFT JOIN LM01106 B ON A.AC_CODE=B.AC_CODE
                 
              
                 WHERE USERNAME=RTRIM(LTRIM (@USER_NAME)) AND PASSWD=RTRIM(LTRIM (@PASSWD))  
                 
                 
            
               
                 
END_PROC:  
  
IF ISNULL(@CERRMSG,'')<>''  
SELECT ISNULL(@CERRMSG,'') AS ERRMSG                  
              
               
END
