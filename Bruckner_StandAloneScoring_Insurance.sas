********************************************************************;
* Model Scoring--Best Model (Model 2, Kaggle submission insurance02a.csv);
********************************************************************;

* Set library name and path to data;

%let PATH = /folders/myfolders/PREDICT_411/Insurance;
%let NAME = LOGIT;
%let LIB = &NAME..;

libname &NAME. "&PATH.";

%let SCORE_ME = &LIB.LOGIT_INSURANCE_TEST;

* Making sure the SCORE_ME file has all 2141 records--it does;
proc means data=&SCORE_ME. n;
var INDEX;
run;

data DEPLOYFILE;
set &SCORE_ME.;

title "Best Model";

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
* Exporting the Scored Model;
********************************************************************;

* Remove the comments to activate + change csv file name for each model;
proc export data=DEPLOYFILE
   outfile='/folders/myfolders/PREDICT_411/Insurance/Bruckner_BestInsurance.csv'
   dbms=csv
   replace;
run;