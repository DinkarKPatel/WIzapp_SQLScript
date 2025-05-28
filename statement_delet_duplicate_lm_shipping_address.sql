with cte as
(
select sr=row_number() over(partition by ac_code, shipping_ac_code order by ac_code, shipping_ac_code desc ), * from lm_shipping_details
)
DELETE from cte where sr>1