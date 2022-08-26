data z0;
set prac4_3;
run;

data z00;
set prac4_2;
run;


proc sort data=z0; by t second_group; run;
proc sort data=z00; by t second_group; run;

data z1;
merge z0 z00;
by t second_group;
excess_pfret=vwret_pt-rf_monthly;
run;



proc sort data=z1 nodupkey;
by excess_pfret;
run;

proc sort data=z1; by second_group; run;

proc means data=z1 noprint;
by second_group;
var excess_pfret;
output out=z2 mean=avg_pfret std=std_pfret t=t_pfret; 
run;




proc sort data=prac4_4;
by second_group;
run;

data prac5_ex2;
merge prac5_ex1 prac4_4;
by second_group;
keep time t excess_pfret excess_mktret smb hml second_group;
run;


data zzz;
set prac5_ex2;
run;

proc sort data=zzz nodupkey;
by second_group t;
run;

proc sort data=zzz;
by second_group;


proc reg data=zzz noprint outest=zzz1 adjrsq tableout;
model excess_pfret=excess_mktret smb hml;
by second_group;
run;



