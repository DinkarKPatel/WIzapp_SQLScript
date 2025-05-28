
create Procedure SPWOW_AUDITTRAILREPORT
(
  @FromDate DateTime='2022-08-01',
  @ToDate DateTime='2022-08-26'

)
as
BEGIN
        SET NOCOUNT ON 
     --this Procedure will be  Display Audi Data Of all Transaction and variance is (Current-First)
	  Print '##Statrt'+convert(varchar(10),getdate(),121)
	 
		;WITH XN_AUDIT AS 
		(
		SELECT  A.XN_ID,AUDITED_ON [Edited Date and Time] ,CWIZUSERNAME,b.cm_dt [Memo date],b.cm_no [Memo no],b.Customer_code,
		       SR=Dense_rank() OVER ( partition by a.xn_id  ORDER BY AUDITED_ON) ,
			   [Original Amount]= CAST(A.OLDVAL AS numeric (14,2)),
			   b.NET_AMOUNT [Current Amount],u.username  as [Original User],
			   a.COMPUTER_NAME [Edited On Device],
			   CWIZUSERNAME  [Edited By (User)]
			 
		FROM XN_AUDIT_TRIAL_DET A
		JOIN CMM01106 B (nolock) ON A.XN_ID =B.CM_ID
		Left join users u on u.user_code =b.user_code 
		WHERE XN_TYPE ='SLS' 
		and b.CM_DT between @FromDate and @ToDate
		AND FIELD_NAME IN('NET_AMOUNT')
		--and b.cm_id='H10112000000H1H1-00005'
		
		)

		SELECT 'Retail Sale' [Transaction Type],  [Memo date], [Memo no],cust.mobile [Customer mobile] ,
		         isnull(Cust.customer_fname,'')+' '+isnull(customer_lname,'') as [Customer name],
				 [Original Amount],[Current Amount] ,[Current Amount]-[Original Amount] as [Amount Variance] ,
				[Original User],[Edited By (User)],[Edited On Device],[Edited Date and Time]
		FROM XN_AUDIT A 
		JOIN CUSTDYM CUST (NOLOCK) ON a.CUSTOMER_CODE =CUST.CUSTOMER_CODE
		where sr=1 

		--;with Audit_SLS as
		--(
		--	SELECT [Transaction Type],  [Memo date], [Memo no], [Customer name] ,[Customer mobile], [Edited Date and Time] ,
		--		   [Original Amount],[DeleteQty], NET_AMOUNT, [Edited By (User)],[Edited On Device],[Original User]
		--	FROM
		--	(
		--		SELECT [Transaction Type],  [Memo date], [Memo no], [Customer mobile] ,
		--			   [Customer name], [Edited Date and Time] ,A.COLUMNVALUE,A.COLUMNNAME,
		--			   NET_AMOUNT, [Edited By (User)],[Edited On Device],[Original User]
		--		FROM #TMPAUDIT A
		--	) a
		--	pivot 
		--	 ( 
		--		SUM(COLUMNVALUE) FOR COLUMNNAME IN ([Original Amount],[DeleteQty])  
		--	 ) AS PV1  
		 
		-- )

		-- select  [Transaction Type], [Memo date], [Memo no] ,[Customer mobile],[Customer name],
		--		 [Original Amount],NET_AMOUNT as [Current Amount],NET_AMOUNT-[Original Amount] as [Amount Variance],
		--		 [Original User],[Edited By (User)],[Edited On Device],[Edited Date and Time]

		-- from Audit_SLS a
		-- order by 1,2,3

	  Print '##END'++convert(varchar(10),getdate(),121)



END


--select top 100 * from XN_AUDIT_TRIAL_DET where XN_TYPE='sls'
--and xn_id='H10112000000H1H1-00005'
--order by AUDITED_ON