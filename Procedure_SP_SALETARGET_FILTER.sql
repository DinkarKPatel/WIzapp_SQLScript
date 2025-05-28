create Procedure SP_SALETARGET_FILTER
(
@DFROMDATE dateTime ='2024-04-01', 
@DTODATE dateTime= '2025-03-31', 
@MEMO_NAME varchar(100)='MAR25', 
@MEMO_ID varchar(10)=''
)
as
begin
    
	select a.location_code ,b.dept_name, A.MEMO_NO,A.MEMO_DT  ,A.MEMO_NAME ,u.username 
	from SLSTARGET_MST A (nolock)
	join location b (nolock) on A.location_code =b.dept_id 
	join users u (nolock) on A.USER_CODE =u.user_code 
	where A.MEMO_DT between @DFROMDATE and @DTODATE
	and (@MEMO_NAME='' or A.MEMO_NAME =@MEMO_NAME)
	and (@MEMO_ID='' or A.MEMO_ID=@MEMO_ID)

end

