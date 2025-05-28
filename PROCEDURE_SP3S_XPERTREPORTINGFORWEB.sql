CREATE PROCEDURE SP3S_XPERTREPORTINGFORWEB
(
@IQUERYID INT,
@cWhere Varchar(500)='',
@cWhere2 Varchar(500)=''
)
AS
BEGIN

   
IF @IQUERYID = 1    
GOTO LBL1  
ELSE IF  @IQUERYID = 2    
GOTO LBL2  
ELSE IF  @IQUERYID = 3   
GOTO LBL3  


LBL1:


SELECT   'Stock Analysis'  AS ReportCategory ,'X001' as Rep_code ,1 as Sorder
UNION
SELECT   'Transaction Analysis'  AS ReportCategory ,'TR01' as Rep_code , 2 as Sorder
UNION
SELECT   'Transaction Summary'  AS ReportCategory ,'TR02' as Rep_code, 3 as Sorder
UNION
SELECT   'Pendency Analysis '  AS ReportCategory ,'TR03' as Rep_code ,4 as Sorder
UNION
SELECT   'Customer Analysis '  AS ReportCategory ,'TR04' as Rep_code,5 as Sorder
Order by sorder

GOTO LAST  


LBL2:

	SELECT a.rep_id,a.rep_name,	(case when  a.XPERT_REP_CODE='R1' then 'X001'  
	 when  a.XPERT_REP_CODE='R2' then 'TR01' when  a.XPERT_REP_CODE='R3' then 'TR02'
	 when a.XPERT_REP_CODE='R4' then 'TR03' when a.XPERT_REP_CODE='R5' then 'TR04' else 'X001' End) As Rep_Code,
	 a.user_rep_type,a.Remarks
	FROM rep_mst a (NOLOCK) 	
	JOIN USERS C on a.user_code = c.user_code 
	WHERE    c.username =@cwhere    and  (@cWhere2='' or a.XPERT_REP_CODE =@cWhere2 )
	And  XPERT_REP_CODE  <> '' and a.xn_history=0
	UNION
	SELECT a.rep_id,a.rep_name,	(case when  a.XPERT_REP_CODE='R1' then 'X001'  
	when  a.XPERT_REP_CODE='R2' then 'TR01' when  a.XPERT_REP_CODE='R3' then 'TR02'
	when a.XPERT_REP_CODE='R4' then 'TR03' when a.XPERT_REP_CODE='R5' then 'TR04' else 'X001' End) As Rep_Code,
	a.user_rep_type,a.Remarks
	FROM replocs r (nolock)
	join rep_mst a (NOLOCK) on r.rep_id= a.rep_id 
	join reportType b (NOLOCK) ON a.rep_code=b.rep_code 
	JOIN USERS C (nolock) on r.user_code = c.user_code 
	WHERE    c.username =@cwhere    and  (@cWhere2='' or a.XPERT_REP_CODE =@cWhere2 )
	And  XPERT_REP_CODE  <> '' and a.xn_history=0
	order by rep_name

GOTO LAST  

LBL3:

select Filter_id, Filter_Name ,Filter_display,a.rep_code from Xpert_filter_Mst  a
where a.rep_code =@cWhere
GOTO LAST  



LAST:

END








	--sP3S_XPERTREPORTINGFORWEB 2, 'super', 'Transaction Analysis'    





