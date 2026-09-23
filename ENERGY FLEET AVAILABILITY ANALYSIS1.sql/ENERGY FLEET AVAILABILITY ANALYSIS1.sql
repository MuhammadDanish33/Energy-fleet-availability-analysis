USE NovaGroup;

-- =============================================================================
-- Query A / Objective 1: Fleet-Level Availability by Asset Type and Region
-- =============================================================================
SELECT
    a.AssetType,
    r.RegionName,
    r.Country,
    r.GridOperator,
    COUNT(DISTINCT av.AssetKey)             AS NumberOfAssets,
    COUNT(av.AvailabilityID)                AS TotalDaysSampled,
    ROUND(AVG(av.AvailabilityPct), 2)       AS AvgAvailabilityPct,
    ROUND(MIN(av.AvailabilityPct), 2)       AS MinAvailabilityPct,
    ROUND(MAX(av.AvailabilityPct), 2)       AS MaxAvailabilityPct,
    ROUND(SUM(CASE WHEN av.AvailableHours IS NOT NULL
                   THEN 24 - av.AvailableHours ELSE 0 END), 2) AS TotalLostHours,
    CASE
        WHEN AVG(av.AvailabilityPct) <  85  THEN 'Below Target  - Priority Review'
        WHEN AVG(av.AvailabilityPct) <  90  THEN 'Marginal      - Monitor Closely'
        WHEN AVG(av.AvailabilityPct) <  95  THEN 'On Track      - Within PPA Band'
        ELSE                                     'Excellent     - Above 95%'
    END                                     AS PerformanceBand
FROM Energy.FactAssetAvailability av
JOIN Energy.DimAsset   a ON av.AssetKey = a.AssetKey
JOIN Energy.DimRegion  r ON a.RegionKey = r.RegionKey
WHERE a.IsActive = 1
GROUP BY a.AssetType, r.RegionName, r.Country, r.GridOperator
ORDER BY AvgAvailabilityPct ASC;


-- =============================================================================
-- Query B / Objective 2: Weekday vs Weekend Availability Comparison
-- =============================================================================
SELECT
    a.AssetType,
    r.RegionName,
    CASE WHEN dd.IsWeekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS DayType,
    COUNT(av.AvailabilityID)                       AS DaysSampled,
    ROUND(AVG(av.AvailabilityPct), 2)              AS AvgAvailabilityPct,
    ROUND(SUM(CASE WHEN av.AvailableHours IS NOT NULL
                   THEN 24 - av.AvailableHours ELSE 0 END), 2) AS TotalLostHours,
    ROUND(AVG(av.AvailableHours), 2)               AS AvgAvailableHoursPerDay
FROM Energy.FactAssetAvailability av
JOIN Energy.DimAsset   a  ON av.AssetKey = a.AssetKey
JOIN Energy.DimRegion  r  ON a.RegionKey = r.RegionKey
JOIN Common.DateDim    dd ON av.DateKey  = dd.DateKey
WHERE a.IsActive = 1
GROUP BY a.AssetType, r.RegionName, dd.IsWeekend
ORDER BY a.AssetType, r.RegionName, DayType;


-- =============================================================================
-- Query C / Objective 3: Individual Asset Ranking with Peer Deviation
-- =============================================================================
WITH AssetQuarter AS (
    SELECT
        a.AssetKey,
        a.AssetName,
        a.AssetType,
        a.CapacityMW,
        r.RegionName,
        dd.Year,
        dd.Quarter,
        COUNT(av.AvailabilityID) AS DaysSampled,
        AVG(av.AvailabilityPct)  AS AvgAvailabilityPct,
        SUM(CASE WHEN av.AvailableHours IS NOT NULL
                 THEN 24 - av.AvailableHours ELSE 0 END) AS TotalLostHours
    FROM Energy.FactAssetAvailability av
    JOIN Energy.DimAsset   a  ON av.AssetKey = a.AssetKey
    JOIN Energy.DimRegion  r  ON a.RegionKey = r.RegionKey
    JOIN Common.DateDim    dd ON av.DateKey  = dd.DateKey
    WHERE a.IsActive = 1
    GROUP BY
        a.AssetKey, a.AssetName, a.AssetType, a.CapacityMW,
        r.RegionName, dd.Year, dd.Quarter
)
SELECT
    aq.AssetKey,
    aq.AssetName,
    aq.AssetType,
    aq.CapacityMW,
    aq.RegionName,
    aq.Year,
    aq.Quarter,
    aq.DaysSampled,
    ROUND(aq.AvgAvailabilityPct, 2) AS AvgAvailabilityPct,
    ROUND(aq.TotalLostHours, 2)     AS TotalLostHours,
    ROUND(
        aq.AvgAvailabilityPct
        - AVG(aq.AvgAvailabilityPct) OVER (PARTITION BY aq.AssetType, aq.RegionName),
    2) AS DiffFromRegionalTypeAvg,
    RANK() OVER (
        PARTITION BY aq.AssetType, aq.Year
        ORDER BY aq.AvgAvailabilityPct ASC
    ) AS RankWorstInTypeByYear,
    CASE
        WHEN aq.AvgAvailabilityPct <  85 THEN 'Investigate - Fault / Contract Risk'
        WHEN aq.AvgAvailabilityPct <  90 THEN 'Monitor     - Marginal Performance'
        WHEN aq.AvgAvailabilityPct <  95 THEN 'Acceptable  - Within PPA Threshold'
        ELSE                                  'Strong      - No Action Required'
    END AS ActionFlag
FROM AssetQuarter aq
ORDER BY aq.AssetType, aq.Year, RankWorstInTypeByYear ASC;


-- =============================================================================
-- Query D / Objective 4: Quarterly Trends by Asset Type and Year
-- =============================================================================
SELECT
    a.AssetType,
    dd.Year,
    dd.Quarter,
    COUNT(DISTINCT av.AssetKey)             AS NumberOfAssets,
    COUNT(av.AvailabilityID)                AS DaysSampled,
    ROUND(AVG(av.AvailabilityPct), 2)       AS AvgAvailabilityPct,
    ROUND(SUM(CASE WHEN av.AvailableHours IS NOT NULL
                   THEN 24 - av.AvailableHours ELSE 0 END), 2) AS TotalLostHours,
    ROUND(
        AVG(av.AvailabilityPct)
        - LAG(AVG(av.AvailabilityPct)) OVER (
              PARTITION BY a.AssetType
              ORDER BY dd.Year, dd.Quarter
          ),
    2) AS QoQ_Change_PctPoints
FROM Energy.FactAssetAvailability av
JOIN Energy.DimAsset   a  ON av.AssetKey = a.AssetKey
JOIN Common.DateDim    dd ON av.DateKey  = dd.DateKey
WHERE a.IsActive = 1
GROUP BY a.AssetType, dd.Year, dd.Quarter
ORDER BY a.AssetType, dd.Year, dd.Quarter;