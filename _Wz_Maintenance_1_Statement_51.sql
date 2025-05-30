

IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE  CONFIG_OPTION='DROP_ALL_CONSTRAINTS1' AND VALUE=1)
BEGIN

        DECLARE @HO_LOCATION_ID VARCHAR(5),@LOCATION_ID VARCHAR(5),@PUR_LOC BIT
        
        SELECT @HO_LOCATION_ID=VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID' 
        SELECT @LOCATION_ID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID' 
        SELECT @PUR_LOC=PUR_LOC FROM LOCATION WHERE DEPT_ID=@LOCATION_ID
        
       
			    
			IF EXISTS (SELECT * FROM SYS.CHECK_CONSTRAINTS A JOIN SYS.TABLES B ON A.PARENT_OBJECT_ID=B.OBJECT_ID
			WHERE A.NAME='CHK_PARA1_NAME' AND B.NAME='PARA1')
			ALTER TABLE PARA1 DROP CONSTRAINT CHK_PARA1_NAME
			

			IF EXISTS (SELECT * FROM SYS.CHECK_CONSTRAINTS A JOIN SYS.TABLES B ON A.PARENT_OBJECT_ID=B.OBJECT_ID
			WHERE A.NAME='CHK_PARA2_NAME' AND B.NAME='PARA2')
			ALTER TABLE PARA2 DROP CONSTRAINT CHK_PARA2_NAME
			

			IF EXISTS (SELECT * FROM SYS.CHECK_CONSTRAINTS A JOIN SYS.TABLES B ON A.PARENT_OBJECT_ID=B.OBJECT_ID
			WHERE A.NAME='CHK_PARA3_NAME' AND B.NAME='PARA3')
			ALTER TABLE PARA3 DROP CONSTRAINT CHK_PARA3_NAME
			

			IF EXISTS (SELECT * FROM SYS.CHECK_CONSTRAINTS A JOIN SYS.TABLES B ON A.PARENT_OBJECT_ID=B.OBJECT_ID
			WHERE A.NAME='CHK_PARA4_NAME' AND B.NAME='PARA4')
			ALTER TABLE PARA4 DROP CONSTRAINT CHK_PARA4_NAME
			

			IF EXISTS (SELECT * FROM SYS.CHECK_CONSTRAINTS A JOIN SYS.TABLES B ON A.PARENT_OBJECT_ID=B.OBJECT_ID
			WHERE A.NAME='CHK_PARA5_NAME' AND B.NAME='PARA5')
			ALTER TABLE PARA5 DROP CONSTRAINT CHK_PARA5_NAME
			

			IF EXISTS (SELECT * FROM SYS.CHECK_CONSTRAINTS A JOIN SYS.TABLES B ON A.PARENT_OBJECT_ID=B.OBJECT_ID
			WHERE A.NAME='CHK_PARA6_NAME' AND B.NAME='PARA6')
			ALTER TABLE PARA6 DROP CONSTRAINT CHK_PARA6_NAME
			

			IF EXISTS (SELECT * FROM SYS.CHECK_CONSTRAINTS A JOIN SYS.TABLES B ON A.PARENT_OBJECT_ID=B.OBJECT_ID
			WHERE A.NAME='CHK_ARTICLE_NO' AND B.NAME='ARTICLE')
			ALTER TABLE ARTICLE DROP CONSTRAINT CHK_ARTICLE_NO
			

			IF EXISTS (SELECT * FROM SYS.CHECK_CONSTRAINTS A JOIN SYS.TABLES B ON A.PARENT_OBJECT_ID=B.OBJECT_ID
			WHERE A.NAME='CHK_SUBSECTION_NAME' AND B.NAME='SECTIOND')
			ALTER TABLE SECTIOND DROP CONSTRAINT CHK_SUBSECTION_NAME
			

			IF EXISTS (SELECT * FROM SYS.CHECK_CONSTRAINTS A JOIN SYS.TABLES B ON A.PARENT_OBJECT_ID=B.OBJECT_ID
			WHERE A.NAME='CHK_SECTION_NAME' AND B.NAME='SECTIONM')
			ALTER TABLE SECTIONM DROP CONSTRAINT CHK_SECTION_NAME
			
	 IF @HO_LOCATION_ID<>@LOCATION_ID AND @PUR_LOC=0
        BEGIN
            UPDATE PARA1 SET INACTIVE=0
            UPDATE PARA2 SET INACTIVE=0
            UPDATE PARA3 SET INACTIVE=0
            UPDATE PARA4 SET INACTIVE=0
            UPDATE PARA5 SET INACTIVE=0
            UPDATE PARA6 SET INACTIVE=0
        END
            
            
            EXEC SP3S_INACTIVE_DUP_PARA
			
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='DROP_ALL_CONSTRAINTS1')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('DROP_ALL_CONSTRAINTS1',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE='1' WHERE  CONFIG_OPTION='DROP_ALL_CONSTRAINTS1'
		 
END
