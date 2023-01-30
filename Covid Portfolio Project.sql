create database DB_Covid;

use DB_Covid;

select * from coviddeaths
order by 3

select * from DB_Covid..covidvaccines
order by 3


-- select the data that we are going to use

select location, date, total_cases, new_cases, total_deaths, population
from DB_Covid..coviddeaths
order by 1,2

-- total cases vs total deaths

-- shows the liklihood of dying if u get covid in india

select location, date, total_cases,total_deaths, (CAST(total_deaths as float)/CAST(total_cases as float))*100 as death_Percentage
from DB_Covid..coviddeaths
where location like '%ind%'
order by 1,2

-- total cases vs total population
-- what %age of population got covid in India

select location, date, total_cases,population, (CAST(total_cases as float)/CAST(population as float))*100 as cases_Percentage
from DB_Covid..coviddeaths
where location like '%ind%'

-- which country has the highest infection rate compared to population

select location, population, Max(total_cases) max_total_cases, max((CAST(total_cases as float)/CAST(population as float)))*100 as infection_Percentage
from DB_Covid..coviddeaths
group by location, population
order by infection_Percentage desc

-- countries with the highest death count 
--beacause some records holds location as continent where continent is null

select location, max(total_deaths) as Highest_death_count from coviddeaths
where continent is not null
group by location
order by Highest_death_count desc

-- continents with the highest death count 

select continent, max(total_deaths) as Highest_death_count from coviddeaths
where continent is not null
group by continent
order by Highest_death_count desc

select location, max(total_deaths) as Highest_death_count from coviddeaths
where continent is null
group by location
order by Highest_death_count desc



-- GLOBAL NUMBERS

-- daily percentage of new cases vs new deaths
select date, SUM(new_cases) as total_cases_per_day , SUM(new_deaths) as total_death_per_day, 
(SUM(cast(new_deaths as float))/SUM(cast(new_cases as int)))* 100 as death_percenage_per_day
from coviddeaths
where continent is not null
group by date

-- globally total cases vs total deaths
select SUM(total_cases) as TotalCase, SUM(total_deaths) as TotalDeaths, (SUM(cast(total_deaths as float))/SUM(total_cases))*100
as TotalPercentageOfDeathsGlobaly
from coviddeaths
where continent is not null

-- Globally Daily new cases vs daily hospitalisation and Percentage 

select date, sum(new_cases) as NewCases, sum(cast(hosp_patients as float)) as Hospitalisation, 
(sum(cast(hosp_patients as float))/sum(new_cases)) as PercentageOfDailyHospitalisation
from coviddeaths
group by date


-- total population vs total vaccination

select SUM(cast(population as bigint)) as Total_Population , sum(cast(total_vaccinations as bigint )) as Total_Vaccination,
(sum(cast(total_vaccinations as float))/SUM(cast(population as bigint)))*100 as Percentage_of_people_vaccinated
from coviddeaths death
join covidvaccines vacc
on vacc.location = death.location and vacc.date = death.date

-- total population vs total vaccination continent wise daily

select death.continent, death.location, death.date,SUM(cast(population as bigint)) as Total_Population , sum(cast(total_vaccinations as bigint )) as Total_Vaccination,
(sum(cast(total_vaccinations as float))/SUM(cast(population as bigint)))*100 as Percentage_of_people_vaccinated
from coviddeaths death
join covidvaccines vacc
on vacc.location = death.location and vacc.date = death.date
where death.continent is not null
group by death.continent, death.location, death.date
order by 1,2,3

-- Total population vs new vaccinations
select death.continent, death.location, death.date,death.population as Total_Population , vacc.new_vaccinations as New_Vaccination
from coviddeaths death
join covidvaccines vacc
on vacc.location = death.location and vacc.date = death.date
where death.continent is not null
order by 2,3

-- Location wise Boosters
select location, sum(cast(total_vaccinations as bigint)) as Total_Vaccinations, sum(cast(total_boosters as bigint))  as Total_Boosters,
(sum(cast(total_boosters as float))/sum(cast(total_vaccinations as bigint)))*100 as Percentage_Of_Boosters_Pop
from covidvaccines
where continent is not null
group by location
order by 1


-- rolling people vaccinated location wise daily

select death.continent, death.location, death.date, cast(death.population as varchar) as Total_Population , cast(vacc.new_vaccinations as varchar) as New_Vaccination,
sum(cast(vacc.new_vaccinations as bigint))over(partition by death.location order by death.date) as rolling_vaccination_count
from coviddeaths death
join covidvaccines vacc
on vacc.location = death.location and vacc.date = death.date
where death.continent is not null

-- use CTE to get rolling percentage of rolling vaccinitations vs population daily

with RollVaccVSPop (continent, location, date, Total_Population, New_Vaccination, rolling_vaccination_count)
as
(select death.continent, death.location, death.date, cast(death.population as varchar) as Total_Population , cast(vacc.new_vaccinations as varchar) as New_Vaccination,
sum(cast(vacc.new_vaccinations as bigint))over(partition by death.location order by death.date) as rolling_vaccination_count
from coviddeaths death
join covidvaccines vacc
on vacc.location = death.location and vacc.date = death.date
where death.continent is not null)

select * , (cast(rolling_vaccination_count as float)/cast(Total_Population as int))*100 as rolling_Vacc_Percantage
from RollVaccVSPop;

-- use CTE to get rolling percentage of rolling vaccinitations vs population location wise

with Location_wise_RollVaccVSPop (continent, location, Total_Population, New_Vaccination, rolling_vaccination_count)
as
(select death.continent, death.location, cast(death.population as varchar) as Total_Population , cast(vacc.new_vaccinations as varchar) as New_Vaccination,
sum(cast(vacc.new_vaccinations as bigint))over(partition by death.location order by death.date) as rolling_vaccination_count
from coviddeaths death
join covidvaccines vacc
on vacc.location = death.location and vacc.date = death.date
where death.continent is not null)

select * , (cast(rolling_vaccination_count as float)/cast(Total_Population as int))*100 as rolling_Vacc_Percantage
from Location_wise_RollVaccVSPop;

-- creating temporary table

drop table if exists VaccinationAndRollingSum
create table VaccinationAndRollingSum
(Continent	nvarchar(255),
Location	nvarchar(255),
Date	datetime,
Population	bigint,
New_Vaccinations	bigint,
rolling_vaccination_count	bigint)


insert into VaccinationAndRollingSum
	select death.continent, death.location, death.date, cast(death.population as varchar) as Total_Population , cast(vacc.new_vaccinations as varchar) as New_Vaccination,
sum(cast(vacc.new_vaccinations as bigint))over(partition by death.location order by death.date) as rolling_vaccination_count
from coviddeaths death
join covidvaccines vacc
on vacc.location = death.location and vacc.date = death.date
where death.continent is not null

select *, (cast(rolling_vaccination_count as float)/Population)*100 as PercentageOfPopulationVaccinated  from VaccinationAndRollingSum

-- Creating View  Percantage of daily new casesd VS death

create view DailyCasesVSDailyDeaths as
select date, SUM(new_cases) as total_cases_per_day , SUM(new_deaths) as total_death_per_day, 
(SUM(cast(new_deaths as float))/SUM(cast(new_cases as int)))* 100 as death_percenage_per_day
from coviddeaths
where continent is not null
group by date

