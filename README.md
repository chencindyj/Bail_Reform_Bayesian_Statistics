# Bail_Reform_Bayesian_Statistics
Studying Biases in New York's Bail Reform Laws using Bayesian Statistics

## Abstract

New York is the only state in America that requires judges to set bail exclusively based on a defendant’s income and risk of failing to appear for court with no consideration for their perceived “dangerousness” since it can induce racial biases. Following New York’s controversial bail reform laws in January 2020 that relaxed rules around charges where bail could be set, July 2020 amendments reinstated stricter bail requirements. This analysis employs hierarchical Bayesian models to evaluate how bail amounts are set across the population of defendants and by judge on standard criteria such as criminal history and estimated income, as well as the effect of the July 2020 rule changes and judges’ racial biases. In studying population-level effects to bail amounts, the conditional effects of bail on various key variables, and investigating judge-specific behaviors in setting bail, clear and concerning racial discrepancies exist in how bail is set across a variety of metrics in New York state, which the July 2020 reforms do not alter. This raises concerns around racial equity and greater standardization needed in how judges set bail, especially as the recent midterm elections promise sweeping changes to current bail rules.


## Data
The raw data for this project can be found here: https://ww2.nycourts.gov/pretrial-release-data-33136

## What's Shared on Github
The code for cleaning and analyzing the data can be found in the /src folder
The visualization outputs can be found in the /outputs folder

## Want the Full Report?
Please message me on LinkedIn if you would like to read the full thesis with full methodology, assumptions, and results.

## Sample Findings
<img src="https://github.com/chencindyj/Bail_Reform_Bayesian_Statistics/blob/main/outputs/cond_effects_race_income.png"/>
<img src="https://github.com/chencindyj/Bail_Reform_Bayesian_Statistics/blob/main/outputs/income_bracket_race_judge.png" />
<img src="https://github.com/chencindyj/Bail_Reform_Bayesian_Statistics/blob/main/outputs/inexperienced_non_vfo.png"/>
<img src="https://github.com/chencindyj/Bail_Reform_Bayesian_Statistics/blob/main/outputs/cond_effects_race_age.png" />
