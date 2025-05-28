CREATE PROCEDURE SAVETRAN_STOCKRECON  
(  
 @SPID varchar(40) ,
 @CFIN_YEAR varchar(5),
 @cLocId varchar(4)=''
)  
AS  
BEGIN  
	--changes by Dinkar in location id varchar(4)..
    Declare @NMEMONOLEN numeric(2,0),@CERRORMSG varchar(1000),@CMEMONOPREFIX varchar(5),@NSTEP numeric(5,0),
	        @CMEMONOVAL varchar(10),@CTEMPMASTERTABLENAME varchar(100),@CTEMPDETAILTABLENAME varchar(100),
			@CWHERECLAUSE varchar(100),@lotCountQty numeric(18,3),@ndet_QTY numeric(18,3),
			@nbeforesavedet_QTY numeric(18,3)

 BEGIN TRY  
 BEGIN TRANSACTION  

     SET @NMEMONOLEN=7
     SET @CERRORMSG=''
     SET @CMEMONOPREFIX=@cLocId

	 set @CTEMPMASTERTABLENAME='STOCKRECON_STLM01106_UPLOAD'
	 set @CTEMPDETAILTABLENAME='STOCKRECON_STLD01106_UPLOAD'

     SET @NSTEP=10
  LBLLOTNO:
  --GENERATING MEMO_NO  
  EXEC GETNEXTKEY  @CTABLENAME='STLM01106'  
      ,@CCOLNAME='LOT_NO'  
      ,@NWIDTH=@NMEMONOLEN  
      ,@CPREFIX=@CMEMONOPREFIX  
      ,@NLZEROS=1  
      ,@CFINYEAR=@CFIN_YEAR  
      ,@NROWCOUNT=0  
      ,@CNEWKEYVAL=@CMEMONOVAL OUTPUT  
      
      SET @NSTEP=20
      IF ISNULL(@CMEMONOVAL,'')='' 
      BEGIN
           SET @CERRORMSG='LOT NO GENERATION ERROR'
           GOTO END_PROC
      END
      
      IF EXISTS (SELECT TOP 1 'U' FROM STLM01106 WHERE LOT_NO =@CMEMONOVAL)
         GOTO LBLLOTNO

	  UPDATE A SET LOT_NO=@CMEMONOVAL FROM   STOCKRECON_STLM01106_UPLOAD A (nolock) WHERE SP_ID=@SPID
      UPDATE A SET LOT_NO=@CMEMONOVAL FROM   STOCKRECON_STLD01106_UPLOAD A (nolock) WHERE SP_ID=@SPID

	SELECT A.LOT_NO , a.PRODUCT_CODE,a.MRP,A.BIN_ID,
	       SUM(A.QUANTITY) AS QUANTITY
	into #tmpstld
	FROM STOCKRECON_STLD01106_UPLOAD A
	JOIN SKU_NAMES B ON A.PRODUCT_CODE=B.PRODUCT_CODE 
	WHERE B.SN_BARCODE_CODING_SCHEME =1 and isnull(b.sku_item_type ,0) in(0,1)
	and  SP_ID=@SPID and a.product_code not like '%@%'
    GROUP BY A.LOT_NO , a.PRODUCT_CODE,a.MRP,A.BIN_ID
    
    DECLARE @CREP_ID VARCHAR(100)
    
    select @CREP_ID=a.rep_id  from stmh01106  A (nolock) 
    join STOCKRECON_STLM01106_UPLOAD b on a.Memo_Id =b.Memo_Id
    WHERE b.SP_ID=@SPID

    IF ISNULL(@CREP_ID,'')=''
    BEGIN
        SET @CERRORMSG='RECONCILE MEMO NOT FOUND : '
        GOTO END_PROC
    
    END 
    
	--Remove in normalize which has no any batch barcode
	DELETE A  FROM #TMPSTLD A
	LEFT JOIN pmt01106  B (NOLOCK) ON A.PRODUCT_CODE =LEFT(B.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',B.PRODUCT_CODE)-1,-1),LEN(B.PRODUCT_CODE )))
	AND B.PRODUCT_CODE LIKE '%@%' AND B.REP_ID =@CREP_ID and b.DEPT_ID =@cLocId AND A.bin_id =B.BIN_ID 
	WHERE B.PRODUCT_CODE IS NULL
	
	
	
	
	
	select @nbeforesavedet_QTY=SUM(B.Quantity)  from STOCKRECON_STLD01106_UPLOAD b  WHERE b.SP_ID=@SPID
	
	if exists (select top 1 'U' from #tmpstld)
	begin

	   ;WITH Barcode_CTE  AS  
		(  
		  SELECT b.lot_no , b.product_code as barcode_wobatch,  a.product_code  ,
		         (isnull(a.STOCK_RECO_QUANTITY_IN_STOCK,0)-isnull(a.PhysicalScanQty ,0)) quantity_in_stock,b.Quantity,
				 b.mrp,a.bin_id  ,
				 SUBSTRING(A.PRODUCT_CODE, CHARINDEX('@',A.PRODUCT_CODE)+3,LEN(A.PRODUCT_CODE)) as batch_no,
				 SrNo =cast(0 as numeric(18,0))
		  FROM PMT01106 A (nolock)
		  join sku_names  (nolock) on a.product_code=sku_names.product_code
		  join #tmpstld b on LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))=b.product_code 
		  and sku_names.mrp=b.mrp and a.BIN_ID=b.bin_id 
		  where  (a.product_code like '%@%'  or (isnull(a.STOCK_RECO_QUANTITY_IN_STOCK,0)-isnull(a.PhysicalScanQty ,0)) >0)
		  and a.DEPT_ID =@cLocId AND A.rep_id =@CREP_ID
		 
		  
		 )  
		 
		 select * into #tmpbarcode from Barcode_CTE
		 
		 UPDATE #TMPBARCODE SET SRNO =0 WHERE PRODUCT_CODE NOT LIKE '%@%' AND SRNO<>0
		 UPDATE #TMPBARCODE SET SrNo =batch_no  WHERE  ISNUMERIC (batch_no)=1 and  product_code  like '%@%'

		 ;with cte as
		 (
		  select *,Sr=ROW_NUMBER () over (partition by barcode_wobatch order by SrNo ) from #TMPBARCODE
		 )
		 Update cte set SrNo =Sr  
		
		 
		

		  select a.lot_no, a.barcode_wobatch,a.product_code,a.mrp,a.bin_id,a.quantity_in_stock,a.Quantity,a.SrNo ,
				 SUM(b.quantity_in_stock) as cumm_sum,
				 cast(0 as numeric(10,3)) as StldQTY
		  into #tmpitem
		  from #TMPBARCODE A
		  join #TMPBARCODE b on a.barcode_wobatch =b.barcode_wobatch and a.mrp =b.mrp and a.BIN_ID =b.BIN_ID and b.SrNo <=a.SrNo 
		  group by a.lot_no,a.barcode_wobatch,a.product_code,a.mrp,a.bin_id,a.quantity_in_stock,a.Quantity,a.SrNo
         
        
      
		  delete a from #tmpitem A
		  where a.quantity_in_stock =0 and SrNo >1
		  
		  delete a from #tmpitem A
		  join
		  (
		   select a.barcode_wobatch,a.mrp,a.BIN_ID,a.quantity ,
				  min(srNo) as minsrno
		  from #tmpitem A
		   where cumm_sum >=quantity
		  group by a.barcode_wobatch,a.mrp,a.BIN_ID,a.quantity 
		 ) b on  a.barcode_wobatch =b.barcode_wobatch and a.mrp =b.mrp and a.BIN_ID =b.BIN_ID 
		 where a.SrNo >b.minsrno
		  
		  Update a set StldQTY =case when a.SrNo =b.maxsrno   then a.quantity -(a.cumm_sum -a.quantity_in_stock ) 
					   else a.quantity_in_stock end 
		  from #tmpitem A
		  join
		  (
		  select a.barcode_wobatch,a.mrp,a.BIN_ID,a.quantity ,
				  max(cumm_sum) as cumm_sum,
				  MAX(srNo) as maxsrno
		  from #tmpitem A
		  group by a.barcode_wobatch,a.mrp,a.BIN_ID,a.quantity 
		  having  max(cumm_sum)<=a.quantity 
		  ) b on a.barcode_wobatch =b.barcode_wobatch and a.mrp =b.mrp and a.BIN_ID =b.BIN_ID and a.SrNo <=b.maxsrno 
	  
	
		  Update a set StldQTY =case when quantity >=cumm_sum then quantity_in_stock
					   else quantity -(cumm_sum -quantity_in_stock ) end 
		  from  #tmpitem A
		  where quantity -(cumm_sum -quantity_in_stock )>0
		  and StldQTY=0

		  delete A  from STOCKRECON_STLD01106_UPLOAD A (nolock)
		  join #tmpstld b on a.product_code=b.PRODUCT_CODE and a.mrp=b.mrp and a.bin_id=b.bin_id 

		   INSERT STOCKRECON_STLD01106_UPLOAD	( bin_id, dept_id, lot_no, mrp, product_code, quantity, sp_id ) 
		   SELECT 	 A. BIN_ID, @cLocId DEPT_ID, A.LOT_NO, A.MRP, A.PRODUCT_CODE,A.STLDQTY QUANTITY,@SPID SP_ID 
		   FROM #TMPITEM A
		   WHERE STLDQTY>0


	  end


	  select @ndet_QTY=SUM(B.Quantity)  from STOCKRECON_STLD01106_UPLOAD b  WHERE b.SP_ID=@SPID
	  select @lotCountQty=A.lotCountQty from STOCKRECON_STLM01106_UPLOAD a WHERE A.SP_ID=@SPID
	  
	  
	  if isnull(@nbeforesavedet_QTY,0)<>isnull(@ndet_QTY,0) 
	  begin
	       SET @CERRORMSG='Qty mismatch in befor normalize : '+ RTRIM( LTRIM( STR(isnull(@nbeforesavedet_QTY,0)))) +
		                   'Barcode qty:'+ RTRIM( LTRIM( STR(isnull(@ndet_QTY,0))))
           GOTO END_PROC
	  end

	   if isnull(@lotCountQty,0)<>isnull(@ndet_QTY,0) and isnull(@lotCountQty,0)>0
	  begin
	       SET @CERRORMSG='Qty mismatch in lotqty: '+ RTRIM( LTRIM( STR(isnull(@lotCountQty,0)))) +
		                   'Barcode qty:'+ RTRIM( LTRIM( STR(isnull(@ndet_QTY,0))))
           GOTO END_PROC
	  end
	  
	  
	  IF EXISTS (SELECT TOP 1 'U'       
	  FROM STOCKRECON_STLD01106_UPLOAD A
	  LEFT JOIN PMT01106 B ON A.PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID AND B.DEPT_ID =@cLocId
	  WHERE    A.SP_ID=@SPID AND B.PRODUCT_CODE IS NULL)
	  BEGIN
	       
	      SELECT A.PRODUCT_CODE ,A.quantity,a.bin_id ,a.mrp ,'BARCODE NOT IN PMT....PLEASE CHECK' as errmsg
          FROM STOCKRECON_STLD01106_UPLOAD A
		  LEFT JOIN PMT01106 B ON A.PRODUCT_CODE =B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID AND B.DEPT_ID =@cLocId
		  WHERE    A.SP_ID=@SPID AND B.PRODUCT_CODE IS NULL
			  
		   SET @CERRORMSG='BARCODE NOT IN PMT....PLEASE CHECK'
      
	  
	  END
	  
	  Update a set PhysicalScanQty =ISNULL(a.PhysicalScanQty,0)+ c.quantity ,quantity_in_stock=ISNULL(a.quantity_in_stock,0)+ c.quantity
	  from   pmt01106 A (nolock)
	  join sku_names b (nolock) on a.product_code =b.product_Code 
	  join STOCKRECON_STLD01106_UPLOAD c (nolock) on a.product_code =c.product_code and c.bin_id =a.BIN_ID and c.mrp =b.mrp 
      where c.SP_ID=@SPID AND A.DEPT_ID =@cLocId
      
 
	  SET @CWHERECLAUSE = ' SP_ID='''+LTRIM(RTRIM(@SPID))+''''

	  EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN 
	  	@CSOURCEDB	= ''
		, @CSOURCETABLE = @CTEMPMASTERTABLENAME
		, @CDESTDB		= ''
		, @CDESTTABLE	= 'STLM01106'
		, @CKEYFIELD1	= 'Lot_no'
		, @BALWAYSUPDATE = 1
		,@CFILTERCONDITION=@CWHERECLAUSE
		,@LINSERTONLY=1
		,@LUPDATEXNS=1
	

		 EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN 
	  	@CSOURCEDB	= ''
		, @CSOURCETABLE = @CTEMPDETAILTABLENAME
		, @CDESTDB		= ''
		, @CDESTTABLE	= 'STLD01106'
		, @CKEYFIELD1	= 'product_code'
		, @BALWAYSUPDATE = 1
		,@CFILTERCONDITION=@CWHERECLAUSE
		,@LINSERTONLY=1
		,@LUPDATEXNS=1
		
		if not  exists (select top 1 'u' from STLD01106 where lot_no =@CMEMONOVAL)
		begin
		     SET @CERRORMSG='BLANK DETAILS CAN NOT BE SAVED ....PLEASE CHECK'
		end 




 END TRY  
 BEGIN CATCH  
   SET @CERRORMSG = 'Procedure SAVETRAN_STOCKRECON STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()  
 END CATCH  
   
END_PROC:  

 IF @@TRANCOUNT>0  
 BEGIN  
	  IF ISNULL(@CERRORMSG,'') = ''  
	   BEGIN  
		COMMIT TRANSACTION  
	   END  
	  ELSE  
	  BEGIN  
		ROLLBACK  
	  END  
 END  

 select  @CERRORMSG As Errmsg,@CMEMONOVAL as LOT_NO

 DELETE A FROM STOCKRECON_STLM01106_UPLOAD A (nolock) where sp_id=@SPID
 DELETE A FROM STOCKRECON_STLd01106_UPLOAD A (nolock) where sp_id=@SPID
 
END   
