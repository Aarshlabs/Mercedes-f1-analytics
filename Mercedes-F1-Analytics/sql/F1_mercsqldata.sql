create database F1;
use f1;
-- QUERY 1: Confirm the imported table is present
-- ============================================================
SHOW TABLES;

-- ============================================================
-- QUERY 2: Preview rows
-- ============================================================
SELECT *
FROM `f1merc_data`
LIMIT 10;
-- ============================================================
-- QUERY 3: Row count and season range
-- ============================================================
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT `Season`) AS total_seasons,
    MIN(`Season`) AS first_season,
    MAX(`Season`) AS last_season
FROM `f1merc_data`;

-- ============================================================
-- QUERY 4: Check missing values in key fields
-- ============================================================
SELECT
    SUM(`Season` IS NULL) AS missing_season,
    SUM(`Driver` IS NULL OR TRIM(`Driver`) = '') AS missing_driver,
    SUM(`Finish Pos` IS NULL) AS missing_finish_position,
    SUM(`Total Weekend Points` IS NULL) AS missing_weekend_points,
    SUM(`Starting Grid` IS NULL) AS missing_starting_grid,
    SUM(`Quali Pos` IS NULL) AS missing_qualifying_position
FROM `f1merc_data`;

-- ============================================================
-- QUERY 5: Check duplicate driver-race rows
-- ============================================================
SELECT
    `Season`,
    `Race No`,
    `Driver`,
    COUNT(*) AS row_count
FROM `f1merc_data`
GROUP BY `Season`, `Race No`, `Driver`
HAVING COUNT(*) > 1
ORDER BY `Season`, `Race No`, `Driver`;

-- ============================================================
-- QUERY 6: Mercedes total weekend points by season
-- ============================================================
SELECT
    `Season`,
    ROUND(SUM(COALESCE(`Total Weekend Points`, 0)), 2) AS total_weekend_points
FROM `f1merc_data`
GROUP BY `Season`
ORDER BY `Season`;

-- ============================================================
-- QUERY 7: Wins and podiums by season
-- ============================================================
SELECT
    `Season`,
    SUM(COALESCE(`Win`, 0)) AS total_wins,
    SUM(COALESCE(`Podium`, 0)) AS total_podiums
FROM `f1merc_data`
GROUP BY `Season`
ORDER BY `Season`;

-- ============================================================
-- QUERY 8: Number of unique race rounds and points per round
-- ============================================================
SELECT
    `Season`,
    COUNT(DISTINCT `Race No`) AS unique_rounds,
    ROUND(SUM(COALESCE(`Total Weekend Points`, 0)), 2) AS total_weekend_points,
    ROUND(
        SUM(COALESCE(`Total Weekend Points`, 0)) /
        NULLIF(COUNT(DISTINCT `Race No`), 0),
        2
    ) AS points_per_round
FROM `f1merc_data`
GROUP BY `Season`
ORDER BY `Season`;

-- ============================================================
-- QUERY 9: Rank seasons by total weekend points
-- ============================================================
SELECT
    `Season`,
    ROUND(SUM(COALESCE(`Total Weekend Points`, 0)), 2) AS total_weekend_points,
    RANK() OVER (
        ORDER BY SUM(COALESCE(`Total Weekend Points`, 0)) DESC
    ) AS season_rank
FROM `f1merc_data`
GROUP BY `Season`
ORDER BY season_rank;

-- ============================================================
-- QUERY 10: Total points by driver and season
-- ============================================================
SELECT
    `Season`,
    `Driver`,
    ROUND(SUM(COALESCE(`Total Weekend Points`, 0)), 2) AS total_weekend_points
FROM `f1merc_data`
GROUP BY `Season`, `Driver`
ORDER BY `Season`, total_weekend_points DESC;

-- ============================================================
-- QUERY 11: Overall wins, podiums, and points by driver
-- ============================================================
SELECT
    `Driver`,
    SUM(COALESCE(`Win`, 0)) AS total_wins,
    SUM(COALESCE(`Podium`, 0)) AS total_podiums,
    ROUND(SUM(COALESCE(`Total Weekend Points`, 0)), 2) AS total_weekend_points
FROM `f1merc_data`
GROUP BY `Driver`
ORDER BY total_weekend_points DESC;

-- ============================================================
-- QUERY 12: Average finishing position by driver and season
-- Lower average is better. Excludes non-positive finish positions.
-- ============================================================
SELECT
    `Season`,
    `Driver`,
    COUNT(`Finish Pos`) AS classified_numeric_finishes,
    ROUND(AVG(`Finish Pos`), 2) AS average_finish_position
