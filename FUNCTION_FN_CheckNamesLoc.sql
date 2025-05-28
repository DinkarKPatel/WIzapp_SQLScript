CREATE FUNCTION FN_CheckNamesLoc 
(  @cParaCode varchar(10),  @cParaName varchar(50),  @cTableName varchar(50),  @cParaCode2 VARCHAR(10)  ) RETURNS bit AS BEGIN  DECLARE @lRetVal bit  SET @lRetVal = 1    IF @cTableName = 'SECTIONM' 
BEGIN   IF EXISTS ( SELECT section_code     FROM sectionm   WHERE section_name = @cParaName            AND section_code <> @cParaCode       AND inactive=0     AND LEFT(section_code,2) = LEFT(@cParaCode,2) )    SET @lRetVal = 0  END  ELSE  IF @cTableName = 'SECTIOND' 
BEGIN   IF EXISTS ( SELECT sub_section_code FROM sectiond   WHERE sub_section_name  = @cParaName       AND section_code  = @cParaCode2      AND inactive=0     AND sub_section_code <> @cParaCode      AND LEFT(sub_section_code,2) = LEFT(@cParaCode,2) )    SET @lRetVal = 0  END  ELSE  IF @cTableName = 'ARTICLE'  
BEGIN   IF EXISTS (SELECT article_code      FROM article    WHERE article_no		= @cParaName       AND article_code <> @cParaCode       AND inactive=0     AND LEFT(article_code,2) = LEFT(@cParaCode,2))    SET @lRetVal = 0  END  ELSE  IF @cTableName = 'PARA1'  
BEGIN   IF EXISTS ( SELECT para1_code       FROM para1      WHERE para1_name		= @cParaName       AND para1_code   <> @cParaCode      AND inactive=0      AND LEFT(para1_code,2) = LEFT(@cParaCode,2) )    SET @lRetVal = 0  END  ELSE  IF @cTableName = 'PARA2'  
BEGIN   IF EXISTS ( SELECT para2_code       FROM para2      WHERE para2_name		= @cParaName       AND para2_code   <> @cParaCode      AND inactive=0      AND LEFT(para2_code,2) = LEFT(@cParaCode,2) )    SET @lRetVal = 0  END  ELSE  IF @cTableName = 'PARA3'  
BEGIN   IF EXISTS ( SELECT para3_code       FROM para3      WHERE para3_name		= @cParaName       AND para3_code   <> @cParaCode      AND inactive=0      AND LEFT(para3_code,2) = LEFT(@cParaCode,2) )    SET @lRetVal = 0  END  ELSE  IF @cTableName = 'PARA4'  
BEGIN   IF EXISTS ( SELECT para4_code       FROM para4      WHERE para4_name		= @cParaName       AND para4_code   <> @cParaCode      AND inactive=0      AND LEFT(para4_code,2) = LEFT(@cParaCode,2) )    SET @lRetVal = 0  END  ELSE  IF @cTableName = 'PARA5'  
BEGIN   IF EXISTS ( SELECT para5_code       FROM para5      WHERE para5_name		= @cParaName       AND para5_code   <> @cParaCode      AND inactive=0      AND LEFT(para5_code,2) = LEFT(@cParaCode,2) )    SET @lRetVal = 0  END  ELSE  IF @cTableName = 'PARA6'  
BEGIN   IF EXISTS ( SELECT para6_code       FROM para6      WHERE para6_name		= @cParaName       AND para6_code   <> @cParaCode      AND inactive=0      AND LEFT(para6_code,2) = LEFT(@cParaCode,2) )    SET @lRetVal = 0  END  ELSE  IF @cTableName = 'lm01106'  
BEGIN   IF EXISTS ( SELECT ac_code          FROM lm01106    WHERE ac_name			= @cParaName       AND ac_code      <> @cParaCode      AND LEFT(ac_code,2) = LEFT(@cParaCode,2) )   
 SET @lRetVal = 0  
 END       
 RETURN @lRetVal 
END 
