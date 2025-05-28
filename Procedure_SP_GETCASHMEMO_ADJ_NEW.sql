create PROCEDURE SP_GETCASHMEMO_ADJ_NEW    
(        
  @NADJUSTMENTMETHOD INT=1  ,--1 FOR AUTO ,bill wise    
  @NMODE INT=1,    
  @DTFROM  DATETIME =''        
 ,@DTTO   DATETIME =''        
 ,@CFILTER  VARCHAR(MAX)=''        
 ,@CDEPT_ID VARCHAR(4)=''    
 ,@NREDUCETYPE INT=1 --1 FOR DISCOUNT REDUCE 2 MRP REDUCE      
 ,@NFM_DISC_RANGE NUMERIC(5,0)=0    
 ,@nto_DISC_RANGE NUMERIC(5,0)=0    
 ,@CSP_ID VARCHAR(50)=''    
)    
AS        
BEGIN        
SET NOCOUNT ON    
    
  /*    
   @NADJUSTMENTMETHOD :IT IS USE TO AUTO MRP REDUCE oR DISCOUNT REDUCE /2 FOR MANUAL INSERT OLD MRP & NEW MRP OF SELECTD PERIOD    
 @NMODE:1 FOR GET DATA TOTAL SALE CASH & PROCESSABLE AMOUNT - AFETR INSERTING REDUCE AMOUNT CALL 2 FOR GET DATA WITH NEW SALE    
 @NREDUCETYPE : IN AUTO MODE 1 FOR DISCOUNT REDUCE , 2 FOR MRP REDUCE ADJUSTMENT 2 ALWAYS BE REDUCE MRP    
 @NFM_DISC_RANGE : RANGE WILL BE APPLICABLE OF EACH BILL OF SELECTED PERIOD EX-5,10,15 OF RANGE 5 TO 15     
  */    
  
  
  if @NADJUSTMENTMETHOD=2  
  begin  
  
  EXEC SP_GETCASHMEMO_ADJ_NEW_BILLNOWISE   
    @NADJUSTMENTMETHOD=@NADJUSTMENTMETHOD,  
 @NMODE=@NMODE,  
 @DTFROM=@DTFROM,  
 @DTTO=@DTTO,  
 @CFILTER=@CFILTER,  
 @CDEPT_ID=@CDEPT_ID,  
 @NREDUCETYPE=@NREDUCETYPE,  
 @NFM_DISC_RANGE=@NFM_DISC_RANGE,  
 @nto_DISC_RANGE=@nto_DISC_RANGE,  
 @CSP_ID=@CSP_ID  
  
 Return  
 end  
     
  DECLARE @CCMD01106 VARCHAR(100),@CRPSDET VARCHAR(100) ,@NSTEP numeric(5,0),@CERRORMSG varchar(1000),    
          @MRP_ROUNDING_LEVEL varchar(10)    
    
  IF OBJECT_ID('TEMPDB..#TABLECM_ID','U') IS NOT NULL    
  DROP TABLE #TABLECM_ID    
     
   select @MRP_ROUNDING_LEVEL=value  from config where config_option='MRP_ROUNDING_LEVEL'    
      
 CREATE TABLE #TABLECM_ID(CM_DT DATETIME,CM_ID VARCHAR(50),PROCESS_AMOUNT NUMERIC(10,2),CASH_AMOUNT NUMERIC(10,2),
 ROW_ID VARCHAR(50),LESS_DISCOUNT NUMERIC(14,2),mrp NUMERIC(14,2),DISCOUNT_PERCENTAGE NUMERIC(14,3),DISCOUNT_amount NUMERIC(14,2),
 net NUMERIC(14,2),cmm_discount_amount NUMERIC(14,2),Quantity numeric(10,3),CMM_DISC_PERCENTAGE  numeric(10,3))    
    
 DECLARE @CCMD VARCHAR(MAX)    
  
  DECLARE @CPickRoundITEMLEVELFromLoc VARCHAR(2) ,@CROUNDITEMLEVEL VARCHAR(2)  
  
  SELECT TOP 1 @CPickRoundITEMLEVELFromLoc = VALUE  FROM CONFIG WHERE  CONFIG_OPTION='Pick_SLS_ROUND_OFF_fromloc'  
   
   if isnull(@CPickRoundITEMLEVELFromLoc,'')<>'1'  
  SELECT TOP 1 @CROUNDITEMLEVEL = VALUE  FROM CONFIG WHERE  CONFIG_OPTION='SLS_ROUND_ITEM_NET'  
 ELSE  
  SELECT TOP 1 @CROUNDITEMLEVEL = sls_round_item_level  FROM location (NOLOCK) WHERE dept_id=@CDEPT_ID  
  
 SET @CROUNDITEMLEVEL=ISNULL(@CROUNDITEMLEVEL,'')  
  
    
