CREATE PROCEDURE SP_PROCESS_IMPORTDATA_BIN  --(LocId 3 digit change by Sanjay:06-11-2024)
(  
 @CSOURCETABLE VARCHAR(100)=''  
)  
as  
begin  
  
    DECLARE @NSTEP int,@CERRORMSG varchar(1000),@UPDATEVALUE NUMERIC(10,0),  
            @UPDATEVALUE1 NUMERIC(10,0),@UPDATEVALUE2 NUMERIC(10,0),  
            @BLOOP BIT,@DTSQL NVARCHAR(MAX),@CLOCID VARchar(4),@CHODEPT_ID VARCHAR(4)  
              
            SELECT @CLOCID=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID   
     
              
            SELECT @CHODEPT_ID=VALUE  FROM CONFIG WHERE CONFIG_OPTION ='HO_LOCATION_ID'  
               
       
    BEGIN TRANSACTION  
 BEGIN TRY  
       
       IF ISNULL(@CLOCID,'')=''  
   BEGIN  
   SET @CERRORMSG = 'STEP-00  LOCATION ID CAN NOT BE BLANK  '    
   GOTO END_PROC      
   END  
  
        SET @CERRORMSG=''  
        set @NSTEP=00  
         IF @CLOCID<>@CHODEPT_ID  
         BEGIN   
             SET @CERRORMSG='IMPORT BIN MASTER DOES NOT ALLOW NON HO LOCATION'  
          GOTO END_PROC  
           
         END  
          
          
        IF OBJECT_ID ('TEMPDB..#TMPBIN','U') IS NOT NULL  
           DROP TABLE #TMPBIN  
            
            
          SELECT BIN_ID,BIN_NAME,BIN_ALIAS,MBO_COUNTER,BIN_NAME AS MAJOR_BIN_NAME,  
                 MAJOR_BIN_ID  
          INTO #TMPBIN  
          FROM BIN WHERE 1=2  
            
         SET @DTSQL=N' SELECT CAST('''' AS CHAR(7)) AS  BIN_ID,  
                      BIN_NAME,ISNULL(BIN_ALIAS,'''') AS BIN_ALIAS,MBO_COUNTER,  
                      MAJOR_BIN_NAME,  
                      CAST('''' AS CHAR(7)) AS  MAJOR_BIN_ID  
                   FROM '+@CSOURCETABLE+' '   
         INSERT INTO #TMPBIN  
         exec sp_executesql @DTSQL  
           
           
         --DUPLICATE BIN REMOVE  
         ;WITH CTE AS  
         (  
          SELECT * ,SR =ROW_NUMBER () OVER (PARTITION BY BIN_NAME ORDER BY BIN_NAME)  
          FROM #TMPBIN A  
            
         )  
         DELETE FROM CTE  WHERE SR>1  
    
           
         DELETE B   
         FROM #TMPBIN A  
         JOIN BIN B ON RTRIM(LTRIM(A.BIN_NAME)) =RTRIM(LTRIM(B.BIN_NAME))  
         
         SET @NSTEP=10  
       
   SELECT @UPDATEVALUE1 = ISNULL(MAX(CONVERT(NUMERIC,SUBSTRING(LASTKEYVAL,3,LEN(LASTKEYVAL)))),0) FROM           
   KEYS WHERE TABLENAME='BIN' AND COLUMNNAME='BIN_ID' AND ISNULL(LASTKEYVAL,'')<>''         
   AND PATINDEX('%[A-Z]%',SUBSTRING(LASTKEYVAL,3,LEN(LASTKEYVAL)))=0    
   AND LEN(LASTKEYVAL)=7 AND PREFIX =@CLOCID   
        
      set @NSTEP=20  
  
     
         
            
     SELECT @UPDATEVALUE2 = MAX(ISNULL(CONVERT(NUMERIC,SUBSTRING(BIN_ID,3,LEN(LTRIM(RTRIM(BIN_ID))))),0))           
     FROM  BIN WHERE PATINDEX('%[A-Z]%',SUBSTRING(BIN_ID,3,LEN(LTRIM(RTRIM(BIN_ID)))))=0          
     AND LTRIM(RTRIM(ISNULL(BIN_ID,'')))<>''    
     AND   LEN(BIN_ID)=7 and LEFT (BIN_ID,2)=@CLOCID  
  
  
         
     set @NSTEP=30  
    
     IF ISNULL(@UPDATEVALUE1,0)>ISNULL(@UPDATEVALUE2,0)          
   SET @UPDATEVALUE=ISNULL(@UPDATEVALUE1,0)          
     ELSE          
   SET @UPDATEVALUE=ISNULL(@UPDATEVALUE2,0)          
        
     PRINT 'IMPORT BIN-'+STR(@NSTEP)      
       
      set @NSTEP=40  
        
               
     SET @BLOOP=0      
     WHILE @BLOOP=0      
     BEGIN        
   UPDATE #TMPBIN SET BIN_ID = @CLOCID+REPLICATE('0',5-LEN(LTRIM(STR(@UPDATEVALUE))))+LTRIM(STR(@UPDATEVALUE)),          
   @UPDATEVALUE = @UPDATEVALUE + 1          
            
   IF NOT EXISTS (SELECT TOP 1 A.BIN_ID FROM BIN A JOIN #TMPBIN B ON A.BIN_ID=      
      B.BIN_ID)      
        SET @BLOOP=1                 
      END      
       
       
         UPDATE A SET MAJOR_BIN_ID=B.BIN_ID    
         FROM #TMPBIN A  
         JOIN BIN B ON A.MAJOR_BIN_NAME =B.BIN_NAME   
  
   UPDATE A SET MAJOR_BIN_ID=a.BIN_ID    
         FROM #TMPBIN A  
         where BIN_NAME=MAJOR_BIN_NAME  
   and isnull(MAJOR_BIN_ID,'')=''  
    
        
      IF EXISTS (SELECT TOP 1 'U'  FROM #TMPBIN A  
         LEFT JOIN BIN B ON A.MAJOR_BIN_ID =B.BIN_ID          
       WHERE b.BIN_ID IS NULL and isnull(a.bin_id,'') <>isnull(a.major_bin_id,'') )      
       BEGIN  
           SET @CERRORMSG='NEW MAJOR BIN FOUND PLEASE CREATE MAJOR BIN FIRST'  
           GOTO END_PROC  
       END  
              
     SET @NSTEP=50   
                  
     INSERT BIN ( BIN_ID,BIN_NAME,BIN_ALIAS,INACTIVE,LAST_UPDATE,MBO_COUNTER,  
                       MBO_LEDGER_AC_CODE,bill_prefix,address1,address2,area_code,area_covered,  
                       TIN_NO,TAN_NO,PAN_NO,PHONE_NO,online_counter,major_bin_id )          
      
     SELECT RTRIM(LTRIM( BIN_ID)) AS BIN_ID,RTRIM(LTRIM(BIN_NAME)),BIN_ALIAS AS BIN_ALIAS,  
            0 AS INACTIVE,GETDATE() AS LAST_UPDATE,MBO_COUNTER,  
                       '0000000000' AS MBO_LEDGER_AC_CODE,'' AS bill_prefix, '' AS address1,  
                       '' AS address2,'' AS area_code,0 AS area_covered,  
                       '' AS TIN_NO,'' AS TAN_NO,'' AS PAN_NO,'' AS PHONE_NO,0 AS online_counter,  
                       major_bin_id      
     FROM #TMPBIN WHERE BIN_ID<>''         
         
         
     SET @NSTEP=60    
                    
     IF  EXISTS (SELECT LASTKEYVAL FROM KEYS WHERE TABLENAME='BIN' AND PREFIX =@CLOCID)           
   UPDATE KEYS SET LASTKEYVAL = @CLOCID+REPLICATE('0',7-LEN(LTRIM(STR(@UPDATEVALUE))))+LTRIM(STR(@UPDATEVALUE))          
   WHERE TABLENAME='BIN'  AND @UPDATEVALUE<>0 AND PREFIX =@CLOCID          
     ELSE          
   INSERT KEYS (TABLENAME,LASTKEYVAL,COLUMNNAME,PREFIX,FINYEAR)          
   VALUES  ('BIN',@CLOCID+REPLICATE('0',7-LEN(LTRIM(STR(@UPDATEVALUE))))+LTRIM(STR(@UPDATEVALUE)),          
   'BIN_ID',@CLOCID ,'01120')      
     
     
        
             
END TRY  
 BEGIN CATCH  
  SET @CERRORMSG = 'PROCEDURE sp_process_importdata_BIN: STEP- ' + LTRIM(STR(@NSTEP,10)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()  
  GOTO END_PROC  
 END CATCH  
   
END_PROC:  
  
 IF @@TRANCOUNT>0   
 BEGIN  
  IF ISNULL(@CERRORMSG,'')=''   
  BEGIN  
   commit  TRANSACTION  
  END   
  ELSE  
   ROLLBACK  
 END  
   
 SELECT @CERRORMSG AS message  
  
END  
  
  