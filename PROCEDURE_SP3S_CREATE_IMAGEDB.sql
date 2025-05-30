CREATE PROC SP3S_CREATE_IMAGEDB
AS 
BEGIN
SET NOCOUNT ON
DECLARE @DB VARCHAR(100),@PATH VARCHAR(100),@CCMD NVARCHAR(MAX),@ERR INT=0,@ERR_MSG VARCHAR(100)=''
SET @DB=DB_NAME()+'_IMAGE'
SELECT @PATH=REVERSE(SUBSTRING(REVERSE(FILENAME),CHARINDEX('\',REVERSE(FILENAME),1),1000)) FROM MASTER..SYSDATABASES WHERE NAME=DB_NAME()
SET @CCMD=N'CREATE DATABASE ['+@DB+'] ON  PRIMARY 
(NAME = N'''+@DB+''', FILENAME = N'''+@PATH+@DB+'.MDF'')
LOG ON 
(NAME = N'''+@DB+'_LOG'', FILENAME = N'''+@PATH+@DB+'.LDF'')'
IF NOT EXISTS(SELECT * FROM SYS.DATABASES WHERE NAME=@DB)
   BEGIN
     EXEC(@CCMD)
     SET @ERR=CAST(@@ERROR AS INT)
     IF @ERR!=0
        SET @ERR_MSG='ERROR WHILE CREATING DATABASE'
   END  
IF @ERR!=0
   GOTO FINISH
SET @CCMD=N'USE ['+@DB+'];
IF EXISTS(SELECT * FROM SYSOBJECTS WHERE TYPE=''U'' AND NAME=''IMAGE_INFO_BAK'')
   DROP TABLE IMAGE_INFO_BAK;
CREATE TABLE IMAGE_INFO_BAK (IMG_ID VARCHAR(100) NOT NULL,SECTION_CODE CHAR(7),SUB_SECTION_CODE CHAR(7),ARTICLE_CODE CHAR(9),PARA1_CODE CHAR(9),PARA2_CODE CHAR(9),PARA3_CODE CHAR(9),PARA4_CODE CHAR(9),PARA5_CODE CHAR(9),PARA6_CODE CHAR(9),PRODUCT_CODE VARCHAR(50),PROD_IMAGE VARBINARY(MAX),PROD_IMAGE1 VARBINARY(MAX),PROD_IMAGE2 VARBINARY(MAX),PROD_IMAGE3 VARBINARY(MAX),PROD_IMAGE4 VARBINARY(MAX),UPLOADED_TO_HO BIT,DEPT_ID VARCHAR(5));

IF EXISTS(SELECT * FROM SYSOBJECTS WHERE TYPE=''U'' AND NAME=''IMAGE_INFO_DOC_BAK'')
   DROP TABLE IMAGE_INFO_DOC_BAK
CREATE TABLE IMAGE_INFO_DOC_BAK (IMG_ID VARCHAR(100) NOT NULL, XN_TYPE VARCHAR(10),MEMO_ID VARCHAR(50),DOC_IMAGE VARBINARY(MAX),DOC_IMAGE1 VARBINARY(MAX),DOC_IMAGE2 VARBINARY(MAX),DOC_IMAGE3 VARBINARY(MAX),DOC_IMAGE4 VARBINARY(MAX),UPLOADED_TO_HO BIT,DEPT_ID VARCHAR(5));'
PRINT @CCMD
EXEC(@CCMD)

SET @CCMD=N'USE ['+@DB+'];
IF OBJECT_ID(''IMAGE_INFO'') IS NULL
   CREATE TABLE IMAGE_INFO (LAST_UPDATE DATETIME, IMG_ID VARCHAR(100) NOT NULL,SECTION_CODE CHAR(7),SUB_SECTION_CODE CHAR(7),ARTICLE_CODE CHAR(9),PARA1_CODE CHAR(9),PARA2_CODE CHAR(9),PARA3_CODE CHAR(9),PARA4_CODE CHAR(9),PARA5_CODE CHAR(9),PARA6_CODE CHAR(9),PRODUCT_CODE VARCHAR(50),PROD_IMAGE VARBINARY(MAX),PROD_IMAGE1 VARBINARY(MAX),PROD_IMAGE2 VARBINARY(MAX),PROD_IMAGE3 VARBINARY(MAX),PROD_IMAGE4 VARBINARY(MAX),UPLOADED_TO_HO BIT,DEPT_ID VARCHAR(5));

IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''LAST_UPDATE'')
   ALTER TABLE IMAGE_INFO ADD LAST_UPDATE DATETIME NOT NULL DEFAULT '''';

IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''IMG_ID'')
   ALTER TABLE IMAGE_INFO ADD IMG_ID VARCHAR(100) NOT NULL DEFAULT '''';
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''SECTION_CODE'')
   ALTER TABLE IMAGE_INFO ADD SECTION_CODE CHAR(7);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''SUB_SECTION_CODE'')
   ALTER TABLE IMAGE_INFO ADD SUB_SECTION_CODE CHAR(7);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''ARTICLE_CODE'')
   ALTER TABLE IMAGE_INFO ADD ARTICLE_CODE CHAR(9);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PARA1_CODE'')
   ALTER TABLE IMAGE_INFO ADD PARA1_CODE CHAR(9);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PARA2_CODE'')
   ALTER TABLE IMAGE_INFO ADD PARA2_CODE CHAR(9);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PARA3_CODE'')
   ALTER TABLE IMAGE_INFO ADD PARA3_CODE CHAR(9);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PARA4_CODE'')
   ALTER TABLE IMAGE_INFO ADD PARA4_CODE CHAR(9);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PARA5_CODE'')
   ALTER TABLE IMAGE_INFO ADD PARA5_CODE CHAR(9);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PARA6_CODE'')
   ALTER TABLE IMAGE_INFO ADD PARA6_CODE CHAR(9);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PRODUCT_CODE'')
   ALTER TABLE IMAGE_INFO ADD PRODUCT_CODE VARCHAR(50);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PROD_IMAGE'')
   ALTER TABLE IMAGE_INFO ADD PROD_IMAGE VARBINARY(MAX);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PROD_IMAGE1'')
   ALTER TABLE IMAGE_INFO ADD PROD_IMAGE1 VARBINARY(MAX);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PROD_IMAGE2'')
   ALTER TABLE IMAGE_INFO ADD PROD_IMAGE2 VARBINARY(MAX);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PROD_IMAGE3'')
   ALTER TABLE IMAGE_INFO ADD PROD_IMAGE3 VARBINARY(MAX);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''PROD_IMAGE4'')
   ALTER TABLE IMAGE_INFO ADD PROD_IMAGE4 VARBINARY(MAX);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''UPLOADED_TO_HO'')
   ALTER TABLE IMAGE_INFO ADD UPLOADED_TO_HO BIT;
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO'' AND NAME=''DEPT_ID'')
   ALTER TABLE IMAGE_INFO ADD DEPT_ID VARCHAR(5);'
