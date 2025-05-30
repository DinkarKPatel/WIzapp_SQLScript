CREATE PROCEDURE UPDATEPMT_PRD_JWR  
  @CXNTYPE VARCHAR(10),  
  @CXNNO VARCHAR(40),  
  @CXNID VARCHAR(40),  
  @NREVERTFLAG BIT = 0,  
  @NALLOWNEGSTOCK BIT = 0,  
  @NCHKDELBARCODES BIT = 0,  
  @NUPDATEMODE INT=0,   
  @CCMD NVARCHAR(4000) OUTPUT  
  
  --*** PARAMETERS :  
  --*** @CXNTYPE -		TRANSACTION TYPE (MODULE SPECIFIC)  
  --*** @CXNNO -		TRANSACTION NO ( MEMO NO OF MASTER TABLE )  
  --*** @CXNID -		TRANSACTION ID ( MEMO ID OF MASTER TABLE )  
  --*** @NREVERTFLAG -	A FLAG TO INDICATE WHETHER THIS PROCEDURE IS CALLED TO REVERT STOCK  
  --*** @NALLOWNEGSTOCK - FLAG TO INDICATE WHETHER OR NOT ALLOW NEGATIVE STOCK  
  --*** @NRETVAL - OUTPUT PARAMETER RETURNED BY THIS PROCEDURE (BIT 1-SUCCESS, 0-UNSUCCESS)  
