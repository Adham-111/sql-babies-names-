# 📊 Baby Names SQL Project

## 📌 Project Overview
This project analyzes the **U.S. Baby Names dataset** using SQL.  
It covers everything from **database creation, data ingestion, and cleaning** to **advanced analytical queries**.  
The results are also visualized with charts for better storytelling.

---

## 🎯 Goals of the Project
- Create and manage a relational database for baby names  
- Import and clean data from CSV files  
- Explore naming trends over time, across regions, and by gender  
- Answer key questions such as:  
  - What are the most popular male and female names?  
  - How have names like *Jessica* and *Michael* changed over time?  
  - Which names are androgynous?  
  - What regions show unique naming patterns?  
  - What are the shortest and longest popular names?  


---

## 📂 Database Schema

### `names` Table
| Column | Type    | Description                     |
|--------|---------|---------------------------------|
| State  | CHAR(2) | U.S. state abbreviation         |
| Gender | CHAR(1) | M = Male, F = Female            |
| Year   | INT     | Year of birth                   |
| Name   | VARCHAR | Baby name                       |
| Births | INT     | Number of births with that name |

### `regions` Table
| Column | Type    | Description         |
|--------|---------|---------------------|
| State  | CHAR(2) | U.S. state          |
| Region | VARCHAR | Geographic region   |

---

## 📂 Database Setup & Code

