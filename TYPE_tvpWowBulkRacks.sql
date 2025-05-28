CREATE TYPE tvpWowBulkRacks as table
(
locId VARCHAR(5),
zoneId VARCHAR(7),
zoneName VARCHAR(500),
rackId VARCHAR(7),
rackName VARCHAR(500),
rackCategoryCode VARCHAR(10),
rackCategoryName VARCHAR(500),
maxStock NUMERIC(10,2),
rackSectionName VARCHAR(500)
)