FROM `f1merc_data`
WHERE `Finish Pos` IS NOT NULL
  AND `Finish Pos` > 0
GROUP BY `Season`, `Driver`
ORDER BY `Season`, average_finish_position ASC;

-- ============================================================
-- QUERY 13: Rank drivers within each season by points
-- ============================================================
WITH driver_points AS (
    SELECT
        `Season`,
        `Driver`,
        SUM(COALESCE(`Total Weekend Points`, 0)) AS total_weekend_points
    FROM `f1merc_data`
    GROUP BY `Season`, `Driver`
)
SELECT
    `Season`,
    `Driver`,
    ROUND(total_weekend_points, 2) AS total_weekend_points,
    DENSE_RANK() OVER (
        PARTITION BY `Season`
        ORDER BY total_weekend_points DESC
    ) AS driver_rank
FROM driver_points
ORDER BY `Season`, driver_rank, `Driver`;

-- ============================================================
-- QUERY 14: Average qualifying position by driver and season
-- Skips missing qualifying positions.
-- ============================================================
SELECT
    `Season`,
    `Driver`,
    COUNT(`Quali Pos`) AS qualifying_records,
    ROUND(AVG(`Quali Pos`), 2) AS average_qualifying_position
FROM `f1merc_data`
WHERE `Quali Pos` IS NOT NULL
  AND `Quali Pos` > 0
GROUP BY `Season`, `Driver`
ORDER BY `Season`, average_qualifying_position ASC;

-- ============================================================
-- QUERY 15: Average positions gained from starting grid to finish
-- Positive means gained places; negative means lost places.
-- ============================================================
SELECT
    `Season`,
    `Driver`,
    COUNT(*) AS usable_finishes,
    ROUND(AVG(`Starting Grid` - `Finish Pos`), 2) AS average_positions_gained
FROM `f1merc_data`
WHERE `Starting Grid` IS NOT NULL
  AND `Starting Grid` > 0
  AND `Finish Pos` IS NOT NULL
  AND `Finish Pos` > 0
GROUP BY `Season`, `Driver`
ORDER BY `Season`, average_positions_gained DESC;

-- ============================================================
-- QUERY 16: Pole starts and win conversion by driver/season
-- ============================================================
SELECT
    `Season`,
    `Driver`,
    COUNT(*) AS pole_starts,
    SUM(COALESCE(`Win`, 0)) AS wins_recorded,
    ROUND(
        100.0 * SUM(COALESCE(`Win`, 0)) / NULLIF(COUNT(*), 0),
        2
    ) AS pole_conversion_percent
FROM `f1merc_data`
WHERE `Starting Grid` = 1
GROUP BY `Season`, `Driver`
ORDER BY `Season`, pole_conversion_percent DESC;

-- ============================================================
-- QUERY 17: Performance by starting-grid group
-- ============================================================
SELECT
    `Grid Group`,
    COUNT(*) AS starts,
    ROUND(AVG(`Finish Pos`), 2) AS average_finish_position,
    SUM(COALESCE(`Podium`, 0)) AS podiums,
    SUM(COALESCE(`Win`, 0)) AS wins,
    ROUND(SUM(COALESCE(`Total Weekend Points`, 0)), 2) AS total_weekend_points
FROM `f1merc_data`
WHERE `Grid Group` IS NOT NULL
  AND `Finish Pos` > 0
GROUP BY `Grid Group`
ORDER BY starts DESC;

-- ============================================================
-- QUERY 18: Circuit performance (minimum 2 starts)
-- ============================================================
SELECT
    `Circuit`,
    COUNT(*) AS driver_starts,
    ROUND(AVG(`Finish Pos`), 2) AS average_finish_position,
    SUM(COALESCE(`Podium`, 0)) AS podiums,
    SUM(COALESCE(`Win`, 0)) AS wins,
    ROUND(SUM(COALESCE(`Total Weekend Points`, 0)), 2) AS total_weekend_points
FROM `f1merc_data`
WHERE `Finish Pos` IS NOT NULL
  AND `Finish Pos` > 0
GROUP BY `Circuit`
HAVING COUNT(*) >= 2
ORDER BY average_finish_position ASC;

-- ============================================================
-- QUERY 19: Top 10 circuits by total weekend points
-- ============================================================
SELECT
    `Circuit`,
    ROUND(SUM(COALESCE(`Total Weekend Points`, 0)), 2) AS total_weekend_points,
    COUNT(DISTINCT `Season`) AS seasons_visited
FROM `f1merc_data`
GROUP BY `Circuit`
ORDER BY total_weekend_points DESC
LIMIT 10;

