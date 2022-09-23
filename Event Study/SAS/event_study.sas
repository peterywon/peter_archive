* *************************************************************************** *
                                                    Event Study using SAS SQL
                                                 modified Yoon Sun-Heum's  by  Kim Ryumi     
* *************************************************************************** *
* --------------------------------------------------------------------------- *
   Data Sets used in This Program

   1. SAS DATA SET #1 : Return dataset 
      - variables: cd - multiple stock code,
                   dt - trading day,
                   ret- daily return
 
   2. SAS DATA SET #2 : Market Index Return dataset
      - variables: dt - trading day
                   mkt_ret - daily market return

   3. SAS DATA SET #3 : Event dataset
      - variables: cd - code for event stock
                   dt - the day of event

   -------------------------------------------------------------------------- *
   Variables Generated to implement Event Study

   1. Seq_day  : convert calendar day into sequential number which begins 1
   2. Event_num: unique seq. event number - allows multiple events in a stock 
   3. Event_day: event day which has '-' before event and '+' after event day 

   -------------------------------------------------------------------------- *
   Two sas data sets will be used in Event Study

   1. dsetwithmkt : sas dset #1 + sas dset #2 with Seq_day

   2. eventdset   : sas dset #3 with Event_num

   -------------------------------------------------------------------------- *
   Features of this program

   1. using SAS SQL - allows multiple events in a stock
   2. using 'retain' in CAR calculation  

   3. Assume that three sample sas data sets are in 'tmp1' sas library

   ---------------------------------------------------------------------------;

* --------------------------------------------------------------------------- *
*                             I. Start                                        *
* --------------------------------------------------------------------------- ;

libname tmp1 'd:\event_study\';

* Read data sets;

data ind  ; set tmp1.ind; 
data mkt  ; set tmp1.mkt; 
data event; set tmp1.event; run;

* merge index and ind. stock ;

proc sort data=ind; by dt; 
proc sort data=mkt; by dt; 

data xevent; merge ind mkt; by dt; run;


* sequential day number;

data date; set xevent; if dt eq lag(dt) then delete; run;

data date; set date; 
  keep dt seq_day; 
  seq_day=_n_; 
run;


* merge seq. number and sort by cd and dt in the cd;

data dsetwithmkt; merge xevent date; by dt; run;

proc sort data=dsetwithmkt; by cd dt; run;


* give seq_day into event data set 
  - unique sequential number of event;

data event; set event;
      event_num = _n_; 
run;

proc sort data=event; by dt; run;

data eventdset; merge event date; by dt;  
  if event_num eq . then delete; 
run;

proc sort data=eventdset; by event_num; run;



* --------------------------------------------------------------------------- *
*                     II. Implement Event Study                               *
*     Market and Risk Adjusted Return Model: AR_it = r_it-(a^ + b^*r_mt)      *
* --------------------------------------------------------------------------- ;

* Select data between Estimation Period & Post Event Period;

proc sql;

  create table edset as
  select distinct event_num, a.cd as cd, b.dt as dt, 
                  ret, mkt_ret, 
                  b.seq_day - a.seq_day as event_day
  
  from  eventdset   as a, dsetwithmkt as b

  where a.cd eq b.cd 

  order by event_num, event_day ; 
quit; run;

data edset; set edset;
   if (-120 <= event_day =< 30);               
run;


* make data set for estimation ;

data est_prd; set edset;
   if (-120 <= event_day < -30);
run;


* estimate alpha and beta;

proc reg data = est_prd outest=beta tableout noprint;

  model ret = mkt_ret ; 

  by    event_num;
run;

data beta; 
  set beta(keep = event_num _type_ intercept mkt_ret); 
  label intercept='alpha' mkt_ret ='beta' ;
  where _type_ eq 'PARMS';
  rename intercept = alpha  mkt_ret = beta ; 
  drop _type_;
run;

* --------------------------------------------------------------------------- *
*  Abnormal Return(AR),  CAR(Cumulative Abnormal Return)
*  AAR(Average AR),     CAAR(Cumulative AAR)
* -------------------------------------------------------------------------- *;
* make data set to calc. AR, CAR, AAR, CAAR ;
* event period and post event period;

data x_edset; merge edset beta; by event_num; 

   if (-30 <= event_day =< 30);            
 
run;


* AR and CAR for each event;

data x_edset; set x_edset;

   retain car 0;

   ar = ret - (alpha + beta*mkt_ret) ;

   car= car + ar;

   if event_num ne lag(event_num) then car = ar;

run;


* AAR and CAAR for average event;

proc sort data = x_edset; by event_day event_num; run;

proc means data = x_edset noprint;
  var ar;
  by  event_day;
  output out = aar(drop = _type_) mean = aar t = aar_t ;
run;

data aar; set aar; 

   retain caar 0;

   caar = caar + aar;

run;

proc export data = aar dbms = csv outfile = 'd:\event_study\aar.csv' replace; run;

* --------------------------------------------------------------------------- *
* Test Statistic for CAAR
  CAAR(-1, +1)
* -------------------------------------------------------------------------- *;

data x_edset; merge edset beta; by event_num; 
   if (-1 <= event_day =< 1);               
run;

data x_edset; set x_edset;
   retain car 0;
   ar = ret - (alpha + beta*mkt_ret) ;
   car= car + ar;
   if event_num ne lag(event_num) then car = ar;
run;


* mean of CAAR(-1, +1);

proc means data = x_edset noprint;
	var car;
	where event_day = 1;
	output out = caar(drop = _type_) mean = caar ; 
run;


* variance of AR_i;

proc sort  data = x_edset; by event_day event_num; run;

proc means data = x_edset noprint;
	var ar;
	by  event_day;
	output out = var_ar (drop = _type_) var = var_ar; 
run;

proc means data = var_ar noprint;
  var var_ar;
  output out = sum_var_ar(drop = _type_) sum = sum_var_ar; 
run;

data caar_t; merge caar sum_var_ar;
  t = caar/sqrt(sum_var_ar);
run;


proc print data = caar_t; var _all_; run;


proc export data = caar_t dbms = csv outfile = 'd:\event_study\car_t.csv' replace; run;




* --------------------------------------------------------------------------- *
                              End Of Event Study
* --------------------------------------------------------------------------- *
