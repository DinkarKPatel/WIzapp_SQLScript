CREATE PROCEDURE SP3S_WSL_CUST_LIST
AS
BEGIN

DECLARE @CHEADCODESTR VARCHAR(MAX)
SELECT @CHEADCODESTR = DBO.FN_ACT_TRAVTREE('0000000018')
SELECT LMV.AC_CODE, LMV.AC_NAME,LMP.ADDRESS0,
LMP.ADDRESS1,LMP.ADDRESS2, AREA_NAME , LMC.CITY, LMS.[STATE],LMA.PINCODE,
ISNULL(LMP.DISCOUNT_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE,LMP.INV_RATE_TYPE,LMP.FORM_ID, 
ISNULL(LMP.DEFAULT_RATE_TYPE,1) AS DEFAULT_RATE_TYPE,LMP.BROKER_AC_CODE,LMP.RESTRICT_PUR_ENTRY,
ISNULL(LMP.WSL_RATE_CALC_METHOD,1)AS WSL_RATE_CALC_METHOD
,ISNULL(B.MBO_COUNTER,0) AS MBO_COUNTER
,ISNULL(B.BIN_ID,'') AS BIN_ID
,ISNULL(B.BIN_NAME,'') AS BIN_NAME
,ISNULL(B.BIN_ALIAS,'') AS BIN_ALIAS,CREDIT_DAYS,
ISNULL(LMP.PURCHASE_AGAINST_TERMS,0) AS [PURCHASE_AGAINST_TERMS],
ISNULL(ON_HOLD,0) AS ON_HOLD,LMP.ANGADIA_CODE,ANG.ANGADIA_NAME,LMS.STATE_CODE
,ISNULL(RATE_MST.TAX_METHOD,1) AS TAX_METHOD ,ISNULL(LMP.ON_HOLD,0) AS ON_HOLD  
,LMP.Ac_gst_no AS [GST_NO],(CASE WHEN RATE_MST.MEMO_ID IS NULL THEN 0 ELSE 1 END) AS ENABLED_PARTY_RATE,
ISNULL(LMP.fc_code,'0000000') AS FC_CODE,FC.FC_NAME,FC.FC_RATE
,LMP.registered_gst_dealer,LMP.ac_gst_state_code
,ISNULL(RATE_MST.PARTY_RATE_MST_DISCOUNT_PERCENTAGE_1,0) AS PARTY_RATE_MST_DISCOUNT_PERCENTAGE_1
,ISNULL(RATE_MST.PARTY_RATE_MST_DISCOUNT_PERCENTAGE_2,0) AS PARTY_RATE_MST_DISCOUNT_PERCENTAGE_2
,ISNULL(RATE_MST.PARTY_RATE_MST_DISCOUNT_PERCENTAGE,0) AS PARTY_RATE_MST_DISCOUNT_PERCENTAGE
,ISNULL(LMV.lm_REMARKS,'') AS LEDGER_REMARKS, 
ISNULL(RATE_MST.MEMO_ID,'') AS PARTY_RATE_MEMO_ID,
(CASE WHEN LMP.freightPaidBy =2 then 'Party' else 'Company' end) as freightmethod
FROM LM01106   LMV (NOLOCK)
JOIN  LMP01106   LMP (NOLOCK) ON LMV.AC_CODE=LMP.AC_CODE
LEFT OUTER JOIN AREA LMA (NOLOCK) ON LMP.AREA_CODE = LMA.AREA_CODE
LEFT OUTER JOIN CITY LMC (NOLOCK) ON LMA.CITY_CODE = LMC.CITY_CODE 
LEFT OUTER JOIN STATE LMS (NOLOCK) ON LMC.STATE_CODE = LMS.STATE_CODE   
LEFT JOIN BIN B (NOLOCK) ON LMV.AC_CODE=B.MBO_LEDGER_AC_CODE
LEFT JOIN ANGM ANG (NOLOCK) ON LMP.ANGADIA_CODE=ANG.ANGADIA_CODE
LEFT OUTER JOIN PARTY_RATE_MST RATE_MST (NOLOCK) ON RATE_MST.MEMO_ID=LMP.PARTY_RATE_MEMO_ID
LEFT OUTER JOIN FC  ON FC.FC_CODE = LMP.FC_CODE 
WHERE (CHARINDEX(LMV.HEAD_CODE,@CHEADCODESTR)>0
OR LMP.ALLOW_CREDITOR_DEBTOR=1) AND LMV.AC_CODE <>'0000000000' AND ISNULL(LMV.AC_NAME,'')<>''
AND LMV.INACTIVE=0
ORDER BY LMV.AC_NAME 

END
