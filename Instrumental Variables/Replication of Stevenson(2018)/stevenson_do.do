******************************************************************************
* name: stevenson_do
* author: Debaleena Goswami
* description: Done as a part of the coding lab of Mixtape Sessions: Instrumental Variables (IV), instructed by Peter Hull (Groos Family Assistant Professor of Economics, Brown University)
* last updated: December 06, 2022
******************************************************************************

/* Replication of Stevenson (2018)
Paper title: Distortion of Justice: How the Inability to Pay Bail Affects Case Outcomes
Authors: Megan T. Stevenson
Published in: The Journal of Law, Economics, & Organization
*/

/*Variable Description:
1. lwage: Log of wages
2. educ: years of education
3. qob: Quarter of birth
4. yob: Year of Birth
*/

/*
Installation of packages used in this file:
cap ssc install ranktest
cap ssc install ivreg2

findit jive
*/

*Load the data
clear all
use "https://github.com/debalee101/Workshops/blob/172ae0f68946b40fea3048b7d895f63494617668/Instrumental%20Variables/Replication%20of%20Stevenson(2018)/stevenson.dta", replace

/*Question 1:
Limit the sample to Black defendants (black==1) and compute the "leniency" of a defendant's assigned judge. This is the average pretrial detention rate (indicated by jail3) by the eight judges (indicated by judge_pre_1-judge_pre_7). Generate an indicator for a defendant having an above-median lenient judge; call this variable more_lenient.  Estimate OLS and 2SLS regressions of the guilty plea outcome (guilt) on pretrial detention, with the latter instrumenting by more_lenient. Report your coefficients and robust standard errors. What do you find interesting here?
*/

*Limiting the sample to black defendents
keep if black == 1

*Compute leniency: generate a dummy IV
reg jail3 judge_pre_1-judge_pre_7
predict leniency, xb
sum leniency, d
generate more_lenient = (leniency>r(p50))

*OLS and 2SLS

*OLS
reg guilt jail3, r

/*OLS results:
 Estimate: -0.0189292
 Std. Error: 0.0022907
 */

*2SLS
ivreg2 guilt (jail3=more_lenient), r

/*2SLS results:
Estimate: 0.2861952
Std. error: 0.1056618
*/

/*Interpretation of the results:
The interesting thing is, the estimate increases by huge percentage points when an IV is used (though the estimate is noisy). This effect is pretty large, and this is something to worry about. One of the assumptions of the IV must have been violated, causing this to happen.
*/

*----------------------------------------------------------------------------*

/*Question 2:
Show that this instrument is correlated with a defendant having a prior felony charge (indicated by prior_felChar==1). What assumption of the LATE theorem appears to be violated, given such a correlation? Show that this correlation mostly goes away when controlling for date fixed effects (coded in bailDate). Re-run your OLS and 2SLS estimates with these controls and comment on the change.
*/

/* Check the balance on prior felonies
[Regress the balance variable on the instrument]*/
reg prior_felChar more_lenient, r

/*Interpretation:
Shows a pretty imbalanced result. People who are assigned a more lenient judge tend to have more prior felony charges. This explain why the prior 2SLS results were so big. We are comparing people who tend to have higher prior felony charges to people who are less likely to have prior felony charges. This is a VIOLATION of the as-good-as-random-assignemnt. The defendents who are assigned to a more lenient judge are observably different; thus they are likely to be unobservably different
*/

*Check that correlation mostly goes away, date fixed effects are absorbed, vce(robust) is a way to specify robust std errors. This addresses the prior issue.
reghdfe prior_felChar more_lenient, vce(robust) absorb(bailDate)



/* Re-running the OLS and 2SLS with controls*/

*OLS
reghdfe guilt jail3, absorb(bailDate) vce(robust)

*2SLS
ivreghdfe guilt (jail3=more_lenient), absorb(bailDate) r

/*Interpretation:
Thus, the large IV estimate we were getting before were a balancing failure, and it can be controlled by using fixed effects, which isolates the within-date variations in the instrument.
*/

*----------------------------------------------------------------------------*

/*Question 3:
Estimate the average untreated potential outcome for compliers in the controlled 2SLS specification, using the simple trick we saw in lecture. Compare this to the average outcome among jail3==0 defendants in the full population. Interpret the difference
*/
 
/* Estimate complier Y0 and compare to overall E[Y|D=0] */
gen Y_omD=guilt*(1-jail3)
gen omD=1-jail3
ivreghdfe Y_omD (omD=more_lenient), absorb(bailDate) r
summ guilt if jail3==0

/*Question 4:
Returning to the 2SLS specification without controls, replace the single more_lenient instrument with indicators for seven of the eight judges. Show that you get an identical 2SLS estimate and standard error if you instrument by the assigned judge leniency.
*/

/* 2SLS using all judges */
ivreghdfe guilt (jail3=judge_pre_1-judge_pre_7), r 
ivreghdfe guilt (jail3=leniency), r

/* Result: These two render exactly the same estimates.*/

*----------------------------------------------------------------------------*

/*Question 5:
Estimate the coefficient of interest by JIVE, without controls, using the judge indicators as seven instruments. Show that you get a (basically) identical 2SLS estimate and standard error if you instrument by the leave-out assigned judge leniency. That is, the average pretrial detention rate among other defendants assigned to each defendant's judge.
*/

/* JIVE using all judges */
jive guilt (jail3=judge_pre_1-judge_pre_7), r 
egen judge=group(judge_pre_*)
bys judge: egen num=count(jail3)
gen lo_leniency=(leniency*num-jail3)/(num-1)
ivreghdfe guilt (jail3=lo_leniency), r 

*----------------------------------------------------------------------------*

/*Question 6: Add date fixed effects to the above 2SLS and JIVE specifications, and comment on how the coefficients change. Finally, estimate the coefficient by Kolesar's UJIVE with controls and judge indicators as seven instruments. You should use the manyiv Stata command for this; unzip the manyiv-0.5.0.zip file included in this repository and put its contents in the folder you're running Stata from (and check out the help file). Comment on the different estimates.
*/

ivreghdfe guilt (jail3=judge_pre_1-judge_pre_7), absorb(bailDate) r 
manyiv guilt (jail3 = judge_pre_1-judge_pre_7), absorb(bailDate)