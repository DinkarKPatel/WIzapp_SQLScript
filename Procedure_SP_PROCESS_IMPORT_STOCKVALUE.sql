CREATE PROCEDURE SP_PROCESS_IMPORT_STOCKVALUE
(
 @ctablename varchar(100)=''
)        
AS        
BEGIN        
     
     DECLARE @NSTEP INT,@CERRORMSG varchar(1000),@cCurLocId VARCHAR(5),@cHoLocId VARCHAR(5)
  BEGIN TRY  
       
            PRINT 'DEPT NAME VALIDATION'  
        
		SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='location_id'
		SELECT TOP 1 @cCurLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'
       
        DECLARE @DTSQL NVARCHAR(MAX)
       
         SET @DTSQL= N'UPDATE A SET DEPT_NAME =ISNULL(B.DEPT_NAME,loc.dept_name) ,
                         ARTICLE_CODE=ISNULL(ART.ARTICLE_CODE,''00000000''),
                         SUB_SECTION_CODE=ISNULL(SD.SUB_SECTION_CODE ,''00000000''),
                         SECTION_CODE=ISNULL(SM.section_code ,''00000000''),
                         PARA1_CODE=ISNULL(P1.PARA1_CODE ,''0000000''),
                         PARA2_CODE=ISNULL(P2.PARA2_CODE ,''0000000''),
                         PARA3_CODE=ISNULL(P3.PARA3_CODE ,''0000000''),
                         PARA4_CODE=ISNULL(P4.PARA4_CODE ,''0000000''),
                         PARA5_CODE=ISNULL(P5.PARA5_CODE ,''0000000''),
                         PARA6_CODE=ISNULL(P6.PARA6_CODE ,''0000000'')
                       
            FROM '+@ctablename+' A (NOLOCK)
            LEFT JOIN LOCATION B (NOLOCK) ON A.DEPT_ID =B.DEPT_ID 
            LEFT JOIN ARTICLE ART  (NOLOCK) ON ART.article_no  =ISNULL(A.ARTICLE_NO ,'''')
            LEFT JOIN Sectiond SD (NOLOCK) ON SD.sub_section_name =ISNULL(A.sub_section_name ,'''')
            LEFT JOIN SectionM SM (NOLOCK) ON SM.section_name =ISNULL(A.section_name ,'''')
            LEFT JOIN PARA1 P1 (NOLOCK) ON P1.PARA1_NAME=ISNULL(A.PARA1_NAME ,'''')
            LEFT JOIN PARA2 P2 (NOLOCK) ON P2.PARA2_NAME=ISNULL(A.PARA2_NAME ,'''')
            LEFT JOIN PARA3 P3 (NOLOCK) ON P3.PARA3_NAME=ISNULL(A.PARA3_NAME ,'''')
            LEFT JOIN PARA4 P4 (NOLOCK) ON P4.PARA4_NAME=ISNULL(A.PARA4_NAME ,'''')
            LEFT JOIN PARA5 P5 (NOLOCK) ON P5.PARA5_NAME=ISNULL(A.PARA5_NAME ,'''')
            LEFT JOIN PARA6 P6 (NOLOCK) ON P6.PARA6_NAME=ISNULL(A.PARA6_NAME ,'''')
			JOIN location loc (NOLOCK) ON loc.dept_id='''+@cCurLocId+'''
			'
			PRINT @DTSQL
			EXEC SP_EXECUTESQL @DTSQL
			
            SET @DTSQL= N'SELECT A.* 
            FROM '+@CTABLENAME+' A 
            where isnull(DEPT_NAME,'''')<>'''' '
            PRINT @DTSQL
			EXEC SP_EXECUTESQL @DTSQL
           
           
              

  GOTO END_PROC        
          
 END TRY        
         
 BEGIN CATCH        
  SET @CERRORMSG = 'PROCEDURE SP_PROCESS_IMPORTDATA_SLSTRG : STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()        
  GOTO END_PROC        
 END CATCH        
         
END_PROC:  
if isnull(@CERRORMSG,'')<>''
SELECT @CERRORMSG AS ERRMSG      
        
END        
---END OF PROCEDURE - SP_PROCESS_IMPORTDATA_SLSTRG
