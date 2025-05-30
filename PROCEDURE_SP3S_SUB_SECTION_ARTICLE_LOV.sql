CREATE PROCEDURE SP3S_SUB_SECTION_ARTICLE_LOV
(
  @NMODE INT
)
--WITH ENCRYPTION
AS
BEGIN
IF @NMODE=1
GOTO SUB_SECTION_LOV
ELSE IF @NMODE=2
GOTO ARTICLE_LOV
ELSE 
GOTO END_PROC

     DECLARE @CHODEPT_ID VARCHAR(2)
     SELECT TOP 1 @CHODEPT_ID=VALUE  FROM CONFIG WHERE CONFIG_OPTION ='HO_LOCATION_ID' 
     
	 SUB_SECTION_LOV:
	 
		 SELECT A.SUB_SECTION_CODE,A.SUB_SECTION_NAME,SECTION_NAME  ,A.SUB_SECTION_CODE AS PARA_CODE
		 FROM 
		    (
		     SELECT SUB_SECTION_CODE ,SUB_SECTION_NAME  ,SECTION_CODE,
				    SR=ROW_NUMBER() OVER (PARTITION BY SUB_SECTION_NAME ORDER BY SUB_SECTION_NAME,CASE WHEN @CHODEPT_ID=LEFT(SUB_SECTION_CODE,2) THEN 1 ELSE 0 END)
			 FROM SECTIOND A WHERE SUB_SECTION_CODE <>'0000000' AND INACTIVE=0
		     ) A 
		  JOIN SECTIONM B ON A.SECTION_CODE=B.SECTION_CODE
		  --WHERE SR=1
		  ORDER BY SUB_SECTION_NAME
			 
	 GOTO END_PROC
	 
	 ARTICLE_LOV:
	 
	      SELECT A.ARTICLE_CODE ,A.ARTICLE_NAME , B.SUB_SECTION_NAME,C.SECTION_NAME, A.ARTICLE_CODE AS PARA_CODE
	      FROM 
             (
              SELECT ARTICLE_CODE ,ARTICLE_NAME ,SUB_SECTION_CODE,
                    SR=ROW_NUMBER() OVER (PARTITION BY ARTICLE_NAME ORDER BY ARTICLE_NAME,CASE WHEN @CHODEPT_ID=LEFT(ARTICLE_CODE,2) THEN 1 ELSE 0 END)
              FROM ARTICLE A WHERE ARTICLE_CODE  <>'00000000' AND INACTIVE=0
              ) A 
           JOIN SECTIOND B ON A.SUB_SECTION_CODE=B.SUB_SECTION_CODE
           JOIN SECTIONM C ON C.SECTION_CODE=B.SECTION_CODE
           WHERE SR=1
           ORDER BY ARTICLE_NAME 
	 
	 GOTO END_PROC
	 
	 
 
 END_PROC:

END
