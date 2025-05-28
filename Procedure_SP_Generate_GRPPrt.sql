create PROCEDURE SP_Generate_GRPPrt  
(   
	 @CMEMOID   VARCHAR(40)='',
	 @CLOCID VARCHAR(2)='',
	 @CRETRUNID varchar(50) output,
	 @cErrormsg varchar(1000) output,
	 @CPS_ID varchar(30)='',
	 @BDONOTCALLEDFROMGIT bit=0,
	 @cUser_code varchar(7)='0000000'
)  
----WITH ENCRYPTION
AS  
BEGIN  
--(dinkar) Replace  left(memoid,2) to Location_code 

/*
	THIS PROCEDURES SAVES DATA IN RMM01106 TABLE FROM TEMPORARY TABLE.
	THE TEMPERORY TABLE WILL HAVE NO ITEM DETAILS.when at the time of Goods 
	Receive In Git Bin Use Want to return box at the time of Receiving Goosd in Git Bin 
	and also user Generate debit note of item at the time of bin transfer from git bin to actual bin
*/
  
 DECLARE   @CMASTERTABLENAME  VARCHAR(100), @CDETAILTABLENAME  VARCHAR(100),   
		   @CTEMPMASTERTABLE  VARCHAR(100), @CTEMPDETAILTABLE  VARCHAR(100),  
		   @CKEYFIELDVAL1   VARCHAR(50), @CKEYFIELD1    VARCHAR(50), @CMEMONO    VARCHAR(20),  
		   @NMEMONOLEN    NUMERIC(20,0), @CMEMONOVAL    VARCHAR(50),  
		   @CCMD     NVARCHAR(4000),@CCMDOUTPUT    NVARCHAR(4000),  
		   @NSAVETRANLOOP   BIT,@NSTEP  VARCHAR(10),
		   @nUpdatemode int, @CDEPT_ID varchar(2),@nSpId VARCHAR(50),@CFINYEAR varchar(10),
		   @CMEMONOPREFIX varchar(10),@cDeptAcCode varchar(15),@bAC_GST_NO varchar(15),
		   @cprtyStatecode varchar(2),@NEXCLTAX numeric(10,2),@NGSTCESSAMOUNT numeric(10,2),
		   @CXNTYPEPARA varchar(10),@CTARGETLOCID varchar(2),@CMEMOPREFIXPROC varchar(20),
		   @ntotalGitQTY numeric(10,3),@ntotalReturnQTY numeric(10,3),@BPREFIXLZEROS bit
		   
		
  SET @nSpId=NEWID()		   
  SET @nUpdatemode=1

  SET @NSTEP = '5'  -- SETTTING UP ENVIRONMENT  
   
 SET @CMASTERTABLENAME = 'DNPS_MST'  
 SET @CDETAILTABLENAME='DNPS_DET'
  
 SET @CTEMPMASTERTABLE = 'DNPS_'+@CMASTERTABLENAME+'_UPLOAD'
 SET @CTEMPDETAILTABLE=  'DNPS_'+@CDETAILTABLENAME+'_UPLOAD'
  
 SET @cErrormsg   = ''  
 SET @CKEYFIELD1   = 'PS_id'  
  
  SET @NSTEP = '10'
 SET @CMEMONO   = 'ps_no'  
 
 
	set @CDEPT_ID =@clocid
	
 SET @NSTEP = '12'
 
 set @CMEMONOPREFIX=@CDEPT_ID+'-'
 
 
 SET @NMEMONOLEN= LEN(@CMEMONOPREFIX)+6
 SET @BPREFIXLZEROS=0
 
 
 BEGIN TRY  
 
  if ISNULL(@CDEPT_ID,'')=''
    begin
         SET @cErrormsg = 'Location Code can not be blank'  
		 GOTO END_PROC  
    
    end
 
 
   SELECT @CFINYEAR='01'+ DBO.FN_GETFINYEAR(getdate() )
   
   
   DELETE A FROM DNPS_DNPS_MST_UPLOAD A (NOLOCK) WHERE SP_ID=@NSPID
   
   DECLARE @source_loc  VARCHAR(5),@cagainstpsno varchar(max),@cgainstinvno varchar(max),@cagainstTransfer varchar(100),@cremarks varchar(1000)
   select @cgainstinvno=INV_NO +' DT: '+CONVERT(varchar(10),inv_dt,121) ,@source_loc= challan_source_location_code from PIM01106  a (nolock) where a.INV_ID=@CMEMOID  and CANCELLED =0
   
   
   SELECT @cDeptAcCode=A.DEPT_AC_CODE ,@bAC_GST_NO=B.AC_GST_NO ,@cprtyStatecode=b.ac_gst_state_code 
   FROM   LOCATION A (NOLOCK) 
   JOIN LMP01106 B (NOLOCK) ON A.DEPT_AC_CODE =B.AC_CODE 
   WHERE  A.DEPT_ID =@source_loc  
 
   select @cagainstpsno=QUOTENAME(SUBSTRING(RIGHT(@CPS_ID,LEN(@CPS_ID)-LEN(@source_loc)+5),CHARINDEX(LEFT(@CPS_ID,LEN(@source_loc)), RIGHT(@CPS_ID,LEN(@CPS_ID)-LEN(@source_loc)+5)),LEN(@source_loc)+13) )
   
  
  -- select @cagainstpsno=QUOTENAME(SUBSTRING(RIGHT(@CPS_ID,LEN(@CPS_ID)-7),CHARINDEX(LEFT(@CPS_ID,2), RIGHT(@CPS_ID,LEN(@CPS_ID)-7)),15) )
  select @cagainstTransfer=MEMO_NO  +' DT: '+CONVERT(varchar(10),MEMO_DT ,121) from FLOOR_ST_MST (nolock) where CANCELLED =0 and PS_ID=@CPS_ID
	 
   set @cremarks='CHO Against:('+@cgainstinvno+'),psno:('+@cagainstpsno+')'
   
   IF ISNULL(@CAGAINSTTRANSFER,'')<>''
       SET @CREMARKS=@CREMARKS+',TRANSFER MEMO('+@CAGAINSTTRANSFER+')'
   
	  
  
   INSERT INTO DNPS_DNPS_MST_UPLOAD(ac_code, bill_challan_mode, BIN_ID, CANCELLED, edt_user_code, FIN_YEAR, LAST_UPDATE, 
             MEMO_TYPE, party_dept_id, ps_dt, ps_id, ps_mode, ps_no, REMARKS, SP_ID, TARGET_BIN_ID, USER_CODE ,GITBIN_INV_ID,GITBIN_PS_ID ,location_Code    )
                
    SELECT @cDeptAcCode ac_code,0 bill_challan_mode,'888'  BIN_ID,0 CANCELLED,'0000000' edt_user_code,@CFINYEAR FIN_YEAR,GETDATE() LAST_UPDATE, 
            1 MEMO_TYPE,@source_loc party_dept_id,CONVERT(VARCHAR(10),GETDATE(),121) ps_dt, 'LATER' ps_id,2 ps_mode,'LATER' ps_no,
            @cremarks REMARKS,@NSPID SP_ID,'000' TARGET_BIN_ID,@cUser_code USER_CODE ,
            @CMEMOID as GITBIN_INV_ID,@CPS_ID GITBIN_ps_ID,@CDEPT_ID as Location_code 
    
 
    	
   
   -- GENERATING NEW JOB ORDER NO    
   SET @NSAVETRANLOOP=0  
   WHILE @NSAVETRANLOOP=0  
   BEGIN  
   
  
		SET @NSTEP = '25'
		EXEC GETNEXTKEY @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMONOPREFIX,@BPREFIXLZEROS,
								@CFINYEAR,0, @CMEMONOVAL OUTPUT   
		
      
		SET @NSTEP = '35'  
		PRINT '96 '+@CMEMONOVAL  
		SET @CCMD=N'IF EXISTS ( SELECT '+@CMEMONO+' FROM '+@CMASTERTABLENAME+'   
								WHERE '+@CMEMONO+'='''+@CMEMONOVAL+'''   
								AND FIN_YEAR = '''+@CFINYEAR+''' )  
					SET @NLOOPOUTPUT=0  
				   ELSE  
					SET @NLOOPOUTPUT=1'  
		PRINT @CCMD  
		EXEC SP_EXECUTESQL @CCMD, N'@NLOOPOUTPUT BIT OUTPUT',@NLOOPOUTPUT=@NSAVETRANLOOP OUTPUT  
   END  
  
   SET @NSTEP = '45'
   IF @CMEMONOVAL IS NULL OR @CMEMONOVAL LIKE '%LATER%'
   BEGIN  
      SET @cErrormsg = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO NO....'   
      GOTO END_PROC      
   END  
   

		   SET @NSTEP = '100'  
		   SET @CKEYFIELDVAL1 = @CDEPT_ID + @CFINYEAR+ REPLICATE('0', 15-LEN(LTRIM(RTRIM(@CMEMONOVAL)))) + LTRIM(RTRIM(@CMEMONOVAL))  
		   IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'    
		   BEGIN  
			  SET @cErrormsg = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
			  GOTO END_PROC  
		   END  

		  PRINT '121 ID='+@CKEYFIELDVAL1+'; NO='+@CMEMONOVAL
		   SET @NSTEP = 40  -- UPDATING NEW ID INTO TEMP TABLES  
		   SET @CCMD = 'UPDATE ' + @CTEMPMASTERTABLE + ' SET ' +@CMEMONO+'=''' + @CMEMONOVAL+''',' 
								 +@CKEYFIELD1+' = '''+@CKEYFIELDVAL1+'''
								 WHERE SP_ID ='''+LTRIM(RTRIM(@NSPID))+''' '  
		   PRINT @CCMD  
		   EXEC SP_EXECUTESQL @CCMD  
		  SET @NSTEP = '105'
		  -- RECHECKING IF ID IS STILL LATER  
		  IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
		  BEGIN  
			 SET @cErrormsg = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'  
			 GOTO END_PROC  
		  END

		SET @NSTEP = '125'
		DELETE A FROM DNPS_DNPS_DET_UPLOAD   A (NOLOCK) WHERE SP_ID=@NSPID
		
		
		if @BDONOTCALLEDFROMGIT=0
		begin
	
		 INSERT DNPS_DNPS_DET_UPLOAD	( BIN_ID, BOX_ID, DEPT_ID, DNPS_CD_PERCENTAGE, DNPS_Terms, LAST_UPDATE, PRODUCT_CODE, ps_id, pur_bill_challan_mode, QUANTITY, ROW_ID, SP_ID )  
		  SELECT 	 a. BIN_ID, BOX_ID, DEPT_ID,0 DNPS_CD_PERCENTAGE,'' DNPS_Terms,GETDATE() LAST_UPDATE, PRODUCT_CODE, 
		  'LATER' ps_id,b.bill_challan_mode  pur_bill_challan_mode, QUANTITY,CONVERT(VARCHAR(40),NEWID()) ROW_ID,@NSPID SP_ID 
		 FROM PID01106  A (NOLOCK)
		 JOIN pim01106  B (NOLOCK) ON A.mrr_id =B.mrr_id 
		 join DOCWSL_XNRECON_GITBIN_UPLOAD c (nolock) on c.PS_ID  =a.PS_ID and b.inv_id =c.INV_ID 
		 AND b.inv_id  =@CMEMOID  and ISNULL(GIT_RECEIVED,0)=0 and b.CANCELLED=0
		 and c.PS_ID =@CPS_ID
		
	     
         select @ntotalGitQTY=SUM(GIT_QTY) FROM DOCWSL_XNRECON_GITBIN_UPLOAD (nolock) WHERE INV_ID=@CMEMOID and ISNULL(GIT_RECEIVED,0)=0 and PS_ID =@CPS_ID

      END 
	  ELSE 
	  begin
	      
	      INSERT DNPS_DNPS_DET_UPLOAD	( BIN_ID, BOX_ID, DEPT_ID, DNPS_CD_PERCENTAGE, DNPS_Terms, LAST_UPDATE, PRODUCT_CODE, ps_id, pur_bill_challan_mode, QUANTITY, ROW_ID, SP_ID )  
		  SELECT 	 a. BIN_ID, BOX_ID, DEPT_ID,0 DNPS_CD_PERCENTAGE,'' DNPS_Terms,GETDATE() LAST_UPDATE, c.PRODUCT_CODE, 
		  'LATER' ps_id,b.bill_challan_mode  pur_bill_challan_mode, c.QUANTITY,CONVERT(VARCHAR(40),NEWID()) ROW_ID,@NSPID SP_ID 
		 FROM PID01106  A (NOLOCK)
		 JOIN pim01106  B (NOLOCK) ON A.mrr_id =B.mrr_id 
		 join XNS_GITBINITEM_UPLOAD c (nolock) on c.PS_ID  =a.PS_ID and b.inv_id =c.INV_ID and a.product_code =C.product_code
		 where  b.inv_id  =@CMEMOID  and a.ps_id =@CPS_ID  and b.CANCELLED =0
		 
	  
	  
	  select @ntotalGitQTY=SUM(Quantity) FROM XNS_GITBINITEM_UPLOAD (nolock) WHERE INV_ID=@CMEMOID and ps_id=@CPS_ID
	  
	  end
	  
	  	UPDATE A SET ps_id=@CKEYFIELDVAL1,ROW_ID =CONVERT(VARCHAR(40),NEWID()) ,bin_id='888'
		FROM  dnps_dnps_det_UPLOAD  A (NOLOCK) WHERE SP_ID=@NSPID
	 	
	 	
		 
		 
		 
		UPDATE A SET TOTAL_QUANTITY=ISNULL(B.INVOICE_QUANTITY,0)
		FROM DNPS_DNPS_MST_UPLOAD   A 
		LEFT OUTER JOIN
		( 	
			SELECT	SUM(QUANTITY) AS INVOICE_QUANTITY
			FROM DNPS_DNPS_det_UPLOAD (nolock)
			where SP_ID=@NSPID
		) B ON  1=1
		where a.SP_ID=@NSPID
		
		
	  --Stock reduce In Pmt 
		 Update a set quantity_in_stock =quantity_in_stock-b.quantity  
		 from pmt01106 A (nolock)
		 join DNPS_DNPS_det_UPLOAD b (nolock) on a.BIN_ID  =b.BIN_ID and a.product_code =b.product_code 
		 where a.dept_id=@CLOCID and isnull(a.bo_order_id ,'')=''
		 and b.SP_ID =@NSPID
   
		 DECLARE @CWHERECLAUSE VARCHAR(100)
		 SET @CWHERECLAUSE = ' SP_ID='''+LTRIM(RTRIM(@NSPID))+''''
    
		  SET @NSTEP = '175' -- UPDATING MASTER TABLE  
		  
		  
		  EXEC UPDATEMASTERXN_MIRROR 
		       @CSOURCEDB='',
		       @CSOURCETABLE=@CTEMPMASTERTABLE,
		       @CDESTDB='',        
			   @CDESTTABLE=@CMASTERTABLENAME,
			   @CKEYFIELD1=@CKEYFIELD1,       
			   @LINSERTONLY=1,@BUPDATEXNS=1,
			   @BALWAYSUPDATE=1,
			   @CFILTERCONDITION=@CWHERECLAUSE
  
 
	     SET @NSTEP = '185'
	    
	      EXEC UPDATEMASTERXN_MIRROR 
		       @CSOURCEDB='',
		       @CSOURCETABLE=@CTEMPDETAILTABLE,
		       @CDESTDB='',        
			   @CDESTTABLE=@CDETAILTABLENAME,
			   @CKEYFIELD1=@CKEYFIELD1,       
			   @LINSERTONLY=1,
			   @BUPDATEXNS=1,
			   @BALWAYSUPDATE=1,
			   @CFILTERCONDITION=@CWHERECLAUSE
	    
		
		 SET @NSTEP=280
		 
		 
		 
		 select @ntotalReturnQTY=SUM(Quantity ) FROM dnps_det  (nolock) WHERE ps_id =@CKEYFIELDVAL1 
		 
		 SET @CRETRUNID=@CKEYFIELDVAL1
		 
	
		 IF ISNULL(@NTOTALGITQTY,0)<>ISNULL(@NTOTALRETURNQTY,0)
		 BEGIN
		     SET @CERRORMSG ='error in goods return Item qty mismatch PLEASE CHECK'
		     GOTO END_PROC	
		 END
		 
		 
	   Update a set HO_SYNCH_LAST_UPDATE ='',LAST_UPDATE =GETDATE() from   DNPS_MST A (nolock) where ps_id=@CKEYFIELDVAL1
		 

 GOTO END_PROC	
 END TRY  
 BEGIN CATCH
	print 'enter catch'
    SET @cErrormsg = 'Error in Procedure SP_Generate_GRPPrt at STEP# ' + @NSTEP +  ' ' + ERROR_MESSAGE()
	GOTO END_PROC
 END CATCH 
   
END_PROC:  
	

	DELETE FROM DNPS_DNPS_MST_UPLOAD WITH (ROWLOCK) WHERE SP_ID =LTRIM(RTRIM(@NSPID)) 
	DELETE FROM DNPS_DNPS_DET_UPLOAD WITH (ROWLOCK) WHERE SP_ID =LTRIM(RTRIM(@NSPID)) 
			
				

END        
---------- END OF PROCEDURE SAVETRAN_PUR_DIFF_PRT