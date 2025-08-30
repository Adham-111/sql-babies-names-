--create New database 
CREATE database baby_names_db;
USE baby_names_db;

--
-- Table structure for table `names`
--

CREATE TABLE names (
  State CHAR(2),
  Gender CHAR(1),
  Year INT,
  Name VARCHAR(45),
  Births INT);

--
-- Table structure for table `regions`
BULK INSERT names
FROM 'D:\project retail\US+Baby+Names+MySQL (1)\names_data.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
)
-- insert data from csv file into names table 

CREATE TABLE names_staging (
  State NVARCHAR(10),
  Gender NVARCHAR(10),
  Year NVARCHAR(10),
  Name NVARCHAR(100),
  Births NVARCHAR(100)   
);

BULK INSERT names_staging
FROM 'D:\project retail\US+Baby+Names+MySQL (1)\names_data.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,        -- skip header row
    CODEPAGE = '65001',  -- handles UTF-8
    TABLOCK
);

SELECT *
FROM names_staging
WHERE TRY_CAST(Births AS INT) IS NULL
      AND Births IS NOT NULL;

INSERT INTO names (State, Gender, Year, Name, Births)
SELECT 
    State,
    Gender,
    TRY_CAST(Year AS INT),
    Name,
    ISNULL(TRY_CAST(REPLACE(Births, ',', '') AS INT), 0)  --handel error when load 
FROM names_staging;




--

CREATE TABLE regions (
  State CHAR(2),
  Region VARCHAR(45));


-- Insert data into table regions
--

INSERT INTO regions VALUES ('AL', 'South'),
('AK', 'Pacific'),
('AZ', 'Mountain'),
('AR', 'South'),
('CA', 'Pacific'),
('CO', 'Mountain'),
('CT', 'New_England'),
('DC', 'Mid_Atlantic'),
('DE', 'South'),
('FL', 'South'),
('GA', 'South'),
('HI', 'Pacific'),
('ID', 'Mountain'),
('IL', 'Midwest'),
('IN', 'Midwest'),
('IA', 'Midwest'),
('KS', 'Midwest'),
('KY', 'South'),
('LA', 'South'),
('ME', 'New_England'),
('MD', 'South'),
('MA', 'New_England'),
('MN', 'Midwest'),
('MS', 'South'),
('MO', 'Midwest'),
('MT', 'Mountain'),
('NE', 'Midwest'),
('NV', 'Mountain'),
('NH', 'New England'),
('NJ', 'Mid_Atlantic'),
('NM', 'Mountain'),
('NY', 'Mid_Atlantic'),
('NC', 'South'),
('ND', 'Midwest'),
('OH', 'Midwest'),
('OK', 'South'),
('OR', 'Pacific'),
('PA', 'Mid_Atlantic'),
('RI', 'New_England'),
('SC', 'South'),
('SD', 'Midwest'),
('TN', 'South'),
('TX', 'South'),
('UT', 'Mountain'),
('VT', 'New_England'),
('VA', 'South'),
('WA', 'Pacific'),
('WV', 'South'),
('WI', 'Midwest'),
('WY', 'Mountain');

---




--analysis 
--Find the overall most popular girl and boy names and show how they have changed
--in popularity rankings over the years 
SELECT TOP 1 
    n.Name,
    SUM(births) AS number_of_births
FROM names n
WHERE gender = 'F'
GROUP BY n.Name
ORDER BY number_of_births DESC;  --jesica
----find most populat  name for male
select top 1 
n.name , sum(births) as number_of_births 
from names n 
where gender ='M'
group by n.Name
order by number_of_births desc --michael 
--
--get all names of girls
WITH girls_names AS (
    SELECT year, name, SUM(births) AS number_births
    FROM names 
    WHERE gender = 'F'
    GROUP BY year, name
), 
--- make column as popularity using windowfunction and check changes in ranking over years
popular_girls_name AS (
    SELECT year, name,
           ROW_NUMBER() OVER (PARTITION BY year ORDER BY number_births DESC) AS popularity
    FROM girls_names
)
-- filter by most popular girl only 
SELECT *
FROM popular_girls_name
WHERE name = 'Jessica'
---for boys names 
with boys_names as (select year ,name ,sum(births) as number_of_births 
from names
where gender ='M'
group by name ,year 
),
 popularity_boys_names as (select name , year , 
ROW_NUMBER()over(partition by year order by number_of_births desc) as popularity_ranking
from boys_names)
select * from popularity_boys_names 
where  name = 'Michael'