### 1️⃣ Create Database and Tables
```sql
-- Create new database
CREATE DATABASE baby_names_db;
USE baby_names_db;

-- Table for cleaned baby names
CREATE TABLE names (
  State CHAR(2),
  Gender CHAR(1),
  Year INT,
  Name VARCHAR(45),
  Births INT
);

-- Table for staging raw CSV data
CREATE TABLE names_staging (
  State NVARCHAR(10),
  Gender NVARCHAR(10),
  Year NVARCHAR(10),
  Name NVARCHAR(100),
  Births NVARCHAR(100)
);
2️⃣ Load Data from CSV
sql
Copy code
-- Insert data into staging table
BULK INSERT names_staging
FROM 'D:\project retail\US+Baby+Names+MySQL (1)\names_data.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    TABLOCK
);

-- Clean data and move into final table
INSERT INTO names (State, Gender, Year, Name, Births)
SELECT 
    State,
    Gender,
    TRY_CAST(Year AS INT),
    Name,
    ISNULL(TRY_CAST(REPLACE(Births, ',', '') AS INT), 0)
FROM names_staging;
   3️⃣ Create Regions Table
   CREATE TABLE regions (
  State CHAR(2),
  Region VARCHAR(45)
);

INSERT INTO regions VALUES 
('AL', 'South'), ('AK', 'Pacific'), ('AZ', 'Mountain'),
('AR', 'South'), ('CA', 'Pacific'), ('CO', 'Mountain'),
('CT', 'New_England'), ('DC', 'Mid_Atlantic'), ('DE', 'South'),
('FL', 'South'), ('GA', 'South'), ('HI', 'Pacific'),
('ID', 'Mountain'), ('IL', 'Midwest'), ('IN', 'Midwest'),
('IA', 'Midwest'), ('KS', 'Midwest'), ('KY', 'South'),
('LA', 'South'), ('ME', 'New_England'), ('MD', 'South'),
('MA', 'New_England'), ('MN', 'Midwest'), ('MS', 'South'),
('MO', 'Midwest'), ('MT', 'Mountain'), ('NE', 'Midwest'),
('NV', 'Mountain'), ('NH', 'New_England'), ('NJ', 'Mid_Atlantic'),
('NM', 'Mountain'), ('NY', 'Mid_Atlantic'), ('NC', 'South'),
('ND', 'Midwest'), ('OH', 'Midwest'), ('OK', 'South'),
('OR', 'Pacific'), ('PA', 'Mid_Atlantic'), ('RI', 'New_England'),
('SC', 'South'), ('SD', 'Midwest'), ('TN', 'South'),
('TX', 'South'), ('UT', 'Mountain'), ('VT', 'New_England'),
('VA', 'South'), ('WA', 'Pacific'), ('WV', 'South'),
('WI', 'Midwest'), ('WY', 'Mountain');
📊 Analysis Queries
🔹 Most Popular Names
-- Most popular girl name
SELECT TOP 1 Name, SUM(Births) AS number_of_births
FROM names
WHERE Gender = 'F'
GROUP BY Name
ORDER BY number_of_births DESC;

-- Most popular boy name
SELECT TOP 1 Name, SUM(Births) AS number_of_births
FROM names
WHERE Gender = 'M'
GROUP BY Name
ORDER BY number_of_births DESC;

🔹 Popularity Over Time
-- Jessica ranking over time
WITH girls_names AS (
    SELECT Year, Name, SUM(Births) AS number_births
    FROM names
    WHERE Gender = 'F'
    GROUP BY Year, Name
),
popular_girls AS (
    SELECT Year, Name,
           ROW_NUMBER() OVER (PARTITION BY Year ORDER BY number_births DESC) AS popularity
    FROM girls_names
)
SELECT * FROM popular_girls WHERE Name = 'Jessica';

-- Michael ranking over time
WITH boys_names AS (
    SELECT Year, Name, SUM(Births) AS number_births
    FROM names
    WHERE Gender = 'M'
    GROUP BY Year, Name
),
popular_boys AS (
    SELECT Year, Name,
           ROW_NUMBER() OVER (PARTITION BY Year ORDER BY number_births DESC) AS popularity
    FROM boys_names
🔹 Biggest Jumps in Popularity
WITH ranked_names AS (
  SELECT Name, Gender, Year,
         ROW_NUMBER() OVER (PARTITION BY Year, Gender ORDER BY SUM(Births) DESC) AS rank
  FROM names
  GROUP BY Name, Gender, Year
),
rank_change AS (
  SELECT Name, Gender,
         MIN(CASE WHEN Year = 1910 THEN rank END) AS rank_start,
         MAX(CASE WHEN Year = 2015 THEN rank END) AS rank_end
  FROM ranked_names
  GROUP BY Name, Gender
)
SELECT Name, Gender, (rank_start - rank_end) AS jump
FROM rank_change
ORDER BY jump DESC;

🔹 Top 3 Names Per Year
WITH yearly_rank AS (
  SELECT Year, Name, Gender,
         ROW_NUMBER() OVER (PARTITION BY Year, Gender ORDER BY SUM(Births) DESC) AS rank
  FROM names
  GROUP BY Year, Name, Gender
)
SELECT Year, Name, Gender, rank
FROM yearly_rank
WHERE rank <= 3
ORDER BY Year, Gender, rank;

🔹 Top 3 Names Per Decade
WITH decade_rank AS (
  SELECT (Year/10)*10 AS decade, Name, Gender,
         ROW_NUMBER() OVER (PARTITION BY (Year/10)*10, Gender ORDER BY SUM(Births) DESC) AS rank
  FROM names
  GROUP BY (Year/10)*10, Name, Gender
)
SELECT decade, Name, Gender, rank
FROM decade_rank
WHERE rank <= 3
ORDER BY decade, Gender, rank;

🔹 Regional Distribution
SELECT r.Region, n.Name, SUM(n.Births) AS total_births
FROM names n
JOIN regions r ON n.State = r.State
GROUP BY r.Region, n.Name
ORDER BY r.Region, total_births DESC;

🔹 Top 10 Androgynous Names
WITH gender_totals AS (
  SELECT Name, Gender, SUM(Births) AS total_births
  FROM names
  GROUP BY Name, Gender
),
pivoted AS (
  SELECT Name,
         SUM(CASE WHEN Gender = 'M' THEN total_births ELSE 0 END) AS male_births,
         SUM(CASE WHEN Gender = 'F' THEN total_births ELSE 0 END) AS female_births
  FROM gender_totals
  GROUP BY Name
)
SELECT TOP 10 Name, male_births, female_births
FROM pivoted
WHERE male_births > 0 AND female_births > 0
ORDER BY ABS(male_births - female_births);

🔹 Shortest and Longest Names
SELECT TOP 10 Name, SUM(Births) AS total_births, LEN(Name) AS name_length
FROM names
GROUP BY Name
ORDER BY LEN(Name) ASC, total_births DESC;

SELECT TOP 10 Name, SUM(Births) AS total_births, LEN(Name) AS name_length
FROM names
GROUP BY Name
ORDER BY LEN(Name) DESC, total_births DESC;

🔹 States with Highest % of “Chris”
SELECT State,
       SUM(Births) AS total_state_births,
       SUM(CASE WHEN Name = 'Chris' THEN Births ELSE 0 END) AS chris_births,
       CAST(SUM(CASE WHEN Name = 'Chris' THEN Births ELSE 0 END) * 100.0 /
            SUM(Births) AS DECIMAL(5,2)) AS chris_percentage
FROM names
GROUP BY State
ORDER BY chris_percentage DESC;
)
SELECT * FROM popular_boys WHERE Name = 'Michael';
