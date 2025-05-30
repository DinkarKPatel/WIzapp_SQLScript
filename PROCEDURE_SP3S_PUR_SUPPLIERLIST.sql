CREATE PROCEDURE SP3S_PUR_SUPPLIERLIST
(
@CACNAME		VARCHAR(MAX)
) 
AS
BEGIN
	DECLARE @CHEADCODE VARCHAR(MAX)
	SET @CHEADCODE=DBO.FN_ACT_TRAVTREE('0000000021')
	SELECT TOP 50 LM.ALIAS,LM.AC_CODE, LM.AC_NAME, ISNULL(LMP.CREDIT_DAYS, 0) AS CREDIT_DAYS,   
	ISNULL(LMP.DISCOUNT_PERCENTAGE, 0) AS DISCOUNT_PERCENTAGE,  
	ISNULL(LMP.ADDRESS0,'') + ' ' + ISNULL(LMP.ADDRESS1,'') + ' ' + ISNULL(LMP.ADDRESS2,'') + ', ' + ISNULL(AREA.AREA_NAME,'') + ' ' + ISNULL(CITY.CITY,'') + ' ' +   
	ISNULL(STATE.STATE,'') AS 'SUPP_ADDRESS', AC_NAME AS REPCOLNAME ,LMP.FORM_ID ,ISNULL(F.FORM_NAME,'') AS [FORM_NAME] , 
	LMP.MP_PERCENTAGE,LMP.WP_PERCENTAGE,  
	LMP.ADDRESS0 , LMP.ADDRESS1 , LMP.ADDRESS2, AREA.AREA_NAME , CITY.CITY ,STATE.STATE ,AREA.PINCODE , LM.ALIAS_TO_BE_SUFFIXED
	,ISNULL(LMP.PUR_CAL_METHOD,1) AS PUR_CAL_METHOD 
	,ISNULL(LMP.RESTRICT_PUR_ENTRY,0) AS RESTRICT_PUR_ENTRY,BROKER_AC_CODE,
	ISNULL(LMP.PURCHASE_AGAINST_TERMS,0) AS [PURCHASE_AGAINST_TERMS],
	ISNULL(LMP.EOSS_DISCOUNT_SHARE,0) AS [EOSS_DISCOUNT_SHARE],
    ISNULL(LMP.EOSS_DISCOUNT_PER,0) AS [EOSS_DISCOUNT_PER],
    ISNULL(LMP.DO_NOT_ALLOW_DIRECT_PUR,0) AS DO_NOT_ALLOW_DIRECT_PUR,STATE.STATE_CODE
    ,ISNULL(TRADE_DISCOUNT_PERCENTAGE,0) AS TRADE_DISCOUNT_PERCENTAGE,LMP.Ac_gst_no,rcm_applicable
	,ISNULL(LMP.ON_HOLD,0) AS ON_HOLD,ISNULL(LMP.fc_code,'0000000') AS FC_CODE,FC.FC_NAME,FC.FC_RATE 
	,ISNULL(LMP.mp_calc_based_on,1) AS mp_calc_based_on,LMP.registered_gst_dealer,lmp.ac_gst_state_code
	FROM LM01106 LM   
	LEFT OUTER JOIN LMP01106 LMP   ON LMP.AC_CODE=LM.AC_CODE
	LEFT OUTER JOIN FORM F ON F.FORM_ID=LMP.FORM_ID
	LEFT OUTER JOIN AREA ON ( LMP.AREA_CODE = AREA.AREA_CODE )  
	LEFT OUTER JOIN CITY ON ( AREA.CITY_CODE = CITY.CITY_CODE )  
	LEFT OUTER JOIN STATE ON ( CITY.STATE_CODE = STATE.STATE_CODE )  
	LEFT OUTER JOIN REGIONM  ON STATE.REGION_CODE = REGIONM.REGION_CODE   
	LEFT OUTER JOIN FC  ON FC.FC_CODE = LMP.FC_CODE    
	WHERE  ( CHARINDEX ( HEAD_CODE, @CHEADCODE ) > 0  OR ALLOW_CREDITOR_DEBTOR = 1 )   
	AND LM.INACTIVE = 0   AND LM.AC_NAME <> ''
	--AND ISNULL(LM.SOR_party,0) <> 1 --as per Aurn sir
	AND ISNULL(@CACNAME ,'')  <>'' AND ((LM.AC_NAME LIKE @CACNAME  OR LM.ALIAS LIKE @CACNAME ))
	ORDER BY AC_NAME,AC_CODE
END
