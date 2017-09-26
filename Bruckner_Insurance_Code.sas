* Andrea Bruckner
  PREDICT 411, Sec 55
  Spring 2016
  Unit 02: Insurance
;

********************************************************************;
* Preliminary Steps--All Models;
********************************************************************;

* Access library where data sets are stored;

%let PATH = /folders/myfolders/PREDICT_411/Insurance;
%let NAME = LOGIT;
%let LIB = &NAME..;

libname &NAME. "&PATH.";
%let INFILE = &LIB.LOGIT_INSURANCE;

proc contents data=&INFILE.; run;

proc print data=&INFILE.(obs=10);
run;

********************************************************************;
* Data Exploration/EDA--All Models;
********************************************************************;

* EDA for numeric variables;
proc means data=&INFILE. min max mean median n nmiss;
run;

proc freq data=&INFILE.;
table TARGET_FLAG;
run;

* EDA visualization of numeric variables;
data edafile;
set &INFILE.;
drop INDEX;
run;

proc univariate data=edafile plot;
run;

* A lot of the histograms' distributions look very similar for TARGET_FLAG = 0 vs TARGET_FLAG = 1;
proc univariate data=edafile;
class TARGET_FLAG;
var _numeric_;
histogram;
run;

* EDA for character variables;
proc freq data=&INFILE.;
table _character_ /missing; * Only JOB has missing values: 526/8161;
run;

* Cross Tabulation with Character Variables;
*proc freq data=&INFILE.;
*tables TARGET_FLAG * CAR_TYPE;
*tables TARGET_FLAG * CAR_USE;
*tables TARGET_FLAG * EDUCATION;
*tables TARGET_FLAG * JOB / missing;
*tables TARGET_FLAG * MSTATUS;
*tables TARGET_FLAG * PARENT1;
*tables TARGET_FLAG * RED_CAR;
*tables TARGET_FLAG * REVOKED;
*tables TARGET_FLAG * SEX;
*tables TARGET_FLAG * URBANICITY;
*run;

* Shorter way of doing the above;
proc freq data=&INFILE.;
table TARGET_FLAG * (_character_) /missing;
run;

* EDA visualization of character variables;
* Alternative to vbar--figure out how to put datalabel on bars;
proc freq data=edafile;
table (_character_) / plots=freqplot missing;
run;

proc freq data=edafile;
table KIDSDRIV / plots=freqplot missing;
run;

proc freq data=edafile;
table HOMEKIDS / plots=freqplot missing;
run;

* Preparing the numeric data to create a correlation matrix with just crashes;
data crashed;
set &INFILE.;
if TARGET_FLAG > 0;
drop TARGET_FLAG;
drop INDEX;
run;

proc print data=crashed(obs=10);
run;

* Correlation matrix--doesn't reveal any variables that strongly correlate with TARGET AMT;
ods graphics on;
proc corr data=crashed plots=matrix; * Too much info to include scatterplots;
var
TARGET_AMT
AGE
BLUEBOOK
CAR_AGE
CLM_FREQ
HOMEKIDS
HOME_VAL
INCOME
KIDSDRIV
MVR_PTS
OLDCLAIM
TIF
TRAVTIME
YOJ
;
run;
ods graphics off;

********************************************************************;
* Data Preparation--Model 1;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;
title "Model 1";
IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;
run;

***
Data Preparation Checks
***

* Make sure all imputations worked by seeing that everything has 8161 records--YEP;
proc print data=tempfile (obs=10);
run;

proc means data=tempfile min mean median n nmiss;
run;

* Can see the distribution of ages in the bins;
proc means data=tempfile min max mean;
class AGE_BIN;
var IMP_AGE;
run;

proc freq data=tempfile;
table AGE_BIN / plots=freqplot;
run;

* Alternative to the code above, but it doesn't look good and is misleading;
*proc univariate data=tempfile plot;
*var IMP_AGE;
*histogram / midpoints= 20 to 80 by 10; * 16 to 81 (min and max AGE) by 5 looked better but was misleading;
*run;

* Make sure imputation corrected missing jobs;
proc freq data=tempfile;
table IMP_JOB / missing;
run;

* Can compare freq tables to see how many of each job was added;
proc freq data=tempfile;
table JOB IMP_JOB;
run;

* Make sure imputation corrected missing home values;
proc means data=tempfile n min max mean;
class IMP_JOB;
var IMP_HOME_VAL;
run;

* Summary of changes for imputed numeric variables;
proc means data=tempfile min mean median n nmiss;
run;

* Visualization of imputed numeric variables;
* Will use these to create caps and bins in Model 2;
proc univariate data=tempfile plot;
var 
	IMP_AGE
	IMP_YOJ
	IMP_INCOME
	IMP_HOME_VAL
	TRAVTIME
	BLUEBOOK
	TIF
	OLDCLAIM
	CLM_FREQ
	MVR_PTS
	IMP_CAR_AGE
	;
run;

proc univariate data=tempfile;
class TARGET_FLAG;
var 
	IMP_AGE
	IMP_YOJ
	IMP_INCOME
	IMP_HOME_VAL
	TRAVTIME
	BLUEBOOK
	TIF
	OLDCLAIM
	CLM_FREQ
	MVR_PTS
	IMP_CAR_AGE
	;
histogram;
run;

**********
In order to get some of the values I used in the Data Preparation/Imputation above,
I used the following code. I didn't paste this code above the Data Preparation/Imputation
code above in the EDA section becuase I developed my imputation process piece by piece.
That is, I introduced an IMP_ in the tempfile above then used that IMP_ to determine other
IMP_'s. Because the IMP_ does not exist prior to the tempfile data step, I have to keep this
code after the tempfile data step/data preparation step has been done;
**********

* Performed this to determine IMP_YOJ;
* I looked at the mean of YOJ given the AGE_BIN and rounded to the nearest whole number;
proc means data=tempfile n nmiss min max mean;
class AGE_BIN;
var YOJ;
run;

