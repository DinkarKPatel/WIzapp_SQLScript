CREATE PROCEDURE SP3S_COMPARE_PROCEDURE_CREATE_TIME
(
	@cUserCode VARCHAR(50)
)
AS
BEGIN
	;WITH A
	AS
	( 
		select DISTINCT b.proc_name,a.modify_date  from sys.procedures a(NOLOCK)
		JOIN modules_proc b(NOLOCK)ON b.proc_name=a.name
	)
	,B 
	AS
	( 
		select DISTINCT b.proc_name,a.name AS USER_PROC_NAME,a.create_date  from sys.procedures a(NOLOCK)
		JOIN modules_proc b(NOLOCK) ON b.proc_name+'_'+b.module_name+'_'+LTRIM(RTRIM(@cUserCode))=a.name
	)
	SELECT A.*,B.USER_PROC_NAME,B.create_date,CAST( (CASE WHEN A.modify_date > ISNULL(B.create_date,'') THEN 1 ELSE 1 END) AS BIT) AS DROP_N_CREATE
	FROM A
	LEFT OUTER JOIN B ON A.proc_name=B.proc_name
END