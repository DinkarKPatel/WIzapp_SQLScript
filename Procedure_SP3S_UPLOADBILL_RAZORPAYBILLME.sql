CREATE PROCEDURE SP3S_UPLOADBILL_RAZORPAYBILLME
(
	@cCM_ID		VARCHAR(50)
)
AS
BEGIN
select A.location_Code,A.CM_NO,A.cm_dt,A.cm_time, A.cm_id,A.fin_year,fin_year,
A.SUBTOTAL,A.DT_CODE,A.DISCOUNT_PERCENTAGE,A.DISCOUNT_AMOUNT,A.NET_AMOUNT,A.CUSTOMER_CODE,A.CANCELLED,A.USER_CODE,A.atd_charges,A.round_off,A.cash_tendered,
A.payback,A.gst_round_off,A.REMARKS,A.Party_Gst_No,A.ACH_NO,A.ACH_DT,A.IRN_QR_CODE,A.EINV_IRN_NO,A.DELIVERY_MODE,A.SUPPLY_TYPE_CODE,
A.TOTAL_MRP_VALUE,A.TOTAL_DISCOUNT,A.TOTAL_GST_AMOUNT,

A.CUSTOMER_CODE,B.user_customer_code,B.dt_birth,B.dt_anniversary,B.area_code,address0,cus_gst_no,cus_gst_state_code,address9,customer_title,customer_fname,
customer_lname,address1,address2,phone1,phone2,mobile,email,gender,panNo,ar.area_name,st.state,cnt.COUNTRY_NAME,ar.pincode,ct.CITY
FROM CMM01106 A
JOIN custdym B On B.customer_code=A.CUSTOMER_CODE
LEFT OUTER JOIN area ar ON ar.area_code=B.area_code
LEFT OUTER JOIN CITY ct on ct.CITY_CODE=ar.city_code
LEFT OUTER JOIN state st on ct.state_code=st.state_code
LEFT OUTER JOIN COUNTRY cnt on cnt.COUNTRY_CODE=st.company_code
WHERE A.cm_id=@cCM_ID

SELECT B.para3_name AS brand,
                        B.para1_name colour , B.para2_name size ,B.para3_name AS style,
                        B.sn_article_desc [description],
                        li.discount_amount discount  ,
						li.discount_percentage discount_percent  ,
                        '' discount_description ,
                        li.hsn_code ,
                        '' image_url ,
                        B.sub_section_name AS [name],
                        li.product_code ,
                        li.PRODUCT_CODE product_uid ,
                        li.quantity,
                        li.CGST_AMOUNT AS taxes_name_CGST ,
						li.SGST_AMOUNT AS taxes_name_SGST ,
						li.IGST_AMOUNT AS taxes_name_IGST ,
						li.GST_PERCENTAGE AS TAX_PERCENT,
                        li.net total_amount ,
                        B.uom unit /*Possible values: kg | g | mg | lt | ml | pc | cm | m | in | ft | set*/,
                        Li.MRP unit_amount ,
						emp.emp_code as empcode,
						emp1.emp_code as empcode1,
						emp2.emp_code as empcode2,
						emp.emp_name as emp,
						emp1.emp_name as emp1,
						emp2.emp_name as emp2,
						(li.mrp * li.QUANTITY) as sub_total_amount
						
            
FROM CMD01106 li 
JOIN SKU_NAMES B ON B.product_Code=lI.PRODUCT_CODE 
JOIN employee emp ON emp.emp_code=li.emp_code
JOIN employee emp1 ON emp1.emp_code=li.emp_code1
JOIN employee emp2 ON emp2.emp_code=li.emp_code2
WHERE li.cm_id=@cCM_ID


SELECT A.amount,A.paymode_code,c.paymode_name,A.ref_no,A.REMARKS
FROM PAYMODE_XN_DET A
JOIN CMM01106 B On B.cm_id=A.memo_id AND A.xn_type='SLS'
JOIN paymode_mst C ON C.paymode_code=A.paymode_code
WHERE B.cm_id=@cCM_ID

END