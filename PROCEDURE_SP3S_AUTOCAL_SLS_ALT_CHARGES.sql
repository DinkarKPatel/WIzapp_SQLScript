CREATE PROCEDURE SP3S_AUTOCAL_SLS_ALT_CHARGES
as
BEGIN
	print 'enter alt charges picking'
	--UPDATE #tSlsDetTable SET ALT_JOB_RATE=0

	--UPDATE a SET ALT_JOB_RATE=(CASE WHEN (xn_value_without_gst+cgst_amount+sgst_amount+igst_amount)>BASE_NRV
	--THEN ats.JOBRATE_MORETHAN_NRV ELSE ats.JOBRATE_LESSTHAN_NRV END) FROM #tSlsDetTable a
	--JOIN sku b (NOLOCK) ON a.PRODUCT_CODE=b.product_code
	--JOIN article c (NOLOCK) ON c.article_code=b.article_code
	--JOIN ALTERATIONSETUP ATS (NOLOCK) ON ats.SUB_SECTION_CODE=c.sub_section_code AND a.alt_job_code=ats.job_code AND ats.dept_id=a.dept_id 
	--WHERE ISNULL(a.Hold_for_Alter,0)=1 AND ISNULL(a.ALT_charges_applicable,0)=1 

	--UPDATE a SET ALT_VENDOR_JOB_RATE=ats.VENDOR_RATE FROM #tSlsDetTable a
	--JOIN sku b (NOLOCK) ON a.PRODUCT_CODE=b.product_code
	--JOIN article c (NOLOCK) ON c.article_code=b.article_code
	--JOIN ALTERATIONSETUP ATS (NOLOCK) ON ats.SUB_SECTION_CODE=c.sub_section_code
	--WHERE  ISNULL(a.Hold_for_Alter,0)=1

	--UPDATE a SET atd_charges=b.atd_charges FROM #tSlsmstTable a
	--JOIN (SELECT sum(ALT_JOB_RATE*QUANTITY) AS atd_charges FROM #tSlsDetTable
	--	  ) b ON 1=1
END