

	  Update A SET SOARTICLE=1,
	               SOPARA1=ISNULL(p1.OPEN_KEY,0),
				   SOPARA2=ISNULL(p2.OPEN_KEY,0),
				   SOPARA3=ISNULL(p3.OPEN_KEY,0)
	  FROM SECTIOND A (NOLOCK)
	  LEFT JOIN CONFIG_BUYERORDER P1 (NOLOCK) ON P1.OPEN_KEY=1 AND P1.COLUMN_NAME='PARA1_NAME'
	  LEFT JOIN CONFIG_BUYERORDER P2 (NOLOCK) ON P2.OPEN_KEY=1 AND P2.COLUMN_NAME='PARA2_NAME'
	  LEFT JOIN CONFIG_BUYERORDER P3 (NOLOCK) ON P3.OPEN_KEY=1 AND P3.COLUMN_NAME='PARA3_NAME'
	  WHERE ISNULL(SOARTICLE,0)=0 AND ISNULL(SOPARA1,0)=0 AND ISNULL(SOPARA2,0)=0 AND ISNULL(SOPARA3,0)=0