PRINT @CCMD   
EXEC(@CCMD)
  
SET @CCMD=N'USE ['+@DB+'];
IF NOT EXISTS(SELECT * FROM SYS.OBJECTS WHERE TYPE=''PK'' AND NAME=''PK_IMAGEID_IMGINFO'' AND OBJECT_NAME(PARENT_OBJECT_ID)=''IMAGE_INFO'')  
   BEGIN
      DELETE IMAGE_INFO_BAK
      INSERT IMAGE_INFO_BAK (SECTION_CODE,SUB_SECTION_CODE,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,PARA4_CODE,PARA5_CODE,PARA6_CODE,PRODUCT_CODE,PROD_IMAGE,PROD_IMAGE1,PROD_IMAGE2,PROD_IMAGE3,PROD_IMAGE4,UPLOADED_TO_HO,DEPT_ID)
      SELECT SECTION_CODE,SUB_SECTION_CODE,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,PARA4_CODE,PARA5_CODE,PARA6_CODE,PRODUCT_CODE,PROD_IMAGE,PROD_IMAGE1,PROD_IMAGE2,PROD_IMAGE3,PROD_IMAGE4,UPLOADED_TO_HO,DEPT_ID FROM IMAGE_INFO
      
      DELETE IMAGE_INFO   
      
      ALTER TABLE IMAGE_INFO WITH NOCHECK ADD CONSTRAINT PK_IMAGEID_IMGINFO PRIMARY KEY CLUSTERED (IMG_ID);  
      
      INSERT IMAGE_INFO (LAST_UPDATE,SECTION_CODE,SUB_SECTION_CODE,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,PARA4_CODE,PARA5_CODE,PARA6_CODE,PRODUCT_CODE,PROD_IMAGE,PROD_IMAGE1,PROD_IMAGE2,PROD_IMAGE3,PROD_IMAGE4,IMG_ID,UPLOADED_TO_HO,DEPT_ID)
      SELECT GETDATE(),SECTION_CODE,SUB_SECTION_CODE,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,PARA4_CODE,PARA5_CODE,PARA6_CODE,PRODUCT_CODE,PROD_IMAGE,PROD_IMAGE1,PROD_IMAGE2,PROD_IMAGE3,PROD_IMAGE4,NEWID(),UPLOADED_TO_HO,DEPT_ID FROM IMAGE_INFO_BAK
   END;' 
