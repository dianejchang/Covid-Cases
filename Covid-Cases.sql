CREATE TABLE public."covid_deaths"(iso_code varchar(100),continent varchar(100),location varchar(100),date varchar(100),population float, total_cases float,new_cases float,
new_cases_smoothed float,total_deaths float,new_deaths float,new_deaths_smoothed float,total_cases_per_million float,new_cases_per_million float,
new_cases_smoothed_per_million float,total_deaths_per_million float,new_deaths_per_million float,new_deaths_smoothed_per_million float,
reproduction_rate float,icu_patients float,icu_patients_per_million float,hosp_patients float,hosp_patients_per_million float,
weekly_icu_admissions float,weekly_icu_admissions_per_million float,weekly_hosp_admissions float,weekly_hosp_admissions_per_million float)

CREATE TABLE public."covid_vaccinations"(iso_code varchar(100),continent varchar(100),location varchar(100),date varchar(100),new_tests  float,total_tests  float,
total_tests_per_thousand  float,new_tests_per_thousand  float,new_tests_smoothed  float,new_tests_smoothed_per_thousand float,
positive_rate  float,tests_per_case  float,tests_units varchar(100),total_vaccinations float,people_vaccinated float,
people_fully_vaccinated float,new_vaccinations float,new_vaccinations_smoothed float,total_vaccinations_per_hundred float,
people_vaccinated_per_hundred float,people_fully_vaccinated_per_hundred float,new_vaccinations_smoothed_per_million float,
stringency_index float,population_density float,median_age float,aged_65_older float,aged_70_older float,gdp_per_capita float,
extreme_poverty float,cardiovasc_death_rate float,diabetes_prevalence float,female_smokers float,male_smokers float,
handwashing_facilities float,hospital_beds_per_thousand float,life_expectancy float,human_development_index float)
;


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your Country
SELECT location, date, total_deaths, total_cases, (total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location LIKE '%States%'
ORDER BY 1, 3, 2
;


-- Looking at Total Cases vs Population
-- Shows what percentage of Population got Covid
SELECT location, date, total_cases, population, total_cases, (total_cases/population)*100 AS percent_of_population_infected
FROM covid_deaths
WHERE location LIKE '%States%'
ORDER BY 1, 3, 2
;


-- Looking at Countries with highest infection rate compared to Population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS percent_of_population_infected
FROM covid_deaths
--WHERE location LIKE '%States%'
GROUP BY location, population
ORDER BY percent_of_population_infected DESC
;


-- Showing Countries with highest death count per Population

SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC
;


-- Breakdown by continent
-- Continents with highest death count per Population
SELECT continent, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC
;


-- Global numbers
SELECT --date, 
	SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths,  SUM(new_deaths)/NULLIF(SUM(cast(new_cases as int)),0)*100 AS death_percentage
FROM covid_deaths
--WHERE location LIKE '%States%'
WHERE continent is NOT NULL
--GROUP BY date, total_cases, total_deaths
--HAVING SUM(new_cases) > 0
ORDER BY 2 DESC, 1
;


-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated, 
		((SUM(vac.new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location, dea.date))/dea.population) * 100 AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 2, 3
;


-- USING CTE to perform caluclation on Partitian by in previous query
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
)

SELECT *, (rolling_people_vaccinated/population) * 100
FROM PopvsVac
;


-- USING TEMP TABLE to perform Calculation on Partitian By in previous query
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMP TABLE PercentPopulationVaccinated
(
Continent varchar(100),
location varchar(100),
date varchar(100),
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
);


INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
;


SELECT *, (rolling_people_vaccinated/population) * 100
FROM PercentPopulationVaccinated
;


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
;
