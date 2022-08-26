
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
rename mktcap=mktcap1; *lag�� mktcap�̶�� �ǹ̷�;
run;

data datawork1; 
merge prac1(in=a) lagdata1;
by n firmcode;
if a; *lagdata���� n=133�̶�� �ʿ���� ���� ����Ƿ� merge�� ���Ͽ��� �������ִ� �����̴�;
run;

proc means data= datawork1 noprint;
by n;
var return/weight=mktcap1;  */weight=mktcap1 -> ���� ��ü�� (mktcap1�̶�� ������ ������ ����ġ�� ����Ѵٴ� �ǹ�); 
output out = datawork3 mean=vwmktret; *�и�(�ð��Ѿ� ��) ���ؼ� ���ΰ�;
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
 

 *2007�� 6������ 2006������ ���ĵ�. ;
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


*��ũ����;

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
second_group = size_group2*5 + beme_group2+1; *size�׷�� beme �׷쿡�� �ѹ����ϴ� �ڵ�;
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
run;  *���� �ٽ� ���� �����Ϳ� �����ش�.;


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

*���� ��Ÿ ��� ��÷�ڸ� �� ���̰� �ٸ� �����鿡 t ���� ��÷�ڸ� ���δ�.  
����/��Ÿ � i ��÷�ڸ� ���̸� �� ����� ���� ��� reg�� ������
����/��Ÿ � t ��÷�ڸ� ���̸� �ǹ̰� ����(�� ���� ���� ����) 
��, ��÷�ڸ� ��� ���̳Ŀ� ���� ����� �޶��� �� �ִ�. 

=> fama/french�� pf�� p�� ����� (p�� 1-25��) ��÷�ڸ� �ٿ���. 

i=1-300, t=1-132, p=1-25�� ����� p 1���� t 1-132���� ������ �Ǵ� ���̴�. 


1. ������Ʈ�������� ���ͷ� �ʿ� (�����ֽ��� �ƴ� ������Ʈ�������̱⶧��) 
2. rf, rm -> �ٷ� �ٿ�ε� ���� 
3. size factor
4. hml factor 

for 1. -> ri, 6�� ���� mktcap, lag�� mktcap,  11���� b/m �ʿ� 
for 2. -> mktcap, ri �ʿ� 
for 3,4. -> mktcap, bm �ʿ� 

�׷� �ʿ��ѵ����͵��� ��� ��������, ��� �ٿ������, ������ ���� ��������, ��� ����ؾ�����..(�׵��� ������ ���͵� �ϳ��ϳ�) 

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
by second_group; *�̰� ������? �׳� �ϳ��� ������ ��.;
run;



*
�������� ǥ ������ �� 
���ݼ� ���ְ�, �Ʒ�/�� �׵θ� �����, ����ü�� times new roman, �Ҽ��� 2�ڸ�����, ��ġ�� ������� 
;








