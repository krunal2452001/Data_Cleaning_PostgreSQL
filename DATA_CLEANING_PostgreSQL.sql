-- PROJECT 1
-- CLEANING THE DATA USING PostgreSQL

CREATE TABLE layoffs_staging 
(LIKE world_layoffs INCLUDING ALL);

SELECT * 
FROM layoffs_staging;

INSERT INTO layoffs_staging
SELECT * 
FROM world_layoffs;






-- remove all the duplicate values
/*
1: we will use rownumber() to check row count for each row
2: if rowcount is > 1 means that row is repeated
3; delete all rows having rowcount > 1
*/

-- we put location and date in '' because they are key words so to treate them as col name we kept ithem into ''.
-- step 1
SELECT *,
ROW_NUMBER() OVER( PARTITION BY company, 'location' , industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- step 2: put above query in CTE to extract all duplicate rows

WITH duplicate_cte AS (
SELECT *,
ROW_NUMBER() OVER( PARTITION BY company, 'location' , industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Step3: remove all duplicate rows
/*
big problem is if we perform delete operation now it will delete original and duplicate
row but we just want to delete duplicate row so there will be slite change in code
*/

WITH duplicate_cte AS (
  SELECT *,
    ROW_NUMBER() OVER(
      PARTITION BY company, "location", industry, total_laid_off, percentage_laid_off, "date", stage, country, funds_raised_millions
    ) AS row_num
  FROM layoffs_staging
)
DELETE FROM layoffs_staging
WHERE (company, "location", industry, total_laid_off, percentage_laid_off, "date", stage, country, funds_raised_millions) IN (
  SELECT company, "location", industry, total_laid_off, percentage_laid_off, "date", stage, country, funds_raised_millions
  FROM duplicate_cte
  WHERE row_num > 1
);

SELECT * 
FROM layoffs_staging;







-- standardizing data (ie: remove extra space and giving proper datatype and everything)

SELECT DISTINCT TRIM(company) AS trim_company
FROM layoffs_staging;

UPDATE layoffs_staging
SET company = TRIM(company);

-- now we check for miss spell or same spelling but little bit of error

SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1; -- "Crypto", "Crypto Currency", "CryptoCurrency" we found this 3 but they 
-- can be just 1 as crypto so lets combine them.

UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'; -- this will take all the words which have crypto

-- cross-verify above update
SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1; 

-- lets repeat above step for all the columns which have string datatype
SELECT DISTINCT location
FROM layoffs_staging
ORDER BY 1;

UPDATE layoffs_staging
SET location = 'Malmo'
WHERE location = 'Malmö';

SELECT DISTINCT country
FROM layoffs_staging
ORDER BY 1;

UPDATE layoffs_staging
SET country = TRIM( TRAILING '.' FROM country)
WHERE country LIKE 'United States%';










-- changing datatype of date column to date datetype rn its string

SELECT TO_DATE(date, 'MM/DD/YYYY')
FROM layoffs_staging;

UPDATE layoffs_staging
SET date = TO_DATE(date, 'MM/DD/YYYY');

-- datatype of date column is still text/varchar but the date is in the proper formate
-- so we will now change the datatype of column but make sure that we do this is staging
-- table as we dont want to mess around with main table as changing datatype of column 
-- is really a big task for dataset

ALTER TABLE layoffs_staging
ALTER COLUMN date TYPE DATE
USING date::DATE;







-- handelling missing and null values

/*
step 1: we will check all the missing values and null
step 2: Do self Join on table to find what we can replace the value with to handle 
        missing values
Step 3: change all the missing values to null values 
step 4: update all null values
step 5: check if all things got updated or not( just run step 2 and we shoul get 0 
		rows as output so it got updated and run last query from step 1 just to double
		check)
step 6: check if we still have missing values reason is there is only 1 row for those 
		rows
*/

-- step1

SELECT *
FROM layoffs_staging
WHERE total_laid_off IS NULL;

SELECT *
FROM layoffs_staging
WHERE industry IS NULL OR
industry = ''; -- we found missing values and null

SELECT *
FROM layoffs_staging
WHERE company = 'Airbnb'; /* we got multiple rows for "Airbnb" and found out that 
industry for "Airbnb" is travel as it is mentioned in other column and do exect 
same thing for other companies as well and we will now replace the industry where 
values are missing */

-- step 2

SELECT *
FROM layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- step 3

UPDATE layoffs_staging
SET industry = NULL
WHERE industry = '';

-- step 4

UPDATE layoffs_staging AS t1
SET industry = t2.industry
FROM layoffs_staging AS t2
WHERE t1.company = t2.company
  AND t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- step 5
-- run step 2 and its correct


-- step 6

SELECT *
FROM layoffs_staging
WHERE industry IS NULL;









/*
Lets handle missing value in "percentage_laid_off" and "total_laid_off" Now we will 
totaly delete the rows where both the column are null because its complately useless 
for us. But if we had 3rd rows like "total_employs" then we can do some math calculations
and fill the one empty row but in this case we cant. so we will drop all of those rows.
Reason 1: our analyis need those 2 rows a lot so we dont want any null values in those 2
reason 2: we dont have 3rd row using which we can fill these empty values.

Is it the best way to deal with data?
No, we should not delete data but in these case we dont have any option.
*/


-- 2353 total rows

SELECT COUNT(*)
FROM layoffs_staging
WHERE total_laid_off IS NULL AND
percentage_laid_off IS NULL; -- 362 null rows

-- 362/2353 = 0.15 -> so we are removing 15% of data which is a lot

DELETE
FROM layoffs_staging
WHERE total_laid_off IS NULL AND
percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging;
