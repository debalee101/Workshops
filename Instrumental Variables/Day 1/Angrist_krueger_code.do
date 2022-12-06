******************************************************************************
* name: Angrist_krueger_do
* author: Debaleena Goswami
* description: Done as a part of the coding lab of Mixtape Sessions: Instrumental Variables (IV), instructed by Peter Hull (Groos Family Assistant Professor of Economics, Brown University)
* last updated: August 03, 2022
******************************************************************************

/* Replication of Angrist and Krueger (1991)
Paper title: Does Compulsory School Attendance Affect Schooling and Earnings?
Authors: Joshua D. Angrist and Alan B. Krueger
Published in: The Quarterly Journal of Economics
*/

/*Variable Description:
1. lwage: Log of wages
2. educ: years of education
3. qob: Quarter of birth
4. yob: Year of Birth
*/

/*
Installation of packages used in this file:
cap ssc install binscatter
cap ssc install ranktest
cap ssc install ivreg2
*/

//Data setup

use https://github.com/debalee101/Workshops/blob/c1b7950c7e311d7e4da9a5343d29d7dab2f35f72/Instrumental%20Variables/Day%201/Data/angrist_krueger.dta, replace
clear all
use angrist_krueger, clear
forval q=1/4 {
	gen qob_`q'=(qob==`q')
}

/* Question 1: OLS
Estimate the bivariate statistical relationship between log wages (lwage) and completed years of schooling (educ) using OLS. Report your coefficient and standard error. Visualize this relationship with a simple graph of your choice.
 */
reg lwage educ, r

/*
--Results:
1. Coefficient: 0.801112
2. Std error: 0.000394
*/

/*
--Visualizing the regression--
The binscatter command is useful when there are no controls, even when there are a large number of observations, binscatter gives the average of the dependent variable in bins of the independent variable

Note: always visualize the data, binscatter is a handy thing to go to
*/
binscatter lwage educ, xtitle("Years of Schooling") ytitle ("Log of Wages")

//---------------------------------------------------------------------------//

/*
Question2: Wald IV
	Estimate the returns to schooling using an indicator for individuals being born in the first quarter of the year as an instrument for completed years of schooling (and no other controls). Report your coefficient and standard error. What interesting things do you notice vs the answer in 1?

Outcome variable is lwage
Tratment is education
Instrument is qob_1r is for robustness
*/
ivreg2 lwage (educ=qob_1), r
/*
--Interpretation of output--

1. The coefficient goes down (0.0715133)
2. The sd. error gets much bigger (0.0219468)
	Because we're using a very narrow source of variation (not all of education, but just a quarter)
3. Kleibergen-Paap rk Wald F-Stat is the first-stage robust F-stat (64.487)
	It is the same result one will get when running `reg educ qob_1, r' and squaring the t-stat (t-stat will be -8.03 and the sqaure is 64.4809)
*/

//---------------------------------------------------------------------------//

/* Question 3: Decompose
	Estimate the average log wages and completed years of schooling for individuals who are and are not born in the first quarter. Check that you can get the 2SLS estimate in 2 manually from these numbers, suing the Wald IV formula
*/

foreach var of varlist lwage educ {
	sum `var' if qob_1==1
	sum `var' if qob_1==0
}

/*
--Results--
The difference in expected mean of lwage when the quarter of birth is zero and when it is not zero (5.148471-5.15745) ; divided by the difference in mean of educ when the quarter of birth is zero and when it is not zero (11.3996-11.52515) is equal to the coeff of the ivreg2 command.
*/

//---------------------------------------------------------------------------//

/* Question 4: Overidentification
	Add indicators for being born in the second and third quarter of the year as instruments to your specification in 2. Report your coefficient and robust standard error. What interesting things do you notice this vs. the answer in 1?
*/

ivreg2 lwage (educ=qob_1 qob_2 qob_3), r

/*
--Results interpretation--
1. The standard error goes down (0.016218)
	If we add more instruments, we're adding more things that could predict, i.e., picking up more variation in the first stage.
2. Hansen J Statistic (0.3084)
	The chi-sq P-val is above 0.05 so we can't reject the null that all the IV estimates are the same.
	If we reject the overid test, it will mean that some of the IVs are giving different results, which indicates that something is wrong.
*/
//---------------------------------------------------------------------------//
/* Question 5: Collapse by QOB
	Collapse your data into means of log wages and completed years of schooling by quarter of birth. Plot average log wages against average years of schooling. What is the slope of this relationship?
Are you surprised? Explain what we have shown here.
*/
preserve
//The "preserve" command allows us to come back to the same dataset after collapse//

collapse (mean) lwage educ, by(qob)
scatter lwage educ || lfit lwage educ
reg lwage educ, r
restore

/*
1. QOB_3 and QOB_4 tend to have higher education and higher earnings.
2. The slope is very similar to the overidentified coefficient.
	Because the overidentification test looks at exactly this relationship by the IV groups
*/

/*
Question 6: 2S in 2SLS
	Let's put the 2S in 2SLS. First add your overidentified specification in 4 indicators for an individual's year-of-birth as controls. Report your coefficient and robust standard error. Now obtain exactly the same coeeficient estimate in two steps, where the second step involves a regression on SLS fitted values. Comment on the difference in the standard errors and any other 2SLS diagnostics.
*/
ivreg2 lwage (educ=qob_1 qob_2 qob_3) i.yob, r

reg educ qob_1 qob_2 qob_3 i.yob
predict educ_hat i.yob, r
reg lwage educ_hat i.yob, r

/*
1. The 
*/

/* Question 7: Ok, now let's get crazy. Add to the previous 2SLS specification interactions of the three quarter-of-birth indicators with all of the year-of-birth indicators as instruments (keeping the year-of-birth "main effects" as controls). Report your coefficient and standard error. How do these compare with the coefficients and standard errors in part 1 and 2? Comment on any other 2SLS diagnostics and how they affect how you feel about this estimate of the returns to schooling.
*/
ivreg2 lwage (educ=qob_1#yob qob_2#yob qob_3#yob) i.yob, r

