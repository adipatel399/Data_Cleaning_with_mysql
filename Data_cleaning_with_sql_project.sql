select* 
from layoffs; 

create table layoffs_staging
like layoffs;

insert layoffs_staging
select*
from layoffs;



-- Removing Duplicates

select* ,
row_number() over(partition by company, location, industry, total_laid_off,
percentage_laid_off, 'date', stage, country, funds_raised_millions) as r_no
from layoffs_staging ; 

with duplicate_cte as
(
select* ,
row_number() over(partition by company, location, industry, total_laid_off,
percentage_laid_off, 'date', stage, country, funds_raised_millions) as r_no
from layoffs_staging 
)
select*
from duplicate_cte
where r_no > 1;




CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `r_no` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


insert into layoffs_staging2
select* ,
row_number() over(partition by company, location, industry, total_laid_off,
percentage_laid_off, 'date', stage, country, funds_raised_millions) as r_no
from layoffs_staging ;


select*
from layoffs_staging2
;


-- Standardizing Data

update layoffs_staging2
set company = trim(company);

select company,industry
from layoffs_staging2
where company = 'Airbnb';

update layoffs_staging2
set industry = 'Travel'
where company = 'Airbnb';

select company,industry
from layoffs_staging2
order by company;

select *
from layoffs_staging2
where industry like 'Crypto%';

select distinct(country)
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = trim(trailing '.'from country);

select country
from layoffs_staging2
where country like 'United States%';

select `date`,
STR_TO_DATE(`date`,'%m/%d/%Y') AS chan_date 
from layoffs_staging2;

update layoffs_staging2
set `date` = STR_TO_DATE(`date`,'%m/%d/%Y');


select *
from layoffs_staging2;

alter table layoffs_staging2
modify column `date` date;

-- Null values


select* 
from layoffs_staging2 t1
join layoffs_staging t2
  on t1.company = t2.company
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoffs_staging2
set industry = null
where industry = '';

update layoffs_staging2 t1
join layoffs_staging2 t2
  on t1.company = t2.company
set t1.industry = t2.industry
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;  


select *
from layoffs_staging2
where total_laid_off is null 
and percentage_laid_off is null;

delete 
from layoffs_staging2
where total_laid_off is null 
and percentage_laid_off is null;


-- Removing Columns

alter table layoffs_staging2
drop column r_no;

select*
from layoffs_staging2;

-- Data Exploratory Analysis

select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;

select*
from layoffs_staging2
where percentage_laid_off = 1;


select*
from layoffs_staging2
where percentage_laid_off = 1 and total_laid_off is not null
order by total_laid_off;

select*
from layoffs_staging2
where percentage_laid_off = 1
order by funds_raised_millions desc;

select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

select min(`date`), max(`date`)
from layoffs_staging2;

select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

select country, sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc;

select year(`date`), sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 1 desc;

select stage, sum(total_laid_off)
from layoffs_staging2
group by stage
order by 2 desc;

select company, sum(percentage_laid_off)
from layoffs_staging2
group by company
order by 2 desc;
;

select substring(`date`, 1,7) as `month`, sum(total_laid_off)
from layoffs_staging2
where substring(`date`, 1,7) is not null
group by `month`
order by 1 asc;

with rolling_total as
(
select substring(`date`, 1,7) as `month`, sum(total_laid_off) as total_off
from layoffs_staging2
where substring(`date`, 1,7) is not null
group by `month`
order by 1 asc
)
select `month`, total_off, 
 sum(total_off) over(order by `month`) as Roll_total
from rolling_total ;

select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
order by 3 desc;

with company_year (company, years, total_laid_off) as
(
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
), Company_year_rank as
(
select* ,
dense_rank() over (partition by years order by total_laid_off desc)as ranking
from company_year
where years is not null
)
select*
from company_year_rank
where ranking<=5;