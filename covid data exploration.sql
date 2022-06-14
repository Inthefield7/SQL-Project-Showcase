/*
Covid data exploration 
Functions used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

**Download excel campatablity bundle from microsoft if the import data type doesn't support excel
*/

select *
from CovidProjects..CovidDeath
where continent is not null
order by 3,4

--total cases / total deaths 
--covid mortality rate of a specific country 
select 
	Location
	,date
	,total_cases
	,total_deaths
	,(total_deaths/total_cases)*100 as DeathPercentage
from CovidProjects..CovidDeath
where location like '%states%'
	and continent is not null
order by 1,2

--total cases / population 
--infection rate of an country 
select
	Location
	,total_cases
	,date
	,population
	,(total_cases/population)*100 as InfectionPercentage
from CovidProjects..CovidDeath
where continent is not null
order by 1, 3

--ranked contries by population infection rate
select
	location
	,population
	,max(total_cases) as maxinfectioncount
	,max((total_cases/population))*100 as PercentPopInfected
from CovidProjects..CovidDeath
group by location, population
having max((total_cases/population))*100 is not null
order by PercentPopInfected

--ranked countries by population death rate
select 
	location
	,population
	,max(total_deaths) as maxdeathcount
	,max((total_deaths/population))*100 as PercentPopdead
from CovidProjects..CovidDeath
group by location, population
having max((total_deaths/population))*100 is not null
order by PercentPopdead

--continent data
--*deaths values are in nvarchar, needs to be cast as int for math op
select 
	continent
	,max(cast(Total_deaths as int)) as TotalDeathcount
from CovidProjects..CovidDeath
where continent is not null
group by continent
order by TotalDeathcount desc

--global numbers 

--golbal death number
select 
	sum(new_cases) as total_cases
	,sum(cast(new_deaths as int)) as total_deaths
	,sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from CovidProjects..CovidDeath
where continent is not null
order by 1,2

--join two dataset
select *
from CovidProjects..CovidDeath dea
	join CovidProjects..CovidVaccine vac
		on dea.location = vac.location
		and dea.date = vac.date

--total population vs vaccinations
--% of population
--partition by => break up the sum by location to get vaccination # of each country
--"order by" to show rolling count
select 
	dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,sum(convert(int,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date) as rollingPepVaccinated
from CovidProjects..CovidDeath dea
	join CovidProjects..CovidVaccine vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null
order by 2,3

--create a CTE(common table expression) 
 
with PopvsVac (continent, Location, Date, Population, New_Vaccinations, rollingPepVaccinated)
as 
(
select 
	dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,sum(convert(bigint,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date) as rollingPepVaccinated
from CovidProjects..CovidDeath dea
	join CovidProjects..CovidVaccine vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (rollingPepVaccinated / Population) * 100 as RollingPepVacPerc
from PopvsVac
where rollingPepVaccinated is not null

--temp table
Drop table if exists #PercPepVaccinated --allows multiple execution 
create table #PercPepVaccinated
(
Continent nvarchar(255)
,Location nvarchar(255)
,Date datetime
,Population numeric
,New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercPepVaccinated
select
	dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,sum(convert(bigint,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date) as rollingPepVaccinated
from CovidProjects..CovidDeath dea
join CovidProjects..CovidVaccine vac
		on dea.location = vac.location
		and dea.date = vac.date
Select *, (RollingPeopleVaccinated/Population)*100
From #PercPepVaccinated

--create view to store data for visualization
create view PercPepVaccinated as
select
	dea.continent
	,dea.location
	,dea.date
	,dea.population
	,vac.new_vaccinations
	,sum(convert(bigint,vac.new_vaccinations))over (partition by dea.location order by dea.location, dea.date) as rollingPepVaccinated
from CovidProjects..CovidDeath dea
join CovidProjects..CovidVaccine vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null

--visualize 
select *
from PercPepVaccinated