CREATE PROCEDURE SP3S_GETBILLINFO_PENDINGBB ---- Do not overwrite in May2022 Release
@CTEMPTABLENAME VARCHAR(200),
@CDEBTORHEADS  VARCHAR(max),
@BSHOWMRRNO BIT=0,
@DT_TODATE DATETIME='',
@NDUEBILLMODE NUMERIC(2,0)=1,
@nMode NUMERIC(1,0)=1
,@bCalledFromSingleLedger BIT=0
,@nSortOn NUMERIC(2,0)=1---@nSortOn=1 ON BILL DATE; @nSortOn=2 ON DUE DATE
AS
BEGIN			
	DECLARE @CCMD NVARCHAR (MAX)
	
	IF @nMode=5 ---- If called from Dynamic Reporting of Billas Payable, then we have to forcly take mrr_no
		SET @BSHOWMRRNO=1

	print 'enter SP3S_GETBILLINFO_PENDINGBB_chk'
	SET @CCMD=N'UPDATE A SET BILL_DT=(SELECT TOP 1 VOUCHER_DT FROM BILL_BY_BILL_REF B
								  JOIN VD01106 C ON C.VD_ID=B.VD_ID	
								  JOIN VM01106 D ON D.VM_ID=C.VM_ID
								  JOIN LM01106 LM ON LM.AC_CODE=C.AC_CODE
								  WHERE B.REF_NO=A.REF_NO AND C.AC_CODE=A.AC_CODE
								  AND CANCELLED=0 AND B.X_TYPE=a.PENDING_AMOUNT_CR_DR
								  ORDER BY VOUCHER_DT
								 ) FROM  '+@CTEMPTABLENAME+' A'
	PRINT @CCMD								 
	EXEC SP_EXECUTESQL @CCMD


	SET @CCMD=N'UPDATE A SET DUE_DATE=ISNULL((SELECT TOP 1 due_dt FROM BILL_BY_BILL_REF B
								  JOIN VD01106 C ON C.VD_ID=B.VD_ID	
								  JOIN VM01106 D ON D.VM_ID=C.VM_ID
								  JOIN LM01106 LM ON LM.AC_CODE=C.AC_CODE
								  WHERE B.REF_NO=A.REF_NO AND C.AC_CODE=A.AC_CODE
								  AND CANCELLED=0 AND B.X_TYPE=a.PENDING_AMOUNT_CR_DR
								  ORDER BY VOUCHER_DT
								 ),'''') FROM  '+@CTEMPTABLENAME+' A WHERE isnull(due_date,'''')='''''
	PRINT @CCMD
	EXEC SP_EXECUTESQL @CCMD

					
	SET @cCmd=N'UPDATE '+@CTEMPTABLENAME+' SET DUE_DATE=DATEADD(DAY,CR_DAYS,ISNULL(BILL_DT,''''))  
				WHERE ISNULL(DUE_DATE,'''')='''''
	
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd																		 			
					
	SET @cCmd=N'UPDATE  '+@CTEMPTABLENAME+' SET DUE_DATE=ISNULL(BILL_DT,'''') WHERE ISNULL(DUE_DATE,'''')='''''
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd


	SET @CCMD=N'UPDATE '+@CTEMPTABLENAME+' SET DISPLAY_REF_NO=LEFT(REF_NO,LEN(REF_NO)-9)
			WHERE ISDATE(RIGHT(REF_NO,8))=1 AND SUBSTRING(REVERSE(REF_NO),9,1)=''/'''
	PRINT @CCMD
	EXEC SP_EXECUTESQL @CCMD	
	
	if @CTEMPTABLENAME in ('#tmppendingbills')
	begin
		SET @CCMD=N'UPDATE A SET cost_center_dept_id=(SELECT TOP 1 cost_center_dept_id FROM BILL_BY_BILL_REF B
									  JOIN VD01106 C ON C.VD_ID=B.VD_ID	
									  JOIN VM01106 D ON D.VM_ID=C.VM_ID
									  JOIN LM01106 LM ON LM.AC_CODE=C.AC_CODE
									  WHERE B.REF_NO=A.REF_NO AND C.AC_CODE=A.AC_CODE
									  AND CANCELLED=0 AND B.X_TYPE=a.PENDING_AMOUNT_CR_DR
									  ORDER BY VOUCHER_DT
									 ) FROM  '+@CTEMPTABLENAME+' A'
		PRINT @CCMD								 
		EXEC SP_EXECUTESQL @CCMD				

	end

		--Start purchase details*************
	
	print 'enter step-1 of multibb'
	IF NOT (@nMode=4)
	BEGIN			
	
		SET @CCMD=N'ALTER TABLE '+@CTEMPTABLENAME+' add mrr_id VARCHAR(50)'
		EXEC SP_EXECUTESQL @cCmd

		IF @nMode<>1
		BEGIN
			SET @cCmd=N'UPDATE a SET mrr_id=pim.mrr_id,mrr_no=pim.mrr_no	FROM '+@CTEMPTABLENAME+' a
			JOIN bill_by_bill_ref b (NOLOCK) ON a.REF_NO=b.REF_NO
			JOIN vd01106 c (NOLOCK) ON c.vd_id=b.vd_id  AND c.ac_code=a.ac_code
			JOIN vm01106 d (NOLOCK) ON d.vm_id=c.vm_id
			JOIN POSTACT_VOUCHER_LINK e (NOLOCK) ON e.vm_id=d.vm_id
			JOIN pim01106 pim (NOLOCK) ON pim.mrr_id=e.memo_ID
			WHERE e.xn_type=''PUR'' AND d.cancelled=0'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		END		
		IF @NMODE in(3,6,7,8)
	 	BEGIN
			print 'enter step-2 of multibb'
					SET @cCmd=N'UPDATE A  SET LM_CR_DAYS=B.CREDIT_DAYS,LM_DISCOUNT_PERCENTAGE=B.DISCOUNT_PERCENTAGE FROM #TMPPENDINGBILLS A
					JOIN LMP01106 B ON A.AC_CODE=B.AC_CODE'
					EXEC SP_EXECUTESQL @cCmd

					SET @cCmd=N'UPDATE A SET REF_DATE=B.REF_DATE FROM #TMPPENDINGBILLS A
					JOIN (SELECT REF_NO,AC_CODE,MIN(BILL_DT) AS REF_DATE FROM #TMPPENDINGBILLS WHERE ISNULL(BILL_DT,'''')<>''''
						  GROUP BY REF_NO,AC_CODE) B ON A.AC_CODE=B.AC_CODE AND A.REF_NO=B.REF_NO' 
	 				EXEC SP_EXECUTESQL @cCmd

					print 'enter step-3 of multibb'
					IF @NMODE in(3,7,8)
					BEGIN
						SET @cCmd=N'UPDATE #TMPPENDINGBILLS  SET DEBIT_AMOUNT=NULL,debit_amount_forex=NULL WHERE ISNULL(DEBIT_AMOUNT,0)=0'
	 					EXEC SP_EXECUTESQL @cCmd
						SET @cCmd=N'UPDATE #TMPPENDINGBILLS  SET CREDIT_AMOUNT=NULL,credit_amount_forex=NULL WHERE ISNULL(CREDIT_AMOUNT,0)=0'
	 					EXEC SP_EXECUTESQL @cCmd
						SET @cCmd=N'UPDATE #TMPPENDINGBILLS  SET CD_AMOUNT=NULL WHERE ISNULL(CD_AMOUNT,0)=0'
	 					EXEC SP_EXECUTESQL @cCmd
						SET @cCmd=N'UPDATE #TMPPENDINGBILLS  SET CD_PERCENTAGE=NULL WHERE ISNULL(CD_PERCENTAGE,0)=0'
	 					EXEC SP_EXECUTESQL @cCmd


						SET @cCmd=N'ALTER TABLE #TMPPENDINGBILLS ALTER COLUMN BILL_DT DATETIME NOT NULL'
						EXEC SP_EXECUTESQL @cCmd
						SET @cCmd=N'ALTER TABLE #TMPPENDINGBILLS ALTER COLUMN REF_NO VARCHAR(100) NOT NULL'
						EXEC SP_EXECUTESQL @cCmd
						SET @cCmd=N'ALTER TABLE #TMPPENDINGBILLS ADD CONSTRAINT PK_1 PRIMARY KEY (BILL_DT,REF_NO)'
						EXEC SP_EXECUTESQL @cCmd

						DECLARE @NSUMVALUE NUMERIC(20,2),@NSUMVALUEForex NUMERIC(20,2),@cAcCode CHAR(10)
						SELECT DISTINCT ac_code INTO #tmpSUm FROM #TMPPENDINGBILLS      

						WHILE EXISTS (SELECT TOP 1 * from #tmpsum)      
						BEGIN       
							SELECT TOP 1 @cAcCode=ac_code FROM #tmpsum      
	  
							SElECT @NSUMVALUE=0,@NSUMVALUEForex=0
      
							;WITH A    
							AS    
							(    
							SELECT TOP 100 PERCENT *     
							FROM #TMPPENDINGBILLS    
							WHERE ac_code=@cAcCode
							ORDER BY bill_dt
							)     

							UPDATE #TMPPENDINGBILLS SET RunningTotal=ISNULL(RunningTotal,0)+ISNULL(@NSUMVALUE,0),      
							@NSUMVALUE=ISNULL(@NSUMVALUE,0)+ISNULL(DEBIT_AMOUNT,0)-ISNULL(Credit_Amount  ,0),
							RunningTotal_forex=ISNULL(RunningTotal_forex,0)+ISNULL(@NSUMVALUE,0),      
							@NSUMVALUEForex=ISNULL(@NSUMVALUEForex,0)+ISNULL(debit_amount_forex,0)-ISNULL(credit_amount_forex  ,0)							
							WHERE Ac_Code=@cAcCode 

							UPDATE #TMPPENDINGBILLS SET RunningTotal_CrDr=(CASE WHEN ISNULL(RunningTotal,0)>=0 
							THEN 'Dr' ELSE 'Cr' END),RunningTotal_crdr_Forex=(CASE WHEN ISNULL(RunningTotal_Forex,0)>=0 
							THEN 'Dr' ELSE 'Cr' END),
							RunningTotal_Str=(CAST(ABS(RunningTotal) AS VARCHAR(50))+ 
							CASE WHEN  ISNULL(RunningTotal,0)=0 THEN '' WHEN ISNULL(RunningTotal,0)>0 THEN 'Dr' ELSE 'Cr' 
							END),RunningTotal_str_Forex=(CAST(ABS(RunningTotal_Forex) AS VARCHAR(50))+ 
							CASE WHEN  ISNULL(RunningTotal_Forex,0)=0 THEN '' WHEN ISNULL(RunningTotal_Forex,0)>0 THEN 'Dr' ELSE 'Cr' 
							END) WHERE ac_code=@cAcCode

							DELETE FROM #tmpsum WHERE ac_code=@cAcCode
						END

					END

					DECLARE @CDRCRTABLE VARCHAR(100)
					set @CDRCRTABLE=''
					IF @NMODE=6
					BEGIN
					    
						IF OBJECT_ID('TEMPDB..##TMPPENDINGBILLS','U') IS NOT NULL
						   DROP TABLE ##TMPPENDINGBILLS
						   set @CDRCRTABLE=' into ##TMPPENDINGBILLS '

					END
					DECLARE @cSettlementCol VARCHAR(100),@cSettlementJoin varchar(200)

					IF @Nmode=3 AND @NDUEBILLMODE IN (2,3)
						SELECT @cSettlementCol=',voucher_no as settlement_voucher_no,voucher_dt as settlement_voucher_dt',@cSettlementJoin=' LEFT JOIN vm01106 vm (NOLOCK) ON vm.vm_id=a.settlement_vm_id '
					ELSE
						SELECT @cSettlementCol=','''' as settlement_voucher_no,'''' as settlement_voucher_dt',@cSettlementJoin=''

					print 'enter step-4 of multibb'
					SET @cCmd=N'SELECT A.*,
						CASE WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)>0 then A.DEBIT_AMOUNT
						  WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)=0 and ISNULL(A.CREDIT_AMOUNT,0)>0  then A.CREDIT_AMOUNT
					         
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.CREDIT_AMOUNT,0)>0 then A.CREDIT_AMOUNT
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.CREDIT_AMOUNT,0)=0 and ISNULL(A.DEBIT_AMOUNT,0)>0  then A.DEBIT_AMOUNT
						  ELSE ''0'' END AS BILL_AMOUNT,
					      
						  CASE WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.debit_amount_forex,0)>0 then A.debit_amount_forex
						  WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.debit_amount_forex,0)=0 and ISNULL(A.credit_amount_forex,0)>0  
						  then A.credit_amount_forex
					         
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.credit_amount_forex,0)>0 then A.credit_amount_forex
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.credit_amount_forex,0)=0 and ISNULL(A.debit_amount_forex,0)>0  
						  then A.debit_amount_forex
						  ELSE ''0'' END AS BILL_AMOUNT_Forex,

					 CASE WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)>0  and ISNULL(A.CREDIT_AMOUNT,0)>0 then A.CREDIT_AMOUNT
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)>0  and ISNULL(A.CREDIT_AMOUNT,0)>0 then A.DEBIT_AMOUNT
						  ELSE 0 END AS ADJUSTED_AMOUNT,
						  
					CASE  WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.debit_amount_forex,0)>0  and ISNULL(A.credit_amount_forex,0)>0 
						  then A.credit_amount_forex
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.debit_amount_forex,0)>0  and ISNULL(A.credit_amount_forex,0)>0 
						  then A.debit_amount_forex
						  ELSE 0 END AS ADJUSTED_AMOUNT_Forex,
						
						DATEDIFF(DAY,ISNULL(b.DUE_DATE,a.due_date) ,'''+CONVERT(VARCHAR,@DT_TODATE,110)+''') AS OVER_DUE_DAYS ,
						ADDRESS0,ADDRESS1,ADDRESS2,AREA_NAME,CITY,STATE,PINCODE,
						PHONES_O,PHONES_R,PHONES_FAX,ISNULL(LM.LM_REMARKS,'''') AS [AC_REMARKS],
						ISNULL(B.pur_total_amount,0) AS PUR_BILL_AMOUNT,
						ISNULL(B.pur_total_amount_forex,0) AS PUR_BILL_AMOUNT_Forex,
						ISNULL(B.PUR_QTY,0)   AS PUR_QTY,
						ISNULL(B.PRT_QTY,0)   AS PRT_QTY,
						ISNULL(B.pur_qty,0)-isnull(b.PRt_QTY,0)   AS NET_PUR_QTY,
						ISNULL(B.SLS_QTY ,0)  AS SOLD_QTY,
						ISNULL(B.SLS_PP  ,0) AS COST_OF_SOLD_QTY,
						ISNULL(B.clearance_pct,0) AS CLEARANCE_PCT,mst.contact_person_name,mst.designation,mst.phones,mst.email,mobile
						,CONVERT(VARCHAR(50),ISNULL(b.DUE_DATE,a.due_date),105) AS DUE_DATE_STR,CONVERT(VARCHAR(50),A.BILL_DT,105) AS BILL_DT_STR'+
						@cSettlementCol+@CDRCRTABLE+'
						FROM #TMPPENDINGBILLS A
						LEFT JOIN bill_by_bill_inv_status B (NOLOCK) ON A.mrr_id=b.pur_mrr_id
						JOIN LMP01106 lmp ON A.AC_CODE=lmp.AC_CODE
						JOIN LM01106 LM ON LM.AC_CODE=a.AC_CODE
						JOIN AREA C ON C.AREA_CODE=lmp.AREA_CODE
						JOIN CITY D ON D.CITY_CODE=C.CITY_CODE
						JOIN STATE E ON E.STATE_CODE=D.STATE_CODE	
						LEFT OUTER JOIN
						(	SELECT ROW_NUMBER() OVER (PARTITION BY AC_CODE ORDER BY AC_CODE) AS SR_NO,
							AC_CODE,contact_person_name,
							designation,phones,email FROM CONTACT_PERSONS_MST (NOLOCK) 
						)mst ON mst.sr_no=1 AND mst.ac_code=lm.ac_code'+@cSettlementJoin+' 		
						WHERE ('+str(@NDUEBILLMODE)+'=1 AND ISNULL(b.DUE_DATE,a.due_date)<='''+convert(varchar,@DT_TODATE,110)+''') 
								OR '+str(@NDUEBILLMODE)+'<>1
							ORDER BY AC_NAME,BILL_DT,display_ref_no' ---Do not touch this Default Order otherwise Runinngtotal sequencec gets disturbed (Sanjay)

								
					PRINT @CCMD
					EXEC SP_EXECUTESQL @CCMD		

				END	
				ELSE			
				IF @nMode=1
				BEGIN
							

					SET @CCMD=N'	SELECT A.*,
						CASE WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)>0 then A.DEBIT_AMOUNT
						  WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)=0 and ISNULL(A.CREDIT_AMOUNT,0)>0  then A.CREDIT_AMOUNT
					         
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.CREDIT_AMOUNT,0)>0 then A.CREDIT_AMOUNT
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.CREDIT_AMOUNT,0)=0 and ISNULL(A.DEBIT_AMOUNT,0)>0  then A.DEBIT_AMOUNT
						  ELSE ''0'' END AS BILL_AMOUNT,
					         
					 CASE WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)>0  and ISNULL(A.CREDIT_AMOUNT,0)>0 then A.CREDIT_AMOUNT
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)>0  and ISNULL(A.CREDIT_AMOUNT,0)>0 then A.DEBIT_AMOUNT
						  ELSE 0 END AS ADJUSTED_AMOUNT,
					              
						DATEDIFF(DAY,ISNULL(b.DUE_DATE,a.due_date) ,'''+CONVERT(VARCHAR(10),@DT_TODATE,121)+''') AS OVER_DUE_DAYS ,
						ISNULL(b.PUR_TOTAL_AMOUNT,0) AS PUR_BILL_AMOUNT,
						ISNULL(B.PUR_QTY,0)   AS PUR_QTY,
						ISNULL(B.PRT_QTY,0)   AS PRT_QTY,
						ISNULL(B.pur_qty,0)-isnull(b.PRt_QTY,0)   AS NET_PUR_QTY,
						ISNULL(B.SLS_QTY ,0)  AS SOLD_QTY,
						ISNULL(B.SLS_PP  ,0) AS COST_OF_SOLD_QTY,
						ISNULL(B.clearance_pct,0) AS CLEARANCE_PCT,
						loc.dept_id+''-''+dept_name as dept_name
						FROM '+@CTEMPTABLENAME+' A
						JOIN LM01106 LM ON A.AC_CODE=LM.AC_CODE
						JOIN HD01106 HD ON HD.HEAD_CODE =LM.HEAD_CODE 
						LEFT JOIN bill_by_bill_inv_status B (NOLOCK) ON A.MRR_ID =B.pur_MRR_ID
						JOIN location loc (NOLOCK) ON  loc.dept_id=a.cost_center_dept_id
						ORDER BY AC_NAME '

					PRINT @CCMD
					EXEC SP_EXECUTESQL @CCMD		

				END		
				ELSE
				IF @nMode=5
				BEGIN
					TRUNCATE TABLE BILLBYBILL_DYNAMIC_REP
					
					
					SET @cCmd=N'INSERT BILLBYBILL_DYNAMIC_REP	( bb_ac_code, AC_NAME,broker_ac_name,mrr_no, REF_DATE,GRN_DT,bb_ref_no, REF_NO, DUE_DATE,DUE_DAYS,
					 DEBIT_AMOUNT,CREDIT_AMOUNT,pending_amount,PENDING_TYPE,HEAD_NAME,OVER_DUE_DAYS,
					 PUR_BILL_AMOUNT,pur_qty,PRT_QTY, NET_PUR_QTY, sold_qty,
					 cost_of_sold_qty,CLEARANCE_PCT,BILL_AMOUNT ,ADJUSTED_AMOUNT,CR_DAYS,PARTY_BILL_DT,cost_center_dept_id ) 
	         
					SELECT 	a.ac_code, A.AC_NAME,'''' broker_ac_name, b.mrr_no,A.BILL_DT, 
					CASE  WHEN ISNULL(ISNULL(b.DUE_DATE,a.due_date),'''')='''' THEN '''' ELSE  ISNULL(b.DUE_DATE,a.due_date)-A.CR_DAYS END, 
					a.ref_no bb_ref_no,DISPLAY_REF_NO AS REF_NO,ISNULL(b.DUE_DATE,a.due_date) as DUE_DATE, 
					0 AS DUE_DAYS, DEBIT_AMOUNT,CREDIT_AMOUNT,abs(pending_amount)*
					(CASE WHEN PENDING_AMOUNT_CR_DR=''Cr'' THEN 1 ELSE -1 END) pending_amount,
					(CASE WHEN PENDING_AMOUNT_CR_DR=''Dr'' THEN ''RECEIVABLE'' ELSE ''PAYABLE'' END) 
					AS PENDING_TYPE ,HD.HEAD_NAME,
					0 AS OVER_DUE_DAYS ,
					
					ISNULL(B.pur_TOTAL_AMOUNT,0) AS PUR_BILL_AMOUNT,
					ISNULL(B.PUR_QTY,0)   AS PUR_QTY,
					ISNULL(B.PRT_QTY,0)   AS PRT_QTY,
					ISNULL(B.pur_qty,0)-isnull(b.PRt_QTY,0)   AS NET_PUR_QTY,
					ISNULL(B.SLS_QTY ,0)  AS SOLD_QTY,
					ISNULL(B.SLS_PP  ,0) AS COST_OF_SOLD_QTY,
					ISNULL(B.clearance_pct,0) AS CLEARANCE_PCT,
					 CASE WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)>0 then A.DEBIT_AMOUNT
						  WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)=0 and ISNULL(A.CREDIT_AMOUNT,0)>0  then (-1)* A.CREDIT_AMOUNT
					         
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.CREDIT_AMOUNT,0)>0 then A.CREDIT_AMOUNT
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.CREDIT_AMOUNT,0)=0 and ISNULL(A.DEBIT_AMOUNT,0)>0  then (-1)*  A.DEBIT_AMOUNT
						  ELSE ''0'' END AS BILL_AMOUNT,
					         
					 CASE WHEN LM.HEAD_CODE in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)>0  and ISNULL(A.CREDIT_AMOUNT,0)>0 then A.CREDIT_AMOUNT
						  WHEN LM.HEAD_CODE not in('+@CDEBTORHEADS+') and ISNULL(A.DEBIT_AMOUNT,0)>0  and ISNULL(A.CREDIT_AMOUNT,0)>0 then A.DEBIT_AMOUNT
						  ELSE 0 END AS ADJUSTED_AMOUNT,
						  A.CR_DAYS,ISNULL(PUR_VENDOR_BILL_DT,'''') PARTY_BILL_DT,A.cost_center_dept_id
					              
					FROM #TMPPENDINGBILLS A
					JOIN LM01106 LM ON A.AC_CODE=LM.AC_CODE
					JOIN HD01106 HD ON HD.HEAD_CODE =LM.HEAD_CODE
					LEFT JOIN bill_by_bill_inv_status B (NOLOCK) ON A.MRR_ID =B.pur_MRR_ID
					'
					PRINT @CCMD
					EXEC SP_EXECUTESQL @CCMD		
					

					print 'Update Broker from Invoice'
					UPDATE a WITH (ROWLOCK) SET broker_ac_name=LM.ac_name FROM BILLBYBILL_DYNAMIC_REP a 
					JOIN bill_by_bill_ref bb (NOLOCK) ON bb.ref_no=a.bb_ref_no
					JOIN vd01106 c (NOLOCK) ON c.vd_id=bb.vd_id AND c.ac_code=a.bb_ac_code
					JOIN postact_voucher_link d (NOLOCK) ON d.vm_id=c.vm_id
					JOIN vm01106 vm (NOLOCK) ON vm.vm_id=d.vm_id
					JOIN inm01106 e (NOLOCK) ON e.inv_id=d.memo_id
					JOIN lm01106 lm (NOLOCK) ON lm.AC_CODE=e.BROKER_AC_CODE
					WHERE left(d.xn_type,3)='WSL' AND vm.cancelled=0 AND e.BROKER_AC_CODE NOT IN('','0000000000')
					

					print 'Update Broker and Adj Remarks from Credit Note'
					UPDATE a WITH (ROWLOCK) SET broker_ac_name=LM.ac_name,ref_remarks=bb.adj_remarks
					FROM BILLBYBILL_DYNAMIC_REP a 
					JOIN bill_by_bill_ref bb (NOLOCK) ON bb.ref_no=a.bb_ref_no
					JOIN vd01106 c (NOLOCK) ON c.vd_id=bb.vd_id AND c.ac_code=a.bb_ac_code
					JOIN postact_voucher_link d (NOLOCK) ON d.vm_id=c.vm_id
					JOIN vm01106 vm (NOLOCK) ON vm.vm_id=d.vm_id
					JOIN Cnm01106 e (NOLOCK) ON e.Cn_id=d.memo_id
					JOIN lm01106 lm (NOLOCK) ON lm.AC_CODE=e.BROKER_AC_CODE
					WHERE left(d.xn_type,3) IN ('WSR','PRT') AND vm.cancelled=0 AND 
					(e.BROKER_AC_CODE NOT IN('','0000000000') OR ISNULL(bb.adj_remarks,'')<>'')

					print 'Update Adj Remarks from Debit Note'
					UPDATE a WITH (ROWLOCK) SET ref_remarks=bb.adj_remarks
					FROM BILLBYBILL_DYNAMIC_REP a 
					JOIN bill_by_bill_ref bb (NOLOCK) ON bb.ref_no=a.bb_ref_no
					JOIN vd01106 c (NOLOCK) ON c.vd_id=bb.vd_id AND c.ac_code=a.bb_ac_code
					JOIN postact_voucher_link d (NOLOCK) ON d.vm_id=c.vm_id
					JOIN vm01106 vm (NOLOCK) ON vm.vm_id=d.vm_id
					JOIN rmm01106 e (NOLOCK) ON e.rm_id=d.memo_id
					JOIN lm01106 lm (NOLOCK) ON lm.AC_CODE=e.BROKER_AC_CODE
					WHERE left(d.xn_type,3) IN ('PRT') AND vm.cancelled=0 AND ISNULL(bb.adj_remarks,'')<>''
					
					UPDATE a WITH (ROWLOCK) SET broker_ac_name=Lb.ac_name FROM BILLBYBILL_DYNAMIC_REP a 
					left join lm_broker_details lmb (NOLOCK) ON lmb.ac_code=a.bb_ac_code
					LEFT JOIN lm01106 lb (NOLOCK) ON lb.ac_code=lmb.broker_ac_code
					WHERE ISNULL(A.BROKER_AC_NAME,'')=''


					UPDATE a WITH (ROWLOCK) SET cd_percentage=bb.cd_percentage
					FROM BILLBYBILL_DYNAMIC_REP a 
					JOIN bill_by_bill_ref bb (NOLOCK) ON bb.ref_no=a.bb_ref_no

					
					UPDATE BILLBYBILL_DYNAMIC_REP SET GRN_DT=NULL WHERE ISNULL(GRN_DT ,'')=''
					UPDATE BILLBYBILL_DYNAMIC_REP SET NETPAYBLE=BILL_AMOUNT-ADJUSTED_AMOUNT 
				

					UPDATE A SET  sold_qty=0,
						   cost_of_sold_qty=0,
						   CLEARANCE_PCT=0,
						   PRT_QTY=0,
						   NET_PUR_QTY=PUR_QTY
					FROM BILLBYBILL_DYNAMIC_REP A
					WHERE ISNULL(ABS(CLEARANCE_PCT),0)>100
				END			
				

	END					
END
------------ END OF PROCEDURE SP3S_GETBILLINFO_PENDINGBB