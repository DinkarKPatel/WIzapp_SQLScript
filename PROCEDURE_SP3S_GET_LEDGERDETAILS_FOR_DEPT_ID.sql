CREATE PROCEDURE SP3S_GET_LEDGERDETAILS_FOR_DEPT_ID  
(  
 @cdept_id VARCHAR(10)  
)  
AS  
BEGIN  
DECLARE @cAC_CODE VARCHAR(50)  
--DECLARE @cdept_id VARCHAR(10)  
--SELECT @cdept_id='JM'  
select @cAC_CODE =ac_code from lm01106(NOLOCK) where ac_name =(select dept_name+'('+dept_alias+')' from location(NOLOCK) where dept_id=@cdept_id)  
  
IF ISNULL(@cAC_CODE,'')<>''  
BEGIN  
 SELECT * FROM LMV01106(NOLOCK) WHERE AC_CODE=@cAC_CODE  
END  
ELSE  
BEGIN  
 select '' AS contact_person_name,isnull(NULL,0) AS hold_for_payment,rc.COUNTRY_CODE,rc.country_name,region_name,r.region_code,isnull(NULL,'') AS hsn_code,a.gst_state_code,     
 gst.gst_state_code + ' ' + gst.gst_state_name as gst_state_name,loc_gst_no ac_gst_no,'' WhatsApp_no,0 DO_NOT_ALLOW_DIRECT_PUR,'' ac_code,a.dept_name+'('+a.dept_alias+')' ac_name,   
 a.dept_alias as alias,a.dept_name+'('+a.dept_alias+')' print_name  
 ,'' shipping_address,''shipping_address2,'' shipping_address3,'' address0,b.Head_code,isnull(NULL,1) as INV_RATE_TYPE,   
 a.address1,a.address2,  b1.area_name, C.city, d.state, b1.pincode, a.cst_no,   
 '' sst_no, a.tin_no,a.pan_no, a.phone phones_o, a.phone phones_r,    
 ISNULL(NULL,'0000000000') AS broker_ac_code,isnull(NULL,0)as bill_by_bill,C.city_code,a.area_code,'01' company_code,    
 isnull( NULL,0)as allow_creditor_debtor, ISNULL(NULL,0) as inactive,   
 isnull(NULL,1) as wsl_rate_calc_method,    
 isnull(NULL,0)as outstation_party,b.physical,isnull(NULL,0)as SHARE_WITH_WH,  
 isnull(NULL,0)as SHARE_WITH_COMPANY_OWNED_POS,isnull(NULL,0)as SHARE_WITH_FRANCHISE_CONSIGNEE,   
 isnull(NULL,0)as SHARE_WITH_FRANCHISE_OUTRIGHT,    
 a.cst_dt as cst_dt,    
 isnull(registered_gst,0) AS registered_gst_dealer,    
 --'' as dpwef_dt,    
 b.head_name  
 from location a (NOLOCK)    
 join hd01106 b (NOLOCK) on '0000000018'=b.Head_code    
 join area b1(NOLOCK) on a.area_code = b1.area_code   
 join CITY c (NOLOCK)on b1.city_code = c.CITY_CODE   
 join state d (NOLOCK)on c.state_code = d.state_code   
 Left outer join regionm r (NOLOCK)on d.region_code = r.region_code   
 Left outer join country rc (NOLOCK)on r.country_code = rc.country_code   
 left outer JOIN gst_state_mst gst (NOLOCK) on a.gst_state_code=gst.gst_state_code    
 where a.dept_id =@cdept_id  
END  
END
