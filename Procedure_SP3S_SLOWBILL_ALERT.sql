 create PROCEDURE SP3S_SLOWBILL_ALERT
 (
  @CKEYFIELDVAL1 VARCHAR(40)=''
 )
 AS
 BEGIN

 IF DB_NAME()='wizapp3shon_NEW'
  BEGIN
		    
			IF EXISTS (SELECT TOP 1 'U' FROM   SLS_XNSAVELOG_SUMMARY A (NOLOCK) 
			WHERE A.CM_ID=@CKEYFIELDVAL1
			AND (DATEDIFF(SS,BEFORESAVE_START_TIME,BEFORESAVE_END_TIME)+datediff(ss,aftersave_start_time,aftersave_end_time))>15)
			BEGIN
				INSERT INTO SLOWBILL_ALERT
				SELECT A.CM_ID
				FROM   SLS_XNSAVELOG_SUMMARY A (NOLOCK) 
				WHERE A.CM_ID=@CKEYFIELDVAL1
				

	         END

  END

END		