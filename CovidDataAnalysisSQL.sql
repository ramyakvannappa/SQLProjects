select * from CovidDeaths
where continent is not null;

select * from CovidVaccination;

-- Getting some data from coviddeaths table
select location, date,total_cases, new_cases, total_Deaths,population
from CovidDeaths
order by 1,2;


-- Total Cases v/s Total Deaths
select location, date, total_cases, total_Deaths, population, (total_Deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
-- where location like '%states%'
where continent is not null
order by 1,2;


-- Countries with highest infection rate compared to thier population
select location, population, max(total_cases) as highestInfectionCount, max((total_cases/population))*100 as highestPercentofPopulationInfected
from CovidDeaths
where continent is not null
group by location, population
order by highestPercentofPopulationInfected desc;


--Countries with total death count per population
select location, sum(cast(new_deaths as int)) as total_DeathCount
from CovidDeaths
where continent is not null
group by location
order by 2 desc;


-- Highest death count per country ever noticed since the begining of the pandemic
select location, max(cast(new_deaths as int)) as highest_DeathCount
from CovidDeaths
where continent is not null
group by location
order by 2 desc;


-- Continents with their total covid cases
select continent, sum(new_cases) as TotalCasesperContinent
from CovidDeaths
where continent is not null
group by continent
order by 2 desc;


-- GLOBAL NUMBERS 
-- Global covid numbers per day
select date, sum(new_cases) total_cases, sum(cast(new_deaths as int)) total_deaths, (sum(cast(new_deaths as int)) /sum(new_cases))*100 DeathPercentage
from CovidDeaths
where continent is not null
group by date
order by 1,2;

-- Global numbers till date
select  sum(new_cases) total_cases, sum(cast(new_deaths as int)) total_deaths, (sum(cast(new_deaths as int)) /sum(new_cases))*100 DeathPercentage
from CovidDeaths
where continent is not null
order by 1,2;


-- Covid vaccination numbers each day since the start of the pandemic
select cdeath.continent, cdeath.location, cdeath.date, cdeath.population, COALESCE(cvacc.new_vaccinations,0) new_vaccinations
from CovidDeaths cdeath
inner join CovidVaccination cvacc 
on cdeath.location = cvacc.location
and cdeath.date = cvacc.date
where cdeath.continent is not null
order by 2,3;



-- Getting the rolling numbers of covid vaccination per country 
select cdeath.continent, cdeath.location, cdeath.date, cdeath.population, cvacc.new_vaccinations, 
	SUM(CONVERT(INT, cvacc.new_vaccinations)) OVER(PARTITION BY cdeath.location ORDER BY  cdeath.location , cdeath.date ) AS rollingPeopleVaccinated
from CovidDeaths cdeath
inner join CovidVaccination cvacc 
on cdeath.location = cvacc.location
and cdeath.date = cvacc.date
where cdeath.continent is not null
order by 2,3;


-- What percentage of the people in the country are vaccinated
-- USE CTE

WITH PopulationVsVaccination( continent, location, date, population, new_vaccinations, rollingPeopleVaccinated)
AS 
(
select cdeath.continent, cdeath.location, cdeath.date, cdeath.population, cvacc.new_vaccinations, 
SUM(CONVERT(INT, cvacc.new_vaccinations)) OVER(PARTITION BY cdeath.location ORDER BY  cdeath.location , cdeath.date ) AS rollingPeopleVaccinated
from CovidDeaths cdeath
inner join CovidVaccination cvacc 
on cdeath.location = cvacc.location
and cdeath.date = cvacc.date
where cdeath.continent is not null
-- order by 2,3
)
SELECT *, (rollingPeopleVaccinated/population)*100
from PopulationVsVaccination;



 -- Creating a table to insert PercentPopulationVaccinated
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
( continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
select cdeath.continent, cdeath.location, cdeath.date, cdeath.population, cvacc.new_vaccinations, 
SUM(CONVERT(INT, cvacc.new_vaccinations)) OVER(PARTITION BY cdeath.location ORDER BY  cdeath.location , cdeath.date ) AS rollingPeopleVaccinated
from CovidDeaths cdeath
inner join CovidVaccination cvacc 
on cdeath.location = cvacc.location
and cdeath.date = cvacc.date
where cdeath.continent is not null;


SELECT * FROM #PercentPopulationVaccinated;



-- Creating view 
CREATE VIEW PopulationVaccinated as
select cdeath.continent, cdeath.location, cdeath.date, cdeath.population, cvacc.new_vaccinations, 
SUM(CONVERT(INT, cvacc.new_vaccinations)) OVER(PARTITION BY cdeath.location ORDER BY  cdeath.location , cdeath.date ) AS rollingPeopleVaccinated
from CovidDeaths cdeath
inner join CovidVaccination cvacc 
on cdeath.location = cvacc.location
and cdeath.date = cvacc.date
where cdeath.continent is not null
-- order by 2,3