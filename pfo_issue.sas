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

data xx1;
	set x6;	
	mktcap1=lag(mktcap);
	run;

data xx1;
set xx1;
if t=13 then mktcap1=.;
run;

proc sort data=xx1;
by t year_pfo;
run;

proc rank data=xx1 out=xx2 group=2;
by t year_pfo;
var size;
ranks size_group1;
run;

proc rank data=xx2 out=xx2 group=10;
by t year_pfo;
var BM;
ranks BM_group1;
run;


data xx3;
set xx2;
if size_group1 = 0 & bm_group1<=2 then first_group=1;
else if size_group1 = 0 & bm_group1<=6 then first_group=2;
else if size_group1 = 0 & bm_group1<=9 then first_group=3;
else if size_group1 = 1 & bm_group1<=2 then first_group=4;
else if size_group1 = 1 & bm_group1<=6 then first_group=5;
else if size_group1 = 1 & bm_group1<=9 then first_group=6;
run;

proc sort data=xx3;
by t first_group;
run;

proc means data=xx3 noprint;
by t first_group;
var return/weight=mktcap1;
output out=xx4(drop=_type_ _freq_) mean=m_ret;
run;

data xx5;
set xx4;
SMB= (lag5(m_ret) + lag4(m_ret) + lag3(m_ret))/3 - (lag2(m_ret) + lag1(m_ret) + m_ret)/3;
HML = (lag3(m_ret) + m_ret)/2 - (lag5(m_ret) + lag2(m_ret))/2;
if first_group = 6;
drop first_group m_ret;
run;  *이후 다시 원래 데이터에 더해준다.;


proc means data= xx3 noprint;
by t;
var return/weight=mktcap1;  */weight=mktcap1 -> 문법 자체임 (mktcap1이라는 변수를 가지고 가중치로 계산한다는 의미); 
output out = xx6(drop=_type_ _freq_) mean=vwmktret; *분모(시가총액 합) 구해서 붙인것;
run;


data xx7;
merge xx3 xx6;
by t;
excess_mktret=vwmktret-rf_monthly;
run;

proc sort data=xx7;
by firmcode t;
run;

data xx8;
set xx7;
keep time firmcode excess_mktret t;
run;

proc sort data=xx8; by t; run; 
proc sort data=xx5; by t; run; 

data xx9;
merge xx8 xx5;
by t;
if time ^=.;
run;

proc means data=xx9 noprint;
var excess_mktret;
output out=xx10 mean=avg std=std_n t=t_value;
run;

proc means data=xx9 noprint;
var SMB;
output out=xx11 mean=avg std=std_n t=t_value;
run;

proc means data=xx9 noprint;
var  HML;
output out=xx12 mean=avg std=std_n t=t_value;
run;





