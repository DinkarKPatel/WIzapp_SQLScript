create PROCEDURE SP3S_NORMALIZE_BARCODE_SLS
(
   @CDEPT_ID VARCHAR(5)='',
   @cspid varchar(50),
   @cUserCode char(10)=''
)
AS
BEGIN
     
	  Declare @CERRMSG varchar(100),@bAllowNegative bit
	  set @CERRMSG=''


	  SELECT @bAllowNegative=VALUE FROM user_role_det a (NOLOCK)
	  JOIN users b (NOLOCK) ON a.role_id=b.role_id
	  WHERE USER_CODE=@cUserCode 
	  AND FORM_NAME='FRMSALE' 
	  AND FORM_OPTION='ALLOW_NEG_STOCK'

	  SET @bAllowNegative =ISNULL(@bAllowNegative,0) 

	  SELECT PRODUCT_CODE 
		 INTO #tmpitemUnique
	  FROM SLS_BarcodeNormalized_upload (nolock)
	  WHERE SP_ID =@CSPID 
	  GROUP BY PRODUCT_CODE

	  SELECT A.BIN_ID 
	      into #TMPBIN
	  FROM BIN A (NOLOCK)
	  JOIN BINUSERS B ON A.MAJOR_BIN_ID =B.BIN_ID 
	  WHERE USER_CODE =@cUserCode
	  AND A.BIN_ID<>'999'
	  group by A.BIN_ID 
	 

     ;WITH Barcode_CTE  AS  
	(  
	  SELECT b.product_code as barcode_wobatch,  a.product_code  ,a.quantity_in_stock,
	        SrNo=1
	  FROM PMT01106 A (nolock)
	  join #tmpitemUnique b on LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))=b.product_code 
	  join #TMPBIN bin on a.BIN_ID =bin.BIN_ID 
	  where quantity_in_stock >0 and a.BIN_ID <>'999' and a.DEPT_ID =@CDEPT_ID
	  and isnull(a.bo_order_id,'')=''
	  UNION ALL  
	  SELECT e.barcode_wobatch, e.product_code,e.quantity_in_stock,SrNo=SrNo+1
	  from Barcode_CTE e   
	   WHERE SrNo<e.quantity_in_stock 
	 )  

	  select barcode_wobatch,product_code,
	        SrNo =ROW_NUMBER () over (partition by barcode_wobatch order by barcode_wobatch)
	  into #tmpitem
	  from Barcode_CTE
	  order by barcode_wobatch,SrNo
	  option (maxrecursion 1000);
	
	UPDATE A SET ORG_PRODUCT_CODE =B.PRODUCT_CODE 
	FROM SLS_BarcodeNormalized_upload A (NOLOCK)
	JOIN #TMPITEM B ON A.PRODUCT_CODE =B.BARCODE_WOBATCH 
	AND A.SRNO =B.SRNO
	WHERE A.SP_ID=@CSPID

	 if @bAllowNegative=1
	 begin
	    
		UPDATE B SET ORG_PRODUCT_CODE= A.PRODUCT_CODE 
		FROM  PMT01106 A
		JOIN SLS_BarcodeNormalized_upload B  (NOLOCK) ON LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))=B.PRODUCT_CODE 
		WHERE B.SP_ID =@CSPID
		AND ISNULL(B.ORG_PRODUCT_CODE,'')='' and charindex('@',A.PRODUCT_CODE )>0
		AND A.BIN_ID <>'999' AND A.DEPT_ID=@CDEPT_ID

	 end

	lblList:

	IF EXISTS (select TOP 1' U' FROM XN_BARCODENORMALIZED_UPLOAD A (NOLOCK) WHERE A.SP_ID=@CSPID AND ISNULL(A.ORG_PRODUCT_CODE,'')='')
	   SET @CERRMSG ='Stock Going Negative'

	SELECT Product_code, Org_product_code,
	      sum(DISCOUNT_AMOUNT) as DISCOUNT_AMOUNT,
	      count(*) as Quantity ,
	     @CERRMSG AS ERRMSG
	FROM SLS_BarcodeNormalized_upload A (NOLOCK)
	WHERE A.SP_ID=@CSPID
	group by Product_code,Org_product_code



END