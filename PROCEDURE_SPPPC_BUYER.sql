CREATE PROCEDURE SPPPC_BUYER
AS
BEGIN
     
     
     SELECT A.AC_CODE ,B.AC_NAME  
     FROM PPC_BUYER_ORDER_MST A
     JOIN LM01106 B ON A.AC_CODE =B.AC_CODE 
     WHERE A.CANCELLED=0
     GROUP BY A.AC_CODE ,B.AC_NAME
  
END
