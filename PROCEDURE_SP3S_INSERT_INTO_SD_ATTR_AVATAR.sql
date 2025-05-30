CREATE PROCEDURE SP3S_INSERT_INTO_SD_ATTR_AVATAR
AS
BEGIN
       
IF OBJECT_ID('TEMPDB..#T1','U') IS NOT NULL
DROP TABLE #T1
select table_name,table_caption INTO  #T1 from  config_attr WHERE ISNULL(table_caption,'')<>''

Declare @TABLE_NAME VARCHAR(100),@TABLE_CAPTION VARCHAR(100),@bloop bit,@ncnt int
set @bloop=0
set @ncnt=1
while @bloop=0
begin

      IF OBJECT_ID('TEMPDB..#T2','U') IS NOT NULL
		DROP TABLE #T2
		
		SET @TABLE_NAME=''
		SET @TABLE_CAPTION=''
		
		SET @ncnt=@ncnt+1
		
		SELECT TOP 1 @TABLE_NAME=table_name,@TABLE_CAPTION=table_caption FROM #T1
		
		IF ISNULL(@TABLE_NAME,'')='' 
		BREAK
		
	
		SELECT DISTINCT A.SUB_SECTION_CODE INTO  #T2 FROM SD_ATTR A 
		JOIN ATTRM B ON A.ATTRIBUTE_CODE=B.ATTRIBUTE_CODE
		JOIN SECTIOND C ON C.SUB_SECTION_CODE=A.sub_section_code
		 WHERE ATTRIBUTE_NAME=@TABLE_CAPTION
		-- WHERE ATTRIBUTE_NAME= 'ATTR_BRAND'
		 

		 IF EXISTS(SELECT TOP 1'U' FROM #T2)
		 BEGIN
		 
		 DECLARE @CCMD NVARCHAR(MAX)
		 
		  SET @CCMD=N' update a set '+@TABLE_NAME+'=1 from SD_ATTR_AVATAR a join #T2 b on a.sub_section_code=b.sub_section_code'
		 EXEC SP_EXECUTESQL @CCMD

		 
		SET @CCMD=N' INSERT SD_ATTR_AVATAR	( SUB_SECTION_CODE,'+@TABLE_NAME+')
		 SELECT A.sub_section_code,1 FROM #T2 A LEFT JOIN SD_ATTR_AVATAR B ON A.SUB_SECTION_CODE=B.SUB_SECTION_CODE
		 WHERE B.SUB_SECTION_CODE IS NULL'
		 EXEC SP_EXECUTESQL @CCMD
		 
		 END
		 
		 
		 DELETE FROM #T1 WHERE table_name=@TABLE_NAME AND table_caption=@TABLE_CAPTION
	
		
 
end

END