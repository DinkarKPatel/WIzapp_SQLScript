IF NOT EXISTS (SELECT TOP 1 'U' FROM PPC_SHIPPING_DETAILS)
   BEGIN
     INSERT PPC_SHIPPING_DETAILS	( SHIPPING_MODE, SHIPPING_NAME )  
     SELECT 	  SHIPPING_MODE=1, SHIPPING_NAME='BY AIR' 
     UNION ALL
     SELECT 	  SHIPPING_MODE=2, SHIPPING_NAME='BY TRAIN' 
     UNION ALL
     SELECT 	  SHIPPING_MODE=3, SHIPPING_NAME='BY ROAD'
     UNION ALL
     SELECT 	  SHIPPING_MODE=4, SHIPPING_NAME='BY SHIP'
END