-- ============================================================
-- QUERY 20: Circuit performance by season
-- ============================================================
SELECT
    `Season`,
    `Circuit`,
    COUNT(*) AS driver_starts,
    ROUND(SUM(COALESCE(`Total Weekend Points`, 0)), 2) AS total_weekend_points,
    ROUND(AVG(`Finish Pos`), 2) AS average_finish_position
FROM `f1merc_data`
GROUP BY `Season`, `Circuit`
ORDER BY `Season`, total_weekend_points DESC;

-- ============================================================
-- QUERY 21: DNF count and rate by season
-- ============================================================
SELECT
    `Season`,
    COUNT(*) AS driver_starts,
    SUM(COALESCE(`DNF`, 0)) AS dnf_count,
    ROUND(
        100.0 * SUM(COALESCE(`DNF`, 0)) / NULLIF(COUNT(*), 0),
        2
    ) AS dnf_rate_percent
FROM `f1merc_data`
GROUP BY `Season`
ORDER BY `Season`;

-- ============================================================
-- QUERY 22: DNF count and rate by driver
-- ============================================================
SELECT
    `Driver`,
    COUNT(*) AS driver_starts,
    SUM(COALESCE(`DNF`, 0)) AS dnf_count,
    ROUND(100.0 * AVG(COALESCE(`DNF`, 0)), 2) AS dnf_rate_percent
FROM `f1merc_data`
GROUP BY `Driver`
ORDER BY dnf_rate_percent DESC;

-- ============================================================
-- QUERY 23: Non-classified / missing-status records
-- ============================================================
SELECT
    `Season`,
    `Race No`,
    `GP Name`,
    `Driver`,
    `Result Status`,
    `Laps Completed`,
    `Scheduled Laps`,
    `DNF`
FROM `f1merc_data`
WHERE `Result Status` IS NULL
   OR LOWER(TRIM(`Result Status`)) <> 'classified'
ORDER BY `Season`, `Race No`, `Driver`;

-- ============================================================
-- QUERY 24: Highest-scoring driver(s) in each season
-- ============================================================
WITH driver_points AS (
    SELECT
        `Season`,
        `Driver`,
        SUM(COALESCE(`Total Weekend Points`, 0)) AS total_weekend_points
    FROM `f1merc_data`
    GROUP BY `Season`, `Driver`
),
ranked_drivers AS (
    SELECT
        `Season`,
        `Driver`,
        total_weekend_points,
        DENSE_RANK() OVER (
            PARTITION BY `Season`
            ORDER BY total_weekend_points DESC
        ) AS driver_rank
    FROM driver_points
)
SELECT
    `Season`,
    `Driver`,
    ROUND(total_weekend_points, 2) AS total_weekend_points
FROM ranked_drivers
WHERE driver_rank = 1
ORDER BY `Season`;

-- ============================================================
-- QUERY 25: Driver contribution to Mercedes points by season
-- ============================================================
WITH driver_points AS (
    SELECT
        `Season`,
        `Driver`,
        SUM(COALESCE(`Total Weekend Points`, 0)) AS total_weekend_points
    FROM `f1merc_data`
    GROUP BY `Season`, `Driver`
)
SELECT
    `Season`,
    `Driver`,
    ROUND(total_weekend_points, 2) AS total_weekend_points,
    ROUND(
        100.0 * total_weekend_points /
        NULLIF(SUM(total_weekend_points) OVER (PARTITION BY `Season`), 0),
        2
    ) AS points_contribution_percent
FROM driver_points
ORDER BY `Season`, points_contribution_percent DESC;

-- ============================================================
-- EXTRA CHECK: Compare the two points columns in the dataset
-- ============================================================
SELECT
    ROUND(SUM(COALESCE(`Points`, 0)), 2) AS sum_points_column,
    ROUND(SUM(COALESCE(`Sprint Points`, 0)), 2) AS sum_sprint_points_column,
    ROUND(SUM(COALESCE(`Total Weekend Points`, 0)), 2) AS sum_total_weekend_points,
    ROUND(SUM(COALESCE(`Points Total`, 0)), 2) AS sum_points_total_column
FROM `f1merc_data`;

-- ============================================================
-- EXTRA CHECK: Correlation-style scatterplot export data
-- MySQL does not create a chart itself. Run this query and export
-- the result to CSV for plotting in Python/Excel.
-- ============================================================
SELECT
    `Season`,
    `Driver`,
    `GP Name`,
    `Starting Grid`,
    `Finish Pos`
FROM `f1merc_data`
WHERE `Starting Grid` IS NOT NULL
  AND `Starting Grid` > 0
  AND `Finish Pos` IS NOT NULL
  AND `Finish Pos` > 0
ORDER BY `Season`, `Race No`, `Driver`;