--Find the names with the biggest jumps in popularity from the first year of 
--the data set to the last year
--first year
with first_year as(
select year , name , ROW_NUMBER()over(order by sum(births) desc) as rank_first 
from names 
where year = (select min(year) from names) 
group by name , year ),
--last_year 
last_year_ranking AS (
    SELECT year, name,
           ROW_NUMBER() OVER (ORDER BY SUM(births) DESC) AS rank_last
    FROM names
    WHERE year = (SELECT MAX(year) FROM names)
    GROUP BY year, name
)
select f.name ,f.rank_first ,l.rank_last , (f.rank_first-l.rank_last)as rank_change
from first_year f join last_year_ranking l 
on f.name=l.name
ORDER BY ABS(f.rank_first - l.rank_last) DESC

---For each year, return the 3 most popular girl names and 3 most popular boy names
with rank_all_names as(SELECT 
    n.Name,year,gender ,
    SUM(Births) AS number_of_births,
	ROW_NUMBER()over(partition by year,gender order by SUM(Births) desc)as ranked
FROM names n
GROUP BY n.Name ,n.year,gender
) 
select * from rank_all_names 
where ranked <4
--For each decade, return the 3 most popular girl names and 3 most popular boy names
with rank_all_names as(SELECT 
    n.Name,(year/10)*10 as decade,gender ,
    SUM(Births) AS number_of_births,
	ROW_NUMBER()over(partition by (year/10)*10,gender order by SUM(Births) desc)as ranked
FROM names n
GROUP BY n.Name ,(year/10)*10,gender
) 
select * from rank_all_names 
where ranked <4
--Return the number of babies born in each of the six regions
--(NOTE: The state of MI should be in the Midwest region)
select r.Region,sum(n.Births) as number_babies 
from names n 
join regions r on n.state = r.state
group by r.Region
--Return the 3 most popular girl names and 3 most popular boy names within each region
with rank_popular_name as (select r.Region,n.name ,sum(n.Births) as number_babies,n.Gender ,
ROW_NUMBER() over(partition by r.Region ,n.Gender order by sum(n.Births) desc) as rank_popularity
from names n 
join regions r on n.state = r.state
group by r.Region,n.name,n.Gender) 
select * from rank_popular_name 
where rank_popularity < 4
--Find the 10 most popular androgynous names (names given to both females and males)
select top 10
Name , count(distinct Gender) as num_gender ,sum(Births) as number_babies
from names 
group by name 
having count(distinct Gender)=2
order by number_babies desc
--Find the length of the shortest and longest names, and identify the most popular short names 
--(those with the fewest characters) and long names (those with the most characters)
select
max(LEN(name)) as max_length ,min(len(name)) as minimum_length
from names 

select name ,SUM(births) as number_babies
from names
where len(name) in(15,2)
group by name 
order by number_babies desc

--. Find the state with the highest percent of babies named "Chris"

with number_chris as (select state ,sum(births) as number_chrisbabies
from names 
where name ='chris'
group by state
)
,
num_allbabies as (select state ,sum(births) as number_babies
from names 
group by state
)
select f.state , f.number_chrisbabies,s.number_babies,(f.number_chrisbabies * 100.0 / s.number_babies) AS percentage_chris
from number_chris f join num_allbabies s 
on f.State=s.State
order by percentage_chris desc





