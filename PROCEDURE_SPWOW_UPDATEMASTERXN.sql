CREATE PROCEDURE SPWOW_UPDATEMASTERXN
   @CSOURCETABLE VARCHAR(100),  
   @CDESTTABLE VARCHAR(100),  
   @CKEYFIELD1 VARCHAR(40)='',  
   @CKEYFIELD2 VARCHAR(40)='',  
   @CKEYFIELD3 VARCHAR(40)='',  
   @LINSERTONLY BIT = 0,  
   @CJOINSTR VARCHAR(MAX)='',  
   @CFILTERCONDITION VARCHAR(500)='',  
   @LUPDATEONLY BIT = 0,
   @cUpdateStrPara VARCHAR(MAX)=''
--WITH ENCRYPTION     
AS  
BEGIN  
 SET NOCOUNT ON  
  
 DECLARE @CWC VARCHAR(100),  
   @CINSERTSTR NVARCHAR(MAX),  
   @CINSERTSTRVALUE VARCHAR(MAX),  
   @CUPDATESTR VARCHAR(MAX),  
   @CWHERECLAUSE NVARCHAR(MAX),  
   @CCMD NVARCHAR(MAX),  
   @LDONOTREPLNULLS BIT,@CUSERIDPREFIX VARCHAR(30),  
   @CSOURCETABLEEXPR VARCHAR(1000),@CSOURCETABLESTR VARCHAR(1000),@CDESTTABLESTR VARCHAR(1000),@CDISTINCTSTR VARCHAR(200),  
   @CDESTTABLEEXPRSUFFIX VARCHAR(4000),@CSOURCETABLEEXPRSUFFIX VARCHAR(4000)  
   

       
  SELECT @CDESTTABLEEXPRSUFFIX='',@CSOURCETABLEEXPRSUFFIX=''  
    
 SET @CDESTTABLESTR=(CASE WHEN LEFT(@CDESTTABLE,1)<>'[' THEN '[' ELSE '' END)+  
  @CDESTTABLE+(CASE WHEN RIGHT(@CDESTTABLE,1)<>']' THEN ']' ELSE '' END)  
  
  
 SET @CSOURCETABLEEXPR=@CSOURCETABLE  
    
 SET @CSOURCETABLESTR=(CASE WHEN LEFT(@CSOURCETABLE,1)<>'[' THEN '[' ELSE '' END)+  
      @CSOURCETABLE+(CASE WHEN RIGHT(@CSOURCETABLE,1)<>']' THEN ']' ELSE '' END)  
   
   
    
 SET @CWC = ''  
 IF @CKEYFIELD1 <> ''  
  SET @CWC = 'A.' + @CKEYFIELD1 + ' = B.' + @CKEYFIELD1  
 IF @CKEYFIELD2 <> ''  
  SET @CWC = @CWC + ( CASE WHEN @CWC<>'' THEN ' AND ' ELSE '' END ) + 'A.' + @CKEYFIELD2 + ' = B.' + @CKEYFIELD2  
 IF @CKEYFIELD3 <> ''  
  SET @CWC = @CWC + ( CASE WHEN @CWC<>'' THEN ' AND ' ELSE '' END ) + 'A.' + @CKEYFIELD3 + ' = B.' + @CKEYFIELD3  
 IF @CWC <> ''  
  SET @CWC = ' ON ' + @CWC   
  
 IF @LINSERTONLY = 0   
 BEGIN  
      PRINT 'PREPARE UPDATE STATEMENT FOR :'+@CDESTTABLE  
	  IF @cUpdateStrPara=''
		  SELECT @CUPDATESTR=COALESCE(@CUPDATESTR+',','')+columnName+'=b.'+columnName FROM 
		  #tblEditCols  WHERE TABLENAME=@CDESTTABLE AND columnname<>'deleted'
	  ELSE
		 SET @CUPDATESTR=@cUpdateStrPara

	  SET @CWHERECLAUSE=''
  
	  SET @CCMD = N'UPDATE A SET ' + @CUPDATESTR +  
		  ' FROM ' + @CSOURCETABLESTR + ' B' +   
		  ' JOIN ' +  @CDESTTABLESTR + ' A ' +@CWC +@CJOINSTR+ @CWHERECLAUSE +   
		  (CASE WHEN @CFILTERCONDITION<>'' THEN (CASE WHEN @CWHERECLAUSE='' THEN ' WHERE ' ELSE ' AND ' END)  
		   ELSE '' END)+@CFILTERCONDITION  
	  PRINT @CCMD       
	  EXEC SP_EXECUTESQL @CCMD  
 END  
   
 IF @LUPDATEONLY = 1  
  RETURN  
   
 SELECT TOP 1 @CINSERTSTR=INSERTSTR,@CINSERTSTRVALUE=INSERTSTRVALUE  FROM WOW_XNSINFO (NOLOCK)  
 WHERE TABLENAME=@CDESTTABLE
  
  
 PRINT 'PREPARE INSERT STATEMENT FOR MIRROR TABLE :'+@CDESTTABLE  
   
     
 SET @CCMD = N' INSERT ' +  @CDESTTABLESTR+  
      ' ( ' + @CINSERTSTR +@CDESTTABLEEXPRSUFFIX+ ' ) ' +  
     ' SELECT '+@CINSERTSTRVALUE + @CSOURCETABLEEXPRSUFFIX+  
     ' FROM ' + @CSOURCETABLESTR+ ' B ' +   
     (CASE WHEN @LINSERTONLY=0 THEN    
     ' LEFT OUTER JOIN ' +  @CDESTTABLESTR + ' A ' + @CWC +@CJOINSTR+  
     ' WHERE A.' + @CKEYFIELD1 + ' IS NULL ' ELSE '' END)  
  
 IF (@CFILTERCONDITION<>'')   
 BEGIN  
  SET @CCMD = @CCMD +   
     ( CASE WHEN @CKEYFIELD1<>'' AND @LINSERTONLY=0  THEN ' AND ' ELSE ' WHERE ' END ) +   
     @CFILTERCONDITION  
 END  
 PRINT @CCMD  
 EXEC SP_EXECUTESQL @CCMD  
END  
--*************************************** END OF PROCEDURE SPWOW_UPDATEMASTERXN
