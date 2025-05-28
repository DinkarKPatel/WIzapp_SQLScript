
;with cte as
(
select AC_CODE ,ac_name  ,dept_id=left(AC_CODE,2),inactive,
       Dup=row_number() over(partition by ac_name,left(AC_CODE,2) order by isnull(inactive,0) ,ac_code desc )
from lm01106 
)


Update A set ac_name=ac_name+'_'+dept_id +(case when Dup<=2 then '' else '_'+cast(Dup as varchar(10)) end )
from cte A where Dup>1




