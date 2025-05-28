CREATE TYPE tvpWowPaymodexndet as table
(
	amount numeric(10,2),
	adj_memo_id varchar(22),
	paymode_code char(7),
	paymode_name varchar(100),
	ref_no varchar(100),
	row_id varchar(40),
	xn_type varchar(10),
	LAST_UPDATE datetime,
	currency_conversion_rate numeric(10,2),
	remarks varchar(max),
	memo_id varchar (40)
)