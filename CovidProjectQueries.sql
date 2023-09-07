
--SELECT *
--FROM CovidDeaths
--ORDER BY 3, 4

-- Select data we're going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2


-- Looking at total cases vs total deaths
SELECT location, CAST(date as date), total_cases, total_deaths, 
	(CAST(total_deaths AS numeric) / CAST(total_cases AS numeric)) as death_percentage
FROM CovidDeaths
ORDER BY 1,2 desc

-- Shows likelyhood of dying if you contract Covid in your country
SELECT location, CAST(date as date) as date, total_cases, total_deaths, 
	(CAST(total_deaths AS numeric) / CAST(total_cases AS numeric)) as death_percentage
FROM CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Looking at total cases vs population
-- Shows what % of the population contracted Covid
SELECT location, CAST(date as date) as date, total_cases, population, 
	(total_cases / population) as cases_percentage
FROM CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(CAST(total_cases AS int)) AS highest_infection_count, 
	MAX((total_cases / population)) as percent_population_infected
FROM CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- Showing countries with highest death count by population
SELECT location, MAX(CAST(total_deaths AS int)) as total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_death_count DESC

-- Showing continents with highest death count by population
SELECT continent, MAX(CAST(total_deaths AS int)) as total_death_count
FROM CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income'
GROUP BY continent
ORDER BY total_death_count DESC

-- Global numbers by date
SELECT CAST(date as date) as date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS int)) as total_deaths, 
	SUM(CAST(new_deaths AS int)) / SUM(new_cases) as death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income' AND new_cases > 0
GROUP BY date
ORDER BY 1,2

-- Global numbers
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS int)) as total_deaths, 
	SUM(CAST(new_deaths AS int)) / SUM(new_cases) as death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income' AND new_cases > 0
ORDER BY 1,2

-- Total population vs vaccinations
SELECT d.continent, d.location, d.date, population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingTotalVaccinated
FROM CovidDeaths d
JOIN CovidVaccinations v ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND new_vaccinations IS NOT NULL
ORDER BY 2,3

-- Use CTE
WITH PopulationVsVaccinations (Continent, Location, Date, Population, NewVaccinations, RollingTotalVaccinated)
AS
(
SELECT d.continent, d.location, d.date, population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingTotalVaccinated
FROM CovidDeaths d
JOIN CovidVaccinations v ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND new_vaccinations IS NOT NULL
)
SELECT *, (RollingTotalVaccinated / Population) as PercentVaccinated
FROM PopulationVsVaccinations
ORDER BY 2,3


-- Use Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population bigint,
NewVaccinations bigint,
RollingTotalVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingTotalVaccinated
FROM CovidDeaths d
JOIN CovidVaccinations v ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND new_vaccinations IS NOT NULL
ORDER BY 2,3

SELECT *, (RollingTotalVaccinated / Population) as PercentVaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2,3


-- Creating View to Store Data for Visualizations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT d.continent, d.location, d.date, population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingTotalVaccinated
FROM CovidDeaths d
JOIN CovidVaccinations v ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND new_vaccinations IS NOT NULL
--ORDER BY 2,3

