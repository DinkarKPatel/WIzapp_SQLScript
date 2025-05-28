CREATE PROCEDURE SP3S_GET_MANUFACTURER_DETAILS
(
	@cAC_CODE VARCHAR(15)
)
AS
BEGIN
	select  a.*,c.ac_name,c1.ac_name AS SHIPPING_AC_NAME,
	ISNULL(lmp.ADDRESS0,'') + ' ' + ISNULL(lmp.ADDRESS1,'') + ' ' + ISNULL(lmp.ADDRESS2,'') + ', ' + ISNULL(area.area_name,'') + ' ' + ISNULL(CITY.CITY,'') + ' ' +   
	ISNULL(state.STATE,'') AS 'SHIPPING_ADDRESS',lmp.Ac_gst_no as SHIPPING_GST_NO,c.ALIAS
    from lm_shipping_details a   (NOLOCK)                          
    join LM01106 c  (NOLOCK) on a.ac_code= c.ac_code                        
    join LM01106 c1  (NOLOCK) on a.shipping_ac_code= c1.ac_code    
	LEFT OUTER JOIN lmp01106 lmp (NOLOCK)   ON lmp.AC_CODE=c1.AC_CODE
    LEFT OUTER JOIN FORM F  (NOLOCK)ON F.FORM_ID=lmp.FORM_ID
    LEFT OUTER JOIN AREA (NOLOCK) ON ( LMP.AREA_CODE = AREA.AREA_CODE )  
    LEFT OUTER JOIN CITY (NOLOCK) ON ( AREA.CITY_CODE = CITY.CITY_CODE )  
    LEFT OUTER JOIN STATE (NOLOCK) ON ( CITY.STATE_CODE = STATE.STATE_CODE )  
    LEFT OUTER JOIN REGIONM  (NOLOCK) ON STATE.REGION_CODE = REGIONM.REGION_CODE 
	WHERE a.ac_code=@cAC_CODE


--SELECT LM.alias,LM.AC_CODE, LM.AC_NAME, ISNULL(LMP.CREDIT_DAYS, 0) AS CREDIT_DAYS,   
--                            ISNULL(lmp.DISCOUNT_PERCENTAGE, 0) AS DISCOUNT_PERCENTAGE,  
--                            ISNULL(lmp.ADDRESS0,'') + ' ' + ISNULL(lmp.ADDRESS1,'') + ' ' + ISNULL(lmp.ADDRESS2,'') + ', ' + ISNULL(area.area_name,'') + ' ' + ISNULL(CITY.CITY,'') + ' ' +   
--                            ISNULL(state.STATE,'') AS 'SUPP_ADDRESS', AC_NAME AS REPCOLNAME ,LMP.FORM_ID ,ISNULL(F.FORM_NAME,'') as [FORM_NAME] , isnull(lmp.MP_PERCENTAGE,0) as MP_PERCENTAGE ,isnull(lmp.WP_PERCENTAGE,0) as WP_PERCENTAGE, 
--                            lmp.ADDRESS0 , lmp.ADDRESS1 , lmp.ADDRESS2, area.AREA_NAME , city.CITY ,state.STATE ,area.PINCODE , lm.Alias_to_be_suffixed
--							,ISNULL(LMP.PUR_CAL_METHOD,1) As PUR_CAL_METHOD,ISNULL(LMP.Restrict_pur_Entry,0) as Restrict_pur_Entry,BROKER_AC_CODE,ISNULL(LMP.DO_NOT_ALLOW_DIRECT_PUR,0) As DO_NOT_ALLOW_DIRECT_PUR
--                              ,ISNULL(TRADE_DISCOUNT_PERCENTAGE,0) AS TRADE_DISCOUNT_PERCENTAGE,lmp.Ac_gst_no,rcm_applicable
--                            FROM lm01106 LM   (NOLOCK)
--                            LEFT OUTER JOIN lmp01106 lmp (NOLOCK)   ON lmp.AC_CODE=lm.AC_CODE
--                            LEFT OUTER JOIN FORM F  (NOLOCK)ON F.FORM_ID=lmp.FORM_ID
--                            LEFT OUTER JOIN AREA (NOLOCK) ON ( LMP.AREA_CODE = AREA.AREA_CODE )  
--                            LEFT OUTER JOIN CITY (NOLOCK) ON ( AREA.CITY_CODE = CITY.CITY_CODE )  
--                            LEFT OUTER JOIN STATE (NOLOCK) ON ( CITY.STATE_CODE = STATE.STATE_CODE )  
--                            LEFT OUTER JOIN REGIONM  (NOLOCK) ON STATE.REGION_CODE = REGIONM.REGION_CODE    
--                            WHERE 1=2

END