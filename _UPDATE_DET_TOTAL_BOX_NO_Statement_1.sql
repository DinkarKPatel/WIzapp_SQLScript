
IF NOT EXISTS(SELECT TOP 1 'U' FROM CONFIG WHERE CONFIG_OPTION='UPDATE_DET_TOTAL_BOX_NO' AND VALUE=1)
BEGIN
  INSERT INTO CONFIG(CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
  VALUES('UPDATE_DET_TOTAL_BOX_NO',1,NEWID(),GETDATE())
  
	   UPDATE A SET  TOTAL_BOX_NO=ISNULL(B.TOTAL_BOX_NO,0)          
		FROM RMM01106 A LEFT OUTER JOIN
		( 	
			SELECT	RM_ID,COUNT(DISTINCT BOX_NO)TOTAL_BOX_NO 
			FROM RMD01106  
			GROUP BY RM_ID  
		) B ON  A.RM_ID = B.RM_ID  
		
		 UPDATE A SET  TOTAL_BOX_NO=ISNULL(B.TOTAL_BOX_NO,0)          
		FROM INM01106 A LEFT OUTER JOIN
		( 	
			SELECT	INV_ID,COUNT(DISTINCT BOX_NO)TOTAL_BOX_NO 
			FROM IND01106 WHERE ISNULL(BOX_NO,0)>0
			GROUP BY INV_ID 
		) B ON  A.INV_ID = B.INV_ID  
		
		 UPDATE A SET  TOTAL_BOX_NO=ISNULL(B.TOTAL_BOX_NO,0)          
		FROM PIM01106 A LEFT OUTER JOIN
		( 	
			SELECT	MRR_ID,COUNT(DISTINCT BOX_NO)TOTAL_BOX_NO 
			FROM PID01106
			GROUP BY MRR_ID 
		) B ON  A.MRR_ID = B.MRR_ID  

END
