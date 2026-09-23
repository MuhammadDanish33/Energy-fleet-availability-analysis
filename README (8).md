# Energy Fleet Availability Analysis
### SQL Portfolio Project | Energy Data Analysis | UK & Ireland Renewable Fleet

---

## Project Overview

This project analyses the operational availability of a 120-asset UK and Ireland renewable energy fleet — spanning Wind, Solar, and Battery assets across 18 regions — using structured SQL queries executed against a verified relational dataset.

The analysis answers four operational business questions through a progressive, data-driven framework: from fleet-level benchmarking down to individual asset prioritisation and multi-year trend tracking. Results were validated against 5,000 daily availability records covering January 2022 to December 2025.

> **Audience:** This project is designed to demonstrate practical SQL and energy domain skills relevant to Energy Data Analyst, Asset Performance Analyst, and O&M Data roles.

---

## Business Problem & Objectives

A **90% availability threshold** is the standard benchmark in UK renewable energy Power Purchase Agreements (PPAs) and project finance covenants. Sustained performance below this level exposes asset owners to penalty clauses, reduced revenue, and investor scrutiny.

Despite this, many O&M teams still rely on manual reporting that cannot answer a simple question: **which assets are structurally underperforming, and why?**

This analysis builds a systematic fleet performance classification system to answer four connected business questions:

| # | Business Question | Purpose |
|---|---|---|
| 1 | Which asset types and regions have the lowest average availability? | Establish the fleet-wide baseline and surface priority areas |
| 2 | Is availability lower on weekends than weekdays, by asset type and region? | Determine whether poor performance is technical or operational |
| 3 | Which individual assets are chronically below their regional peers? | Produce a named, ranked O&M priority list |
| 4 | Is fleet availability improving or deteriorating over time? | Track whether maintenance programmes are working |

---

## Data & Approach

### Dataset
- **Source:** Structured relational energy dataset — verified through full dataset audit before analysis
- **Primary table:** `Energy.FactAssetAvailability` — 5,000 daily availability records (cleanest and most complete table in the dataset)
- **Supporting tables:** `Energy.DimAsset`, `Energy.DimRegion`, `Common.DateDim`
- **Coverage:** 120 assets · 18 UK & Ireland regions · 4 full years (2022–2025)
- **Asset types:** Wind, Solar, Battery

### Data Governance Applied
Before writing a single query, a full dataset audit was completed. The following decisions were applied:
- `IsActive = 1` filter applied in all queries — excludes 11 decommissioned or inactive assets
- `Technology` column excluded — confirmed unreliable due to systematic AssetType/Technology mismatch
- `DateKey` (INTEGER YYYYMMDD) joins directly to `Common_DateDim` — no conversion required
- All queries are NULL-safe: `TotalLostHours` uses `CASE WHEN AvailableHours IS NOT NULL THEN 24 - AvailableHours ELSE 0 END`

### Performance Thresholds

| Availability % | Band | Action |
|---|---|---|
| `< 85%` | Below Target | Immediate investigation — fault or contract risk |
| `85% – < 90%` | Marginal | Monitor closely — schedule diagnostics |
| `90% – < 95%` | On Track | Acceptable — routine monitoring |
| `≥ 95%` | Excellent | No action required |

---

## Analysis Performed

The project comprises four SQL queries, each directly answering one business question:

| Query | Question Answered | Key SQL Techniques |
|---|---|---|
| **Query A** — Fleet Baseline | Which regions/types underperform? | `GROUP BY`, `AVG`, `MIN`, `MAX`, `SUM`, `CASE` |
| **Query B** — Weekday vs. Weekend | Is the gap operational or technical? | `JOIN` to DateDim, `CASE` on `IsWeekend`, grouped aggregates |
| **Query C** — Individual Asset Ranking | Which assets need urgent attention? | CTE, `RANK() OVER (PARTITION BY...)`, nested `AVG() OVER (PARTITION BY...)`, `CASE` ActionFlag |
| **Query D** — Quarterly Trends | Is performance improving over time? | `LAG()` window function, `GROUP BY` Year + Quarter |

> Full SQL is available in [`ENERGY FLEET AVAILABILITY ANALYSIS1.sql`](./ENERGY%20FLEET%20AVAILABILITY%20ANALYSIS1.sql)

---

## Key Results & Insights

### Finding 1 — The Entire Fleet Is Stuck in the Marginal Band

> **All 46 asset-type × region combinations returned an average availability of 86.29% to 89.71% — every single one classified as "Marginal — Monitor Closely."**

Not one region or asset type reached the 90% PPA benchmark at the fleet aggregate level. The fleet has operated below the contractual threshold across the entire 4-year period.

