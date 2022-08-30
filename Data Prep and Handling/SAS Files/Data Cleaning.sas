FILENAME REFFILE '/home/u60688916/sasuser.v94/BAN 110 Data Handling/data/adulterror.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.INCOME;
	GETNAMES=YES;
RUN;

data income;
set income;
ID = _n_;
run;
        
title "Printing the first 10 observation";
proc print data= income (obs=10);
run;

title "Frequency Distribution of Categorical Variables";
proc FREQ data = income ;
tables workclass education education_num marital_status occupation relationship race sex native_country income; 
run;

title "Summary Statistics of Numerical Variables";
PROC SUMMARY PRINT MEAN MEDIAN MIN MAX STD SKEWNESS Q1 Q3;
  VAR age fnlwgt capital_gain capital_loss hour_week;
  RUN;
  
title "Histogram to show distribution of Numerical Variables";
PROC univariate data= income noprint;
  histogram age fnlwgt capital_gain capital_loss hour_week / normal;
RUN;

*Part 4;

/*printing 100 observations of the data */
proc print data = income (obs=10);
run;

proc contents data = income (obs=10);
run;


/*frequency table for the categorical variables*/
proc freq data = income;
tables WorkClass Education Marital_Status Occupation Relationship Race 
Sex Native_Country;
run;

/*checking for records where workclass, occupation and native country is missing*/
proc print data = income(obs=10);
where workclass = "?" and occupation = "?" and Native_Country="?";
run;

/*deleting records where all three variables are missing as they represent 
a minority population*/
data income_correction;
set income;
if workclass="?" and occupation="?" and Native_Country="?" then delete;
run;

/*frequency table for the new dataset*/
proc freq data = income_correction;
tables WorkClass Education Marital_Status Occupation Relationship Race 
Sex Native_Country;
run;

/*replacing the missing values for workclass and Occupation with value 'Other'*/
data income_other;
set income_correction;
if workclass = "?" then workclass="Other";
if Occupation = "?" then Occupation = "Other";
run;

/*checking if the correction worked*/
proc freq data = income_other;
tables workclass occupation;
run;

/*deleting the values where country is missing as there are only 58 records*/
data income_country;
set income_other;
if Native_Country="?" then delete;
run;

/*checking if the correction worked*/
proc freq data = income_country;
table native_country;
run;

proc print data = income_country (obs=10);
run;

/*creating a derived variable marital_status_new*/
data income_country;
set income_country;
if Marital_Status in ("Married-AF-spouse","Married-civ-spouse","Married-spouse-absent") 
then marital_status_new="Married";
else marital_status_new="Single";
run;

proc print data = income_country (obs=10);
run;

DATA income_country;
set income_country;
	length Location $10;
  	if hour_week>40 and income='<=50K' 
  		then Min_Wage='Yes';
    if hour_week<=40 and income='>50K' 
  		then Min_Wage='No';
	if hour_week>40 and income='>50K'
 		then Min_Wage='NW';*NW represents Normal Wage;
 	if hour_week<=40 and income='<=50K' 
		then Min_Wage='NW';*NW represents Normal Wage;
	if native_country='United-States'  
  		then Location='US';
   	if native_country^='United-States'  
  		then Location='non US';
run;

proc freq data=income_country;
table Min_Wage Location;
run;

*PART 5;


title "Printing the first 10 observation";

proc print data=income_country(obs=10);
run;

title "Basic statistical measures on numerical variablse";

proc means data=income_country n nmiss min max mean median mode;
run;

ods trace on;
title "Running PROC UNIVARIATE on age, education_num, hour_week";
ODS Select ExtremeObs Quantiles Histogram;

proc univariate data=income_country;
	var age education_num hour_week capital_gain capital_loss;
	histogram / normal;
run;

ods trace off;
title "Check for Out of range Values";
*Check for Out of range Values;

data _null_;
	set income_country;
	file print;

	if age lt 16 or age gt 120 then
		put "Out of range AGE value: " age " for ID " ID;

	if hour_week le 0 then
		put "Out of range HOUR_WEEK value: " hour_week " for ID " ID;

	if education_num lt 1 or education_num gt 16 then
		put "Out of range EDUCATION_NUM value: " education_num " for ID " ID;
run;

data missing_data;
	set income_country;

	if ID in (41, 77, 137, 197, 346, 524, 824, 1161, 1332);
run;

title "Looking at the complete data for missing values";

proc print data=missing_data;
run;

/*
Correcting error by deleting out of range values
Observations with age greater than 120 or hour_week less eq 0 is deleted.
*/
data error_correction;
	set income_country;

	if age ge 120 or hour_week eq 0 then
		delete;
run;

ods trace on;
title "Running PROC UNIVARIATE on age, education_num, hour_week";
ODS Select ExtremeObs Quantiles Histogram;

proc univariate data=error_correction;
	var age;
	histogram / normal;
run;

ods trace off;

proc means data=error_correction;
run;

*Listing Highest and Lowest Values;

proc sort data=error_correction(keep=ID age where=(age is not missing)) out=Tmp;
	by age;
