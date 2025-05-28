CREATE PROCEDURE DBSALE_KPI_SALE_DETAIL(@USER_CODE VARCHAR(7)='',@LOC VARCHAR(MAX)='',@DT VARCHAR(10))
AS    
BEGIN    
   SET NOCOUNT ON
   
   SELECT 
   SUM(CASE WHEN kpi_name='total discount' then  CY_ftd else 0 end) cy_ftd_disc,SUM(CY_ftd) CY_FTD_Sale,
   SUM(CASE WHEN kpi_name='total discount' then  lY_ftd else 0 end) ly_ftd_disc,SUM(lY_ftd) LY_FTD_Sale,
   SUM(CASE WHEN kpi_name='total discount' then  CY_wtd else 0 end) cy_wtd_disc,SUM(CY_wtd) CY_WTD_Sale,
   SUM(CASE WHEN kpi_name='total discount' then  lY_wtd else 0 end) ly_wtd_disc,SUM(lY_wtd) LY_WTD_Sale,
   SUM(CASE WHEN kpi_name='total discount' then  CY_qtd else 0 end) cy_qtd_disc,SUM(CY_qtd) CY_QTD_Sale,
   SUM(CASE WHEN kpi_name='total discount' then  lY_qtd else 0 end) ly_qtd_disc,SUM(lY_qtd) LY_QTD_Sale,
   SUM(CASE WHEN kpi_name='total discount' then  CY_mtd else 0 end) cy_mtd_disc,SUM(CY_mtd) CY_MTD_Sale,
   SUM(CASE WHEN kpi_name='total discount' then  lY_mtd else 0 end) ly_mtd_disc,SUM(lY_mtd) LY_MTD_Sale,
   SUM(CASE WHEN kpi_name='total discount' then  CY_ytd else 0 end) cy_ytd_disc,SUM(CY_ytd) CY_YTD_Sale,
   SUM(CASE WHEN kpi_name='total discount' then  lY_ytd else 0 end) ly_ytd_disc,SUM(lY_ytd) LY_YTD_Sale
   INTO #tmpDiscRatio FROM dbsale_1 (NOLOCK) 
   WHERE db_DT=@DT AND kpi_name in ('Total Discount','SALE')
   AND (@LOC='' OR DEPT_ID IN (SELECT CODE FROM DBO.FN_SPLIT_VALUE(@LOC)))

   SELECT kpi_name AS SALES_DETAILS,
   SUM(CY_ftd)FTD_CY,SUM(LY_ftd)FTD_LY,(case when sum(ly_ftd)=0 then 0 else CONVERT(NUMERIC(10,2),((SUM(cy_ftd)-SUM(ly_ftd))/SUM(ly_ftd))*100) end) FTD_INC_P,
   SUM(CY_wtd)WK_CY,SUM(LY_wtd)WK_LY,(case when sum(ly_ftd)=0 then 0 else CONVERT(NUMERIC(10,2),((SUM(cy_wtd)-sum(ly_wtd))/SUM(ly_wtd))*100) end) WK_INC_P,
   SUM(CY_mtd)MTD_CY,SUM(LY_mtd)MTD_LY,(case when sum(ly_ftd)=0 then 0 else CONVERT(NUMERIC(10,2),((SUM(cy_mtd)-sum(ly_mtd))/SUM(ly_mtd))*100) end) MTD_INC_P,
   SUM(CY_qtd)QTD_CY,SUM(LY_qtd)QTD_LY,(case when sum(ly_ftd)=0 then 0 else CONVERT(NUMERIC(10,2),((SUM(cy_qtd)-sum(ly_qtd))/SUM(ly_qtd))*100) end) QTD_INC_P,
   SUM(CY_YTD)YTD_CY,SUM(ly_ytd)YTD_LY,(case when sum(ly_ftd)=0 then 0 else CONVERT(NUMERIC(10,2),((SUM(cy_ytd)-sum(ly_ytd))/SUM(ly_ytd))*100) end) YTD_INC_P
   FROM dbsale_1 (NOLOCK) 
   WHERE db_DT=@DT AND kpi_name<>'Total Discount'
   AND (@LOC='' OR DEPT_ID IN (SELECT CODE FROM DBO.FN_SPLIT_VALUE(@LOC)))
   GROUP BY kpi_name
   UNION ALL
   SELECT 'Disc/Sale Ratio' AS SALES_DETAILS,
   (CASE WHEN CY_FTD_Sale<>0 THEN (CY_ftd_disc/CY_FTD_Sale)*100 else 0 end) as FTD_CY,(CASE WHEN LY_FTD_Sale<>0 THEN (lY_ftd_disc/LY_FTD_Sale)*100 else 0 end) as FTD_LY,
   CONVERT(NUMERIC(10,2),((CASE WHEN CY_FTD_Sale<>0 THEN (CY_ftd_disc/CY_FTD_Sale)*100 else 0 end) -(CASE WHEN LY_FTD_Sale<>0 THEN (lY_ftd_disc/LY_FTD_Sale)*100 else 0 end)))  FTD_INC_P,
   (CASE WHEN CY_WTD_Sale<>0 THEN (CY_WTD_disc/CY_WTD_Sale)*100 else 0 end) as WTD_CY,(CASE WHEN LY_WTD_Sale<>0 THEN (lY_WTD_disc/LY_WTD_Sale)*100 else 0 end) as WTD_LY,
   CONVERT(NUMERIC(10,2),((CASE WHEN CY_WTD_Sale<>0 THEN (CY_WTD_disc/CY_WTD_Sale)*100 else 0 end) -(CASE WHEN LY_WTD_Sale<>0 THEN (lY_WTD_disc/LY_WTD_Sale)*100 else 0 end)))  WTD_INC_P,
   (CASE WHEN CY_mTD_Sale<>0 THEN (CY_mTD_disc/CY_mTD_Sale)*100 else 0 end) as mTD_CY,(CASE WHEN LY_mTD_Sale<>0 THEN (lY_mTD_disc/LY_mTD_Sale)*100 else 0 end) as mTD_LY,
   CONVERT(NUMERIC(10,2),((CASE WHEN CY_mTD_Sale<>0 THEN (CY_mTD_disc/CY_mTD_Sale)*100 else 0 end) -(CASE WHEN LY_mTD_Sale<>0 THEN (lY_mTD_disc/LY_mTD_Sale)*100 else 0 end)))  mTD_INC_P,
   (CASE WHEN CY_qTD_Sale<>0 THEN (CY_qTD_disc/CY_qTD_Sale)*100 else 0 end) as qTD_CY,(CASE WHEN LY_qTD_Sale<>0 THEN (lY_qTD_disc/LY_qTD_Sale)*100 else 0 end) as qTD_LY,
   CONVERT(NUMERIC(10,2),((CASE WHEN CY_qTD_Sale<>0 THEN (CY_qTD_disc/CY_qTD_Sale)*100 else 0 end) -(CASE WHEN LY_qTD_Sale<>0 THEN (lY_qTD_disc/LY_qTD_Sale)*100 else 0 end)))  qTD_INC_P,
   (CASE WHEN CY_yTD_Sale<>0 THEN (CY_yTD_disc/CY_yTD_Sale)*100 else 0 end) as yTD_CY,(CASE WHEN LY_yTD_Sale<>0 THEN (lY_yTD_disc/LY_yTD_Sale)*100 else 0 end) as yTD_LY,
   CONVERT(NUMERIC(10,2),((CASE WHEN CY_yTD_Sale<>0 THEN (CY_yTD_disc/CY_yTD_Sale)*100 else 0 end) -(CASE WHEN LY_yTD_Sale<>0 THEN (lY_yTD_disc/LY_yTD_Sale)*100 else 0 end)))  YTD_INC_P
   FROM #tmpDiscRatio
   ORDER BY SALEs_DETAILS
   
   --ORDER NEED TO BE SET
   SET NOCOUNT OFF
END--DBSALE_KPI_SALE_DETAIL