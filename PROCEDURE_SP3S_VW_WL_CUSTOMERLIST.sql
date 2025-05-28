CREATE PROC sp3S_VW_WL_CUSTOMERLIST  
(  
@cWHERE varchar(max)=''  
)  
  
AS       
begin  
  
	DECLARE @CCMD NVARCHAR(MAX)  
 
	Declare @val Varchar(MAX), @val2 Varchar(MAX);
	Select @val = COALESCE(@val + ', ' + replace(column_name,'_name','_key_name') + ' as ['+ table_caption +']', replace(column_name,'_name','_key_name')+ ' as [' + table_caption+']') 
	From  CONFIG_CUST_ATTR where table_caption  <> ''    order by table_caption 

	Select @val2 = COALESCE(@val2 + ', ' + replace(column_name,'_name','_key_name') ,replace(column_name,'_name','_key_name')) 
	From CONFIG_CUST_ATTR  where table_caption  <> '' order by table_caption 

	if  isnull(@val,'')=''
	Set @val=''	
	Else
	Set @val=','+ @val

	if  isnull(@val2,'')=''
	Set @val2=''	
	Else
	Set @val2=','+ @val2
	
        
  SET @CCMD=N'SELECT  CAST ( 1 AS BIT ) AS PRINT_LBL,A.CUSTOMER_CODE AS MEMO_ID,  
   A.USER_CUSTOMER_CODE AS CUSTOMER_ID, A.CUSTOMER_CODE,  
        A.CUSTOMER_TITLE,  
        (PF.PREFIX_NAME+'''' +A.CUSTOMER_FNAME) AS CUSTOMER_FNAME,   
        A.CUSTOMER_LNAME,     
		case when a.gender=3 then ''Transgender'' when a.gender=2 then ''Female'' else ''Male'' end as Gender ,
        A.ADDRESS0 AS ADDRESS,  
  A.ADDRESS1  AS ADDRESS1,   
  A.ADDRESS2 AS ADDRESS2,  
  A.ADDRESS9 AS ADDRESS3,  
  B.AREA AS AREA, B. PIN, B.CITY,       
  B.STATE, B.REGION_NAME, A.PHONE1, A.PHONE2, A.MOBILE, A.EMAIL, A.OPENING_BALANCE,  
  SUM(ISNULL(V.CREDIT_AMOUNT,0)) CREDIT_AMOUNT ,       
  (CASE WHEN A.DT_BIRTH='''' THEN NULL ELSE CONVERT(DATETIME,''1932-''+CAST(DATEPART(M,A.DT_BIRTH) AS VARCHAR(5))+''-''+CAST(DATEPART(D,A.DT_BIRTH) AS VARCHAR(5))) END) AS DT_BIRTH,   
  (CASE WHEN A.DT_ANNIVERSARY ='''' THEN NULL ELSE CONVERT(DATETIME,''1932-''+CAST(DATEPART(M,A.DT_ANNIVERSARY) AS VARCHAR(5))+''-''+CAST(DATEPART(D,A.DT_ANNIVERSARY) AS VARCHAR(5))) END) AS DT_ANNIVERSARY,  
     A.INACTIVE,  
        A.CARD_NO ,A.CARD_NAME, (CASE WHEN A.FLAT_DISC_CUSTOMER =0 THEN ''NO'' ELSE ''YES'' END) AS FLAT_DISC_CUSTOMER  
        ,FLAT_DISC_PERCENTAGE,A.DT_CREATED , A.DT_CARD_ISSUE , A.DT_CARD_EXPIRY  '+@val + '
FROM CUSTDYM A 
LEFT OUTER JOIN 
(
  Select CUSTOMER_CODE,AREA , PIN , CITY, STATE, REGION_NAME' +@val2 + '  FROM CUST_ATTR_NAMES 
) B ON A.CUSTOMER_CODE= B.CUSTOMER_CODE  
LEFT OUTER JOIN PREFIX PF ON PF.PREFIX_CODE=A.PREFIX_CODE     
LEFT OUTER JOIN CMM01106 CMM ON CMM.CUSTOMER_CODE=A.CUSTOMER_CODE  
LEFT OUTER JOIN VW_BILL_PAYMODE V ON V.MEMO_ID=CMM.CM_ID AND XN_TYPE = ''SLS''  
     
WHERE A.CUSTOMER_CODE<>''000000000000'' and '  + @cWHERE + '  
GROUP BY  A.USER_CUSTOMER_CODE , A.CUSTOMER_CODE,  
        A.CUSTOMER_TITLE,  
        A.CUSTOMER_FNAME,  
        PF.PREFIX_NAME,   
        A.CUSTOMER_LNAME,     
		case when a.gender=3 then ''Transgender'' when a.gender=2 then ''Female'' else ''Male'' end ,
        A.ADDRESS0 ,  
  A.ADDRESS1  ,   
  A.ADDRESS2 ,  
  A.ADDRESS9 ,  
  B.AREA , B.PIN , B.CITY,       
  B.STATE, B.REGION_NAME, A.PHONE1, A.PHONE2, A.MOBILE, A.EMAIL, A.OPENING_BALANCE,  
  A.DT_BIRTH, A.DT_ANNIVERSARY, A.INACTIVE,  
        A.CARD_NO ,A.CARD_NAME, (CASE WHEN A.FLAT_DISC_CUSTOMER =0 THEN ''NO'' ELSE ''YES'' END)   
        ,FLAT_DISC_PERCENTAGE,A.DT_CREATED , A.DT_CARD_ISSUE , A.DT_CARD_EXPIRY '+@val2+''     
    
  PRINT @cCMD  
  EXEC SP_EXECUTESQL @cCMD  
  
end  