| Worst Performing Group | AvgAvailability | Lost Hours | Band |
|---|---|---|---|
| Wind · South East (National Grid ESO) | 86.29% | 171.06 hrs | Marginal |
| Battery · Midlands (National Grid ESO) | 86.35% | 258.88 hrs | Marginal |
| Wind · Scotland South (National Grid ESO) | 86.49% | 246.38 hrs | Marginal |

Highest lost-hour groups:
- **Solar · Yorkshire** — 659.39 total lost hours (5 assets, 212 days sampled)
- **Wind · Wales** — 603.07 total lost hours (4 assets, 192 days sampled)
- **Solar · North West** — 632.64 total lost hours (5 assets, 206 days sampled)

---

### Finding 2 — Weekend Availability Gaps Signal Operational Coverage Issues

Query B revealed that the weekday vs. weekend availability gap is not uniform — it is concentrated in specific asset type and region combinations, pointing to operational rather than purely technical causes.

| Asset Type | Region | Weekday Avg | Weekend Avg | Gap |
|---|---|---|---|---|
| Battery | Ireland | 88.24% | 83.23% | **−5.01%** |
| Battery | North England | 88.27% | 83.71% | **−4.56%** |
| Wind | Scotland South | 87.48% | 83.92% | **−3.56%** |
| Wind | North Sea | 87.69% | 84.92% | **−2.77%** |
| Battery | Scotland South | 88.68% | 86.97% | **−1.71%** |

> A 5% weekend availability drop in Battery (Ireland) and 4.56% in Battery (North England) is not consistent with equipment failure patterns — it points to reduced monitoring coverage or delayed incident response at weekends.

Some combinations show the reverse — Solar Channel Islands (weekday 87.47% vs. weekend 90.00%) and Wind South East (weekday 85.12% vs. weekend 88.51%) — confirming that this is not a fleet-wide pattern but a location-specific operational issue.

---

### Finding 3 — Repeat Offender Assets Identified Across Multiple Years

Query C ranked every asset by availability within its type and year. Several assets appeared in the bottom rankings repeatedly:

| Asset | Type | Region | Worst Single Quarter | Years in "Investigate" |
|---|---|---|---|---|
| Battery Farm East Kylehaven 94 | Battery | Midlands | **75.00%** (2023 Q2) | 2022, 2023, 2024, 2025 |
| Battery Farm Lynnton 89 | Battery | Midlands | 75.42% (2024 Q1) | 2022, 2023, 2024, 2025 |
| Battery Farm Raymondchester 58 | Battery | Scotland North | 75.96% (2022 Q1) | 2022, 2023, 2024, 2025 |
| Wind Farm Deanborough 55 | Wind | Yorkshire | 75.79% (2023 Q3) | 2023, 2024, 2025 |
| Solar Farm Turnertown 109 | Solar | Ireland | 76.46% (2023 Q1) | 2022, 2023, 2024 |

The `DiffFromRegionalTypeAvg` column confirms these assets are structurally underperforming — not experiencing isolated incidents. Battery Farm Raymondchester 58 recorded `DiffFromRegionalTypeAvg = −12.1` in 2022 Q1, meaning its availability was **12.1 percentage points below Scotland North Battery peers** in that period.

---

### Finding 4 — No Sustained Improvement Across Four Years

Query D computed quarter-over-quarter availability change for each asset type across all 16 quarters (2022 Q1 – 2025 Q4).

**Battery — Selected QoQ Results:**

| Period | AvgAvailabilityPct | QoQ Change |
|---|---|---|
| 2022 Q1 | 87.89% | — (baseline) |
| 2022 Q4 | 86.24% | −1.05% |
| 2023 Q1 | 88.09% | +1.85% |
| 2024 Q4 | 88.72% | +2.51% |
| 2025 Q3 | 86.38% | **−2.60%** (largest single-quarter drop) |
| 2025 Q4 | 87.10% | +0.71% |

**Wind — Selected QoQ Results:**

| Period | AvgAvailabilityPct | QoQ Change |
|---|---|---|
| 2022 Q1 | 88.25% | — (baseline) |
| 2023 Q2 | 86.80% | **−1.83%** (steepest drop) |
| 2024 Q2 | 88.12% | +0.54% |
| 2025 Q4 | 86.35% | −0.70% |

**Conclusion:** Fleet availability oscillates within the 86–89% "Marginal" band for all three asset types across the entire 4-year period. There is no sustained upward trend. Wind shows a slight deterioration from 88.25% (2022 Q1) to 86.35% (2025 Q4).

