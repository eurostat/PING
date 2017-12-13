/** 
## ctry_population_compare {#sas_ctry_population_compare}
Compare the population ratio of two list of countries for a given threshold.

~~~sas
	%ctry_population_compare(ctry_glob, ctry_part, time, _pop_infl_=, _ans_=, pop_thres=0.7, 
			cds_popxctry=META_POPULATIONxCOUNTRY, clib=LIBCFG);
~~~

### Arguments
* `ctry_glob, ctry_part` : two lists of (blank-separated) strings representing countries' ISO-codes; 
	in practice, countries listed in `ctry_part` are also `ctry_glob`;
* `time` : period of interest;
* `pop_thres` : (_option_) value (in range [0,1]) of the threshold to test whether:
		`pop_part / pop_glob >= pop_thres` ?	
	default to 0.7 (_i.e._ `pop_part` should be at least 70% of `pop_glob`); 
* `cds_popxctry, clib` : (_option_) respectively, name and library of the configuration file storing 
	the population of different countries; by default, these parameters are set to the values 
	`&G_PING_POPULATIONxCOUNTRY` and `&G_PING_LIBCFG`' (_e.g._, `META_POPULATIONxCOUNTRY` and `LIBCFG`
	resp.); see [%meta_populationxcountry](@ref meta_populationxcountry)	for further description.

### Returns
* `_pop_infl_` : name of the macro variables storing the 'inflation' rate between both global and
	partial population, _i.e._ the ratio `pop_glob / pop_part`;
* `_ans_` : name of the macro variables storing the result of the test whether some aggregates
	shall be computed or not, _i.e._ the result (`yes/no`) of the test:
		`pop_part / pop_glob >= pop_thres` ?

### Examples
Let us consider a large country (DE) and a small one (MT). For the area (DE,MT) and year 2010, we 
assume that only DE is available. 
Then, will a threshold of 90% of the population be reached? Considering the actual
figures (found in the `cds_popxctry` table: population of DE is: 81.802.257, that of MT is: 10.014.324) 
it seems obvious that this is actually reached. Let's check:

~~~sas
	%let ans=;
	%let pop_infl=;
	%let year=2010;
	%let thres=0.9; 	*our 90% threshold to check;
	%let ctry_part=DE;
	%let ctry_glob=DE MT;
	%ctry_population_compare(&ctry_glob, &ctry_part, &year, pop_thres=&thres, _pop_infl_=pop_infl, _ans_=ans);
~~~
returns indeed the answer `ans=yes` (and `pop_infl=1.0050613151`). Instead, let's consider another large 
country, say FR (whose population in 2010 amounts to 64.658.856):

~~~sas
	%let ctry_glob=DE FR;  *other variables unchanged;
	%ctry_population_compare(&ctry_glob, &ctry_part, &year, pop_thres=&thres, _pop_infl_=pop_infl, _ans_=ans);
~~~
returns the answer `ans=no` (and `pop_infl=1.7904151471`).

Run macro `%%_example_ctry_population_compare` for more examples.

### Note
The table `cds_popxctry` contains for each country in the EU+EFTA geographic area the total population
for any year from 2003 on (_e.g._, what used to be `CCWGH60`). 

### See also
[%ctry_population](@ref sas_ctry_population), [%zone_population](@ref sas_zone_population), 
[%population_compare](@ref sas_population_compare), [%meta_populationxcountry](@ref meta_populationxcountry).
*/ /** \cond */

/* credits: grazzja, grillma */

%macro ctry_population_compare(ctry_glob	/* Input formatted list of global country ISO-codes  			(REQ) */
							, ctry_part		/* Ibid for partial country ISO-codes  							(REQ) */
							, time 			/* period of interest 											(REQ) */
							, _pop_infl_=	/* Name of the macro variables storing the 'inflation' rate		(REQ) */
							, _ans_=		/* Name of the macro variables storing the result of the test	(REQ) */
							, cds_popxctry=	/* Configuration dataset storing population figures				(OPT) */
							, clib=			/* Name of the library storing configuration file				(OPT) */
							, pop_thres=	/* Population ratio considered as a threshold for the test		(OPT) */
							);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* _POP_INFL_/_ANS_: check */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_pop_infl_) EQ 1 and %macro_isblank(_ans_) EQ 1, mac=&_mac,		
			txt=!!! One of output macro variables _POP_INFL_ or _ANS_ needs to be set !!!) %then
		%goto exit;

	/* POP_THRES: check */
	%if %macro_isblank(pop_thres) %then %do; 			
		%if %symexist(G_PING_AGG_POP_THRESH) %then 	%let pop_thres=&G_PING_AGG_POP_THRESH;
		%else 										%let pop_thres=0.7; /* yep... */
	%end;
 
	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local ___pop_glob /* estimated global cumulated population of the countries enumerated in the list ctry_glob */
		___pop_part;	/* ibid, partial cumulated population from the list ctry_part */

	%ctry_population(%quote(&ctry_glob), &time, _pop_size_=___pop_glob, cds_popxctry=&cds_popxctry, clib=&clib);
	%ctry_population(%quote(&ctry_part), &time, _pop_size_=___pop_part, cds_popxctry=&cds_popxctry, clib=&clib);
	%population_compare(&___pop_glob, &___pop_part, _pop_infl_=&_pop_infl_, _ans_=&_ans_, 
						pop_thres=&pop_thres);

	%exit:
%mend ctry_population_compare;


%macro _example_ctry_population_compare;
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
	
	%let ctry_part=DE;
	%let ctry_glob=DE MT;
	%let year=2015;
	%let pop_thres=0.9;
	%local pop_infl run_agg;
	%ctry_population_compare(&ctry_glob, &ctry_part, &year, pop_thres=&pop_thres,
							 _pop_infl_=pop_infl, _ans_=run_agg);
	%put Let us consider a big country (DE) and a small country (MT)...;
	%put For the area (DE,MT), with only DE available, will the threshold &pop_thres be reached?;
	%put the answer is: &run_agg, with ratio=&pop_infl;

	%put;

	%exit:
%mend _example_ctry_population_compare;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ctry_population_compare;  
*/

/** \endcond */
