*********************************************************
1. check the data
*********************************************************;


*********************************************************
*1.A;

libname tmp1 'C:\Users\user\Dropbox\SAS\SNU\';

data data1; set tmp1.data1; run;

data prac1; set data1;
	if time ^=.;
	month=month(time);
	year=year(time);
	t=(year-1987)*12 + month;
run;

data prac1A_ex; 
	set prac1;
	if mktcap=0 and month=06; 
	skip=1;
	keep firmcode skip;
	run;

proc sort data=prac1A_ex; 
	by firmcode;
	run;
proc sort data=prac1; 
	by firmcode;
	run;

data prac1A;
	merge prac1 prac1A_ex;
	by firmcode;
	if skip=.;
	drop skip;
	run;

*********************************************************
*1.B;


data prac1B_lag;
	set prac1a;	
	if month=12;
	run;

data prac1B_lag1;
	set prac1B_lag;
	BM=bookvalue/mktcap;
	lag_year=year+1;
	keep year lag_year firmcode BM;
	run;

data prac1B_lag2;
	set prac1a;
	keep year firmcode;
	run;

proc sort data=prac1B_lag2 nodupkey out=prac1B_lag2;
by firmcode; 
run; 


proc sort data=prac1B_lag1;by firmcode year; run;
proc sort data=prac1B_lag2;by firmcode year; run;

data prac1B_lag3;
	merge prac1B_lag1 prac1B_lag2;
	by firmcode year;
	year=year+1;
	lag_year=year-1;
	run;

data prac1B_ex1; 
	merge prac1a(in=a) prac1B_lag3;
	by firmcode year;
	drop year;
	rename lag_year=year;
	if a; 
	run;

data prac1B;
	set prac1B_ex1;
	rename year=lag_year;
	if BM=. or BM<=0 then delete;
	if time=. then delete;
	run;

*********************************************************
*1.C;

proc sort data=prac1B; by month; run;


proc means data=prac1B noprint;
	by month;
	var return;
	output out=prac1Cvar1_2 mean=ewret std=ewret_std 
										min=ewret_min max=ewret_max p25=ewret_p25 p50=ewret_p50 p75=ewret_p75;
	run;

proc means data=prac1B noprint;
	by month;
	var mktcap;
	output out=prac1Cvar2_2 mean=ewcap std=ewcap_std 
										min=ewcap_min max=ewcap_max p25=ewcap_p25 p50=ewcap_p50 p75=ewcap_p75;
	run;

proc means data=prac1B noprint;
	by month;
	var BM;
	output out=prac1Cvar3_2 mean=ewBM std=ewBM_std 
										min=ewBM_min max=ewBM_max p25=ewBM_p25 p50=ewBM_p50 p75=ewBM_p75;
	run;


proc summary data=prac1Cvar1_2 noprint;
	var ewret ewret_std ewret_min ewret_max ewret_p25 ewret_p50 ewret_p75;
	output out=prac1Cvar1_3;
	run;

proc summary data=prac1Cvar2_2 noprint;
	var ewcap ewcap_std ewcap_min ewcap_max ewcap_p25 ewcap_p50 ewcap_p75;
	output out=prac1Cvar2_3;
	run;

proc summary data=prac1Cvar3_2 noprint;
	var ewBM ewBM_std ewBM_min ewBM_max ewBM_p25 ewBM_p50 ewBM_p75;
	output out=prac1Cvar3_3;
	run;




*********************************************************
*2;

proc sort data=prac1b;
by month;
run;

proc means data=prac1b noprint;
var return;
by month;
output out=prac2_1 p1=lret p99=hret; 
run;


data prac2_2; 
merge prac1b prac2_1(drop=_type_ _freq_);
by month;
if return < lret then return=lret;
if return > hret then return=hret;
drop lret hret;
run;


proc means data=prac2_2 noprint;
var return;
by month;
output out=prac2_ret mean=ewret std=ewret_std 
									min=ewret_min max=ewret_max p25=ewret_p25 p50=ewret_p50 p75=ewret_p75;;
