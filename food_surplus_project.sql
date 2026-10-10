SELECT * FROM foodsurplus.eurostat
LIMIT 10;
-- INSPECTING THE DATA
-- Checking the table structure
DESCRIBE foodsurplus.eurostat;

-- Rename columns for better readibility
ALTER TABLE eurostat 
RENAME COLUMN `LAST UPDATE` TO last_update,
RENAME COLUMN DATAFLOW TO data_flow,
RENAME COLUMN geo TO countries,
RENAME COLUMN TIME_PERIOD TO time_period,
RENAME COLUMN OBS_FLAG TO observation_flag,
RENAME COLUMN nace_r2 TO sectors,
RENAME COLUMN OBS_VALUE TO food_waste;

SELECT 
	COUNT(*) as row_count, 
    COUNT(DISTINCT geo) as countries,
    COUNT(DISTINCT TIME_PERIOD) as years,
    COUNT(DISTINCT nace_r2) as sectors, 
    COUNT(DISTINCT unit) as units
FROM foodsurplus.eurostat; 

-- Several columns contain the exact same value for every single row. They offer no analytical value and can be safely dropped to clean up the data structure. 
-- Checking constant columns; as a result, we'll see each has only one value:
SELECT DISTINCT data_flow, last_update, freq, wst_oper, waste FROM foodsurplus.eurostat;

-- INSPECTING IMPORTANT COLUMNS FOR MY PROJECT:
-- Sectors
SELECT sectors, 
	COUNT(*) as row_count
FROM foodsurplus.eurostat
GROUP by sectors
ORDER by row_count DESC; 
-- Countries: "European Union-27 countries (from 2020)" is not a country.
SELECT countries, 
	COUNT(*) as row_count
FROM foodsurplus.eurostat
GROUP by countries
ORDER by row_count DESC;
-- Years: should show 2020-2023
SELECT DISTINCT time_period FROM foodsurplus.eurostat
ORDER by time_period ASC;

-- Creating a cleaned table with only 6 columns that I need for the project:
CREATE TABLE eurostat_clean as
SELECT countries, time_period, sectors, food_waste, unit, observation_flag
FROM eurostat;
-- check the clean table structure:
SELECT * FROM foodsurplus.eurostat_clean;

-- Some sector names are unnecessarily long, for further improvement they can be shorten:
SET SQL_SAFE_UPDATES = 0; -- Temporarily disable safe UPDATE mode

UPDATE foodsurplus.eurostat_clean
SET sectors = CASE 
	WHEN sectors = 'Primary production of food - agriculture, fishing and aquaculture' then 'Primary production'
	WHEN sectors = 'Manufacture of food products and beverages' then 'Food manufacturing'
	WHEN sectors = 'Retail and other distribution of food' then 'Retail & distribution'
	WHEN sectors = 'Total activities by households' then 'Households'
	WHEN sectors = 'Restaurants and food services' then  'Restaurants & food services'
	WHEN sectors = 'Total (aggregate changing according to the context)' then 'Total'
    ELSE sectors 
END
WHERE sectors IN ('Primary production of food - agriculture, fishing and aquaculture', 'Manufacture of food products and beverages',
'Retail and other distribution of food', 'Total activities by households', 'Restaurants and food services', 'Total (aggregate changing according to the context)');

SET SQL_SAFE_UPDATES = 1; -- Re-enable safe update mode
-- check the clean table structure:
SELECT * FROM foodsurplus.eurostat_clean
ORDER by food_waste DESC;

-- Start answering the business questions: What does the data tell us about the potential supply side of a surplus-food marketplace?
-- Which food-producing/business sectors generate the most food waste in Europe?
-- I'll start with 2023, because it's the latest year in our dataset.
-- 1. First, I look at the sectors at EU level:
SELECT sectors, food_waste FROM foodsurplus.eurostat_clean
WHERE countries = 'European Union - 27 countries (from 2020)' and time_period = 2023 and unit = 'Kilograms per capita'
ORDER by food_waste DESC;

-- 2. Now how to make it relevant to my app idea? For a Too Good To Go-style marketplace, household food waste isn't directly part of the platform's supply side.
-- So let's isolate the sectors that could potentially provide food surplus:
SELECT sectors, food_waste FROM foodsurplus.eurostat_clean
WHERE countries = 'European Union - 27 countries (from 2020)' and time_period = 2023 and unit = 'Kilograms per capita'
and sectors <> 'Households' and sectors <> 'Total'
ORDER by food_waste DESC; 

-- this leads to a much more relevant question: where does potentially redistributable food waste occur outside households?
-- 3. Creating first important KPI: non-household food waste per capita. And this gives us a first country-level proxy for potential business-side supply
-- i.e., food waste ≠ edible surplus ≠ recoverable surplus.
SELECT countries, time_period, SUM(food_waste) as non_household_waste_kg_per_capita FROM foodsurplus.eurostat_clean
WHERE time_period = 2023 and unit = 'Kilograms per capita'
and sectors <> 'Households' and sectors <> 'Total'
GROUP by countries, time_period
ORDER by non_household_waste_kg_per_capita DESC; 

-- 4. Comparing sectors across countries:
SELECT countries, sectors, food_waste FROM foodsurplus.eurostat_clean
WHERE time_period = 2023 and unit = 'Kilograms per capita'
and sectors <> 'Households' and sectors <> 'Total'
ORDER by countries, food_waste DESC;







