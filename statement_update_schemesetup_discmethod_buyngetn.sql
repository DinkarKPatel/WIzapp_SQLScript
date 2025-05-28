--- Needed to change in this update becuase of mark binding changed in frontend by Anil w.r.t. synching the discount method mark
---  across all kind of schemes windows (Date :23-05-2023)
update SCHEME_SETUP_DET set disc_method=(case when disc_method=3 then 2 else 3 end) where promotional_scheme_id='sch0015'
and disc_method in (2,3)