run;

proc summary data=prac2_ret;
var ewret ewret_std ewret_min ewret_max ewret_p25 ewret_p50 ewret_p75;
output out=prac2_ret1;
run;


proc means data=prac1b noprint;
var mktcap;
by month;
output out=prac2_3 p1=lcap p99=hcap; 
run;


data prac2_4; 
merge prac1b prac2_3(drop=_type_ _freq_);
by month;
if mktcap < lcap then mktcap=lcap;
if mktcap > hcap then mktcap=hcap;
drop lcap hcap;
run;

proc means data=prac2_4 noprint;
var mktcap;
by month;
output out=prac2_cap mean=ewcap std=ewcap_std 
									min=ewcap_min max=ewcap_max p25=ewcap_p25 p50=ewcap_p50 p75=ewcap_p75;;
run;

proc summary data=prac2_cap;
var ewcap ewcap_std ewcap_min ewcap_max ewcap_p25 ewcap_p50 ewcap_p75;
output out=prac2_cap1;
run;


proc means data=prac1b noprint;
var BM;
by month;
output out=prac2_5 p1=lbm p99=hbm; 
run;


data prac2_6; 
merge prac1b prac2_5(drop=_type_ _freq_);
by month;
if BM < lBM then BM=lbm;
if BM > hBM then BM=hbm;
drop lbm hbm;
run;

proc means data=prac2_6 noprint;
var BM;
by month;
output out=prac2_BM mean=ewBM std=ewBM_std 
									min=ewBM_min max=ewBM_max p25=ewBM_p25 p50=ewBM_p50 p75=ewBM_p75;;
run;

proc summary data=prac2_BM;
var ewBM ewBM_std ewBM_min ewBM_max ewBM_p25 ewBM_p50 ewBM_p75;
output out=prac2_BM1;
run;





*********************************************************
*3;

data x;
set prac2_6;
run;

data x;
set x;
year=year(time);
run;

data x1;
set x;
 if month <=6 then year_pfo = year - 2;
 else year_pfo = year - 1;   
 run;

data x2;
set x1;
if month = 12;
keep year year_pfo firmcode BM;
run;

data x3;
set x1;
if month = 6;
year_pfo = year -1;
keep year_pfo year firmcode mktcap;
rename mktcap = size;
run;

proc sort data=x2; by year_pfo firmcode; run;
proc sort data=x3; by year_pfo firmcode; run;


proc sort data = x1;
by year_pfo firmcode;
 run;

 proc sort data = x2;
by year_pfo firmcode;
 run;

 proc sort data = x3;
by year_pfo firmcode;
 run;

 data x5;
 merge x1(in=a) x2 x3;
 by year_pfo firmcode;
 if a;
 if BM=. or BM <0 or time=. then delete;
 run;

 proc sort data=x5;
 by firmcode time;
 run;

 data x6;
 set x5;
 if size^=.;
 run;

proc sort data=x6;
by firmcode;
run;

data prac3_1;
   set x6; 
   firmcode1 = lag1(firmcode); 
   mktcap1 = lag1(mktcap); 
   if firmcode ne firmcode1 then mktcap1 =.; else  mktcap1 =mktcap1 ; 
   drop firmcode1;
run ;


proc sort data=prac3_1;
by t;
run;

proc rank data=prac3_1 out=prac3_2 group=2;
by t;
var mktcap;
ranks size_group1;
run;

proc rank data=prac3_2 out=prac3_2 group=10;
by t;
var BM;
ranks BM_group1;
run;


data prac3_3;
set prac3_2;
if size_group1 = 0 & bm_group1<=2 then first_group=1;
else if size_group1 = 0 & bm_group1<=6 then first_group=2;
else if size_group1 = 0 & bm_group1<=9 then first_group=3;
else if size_group1 = 1 & bm_group1<=2 then first_group=4;
else if size_group1 = 1 & bm_group1<=6 then first_group=5;
else if size_group1 = 1 & bm_group1<=9 then first_group=6;
run;

