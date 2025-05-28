update a set ac_name=a.ac_name+'_'+a.ac_code from lm01106 a join LM01106 b on b.AC_NAME=a.AC_NAME
where b.AC_CODE<>a.AC_CODE
