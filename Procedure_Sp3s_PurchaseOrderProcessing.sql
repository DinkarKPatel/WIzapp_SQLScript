create Procedure Sp3s_PurchaseOrderProcessing  
(  
  @nUpdateMode numeric(1,0),  
  @cmemoid varchar(30)='',  
  @PurchasrOrderXnType varchar(20)='',  
  @CERRORMSG varchar(1000) output  
)  
as  
begin  
  
 Declare @CSTEP varchar(10)  
  
BEGIN TRY   
  
    set @CSTEP=10  
  
     if @nUpdateMode=3  
     goto LblUpdate  
  
   
   ;with cte_PurchaseOrder as  
  (  
      select A.XNTYPE ,A.ROWID,A.REFROWID  
   from PurchaseOrderProcessingnew a (nolock)  
   join pod01106 b (nolock) on a.RowId =b.row_id   
   where b. po_id =@cmemoid and a.xntype=@PurchasrOrderXnType  
   group by A.XNTYPE ,A.ROWID,A.REFROWID  
  )  
  
   INSERT INTO PurchaseOrderProcessingnew(XnType,RowId,RefRowId ,Qty)  
   SELECT a.XnType ,A.RowId,A.RefRowId ,0 as Qty  
   FROM #tmpPurchaseOrderProcessingnew A  
   LEFT OUTER JOIN cte_PurchaseOrder B (nolock) ON  a.XnType=b.XnType and A.RowId=b.RowId and A.RefRowId=b.RefRowId  
   WHERE B.RowId is null  
   group by a.XnType ,A.RowId,A.RefRowId  
   
  
  set @CSTEP=20  
  
  LblUpdate:  
  
  if @nUpdateMode=3  
  begin  
            
      
   DELETE A 
   FROM PURCHASEORDERPROCESSINGNEW A  (NOLOCK)  
   JOIN POD01106 POD (NOLOCK) ON A.ROWID =POD.ROW_ID   
   WHERE POD.PO_ID =@CMEMOID   
   AND A.XNTYPE=@PURCHASRORDERXNTYPE   
  
  
  end  
  else   
  begin  
  
   Update a set QTY=isnull(b.QTY,0)  
   FROM PurchaseOrderProcessingnew A  (nolock)  
   join pod01106 pod (nolock) on a.RowId =pod.row_id   
   left join #tmpPurchaseOrderProcessingnew b on   A.XNTYPE=B.XNTYPE AND A.RowId=B.RowId AND A.RefRowId=B.RefRowId   
   WHERE pod.po_id =@CMEMOID   
   and a.XnType=@PurchasrOrderXnType and a.Qty <>isnull(b.QTY,0)  
  
  
  end  
  
  
  
  
END TRY    
    
BEGIN CATCH    
  SET @CERRORMSG ='ERROR IN PROCEDURE Sp3s_PurchaseOrderProcessing STEP#'+@CSTEP+' '+ ERROR_MESSAGE()    
  PRINT 'ENTER CATCH BLOCK OF Sp3s_PurchaseOrderProcessing'    
      
  GOTO PROC_END     
END CATCH    
      
PROC_END:      
end