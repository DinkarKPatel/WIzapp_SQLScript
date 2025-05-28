CREATE PROCEDURE [DBO].[SP3S_WALLETMASTER]
(
	@NQUERYID NUMERIC(3,0),
	@cWhere		VARCHAR(100)=''
)
AS
BEGIN
            
IF @NQUERYID = 1      
	GOTO PYMTG_MST_RET      
      
ELSE IF @NQUERYID = 2      
	GOTO PYMTG_DET_RET      

ELSE IF @NQUERYID =3     
	GOTO PAYMODE_MST       
ELSE
	GOTO LAST

      
PYMTG_MST_RET:
	SELECT NEWID() AS ROW_ID,a.* FROM PYMTG_MST a JOIN PYMTG_DET b on b.PYG_GRP_CODE=a.PYG_GRP_CODE WHERE (@cWhere='' OR b.PYG_CODE=@cWhere) ORDER BY PYG_GRP_CODE
	GOTO LAST

PYMTG_DET_RET:
	SELECT NEWID() AS ROW_ID,b.* FROM PYMTG_DET b  JOIN PYMTG_MST a on b.PYG_GRP_CODE=a.PYG_GRP_CODE WHERE (@cWhere='' OR b.PYG_CODE=@cWhere) ORDER BY PYG_GRP_CODE
	GOTO LAST

PAYMODE_MST:
	SELECT a.paymode_code as PYG_CODE,a.paymode_name AS PYG_NAME,a.paymode_name AS PYG_GRP_NAME 
	FROM paymode_grp_mst b  JOIN paymode_mst a on b.paymode_grp_code=a.paymode_grp_code 
	WHERE (@cWhere='' OR a.paymode_code=@cWhere) 
	GOTO LAST

	
LAST:      
END

--***************************************** END OF PROCEDURE SP3S_WALLETMASTER
