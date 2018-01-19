/** 
## population_compare {#sas_population_compare}
Compare the ratio of two populations (given as figures) with a given threshold.

~~~sas
	%population_compare(pop_den, pop_num, _pop_infl_=, _ans_=, pop_thres=0.7);
~~~

### Arguments
* `pop_den, pop_num` : two (string/numeric) variables, usually storing respectively 
	the global and partial population figures to compare;
* `pop_thres` : (_option_) value (in range [0,1]) of the threshold to test whether:
		`pop_num / pop_den >= pop_thres` ?
	default to 0.7 (_i.e._ we assume `pop_den > pop_num` and `pop_num` should be at 
	least 70% of `pop_den`).
 
### Returns
* `_pop_infl_` : name of the macro variables storing the 'inflation' rate between both 
	global and partial population, _i.e._ the ratio `pop_den / pop_num`;
* `_ans_` : name of the macro variables storing the result of the test whhether some 
	aggregates shall be computed or not, _i.e._ the result (`YES/NO`) of the test:
		`pop_num / pop_den >= pop_thres` ?

### Examples
_Alleluia!!!_
	
~~~sas
	%let pop_infl=;
	%let ans=;
	%population_compare(1, 0.1, _pop_infl_=pop_infl, _ans_=ans, pop_thres=0.2);
~~~
returns `pop_infl=10` and `ans=no`.

~~~sas
	%population_compare(1, 0.2, _pop_infl_=pop_infl, _ans_=ans, pop_thres=0.2);
~~~
returns `pop_infl=5` and `ans=yes` (note that we indeed test `>=`).

~~~sas
	%population_compare(1, 0.5, _pop_infl_=pop_infl, _ans_=ans, pop_thres=0.2);
~~~
returns `pop_infl=2` and `ans=yes`.

Run macro `%%_example_population_compare` for more examples.

### See also
[%ctry_population_compare](@ref sas_ctry_population_compare)
*/ /** \cond */

/* credits: gjacopo, marinapippi */

%macro population_compare(__pop_glob	/* Global cumulated population 									(REQ) */
						, __pop_part	/* Partial cumulated population 								(REQ) */
						, _pop_infl_=	/* Name of the macro variables storing the 'inflation' rate		(REQ) */
						, _ans_=		/* Name of the macro variables storing the result of the test	(REQ) */
						, pop_thres=	/* Population ratio considered as a threshold for the test 		(OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_pop_infl_) EQ 1 and %macro_isblank(_ans_) EQ 1, mac=&_mac,		
			txt=!!! one of the output macro variables _POP_INFL_ or _ANS_ needs to be set !!!) %then
		%goto exit;

	%if %macro_isblank(pop_thres) %then %do; 			
		%if %symexist(G_PING_AGG_POP_THRESH) %then 	%let pop_thres=&G_PING_AGG_POP_THRESH;
		%else 										%let pop_thres=0.7; /* yep... */
	%end;
 
 	%local __pop_test __pop_infl ___ans;
	/*%let ___ans=;*/
	%let __pop_infl=%sysevalf(&__pop_glob / &__pop_part);
	/*%let pop_infl_i=%sysevalf(&pop_part / &pop_glob);*/
	%let __pop_test=%sysevalf(&__pop_glob * &pop_thres);

	/* perform the test */
	%if &__pop_part >= &__pop_test %then %do;
	/* %if &pop_infl_i >= &pop_thres %then %do; */
		%let ___ans=YES;
	%end;
	%else %do;
		%let ___ans=NO;
	%end;

	/* store the results */
	data _null_;
		;
		%if not %macro_isblank(_pop_infl_) %then %do;
			call symput("&_pop_infl_",%sysevalf(&__pop_infl));
		%end;
		%if not %macro_isblank(_ans_) %then %do;
			call symput("&_ans_","&___ans");
		%end;
	run;

	%exit:
%mend population_compare;

%macro _example_population_compare();
	%if %symexist(G_PING_SETUPPATH) EQ 0 %then %do; 
        %if %symexist(G_PING_ROOTPATH) EQ 0 %then %do;	
			%put WARNING: !!! PING environment not set - Impossible to run &sysmacroname !!!;
			%put WARNING: !!! Set global variable G_PING_ROOTPATH to your PING install path !!!;
			%goto exit;
		%end;
		%else %do;
        	%let G_PING_SETUPPATH=&G_PING_ROOTPATH./PING; 
        	%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
        	%_default_setup_;
		%end;
    %end;

	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */ 

	%local pop_glob pop_part;
	%local ans pop_infl;

	%let year=2015;
	%let ctry_glob=AT BE BG CY CZ DE DK EE ES FI FR EL HU IE 
				   IT LT LU LV MT NL PL PT RO SE SI SK UK HR;
	%let ctry_part=AT BE BG CY CZ DE DK EE ES FI FR EL HU IE;
	
	%put Consider the list of countries glob=&ctry_glob and part=&ctry_part ...;
	%ctry_population(%quote(&ctry_glob), &year, _pop_size_=pop_glob);
	%ctry_population(%quote(&ctry_part), &year, _pop_size_=pop_part);
	%put the corresponding populations are: &pop_glob and &pop_part respectively;

	%let thres=0.7; /* 70% of the total EU28 population */
	%put Setting then a threshold to &thres, the ratio can be estimated ...; 
	%population_compare(&pop_glob, &pop_part, _pop_infl_=pop_infl, _ans_=ans, pop_thres=&thres);
	%put calculation will be run? &ans, while pop_infl=&pop_infl;

	%exit:
%mend _example_population_compare;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_population_compare;  
*/

/** \endcond */
