IF NOT EXISTS ( SELECT Xn_type FROM Print_Report_type WHERE Xn_type = 'WSL' )
BEGIN
	PRINT 'INSERTING DEFAULT ENTRY FOR Print_Report_type'
	INSERT Print_Report_type( Xn_type, Printtype,Printtype_value)  
	VALUES ( 'WSL','Invoice',1)

	INSERT Print_Report_type( Xn_type, Printtype,Printtype_value)  
	VALUES ( 'WSL','BOX',2)

	INSERT Print_Report_type( Xn_type, Printtype,Printtype_value)  
	VALUES ( 'WSL','Barcode',3)
END						 
