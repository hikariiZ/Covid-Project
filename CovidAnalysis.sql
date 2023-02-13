select *
from CovidDeaths
where continent is not null;

select *
from CovidVaccinations ;

--Total cases VS Total deaths =>the likelihood of dying if you contract covid in certain country
select location, date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths`
where location like '%States%'
and continent is not null
order by 1,2;

--Total cases VS Popuation =>the infection rate in certain country
select location, date,total_cases,population,(total_cases/population)*100 as InfectionRate
from CovidDeaths
where location like '%States%'
order by 1,2;

--Coutries with highest infection rate
select date,location,population,Max(total_cases) as HighestInfectionCount,Max(total_cases/population)*100 as InfectionRate
from CovidDeaths
group by date,location, population
order by InfectionRate desc;

--Coutries with highest death count
select location,population,Max(cast(total_deaths as int)) as HighestDeathCount,Max(total_deaths/population)*100 as DeathRate
from CovidDeaths
where continent is not null
group by location,population
order by HighestDeathCount desc;

--Coutries with highest death count,break things further with continent
select continent,Max(cast(total_deaths as int)) as HighestDeathCount,Max(total_deaths/population)*100 as DeathRate
from CovidDeaths`
where continent is not null
group by continent
order by HighestDeathCount desc;

--Global numbers
select date,sum(cast(new_deaths as int)) as total_deaths,sum(new_cases) as total_cases,sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathRate
from CovidDeaths
where continent is not null
group by date
order by 1,2;

select sum(cast(new_deaths as int)) as total_deaths,sum(new_cases) as total_cases,sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathRate
from CovidDeaths
where continent is not null;

--Total death rate group by location
select location,sum(cast(new_deaths as int)) as total_deaths
from CovidDeaths
where continent is null
and location not in ('World','European Union','International')
group by location
order by total_deaths desc;

--Total population vs Vaccination
select dea.continent,dea.location,dea.date,vac.new_vaccinations,dea.population
from CovidDeaths dea
join CovidVaccinations vac
  on dea.date=vac.date
  and dea.location = vac.location
where dea.continent is not null
order by 2,3;

--Add RollingPeopleVaccinated column
select dea.continent,dea.location,dea.date,vac.new_vaccinations,dea.population,sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location,dea.date)as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
  on dea.date=vac.date
  and dea.location = vac.location
where dea.continent is not null
order by 2,3;

--CTE
WITH PopVsVac as(
select dea.continent,dea.location,dea.date,vac.new_vaccinations,dea.population,sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location,dea.date)as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
  on dea.date=vac.date
  and dea.location = vac.location
where dea.continent is not null
)
select continent,location,population,max(RollingPeopleVaccinated) as RollingPeopleVaccinated,(max(RollingPeopleVaccinated)/population*100) as Vaccination_rate
from PopVsVac
where RollingPeopleVaccinated is not null
group by location,continent,population
order by 1,2;

--Create table
CREATE TABLE IF NOT EXISTS PopVac
(`Continent` STRING,
  `Location`  STRING,
  `Date` TIMESTAMP NOT NULL,
  `Population` INT64,
  `new_vaccinations` INT64,
  `RollingPeopleVaccinated` INT64)
INSERT INTO PopVac
(select dea.continent,dea.location,dea.date,vac.new_vaccinations,dea.population,sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location,dea.date)as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
  on dea.date=vac.date
  and dea.location = vac.location
where dea.continent is not null
)
select continent,location,population,max(RollingPeopleVaccinated) as RollingPeopleVaccinated,(max(RollingPeopleVaccinated)/population*100) as Vaccination_rate
from PopVac
where RollingPeopleVaccinated is not null
group by location,continent,population
order by 1,2;

--Create view for later visualisation
CREATE VIEW populationVSvaccination AS
(select dea.continent,dea.location,dea.date,vac.new_vaccinations,dea.population,sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location,dea.date)as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
  on dea.date=vac.date
  and dea.location = vac.location
where dea.continent is not null
)
