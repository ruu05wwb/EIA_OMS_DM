  CREATE OR REPLACE VIEW "DWSEAI01"."OMS_T" AS 
  WITH OMS_MV_PART_TEMP           AS
  (SELECT T1.*,
    CASE
      WHEN MOD(MAX(T1.YEARMONTH) OVER(), 100)>=9
      THEN 1
      ELSE 0
    END AS NEW_PF_FLAG_GL,
    CASE
      WHEN MOD(T1.YEARMONTH, 100)>=9
      THEN 1
      ELSE 0
    END                      AS NEW_PF_FLAG_ROW,
    MAX(T1.YEARMONTH) OVER() AS MAX_YM
  FROM DWSEAI01.OMS_MV T1
  )
SELECT T0.IMC_KEY_NO_CNT,
  T0.YEARMONTH,
  T0.NEW_APP_FLAG,
  T0.TENURE,
  DECODE(T0.U35_FLAG, 1, 'U35', 'Over 35') AS U35_FLAG,
  T0.COUNTRY,
  T2.SUBREGION,
  T2.CLUSTER_NAME,
  T0.GL_SEGMENT,
  T0.SALES_REGION,
  T0.STATE,
  NVL(T1.STATE_LAT, T0.STATE) AS STATE_LAT,
  CASE WHEN T0.IMC_TYPE='FOA' THEN 'Guest Customer' ELSE T0.IMC_TYPE END AS IMC_TYPE,
  CASE WHEN T0.DIST_TYPE='FOA' THEN 'Guest Customer' ELSE T0.DIST_TYPE END AS DIST_TYPE,
  T0.BV_USD,
  T0.BV_USD_EOM,
  T0.PV,
  T0.PV_EOM,
  T0.OMS_UNIT_CNT,
  T0.BUYERS_CNT,
  T0.RCNCY_CNT,
  T0.FRQNCY_CNT,
  T0.SPONSORED_ABOS_CNT,
  T0.SPONSORED_RCS_CNT,
  T0.ABOS_SPONSORING_ABOS_FLAG,
  T0.ABOS_SPONSORING_RCS_FLAG,
  T0.ABOS_SPONSORING_IMCS_FLAG,
  T0.HIGH_IMC,
  T0.HIGH_VOLUME,
  T0.HIGH_BV,
  T0.R_IMC,
  T0.MAX_YM                                       AS LAST_CLOSED_YM,
  T0.MAX_YM          +DECODE(T0.NEW_PF_FLAG_GL, 1, 100, 0) AS PERF_YR_MNTH_MAX,
  MOD(T0.MAX_YM, 100)+DECODE(T0.NEW_PF_FLAG_GL, 1, -8, 4)  AS PERF_MONTH_NO_MAX,
  CASE
    WHEN MOD(T0.YEARMONTH, 100)>MOD(T0.MAX_YM, 100)
    THEN 'NA'
    ELSE DECODE(CAST(T0.MAX_YM/100 AS INTEGER)-CAST(T0.YEARMONTH/100 AS INTEGER), 0, 'Current Yr', 1, 'Previous Yr', 2, '2 Years Ago', 'NA')
  END AS CALEND_YTD,
  CASE
    WHEN (MOD(T0.YEARMONTH, 100)+DECODE(T0.NEW_PF_FLAG_ROW, 1, -8, 4))>(MOD(T0.MAX_YM, 100)+DECODE(T0.NEW_PF_FLAG_GL, 1, -8, 4))
    THEN 'NA'
    ELSE DECODE((CAST(T0.MAX_YM/100 AS INTEGER)+DECODE(T0.NEW_PF_FLAG_GL, 1, 1, 0))-CAST((T0.YEARMONTH+DECODE(T0.NEW_PF_FLAG_ROW, 1, 100, 0))/100 AS INTEGER), 0, 'Current Yr', 1, 'Previous Yr', 2, '2 Years Ago', 'NA')
  END AS PERFORMANCE_YTD,
  CASE
    WHEN CAST(T0.MAX_YM/100 AS INTEGER)*12+MOD(T0.MAX_YM,100)-(CAST(T0.YEARMONTH/100 AS INTEGER)*12+MOD(T0.YEARMONTH,100))+1 IN (1, 2, 3, 13, 14, 15, 25 ,26, 27)
    THEN 1
    ELSE 0
  END AS LAST_3MONTH_FLAG,
  CASE
    WHEN MOD(T0.YEARMONTH, 100)>=9
    THEN T0.YEARMONTH+100
    ELSE T0.YEARMONTH
  END AS PERF_YEARMONTH,
  CAST(T0.YEARMONTH/100 AS INTEGER)+
  CASE
    WHEN MOD(T0.YEARMONTH, 100)>=9
    THEN 1
    ELSE 0
  END AS PERF_YR,
  CASE
    WHEN MOD(T0.YEARMONTH, 100)>=9
    THEN MOD(T0.YEARMONTH, 100)-8
    ELSE MOD(T0.YEARMONTH, 100)+4
  END                                             AS PERF_MONTH_NO,
  CAST(T0.YEARMONTH/100 AS INTEGER)               AS CALEND_YR,
  MOD(T0.YEARMONTH, 100)                          AS CALEND_MONTH_NO,
  TO_DATE(CONCAT(T0.YEARMONTH, '01'), 'yyyymmdd') AS "DATE",
  TO_DATE(CONCAT(T0.MAX_YM, '01'), 'yyyymmdd')    AS "LAST_YM_DATE",
  (SELECT LAST_ANALYZED
  FROM ALL_TABLES
  WHERE OWNER   ='DWSEAI01'
  AND TABLE_NAME='OMS_TEMP_RMS_PART'
  ) AS LAST_UPDATED
FROM OMS_MV_PART_TEMP T0
LEFT JOIN DWSEAI01.STATES_DICT T1
ON T0.STATE    =T1.STATE
LEFT JOIN DWSEAI01.COUNTRIES T2
ON T0.COUNTRY=T2.CNTRY_SHORT_NM
WHERE IMC_TYPE<>'Inactive'  AND NVL(SUBREGION, 'RUS_KAZ_UKR') IN ('RUS_KAZ_UKR', 'EUR_SA_ANZ');