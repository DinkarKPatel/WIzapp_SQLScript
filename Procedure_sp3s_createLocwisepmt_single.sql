CREATE Procedure sp3s_createLocwisepmt_single    
(    
 @cdbname varchar(100)='',    
 @dMinXndt dateTime     
)    
as    
       
   DECLARE @CSTEP VARCHAR(100),@CERRORMSG VARCHAR(1000),@cPmtTableName varchar(100),    
           @CCMD nvarchar(max),@dMaxXndt dateTime,@cPmtlocsTableName varchar(100)    
begin    
BEGIN TRY      
    
      
    
     set @cPmtTableName=@cdbname+'.dbo.pmtLocscbs'    
    
    
   IF OBJECT_ID(@cPmtTableName,'U') IS NULL                                  
   BEGIN        
    
   SET @CCMD=N'SELECT xn_dt=CAST('''' AS DATETIME),dept_id,quantity_in_stock as cbs_qty    
   INTO '+@cPmtTableName+' FROM '+@cDbName+'.dbo.pmt01106 WHERE 1=2'    
   PRINT @cCmd    
   EXEC SP_EXECUTESQL @cCmd    
            
   SET @CCMD=N'CREATE NONCLUSTERED INDEX IX_pmtLocscbs ON '+@cPmtTableName+' ([dept_id])    
   INCLUDE ([xn_dt],[cbs_qty])'    
   print @cCmd    
    EXEC SP_EXECUTESQL @cCmd    
    
   SET @CCMD=N'CREATE unique INDEX UNQ_pmtLocscbs  ON '+@cPmtTableName+' ([dept_id],[xn_dt])'    
   print @cCmd    
    EXEC SP_EXECUTESQL @cCmd    
    
   end    
    
     
   set @dMaxXndt  =convert(date,getdate()-1)    
    
    
   while @dMinXndt<=@dMaxXndt    
   begin    
           
    SET @CPMTLOCSTABLENAME=@CDBNAME+'_PMT.dbo.pmtlocs_'+convert(varchar,@dMinXndt,112)    
    
    
     IF OBJECT_ID(@CPMTLOCSTABLENAME,'U') IS not NULL                                  
        BEGIN       
       
     SET @CCMD=N'insert into '+@cPmtTableName+'(xn_dt,Dept_id,cbs_QTY)    
     select '''+CONVERT(varchar,@dMinXndt,121)+''' as xn_dt, Dept_id ,sum(isnull(cbs_QTY,0))     
     from '+@CPMTLOCSTABLENAME+' group by  Dept_id '    
     print @CCMD    
     exec sp_executesql @CCMD    
    
       
    end     
    
    
    set @dMinXndt=@dMinXndt+1    
   end    
    
    
     
    
      
    
    
END TRY         
BEGIN CATCH      
 SET @cErrormsg='Error in Procedure sp3s_createLocwisepmt at Step#'+@cStep+' '+ERROR_MESSAGE()      
 GOTO END_PROC      
END CATCH      
END_PROC:    
    
    
end