----WITH ENCRYPTION
AS  
BEGIN  
	DECLARE @NOUTFLAG	INT,			@NRETVAL BIT,				@CXNTABLE VARCHAR(50),
			@CEXPR NVARCHAR(500),		@CXNIDPARA	VARCHAR(50),	@BCANCELLED BIT  

	SET @NRETVAL = 0  
	SET @CCMD = '' 
	PRINT 'UPDATEPMT - 1 '  
	IF @NREVERTFLAG = 1  
		SET @NOUTFLAG = 1  
	ELSE  
		SET @NOUTFLAG = -1  
  
	INSERT PRD_PMT (PRODUCT_CODE,QUANTITY_IN_STOCK, DEPARTMENT_ID,LAST_UPDATE,PRODUCT_UID )  
	SELECT B.PRODUCT_CODE,0 AS QUANTITY_IN_STOCK,C.DEPARTMENT_ID,GETDATE() AS LAST_UPDATE,B.PRODUCT_UID 
	FROM PRD_JOBWORK_RECEIPT_DET B  
	JOIN PRD_JOBWORK_RECEIPT_MST C ON C.RECEIPT_ID=B.RECEIPT_ID  
	JOIN PRD_SKU D ON B.PRODUCT_CODE = D.PRODUCT_CODE  
	LEFT OUTER JOIN PRD_PMT PMT ON PMT.PRODUCT_CODE = B.PRODUCT_CODE AND PMT.DEPARTMENT_ID = C.DEPARTMENT_ID  
	WHERE  B.RECEIPT_ID = @CXNID AND PMT.PRODUCT_CODE IS NULL  
     
   
    
	--*** UPDATING THE QUANTITY IN STOCK FROM PMT FOR THE GIVEN MEMO  
	UPDATE A SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - ( @NOUTFLAG * B.QUANTITY )  
	FROM  PRD_PMT A
	JOIN 
	( 
		SELECT B.PRODUCT_CODE, A.DEPARTMENT_ID, SUM(B.QUANTITY) AS QUANTITY   
		FROM PRD_JOBWORK_RECEIPT_DET B   
		JOIN PRD_JOBWORK_RECEIPT_MST A ON A.RECEIPT_ID=B.RECEIPT_ID  
		JOIN PRD_JOBWORK_ISSUE_DET C ON C.ROW_ID=B.REF_ROW_ID  
		JOIN PRD_JOBWORK_ISSUE_MST D ON D.ISSUE_ID=C.ISSUE_ID  
		WHERE B.RECEIPT_ID = @CXNID AND D.ISSUE_TYPE=1  
		GROUP BY B.PRODUCT_CODE,A.DEPARTMENT_ID
	) B  ON A.PRODUCT_CODE = B.PRODUCT_CODE   
	AND A.DEPARTMENT_ID = B.DEPARTMENT_ID  
	
  
   --*** UPDATING THE QUANTITY IN STOCK FROM PMT FOR THE GIVEN MEMO  
	
	
  SET @NRETVAL = 1  --*** SUCCESS  
  
  SELECT @BCANCELLED=CANCELLED FROM JOBWORK_RECEIPT_MST WHERE RECEIPT_ID=@CXNID  
    
  --*** CHECKING FOR NEGATIVE STOCK  
  --*** IF USER OPTED NOT TO ALLOW NEGATIVE STOCK AND STOCK IS GOING OUT  
  IF (@NREVERTFLAG = 0 AND @NALLOWNEGSTOCK = 0 AND @NOUTFLAG = 1) OR @BCANCELLED=1  
  BEGIN  
   IF EXISTS ( SELECT A.PRODUCT_CODE FROM PRD_PMT A JOIN  
      (SELECT B.PRODUCT_CODE,C.DEPARTMENT_ID AS DEPARTMENT_ID, SUM(B.QUANTITY) AS QUANTITY   
      FROM PRD_JOBWORK_RECEIPT_DET B  
      JOIN PRD_JOBWORK_RECEIPT_MST C ON C.RECEIPT_ID=B.RECEIPT_ID  
      JOIN PRD_SKU D ON B.PRODUCT_CODE = D.PRODUCT_CODE  
      JOIN ARTICLE E ON D.ARTICLE_CODE = E.ARTICLE_CODE  
      JOIN PRD_JOBWORK_ISSUE_DET F ON F.ROW_ID=B.REF_ROW_ID  
      JOIN PRD_JOBWORK_ISSUE_MST G ON G.ISSUE_ID=F.ISSUE_ID  
      WHERE  B.RECEIPT_ID = @CXNID AND G.ISSUE_TYPE=1  
      AND E.STOCK_NA=0  
      GROUP BY B.PRODUCT_CODE,C.DEPARTMENT_ID 
      ) B ON B.PRODUCT_CODE=A.PRODUCT_CODE AND B.DEPARTMENT_ID=A.DEPARTMENT_ID  
      WHERE A.QUANTITY_IN_STOCK < 0)  
   BEGIN  
    SET @NRETVAL = 0  --*** UNSUCCESS  
    SET @CCMD = N'SELECT DISTINCT A.PRODUCT_CODE, A.QUANTITY_IN_STOCK FROM PRD_PMT A  JOIN  
      (SELECT B.PRODUCT_CODE,C.DEPARTMENT_ID AS DEPARTMENT_ID, SUM(B.QUANTITY) AS QUANTITY   
      FROM PRD_JOBWORK_RECEIPT_DET B  
      JOIN PRD_JOBWORK_RECEIPT_MST C ON C.RECEIPT_ID=B.RECEIPT_ID  
      JOIN PRD_SKU D ON B.PRODUCT_CODE = D.PRODUCT_CODE  
      JOIN ARTICLE E ON D.ARTICLE_CODE = E.ARTICLE_CODE  
      JOIN PRD_JOBWORK_ISSUE_DET F ON F.ROW_ID=B.REF_ROW_ID  
      JOIN PRD_JOBWORK_ISSUE_MST G ON G.ISSUE_ID=F.ISSUE_ID  
      WHERE  B.RECEIPT_ID = '''+@CXNID+''' AND G.ISSUE_TYPE=1        
      AND E.STOCK_NA=0 GROUP BY B.PRODUCT_CODE,C.DEPARTMENT_ID
      ) B ON B.PRODUCT_CODE=A.PRODUCT_CODE AND B.DEPARTMENT_ID=A.DEPARTMENT_ID  
      WHERE A.QUANTITY_IN_STOCK < 0 '  
   END  
  END   
 END  --  END OF JOB WORK RECEIPT
