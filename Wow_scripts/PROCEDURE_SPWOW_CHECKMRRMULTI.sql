
create   PROCEDURE SPWOW_CHECKMRRMULTI
( 
 @cFromDate varchar(10),
 @cToDate Varchar(10),
 @cSupplierName Varchar(100),
 @coemName Varchar(100),
 @cWhere Varchar(max)
)
As
 Begin


 DROP table IF EXISTS ##tmpProduct 


 Declare @cCmd nvarchar(Max) 
  --Summary
  set @cCmd= '  
 Select  a.product_Code,a.mrr_id,c.ac_name as partyName,isnull(d.ac_name,'''')  as oemSupplier,
 convert(varchar,b.MRR_DT ,106) as mrrDate,b.total_amount as mrrAmount
 into ##tmpProduct 
 From pid01106  a  (Nolock) 
 join pim01106 b (Nolock) on a.mrr_id = b.mrr_id 
 Join lm01106 c (nolock) on b.ac_code = c.ac_code
 Left outer Join lm01106 d (nolock) on b.OEM_AC_CODE  = d.ac_code
 Left outer join sku_names on a.product_code= sku_names.product_code
 where b.mrr_dt between '''+@cFromDate+''' and  '''+@cToDate+'''  and b.CANCELLED =0 and b.INV_MODE=1 
 And (c.ac_name='''+@cSupplierName+'''  or  '''+@cSupplierName+'''='''') and (d.AC_NAME = '''+@coemName+''' or '''+@coemName+''' = '''' )
 AND '+@cWhere +' '
 
 PRINT @cCmd  
 EXEC SP_EXECUTESQL @cCmd  
 --Select * from ##tmpproduct

 Select  partyName, oemSupplier,mrrDate , mrrAmount ,
 Sum(purQty) as purQty,Sum(prtQty) as prtQty,Sum(slsQty) as slsQty,
 Sum(slrQty) as slrQty, Sum(stockQty) as stockQty, sum(saleValue) as saleValue, cast(sum(pp)as numeric(10,2)) as purchaseValue,
 cast(sum(saleValue)-SUM(pp)  as numeric(14,2)) as  profit,
  cast(((sum(saleValue)-SUM(pp)  )/ SUM(pp+0.0001)) * 100  as numeric(14,2)) as  profitpercentage,
 cast((sum(DISCAMT)/sum(MRPVALUE+0.0001))*100  as numeric(14,2)) as discountPercenatage,
 cast(sum(saleAgeing) as numeric(10,0))  as saleAgeing,
 cast(sum(stockAgeing)  as numeric(10,0) ) as stockAgeing,
 cast(sum(shelfAgeing) as numeric(10,0)) as shelfAgeing,
case when (sum(SLSqty)- sum(slrqty)) >0 then  cast((sum(SLSqty)- sum(slrqty)) /( (sum(SLSqty)- sum(slrqty)) + sum(stockQty)) * 100 as numeric(14,2)) else 0 end as saleThru ,
case when sum(isnull(saleAgeing,0)) >0 and (Sum(slsQty)-sum(slrQty))>0 then  cast(sum(saleAgeing) * Sum(stockQty)/ (Sum(slsQty)-sum(slrQty))  as numeric(14,0)) else 0 end  as daysofStock


 From
 (
 Select   partyName, oemSupplier, b.mrrDate , b.mrrAmount ,   sum(a.Quantity) as purQty, cast(0 as numeric(10,2)) as prtQty, cast(0 as numeric(10,2)) as slsQty,
 cast(0 as numeric(10,2)) as slrQty,cast(0 as numeric(10,2)) as stockQty,
 cast(0 as numeric(10,2)) as saleValue, cast(0 as numeric(10,2)) as pp,
cast(0 as numeric(10,2)) as saleAgeing,
 cast(0 as numeric(10,2)) as stockAgeing,cast(0 as numeric(10,2)) as shelfAgeing,cast(0 as numeric(10,2)) as saleThru,
 cast(0 as numeric(10,2)) as daysofStock,cast(0 as numeric(10,2))  as  DISCAMT, cast(0 as numeric(10,2))  as  MRPVALUE
 From pid01106 a join ##tmpproduct  b on a.product_code = b.product_code and  a.mrr_id = b.mrr_id 
 group by partyName, oemSupplier,b.mrrDate , b.MrrAmount 

 UNION ALL

 Select   partyName, oemSupplier,b.mrrdate, b.mrramount,cast(0 as numeric(10,2))  as purQty, sum(a.quantity) as prtQty, cast(0 as numeric(10,2)) as slsQty,
 cast(0 as numeric(10,2)) as slrQty,cast(0 as numeric(10,2)) as stockQty,
 cast(0 as numeric(10,2)) as saleValue,cast(0 as numeric(10,2)) as pp,
 cast(0 as numeric(10,2)) as saleAgeing,
 cast(0 as numeric(10,2)) as stockAgeing,cast(0 as numeric(10,2)) as shelfAgeing,cast(0 as numeric(10,2)) as saleThru,
 cast(0 as numeric(10,2)) as daysofStock ,cast(0 as numeric(10,2))  as  DISCAMT, cast(0 as numeric(10,2))  as  MRPVALUE
 From rmd01106 a  
 join rmm01106 c on a.rm_id= c.rm_id 
 join ##tmpproduct  b on a.product_code = b.product_code 
 where c.CANCELLED = 0 and c.mode =1 
  group by partyName, oemSupplier,b.mrrdate, b.mrramount

 UNION ALL
 
  Select   partyName, oemSupplier,b.mrrdate, b.mrramount, cast(0 as numeric(10,2))  as purQty, cast(0 as numeric(10,2)) as prtQty, sum(a.quantity) as slsQty,
              cast(0 as numeric(10,2)) as slrQty,cast(0 as numeric(10,2)) as stockQty,sum(a.xn_value_with_gst) as saleValue, 
			  SUM(A.QUANTITY*e.PP) as pp,	Avg(selling_days) as saleAgeing,
 cast(0 as numeric(10,2)) as stockAgeing,cast(0 as numeric(10,2)) as shelfAgeing,cast(0 as numeric(10,2)) as saleThru,
 cast(0 as numeric(10,2)) as daysofStock, 
 SUM(A.DISCOUNT_AMOUNT+A.CMM_DISCOUNT_AMOUNT) AS DISCAMT,
 SUM(A.QUANTITY*A.MRP) AS MRPVALUE
 From cmd01106  a
  join cmm01106 c on a.cm_id= c.cm_id 
 join ##tmpproduct  b on a.product_code = b.product_code 
 Join Sku_names e on b.product_code= e.product_code
 where QUANTITY >0    and c.CANCELLED =0
  group by partyName, oemSupplier,b.mrrdate, b.mrramount


 UNION ALL

 Select   partyName, oemSupplier,b.mrrdate, b.mrramount, cast(0 as numeric(10,2))  as purQty, cast(0 as numeric(10,2)) as prtQty, sum(a.quantity) as slsQty,
 cast(0 as numeric(10,2)) as slrQty,cast(0 as numeric(10,2)) as stockQty,
 sum(a.xn_value_with_gst) as saleValue,    SUM(A.QUANTITY*e.PP) as pp,
 Avg(wsl_selling_days) as saleAgeing,
 cast(0 as numeric(10,2)) as stockAgeing,cast(0 as numeric(10,2)) as shelfAgeing,cast(0 as numeric(10,2)) as saleThru,
 cast(0 as numeric(10,2)) as daysofStock, cast(0 as numeric(10,2))  as  DISCAMT, cast(0 as numeric(10,2))  as  MRPVALUE
 From ind01106  a
  join inm01106 c on a.inv_id= c.inv_id 
 join ##tmpproduct  b on a.product_code = b.product_code 
  Join Sku_names e on b.product_code= e.product_code
  where c.CANCELLED = 0 and c.inv_mode =1 
   group by partyName, oemSupplier,b.mrrdate, b.mrramount
 
  UNION ALL
 Select   partyName, oemSupplier,b.mrrdate, b.mrramount, cast(0 as numeric(10,2))  as purQty, cast(0 as numeric(10,2)) as prtQty, cast(0 as numeric(10,2)) as slsQty,
 sum(abs(quantity)) as slrQty,cast(0 as numeric(10,2)) as stockQty,
 sum(a.xn_value_with_gst) as saleValue, SUM(A.QUANTITY*e.PP) as pp,
--avg(a.selling_days) as saleAgeing,
 cast(0 as numeric(10,2)) as saleAgeing,
 cast(0 as numeric(10,2)) as stockAgeing,cast(0 as numeric(10,2)) as shelfAgeing,cast(0 as numeric(10,2)) as saleThru,
 cast(0 as numeric(10,2)) as daysofStock,SUM(A.DISCOUNT_AMOUNT+A.CMM_DISCOUNT_AMOUNT) AS DISCAMT,
 SUM(A.QUANTITY*A.MRP) AS MRPVALUE
 From cmd01106  a 
  join cmm01106 c on a.cm_id= c.cm_id 
  join ##tmpproduct  b on a.product_code = b.product_code 
   Join Sku_names e on b.product_code= e.product_code
  where QUANTITY <0    and c.CANCELLED =0
   group by partyName, oemSupplier,b.mrrdate, b.mrramount
 
 UNION ALL
 Select   partyName, oemSupplier,b.mrrdate, b.mrramount, cast(0 as numeric(10,2))  as purQty, cast(0 as numeric(10,2)) as prtQty, cast(0 as numeric(10,2)) as slsQty,
 sum(abs(a.quantity)) as slrQty,cast(0 as numeric(10,2)) as stockQty,
 sum(a.xn_value_with_gst) as saleValue,  SUM(A.QUANTITY*e.PP) as pp,		  
cast(0 as numeric(10,2)) as saleAgeing,
 cast(0 as numeric(10,2)) as stockAgeing,cast(0 as numeric(10,2)) as shelfAgeing,cast(0 as numeric(10,2)) as saleThru,
 cast(0 as numeric(10,2)) as daysofStock,cast(0 as numeric(10,2))  as  DISCAMT, cast(0 as numeric(10,2))  as  MRPVALUE
 From cnd01106  a
   join cnm01106 c on a.cn_id= c.cn_id 
 join ##tmpproduct  b on a.product_code = b.product_code 
  Join Sku_names e on b.product_code= e.product_code
  where c.CANCELLED = 0 and c.mode =1 
 group by partyName, oemSupplier,b.mrrdate, b.mrramount

 UNION ALL

 Select  partyName, oemSupplier,b.mrrdate, b.mrramount, cast(0 as numeric(10,2))  as purQty, cast(0 as numeric(10,0)) as prtQty, cast(0 as numeric(10,2)) as slsQty,
 cast(0 as numeric(10,2)) as slrQty,sum(quantity_in_stock ) as stockQty,cast(0 as numeric(10,0))as saleValue, 
cast(0 as numeric(10,0)) as  PP,
cast(0 as numeric(10,2)) as saleAgeing,
avg(purchase_ageing_days ) as stockAgeing,avg(shelf_ageing_days )  as shelfAgeing,cast(0 as numeric(10,2)) as saleThru,
 cast(0 as numeric(10,2)) as daysofStock,cast(0 as numeric(10,2))  as  DISCAMT, cast(0 as numeric(10,2))  as  MRPVALUE
 From pmt01106 a join ##tmpproduct  b on a.product_code = b.product_code  where  quantity_in_stock >0
 group by partyName, oemSupplier,b.mrrdate, b.mrramount
 ) a  group by partyName, oemSupplier, mrrDate , MrrAmount 

 --Detail
 Select transactionType,partyName, transactionNo,transactioDt,productCode,sum(transactionQty) as transactionQty ,
           cast(transactionRate as numeric(10,2)) as transactionRate ,   cast(sum(trasactionValue) as numeric(10,2)) as trasactionValue,barcodeImgId ,
		   purchasePrice,Mrp
  From
 (
	 Select  'PUR' as transactionType ,c.ac_name as partyName,Mrr_no as transactionNo, convert(varchar,mrr_dt,106) as transactioDt, 
	 d.product_code as productCode,a.purchase_price as transactionRate,sum(Quantity) as TransactionQty,
	 sum(Quantity*a.purchase_price) as TrasactionValue,e.barcode_img_id as barcodeImgId,e.pp as purchasePrice, e.MRP
	 From pid01106 a (NOLOCK)
	 Join pim01106 b (NOLOCK) on a.mrr_id = b.mrr_id  
	 Join lm01106 c (NOLOCK) on b.ac_code = c.AC_CODE 
	  join ##tmpproduct  d on a.product_code = d.product_code  and  a.mrr_id = d.mrr_id 
	  join sku_names e (NOLOCK) on d.product_code = e.product_Code 
	  group by   c.ac_name ,Mrr_no , b.mrr_dt ,e.barcode_img_id, d.product_code,a.purchase_price ,e.pp , e.MRP

	  UNION ALL

	 Select  'PRT' as TransactionType ,c.ac_name as partyName,rm_no as TransactionNo, convert(varchar,rm_dt,106) as TransactioDt, 
	  d.product_code as productCode,a.purchase_price as transactionRate,sum(Quantity) as TransactionQty,
	--  sum(rfnet) as TrasactionValue,
	 sum(Quantity*a.purchase_price) as TrasactionValue,
	  e.barcode_img_id as barcodeImgId ,e.pp as purchasePrice, e.MRP
	 From rmd01106 a (NOLOCK)
	 Join rmm01106 b (NOLOCK) on a.rm_id = b.rm_id  
	 Join lm01106 c (NOLOCK)  on b.ac_code = c.AC_CODE 
	  join ##tmpproduct  d on a.product_code = d.product_code  
	  join sku_names e (NOLOCK) on d.product_code = e.product_Code 
	  WHERE B.MODE=1 AND B.CANCELLED =0
	  group by   c.ac_name ,rm_no , b.rm_dt ,e.barcode_img_id ,d.product_code,a.purchase_price,e.pp , e.MRP

      UNION ALL

	 Select  'SLS' as TransactionType ,c.customer_fname + ' ' + customer_lname  as partyName,cm_no as TransactionNo, 
	 convert(varchar,cm_dt,106) as TransactioDt,   d.product_code as productCode,a.mrp as transactionRate ,
	 sum(Quantity) as TransactionQty,sum(a.QUANTITY * a.mrp) as TrasactionValue,e.barcode_img_id as barcodeImgId,
	 e.pp as purchasePrice, e.MRP
	 From cmd01106 a 
	 Join cmm01106 b on a.cm_id = b.cm_id  
	 Join custdym c on b.CUSTOMER_CODE = c.customer_code  
	  join ##tmpproduct  d on a.product_code = d.product_code  
	  join sku_names e on d.product_code = e.product_Code 
	   WHERE  B.CANCELLED =0 AND A.QUANTITY >0
	  group by   c.customer_fname + ' ' + customer_lname ,cm_no , b.cm_dt ,e.barcode_img_id ,d.product_code,a.mrp,e.pp , e.MRP

	  UNION ALL

	  Select  'SLS' as TransactionType ,c.ac_name as partyName,inv_no as TransactionNo, convert(varchar,inv_dt,106) as TransactioDt, 
	  d.product_code as productCode,a.rate as transactionRate ,sum(Quantity) as TransactionQty,
	  sum(a.QUANTITY * a.rate) as TrasactionValue,e.barcode_img_id as barcodeImgId,e.pp as purchasePrice, e.MRP
	 From ind01106 a (NOLOCK)
	 Join inm01106 b (NOLOCK) on a.inv_id = b.inv_id  
	 Join lm01106 c (NOLOCK)  on b.ac_code = c.AC_CODE 
	  join ##tmpproduct  d on a.product_code = d.product_code  
	  join sku_names e (NOLOCK) on d.product_code = e.product_Code 
	  WHERE B.inv_mode=1 AND B.CANCELLED =0
	  group by   c.ac_name ,inv_no , b.inv_dt ,e.barcode_img_id ,d.product_code,a.rate,e.pp , e.MRP


	   UNION ALL

	 Select  'SLR' as TransactionType ,c.customer_fname + ' ' + customer_lname  as partyName,cm_no as TransactionNo, 
	 convert(varchar,cm_dt,106) as TransactioDt,   d.product_code as productCode,a.mrp as transactionRate ,
	 sum(Quantity) as TransactionQty,sum(a.QUANTITY * a.mrp) as TrasactionValue,e.barcode_img_id as barcodeImgId,
	 e.pp as purchasePrice, e.MRP
	 From cmd01106 a 
	 Join cmm01106 b on a.cm_id = b.cm_id  
	 Join custdym c on b.CUSTOMER_CODE = c.customer_code  
	  join ##tmpproduct  d on a.product_code = d.product_code  
	  join sku_names e on d.product_code = e.product_Code 
	   WHERE  B.CANCELLED =0 AND A.QUANTITY <0
	  group by   c.customer_fname + ' ' + customer_lname ,cm_no , b.cm_dt ,e.barcode_img_id ,d.product_code,a.mrp,e.pp , e.MRP

	  UNION ALL

	  Select  'SLR' as TransactionType ,c.ac_name as partyName,cn_no as TransactionNo, 
	  convert(varchar,cn_dt,106) as TransactioDt, d.product_code as productCode,a.RATE as transactionRate ,
	 sum(Quantity) as TransactionQty,sum(a.quantity*a.rate) as TrasactionValue,e.barcode_img_id as barcodeImgId ,
	 e.pp as purchasePrice, e.MRP
	 From cnd01106 a (NOLOCK)
	 Join cnm01106 b (NOLOCK) on a.cn_id = b.cn_id  
	 Join lm01106 c (NOLOCK)  on b.ac_code = c.AC_CODE 
	  join ##tmpproduct  d on a.product_code = d.product_code  
	  join sku_names e (NOLOCK) on d.product_code = e.product_Code 
	  WHERE B.mode=1 AND B.CANCELLED =0
	  group by   c.ac_name ,cn_no , b.cn_dt ,e.barcode_img_id ,d.product_code,a.rate,e.pp , e.MRP

  ) a
  group by transactionType,partyName, transactionNo,transactioDt,barcodeImgId  ,productCode, transactionRate,purchasePrice,MRP
  order by transactioDt,transactionNo

  --Stock

	Select   e.product_code as productCode,e.pp as purchasePrice, e.Mrp,sum(Quantity) as purQty,sum(p.quantity_in_stock) as stockQty,
	e.barcode_img_id as barcodeImgId
	From pid01106 a (NOLOCK)
	Join pim01106 b (NOLOCK) on a.mrr_id = b.mrr_id  	 
	join ##tmpproduct  d on a.product_code = d.product_code  and  a.mrr_id = d.mrr_id 
	join sku_names e (NOLOCK) on d.product_code = e.product_Code 
	join pmt01106  p on d.product_code = p.product_code 	 and p.quantity_in_stock >0
	group by  e.product_code, e.pp,e.barcode_img_id,e.mrp

 End