BEGIN TRY       
     
 --B.OLD_MRP=B.MRP OR     
    
 -- donot apply discount on return item    
 SET @NSTEP=10    
    
 SET @CCMD='SELECT convert(varchar(10),A1.CM_DT,121) as cm_dt, A1.CM_ID,    
           ISNULL(X.AMOUNT,0) AS CASH_SALE,    
     ISNULL(B.NET-isnull(b.cmm_discount_amount,0),0) AS  PROCESS_AMOUNT ,    
     b.ROW_ID  ,b.mrp,b.DISCOUNT_PERCENTAGE,b.DISCOUNT_amount ,B.NET,b.cmm_discount_amount ,b.Quantity,a1.discount_percentage
 FROM CMM01106 A1 (NOLOCK)         
 join custdym cust (nolock) on cust.customer_code=a1.customer_code     
 LEFT JOIN CMD01106 B (NOLOCK) ON B.CM_ID=A1.CM_ID      
 LEFT JOIN SKU_NAMES WITH(NOLOCK)  ON SKU_NAMES.PRODUCT_CODE =B.PRODUCT_CODE    
 LEFT JOIN USERS  (NOLOCK) ON USERS.USER_CODE=A1.USER_CODE    
 JOIN       
 (        
   SELECT A.MEMO_ID,B.PAYMODE_GRP_CODE,SUM(A.AMOUNT) AS [AMOUNT]    
   FROM PAYMODE_XN_DET A (NOLOCK)    
   JOIN PAYMODE_MST B (NOLOCK) ON B.PAYMODE_CODE=A.PAYMODE_CODE    
   JOIN PAYMODE_GRP_MST C (NOLOCK) ON C.PAYMODE_GRP_CODE=B.PAYMODE_GRP_CODE    
   WHERE C.PAYMODE_GRP_CODE=''0000001'' AND A.XN_TYPE=''SLS''    
   GROUP BY A.MEMO_ID,B.PAYMODE_GRP_CODE    
 )X ON X.MEMO_ID=A1.CM_ID      
 WHERE   A1.NET_AMOUNT=X.AMOUNT         
 AND (A1.MEMO_TYPE = ''0'' OR A1.MEMO_TYPE = ''1'')        
 AND (A1.CM_DT BETWEEN '''+CONVERT(VARCHAR,@DTFROM,110)+''' AND '''+CONVERT(VARCHAR,@DTTO,110)+''')        
 AND A1.CANCELLED=0      
 AND (ISNULL(A1.SUBTOTAL,0)+ISNULL(A1.SUBTOTAL_R,0))>0     
 AND B.NET>0    
 and isnull(a1.Party_Gst_No,'''')=''''    
 and isnull(a1.EINV_IRN_NO,'''')=''''  
 AND A1.location_code='''+@CDEPT_ID+''' AND     
 '  + (CASE WHEN @CFILTER='' THEN '1=1 '  ELSE @CFILTER END) +'    
  '    
    
 PRINT @CCMD    
 INSERT INTO #TABLECM_ID  (CM_DT,CM_ID ,CASH_AMOUNT,PROCESS_AMOUNT,ROW_ID,mrp ,DISCOUNT_PERCENTAGE,DISCOUNT_amount,net ,cmm_discount_amount,Quantity,CMM_DISC_PERCENTAGE )      
 EXEC (@CCMD)    
  
 --(ISNULL(A1.PATCHUP_RUN,0)=0) as Discuss with Sir reprocess of Patched bill  
    
 SET @NSTEP=20    
    
 ;WITH CTE AS    
 (    
 SELECT *,SR=ROW_NUMBER() OVER (PARTITION  BY CM_ID ORDER BY CM_ID)    
 FROM #TABLECM_ID    
 )    
 UPDATE CTE SET CASH_AMOUNT=0 WHERE SR>1    
    
    
     
     
  IF OBJECT_ID('TEMPDB..#TMPTOTALAMOUNT','U') IS NOT NULL    
  DROP TABLE #TMPTOTALAMOUNT    
    
    
  SELECT A.CM_DT ,A.CM_ID ,A.CASH_AMOUNT,    
        SUM(A.PROCESS_AMOUNT) AS PROCESS_AMOUNT ,  
        CAST(0 AS NUMERIC(14,2)) As Return_amount     
     into #TMPTOTALAMOUNT    
  FROM #TABLECM_ID A    
  group by A.CM_DT ,A.CM_ID ,A.CASH_AMOUNT    
    
    
  UPDATE A SET RETURN_AMOUNT=  (B.NET-CMM_DISCOUNT_AMOUNT)  FROM #TMPTOTALAMOUNT A  
  JOIN CMD01106 B (NOLOCK) ON A.CM_ID =B.CM_ID   
  WHERE (B.NET-isnull(CMM_DISCOUNT_AMOUNT,0)) <0 AND A.CASH_AMOUNT>0  
    
     
    
SET @NSTEP=30    
  IF OBJECT_ID('TEMPDB..#TMPSUMMARY','U') IS NOT NULL    
  DROP TABLE #TMPSUMMARY    
    
    
   SELECT '' AS CURSOR1,CONVERT( VARCHAR(10),A.CM_DT,121) as  CM_DT ,  
          SUM(A.NET_AMOUNT) AS TOTAL_SALE,    
          SUM(ISNULL(B.CASH_AMOUNT,0)) AS TOTAL_CASH_SALE,    
          SUM(ISNULL(B.PROCESS_AMOUNT,0)) AS DISCOUNT_APPLY_AMOUNT,    
          CAST(0 AS NUMERIC(14,2)) AS REDUCE_AMOUNT ,  
          abs(SUM(ISNULL(B.Return_AMOUNT,0))) As Return_amount    
 INTO #TMPSUMMARY    
 FROM CMM01106 A    
 LEFT JOIN (    
 select cm_id ,  
           SUM(ISNULL(CASH_AMOUNT,0)) as CASH_AMOUNT ,    
           SUM(ISNULL(PROCESS_AMOUNT,0)) as PROCESS_AMOUNT ,  
           SUM(ISNULL(Return_AMOUNT,0)) as Return_AMOUNT   
 from #TMPTOTALAMOUNT     
 group by cm_id    
 )  B ON A.CM_ID=B.CM_ID     
 WHERE A.CM_DT BETWEEN @DTFROM AND @DTTO    
 AND a.location_Code =@CDEPT_ID and a.CANCELLED =0    
 --and A.NET_AMOUNT>0    
 GROUP BY CONVERT( VARCHAR(10),A.CM_DT,121)    
     
     
    
    
 IF @NMODE=1    
 BEGIN    
  
  SELECT  CAST(0 AS BIT) AS CHK,'' AS CURSOR1,A.CM_DT ,A.TOTAL_SALE ,A.TOTAL_CASH_SALE ,A.DISCOUNT_APPLY_AMOUNT ,A.REDUCE_AMOUNT ,    
          0 AS NEW_SALE , 0 AS AUTO_REDUCE_AMOUNT, DIFF=0  ,  
         cast('' as varchar(10))  customerMobile, cast('' as varchar(100))   as customerName ,a.TOTAL_SALE net_amount ,   
         cast(0 as numeric(10,2)) as discount_percentage,cast('' as varchar(10)) CM_NO,cast('' as  varchar(50)) CM_ID,0 as Discount_amount,  
         a.Return_amount   
  FROM #TMPSUMMARY A    
  ORDER BY CM_DT     
    
   
    
  GOTO END_PROC    
    
 END    
    
 SET @NSTEP=40    
    
   DELETE FROM #TABLECM_ID WHERE ROW_ID IS NULL    
    
    
  IF OBJECT_ID('TEMPDB..#TMPSUMMARY_DISC','U') IS NOT NULL    
  DROP TABLE #TMPSUMMARY_DISC    
    
      
     SELECT A.CM_DT,a.TOTAL_SALE ,a.TOTAL_CASH_SALE  ,A.DISCOUNT_APPLY_AMOUNT ,B.REDUCE_AMOUNT,    
            DISCADD= CAST(ROUND( CASE WHEN DISCOUNT_APPLY_AMOUNT=0 THEN 0 ELSE  B.REDUCE_AMOUNT*100/DISCOUNT_APPLY_AMOUNT END ,3) AS NUMERIC(10,3)),    
            CAST(0 AS NUMERIC(14,2)) AS NEW_SALE  ,A.Return_amount  
     INTO #TMPSUMMARY_DISC    
     FROM #TMPSUMMARY A    
     JOIN CASHMEMO_ADJ_UPLOAD B ON A.CM_DT =B.CM_DT     
     WHERE B.SP_ID=@CSP_ID  
	 
	
       
      
     delete from CASHMEMO_ADJ_DET_UPLOAD where sp_id=@CSP_ID    
    
      
  lbldiscoutReduce:
    
  SET @NSTEP=50    
 IF @NFM_DISC_RANGE=0 AND @NTO_DISC_RANGE=0 AND @NADJUSTMENTMETHOD=1    
 BEGIN    
     
        
    INSERT INTO CASHMEMO_ADJ_DET_UPLOAD(CM_ID ,CM_DT,OLD_MRP,OLD_DISCOUNT_PERCENTAGE ,OLD_DISCOUNT_AMOUNT,OLD_NET,NEW_MRP,NEW_DISCOUNT_PERCENTAGE,NEW_DISCOUNT_AMOUNT,NEW_NET,CMM_DISCOUNT_AMOUNT,DISCADD,row_id,    
    QUANTITY,LESS_DISCOUNT,sp_id)    
        SELECT B.CM_ID ,B.CM_DT ,    
            A.MRP AS OLD_MRP ,    
      A.DISCOUNT_PERCENTAGE AS OLD_DISCOUNT_PERCENTAGE ,    
      A.DISCOUNT_AMOUNT AS OLD_DISCOUNT_AMOUNT,    
      A.NET AS OLD_NET ,    
      CAST(0 AS NUMERIC(14,2)) AS NEW_MRP,    
      CAST(0 AS NUMERIC(14,3)) AS NEW_DISCOUNT_PERCENTAGE,    
      CAST(A.DISCOUNT_AMOUNT AS NUMERIC(14,2)) AS NEW_DISCOUNT_AMOUNT,        
	  CAST(0 AS NUMERIC(14,2)) AS NEW_NET,    
      A.CMM_DISCOUNT_AMOUNT AS CMM_DISCOUNT_AMOUNT ,    
      C.DISCADD AS DISCADD,a.row_id ,A.QUANTITY  ,    
      LESS_DISCOUNT =A.DISCOUNT_AMOUNT+((A.NET-A.cmm_discount_amount)*C.DISCADD/100),    
      @CSP_ID    
     FROM CMD01106 A    
     JOIN #TABLECM_ID B ON A.ROW_ID =B.ROW_ID     
     JOIN #TMPSUMMARY_DISC C ON B.CM_DT =C.CM_DT    
     
     
         
  END    
  ELSE IF  @NTO_DISC_RANGE>0 AND @NADJUSTMENTMETHOD=1    
  BEGIN    
          
      
   SET @NSTEP=60    
   DECLARE @CCMID VARCHAR(50),@CALDISCRANGE NUMERIC(5,0),@DCM_DT DATETIME,    
   @DOLDCM_DT DATETIME ,@NREDUCE_AMOUNT NUMERIC(14,2)    
    
   SET @DOLDCM_DT=''    
    
   SET @CALDISCRANGE=@NTO_DISC_RANGE    
    
   IF OBJECT_ID ('TEMPDB..#TMPCMM','U') IS NOT NULL    
      DROP TABLE #TMPCMM    
    
   SELECT CM_ID,CM_DT  INTO #TMPCMM     
   FROM #TABLECM_ID     
   GROUP BY CM_ID,CM_DT    
    
   --RANGE DISCOUNT APPLY ON BILL    
    
   WHILE EXISTS (SELECT TOP 1 'U' FROM #TMPCMM)    
   BEGIN    
           
     SELECT TOP 1 @CCMID=CM_ID,@DCM_DT=CM_DT  FROM #TMPCMM    
     ORDER BY CM_DT ,CM_ID     
    
     IF @DCM_DT<>@DOLDCM_DT    
     SELECT  @NREDUCE_AMOUNT=REDUCE_AMOUNT FROM CASHMEMO_ADJ_UPLOAD WHERE SP_ID=@CSP_ID AND CM_DT =@DCM_DT    
     
      
     IF @CALDISCRANGE<=0     
        SET @CALDISCRANGE=@NTO_DISC_RANGE    
    
   
     IF @NREDUCE_AMOUNT>0    
     BEGIN    
         
         if @NREDUCETYPE=1
         begin
	         
			   IF EXISTS (SELECT TOP 1 'U' FROM #TABLECM_ID WHERE  CM_ID =@CCMID  AND DISCOUNT_PERCENTAGE+ISNULL(CMM_DISC_PERCENTAGE,0)+@CALDISCRANGE >100)
			   BEGIN
			  
				   DELETE  FROM #TABLECM_ID WHERE  CM_ID =@CCMID  AND DISCOUNT_PERCENTAGE+ISNULL(CMM_DISC_PERCENTAGE,0)+@CALDISCRANGE>100
				      UPDATE #TABLECM_ID SET DISCOUNT_PERCENTAGE =DISCOUNT_PERCENTAGE+@CALDISCRANGE WHERE CM_ID =@CCMID    
				   UPDATE #TABLECM_ID SET LESS_DISCOUNT =((mrp*Quantity ) * DISCOUNT_PERCENTAGE)/100 WHERE CM_ID =@CCMID   
				  
			   END
			   ELSE
			   BEGIN
			   
			  
			   
				   UPDATE #TABLECM_ID SET DISCOUNT_PERCENTAGE =DISCOUNT_PERCENTAGE+@CALDISCRANGE WHERE CM_ID =@CCMID    
				   UPDATE #TABLECM_ID SET LESS_DISCOUNT =((mrp*Quantity ) * DISCOUNT_PERCENTAGE)/100 WHERE CM_ID =@CCMID    
				   
			   END
		   
		  END
		  ELSE
		  BEGIN
		  
		        UPDATE #TABLECM_ID SET MRP = MRP-(MRP*@CALDISCRANGE/100) WHERE CM_ID =@CCMID    
		        UPDATE #TABLECM_ID SET LESS_DISCOUNT =((MRP*QUANTITY ) * DISCOUNT_PERCENTAGE)/100 WHERE CM_ID =@CCMID    
		        
		     
		  END
      
     END    



	 if exists (select top 1 'U' from cmd01106 a (nolock) where cm_id=@CCMID and QUANTITY <0) AND   EXISTS (SELECT TOP 1 'U' FROM #TABLECM_ID WHERE  CM_ID =@CCMID )
	 begin
           
		   if object_id('tempdb..#tmpNegativebill','u') is not null
		      drop table #tmpNegativebill

		   ;WITH CTE_NEGATIVEBILL AS  
			(  
			  SELECT CM_ID ,SUM((mrp*Quantity )-LESS_DISCOUNT ) AS NEW_NET  
			  FROM #TABLECM_ID A (NOLOCK)  
			  GROUP BY CM_ID  
			)  
        
		  SELECT A.cm_id ,SUM(A.NET )+isnull(B.NEW_NET,0) AS netAmt  
			  into #tmpNegativebill  
		  FROM CMD01106 a (NOLOCK)  
		  JOIN CTE_NEGATIVEBILL  B ON A.cm_id =B.CM_ID   
		  WHERE A.NET <0  
		  and a.cm_id =@CCMID
		  group by A.cm_id,isnull(B.NEW_NET,0)  
		  having (SUM(A.NET )+isnull(B.NEW_NET,0))<0  
    



		  delete a  
		  FROM #TABLECM_ID A(NOLOCK)  
		  JOIN #TMPNEGATIVEBILL B ON A.CM_ID =B.CM_ID   
		  where a.cm_id =@CCMID

	  end 
	
       IF ( SELECT SUM(ISNULL(LESS_DISCOUNT-isnull(DISCOUNT_amount,0),0)) FROM #TABLECM_ID WHERE CM_DT =@DCM_DT)>@NREDUCE_AMOUNT  and @NREDUCETYPE=1
	   begin
	 
	     
		
			DECLARE @NTOTALDISCOUNT NUMERIC(14,2),@CROWID VARCHAR(50),@NLASTDUSC NUMERIC(14,2)
			SELECT @NTOTALDISCOUNT=SUM(ISNULL(LESS_DISCOUNT-ISNULL(DISCOUNT_AMOUNT,0),0)) FROM #TABLECM_ID WHERE CM_ID <>@CCMID 
			and CM_DT =@DCM_DT
			
			SET @NTOTALDISCOUNT=ISNULL(@NTOTALDISCOUNT,0)

			  if object_id('tempdb..#tmpexDisc','u') is not null
		      drop table #tmpexDisc

			select cm_id,row_id,ISNULL(LESS_DISCOUNT-isnull(DISCOUNT_amount,0),0) as discount ,
					sr=row_number() over(order by  ISNULL(LESS_DISCOUNT-isnull(DISCOUNT_amount,0),0)),
					cumm_discount=cast(0 as numeric(14,2))
			into #tmpexDisc
			from #TABLECM_ID WHERE CM_ID =@CCMID 
			
			--select 1, @NREDUCE_AMOUNT,@DCM_DT, * from #tmpexDisc
			
			--if more than one row then Remove records
		if  (select count(*) from #tmpexDisc)>1
		begin
				;with cte as
				(
				select a.cm_id ,a.discount ,a.ROW_ID ,a.sr,@ntotaldiscount+SUM( B.DISCOUNT) as cumm_discount
				from #tmpexDisc A
				join #tmpexDisc b on b.sr <=a.sr 
				group by a.cm_id ,a.discount ,a.ROW_ID ,a.sr 
				)

				delete a  from #TABLECM_ID A
				join cte b on a.ROW_ID =b.ROW_ID 
				where b.sr>
				(
				select min(sr) from cte where cumm_discount>@NREDUCE_AMOUNT)
		 end
		 
	

         DELETE FROM #TMPCMM WHERE CM_DT =@DCM_DT    

	   end 
    
        
    
     SET @DOLDCM_DT=@DCM_DT    
    
     if @NFM_DISC_RANGE=@nto_DISC_RANGE    
        SET @CALDISCRANGE=@CALDISCRANGE    
     else    
        SET @CALDISCRANGE=@CALDISCRANGE-5    
  
  if @CALDISCRANGE<@NFM_DISC_RANGE  
     set @CALDISCRANGE=@nto_DISC_RANGE  
    
      DELETE FROM #TMPCMM WHERE CM_ID =@CCMID    
    
   END    
    
    
SET @NSTEP=70    
   INSERT INTO CASHMEMO_ADJ_DET_UPLOAD(CM_ID ,CM_DT,OLD_MRP,OLD_DISCOUNT_PERCENTAGE ,OLD_DISCOUNT_AMOUNT,OLD_NET,NEW_MRP,NEW_DISCOUNT_PERCENTAGE,NEW_DISCOUNT_AMOUNT,NEW_NET,CMM_DISCOUNT_AMOUNT,DISCADD,row_id,    
    QUANTITY,LESS_DISCOUNT,sp_id,cmm_disc_percentage)    
    
    SELECT B.CM_ID ,B.CM_DT ,    
           A.MRP AS OLD_MRP ,    
		  A.DISCOUNT_PERCENTAGE AS OLD_DISCOUNT_PERCENTAGE ,    
		  A.DISCOUNT_AMOUNT AS OLD_DISCOUNT_AMOUNT,    
		  A.NET AS OLD_NET ,    
		  CAST((CASE WHEN @NREDUCETYPE =1 THEN 0  ELSE B.MRP END ) AS NUMERIC(14,2)) AS NEW_MRP,    
		  CAST(b.discount_percentage AS NUMERIC(14,3)) AS NEW_DISCOUNT_PERCENTAGE,    
		  CAST(0 AS NUMERIC(14,2)) AS NEW_DISCOUNT_AMOUNT,    
		  CAST(0 AS NUMERIC(14,2)) AS NEW_NET,    
		  A.CMM_DISCOUNT_AMOUNT AS CMM_DISCOUNT_AMOUNT ,    
		  0 AS DISCADD,    
		  a.row_id ,A.QUANTITY  ,    
		  LESS_DISCOUNT =isnull(b.LESS_DISCOUNT ,0),    
		  @CSP_ID as sp_id  ,b.cmm_disc_percentage   
     FROM CMD01106 A    
     JOIN #TABLECM_ID B ON A.ROW_ID =B.ROW_ID     
       where (isnull(b.LESS_DISCOUNT ,0)<>0  or @NREDUCETYPE =2)
    
       
     --UPDATE  CASHMEMO_ADJ_DET_UPLOAD SET  DISCADD= CAST(ROUND(LESS_DISCOUNT*100/OLD_NET,3) AS NUMERIC(10,3))     
     --where sp_id=@CSP_ID and isnull(OLD_NET,0)<>0  
	 
     UPDATE #TMPSUMMARY_DISC SET DISCADD =0    
    
         
  END    
    
    
  SET @NSTEP=80   
    
      IF @NREDUCETYPE=1    
      BEGIN    
            
        PRINT ' 2 CHECK DISCOUNT LESS '       
  
		   UPDATE A SET NEW_MRP= OLD_MRP ,    
			            NEW_DISCOUNT_AMOUNT= LESS_DISCOUNT    
		   FROM CASHMEMO_ADJ_DET_UPLOAD A     
		   where  sp_id=@CSP_ID    
  
     UPDATE A SET NEW_DISCOUNT_PERCENTAGE= CAST(ROUND( A.NEW_DISCOUNT_AMOUNT*100/(A.NEW_MRP*A.QUANTITY ),3) AS NUMERIC(10,3))    
	 FROM CASHMEMO_ADJ_DET_UPLOAD A     
	 where sp_id=@CSP_ID  and  isnull(NEW_DISCOUNT_PERCENTAGE,0)=0 and isnull(NEW_DISCOUNT_AMOUNT,0)<>0
	    
		  IF @CROUNDITEMLEVEL='1'  
		  begin
		   UPDATE CASHMEMO_ADJ_DET_UPLOAD WITH (ROWLOCK) SET NEW_DISCOUNT_AMOUNT=round(NEW_DISCOUNT_AMOUNT,0)  
		   WHERE sp_id=@CSP_ID   
  
   
		   UPDATE A SET NEW_DISCOUNT_PERCENTAGE= CAST(ROUND( A.NEW_DISCOUNT_AMOUNT*100/(A.NEW_MRP*A.QUANTITY ),3) AS NUMERIC(10,3))    
		   FROM CASHMEMO_ADJ_DET_UPLOAD A     
		   where sp_id=@CSP_ID    
		  -- WHERE A.OLD_DISCOUNT_AMOUNT<>0    
           
		   end 

		   UPDATE A SET NEW_NET= ((NEW_MRP*QUANTITY )-(NEW_DISCOUNT_AMOUNT ))    
		   FROM CASHMEMO_ADJ_DET_UPLOAD A     
		   where  sp_id=@CSP_ID    

      
    
      END    
      ELSE    
      BEGIN    
    
        PRINT ' 2 CHECK MRP LESS '    
  
	
    
	   UPDATE A SET  NEW_MRP=CASE WHEN ISNULL(@MRP_ROUNDING_LEVEL,'')<>'1' THEN CEILING(NEW_MRP)    
			WHEN ISNULL(@MRP_ROUNDING_LEVEL,'')='1' THEN FLOOR(NEW_MRP)    
		 ELSE NEW_MRP END,ReduceMrp=1    
	   FROM CASHMEMO_ADJ_DET_UPLOAD A     
	   WHERE  SP_ID=@CSP_ID    
  
    
    
      
	   UPDATE A SET NEW_DISCOUNT_AMOUNT = (A.NEW_MRP *A.NEW_DISCOUNT_PERCENTAGE /100   )*QUANTITY
	   FROM CASHMEMO_ADJ_DET_UPLOAD A     
	   WHERE A.OLD_DISCOUNT_AMOUNT<>0    
	   and sp_id=@CSP_ID    
    
	   UPDATE A SET NEW_NET= ((NEW_MRP*QUANTITY )-(NEW_DISCOUNT_AMOUNT ))    
	   FROM CASHMEMO_ADJ_DET_UPLOAD A     
	   where  sp_id=@CSP_ID   
     
  
	   IF @CROUNDITEMLEVEL='1'  
	   UPDATE CASHMEMO_ADJ_DET_UPLOAD WITH (ROWLOCK) SET NEW_NET=round(NEW_NET,0)  
	   WHERE sp_id=@CSP_ID   
	   
	   UPDATE A SET CMM_DISCOUNT_AMOUNT=ROUND( (NEW_NET *a.CMM_DISC_PERCENTAGE /100),2)
	   FROM CASHMEMO_ADJ_DET_UPLOAD  A WITH (NOLOCK)
       WHERE SP_ID=@CSP_ID   
	  
  
    
     END    
       
 
      
    SET @NSTEP=90    
     UPDATE A SET NEW_SALE =B.NEW_NET     
     FROM #TMPSUMMARY_DISC A    
     JOIN    
     (    
     SELECT CM_DT ,SUM(NEW_NET-CMM_DISCOUNT_AMOUNT ) AS NEW_NET    
     FROM CASHMEMO_ADJ_DET_UPLOAD    
     where  sp_id=@CSP_ID     
     GROUP BY CM_DT    
     ) B ON A.CM_DT =B.CM_DT    
       
      SET @NSTEP=100    
        
         
    
    if @NREDUCETYPE =1
    DELETE FROM CASHMEMO_ADJ_DET_UPLOAD WHERE SP_ID =@CSP_ID AND ISNULL(LESS_DISCOUNT,0)=0    
    
    GOTO END_PROC    
    
  
            
END TRY          
BEGIN CATCH          
     SET @CERRORMSG='ERROR IN SP_GETCASHMEMO_ADJ_NEW,STEP-'+LTRIM(STR(@NSTEP))+'SQL ERROR: #'+LTRIM(STR(ERROR_NUMBER())) + '  ' + ERROR_MESSAGE()          
END CATCH               
          
END_PROC:       

--select * from #TMPSUMMARY_DISC 

--select * from CASHMEMO_ADJ_DET_UPLOAD
--where sp_id =@CSP_ID
     
 IF @NMODE<>1    
 BEGIN    
   IF ISNULL(@CERRORMSG,'')<>''    
       SELECT @CERRORMSG AS ERRMSG    
   ELSE     
     SELECT cast(1 as bit) as chk,A.CM_DT ,A.TOTAL_SALE ,A.TOTAL_CASH_SALE ,A.DISCOUNT_APPLY_AMOUNT ,    
            A.REDUCE_AMOUNT ,    
            b.NEW_SALE AS  NEW_SALE,    
		   old_sale-isnull(b.NEW_SALE,0) AS AUTO_REDUCE_AMOUNT,    
		   DIFF=CASE WHEN ISNULL(A.REDUCE_AMOUNT,0)<>0 THEN  A.REDUCE_AMOUNT-(old_sale-isnull(b.NEW_SALE,0) ) ELSE 0 END,    
		   @CSP_ID AS SP_ID   ,  
		   cast('' as varchar(10))  customerMobile, cast('' as varchar(100)) as customerName ,  
		    cast('' as varchar(10)) CM_NO,cast('' as  varchar(50)) CM_ID,  
			cast(0 as numeric(10,2)) as Discount_amount, cast(0 as numeric(10,2)) Discount_Percentage ,A.Return_amount   
    FROM #TMPSUMMARY_DISC A   
	left join
	(
	  select CM_DT ,
	         sum(NEW_NET -CMM_DISCOUNT_AMOUNT) as NEW_SALE ,
			 sum(OLD_NET  -CMM_DISCOUNT_AMOUNT) as old_sale
	  from CASHMEMO_ADJ_DET_UPLOAD
	  where sp_id =@CSP_ID
	  group by CM_DT
	) b on a.CM_DT =b.CM_DT 
    ORDER BY CM_DT     
  
 END    
    
                        
    
END    
  --alter table CASHMEMO_ADJ_DET_UPLOAD add CMM_DISC_PERCENTAGE numeric(10,3)
   --alter table CASHMEMO_ADJ_DET_UPLOAD add ReduceMrp bit