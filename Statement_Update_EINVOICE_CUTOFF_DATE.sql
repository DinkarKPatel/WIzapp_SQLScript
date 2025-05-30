DECLARE @EINVOICE_START_DATE VARCHAR(20)

SELECT @EINVOICE_START_DATE=VALUE FROM CONFIG WHERE CONFIG_OPTION='EINVOICE_START_DATE'
AND ISNULL(VALUE,'') <>''

UPDATE A SET EINVOICE_CUTOFF_DATE=@EINVOICE_START_DATE
FROM LOCATION A WITH (NOLOCK)
WHERE ISNULL(EINVOICE_CUTOFF_DATE,'')=''


Update a set ENABLE_EINVOICE_IN_RETAIL_SALE=1
FROM LOCATION A with (nolock)
WHERE ENABLE_EINVOICE_IN_RETAIL_SALE IS NULL


Update a set ENFORCE_YEAR_CODE_RETAIL_SALE=Enable_EInvoice
FROM LOCATION A with (nolock)
WHERE ENFORCE_YEAR_CODE_RETAIL_SALE IS NULL
