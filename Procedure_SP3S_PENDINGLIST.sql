    
CREATE PROCEDURE SP3S_PENDINGLIST    
(    
 @DFMDATE DATETIME='2024-02-01',    
 @DTODATE DATETIME='2024-03-05',    
 @CLOCID VARCHAR(5)='',    
 @Cusercode varchar(10)=''    
)    
AS    
BEGIN    
            
   Declare  @tblDeatils table (SRNo numeric(5,1),Details varchar(max),Val numeric(9,0))    
    
         DECLARE @choLocid varchar(5),@ccurlocid varchar(5)    
             
         SELECT @ccurlocid=VALUE  FROM CONFIG WHERE CONFIG_OPTION ='LOCATION_ID'    
              
         SELECT @CHOLOCID=VALUE  FROM CONFIG WHERE CONFIG_OPTION ='HO_LOCATION_ID'    
             
    
   PRINT '1.WAREHOUSE TO LOCATION INVOICE NOT RECEIVED BY LOCATION (GIT)'    
    
             
         INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
   SELECT 1 as SRNo, 'PENDING GOODS RECEIVE ADVICE' AS DETAILS, COUNT( A.INV_NO) AS PENDING_CHALLANS    
   FROM INM01106 A (NOLOCK)    
   LEFT JOIN PIM01106 B (NOLOCK) ON A.INV_ID=B.INV_ID AND B.CANCELLED=0 AND B.RECEIPT_DT <=@DTODATE AND B.RECEIPT_DT <>''    
   WHERE A.INV_DT BETWEEN @DFMDATE AND @DTODATE AND A.INV_MODE =2 AND A.CANCELLED =0 AND B.INV_ID IS NULL    
      AND A. TARGET_BIN_ID <>'999' AND (@CLOCID ='' OR A.PARTY_DEPT_ID=@CLOCID)    
      AND (@Cusercode ='' OR A.USER_CODE =@Cusercode)    
       
   PRINT '2.NO OF PACKSLIP PENDING (NOT RECEIVED BY LOCATION)'    
             
          INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
    SELECT 2 as SRNo, 'PACKETS NOT YET RECEIVED' AS DETAILS,  COUNT(DISTINCT IND.PS_ID ) AS PENDING_PACKSLIP    
    FROM INM01106 A (NOLOCK)    
    JOIN IND01106 IND (NOLOCK) ON A.INV_ID =IND.INV_ID     
    LEFT JOIN PIM01106 B (NOLOCK) ON A.INV_ID=B.INV_ID AND B.CANCELLED=0 AND B.RECEIPT_DT <=@DTODATE AND B.RECEIPT_DT <>''    
    WHERE A.INV_DT BETWEEN @DFMDATE AND @DTODATE AND A.INV_MODE =2 AND A.CANCELLED =0 AND B.INV_ID IS NULL    
    AND A. TARGET_BIN_ID <>'999' AND (@CLOCID ='' OR A.PARTY_DEPT_ID=@CLOCID)    
    AND (@Cusercode ='' OR A.USER_CODE =@Cusercode)    
       
  PRINT '3.NO OF PACKSLIP RECEIVED BY LOCATION IN 888 BIN'    
      
  if @CHOLOCID<>@ccurlocid    
  begin    
       
   INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
   SELECT 3 as SRNo, 'NO OF PACKSLIP RECEIVED BY LOCATION IN 888 BIN' AS DETAILS,  COUNT(DISTINCT B.PS_ID ) AS RECEIVED_PACKSLIP_888     
   FROM PIM01106 A (NOLOCK)    
   JOIN PID01106 B (NOLOCK) ON A.MRR_ID=B.MRR_ID     
   WHERE A.INV_MODE=2 AND  A.CANCELLED =0    
   AND A.RECEIPT_DT  BETWEEN @DFMDATE AND @DTODATE     
   AND A. BIN_ID <>'999' AND (@CLOCID ='' OR A.DEPT_ID=@CLOCID)    
   AND (@Cusercode ='' OR A.USER_CODE =@Cusercode)    
      
  end    
  else    
  begin    
      
     INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
   SELECT 3 as SRNo, 'NO OF PACKSLIP RECEIVED BY LOCATION IN 888 BIN' AS DETAILS,  COUNT(DISTINCT B.PS_ID ) AS RECEIVED_PACKSLIP_888     
   FROM PIM01106 A (NOLOCK)    
   JOIN ind01106 B (NOLOCK) ON A.inv_id=B.inv_id    
   join INM01106 c (NOLOCK) on b.INV_ID =c.INV_ID      
   WHERE A.INV_MODE=2 AND  A.CANCELLED =0 and c.CANCELLED =0    
   AND A.RECEIPT_DT  BETWEEN @DFMDATE AND @DTODATE     
   AND A. BIN_ID <>'999' AND (@CLOCID ='' OR A.DEPT_ID=@CLOCID)    
   AND (@Cusercode ='' OR A.USER_CODE =@Cusercode)    
      
      
  end    
      
  PRINT '4.NO OF PACKSLIP RECEIVED BY LOCATION THAT DAY 888 TO DEFAULT'    
      
   INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
  SELECT 4 as SRNo, 'NO OF PACKSLIP RECEIVED BY LOCATION THAT DAY 888 TO DEFAULT' AS DETAILS ,    
           COUNT(DISTINCT A.PICK_LIST_ID ) AS RECEIVED_PACKSLIP_888_TO_DEFALT     
  FROM FLOOR_ST_DET A (NOLOCK)    
  JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID     
  WHERE B.CANCELLED =0 AND A.SOURCE_BIN_ID ='888'    
  AND  B.RECEIPT_DT  BETWEEN @DFMDATE AND @DTODATE     
  AND (@CLOCID ='' OR B.location_Code =@CLOCID)    
  AND (@Cusercode ='' OR b.USER_CODE =@Cusercode)    
    
  PRINT '5.Goods Return WH or Other Location (count of memo no)'    
            
         INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
  select 5 as SRNo, 'Goods Return WH or Other Location (count of memo no)' ,    
          sum(Total) as Totalreturn    
  from     
  (    
  SELECT count(*) as Total     
  FROM WPS_MST A (NOLOCK)    
  where isnull(GITBIN_INV_ID,'')<>'' and a.CANCELLED =0    
  AND (@CLOCID ='' OR A.location_Code =@CLOCID)    
  and a.PS_DT BETWEEN @DFMDATE AND @DTODATE     
  AND (@Cusercode ='' OR A.USER_CODE =@Cusercode)    
  union all    
  SELECT count(*) as Total     
  FROM DNPS_MST A (NOLOCK)    
  where isnull(GITBIN_INV_ID,'')<>'' and a.CANCELLED =0    
  AND (@CLOCID ='' OR A.location_Code =@CLOCID)    
  and a.PS_DT BETWEEN @DFMDATE AND @DTODATE     
  AND (@Cusercode ='' OR A.USER_CODE =@Cusercode)    
  ) A    
    
    
  PRINT '6.Cash counter NO of Bill (without cancelled)'    
            
        
            
   INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
  select 6 as SRNo, 'Cash counter NO of Bill (without cancelled)' as Details, count(*)  as TotalBill    
  from cmm01106 A (NOLOCK)    
  where  a.CANCELLED =0    
  AND (@CLOCID ='' OR A.location_Code =@CLOCID)    
  and a.CM_DT BETWEEN @DFMDATE AND @DTODATE     
  AND (@Cusercode ='' OR A.USER_CODE =@Cusercode)    
    
  PRINT '7.Pending Hold Bill after  Day close'    
  
  
  declare @dLogdate dateTime 
  
  SELECT TOP 1  @DLOGDATE=CONVERT (VARCHAR(10), MAX(LOG_DATE),121) FROM DAYCLOSE_LOG A 
  WHERE DEPT_ID=@CLOCID  
  AND  ISNULL(A.ENDTIME_LOCAL,'')<>''

  
  set @dLogdate= isnull(@dLogdate,'')


   INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
  select 7 as SRNo, 'Pending Hold Bill after  Day close' as Details, count(*)  as HoldBill    
  from cmm_hold A (NOLOCK)    
  where  a.CANCELLED =0    
  AND (@CLOCID ='' OR A.hbd_location_code=@CLOCID)    
  and a.CM_DT BETWEEN @DFMDATE AND @DTODATE     
  AND (@Cusercode ='' OR A.USER_CODE =@Cusercode)  
  and a.CM_DT >= @dLogdate
    
  PRINT '8.Canceled bill that day'    
            
        INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
  select 8 as SRNo, 'Canceled bill that day' as Details, count(*)  as cancelledBill    
  from cmm01106 A (NOLOCK)    
  where  a.CANCELLED =1    
  AND (@CLOCID ='' OR A.location_Code =@CLOCID)    
  and a.CM_DT BETWEEN @DFMDATE AND @DTODATE     
  AND (@Cusercode ='' OR A.USER_CODE =@Cusercode)    
      
      
  PRINT '9.Reprint bill that day'    
            
  INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
  select 9 as SRNo, 'Reprint bill that day' as Details, count(*)  as ReprintBill    
  from cmm01106 A (NOLOCK)    
  where  a.CANCELLED =0    
  and isnull(copies_ptd,0)>1    
  AND (@CLOCID ='' OR A.location_Code =@CLOCID)    
  and a.CM_DT BETWEEN @DFMDATE AND @DTODATE     
  AND (@Cusercode ='' OR A.USER_CODE =@Cusercode)    
      
      
  PRINT '10.No of credit note issue that day'    
      
  INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
  SELECT 10 as SRNo,'No of credit note issue that day' DETAILS,COUNT (cm_id)    
  FROM PAYMODE_XN_DET A  (NOLOCK)         
     JOIN CMM01106 B (NOLOCK) ON A.MEMO_ID = B.CM_ID      
  WHERE  SUBSTRING(B.CM_NO,5,1)='N'     
     AND A.PAYMODE_CODE = '0000004'          
     AND B.CANCELLED = 0      
     AND A.AMOUNT < 0          
     AND B.CM_DT BETWEEN @DFMDATE AND @DTODATE     
       AND (@CLOCID='' OR B.location_Code=@CLOCID)    
       AND (@Cusercode ='' OR b.USER_CODE =@Cusercode)    
         
         
  PRINT '11.No of credit note received that day'    
  INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
   select 11 as SrNo ,'No of credit note received that day' DETAILS,    
          count(*) as VAL    
   from     
  (    
    SELECT P.ADJ_MEMO_ID           
    FROM PAYMODE_XN_DET P (NOLOCK)         
    JOIN CMM01106 Q (NOLOCK) ON P.MEMO_ID = Q.CM_ID          
    WHERE P.PAYMODE_CODE = '0000001'          
    AND   Q.CANCELLED = 0      
    AND Q.CM_DT BETWEEN @DFMDATE AND @DTODATE       
    AND (@CLOCID='' OR Q.location_Code=@CLOCID)    
          AND (@Cusercode ='' OR q.USER_CODE =@Cusercode)    
           
    UNION ALL      
    SELECT P.ADJ_MEMO_ID           
    FROM PAYMODE_XN_DET P (NOLOCK)         
    JOIN ARC01106 Q (NOLOCK) ON P.MEMO_ID = Q.ADV_REC_ID          
    WHERE P.PAYMODE_CODE = '0000001'          
    AND   Q.CANCELLED = 0        
    AND Q.adv_rec_dt  BETWEEN @DFMDATE AND @DTODATE     
    AND (@CLOCID='' OR Q.location_Code=@CLOCID)    
          AND (@Cusercode ='' OR Q.USER_CODE =@Cusercode)    
         
        
  ) A    
      
      
  PRINT '12.No of Till open that day'    
      
  INSERT INTO @TBLDEATILS(SRNO,DETAILS,VAL)    
  select 12 as SrNo ,'No of Till open that day' DETAILS,    
          count(*) as VAL    
     from till_shift_mst    
  where open_date BETWEEN @DFMDATE AND @DTODATE     
  AND (@CLOCID='' OR location_Code=@CLOCID)    
  AND (@Cusercode ='' OR USER_CODE =@Cusercode)    
              
      
  select 'POS Bill Summary' Details,    
        SUM(Sales)  Sales ,    
        SUM(SalesReturn)  SalesReturn ,    
        SUM(Discount) as [Discount],    
        SUM(TaxAmount )as TaxAmount,    
        SUM([Net Sale] ) [Net Sale],    
        SUM( a.round_off +isnull(a.gst_round_off,0) ) Roundoff,    
         SUM(net_amount) as [Net Payable]    
         into #tmpcmm    
  from cmm01106 A (nolock)    
  join     
  (    
   select b.cm_id ,    
          SUM(CASE WHEN QUANTITY>0 THEN (NET-CMM_DISCOUNT_AMOUNT  )+manual_discount_amount ELSE 0 END)  Sales,    
          SUM(CASE WHEN QUANTITY<0 THEN (NET-CMM_DISCOUNT_AMOUNT  )+manual_discount_amount ELSE 0 END)  SalesReturn ,    
          SUM(manual_discount_amount) as [Discount],    
          SUM(case when tax_method =2 then  cgst_amount +sgst_amount +igst_amount else 0 end  )as TaxAmount,    
          SUM(NET-cmm_discount_amount ) [Net Sale]     
   from  cmd01106 b (nolock)     
   group by b.cm_id     
   ) b on a.cm_id=b.cm_id      
  where a.CANCELLED =0 and     
  a.CM_DT between @DFMDATE AND @DTODATE     
  AND (@CLOCID='' OR A.location_Code=@CLOCID)    
  AND (@Cusercode ='' OR a.USER_CODE =@Cusercode)    
      
      
  insert into @TBLDEATILS(SRNO,DETAILS,VAL)    
  SELECT 13.1 AS SRNO,    
         'Sales' DETAILS,    
         SALES     
  FROM #TMPCMM    
  union all    
  SELECT 13.2 AS SRNO,    
         'Returns' DETAILS,    
         SalesReturn     
  FROM #TMPCMM    
  union all    
  SELECT 13.3 AS SRNO,    
        'Discount' DETAILS,    
         [Discount]     
  FROM #TMPCMM    
  union all    
  SELECT 13.4 AS SRNO,    
         'TaxAmount' DETAILS,    
         TaxAmount     
  FROM #TMPCMM    
  union all    
  SELECT 13.5 AS SRNO,    
         'Net Sale' DETAILS,    
         [Net Sale]     
  FROM #TMPCMM    
  union all    
  SELECT 13.6 AS SRNO,    
         'Roundoff' DETAILS,    
         [Roundoff]      
  FROM #TMPCMM    
  union all    
  SELECT 13.7 AS SRNO,    
         'Net Payable' DETAILS,    
         [Net Payable]      
  FROM #TMPCMM    
      
  insert into @TBLDEATILS(SRNO,DETAILS,VAL)    
  SELECT 14.1 as SRNO,  'Credit bill Receiveingl Amt' Details,  SUM(isnull(amount,0)) AS RECEIPT_AMOUNT  --adjust credit note in sale   
   FROM PAYMODE_XN_DET P (NOLOCK)         
   JOIN CMM01106 Q (NOLOCK) ON P.MEMO_ID = Q.CM_ID          
   WHERE P.PAYMODE_CODE = '0000001'          
   AND   Q.CANCELLED = 0    
   and amount >0 and adj_memo_id <>''
   AND Q.CM_DT BETWEEN @DFMDATE AND @DTODATE       
   AND (@CLOCID='' OR Q.location_Code=@CLOCID)    
   AND (@Cusercode ='' OR q.USER_CODE =@Cusercode)        
    
  union all    
  SELECT 14.2 as SRNO,  'NO of refund bill Amt' Details,REFUNDAMOUNT = SUM(ABS(A.AMOUNT))     
  from     
  (    
    --SELECT P.ADJ_MEMO_ID  ,sum(amount) as   amount       
    --FROM PAYMODE_XN_DET P (NOLOCK)         
    --JOIN CMM01106 Q (NOLOCK) ON P.MEMO_ID = Q.CM_ID          
    --WHERE P.PAYMODE_CODE = '0000001'          
    --AND   Q.CANCELLED = 0      
    --AND Q.CM_DT BETWEEN @DFMDATE AND @DTODATE       
    --AND (@CLOCID='' OR LEFT(Q.CM_ID ,2)=@CLOCID)    
    --AND (@Cusercode ='' OR q.USER_CODE =@Cusercode)    
    --group by P.ADJ_MEMO_ID  
  
    --UNION ALL      
    SELECT P.ADJ_MEMO_ID , sum(p.amount) as   amount         
    FROM PAYMODE_XN_DET P (NOLOCK)         
    JOIN ARC01106 Q (NOLOCK) ON P.MEMO_ID = Q.ADV_REC_ID          
    WHERE P.PAYMODE_CODE = '0000001'          
    AND   Q.CANCELLED = 0        
    AND Q.adv_rec_dt  BETWEEN @DFMDATE AND @DTODATE     
    AND (@CLOCID='' OR Q.location_Code=@CLOCID)    
    AND (@Cusercode ='' OR Q.USER_CODE =@Cusercode)        
    group by P.ADJ_MEMO_ID  
  ) A    
      
       
  insert into @TBLDEATILS(SRNO,DETAILS,VAL)    
  select 15.1 as SRNO,  'Petty Cash Receipt' Details,AMOUNT = SUM(ABS(b.xn_amount))     
  from pem01106 A (nolock)    
  join ped01106 b (nolock) on a.pem_memo_id =b.pem_memo_id     
  where a.cancelled =0 and xn_type='CR'    
  and a.pem_memo_dt between @DFMDATE AND @DTODATE     
  AND (@CLOCID='' OR A.location_Code=@CLOCID)    
        AND (@Cusercode ='' OR a.USER_CODE =@Cusercode)    
  union all    
  select 15.2 as SRNO,  'Petty Cash Payment' Details,AMOUNT = SUM(ABS(b.xn_amount))     
  from pem01106 A (nolock)    
  join ped01106 b (nolock) on a.pem_memo_id =b.pem_memo_id     
  where a.cancelled =0 and xn_type='DR'    
  and a.pem_memo_dt between @DFMDATE AND @DTODATE     
  AND (@CLOCID='' OR A.location_Code=@CLOCID)    
        AND (@Cusercode ='' OR a.USER_CODE =@Cusercode)    
      
      
  insert into @TBLDEATILS(SRNO,DETAILS,VAL)    
  select 16 as SrNo, c.paymode_name , SUM(a.amount)    
  from PAYMODE_XN_DET A    
  join cmm01106 b on a.memo_id =b.cm_id     
  join paymode_mst c on a.paymode_code =c.paymode_code     
  where b.CANCELLED =0    
  and b.cm_dt between @DFMDATE AND @DTODATE     
  AND (@CLOCID='' OR b.location_Code=@CLOCID)    
        AND (@Cusercode ='' OR b.USER_CODE =@Cusercode)    
  Group by c.paymode_name    
  order by c.paymode_name    
       
      
  select Details,VAL from @TBLDEATILS    
  Order by SRNo     
    
      
    
END