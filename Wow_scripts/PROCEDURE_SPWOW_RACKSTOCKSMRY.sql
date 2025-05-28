CREATE PROCEDURE SPWOW_RACKSTOCKSMRY 
  (
  @cZone varchar(100)='',
  @cLocId VARCHAR(4)=''
  )
 AS   
BEGIN  
  
  
 declare @cbaseTableCategory varchar(200),@cCmd nvarchar(max),@cCategoryCol VARCHAR(200),@bRetStock bit,
 @cCategoryColHeader VARCHAR(200) ,@cWhereClause VARCHAR(200),@cCategoryJOin VARCHAR(200)  
  
 select top 1 @cCategoryCol = 'sn.' + org_para_name,@cCategoryColHeader = ltrim(rtrim(org_para_name))   
 from rack_management_category_config where selected = 1   
  
 set @cCategoryJOin=(case when @cCategoryColHeader='SECTION_NAME' THEN ' Left outer JOIN sectionm (Nolock) ON sectionm.section_code=b.rack_category_code'  
       else  ' Left outer JOIN sectiond (Nolock) on sectiond.sub_section_code=b.rack_category_code left outer join sectionm (nolock)  on sectiond.section_code= sectionm.section_code' END)  
 
 
 if @cCategoryColHeader= 'Sub_Section_name'
 Begin
 Set @cCategoryColHeader=   'SUB_SECTION_NAME+ '' (''+section_name+'')'''
 End

 -- Had to do this because of the Racks API is being callled in GRN Pack slip entry to fetch the List 
 -- of Racks against selected Zone and it is returning slow due to join of pmt in the below query (Date : 01-06-2023 - Sanjay)
 set @bRetStock=1
 if @cLocId=''
	set @bRetStock=0	

set @cCmd= '  
 Select    L.dept_id as locId, dept_name as locName, dept_alias as locAlias, z.BIN_ID as zoneId, z.bin_name as ZoneName,  
 r.bin_id as rackId, r.bin_name as rackNo , r.rack_category_code as rackCategoryCode, r.categoryName,r.maxStock,   
 R.currentStock,( r.maxStock - r.currentStock)  as availableQty,ISNULL(r.inactive,0) rack_inactive,  
 cast( (case when r.maxStock=0 then 0 else (r.maxStock-isnull(r.currentStock,0))*100/r.maxStock end) as numeric(10,2))   as stockPercentage  
 From location L  (Nolock)
 join   
 (  
  Select  b.dept_id, z.bin_id,z.bin_name From  bin_loc  b  
  join bin z (Nolock) on b.BIN_ID =z.bin_id    
  where  (z.major_bin_id = z.BIN_ID  or z.rack_bin =1   ) 
  AND b.bin_id='''+ @cZone+'''
 ) z on l.dept_id= z.dept_id  
  
 Left outer join   
 (  
  Select  b.bin_id,b.bin_name, b.major_bin_id,isnull(b.maxStock,0) as  maxStock , b.rack_category_code ,'+@cCategoryColHeader+'  as categoryName,'+   
  +(case when @bRetStock=1 then ' sum(isnull(p.quantity_in_stock,0)) ' else ' 0 ' end)+' as currentStock,b.inactive  
  From  bin b (Nolock)  ' + @cCategoryJOin+(case when @bRetStock=1 then    
  ' left outer Join pmt01106 p  (nolock) on  b.BIN_ID = p.BIN_ID  ' else '' end)+ 
  ' where  (b.major_bin_id <> b.BIN_ID  and b.rack_bin =1)   or (b.bin_id=b.major_bin_id) 
  group by b.bin_id,b.bin_name, b.major_bin_id,b.maxStock , b.rack_category_code ,  
  b.inactive ,'+@cCategoryColHeader+'  
  
 ) R on z.bin_id= r.major_bin_id  
  where  l.primary_source_for_aro =1 and (l.dept_id='''+@cLocId+''' OR '''+@cLocId+'''='''')'  
  
    
 PRINT @cCmd  
 EXEC SP_EXECUTESQL @cCmd  
  
  
 End