run;

data _null_;
	if 0 then
		set Tmp nobs=Number_of_Obs;
	*2;
	High=Number_of_Obs - 9;
	call symputx('High_Cutoff', High);
	*3;
	stop;
	*4;
run;

title "Ten Highest and Lowest Values for age";

data _null_;
	set Tmp(obs=10) /* 10 lowest values */
	Tmp(firstobs=&High_Cutoff);
	*5;

	/* 10 highest values */
	file print;
	*6;

	if _n_ le 10 then
		do;
			*7;

			if _n_=1 then
				put / "Ten Lowest Values";
			*8;
			put "ID = " ID @15 "Value = " age;
		end;
	else if _n_ ge 11 then
		do;
			*9;

			if _n_=11 then
				put / "10 Highest Values";
			put "ID = " ID @15 "Value = " age;
		end;
run;

*Printing missing values;

data _null_;
	set error_correction;
	file print;
	array Nums[*] _numeric_;
	length Varname $ 32;

	do iii=1 to dim(Nums);

		if Nums[iii]=. then
			do;
				Varname=vname(Nums[iii]);
				put "Missing value found for variable " Varname "for ID " _n_;
			end;
	end;
	drop iii;
run;

*Deleting missing values for age;
*Missing values have been deleted because it represent a very small portion of the dataset i.e 0.018%;

data deleted_values;
	set error_correction;

	if missing(age) then
		delete;
run;

/*
Outlier 1
Outliers from age were deleted because it represented a tiny portion of the dataset 0.14%;
*/
title "PROC UNIVARIATE for age";

proc univariate data=deleted_values;
	var age;
	histogram /normal;
	qqplot;
run;

proc means data=deleted_values noprint;
	var age;
	output out=work.Tmp Q1=Q3=QRange= / autoname;
run;

data _null_;
	file print;
	set deleted_values(keep=id age);

	if _n_=1 then
		set Tmp;

	if age le age_Q1 - 2*age_QRange and not missing(age) or age ge 
		age_Q3 + 2*age_QRange then
			put "Possible Outlier for ID " ID "Value of Age is " age;
run;

data age_Out;
	set deleted_values;

	if _n_=1 then
		set Tmp;

	if age le age_Q1 - 2*age_QRange and not missing(age) or age ge 
		age_Q3 + 2*age_QRange then
			output;
run;

title "Isolated Outliers for age";

proc means data=age_Out;
	var age;
run;

*Outliers from age were deleted because it represented a tiny portion of the dataset 0.14%;

data outlier_deleted;
	set deleted_values;

	if _n_=1 then
		set Tmp;

	if age le age_Q1 - 2*age_QRange and not missing(age) or age ge 
		age_Q3 + 2*age_QRange then
			delete;
run;

title "PROC UNI after deleting";

proc univariate data=outlier_deleted;
	var age;
	histogram;
	qqplot;
run;

/*
Outlier 2
Outliers detected for hour_week weren't deleted.
Extreme outlier value with 3*Standart deviation was used to detect the outliers.
Result had 6513 values which represent about 20% of the entire dataset.
*/
title "Proc UNIVARIATE HOUR_WEEK";

proc univariate data=outlier_deleted;
	var hour_week;
	histogram;
	qqplot;
run;

proc means data=outlier_deleted noprint;
	var hour_week;
	output out=work.Tmp2 Q1=Q3=QRange= / autoname;
run;

*;

data _null_;
	file print;
	set outlier_deleted(keep=id hour_week);

	if _n_=1 then
		set tmp2;

	if hour_week le hour_week_Q1 - 3*hour_week_QRange and not missing(hour_week) 
		or hour_week ge hour_week_Q3 + 3*hour_week_QRange then
			put "Possible Outlier for index " ID "Value of Hour_Week is " hour_week;
run;

data hour_weekOut;
	set outlier_deleted(keep=id hour_week);

	if _n_=1 then
		set tmp2;

	if hour_week le hour_week_Q1 - 3*hour_week_QRange and not missing(hour_week) 
		or hour_week ge hour_week_Q3 + 3*hour_week_QRange then
			output;
run;

title "Isolated outliers for hour_Week";

proc means data=hour_weekOut;
	var hour_week;
run;

/*
Distribution and log Transformation fnlwgt
Before : QQ Plot forms a curve which means that the data is highlight skewed.
After  : QQ Looks more linear and data isn't as skewed.
*/
proc univariate data=outlier_deleted normal plot;
	var fnlwgt;
	histogram;
	qqplot;
run;

data log_transform;
	SET outlier_deleted;
	log_fnlwgt=log(fnlwgt);
	root4_fnlwgt=(fnlwgt) ** 0.25;
run;

proc univariate data=log_transform normal plot;
	var log_fnlwgt root4_fnlwgt;
run;

proc means data=outlier_deleted;
run;

data clean_data;
set outlier_deleted(drop=_TYPE_ _FREQ_ age_Q1 age_Q3 age_QRange);
run;

proc export data=work.clean_data
    outfile="~/sasuser.v94/clean_data.csv"
    dbms=csv;
run;