PRINT @CCMD   
EXEC(@CCMD)

SET @CCMD=N'USE ['+@DB+'];
IF NOT EXISTS(SELECT * FROM SYS.OBJECTS WHERE NAME=''UQ_ROW'' AND OBJECT_NAME(PARENT_OBJECT_ID)=''IMAGE_INFO'')  
   ALTER TABLE IMAGE_INFO WITH NOCHECK ADD CONSTRAINT UQ_ROW UNIQUE (SECTION_CODE,SUB_SECTION_CODE,ARTICLE_CODE,PARA1_CODE,PARA2_CODE,PARA3_CODE,PARA4_CODE,PARA5_CODE,PARA6_CODE,PRODUCT_CODE);'
PRINT @CCMD
EXEC(@CCMD)

SET @CCMD=N'USE ['+@DB+'];
IF NOT EXISTS(SELECT * FROM SYSOBJECTS WHERE TYPE=''U'' AND NAME=''IMAGE_INFO_DOC'')
   CREATE TABLE IMAGE_INFO_DOC (IMG_ID VARCHAR(100) NOT NULL, XN_TYPE VARCHAR(100),MEMO_ID VARCHAR(50),DOC_IMAGE VARBINARY(MAX),DOC_IMAGE1 VARBINARY(MAX),DOC_IMAGE2 VARBINARY(MAX),DOC_IMAGE3 VARBINARY(MAX),DOC_IMAGE4 VARBINARY(MAX),UPLOADED_TO_HO BIT,DEPT_ID VARCHAR(5));
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''IMG_ID'')
   ALTER TABLE IMAGE_INFO_DOC ADD IMG_ID VARCHAR(100) NOT NULL DEFAULT ''''
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''XN_TYPE'')
   ALTER TABLE IMAGE_INFO_DOC ADD XN_TYPE VARCHAR(100)
ELSE 
    ALTER TABLE IMAGE_INFO_DOC ALTER COLUMN XN_TYPE VARCHAR(100)
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''MEMO_ID'')
   ALTER TABLE IMAGE_INFO_DOC ADD MEMO_ID VARCHAR (50)
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''DOC_IMAGE'')
   ALTER TABLE IMAGE_INFO_DOC ADD DOC_IMAGE VARBINARY(MAX)
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''DOC_IMAGE1'')
   ALTER TABLE IMAGE_INFO_DOC ADD DOC_IMAGE1 VARBINARY(MAX)
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''DOC_IMAGE2'')
   ALTER TABLE IMAGE_INFO_DOC ADD DOC_IMAGE2 VARBINARY(MAX)
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''DOC_IMAGE3'')
   ALTER TABLE IMAGE_INFO_DOC ADD DOC_IMAGE3 VARBINARY(MAX)
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''DOC_IMAGE4'')
   ALTER TABLE IMAGE_INFO_DOC ADD DOC_IMAGE4 VARBINARY(MAX);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''UPLOADED_TO_HO'')
   ALTER TABLE IMAGE_INFO_DOC ADD UPLOADED_TO_HO BIT;
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''DEPT_ID'')
   ALTER TABLE IMAGE_INFO_DOC ADD DEPT_ID VARCHAR(5);
IF NOT EXISTS(SELECT * FROM SYSCOLUMNS WHERE OBJECT_NAME(ID)=''IMAGE_INFO_DOC'' AND NAME=''filename'')
   ALTER TABLE IMAGE_INFO_DOC ADD filename VARCHAR(500);'

PRINT @CCMD
EXEC(@CCMD)

SET @CCMD=N'USE ['+@DB+'];
IF NOT EXISTS(SELECT * FROM SYS.OBJECTS WHERE TYPE=''PK'' AND NAME=''PK_IMAGEID_IMGINFODOC'' AND OBJECT_NAME(PARENT_OBJECT_ID)=''IMAGE_INFO_DOC'')  
   BEGIN
      DELETE IMAGE_INFO_DOC_BAK
      INSERT IMAGE_INFO_DOC_BAK (XN_TYPE,MEMO_ID,DOC_IMAGE,DOC_IMAGE1,DOC_IMAGE2,DOC_IMAGE3,DOC_IMAGE4,IMG_ID,UPLOADED_TO_HO,DEPT_ID)
      SELECT XN_TYPE,MEMO_ID,DOC_IMAGE,DOC_IMAGE1,DOC_IMAGE2,DOC_IMAGE3,DOC_IMAGE4,IMG_ID,UPLOADED_TO_HO,DEPT_ID FROM IMAGE_INFO_DOC
      
      DELETE IMAGE_INFO_DOC  
      ALTER TABLE IMAGE_INFO_DOC WITH NOCHECK ADD CONSTRAINT PK_IMAGEID_IMGINFODOC PRIMARY KEY CLUSTERED (IMG_ID);  
      INSERT IMAGE_INFO_DOC (XN_TYPE,MEMO_ID,DOC_IMAGE,DOC_IMAGE1,DOC_IMAGE2,DOC_IMAGE3,DOC_IMAGE4,IMG_ID,UPLOADED_TO_HO,DEPT_ID)
      SELECT XN_TYPE,MEMO_ID,DOC_IMAGE,DOC_IMAGE1,DOC_IMAGE2,DOC_IMAGE3,DOC_IMAGE4,NEWID(),UPLOADED_TO_HO,DEPT_ID FROM IMAGE_INFO_DOC_BAK
   END;'
PRINT @CCMD
EXEC(@CCMD)

SET @CCMD=N'USE ['+@DB+'];
IF EXISTS(SELECT * FROM SYS.OBJECTS WHERE NAME=''UQ_XNTYP_MEMOID'' AND OBJECT_NAME(PARENT_OBJECT_ID)=''IMAGE_INFO_DOC'')  
   ALTER TABLE IMAGE_INFO_DOC DROP CONSTRAINT UQ_XNTYP_MEMOID ;'  
   --ALTER TABLE IMAGE_INFO_DOC ADD CONSTRAINT UQ_XNTYP_MEMOID UNIQUE (XN_TYPE,MEMO_ID,);' 

PRINT @CCMD
EXEC(@CCMD)
SET @ERR=CAST(@@ERROR AS INT)
IF @ERR!=0
   BEGIN
     SET @CCMD='DROP DATABASE ['+@DB+'];'
     PRINT @CCMD
     --EXEC(@CCMD)
     SET @ERR_MSG='ERROR WHILE CREATING DATABASE AND/OR ITS OBJECTS'
   END
ELSE
  BEGIN
     SET @CCMD=N'USE ['+@DB+'];
	 IF EXISTS(SELECT * FROM SYSOBJECTS WHERE TYPE=''U'' AND NAME=''IMAGE_INFO_BAK'')
		DROP TABLE IMAGE_INFO_BAK;
	 IF EXISTS(SELECT * FROM SYSOBJECTS WHERE TYPE=''U'' AND NAME=''IMAGE_INFO_DOC_BAK'')
		DROP TABLE IMAGE_INFO_DOC_BAK;'
     PRINT @CCMD
     EXEC(@CCMD)
  END   

SET @CCMD=N'USE ['+@DB+'];
IF NOT EXISTS(SELECT TOP 1 NAME FROM SYS.INDEXES WHERE TYPE=2 AND OBJECT_NAME(OBJECT_ID)=''IMAGE_INFO'' AND NAME=''IX_ARTICLE'')
   CREATE INDEX IX_ARTICLE ON IMAGE_INFO(ARTICLE_CODE);
IF NOT EXISTS(SELECT TOP 1 NAME FROM SYS.INDEXES WHERE TYPE=2 AND OBJECT_NAME(OBJECT_ID)=''IMAGE_INFO'' AND NAME=''IX_SECTION'')
   CREATE INDEX IX_SECTION ON IMAGE_INFO(SECTION_CODE);
IF NOT EXISTS(SELECT TOP 1 NAME FROM SYS.INDEXES WHERE TYPE=2 AND OBJECT_NAME(OBJECT_ID)=''IMAGE_INFO'' AND NAME=''IX_PRODCODE'')
   CREATE INDEX IX_PRODCODE ON IMAGE_INFO(PRODUCT_CODE);
IF NOT EXISTS(SELECT TOP 1 NAME FROM SYS.INDEXES WHERE TYPE=2 AND OBJECT_NAME(OBJECT_ID)=''IMAGE_INFO'' AND NAME=''IX_SUBSECTION'')
   CREATE INDEX IX_SUBSECTION ON IMAGE_INFO(SUB_SECTION_CODE);
IF NOT EXISTS(SELECT TOP 1 NAME FROM SYS.INDEXES WHERE TYPE=2 AND OBJECT_NAME(OBJECT_ID)=''IMAGE_INFO'' AND NAME=''IX_PARA1_CODE'')
   CREATE INDEX IX_PARA1_CODE ON IMAGE_INFO(PARA1_CODE);
IF NOT EXISTS(SELECT TOP 1 NAME FROM SYS.INDEXES WHERE TYPE=2 AND OBJECT_NAME(OBJECT_ID)=''IMAGE_INFO'' AND NAME=''IX_PARA2_CODE'')
   CREATE INDEX IX_PARA2_CODE ON IMAGE_INFO(PARA2_CODE);
IF NOT EXISTS(SELECT TOP 1 NAME FROM SYS.INDEXES WHERE TYPE=2 AND OBJECT_NAME(OBJECT_ID)=''IMAGE_INFO'' AND NAME=''IX_PARA3_CODE'')
   CREATE INDEX IX_PARA3_CODE ON IMAGE_INFO(PARA3_CODE);
IF NOT EXISTS(SELECT TOP 1 NAME FROM SYS.INDEXES WHERE TYPE=2 AND OBJECT_NAME(OBJECT_ID)=''IMAGE_INFO'' AND NAME=''IX_PARA4_CODE'')
   CREATE INDEX IX_PARA4_CODE ON IMAGE_INFO(PARA4_CODE);
IF NOT EXISTS(SELECT TOP 1 NAME FROM SYS.INDEXES WHERE TYPE=2 AND OBJECT_NAME(OBJECT_ID)=''IMAGE_INFO'' AND NAME=''IX_PARA5_CODE'')
   CREATE INDEX IX_PARA5_CODE ON IMAGE_INFO(PARA5_CODE);
IF NOT EXISTS(SELECT TOP 1 NAME FROM SYS.INDEXES WHERE TYPE=2 AND OBJECT_NAME(OBJECT_ID)=''IMAGE_INFO'' AND NAME=''IX_PARA6_CODE'')
   CREATE INDEX IX_PARA6_CODE ON IMAGE_INFO(PARA6_CODE);'
PRINT @CCMD
EXEC(@CCMD)
SET @ERR=CAST(@@ERROR AS INT)
  
FINISH:
SET @CCMD='USE ['+REPLACE(@DB,'_IMAGE','')+'];'
EXEC(@CCMD)
SELECT @ERR_MSG ERROR_MSG
SET NOCOUNT OFF
END
