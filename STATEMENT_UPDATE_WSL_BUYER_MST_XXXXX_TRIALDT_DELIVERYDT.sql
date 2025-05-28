
 IF NOT EXISTS(SELECT ORDER_ID FROM wsl_order_mst WHERE ORDER_ID='XXXXX')
 BEGIN
	 INSERT wsl_order_mst	( ac_code, approved, CANCELLED,order_id,total_amount,last_update,company_code,user_code,fin_year,DELIVERY_DT,dept_id,CHECKED_BY,
	 sent_BY,sent,tax_percentage,freight,round_off,tax_amount,edt_user_code,order_no,order_dt)
	 SELECT '0000000000',	1,	1	,'XXXXX',0,getdate(),'01','0000000','','','','','',0,0,0,0,0,'0000000','',''
 END
 

UPDATE A SET a.item_trial_dt=c.trail_dt
FROM WSL_ORDER_DET A 
JOIN WSL_ORDER_MST C ON C.order_id=A.order_id
where ISNULL(a.item_trial_dt,'')=''

UPDATE A SET a.item_delivery_dt=c.DELIVERY_DT
FROM WSL_ORDER_DET A 
JOIN WSL_ORDER_MST C ON C.order_id=A.order_id
where ISNULL(a.item_delivery_dt,'')=''
