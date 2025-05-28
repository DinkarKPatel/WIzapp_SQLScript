
CREATE PROCEDURE SP3S_EOSS_SOR_SUPPLIER
(  
@QueryID int,  
@iSorType int=0,
@cWhere VArchar(50)=''
)   
AS  
BEGIN  


IF @QueryID=1 
GOTO LB11 
ELSE IF @QueryID=2
GOTO LB12
ELSE IF @QueryID=3
GOTO LB13
ELSE IF @QueryID=4
GOTO LB14
ELSE IF @QueryID=5
GOTO LB15
ELSE IF @QueryID=6
GOTO LB16
  
LB11:





DECLARE @CHEADCODE VARCHAR(MAX)  
SET @CHEADCODE=DBO.FN_ACT_TRAVTREE('0000000021')  
SELECT CAST(1 AS BIT)  AS CHK,A.ac_code,
AC_NAME ,AREA_NAME ,CITY,STATE FROM LMV01106   A
JOIN LM_SOR_TERMS_LINK B ON A.AC_CODE= B.AC_CODE 
WHERE   B.terms_id= @cWhere

union

SELECT CAST(0 AS BIT)  AS CHK,A.ac_code,  
AC_NAME ,AREA_NAME ,CITY,STATE FROM LMV01106   A  
WHERE ( CHARINDEX ( HEAD_CODE, @CHEADCODE ) > 0  OR ALLOW_CREDITOR_DEBTOR = 1 )       
AND A.INACTIVE = 0 and SOR_PARTY=  @iSorType   and a.ac_code not in (select ac_code from  LM_SOR_TERMS_LINK    
WHERE  terms_id=@cWhere  )

GOTO LAST 

 

LB12:



SELECT CAST(1 AS BIT)  AS CHK,A.ac_code,
AC_NAME ,AREA_NAME ,CITY,STATE FROM LMV01106   A
JOIN LM_SOR_TERMS_LINK B ON A.AC_CODE= B.AC_CODE 
WHERE   B.terms_id= @cWhere 

GOTO LAST 


LB13:

--SELECT CASE WHEN B.Dept_id IS NULL THEN CAST (0 AS BIT) ELSE CAST(1 AS BIT) END AS CHK,A.dept_id,
--dept_name ,AREA_NAME ,CITY,STATE FROM LOC_VIEW   A
--LEFT OUTER JOIN loc_SOR_TERMS_LINK B ON A.dept_id= B.DEPT_ID 
--WHERE  (@cWhere='' or B.terms_id=@cWhere )
--AND A.INACTIVE = 0 
--ORDER BY A.dept_id ,a.dept_name

SELECT  CAST(1 AS BIT) AS CHK,A.dept_id,
dept_name ,AREA_NAME ,CITY,STATE FROM LOC_VIEW   A
JOIN loc_SOR_TERMS_LINK B ON A.dept_id= B.DEPT_ID 
WHERE  B.terms_id=@cWhere 

UNION
SELECT  CAST(0 AS BIT) AS CHK,A.dept_id,  
dept_name ,AREA_NAME ,CITY,STATE FROM LOC_VIEW   A  
WHERE  A.inactive =0  and a.dept_id not in (select dept_id from  loc_SOR_TERMS_LINK    
WHERE  terms_id=@cWhere  )
ORDER BY A.dept_id ,a.dept_name  
  


GOTO LAST 

LB14:

SELECT  CAST(1 AS BIT)  AS CHK,A.dept_id,
dept_name ,AREA_NAME ,CITY,STATE FROM LOC_VIEW   A
JOIN loc_SOR_TERMS_LINK B ON A.dept_id= B.DEPT_ID 
WHERE  B.terms_id=@cWhere 
ORDER BY A.dept_id ,a.dept_name

GOTO LAST 
	

LB15:

select CAST(1 AS BIT)  AS CHK,id,Name from  TBL_EOSS_DISC_SHARE_MST a
 join lm_sor_terms_link b on a.id= b.terms_id  Where tran_type=1 
and b.ac_code = @cWhere
UNION ALL
select CAST(0 AS BIT)  AS CHK,id,Name from  TBL_EOSS_DISC_SHARE_MST a
Where tran_type=1  and id not in (Select terms_id  From lm_sor_terms_link where ac_code= @cWhere)

GOTO LAST 


LB16:

select CAST(1 AS BIT)  AS CHK,id,Name from  TBL_EOSS_DISC_SHARE_MST a
 join loc_sor_terms_link b on a.id= b.terms_id  Where tran_type=2 
and b.dept_id = @cWhere
UNION ALL
select CAST(0 AS BIT)  AS CHK,id,Name from  TBL_EOSS_DISC_SHARE_MST a
Where tran_type=2  and id not in (Select terms_id  From loc_sor_terms_link where dept_id= @cWhere)

GOTO LAST 

LAST:   
END  