declare @CLOCATIONID varchar(5)/*Rohit 01-11-2024*/,@cCustomerCode CHAR(12)

select top 1 @CLOCATIONID=value from config where config_option='location_id'

EXEC GETNEXTKEY @CTABLENAME='CUSTDYM',    
    @CCOLNAME='CUSTOMER_CODE',    
    @NWIDTH=12,    
    @CPREFIX=@CLOCATIONID,    
    @NLZEROS=1,    
    @CFINYEAR='',    
    @NROWCOUNT=2,    
    @CNEWKEYVAL=@cCustomerCode OUTPUT    


EXEC CHANGED_FOREIGN_KEY_COLUMN_DATA
@TABLE_NAME='CUSTDYM',
@COLUMN_NAME='customer_code',
@OLD_VALUE='',
@NEW_VALUE='000000000000'


update custdym set customer_code=@cCustomerCode,inactive=0 WHERE customer_code=''
