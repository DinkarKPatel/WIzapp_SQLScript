create  Procedure SP3S_IMAGE_INFO_CONSTRAINT
(
 @BCALLFROMAPPLICATION BIT=0,
 @BDELETEDUPLICATEROWS bit=0
)
as
begin
    --auto Remove barcode not allow all record Remove from image info
	RETURN

	DECLARE @BSECTION BIT,@BSUB_SECTION BIT,@BARTICLE BIT,@BPARA1 BIT ,@BPARA2 BIT ,
			@BPARA3 BIT ,@BPARA4 BIT ,@BPARA5 BIT, @BPARA6 BIT ,@BPRODUCT BIT,
			@CCONSTRATNTCOLUMN VARCHAR(1000),@dtsql nvarchar(max),@DBNAME VARCHAR(100),
			@cconstraintname varchar(1000),@CERRMSG VARCHAR(1000),@CDISPLAYCOLNAME varchar(max),
			@cjoin varchar(max),@CLOCID VARCHAR(5),@CHOID VARCHAR(5)

	BEGIN TRY

			set @CCONSTRATNTCOLUMN=''
			set @CDISPLAYCOLNAME=''
			set @cjoin=''
			SET @DBNAME=DB_NAME ()+'_Image.dbo.'

			SELECT @CLOCID=value FROM CONFIG WHERE CONFIG_OPTION ='LOCATION_ID'
			SELECT @CHOID=value FROM CONFIG WHERE CONFIG_OPTION ='HO_LOCATION_ID'

    if @CLOCID=@CHOID and @BCALLFROMAPPLICATION=0
	 GOTO END_PROC

	SELECT @BSECTION =SECTION ,@BSUB_SECTION =SUB_SECTION ,@BARTICLE =ARTICLE ,@BPARA1 =PARA1 ,@BPARA2 =PARA2 ,
		   @BPARA3 =PARA3 ,@BPARA4=PARA4 ,@BPARA5 =PARA5,@BPARA6 =PARA6 ,@BPRODUCT=product
	FROM IMAGE_INFO_CONFIG


	IF @BSECTION=1
	begin
	   SET @CCONSTRATNTCOLUMN='A.SECTION_CODE,'
	   set @CDISPLAYCOLNAME='SECTION_NAME'
	   set @cjoin=' JOIN SECTIONM (NOLOCK) ON SECTIONM.SECTION_CODE=A.SECTION_CODE '
	end

	
	IF @BSUB_SECTION=1
	begin
	    SET @CCONSTRATNTCOLUMN=ISNULL(@CCONSTRATNTCOLUMN,'')+'A.SUB_SECTION_CODE,'

	  	SET @CDISPLAYCOLNAME=ISNULL(@CDISPLAYCOLNAME,'')+'SUB_SECTION_NAME,'
		 set @cjoin=isnull(@cjoin,'')+' JOIN SECTIOND (NOLOCK) ON SECTIOND.SUB_SECTION_CODE=A.SUB_SECTION_CODE '

	end

	IF @BARTICLE=1
	BEGIN
	    SET @CCONSTRATNTCOLUMN=ISNULL(@CCONSTRATNTCOLUMN,'')+'A.Article_code,'
		 SET @CDISPLAYCOLNAME=ISNULL(@CDISPLAYCOLNAME,'')+'Article_No,'
		 set @cjoin=isnull(@cjoin,'')+' JOIN Article (NOLOCK) ON Article.Article_code=A.Article_code '
	END

	IF @BPARA1=1
	begin
	    SET @CCONSTRATNTCOLUMN=ISNULL(@CCONSTRATNTCOLUMN,'')+'A.Para1_code,'

		 SET @CDISPLAYCOLNAME=ISNULL(@CDISPLAYCOLNAME,'')+'PARA1_NAME,'
		 set @cjoin=isnull(@cjoin,'')+' JOIN PARA1 (NOLOCK) ON PARA1.PARA1_CODE=A.PARA1_CODE '
	end

	IF @BPARA2=1
	BEGIN
	    SET @CCONSTRATNTCOLUMN=ISNULL(@CCONSTRATNTCOLUMN,'')+'A.Para2_code,'
		 SET @CDISPLAYCOLNAME=ISNULL(@CDISPLAYCOLNAME,'')+'PARA2_NAME,'
		 set @cjoin=isnull(@cjoin,'')+' JOIN PARA2 (NOLOCK) ON PARA2.PARA2_CODE=A.PARA1_CODE '
	END

	IF @BPARA3=1
	BEGIN
	    SET @CCONSTRATNTCOLUMN=ISNULL(@CCONSTRATNTCOLUMN,'')+'A.Para3_code,'
		 SET @CDISPLAYCOLNAME=ISNULL(@CDISPLAYCOLNAME,'')+'PARA3_NAME,'
		 set @cjoin=isnull(@cjoin,'')+' JOIN PARA3 (NOLOCK) ON PARA3.PARA3_CODE=A.PARA3_CODE '
	END

	IF @BPARA4=1
	BEGIN
	    SET @CCONSTRATNTCOLUMN=ISNULL(@CCONSTRATNTCOLUMN,'')+'A.Para4_code,'
		SET @CDISPLAYCOLNAME=ISNULL(@CDISPLAYCOLNAME,'')+'PARA4_NAME,'
		set @cjoin=isnull(@cjoin,'')+' JOIN PARA4 (NOLOCK) ON PARA4.PARA4_CODE=A.PARA4_CODE '
	END

	IF @BPARA5=1
	BEGIN
	    SET @CCONSTRATNTCOLUMN=ISNULL(@CCONSTRATNTCOLUMN,'')+'A.Para5_code,'
		 SET @CDISPLAYCOLNAME=ISNULL(@CDISPLAYCOLNAME,'')+'PARA5_NAME,'
		 set @cjoin=isnull(@cjoin,'')+' JOIN PARA5 (NOLOCK) ON PARA5.PARA2_CODE=A.PARA5_CODE '
	END

	IF @BPARA6=1
	BEGIN
	    SET @CCONSTRATNTCOLUMN=ISNULL(@CCONSTRATNTCOLUMN,'')+'A.Para6_code,'
		 SET @CDISPLAYCOLNAME=ISNULL(@CDISPLAYCOLNAME,'')+'PARA6_NAME,'
		 set @cjoin=isnull(@cjoin,'')+' JOIN PARA6 (NOLOCK) ON PARA6.PARA6_CODE=A.PARA6_CODE '
    END

	if @BPRODUCT=1
	BEGIN
	   SET @CCONSTRATNTCOLUMN=ISNULL(@CCONSTRATNTCOLUMN,'')+'A.Product_code,'
	    SET @CDISPLAYCOLNAME=ISNULL(@CDISPLAYCOLNAME,'')+'Product_code,'
	 END

	 set @CCONSTRATNTCOLUMN=SUBSTRING (@CCONSTRATNTCOLUMN,1,len(@CCONSTRATNTCOLUMN)-1)
	 set @CDISPLAYCOLNAME=SUBSTRING (@CDISPLAYCOLNAME,1,len(@CDISPLAYCOLNAME)-1)

	
	 IF ISNULL(@CCONSTRATNTCOLUMN,'')=''
	    GOTO END_PROC



	  if @BCALLFROMAPPLICATION=1 and @BDELETEDUPLICATEROWS=0
	  begin
	       
		   set @dtsql=';With DuplicateImage as
		                 (
						  
						  select '+@CDISPLAYCOLNAME+',Sr=row_number() over(Partition by '+@CCONSTRATNTCOLUMN+' order by '+@CCONSTRATNTCOLUMN+')
						  from '+@DBNAME+'Image_info A '+@cjoin+'

						 
						 )
						 select '+@CDISPLAYCOLNAME+',max(Sr)-1 as Duplicate_Rows,''Duplicate Image Found''  As ERRMSG from  DuplicateImage 
						 where sr>1 
						 group by '+@CDISPLAYCOLNAME+'
						 Order by  '+@CDISPLAYCOLNAME+''
			print @dtsql 
			exec sp_executesql @dtsql

			GOTO end_PROC

	  end

	   set @cconstraintname='UNQ_IMAGE_INFO'

	  if @BDELETEDUPLICATEROWS=1
	  begin

			if @CLOCID =@CHOID
			begin

				set @dtsql='  IF OBJECT_ID ('''+@DBNAME+@cconstraintname+''',''UQ'') IS NOT NULL
				alter table '+@DBNAME+'Image_info drop constraint '+@cconstraintname+''
				print @dtsql 
				exec sp_executesql @dtsql
			end

		   set @dtsql=';With DuplicateImage as
		                 (
						  
						  select '+@CCONSTRATNTCOLUMN+',Sr=row_number() over(Partition by '+@CCONSTRATNTCOLUMN+' order by '+@CCONSTRATNTCOLUMN+')
						  from '+@DBNAME+'Image_info A

						 
						 )
						 Delete  from  DuplicateImage where sr>1 
						 '
			print @dtsql 
			exec sp_executesql @dtsql


	  end

 if @CLOCID =@CHOID
  begin

	set @CCONSTRATNTCOLUMN=Replace(@CCONSTRATNTCOLUMN,'a.','')
	set @dtsql='  IF OBJECT_ID ('''+@DBNAME+@cconstraintname+''',''UQ'') IS  NULL
	alter table '+@DBNAME+'Image_info add constraint '+@cconstraintname+' unique('+@CCONSTRATNTCOLUMN+')'

	print @dtsql 
	exec sp_executesql @dtsql

 end

	END TRY
	BEGIN CATCH
	   SET @CERRMSG=' #SQL Error '+ LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
	END CATCH

END_PROC:

if @BCALLFROMAPPLICATION=1 and   @BDELETEDUPLICATEROWS<>0
select @CERRMSG as ERRMSG

end