proc sort data=prac3_3;
by t first_group;
run;

proc means data=prac3_3 noprint;
by t first_group;
var return/weight=mktcap1;
output out=prac3_4(drop=_type_ _freq_) mean=m_ret;
run;

data prac3_5;
set prac3_4;
SMB= (lag5(m_ret) + lag4(m_ret) + lag3(m_ret))/3 - (lag2(m_ret) + lag1(m_ret) + m_ret)/3;
HML = (lag3(m_ret) + m_ret)/2 - (lag5(m_ret) + lag2(m_ret))/2;
if first_group = 6;
drop first_group m_ret;
run;  


proc means data= prac3_3 noprint;
by t;
var return/weight=mktcap1;  
output out = prac3_6(drop=_type_ _freq_) mean=vwmktret;
run;


data prac3_7;
merge prac3_3 prac3_6;
by t;
excess_mktret=vwmktret-rf_monthly;
run;

data prac3_77;
set prac3_7;
run;

proc sort data=prac3_77(keep= t excess_mktret) nodupkey;
by t;
run;

data prac3_8;
merge prac3_77 prac3_5;
by t;
run;

proc means data=prac3_8 noprint;
var excess_mktret;
output out=prac3_10 mean= std= t= / autoname;
run;

proc means data=prac3_8 noprint;
var SMB;
output out=prac3_11 mean= std= t= / autoname;
run;

proc means data=prac3_8 noprint;
var  HML;
output out=prac3_12 mean= std= t= / autoname;
run;


*********************************************************
*4;


proc sort data=prac3_7;
by t;
run;

proc rank data=prac3_7 out=prac4_1 group=5;
by t;
var size;
ranks size_group2;
run;

proc rank data=prac4_1 out=prac4_1 group=5;
by t;
var BM;
ranks BM_group2;
run;

data prac4_2;
set prac4_1;
second_group = size_group2*5 + bm_group2+1; 
run;

proc sort data=prac4_2;
by t second_group;
run;

proc means data=prac4_2 noprint;
by t second_group;
var return/weight=mktcap1;
output out=prac4_3(drop=_type_ _freq_) mean=vwret_pt;
run;

proc sort data=prac4_3; by t second_group; run;
proc sort data=prac4_2; by t second_group; run;



data prac4_4;
merge prac4_2(keep=rf_monthly t second_group) prac4_3;
by t second_group;
excess_pfret=vwret_pt-rf_monthly;
run;

proc sort data=prac4_4 nodupkey;
by t second_group excess_pfret;
run;

proc sort data=prac4_4; by second_group; run;

proc means data=prac4_4 noprint;
by second_group;
var excess_pfret;
output out=prac4_5 mean=avg_pfret std=std_pfret t=t_pfret; 
run;




*********************************************************
*5;

proc sort data=prac3_8;
by t;
run;

proc sort data=prac4_4;
by t second_group;
run;

data prac5_ex1;
merge prac3_8 prac4_4;
by t;
run;

proc sort data=prac5_ex1;
by second_group;
run;

proc reg data=prac5_ex1 noprint outest=prac5_ex2 adjrsq tableout;
model excess_pfret=excess_mktret smb hml;
by second_group;
run;

data prac5_ex3parm;
set prac5_ex2;
by second_group;
if _type_ eq 'PARMS';
run; 

data prac5_ex3t;
set prac5_ex2;
by second_group;
if _type_ eq 'T';
run; 

data prac5_ex3RMSE;
set prac5_ex2;
by second_group;
keep  second_group _RMSE_;
run; 

proc sort data=prac5_ex3RMSE nodupkey;
by second_group;
run;


*
Table1=prac1cvar1_2, 1-3, 2-2, 2-3, 3-2, 3-3 참조 
Table2=prac2_ret / ret1 / cap / cap1 / bm / bm1 참조 
Table3=prac3_10 / 11 / 12 참조 (excess_mktret smb hml 순서)
Table4=prac4_5 참조
Table5=prac5_ex2 / ex3parm / ex3t /ex3stderr 참조 
;