* Performed this to determine IMP_INCOME;
* I set the IMP_INCOME to the mean for each job and used mean INCOME for data missing JOB;
proc means data=tempfile n nmiss min max mean;
class JOB / missing;
var INCOME;
run;

* Performed this to determine IMP_JOB and used "z_Blue Collar" for data missing INCOME since most jobs are blue collar, and the average income matches with the mean income for this job;
* z_Blue Collar is most frequent job, so imputed this for missing jobs that were missing the INCOME since the imputed income = approx the average income for z_Blue Collar;
proc univariate data=tempfile;
class JOB;
var IMP_INCOME;
histogram;
run;

* Performed this to determine IMP_HOME_VAL and used mean HOME_VAL per IMP_JOB;
proc means data=tempfile n nmiss min max mean;
class IMP_JOB;
var HOME_VAL;
run;

********************************************************************;
* Model Creation--Model 1;
********************************************************************;

* Variable Selection;

proc logistic data=tempfile;
class 				CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					RED_CAR
					REVOKED
					SEX
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					RED_CAR
					REVOKED
					SEX
					URBANICITY
					
					IMP_AGE
					BLUEBOOK
					IMP_CAR_AGE
					CLM_FREQ
					HOMEKIDS
					IMP_HOME_VAL
					IMP_INCOME
					KIDSDRIV
					MVR_PTS
					OLDCLAIM
					TIF
					TRAVTIME
					IMP_YOJ
					/selection=stepwise
					;
run;

proc logistic data=tempfile  plot(only)=(roc(ID=prob));
class 				CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					REVOKED
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					REVOKED
					URBANICITY
					BLUEBOOK
					CLM_FREQ
					IMP_HOME_VAL
					IMP_INCOME
					KIDSDRIV
					MVR_PTS
					OLDCLAIM
					TIF
					TRAVTIME
					
					/roceps=0.1
					;
score out=SCORED_FILE;
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE to examine probability--Model 1;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE;

* Making sure the SCORE_ME file has all 8161 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 1";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;


 YHAT = -1.3968 
+ (CAR_TYPE in ("Minivan")) * -0.714
+ (CAR_TYPE in ("Panel Truck")) * -0.1013
+ (CAR_TYPE in ("Pickup")) * -0.1779
+ (CAR_TYPE in ("Sports Car")) * 0.2551
+ (CAR_TYPE in ("Van")) * -0.0781
+ (CAR_USE in ("Commercial")) * 0.8061
+ (EDUCATION in ("<High School")) * 0.00687
+ (EDUCATION in ("Bachelors")) * -0.4219
+ (EDUCATION in ("Masters")) * -0.3762
+ (EDUCATION in ("PhD")) * -0.2939
+ (IMP_JOB in ("Clerical")) * 0.1463
+ (IMP_JOB in ("Doctor")) * -0.4179
+ (IMP_JOB in ("Home Maker")) * 0.0324
+ (IMP_JOB in ("Lawyer")) * -0.09
+ (IMP_JOB in ("Manager")) * -0.7489
+ (IMP_JOB in ("Professional")) * -0.0766
+ (IMP_JOB in ("Student")) * -0.0161
+ (MSTATUS in ("Yes")) * -0.471
+ (PARENT1 in ("No")) * -0.4616
+ (REVOKED in ("No")) * -0.8952
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.3863
+ BLUEBOOK * -0.00002
+ CLM_FREQ * 0.1973
+ IMP_HOME_VAL * -1.34E-06
+ IMP_INCOME * -3.25E-06
+ KIDSDRIV * 0.4172
+ MVR_PTS * 0.1145
+ OLDCLAIM * -0.00001
+ TIF * -0.0556
+ TRAVTIME * 0.0145
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp( YHAT ) / ( 1+exp( YHAT ));

run;

proc print data=DEPLOYFILE(obs=10);
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE_TEST--Model 1;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE_TEST;

* Making sure the SCORE_ME file has all 2141 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 1";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -1.3968 
+ (CAR_TYPE in ("Minivan")) * -0.714
+ (CAR_TYPE in ("Panel Truck")) * -0.1013
+ (CAR_TYPE in ("Pickup")) * -0.1779
+ (CAR_TYPE in ("Sports Car")) * 0.2551
+ (CAR_TYPE in ("Van")) * -0.0781
+ (CAR_USE in ("Commercial")) * 0.8061
+ (EDUCATION in ("<High School")) * 0.00687
+ (EDUCATION in ("Bachelors")) * -0.4219
+ (EDUCATION in ("Masters")) * -0.3762
+ (EDUCATION in ("PhD")) * -0.2939
+ (IMP_JOB in ("Clerical")) * 0.1463
+ (IMP_JOB in ("Doctor")) * -0.4179
+ (IMP_JOB in ("Home Maker")) * 0.0324
+ (IMP_JOB in ("Lawyer")) * -0.09
+ (IMP_JOB in ("Manager")) * -0.7489
+ (IMP_JOB in ("Professional")) * -0.0766
+ (IMP_JOB in ("Student")) * -0.0161
+ (MSTATUS in ("Yes")) * -0.471
+ (PARENT1 in ("No")) * -0.4616
+ (REVOKED in ("No")) * -0.8952
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.3863
+ BLUEBOOK * -0.00002
+ CLM_FREQ * 0.1973
+ IMP_HOME_VAL * -1.34E-06
+ IMP_INCOME * -3.25E-06
+ KIDSDRIV * 0.4172
+ MVR_PTS * 0.1145
+ OLDCLAIM * -0.00001
+ TIF * -0.0556
+ TRAVTIME * 0.0145
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp(YHAT)/(1+exp(YHAT));

keep INDEX P_TARGET_FLAG;

run;

proc means data=DEPLOYFILE;
var P_TARGET_FLAG;
run;

proc print data=DEPLOYFILE(obs=10);
run;

********************************************************************;
* Exporting the Scored Model--Model 1;
********************************************************************;

