# PTM
Aggregates and plots three-point benefit estimates and performs cost-effectiveness and complementarity analysis (in R) for Priority Threat Management

## /analysis
### /code/import.R
* reads individual expert estimate tables from */data/raw/benefits* subfolder and combines them into single */data/Estimates_clean.csv* file
* saves outputs into 2 tables: */data/Estimates_tidy.csv* (tidy version) and *data/Estimates_wide.csv*
* also counts the number of expert estimates for each strategy-group combination (*/data/Estimates_count_strategy.csv*)

### /code/plot.R
* uses */data/Estimates_tidy.csv* to create plots for expert review & feedback (plots not included in this archive)
  * boxplots of the best guess, lower, and upper estimates for each strategy, with separate plots for each ecological group
  * pointrange plots of each individual expert estimate for each strategy, with separate plots for each ecological group
* plots are saved in */figures* subfolder

### /code/aggregate.R
* uses */data/Estimates_std_wide.csv* to
  * calculate the average performance (probability of persistence) under the Baseline scenario (results/Estimates_avg_baseline.csv)
  * calculate benefit of each strategy, benefit = Strategy performance - Baseline performance, and average the benefit across experts (results/Estimates_avg_benefits.csv)
  * calculate the average performance (probability of persistence) under each strategy = vag benefits + avg baseline (results/Estimates_avg_persistence.csv)
  * weights aggregated benefit by number of species in each ecol group (results/Estimates_avg_benefits_groupwtd.csv)
  
### /code/plotAggregated.R
* can use either */results/Estimates_avg_performance.csv* (unweighted by feasibility) or */results/Expected_Performance.csv* (weighted by feasibility) to
  * create pointrange plots of (unweighted or weighted) averaged estimates of probability of persistence (y-axis) for each strategy (x-axis) and for each ecological group
  * plot is saved as */figures/Estimates_avg_persistence_plot.pdf*
  
### /code/optimizeManagement.R
* performs complementarity analysis on Best Guess estimates using consOpt package (https://github.com/ConservationDecisionsLab/consOpt)
  * outputs are a table (*results/ComplementarityBest.csv*) and a plot (*results/ComplementarityBest.pdf*)
  * also performs complementarity analysis using Low.csv and High.csv as benefit matrix (*results/ComplementarityLower.csv*, *results/ComplementarityLower.pdf*; *results/ComplementarityUpper.csv*, *results/ComplementarityUpper.pdf*)

### /code/calculateCEscore.R
* uses */results/Estimates_avg_benefits_groupwtd.csv* and a table of strategy Cost and Feasibility to calculate a cost-effectiveness (CE) score 
    CE = (Benefit*Feasibility)/Cost 
    and rank strategies by Benefit, Cost, and CE. Results are saved as *results/CostEffectiveness_Scores.csv*
* conducts uncertainty analysis on CE scores under cost uncertainty (*results/Uncertainty_CEScores_cost.csv*), 
and plots the results (*results/Uncrtn_Cost_10000R_Scores.pdf*, *results/Uncrtn_Cost_10000R_Ranks.pdf*)

## /data
### /raw/benefits/exp00.csv
* raw data files of expert estimates (*/raw/benefits/expXX.csv*, where XX are expert ID numbers) are not uploaded to maintain expert confidentiality. A blank table (*/raw/banefits/exp00.csv*) is provided instead for reference

### /raw/EcolGroupsList.csv
* table with ecological groups (columns) with group names as headers, and the common names of species/communities included in the group (rows)

### /SpecialCases.csv
* info on number of species in each group that individual experts based their estimates on, where this is less than the total number of species in the group
