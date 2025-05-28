create PROCEDURE SP3S_NORMALIZE_BARCODE_WSL
(
   @CDEPT_ID VARCHAR(5)='',
   @cspid varchar(50),
   @cUserCode char(10)='',
   @cbin_id varchar(7)=''  
)
AS
BEGIN
     
	  Declare @CERRMSG varchar(100),@bAllowNegative bit
	  set @CERRMSG=''


	  SELECT @bAllowNegative=VALUE FROM user_role_det a (NOLOCK)
	  JOIN users b (NOLOCK) ON a.role_id=b.role_id
	  WHERE USER_CODE=@cUserCode 
	  AND FORM_NAME='FRMWSLINVOICE' 
	  AND FORM_OPTION='ALLOW_NEG_STOCK'

	  SET @bAllowNegative =ISNULL(@bAllowNegative,0) 

	  SELECT PRODUCT_CODE ,isnull(mrp,0) as mrp,bin_id
		 INTO #tmpitemUnique
	  FROM WSL_BarcodeNormalized_upload (nolock)
	  WHERE SP_ID =@CSPID 
	  GROUP BY PRODUCT_CODE,mrp,bin_id

	  SELECT A.BIN_ID 
	      into #TMPBIN
	  FROM BIN A (NOLOCK)
	  JOIN BINUSERS B (NOLOCK) ON A.MAJOR_BIN_ID =B.BIN_ID 
	  WHERE USER_CODE =@cUserCode 
	  AND A.BIN_ID<>'999'
	  group by A.BIN_ID 
	 

     ;WITH Barcode_CTE  AS  
	(  
	  SELECT b.product_code as barcode_wobatch,  a.product_code  ,a.quantity_in_stock,
	        SrNo=1 ,b.mrp,a.bin_id   
	  FROM PMT01106 A (nolock)
	  join sku (nolock) on a.product_code=sku.product_code
	  join #tmpitemUnique b on LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))=b.product_code 
	  and sku.mrp=b.mrp and a.BIN_ID=b.bin_id
	  join #TMPBIN bin on a.BIN_ID =bin.BIN_ID 
	  where quantity_in_stock >0 and a.BIN_ID <>'999' and a.DEPT_ID =@CDEPT_ID
	  and isnull(a.bo_order_id,'')=''
	  UNION ALL  
	  SELECT e.barcode_wobatch, e.product_code,e.quantity_in_stock,SrNo=SrNo+1,e.mrp,e.BIN_ID
	  from Barcode_CTE e   
	   WHERE SrNo<e.quantity_in_stock 
	 )  

	  select barcode_wobatch,product_code,mrp,bin_id,
	        SrNo =ROW_NUMBER () over (partition by barcode_wobatch,MRP order by barcode_wobatch)
	  into #tmpitem
	  from Barcode_CTE
	  order by barcode_wobatch,SrNo
	  option (maxrecursion 32767);


	  if  (select count(*) from LOCSKUSP A (nolock)
	  join #tmpitem b on a.product_code=b.product_code
	  where a.dept_id=@CDEPT_ID)>0
	  begin
	       
		   Print 'Pick locskusp mrp '

		   ;WITH CTE AS
		   (
		      SELECT B.PRODUCT_CODE ,A.MRP ,
			      LASTSR=ROW_NUMBER() OVER(PARTITION BY A.PRODUCT_CODE ORDER BY A.FROM_DT DESC)
			  FROM LOCSKUSP A (NOLOCK)
			  JOIN #TMPITEM B ON A.PRODUCT_CODE=B.PRODUCT_CODE
			  WHERE A.DEPT_ID=@CDEPT_ID
		   )

		   UPDATE B SET MRP =A.MRP 
		   FROM CTE A
		   JOIN #TMPITEM B ON A.PRODUCT_CODE =B.PRODUCT_CODE
		   WHERE A.LASTSR=1


	  end
	
	UPDATE A SET ORG_PRODUCT_CODE =B.PRODUCT_CODE ,bin_id=b.BIN_ID
	FROM WSL_BarcodeNormalized_upload A (NOLOCK)
	JOIN #TMPITEM B ON A.PRODUCT_CODE =B.BARCODE_WOBATCH and isnull(a.mrp,0)=isnull(b.mrp ,0) and a.bin_id=b.BIN_ID
	AND A.SRNO =B.SRNO
	WHERE A.SP_ID=@CSPID

	 if @bAllowNegative=1 and exists(select top 1 'u' from WSL_BarcodeNormalized_upload a (nolock) WHERE A.SP_ID=@CSPID  AND ISNULL(a.ORG_PRODUCT_CODE,'')='')
	 begin
	    
		UPDATE B SET ORG_PRODUCT_CODE= A.PRODUCT_CODE
		FROM  sku A (nolock)
		JOIN WSL_BarcodeNormalized_upload B  (NOLOCK) ON LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))=B.PRODUCT_CODE 
		and a.mrp =isnull(b.mrp,0)
		WHERE B.SP_ID =@CSPID
		AND ISNULL(B.ORG_PRODUCT_CODE,'')='' and charindex('@',A.PRODUCT_CODE )>0
	

	 end

	lblList:

	IF EXISTS (select TOP 1' U' FROM WSL_BarcodeNormalized_upload A (NOLOCK) WHERE A.SP_ID=@CSPID AND ISNULL(A.ORG_PRODUCT_CODE,'')='')
	   SET @CERRMSG ='Stock Going Negative'

	if isnull(@CERRMSG,'')<>''
	begin
		SELECT Product_code, Org_product_code,
			  sum(DISCOUNT_AMOUNT) as DISCOUNT_AMOUNT,
			  count(*) as Quantity ,
			case when isnull(Org_product_code,'')='' then @CERRMSG else ''  end  AS ERRMSG,
			a.mrp,a.bin_id
		FROM WSL_BarcodeNormalized_upload A (NOLOCK)
		WHERE A.SP_ID=@CSPID
		group by Product_code,Org_product_code,a.mrp,a.bin_id
	end
	else
	begin

	  SELECT Product_code, Org_product_code,
			  sum(DISCOUNT_AMOUNT) as DISCOUNT_AMOUNT,
			  count(*) as Quantity ,
			 @CERRMSG AS ERRMSG,a.mrp,a.bin_id
		FROM WSL_BarcodeNormalized_upload A (NOLOCK)
		WHERE A.SP_ID=@CSPID
		group by Product_code,Org_product_code,a.mrp,a.bin_id

	end


END