* Remove the comments to activate + change csv file name for each model;
*proc export data=DEPLOYFILE
   outfile='/folders/myfolders/PREDICT_411/Insurance/insurance01a.csv'
   dbms=csv
   replace;
*run;

********************************************************************;
* Data Preparation--Model 2;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;

title "Model 2";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;
run;

***
Data Preparation Checks
***

* Exported csv of dataset to make decision tree in R;
*proc export data=tempfile
   outfile='/folders/myfolders/PREDICT_411/Insurance/model2a.csv'
   dbms=csv
   replace;
*run;

* Make sure all imputations worked by seeing that everything has 8161 records--YEP;
proc print data=tempfile (obs=10);
run;

proc means data=tempfile min max mean median n nmiss;
run;

proc freq data=tempfile;
table OLDCLAIM_BIN / plots=freqplot;
run;

********************************************************************;
* Model Creation--Model 2;
********************************************************************;

* Variable Selection;

proc logistic data=tempfile;
class 				CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					RED_CAR
					REVOKED
					SEX
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					RED_CAR
					REVOKED
					SEX
					URBANICITY
					
					IMP_AGE
					IMP_BLUEBOOK
					IMP_CAR_AGE
					CLM_FREQ
					HOMEKIDS
					IMP_HOME_VAL
					IMP_INCOME
					KIDSDRIV
					MVR_PTS
					OLDCLAIM
					TIF
					IMP_TRAVTIME
					IMP_YOJ
					/selection=stepwise
					; *I tried OLDCLAIM_BIN but it was selected only when OLDCLAIM was included--don't want 2 OLDCLAIM variables;
run;

* adjrsq aic bic mse cp vif selection = stepwise slentry =0.10 slstay=0.10;

proc logistic data=tempfile  plot(only)=(roc(ID=prob)) outest = est;
class 				CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					REVOKED
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					REVOKED
					URBANICITY
					
					IMP_BLUEBOOK
					CLM_FREQ
					IMP_HOME_VAL
					IMP_INCOME
					KIDSDRIV
					MVR_PTS
					OLDCLAIM
					TIF
					IMP_TRAVTIME
					/roceps=0.1
					;
score out=SCORED_FILE;
run;

proc print data=SCORED_FILE(obs=10);
run;

