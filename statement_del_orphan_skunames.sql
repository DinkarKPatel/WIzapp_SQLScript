DELETE a FROM sku_names a LEFT OUTER JOIN sku b ON a.product_code=b.product_code
WHERE b.product_code IS NULL