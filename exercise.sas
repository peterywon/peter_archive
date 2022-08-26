
libname tmp1 'C:\Users\user\Dropbox\SAS\SNU\';

data data; set tmp1.data1; run;

data prac1;
set data;
if time ^=.;
day=day(time);
month=month(time);
year=year(time);
qtr=qtr(time);
n=(year-2007)*12 + month;
ret_mod=mod(mktcap,3);
run;

proc sort data=prac1;
by n;
run;

proc means data=prac1 noprint;
by n;
var return;
output out =ew_mktret(drop=_type_ _freq_) mean= ewmktret n=num;
run;


data lagdata1;
set prac1;
n=n+1;
keep n firmcode mktcap;
rename mktcap=mktcap1; *lag된 mktcap이라는 의미로;
run;

data datawork1; 
merge prac1(in=a) lagdata1;
by n firmcode;
if a; *lagdata에는 n=133이라는 필요없는 값이 생기므로 merge된 파일에서 제거해주는 과정이다;
run;

proc means data= datawork1 noprint;
by n;
var return/weight=mktcap1;  */weight=mktcap1 -> 문법 자체임 (mktcap1이라는 변수를 가지고 가중치로 계산한다는 의미); 
output out = datawork3 mean=vwmktret; *분모(시가총액 합) 구해서 붙인것;
run;

data datawork4;
merge datawork1 datawork3(drop=_type_ _freq_) ew_mktret;
by n;
run;


data datawork5;
set datawork4;
 if month <=6 then year_pfo = year - 2;
 else year_pfo = year - 1; 
 run;

  data data1;
 set datawork5;
 if month=12;
 keep n year firmcode mktcap;
 run;
 

 *2007년 6월값이 2006년으로 정렬됨. ;
 data data2;
 set datawork5;
 if month=6;
 year_pfo=year-1;
 keep year_pfo firmcode mktcap;
rename mktcap=size;
run;

data data3;
merge datawork5(keep=firmcode n bookvalue year year_pfo) data1(drop=year in=a);
by n firmcode;
if a;
BE_ME=(bookvalue)/size;
run; 


proc sort data=data2;
by year_pfo firmcode;
run;
proc sort data=data3;
by year_pfo firmcode;
run;
proc sort data=datawork5;
by year_pfo firmcode;
run;


*스크리닝;

data data4;
merge data2 data3(keep=firmcode BE_ME year_pfo) datawork5;
by year_pfo firmcode; 
run;

data data4;
merge data2 data3(keep=firmcode BE_ME year_pfo) datawork5;
by year_pfo firmcode; 
if return=. or BE_ME=. or size=. or mktcap1=. or ind_code1='K' then delete;
if BE_ME<0  then delete;
run;


*grouping;

proc sort data=data4;
by n;
run;

proc rank data=data4 out=data_exercise;
by n;
var size;
ranks size_group1;
run;

proc rank data=data4 out=data_total group=2;
by n;
var size;
ranks size_group1;
run;

proc rank data=data_total out=data_total group=3;
by n;
var BE_ME;
ranks BEME_group1;
run;

proc rank data=data_total out=data_total group=5;
by n;
var size;
ranks size_group2;
run;

proc rank data=data_total out=data_total group=5;
by n;
var BE_ME;
ranks BEME_group2;
run;

data data_total1;
set data_total;
if size_group1 = 0 & beme_group1<=2 then first_group=1;
else if size_group1 = 0 & beme_group1<=6 then first_group=2;
else if size_group1 = 0 & beme_group1<=9 then first_group=3;
else if size_group1 = 1 & beme_group1<=2 then first_group=4;
else if size_group1 = 1 & beme_group1<=6 then first_group=5;
else if size_group1 = 1 & beme_group1<=9 then first_group=6;
second_group = size_group2*5 + beme_group2+1; *size그룹과 beme 그룹에게 넘버링하는 코드;
run;

proc sort data=data_total1;
by n first_group;
run;

proc means data=data_total1 noprint;
by n first_group;
var return/weight=mktcap1;
output out=factor1_value(drop=_type_ _freq_) mean=m_ret;
run;

data factor2_value;
set factor1_value;
SMB= (lag5(m_ret) + lag4(m_ret) + lag3(m_ret))/3 - (lag2(m_ret) + lag1(m_ret) + m_ret)/3;
HML = (lag3(m_ret) + m_ret)/2 - (lag5(m_ret) + lag2(m_ret))/2;
if first_group = 6;
drop first_group m_ret;
run;  *이후 다시 원래 데이터에 더해준다.;


data data_total2;
merge data_total1 factor2_value;
by n;
excess_ret=return-rf_monthly;
excess_mktret=vwmktret-rf_monthly;
run;

proc sort data=data_total2;
by firmcode n;
run;

proc reg data=data_total2 noprint outest=table3 adjrsq tableout;
model excess_ret=excess_mktret smb hml;
by firmcode;
run;


proc sort data=data_total2;
by n;
run;

proc reg data=data_total2 noprint outest=table4 adjrsq tableout;
model excess_ret=excess_mktret smb hml;
by n;
run;

*알파 베타 등에는 하첨자를 안 붙이고 다른 변수들에 t 등의 하첨자를 붙인다.  
알파/베타 등에 i 하첨자를 붙이면 각 기업에 대한 모든 reg를 돌린다
알파/베타 등에 t 하첨자를 붙이면 의미가 없다(다 같은 값이 나옴) 
즉, 하첨자를 어떻게 붙이냐에 따라 결과가 달라질 수 있다. 

=> fama/french는 pf의 p를 만들어 (p는 1-25개) 하첨자를 붙였다. 

i=1-300, t=1-132, p=1-25로 만들면 p 1개에 t 1-132개를 가지게 되는 셈이다. 


1. 개별포트폴리오의 수익률 필요 (개별주식이 아닌 개별포트폴리오이기때문) 
2. rf, rm -> 바로 다운로드 가능 
3. size factor
4. hml factor 

for 1. -> ri, 6월 기준 mktcap, lag된 mktcap,  11기준 b/m 필요 
for 2. -> mktcap, ri 필요 
for 3,4. -> mktcap, bm 필요 

그럼 필요한데이터들을 어떻게 정렬할지, 어떻게 다운받을지, 제외할 것은 무엇인지, 어떻게 계산해야할지..(그동안 이전에 배운것들 하나하나) 

;

data factor_temp;
set data_total2;
keep n rf_monthly excess_mktret SMB HML;
run;

proc sort data=factor_temp nodupkey out=factordata;
by n;
run; 


data table4_data1;
merge data_total2 factordata;
by n;
run;

proc sort data=table4_data1;
by second_group;
run;


Data table4_data2;
set table4_data1;
excess_pfo_ret=return-rf_monthly;
run;



proc reg data= table4_data2 noprint outest=table5 adjrsq tableout;
model excess_pfo_ret=excess_mktret smb hml;
by second_group; *이게 없으면? 그냥 하나만 나오게 됨.;
run;



*
엑셀에서 표 정리할 때 
눈금선 없애고, 아래/위 테두리 남기고, 글자체는 times new roman, 소수점 2자리까지, 배치는 가운데정렬 
;