proc print data=est(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE to examine probability--Model 2;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE;

* Making sure the SCORE_ME file has all 8161 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 2";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -1.3892 
+ (CAR_TYPE in ("Minivan")) * -0.7099
+ (CAR_TYPE in ("Panel Truck")) * -0.0827
+ (CAR_TYPE in ("Pickup")) * -0.1766
+ (CAR_TYPE in ("Sports Car")) * 0.2555
+ (CAR_TYPE in ("Van")) * -0.0646
+ (CAR_USE in ("Commercial")) * 0.8075
+ (EDUCATION in ("<High School")) * 0.00557
+ (EDUCATION in ("Bachelors")) * -0.4198
+ (EDUCATION in ("Masters")) * -0.376
+ (EDUCATION in ("PhD")) * -0.2978
+ (IMP_JOB in ("Clerical")) * 0.1437
+ (IMP_JOB in ("Doctor")) * -0.418
+ (IMP_JOB in ("Home Maker")) * 0.0287
+ (IMP_JOB in ("Lawyer")) * -0.0855
+ (IMP_JOB in ("Manager")) * -0.7469
+ (IMP_JOB in ("Professional")) * -0.0752
+ (IMP_JOB in ("Student")) * -0.0278
+ (MSTATUS in ("Yes")) * -0.4603
+ (PARENT1 in ("No")) * -0.463
+ (REVOKED in ("No")) * -0.8943
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.3843
+ IMP_BLUEBOOK * -0.00002
+ CLM_FREQ * 0.1968
+ IMP_HOME_VAL * -1.43E-06
+ IMP_INCOME * -3.18E-06
+ KIDSDRIV * 0.4182
+ MVR_PTS * 0.1143
+ OLDCLAIM * -0.00001
+ TIF * -0.0556
+ IMP_TRAVTIME * 0.0151
;


if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp( YHAT ) / ( 1+exp( YHAT ));

run;

proc print data=DEPLOYFILE(obs=10);
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE_TEST--Model 2;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE_TEST;

* Making sure the SCORE_ME file has all 2141 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 2";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -1.3892 
+ (CAR_TYPE in ("Minivan")) * -0.7099
+ (CAR_TYPE in ("Panel Truck")) * -0.0827
+ (CAR_TYPE in ("Pickup")) * -0.1766
+ (CAR_TYPE in ("Sports Car")) * 0.2555
+ (CAR_TYPE in ("Van")) * -0.0646
+ (CAR_USE in ("Commercial")) * 0.8075
+ (EDUCATION in ("<High School")) * 0.00557
+ (EDUCATION in ("Bachelors")) * -0.4198
+ (EDUCATION in ("Masters")) * -0.376
+ (EDUCATION in ("PhD")) * -0.2978
+ (IMP_JOB in ("Clerical")) * 0.1437
+ (IMP_JOB in ("Doctor")) * -0.418
+ (IMP_JOB in ("Home Maker")) * 0.0287
+ (IMP_JOB in ("Lawyer")) * -0.0855
+ (IMP_JOB in ("Manager")) * -0.7469
+ (IMP_JOB in ("Professional")) * -0.0752
+ (IMP_JOB in ("Student")) * -0.0278
+ (MSTATUS in ("Yes")) * -0.4603
+ (PARENT1 in ("No")) * -0.463
+ (REVOKED in ("No")) * -0.8943
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.3843
+ IMP_BLUEBOOK * -0.00002
+ CLM_FREQ * 0.1968
+ IMP_HOME_VAL * -1.43E-06
+ IMP_INCOME * -3.18E-06
+ KIDSDRIV * 0.4182
+ MVR_PTS * 0.1143
+ OLDCLAIM * -0.00001
+ TIF * -0.0556
+ IMP_TRAVTIME * 0.0151
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp(YHAT)/(1+exp(YHAT));

keep INDEX P_TARGET_FLAG;

run;

proc means data=DEPLOYFILE;
var P_TARGET_FLAG;
run;

proc print data=DEPLOYFILE(obs=10);
run;

********************************************************************;
* Exporting the Scored Model--Model 2;
********************************************************************;

* Remove the comments to activate + change csv file name for each model;
*proc export data=DEPLOYFILE
   outfile='/folders/myfolders/PREDICT_411/Insurance/insurance02a.csv'
   dbms=csv
   replace;
*run;

********************************************************************;
* Data Preparation--Model 3;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;

title "Model 3";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 750455 then IMP_HOME_VAL = 750455; * removed just the highest value;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 100 then IMP_TRAVTIME = 100; *eyeballed from proc univariate histogram;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 55000 then IMP_BLUEBOOK = 55000; *eyeballed from proc univariate histogram;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;
run;

***
Data Preparation Checks
***

* Make sure all imputations worked by seeing that everything has 8161 records--YEP;
proc print data=tempfile (obs=10);
run;

proc means data=tempfile min max mean median n nmiss;
run;

********************************************************************;
* Model Creation--Model 3;
********************************************************************;

* Variable Selection;

proc logistic data=tempfile;
class 				CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					RED_CAR
					REVOKED
					SEX
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					RED_CAR
					REVOKED
					SEX
					URBANICITY
					
					IMP_AGE
					IMP_BLUEBOOK
					IMP_CAR_AGE
					CLM_FREQ
					HOMEKIDS
					IMP_HOME_VAL
					IMP_INCOME
					KIDSDRIV
					MVR_PTS
					OLDCLAIM
					TIF
					IMP_TRAVTIME
					IMP_YOJ
					/selection=stepwise
					;
run;

proc logistic data=tempfile  plot(only)=(roc(ID=prob));
class 				CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					REVOKED
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					REVOKED
					URBANICITY
					
					IMP_BLUEBOOK
					CLM_FREQ
					IMP_HOME_VAL
					IMP_INCOME
					KIDSDRIV
					MVR_PTS
					OLDCLAIM
					TIF
					IMP_TRAVTIME
					/roceps=0.1
					;
score out=SCORED_FILE;
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE to examine probability--Model 3;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE;

* Making sure the SCORE_ME file has all 8161 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 2";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 750455 then IMP_HOME_VAL = 750455; * removed just the highest value;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 100 then IMP_TRAVTIME = 100; *eyeballed from proc univariate histogram;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 55000 then IMP_BLUEBOOK = 55000; *eyeballed from proc univariate histogram;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -1.3986 
+ (CAR_TYPE in ("Minivan")) * -0.7132
+ (CAR_TYPE in ("Panel Truck")) * -0.0987
+ (CAR_TYPE in ("Pickup")) * -0.1773
+ (CAR_TYPE in ("Sports Car")) * 0.2554
+ (CAR_TYPE in ("Van")) * -0.0764
+ (CAR_USE in ("Commercial")) * 0.8067
+ (EDUCATION in ("<High School")) * 0.00694
+ (EDUCATION in ("Bachelors")) * -0.422
+ (EDUCATION in ("Masters")) * -0.3768
+ (EDUCATION in ("PhD")) * -0.2948
+ (IMP_JOB in ("Clerical")) * 0.1464
+ (IMP_JOB in ("Doctor")) * -0.417
+ (IMP_JOB in ("Home Maker")) * 0.0338
+ (IMP_JOB in ("Lawyer")) * -0.0888
+ (IMP_JOB in ("Manager")) * -0.7479
+ (IMP_JOB in ("Professional")) * -0.0762
+ (IMP_JOB in ("Student")) * -0.0155
+ (MSTATUS in ("Yes")) * -0.4708
+ (PARENT1 in ("No")) * -0.4617
+ (REVOKED in ("No")) * -0.8953
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.3854
+ IMP_BLUEBOOK * -0.00002
+ CLM_FREQ * 0.1972
+ IMP_HOME_VAL * -1.34E-06
+ IMP_INCOME * -3.24E-06
+ KIDSDRIV * 0.4171
+ MVR_PTS * 0.1146
+ OLDCLAIM * -0.00001
+ TIF * -0.0556
+ IMP_TRAVTIME * 0.0146
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp( YHAT ) / ( 1+exp( YHAT ));

run;

proc print data=DEPLOYFILE(obs=10);
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE_TEST--Model 3;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE_TEST;

* Making sure the SCORE_ME file has all 2141 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 3";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 750455 then IMP_HOME_VAL = 750455; * removed just the highest value;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 100 then IMP_TRAVTIME = 100; *eyeballed from proc univariate histogram;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 55000 then IMP_BLUEBOOK = 55000; *eyeballed from proc univariate histogram;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -1.3986 
+ (CAR_TYPE in ("Minivan")) * -0.7132
+ (CAR_TYPE in ("Panel Truck")) * -0.0987
+ (CAR_TYPE in ("Pickup")) * -0.1773
+ (CAR_TYPE in ("Sports Car")) * 0.2554
+ (CAR_TYPE in ("Van")) * -0.0764
+ (CAR_USE in ("Commercial")) * 0.8067
+ (EDUCATION in ("<High School")) * 0.00694
+ (EDUCATION in ("Bachelors")) * -0.422
+ (EDUCATION in ("Masters")) * -0.3768
+ (EDUCATION in ("PhD")) * -0.2948
+ (IMP_JOB in ("Clerical")) * 0.1464
+ (IMP_JOB in ("Doctor")) * -0.417
+ (IMP_JOB in ("Home Maker")) * 0.0338
+ (IMP_JOB in ("Lawyer")) * -0.0888
+ (IMP_JOB in ("Manager")) * -0.7479
+ (IMP_JOB in ("Professional")) * -0.0762
+ (IMP_JOB in ("Student")) * -0.0155
+ (MSTATUS in ("Yes")) * -0.4708
+ (PARENT1 in ("No")) * -0.4617
+ (REVOKED in ("No")) * -0.8953
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.3854
+ IMP_BLUEBOOK * -0.00002
+ CLM_FREQ * 0.1972
+ IMP_HOME_VAL * -1.34E-06
+ IMP_INCOME * -3.24E-06
+ KIDSDRIV * 0.4171
+ MVR_PTS * 0.1146
+ OLDCLAIM * -0.00001
+ TIF * -0.0556
+ IMP_TRAVTIME * 0.0146
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp(YHAT)/(1+exp(YHAT));

keep INDEX P_TARGET_FLAG;

run;

proc means data=DEPLOYFILE;
var P_TARGET_FLAG;
run;

proc print data=DEPLOYFILE(obs=10);
run;

********************************************************************;
* Exporting the Scored Model--Model 3;
********************************************************************;

* Remove the comments to activate + change csv file name for each model;
*proc export data=DEPLOYFILE
   outfile='/folders/myfolders/PREDICT_411/Insurance/insurance03a.csv'
   dbms=csv
   replace;
*run;

********************************************************************;
* Data Preparation--Model 4;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;

title "Model 2";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0 < OLDCLAIM <= 5000 then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 then OLDCLAIM_BIN = 2;
if OLDCLAIM > 10000 then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;
run;

***
Data Preparation Checks
***

* Make sure all imputations worked by seeing that everything has 8161 records--YEP;
proc print data=tempfile (obs=10);
run;

proc means data=tempfile min max mean median n nmiss;
run;

proc freq data=tempfile;
table OLDCLAIM_BIN / plots=freqplot;
run;

********************************************************************;
* Model Creation--Model 4;
********************************************************************;

* Variable Selection;

proc logistic data=tempfile;
class 				CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					RED_CAR
					REVOKED
					SEX
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					RED_CAR
					REVOKED
					SEX
					URBANICITY
					
					IMP_AGE
					IMP_BLUEBOOK
					IMP_CAR_AGE
					CLM_FREQ
					HOMEKIDS
					IMP_HOME_VAL
					IMP_INCOME
					KIDSDRIV
					MVR_PTS
					OLDCLAIM
					TIF
					IMP_TRAVTIME
					IMP_YOJ
					/ selection = stepwise slentry =0.10 slstay=0.10;
					; *I tried OLDCLAIM_BIN but it was selected only when OLDCLAIM was included--don't want 2 OLDCLAIM variables;
run;

proc logistic data=tempfile  plot(only)=(roc(ID=prob));
class 				CAR_TYPE
					CAR_USE
					IMP_JOB
					PARENT1
					REVOKED
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE
					CAR_USE
					IMP_JOB
					PARENT1
					REVOKED
					URBANICITY
					
					CLM_FREQ
					IMP_HOME_VAL
					IMP_INCOME
					KIDSDRIV
					MVR_PTS
					OLDCLAIM
					TIF
					IMP_TRAVTIME
					/roceps=0.1
					;
score out=SCORED_FILE;
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE to examine probability--Model 4;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE;

* Making sure the SCORE_ME file has all 8161 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 4";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0 < OLDCLAIM <= 5000 then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 then OLDCLAIM_BIN = 2;
if OLDCLAIM > 10000 then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -1.6041
+ (CAR_TYPE in ("Minivan")) * -0.7771
+ (CAR_TYPE in ("Panel Truck")) * -0.4029
+ (CAR_TYPE in ("Pickup")) * -0.1606
+ (CAR_TYPE in ("Sports Car")) * 0.2482
+ (CAR_TYPE in ("Van")) * -0.2253
+ (CAR_USE in ("Commercial")) * 0.7525
+ (IMP_JOB in ("Clerical")) * 0.1509
+ (IMP_JOB in ("Doctor")) * -0.4762
+ (IMP_JOB in ("Home Maker")) * -0.1169
+ (IMP_JOB in ("Lawyer")) * -0.2937
+ (IMP_JOB in ("Manager")) * -0.9183
+ (IMP_JOB in ("Professional")) * -0.2491
+ (IMP_JOB in ("Student")) * -0.0999
+ (PARENT1 in ("No")) * -0.6927
+ (REVOKED in ("No")) * -0.894
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.3196
+ CLM_FREQ * 0.2017
+ IMP_HOME_VAL * -2.49E-06
+ IMP_INCOME * -3.95E-06
+ KIDSDRIV * 0.3688
+ MVR_PTS * 0.1128
+ OLDCLAIM * -0.00001
+ TIF * -0.0546
+ IMP_TRAVTIME * 0.0145
;


if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp( YHAT ) / ( 1+exp( YHAT ));

run;

proc print data=DEPLOYFILE(obs=10);
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE_TEST--Model 4;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE_TEST;

* Making sure the SCORE_ME file has all 2141 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 4";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0 < OLDCLAIM <= 5000 then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 then OLDCLAIM_BIN = 2;
if OLDCLAIM > 10000 then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -1.6041
+ (CAR_TYPE in ("Minivan")) * -0.7771
+ (CAR_TYPE in ("Panel Truck")) * -0.4029
+ (CAR_TYPE in ("Pickup")) * -0.1606
+ (CAR_TYPE in ("Sports Car")) * 0.2482
+ (CAR_TYPE in ("Van")) * -0.2253
+ (CAR_USE in ("Commercial")) * 0.7525
+ (IMP_JOB in ("Clerical")) * 0.1509
+ (IMP_JOB in ("Doctor")) * -0.4762
+ (IMP_JOB in ("Home Maker")) * -0.1169
+ (IMP_JOB in ("Lawyer")) * -0.2937
+ (IMP_JOB in ("Manager")) * -0.9183
+ (IMP_JOB in ("Professional")) * -0.2491
+ (IMP_JOB in ("Student")) * -0.0999
+ (PARENT1 in ("No")) * -0.6927
+ (REVOKED in ("No")) * -0.894
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.3196
+ CLM_FREQ * 0.2017
+ IMP_HOME_VAL * -2.49E-06
+ IMP_INCOME * -3.95E-06
+ KIDSDRIV * 0.3688
+ MVR_PTS * 0.1128
+ OLDCLAIM * -0.00001
+ TIF * -0.0546
+ IMP_TRAVTIME * 0.0145
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp(YHAT)/(1+exp(YHAT));

keep INDEX P_TARGET_FLAG;

run;

proc means data=DEPLOYFILE;
var P_TARGET_FLAG;
run;

proc print data=DEPLOYFILE(obs=10);
run;

********************************************************************;
* Exporting the Scored Model--Model 4;
********************************************************************;

* Remove the comments to activate + change csv file name for each model;
*proc export data=DEPLOYFILE
   outfile='/folders/myfolders/PREDICT_411/Insurance/insurance04.csv'
   dbms=csv
   replace;
*run;

********************************************************************;
* Data Preparation--Model 5;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;

title "Model 5";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;
run;

***
Data Preparation Checks
***

* Make sure all imputations worked by seeing that everything has 8161 records--YEP;
proc print data=tempfile (obs=10);
run;

proc means data=tempfile min max mean median n nmiss;
run;

********************************************************************;
* Model Creation--Model 5;
********************************************************************;

* Variable Selection = decision tree in R;

* Model;
proc logistic data=tempfile  plot(only)=(roc(ID=prob));
class 				IMP_JOB
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					IMP_JOB
					URBANICITY
					OLDCLAIM
					/roceps=0.1
					;
score out=SCORED_FILE;
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE to examine probability--Model 5;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE;

* Making sure the SCORE_ME file has all 8161 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 5";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -2.5621 
+ (IMP_JOB in ("Clerical")) * -0.0898
+ (IMP_JOB in ("Doctor")) * -1.3611
+ (IMP_JOB in ("Home Maker")) * -0.1227
+ (IMP_JOB in ("Lawyer")) * -1.0455
+ (IMP_JOB in ("Manager")) * -1.4611
+ (IMP_JOB in ("Professional")) * -0.7231
+ (IMP_JOB in ("Student")) * 0.3445
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.1726
+ OLDCLAIM * 0.000021
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp( YHAT ) / ( 1+exp( YHAT ));

run;

proc print data=DEPLOYFILE(obs=10);
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE_TEST--Model 5;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE_TEST;

* Making sure the SCORE_ME file has all 2141 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 5";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -2.5621 
+ (IMP_JOB in ("Clerical")) * -0.0898
+ (IMP_JOB in ("Doctor")) * -1.3611
+ (IMP_JOB in ("Home Maker")) * -0.1227
+ (IMP_JOB in ("Lawyer")) * -1.0455
+ (IMP_JOB in ("Manager")) * -1.4611
+ (IMP_JOB in ("Professional")) * -0.7231
+ (IMP_JOB in ("Student")) * 0.3445
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.1726
+ OLDCLAIM * 0.000021
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp(YHAT)/(1+exp(YHAT));

keep INDEX P_TARGET_FLAG;

run;

proc means data=DEPLOYFILE;
var P_TARGET_FLAG;
run;

proc print data=DEPLOYFILE(obs=10);
run;

********************************************************************;
* Exporting the Scored Model--Model 5;
********************************************************************;

* Remove the comments to activate + change csv file name for each model;
*proc export data=DEPLOYFILE
   outfile='/folders/myfolders/PREDICT_411/Insurance/insurance05.csv'
   dbms=csv
   replace;
*run;

********************************************************************;
* Data Preparation--Model 6;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;

title "Model 6";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;
run;

***
Data Preparation Checks
***

* Make sure all imputations worked by seeing that everything has 8161 records--YEP;
proc print data=tempfile (obs=10);
run;

proc means data=tempfile min max mean median n nmiss;
run;

********************************************************************;
* Model Creation--Model 6;
********************************************************************;

* Variable Selection = decision tree in R;

* Model;
proc logistic data=tempfile  plot(only)=(roc(ID=prob));
class 				IMP_JOB
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					IMP_JOB
					URBANICITY
					OLDCLAIM
					IMP_HOME_VAL
					/roceps=0.1
					;
score out=SCORED_FILE;
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE to examine probability--Model 6;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE;

* Making sure the SCORE_ME file has all 8161 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 6";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -2.0702 
+ (IMP_JOB in ("Clerical")) * -0.2079
+ (IMP_JOB in ("Doctor")) * -1.1322
+ (IMP_JOB in ("Home Maker")) * -0.3468
+ (IMP_JOB in ("Lawyer")) * -0.9459
+ (IMP_JOB in ("Manager")) * -1.3787
+ (IMP_JOB in ("Professional")) * -0.6326
+ (IMP_JOB in ("Student")) * -0.1073
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.1996
+ OLDCLAIM * 0.00002
+ IMP_HOME_VAL * -3.34E-06
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp( YHAT ) / ( 1+exp( YHAT ));

run;

proc print data=DEPLOYFILE(obs=10);
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE_TEST--Model 6;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE_TEST;

* Making sure the SCORE_ME file has all 2141 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 6";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -2.0702 
+ (IMP_JOB in ("Clerical")) * -0.2079
+ (IMP_JOB in ("Doctor")) * -1.1322
+ (IMP_JOB in ("Home Maker")) * -0.3468
+ (IMP_JOB in ("Lawyer")) * -0.9459
+ (IMP_JOB in ("Manager")) * -1.3787
+ (IMP_JOB in ("Professional")) * -0.6326
+ (IMP_JOB in ("Student")) * -0.1073
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.1996
+ OLDCLAIM * 0.00002
+ IMP_HOME_VAL * -3.34E-06
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp(YHAT)/(1+exp(YHAT));

keep INDEX P_TARGET_FLAG;

run;

proc means data=DEPLOYFILE;
var P_TARGET_FLAG;
run;

proc print data=DEPLOYFILE(obs=10);
run;

********************************************************************;
* Exporting the Scored Model--Model 6;
********************************************************************;

* Remove the comments to activate + change csv file name for each model;
*proc export data=DEPLOYFILE
   outfile='/folders/myfolders/PREDICT_411/Insurance/insurance06.csv'
   dbms=csv
   replace;
*run;

********************************************************************;
* Data Preparation--Model 7 (same as Model 2 but with outest);
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;

title "Model 7";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;
run;

***
Data Preparation Checks
***

* Make sure all imputations worked by seeing that everything has 8161 records--YEP;
proc print data=tempfile (obs=10);
run;

proc means data=tempfile min max mean median n nmiss;
run;

proc freq data=tempfile;
table OLDCLAIM_BIN / plots=freqplot;
run;

********************************************************************;
* Model Creation--Model 7;
********************************************************************;

* Variable Selection;

proc logistic data=tempfile;
class 				CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					RED_CAR
					REVOKED
					SEX
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					RED_CAR
					REVOKED
					SEX
					URBANICITY
					
					IMP_AGE
					IMP_BLUEBOOK
					IMP_CAR_AGE
					CLM_FREQ
					HOMEKIDS
					IMP_HOME_VAL
					IMP_INCOME
					KIDSDRIV
					MVR_PTS
					OLDCLAIM
					TIF
					IMP_TRAVTIME
					IMP_YOJ
					/selection=stepwise
					; *I tried OLDCLAIM_BIN but it was selected only when OLDCLAIM was included--don't want 2 OLDCLAIM variables;
run;

* adjrsq aic bic mse cp vif selection = stepwise slentry =0.10 slstay=0.10;

proc logistic data=tempfile  plot(only)=(roc(ID=prob)) outest = est;
class 				CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					REVOKED
					URBANICITY /param=ref;
model TARGET_FLAG( ref="0" ) = 
					CAR_TYPE
					CAR_USE
					EDUCATION
					IMP_JOB
					MSTATUS
					PARENT1
					REVOKED
					URBANICITY
					
					IMP_BLUEBOOK
					CLM_FREQ
					IMP_HOME_VAL
					IMP_INCOME
					KIDSDRIV
					MVR_PTS
					OLDCLAIM
					TIF
					IMP_TRAVTIME
					/roceps=0.1
					;
score out=SCORED_FILE;
run;

proc print data=SCORED_FILE(obs=10);
run;

proc print data=est(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE to examine probability--Model 7;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE;

* Making sure the SCORE_ME file has all 8161 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 7";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -1.38917 
+ (CAR_TYPE in ("Minivan")) * -0.70994
+ (CAR_TYPE in ("Panel Truck")) * -0.082678
+ (CAR_TYPE in ("Pickup")) * -0.17664
+ (CAR_TYPE in ("Sports Car")) * 0.25548
+ (CAR_TYPE in ("Van")) * -0.06465
+ (CAR_USE in ("Commercial")) * 0.80753
+ (EDUCATION in ("<High School")) * 0.00556735
+ (EDUCATION in ("Bachelors")) * -0.41984
+ (EDUCATION in ("Masters")) * -0.37598
+ (EDUCATION in ("PhD")) * -0.29778
+ (IMP_JOB in ("Clerical")) * 0.14372
+ (IMP_JOB in ("Doctor")) * -0.41801
+ (IMP_JOB in ("Home Maker")) * 0.028733
+ (IMP_JOB in ("Lawyer")) * -0.085488
+ (IMP_JOB in ("Manager")) * -0.74691
+ (IMP_JOB in ("Professional")) * -0.075196
+ (IMP_JOB in ("Student")) * -0.027836
+ (MSTATUS in ("Yes")) * -0.46027
+ (PARENT1 in ("No")) * -0.46297
+ (REVOKED in ("No")) * -0.89435
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.3843
+ IMP_BLUEBOOK * -0.000024963
+ CLM_FREQ * 0.19678
+ IMP_HOME_VAL * -0.000001431
+ IMP_INCOME * -0.000003177
+ KIDSDRIV * 0.4182
+ MVR_PTS * 0.11428
+ OLDCLAIM * -0.000014076
+ TIF * -0.055586
+ IMP_TRAVTIME * 0.015053
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp( YHAT ) / ( 1+exp( YHAT ));

run;

proc print data=DEPLOYFILE(obs=10);
run;

proc print data=SCORED_FILE(obs=10);
run;

********************************************************************;
* Model Scoring--Using LOGIT_INSURANCE_TEST--Model 7;
********************************************************************;

%let SCORE_ME = &LIB.LOGIT_INSURANCE_TEST;

* Making sure the SCORE_ME file has all 2141 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Model 7";

IMP_AGE = AGE;
M_IMP_AGE = missing(IMP_AGE);
if IMP_AGE = . then IMP_AGE = 45;

AGE_BIN = 0;
if 25 < IMP_AGE <= 35 	then AGE_BIN = 1;
if 35 < IMP_AGE <= 45 	then AGE_BIN = 2;
if 45 < IMP_AGE <= 55 	then AGE_BIN = 3;
if 55 < IMP_AGE <= 65	then AGE_BIN = 4;
if 65 < IMP_AGE			then AGE_BIN = 5;

IMP_YOJ = YOJ;
M_IMP_YOJ = missing(IMP_YOJ);
if IMP_YOJ = . then do;
if AGE_BIN = 0 then IMP_YOJ = 8;
if AGE_BIN = 1 then IMP_YOJ = 10;
if AGE_BIN = 2 then IMP_YOJ = 10;
if AGE_BIN = 3 then IMP_YOJ = 10;
if AGE_BIN = 4 then IMP_YOJ = 12;
if AGE_BIN = 5 then IMP_YOJ = 13;
end;
if IMP_YOJ > 19 then IMP_YOJ = 19; * gets rid of 2 highest outliers;

IMP_INCOME = INCOME;
M_IMP_INCOME = missing(IMP_INCOME);
if missing(IMP_INCOME) then do;
	if JOB = "Clerical" then
		IMP_INCOME = 33861.19;	
	else if JOB = "Doctor" then
		IMP_INCOME = 128679.71;
	else if JOB = "Home Maker" then
		IMP_INCOME = 12073.33;
	else if JOB = "Lawyer" then
		IMP_INCOME = 88304.81;
	else if JOB = "Manager" then
		IMP_INCOME = 87461.56;
	else if JOB = "Professional" then
		IMP_INCOME = 76593.11;
	else if JOB = "Student" then
		IMP_INCOME = 6309.65;
	else if JOB = "z_Blue Collar" then
		IMP_INCOME = 58957.01;
	else
		IMP_INCOME = 61898.10;
end;

IMP_JOB = JOB;
M_IMP_JOB = missing(IMP_JOB);
if missing(IMP_JOB) then do; * Just ballparked values somewhere between the 50th and 75th percentile for the top 4 paying professions;
	if IMP_INCOME > 125000  then 
		IMP_JOB = "Doctor";	
	else if IMP_INCOME > 95000 then 
		IMP_JOB = "Lawyer";
	else if IMP_INCOME > 75000 then 
		IMP_JOB = "Manager";
	else if IMP_INCOME > 60000 then 
		IMP_JOB = "Professional";
	else
		IMP_JOB = "z_Blue Collar";
end;

IMP_HOME_VAL = HOME_VAL;
M_IMP_HOME_VAL = missing(IMP_HOME_VAL);
if missing(IMP_HOME_VAL) then do;
	if IMP_JOB = "Clerical" then
		IMP_HOME_VAL = 117635.99;	
	else if IMP_JOB = "Doctor" then
		IMP_HOME_VAL = 269556.66;
	else if IMP_JOB = "Home Maker" then
		IMP_HOME_VAL = 86861.73;
	else if IMP_JOB = "Lawyer" then
		IMP_HOME_VAL = 201922.45;
	else if IMP_JOB = "Manager" then
		IMP_HOME_VAL = 199290.2;
	else if IMP_JOB = "Professional" then
		IMP_HOME_VAL = 192245.39;
	else if IMP_JOB = "Student" then
		IMP_HOME_VAL = 15385.9;
	else if IMP_JOB = "z_Blue Collar" then
		IMP_HOME_VAL = 156413.52;
end;
if IMP_HOME_VAL > 497746 then IMP_HOME_VAL = 497746; *99p;

IMP_TRAVTIME = TRAVTIME;
if IMP_TRAVTIME > 75.14433 then IMP_TRAVTIME = 75.14433; *99p;

IMP_BLUEBOOK = BLUEBOOK;
if IMP_BLUEBOOK > 39090 then IMP_BLUEBOOK = 39090; *99p;

OLDCLAIM_BIN = 0;
if 0    < OLDCLAIM <= 5000 		then OLDCLAIM_BIN = 1;
if 5000 < OLDCLAIM <= 10000 		then OLDCLAIM_BIN = 2;
if 		OLDCLAIM	> 10000		then OLDCLAIM_BIN = 3;

IMP_CAR_AGE = CAR_AGE;
M_IMP_CAR_AGE = missing(IMP_CAR_AGE);
if IMP_CAR_AGE = . then IMP_CAR_AGE = 8; * used median;
if IMP_CAR_AGE = -3 then IMP_CAR_AGE = 3; * I figured the negative sign was a typo;

 YHAT = -1.38917 
+ (CAR_TYPE in ("Minivan")) * -0.70994
+ (CAR_TYPE in ("Panel Truck")) * -0.082678
+ (CAR_TYPE in ("Pickup")) * -0.17664
+ (CAR_TYPE in ("Sports Car")) * 0.25548
+ (CAR_TYPE in ("Van")) * -0.06465
+ (CAR_USE in ("Commercial")) * 0.80753
+ (EDUCATION in ("<High School")) * 0.00556735
+ (EDUCATION in ("Bachelors")) * -0.41984
+ (EDUCATION in ("Masters")) * -0.37598
+ (EDUCATION in ("PhD")) * -0.29778
+ (IMP_JOB in ("Clerical")) * 0.14372
+ (IMP_JOB in ("Doctor")) * -0.41801
+ (IMP_JOB in ("Home Maker")) * 0.028733
+ (IMP_JOB in ("Lawyer")) * -0.085488
+ (IMP_JOB in ("Manager")) * -0.74691
+ (IMP_JOB in ("Professional")) * -0.075196
+ (IMP_JOB in ("Student")) * -0.027836
+ (MSTATUS in ("Yes")) * -0.46027
+ (PARENT1 in ("No")) * -0.46297
+ (REVOKED in ("No")) * -0.89435
+ (URBANICITY in ("Highly Urban/ Urban")) * 2.3843
+ IMP_BLUEBOOK * -0.000024963
+ CLM_FREQ * 0.19678
+ IMP_HOME_VAL * -0.000001431
+ IMP_INCOME * -0.000003177
+ KIDSDRIV * 0.4182
+ MVR_PTS * 0.11428
+ OLDCLAIM * -0.000014076
+ TIF * -0.055586
+ IMP_TRAVTIME * 0.015053
;

if YHAT > 999  then YHAT = 999;
if YHAT < -999 then YHAT = -999;

P_TARGET_FLAG = exp(YHAT)/(1+exp(YHAT));

keep INDEX P_TARGET_FLAG;

run;

proc means data=DEPLOYFILE;
var P_TARGET_FLAG;
run;

proc print data=DEPLOYFILE(obs=10);
run;

********************************************************************;
* Exporting the Scored Model--Model 7;
********************************************************************;

* Remove the comments to activate + change csv file name for each model;
proc export data=DEPLOYFILE
   outfile='/folders/myfolders/PREDICT_411/Insurance/insurance07.csv'
   dbms=csv
   replace;
run;
