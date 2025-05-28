
create Procedure VALIDATEXN_PRCL_BEFORE_Cancel
(
@CMEMOID VARCHAR(30),
@CERRORMSG VARCHAR(200) OUTPUT
)
as 
begin

	Declare @CREF_MEMO_ID VARCHAR(100),@CXNTYPE VARCHAR(20)

	SELECT TOP 1  @CREF_MEMO_ID=REF_MEMO_ID,@CXNTYPE=xn_type  
	FROM  PARCEL_DET A (NOLOCK)
	JOIN PARCEL_MST B (NOLOCK) ON A.PARCEL_MEMO_ID =B.PARCEL_MEMO_ID 
	WHERE A.REF_MEMO_ID <>'' AND B.XN_TYPE IN('WSL','PRT') AND A.PARCEL_MEMO_ID=@CMEMOID 

	IF ISNULL(@CREF_MEMO_ID,'')<>''
	 BEGIN
     
			 IF @CXNTYPE='WSL'
			 BEGIN
	      
				  IF EXISTS (SELECT TOP 1 'U' FROM INM01106 A (NOLOCK)
				  JOIN LOCATION B (NOLOCK) ON LEFT(A.INV_ID,2)=b.DEPT_ID
				  JOIN LOCATION C (NOLOCK) ON A.PARTY_DEPT_ID =C.DEPT_ID 
				  WHERE A.INV_ID =@CREF_MEMO_ID AND (ISNULL(B.server_loc,0) =0 OR ISNULL(C.server_loc,0) =0))
				  BEGIN
		      
					  SET @CERRORMSG=' Dispatch details have been attached with the invoice, you cannot cancel.'
					  GOTO END_PROC
		     
				  END

			 END
			 ELSE IF @CXNTYPE='PRT'
			 BEGIN
	      
				  IF EXISTS (SELECT TOP 1 'U' FROM rmm01106  A (NOLOCK)
				  JOIN LOCATION B (NOLOCK) ON LEFT(A.rm_id,2)=b.DEPT_ID
				  JOIN LOCATION C (NOLOCK) ON A.PARTY_DEPT_ID =C.DEPT_ID 
				  WHERE A.rm_id =@CREF_MEMO_ID AND (ISNULL(B.server_loc,0) =0 OR ISNULL(C.server_loc,0) =0))
				  BEGIN
		      
					  SET @CERRORMSG=' Dispatch details have been attached with the Group Debitnote, you cannot cancel.'
					  GOTO END_PROC
		     
				  END

			 END
	
END

END_PROC:

end