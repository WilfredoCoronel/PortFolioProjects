-- Select Data that we are going to be using

SELECT country, date, total_cases, new_cases, total_deaths, population
FROM lastcoviddeaths
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths

SELECT country,date, total_cases, total_deaths,
    CASE
        WHEN total_cases = 0 THEN 0 
        ELSE (total_deaths::numeric / total_cases::numeric) * 100
    END AS DeathsPercentage
FROM lastcoviddeaths
WHERE country like '%States%'
ORDER BY country, date;

-- Looking at Total Cases vs Population
-- Show what percentage of population got Covid

SELECT country, date,population, total_cases,
    CASE
        WHEN total_cases = 0 THEN 0 
        ELSE (total_cases::numeric /population::numeric ) * 100
    END AS Infectionpercentage
FROM lastcoviddeaths
WHERE country like '%States%'
ORDER BY country, date;

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT country, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases::numeric/population::numeric)*100) AS PercentPopulationInfected
FROM lastcoviddeaths
WHERE country like '%States%'
GROUP BY  country, population
ORDER BY PercentPopulationInfected DESC;

-- Showing Countries with the Highest Death Count per Population

SELECT country, MAX(total_deaths) AS TotalDeathCount
FROM lastcoviddeaths
WHERE country NOT IN ('High income', 'Low income', 'Lower middle income', 'Upper middle income', 'World', 'Europe', ' Asia', 'North America', 'South America', 'European Union')
GROUP BY  country
ORDER BY TotalDeathCount DESC;


-- Showing Continent with the highest DeathCount

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM lastcoviddeaths
WHERE continent <>'0'
GROUP BY  continent
ORDER BY TotalDeathCount DESC;

-- GLobal Numbers

SELECT  
       SUM(new_cases) AS TotalNewCases, 
       SUM(new_deaths) AS TotalNewDeaths,
       CASE
           WHEN SUM(new_cases) = 0 THEN 0
           ELSE (SUM(new_deaths)::numeric / NULLIF(SUM(new_cases)::numeric, 0)) * 100
       END AS TotalNewDeathsPercentage
FROM lastcoviddeaths
--GROUP BY date
ORDER BY 1,2;

-- Joining both tables

SELECT *
FROM lastcoviddeaths dea
JOIN lastcovidvaccinations vac
	ON dea.country = vac.country
	AND dea.date = vac.date;
	
	
-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.country, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.country ORDER BY dea.country, dea.date) AS RollingPeopleVaccinated  
FROM lastcoviddeaths dea
JOIN lastcovidvaccinations vac
	ON dea.country = vac.country
	AND dea.date = vac.date
WHERE dea.continent <>'0'
ORDER BY 2,3;

--USE CTE

With PopsvsVac (Continent, Country, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.country, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.country ORDER BY dea.country, dea.date) AS RollingPeopleVaccinated  
FROM lastcoviddeaths dea
JOIN lastcovidvaccinations vac
	ON dea.country = vac.country
	AND dea.date = vac.date
WHERE dea.continent <>'0'
ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM PopsvsVac;

-- Temp Table

DROP TABLE if exists PercentPopulationVaccinated;
Create Table PercentPopulationVaccinated
(
Continent varchar(255),
Country varchar(255),
Date date,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT into PercentPopulationVaccinated
SELECT dea.continent, dea.country, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.country ORDER BY dea.country, dea.date) AS RollingPeopleVaccinated  
FROM lastcoviddeaths dea
JOIN lastcovidvaccinations vac
	ON dea.country = vac.country
	AND dea.date = vac.date
WHERE dea.continent <>'0'
ORDER BY 2,3;

SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM PercentPopulationVaccinated;

-- Creating View to store dara for later visualizations

CREATE VIEW PercentPeopleVaccinated2 AS
SELECT dea.continent, dea.country, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.country ORDER BY dea.country, dea.date) AS RollingPeopleVaccinated  
FROM lastcoviddeaths dea
JOIN lastcovidvaccinations vac
	ON dea.country = vac.country
	AND dea.date = vac.date
WHERE dea.continent <>'0'
ORDER BY 2,3;

-- Testing View
SELECT * 
FROM PercentPeopleVaccinated2