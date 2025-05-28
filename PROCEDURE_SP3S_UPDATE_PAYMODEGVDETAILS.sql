CREATE PROCEDURE SP3S_UPDATE_PAYMODEGVDETAILS
@nSpId VARCHAR(40),
@CSCHEMEDETROWID VARCHAR(40)
AS
BEGIN	
	DECLARE @cGvSrno VARCHAR(50)
	SELECT TOP 1 @cGvSrno=A.gv_srno FROM sls_paymode_xn_det_upload a (NOLOCK) 
	WHERE sp_id=@nSpId AND ISNULL(remarks,'')=''
	AND ISNULL(a.gv_srno,'')<>'' AND a.cc_name=@CSCHEMEDETROWID
										
	UPDATE A set remarks=@CSCHEMEDETROWID FROM sls_paymode_xn_det_upload a (NOLOCK) 
	WHERE sp_id=@nSpId AND ISNULL(remarks,'')=''
	AND ISNULL(a.gv_srno,'')<>'' AND a.cc_name=@CSCHEMEDETROWID 
	AND a.gv_srno=@cGvSrno
END