---

## Business & Stakeholder Impact

| Stakeholder | What This Analysis Provides |
|---|---|
| **O&M Director** | A named, ranked list of assets requiring immediate investigation — replacing ad-hoc reporting with a data-driven maintenance priority queue |
| **Asset Manager** | Portfolio-wide benchmarking of 120 assets across 18 regions; identification of repeat underperformers before contract renewal or refinancing events |
| **Finance / CFO** | Quantified lost hours by region and asset type — provides the input needed to calculate PPA penalty exposure when contract thresholds are applied |
| **Grid Operators** | Fleet uptime data by GridOperator (National Grid ESO, EirGrid, SONI, Manx Utilities, Jersey Electricity) supports grid balancing and regulatory reporting |
| **Lenders / Investors** | Demonstrates systematic, documented performance monitoring — satisfies project finance covenant and ESG disclosure requirements |

> **Important boundary:** This analysis quantifies availability loss and identifies underperforming assets. Specific PPA penalty amounts require contract-level threshold data not present in this dataset. The weekend gap flags a potential staffing issue — HR and scheduling data would be required to confirm root cause.

---

## Recommendations

The following recommendations are derived directly from the numerical results — no assumptions are made beyond what the data supports.

**1. Immediate O&M Investigation — Battery Assets in Midlands and Scotland North**
Battery Farm East Kylehaven 94 (Midlands) recorded a single-quarter low of **75.00%** and consistently ranks at or near the bottom of Battery assets across all four years. Given a reported capacity of 437.4 MW, each 1% availability improvement represents meaningful generation recovery. These assets should be the first target of a diagnostic review.

**2. Weekend Monitoring Coverage Review — Battery (Ireland) and Battery (North England)**
The 5.01% and 4.56% weekend availability gaps in these two region–type combinations are the largest in the dataset. O&M management should review weekend staffing, remote monitoring alert thresholds, and incident response times for these locations. The pattern is unlikely to be equipment-driven given its consistency on weekend days specifically.

**3. Wind Fleet Performance Review — Downward Trend Confirmed**
Wind availability declined from 88.25% (2022 Q1) to 86.35% (2025 Q4). While the change appears small, this represents a sustained multi-year directional decline. A structured inspection programme focused on the highest lost-hour regions (Wales: 603.07 hours; Yorkshire: 273.97 hours) is warranted.

**4. Fleet-Wide: Set Asset-Level PPA Reporting Targets Below 90% Threshold**
Since no region or asset type has reached the 90% threshold at the fleet aggregate level in four years, internal targets and reporting dashboards should reflect this reality. Availability targets set without reference to actual historical data create misleading performance assessments for investors and lenders.

---

## Skills Demonstrated

```
SQL                          Data Analysis               Energy Domain
─────────────────────────    ────────────────────────    ─────────────────────────────
Window functions             Dataset auditing            PPA threshold interpretation
  RANK() OVER PARTITION BY   KPI design                  Fleet availability analysis
  AVG() OVER PARTITION BY    Performance banding         O&M prioritisation logic
  LAG() for trend analysis   Root cause framing          Weekday vs. weekend ops insight
CTE design & usage           Cross-table validation      UK grid operator awareness
Multi-table JOINs            Stakeholder mapping         Renewable asset types (Wind/Solar/BESS)
NULL-safe aggregation        Result interpretation        4-year trend analysis
CASE WHEN classification     Analytical storytelling     Energy sector KPI fluency
```

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| **SQL Server** | Query development and execution (schema: `Energy.*`, `Common.*`) |
| **Microsoft Excel** | Result storage, validation, and structured output across 4 sheets |
| **Relational Dataset** | 17-table star schema — 5 Fact tables, 12 Dimension tables |

---

## Project Outcome

This project demonstrates the complete analytical workflow of an Energy Data Analyst: from raw dataset audit, through structured SQL development, to result validation and business interpretation.

**What was delivered:**
- A fleet-level performance baseline for 120 renewable energy assets across 18 UK and Ireland regions
- Identification of the weekend availability gap as an operational — not technical — issue in specific regions
- A named, ranked O&M priority list of chronically underperforming assets with quantified peer deviation
- A 4-year quarterly trend analysis confirming the fleet has not sustainably improved beyond the Marginal band

**The core finding:** The entire UK and Ireland renewable energy fleet analysed has operated below the standard 90% PPA availability benchmark for four consecutive years, with no asset type or region achieving sustained improvement — making this analysis directly actionable for O&M, Finance, and Asset Management teams.

---

*Prepared by Muhammad Danish · Research and Innovation Manager · September 2026*
