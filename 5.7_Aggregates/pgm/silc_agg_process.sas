/**  
## silc_agg_process {#sas_silc_agg_process}
Legacy "EUVALS"-based code that calculates: (i) as many EU aggregates of (ii) as many 
indicators over (iii) as many years, as desired, possibly imputing data for missing countries 
from past years. 

~~~sas
	%silc_agg_process(indicators, aggregates, years, geo2geo=, ex_ctry=,
			max_yback=0, thr_min=0.7, thr_cum=0, ilib=WORK, olib=WORK);
~~~

### Arguments
* `indicators` : list of indicators, _i.e._ names of the datasets that store the indicators; 
	aggregates will be estimated over the `aggregates` areas and during the `years` period;
* `aggregates` : list of geographical areas, _e.g._ EU28, EA, ...;
* `years` : list of year(s) of interest;
* `geo2geo` : (_option_) list of correspondance rule that will enable you to copy the observations
	of a given aggregate into another one; it will take the form `((ogeo1=igeo1) (ogeo1=ogeo2) ...)`
	where all observations `igeo1` are copied (while preserved) to `ogeo1` in the output table,
	ibid for `igeo2` and `ogeo2`, _etc_...; note that the outermost parentheses `(...)` are not
	necessary; default: `geo2geo` is empty, _i.e._ no copy is operated; see 
	[%obs_geocopy](@ref sas_obs_geocopy) for more details;
* `ex_ctry` : (_option_)list of ISO-codes of countries that are explicitely excluded from 
	calculations; typically, Liechtenstein will be excluded from EFTA aggregate calculations of 
	EU-SILC indicators using: `ex_ctry=LI`; default: `ex_ctry` is empty, _i.e._ whatever list of 
	countries is retrieved from the metadata on population per country (see 
	[%silc_agg_compute](@ref sas_silc_agg_compute) for more details), it will be used in the
	aggregate estimation;
* `max_yback` : (_option_) number of years used for imputation of missing data; it tells how 
	to look backward in time, _i.e._ consider the `max_yback` years prior to the estimated 
	year; see [%silc_agg_compute](@ref sas_silc_agg_compute) for further details; default: 
	`max_yback=0`; 
* `thr_min` : (_option_) value (in range [0,1]) of (lower acceptable) the threshold used to 
	compare currently available population to global population; see 
	[%silc_agg_compute](@ref sas_silc_agg_compute) for further details; default: `thr_min=0.7`; 
* `thr_cum`: (_option_) value (in range [0,1]) of the (lower acceptable) threshold used to 
	compare the cumulated available population over `max_yback` years to global population; 
	see [%silc_agg_compute](@ref sas_silc_agg_compute); default: `thr_cum=0`; 
* `ilib` : (_option_) input dataset library; default (not passed or ' '): `ilib=WORK`;
* `olib` : (_option_) input dataset library; default (not passed or ' '): `olib=WORK`.

### Returns
For each input indicators in `indicators`, update the corresponding table in `ilib` with all 
aggregated values and store it (with the same name) in `olib`. 

### Example
Considering the following `PEPS01` indicator table:
| geo | time | age   | sex | unit | ivalue  | flag | unrel | n     | ntot  | totwgh |
|:---:|-----:|:-----:|:---:|:----:|--------:|:----:|------:|------:|------:|-------:| 
| AT  | 2015 | TOTAL | T   | PC   | 18.3001 |      | 0     | 2221  | 13213 | 8476450.56  |
| BE  | 2015 | TOTAL | T   | PC   | 21.0982 |      | 0     | 3103  | 14209 | 11073760.02 |
| BG  | 2015 | TOTAL | T   | PC   | 41.3311 |      | 0     | 5155  | 12031 | 7214208.95 |
| BG  | 2016 | TOTAL | T   | PC   | 40.3672 | b    | 0     | 7342  | 17788 | 7159945.97 |
| CH  | 2015 | TOTAL | T   | PC   | 18.1994 |      | 0     | 2474  | 17164 | 8107904 |
| CY  | 2015 | TOTAL | T   | PC   | 28.9414 |      | 0     | 3240  | 11966 | 843221 |
| CZ  | 2015 | TOTAL | T   | PC   | 13.9887 |      | 0     | 2184  | 17714 | 10324059.2 |
| DE  | 2015 | TOTAL | T   | PC   | 19.9646 |      | 0     | 4742  | 26379 | 80556397   |
| DK  | 2015 | TOTAL | T   | PC   | 17.7494 |      | 0     | 1197  | 13969 | 5626658.53 |
| EE  | 2015 | TOTAL | T   | PC   | 24.2108 |      | 0     | 3431  | 14558 | 1300279 |
| EL  | 2015 | TOTAL | T   | PC   | 35.7038 |      | 0     | 12145 | 34465 | 10723089 |
| ES  | 2015 | TOTAL | T   | PC   | 28.65 	|      | 0     | 8776  | 32380 | 45986380 |
| ES  | 2016 | TOTAL | T   | PC   | 27.9123 |      | 0     | 9158  | 36380 | 45953168 |
| FI  | 2015 | TOTAL | T   | PC   | 16.7624 |      | 0     | 3196  | 26433 | 5390568.68 |
| FI  | 2016 | TOTAL | T   | PC   | 16.5823 |      | 0     | 3018  | 25983 | 5404487.99  |
| FR  | 2015 | TOTAL | T   | PC   | 17.6896 |      | 0     | 4610  | 26645 | 62453275.37 |
| HR  | 2015 | TOTAL | T   | PC   | 29.0582 |      | 0     | 5538  | 17177 | 4184976 |
| HU  | 2015 | TOTAL | T   | PC   | 28.2079 |      | 0     | 5764  | 18682 | 9695142 |
| IE  | 2015 | TOTAL | T   | PC   | 26.0018 |      | 0     | 3568  | 13793 | 4641897.99 |
| IS  | 2015 | TOTAL | T   | PC   | 12.9913 |      | 0     | 855   | 8604  | 316430 |
| IT  | 2015 | TOTAL | T   | PC   | 28.7108 |      | 0     | 10404 | 42987 | 60843061.04 |
| LT  | 2015 | TOTAL | T   | PC   | 29.3489 |      | 0     | 3077  | 11015 | 2921262      |
| LU  | 2015 | TOTAL | T   | PC   | 18.4715 |      | 0     | 1723  | 8767  | 514254 |
| LV  | 2015 | TOTAL | T   | PC   | 30.8766 |      | 0     | 4676  | 13923 | 1961234 |
| LV  | 2016 | TOTAL | T   | PC   | 28.5005 |      | 0     | 4374  | 13864 | 1942760 |
| MK  | 2015 | TOTAL | T   | PC   | 41.5739 |      | 0     | 5693  | 13458 | 2069751.38 |
| MT  | 2015 | TOTAL | T   | PC   | 22.4401 |      | 0     | 2516  | 11252 | 420007.95 |
| NL  | 2015 | TOTAL | T   | PC   | 16.375  |      | 0     | 2163  | 23338 | 16757719.39 |
| NO  | 2015 | TOTAL | T   | PC   | 14.9751 |      | 0     | 1516  | 15699 | 5142181.91  |
| PL  | 2015 | TOTAL | T   | PC   | 23.4404 |      | 0     | 8691  | 33652 | 37374543 |
| RO  | 2015 | TOTAL | T   | PC   | 37.3783 |      | 0     | 6345  | 17411 | 19890447.12 |
| RS  | 2015 | TOTAL | T   | PC   | 41.2957 |      | 0     | 7797  | 18270 | 7086011 |
| SI  | 2015 | TOTAL | T   | PC   | 19.1585 |      | 0     | 4417  | 26150 | 2006985.22 |
| SK  | 2015 | TOTAL | T   | PC   | 18.3874 |      | 0     | 2882  | 16181 | 5236123.99 |
| PT  | 2015 | TOTAL | T   | PC   | 26.6478 |      | 0     | 6350  | 21965 | 10374822 |
| SE  | 2015 | TOTAL | T   | PC   | 18.6015 | b    | 0     | 1614  | 14249 | 9746194.26 |
| CZ  | 2016 | TOTAL | T   | PC   | 13.3016 |      | 0     | 2193  | 18964 | 10339778.6 |
| DK  | 2016 | TOTAL | T   | PC   | 16.7469 |      | 0     | 1196  | 13846 | 5657944 |
| HU  | 2016 | TOTAL | T   | PC   | 26.2791 |      | 0     | 5362  | 18809 | 9669282 |
| PT  | 2016 | TOTAL | T   | PC   | 25.0922 |      | 0     | 7506  | 26565 | 10341330 |
| SK  | 2016 | TOTAL | T   | PC   | 18.1111 |      | 0     | 3056  | 16507 | 5247463.13 |
| SI  | 2016 | TOTAL | T   | PC   | 18.4238 |      | 0     | 4023  | 25637 | 2015471.69 |
| NO  | 2016 | TOTAL | T   | PC   | 15.2872 |      | 0     | 1739  | 16899 | 5174830.98 |
| TR  | 2015 | TOTAL | T   | PC   | 41.2995 |      | 0     | 36666 | 81048 | 76368972 |
| RS  | 2016 | TOTAL | T   | PC   | 38.7272 |      | 0     | 7068  | 17720 | 7033451 |
| LT  | 2016 | TOTAL | T   | PC   | 30.1481 |      | 0     | 3056  | 10905 | 2888558 |
| EE  | 2016 | TOTAL | T   | PC   | 24.436  |      | 0     | 3578  | 15193 | 1302797 |
| PL  | 2016 | TOTAL | T   | PC   | 21.9182 |      | 0     | 8089  | 32609 | 37508480.69 |
| UK  | 2015 | TOTAL | T   | PC   | 23.4504 |      | 0     | 5259  | 21242 | 63954009 |
| UK  | 2016 | TOTAL | T   | PC   | 22.184  |      | 0     | 5160  | 22205 | 64728438    |
| SE  | 2016 | TOTAL | T   | PC   | 18.2622 |      | 0     | 1697  | 14072 | 9851017 |
| CH  | 2016 | TOTAL | T   | PC   | 17.8124 |      | 0     | 2495  | 17881 | 8195862 |
| FR  | 2016 | TOTAL | T   | PC   | 18.2425 |      | 0     | 4730  | 26647 | 62837901.62 |
| DE  | 2016 | TOTAL | T   | PC   | 19.6926 |      | 0     | 4930  | 26803 | 81427111 |
| NL  | 2016 | TOTAL | T   | PC   | 16.7216 | b    | 0     | 3575  | 29559 | 16724232 |
| HR  | 2016 | TOTAL | T   | PC   | 27.9418 |      | 0     | 5980  | 19661 | 4149254 |
| MT  | 2016 | TOTAL | T   | PC   | 20.0758 |      | 0     | 2225  | 10743 | 424831.04   |
| RO  | 2016 | TOTAL | T   | PC   | 38.8253 |      | 0     | 6238  | 17355 | 19817899.94 |
| CY  | 2016 | TOTAL | T   | PC   | 27.6947 |      | 0     | 3018  | 11236 | 844559 |
| EL  | 2016 | TOTAL | T   | PC   | 35.5734 |      | 0     | 15508 | 44094 | 10651929 |
| BE  | 2016 | TOTAL | T   | PC   | 20.7181 |      | 0     | 2963  | 13773 | 11269855.71 |
| IT  | 2016 | TOTAL | T   | PC   | 29.9778 |      | 0     | 12337 | 48316 | 60500228.84 |
| IE  | 2016 | TOTAL | T   | PC   | 24.2317 |      | 0     | 3261  | 13186 | 4683666.01 |
| LU  | 2016 | TOTAL | T   | PC   | 19.8087 | b    | 0     | 1986  | 10159 | 575993.71  |
| AT  | 2016 | TOTAL | T   | PC   | 17.9541 |      | 0     | 2072  | 13049 | 8590169.38 |
| MK  | 2016 | TOTAL | T   | PC   | 41.1011 |      | 0     | 5970  | 14310 | 2072573.48 |
| DK  | 2017 | TOTAL | T   | PC   | 17.1904 |      | 0     | 1205  | 12727 | 5697896 |
| HU  | 2017 | TOTAL | T   | PC   | 25.578  |      | 0     | 5075  | 18591 | 9637338 |
then calling the macro:	

~~~sas
	%silc_agg_process(PEPS01, EU28 EU27, 2016 2015, 
		geo2geo=((EU=EU28) (EA=EA19)), max_yback=0, ilib=WORK);
~~~
will update that same table with the following estimated aggregate observations:
| geo  | time | age   | sex | unit | ivalue  | flag | unrel | n      | ntot   | totwgh |
|:----:|-----:|:-----:|:---:|:----:|--------:|:----:|------:|-------:|-------:|-------:| 
| EU28 | 2016 | TOTAL | T   | PC   | 23.4893 |      |  0    | 137631 | 593908 | 502508553.3 |
| EU27 | 2016 | TOTAL | T   | PC   | 23.4522 |      |  0    | 131651 | 574247 | 498359299.3 |
| EA19 | 2016 | TOTAL | T   | PC   | 23.0942 |      |  0    | 943744 | 18599  | 333626513.1 |
| EU   | 2016 | TOTAL | T   | PC   | 23.4893 |      |  0    | 137631 | 593908 | 502508553.3 |
| EA   | 2016 | TOTAL | T   | PC   | 23.0942 |      |  0    | 943744 | 18599  | 333626513.1 |
| EU28 | 2015 | TOTAL | T   | PC   | 23.7865 |      |  0    | 128987 | 555746 | 500491026.3 |
| EU27 | 2015 | TOTAL | T   | PC   | 23.7420 |      |  1    | 234495 | 38569  | 496306050.3 |
| EA19 | 2015 | TOTAL | T   | PC   | 23.0593 |      |  0    | 872403 | 89619  | 332480788.2 |
| EU   | 2015 | TOTAL | T   | PC   | 23.7865 |      |  0    | 128987 | 555746 | 500491026.3 |
| EA   | 2015 | TOTAL | T   | PC   | 23.0593 |      |  0    | 872403 | 89619  | 332480788.2 |
since the aggregate `EA19` needs to be estimated to fill in the `EA` value as well.  
 
Instead, it is also possible to run:
~~~sas
	%silc_agg_process(PEPS01, EU28 EU27, 2017, thr_min=0, max_yback=1, ilib=WORK);
~~~

in order to estimate 2017 aggregates while most values are missing, so as to update the table 
with the following estimated aggregate observations:
| geo  | time | age   | sex | unit | ivalue  | flag | unrel | n      | ntot   | totwgh |
|:----:|-----:|:-----:|:---:|:----:|--------:|:----:|------:|-------:|-------:|-------:| 
| EU28 | 2017 | TOTAL | T   | PC   | 23.4802 | e    | 0     | 137353 | 592571 | 502516561.3 |
| EU27 | 2017 | TOTAL | T   | PC   | 23.443	 | e    | 0     | 131373 | 572910 | 498367307.3 |

Run macro `%%_example_silc_agg_process` for more examples. 
 
### Note 
See [%silc_agg_compute](@ref sas_silc_agg_compute) and  [%silc_EUvals](@ref sas_silc_euvals)
for further details on effective computation. 
 
### References
1. World Bank [aggregation rules](http://data.worldbank.org/about/data-overview/methodologies).
2. Eurostat [geography glossary](http://ec.europa.eu/eurostat/statistics-explained/index.php/Category:Geography_glossary).

### See also
[%silc_agg_compute](@ref sas_silc_agg_compute), [%silc_EUvals](@ref sas_silc_euvals), 
[%silc_agg_list](@ref sas_silc_agg_list), [%obs_geocopy](@ref sas_obs_geocopy), 
[%ctry_select](@ref sas_ctry_select), [%zone_to_ctry](@ref sas_zone_to_ctry), 
[%var_to_list](@ref sas_var_to_list).
*/ /** \cond */

/* credits: gjacopo */

%macro silc_agg_process(indicators		/* List of indicators/datasets to aggregate 						(REQ) */
						, aggregates	/* List of geographical areas' codes 								(REQ) */
						, years			/* List of years (period) of interest 								(REQ) */
						, geo2geo=		/* List of source/destination aggregate pairs to be copied 			(OPT) */
						, max_yback=	/* Number of years to explore 										(OPT) */
						, thr_min=		/* Threshold on currently available population  					(OPT) */
						, thr_cum=		/* Threshold on cumulated available population  					(OPT) */
						/* , pdsn=			/* name of the directory storing the population file 			(OPT) */
						/* , plib=			/* name of the population library 								(OPT) */
						, ex_ctry=		/* ISO-codes of countries explicitely excluded from calculations	(OPT) */
						, ilib=			/* Input library where source indicators are stored 				(OPT) */
						, olib=			/* Output library where aggregated indicators will be saved 		(OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(indicators) or %macro_isblank(aggregates) or %macro_isblank(years) %then
		%goto exit;

	%local DEBUG VERBOSE;

	%if %macro_isblank(DEBUG) %then %do;
		%if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
		%else 								%let DEBUG=0;
	%end;

	%if %macro_isblank(VERBOSE) %then %do;
		%if %symexist(G_PING_VERBOSE) %then 	%let VERBOSE=&G_PING_VERBOSE;
		%else 									%let VERBOSE=0;
	%end;

	/* ILIB/OLIB: set default */
	%if %macro_isblank(ilib) %then %do;
		/*%if %symexist(G_PING_LIBCRDB) %then 	%let ilib=&G_PING_LIBCRDB;
		%else 								*/ 	%let ilib=WORK;
	%end;
	%if %macro_isblank(olib)	%then 			%let olib=WORK;

	%if %error_handle(WarningInputDataset, 
			"&ilib" EQ "&olib" or "%sysfunc(pathname(ilib))" EQ "%sysfunc(pathname(olib))", mac=&_mac,		
			txt=! The aggregates will be saved together with the source dataset !, verb=warn) %then
		%goto warning1;
	%warning1:

	/* INDICATORS: all test are performed in the loop below */

	/* note: all the test below are performed again in SILC_AGG_COMPUTE macro
	* still, we do it here once for all */

	/* THR_MIN/THR_CUM: set default/check  */
	%if %macro_isblank(thr_min) %then				%let thr_min=0.7; 
	%else %if %error_handle(ErrorInputParameter, 
			%par_check(&thr_min, type=NUMERIC, range=0 1, set=0 1) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong input threshold value for THR_MIN - Must be in  [0,1] !!!)) %then 
		%goto exit;

	%if %macro_isblank(thr_cum) %then				%let thr_cum=0; 
	%else %if %error_handle(ErrorInputParameter, 
			%par_check(&thr_cum, type=NUMERIC, range=0 1, set=0 1) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong input threshold value for THR_CUM - Must be in  [0,1] !!!)) %then 
		%goto exit;

	/* MAX_YBACK: set default */
	%if %macro_isblank(max_yback) %then				%let max_yback=0;

	%if %error_handle(ErrorInputParameter, 
			"&max_yback" NE "_ALL_" and %par_check(&max_yback, type=INTEGER, range=0, set=0) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for MAX_YBACK - Must be _ALL_ or an int in  [0,inf[ !!!)) %then 
		%goto exit;

	/* PDSN/PLIB: check/set
	%if %macro_isblank(pdsn) %then 					%let pdsn=meta_populationxcountry; 
	%if %macro_isblank(plib) %then %do;
		%let plib=&G_PING_LIBCFG;
	%end; */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local l_TIME l_GEO; /* pair of (TIME,GEO) labels used in the datasets */
	%if %symexist(G_PING_LAB_TIME) %then 			%let l_TIME=&G_PING_LAB_TIME;
	%else											%let l_TIME=TIME;
	%if %symexist(G_PING_LAB_GEO) %then 			%let l_GEO=&G_PING_LAB_GEO;
	%else											%let l_GEO=GEO;

	%local __ans					/* dummy boolean flag used to test dataset existence */
		 __allAreas					/* list of all aggregate areas to compute and/or copy (not just AGGREGATES) */
		__allCtries 				/* list of all (merged) countries needed to compute all aggregates (in _ALLAREAS) */
		_indTMPin 					/* name of temporary input table storing all countries needed for aggregate calculation */
		_indTMPout					/* name of temporary output table storing calculated aggregate */
		__yy __year nyears			/* temporary vars used to loop through the NYEARS items in YEARS */
		__i __ind nindicators		/* temporary vars used to loop through the NINDICATORS items in INDICATORS */
		__a __agg naggregates 		/* temporary vars used to loop through the NAGGREGATES items in AGGREGATES */
		__g2g __geo2geo ngeo2geo	/* temporary vars used to loop through the NGEO2GEO items in GEO2GEO */
		__igeo __ogeo				/* temporary vars used as (input,output) pairs of GEO2GEO */
		_anythingHasBeenAdded		/* dummy boolean flag set when one calculation takes place at least */
		_outputHasBeenCreated		/* dummy boolean flag set when the output dataset is created in this macro */
		;
	%let _anythingHasBeenAdded=NO;
	%let _outputHasBeenCreated=NO;

	/* properly format the list GEO2GEO of geo-to-geo strings (and count if any) and
	* count the number of elements in it */
	%if not %macro_isblank(geo2geo) %then %do;
		%let geo2geo=%clist_unquote(%quote(&geo2geo), mark=_EMPTY_);
		%let ngeo2geo=%list_length(%quote(&geo2geo), sep=%quote( ));
	%end;
	%else 
		%let ngeo2geo=0;

	/* first update the list of aggregates in case one of the input aggregate areas passed in  
	* GEO2GEO is not already presented in the list AGGREGATES
	* th create the list _ALLAREAS of all areas that will be stored in the output dataset:
	* it will contain all aggregate areas passed for computation through AGGREGATES, but 
	* also those passed as output copies through GEO2GEO (when not empty) */
	%let __allAreas=;
	%if &ngeo2geo NE 0 %then %do;
		%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
			%put;
			%put --------------------------------------------------------------------------;
			%put Checking areas concerned by GEO2GEO assignments...;
			%put --------------------------------------------------------------------------;
		%end;

		%do __g2g=1 %to &ngeo2geo;
			%let __geo2geo=%scan(&geo2geo, &__g2g);
			/* input area */
			%let __igeo=%scan(&__geo2geo, 2, %str(=));
			%if %error_handle(WarningInputParameter, 
					"%list_find(&aggregates, &__igeo)" EQ "", mac=&_mac,		
					txt=! The aggregate &__igeo will also be calculated !, verb=warn) %then
				%let aggregates=&aggregates &__igeo;
			/* output area */
			%let __ogeo=%scan(&__geo2geo, 1, %str(=));
			%let __allAreas=&__allAreas &__ogeo;
		%end;
	%end;
	%let __allAreas=%list_unique(&aggregates &__allAreas); /* actually... not used! */

	/* useful temporary variables storing the list of the lenght passed in input */
	%let nyears=%list_length(&years);
	%let naggregates=%list_length(&aggregates); /* possibly updated previously */
	%let nindicators=%list_length(&indicators);

	/* dummy names for temporary files */
	%let _indTMPin=_ITMP;
	%let _indTMPout=_OTMP;

	%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put Loop over the list of years: &years;
		%put --------------------------------------------------------------------------;
	%end;

	/* loop over the list of years... */
	%do __yy=1 %to &nyears;
		%let __year=%scan(&years, &__yy);

		%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
			%put;
			%put --------------------------------------------------------------------------;
			%put Considering year &__year...;
			%put --------------------------------------------------------------------------;
		%end;

		/* initialise the list _ALLCTRIES of all countries that are needed for computing all 
		* desired aggregates in the considered year: one such list per __YEAR, for all AGGREGATES
		* and all INDICATORS (i.e., it depends neither on AGGREGATES, nor on INDICATORS) */
		%let __allCtries=;  

		%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
			%put;
			%put --------------------------------------------------------------------------;
			%put Retrieve the list of countries that belong to the considered areas...;
			%put --------------------------------------------------------------------------;
		%end;

		/* given a single __YEAR and a list of AGGREGATES (=areas), retrieve all the countries 
		* that belong to the areas (one list of ISO-codes per area __AGG) during that time.
		* the variables _CTRYINAGG&__AGG below are set on the fly, with __AGG scanning the list of 
		* areas' codes : list of countries that belong to the &__AGG area (one for each area 
		* in AGGREGATES). 		*/
		%do __a=1 %to &naggregates;
			%let __agg=%scan(&aggregates, &__a);

			/* retrieve the list of countries from the area name: ok we may have to run this several times...
			* not optimal but the loop is better in this order */
			%local _ctryInAgg&__agg;
			%let _ctryInAgg&__agg=;
			/* retrieve, for __AGG aggregate, the list of countries in _CTRYINAGG&__AGG */
			%zone_to_ctry(&__agg, time=&__year, _ctrylst_=_ctryInAgg&__agg);
			/* for instance, for __AGG=EU28, this will result in:
			* _CTRYINAGGEU28 = AT BE BG CY CZ DE DK EE ES FI FR EL HU IE IT LT LU LV MT NL PL PT RO SE SI SK UK HR */

			%if not %macro_isblank(ex_ctry) %then %do;
				%let _ctryInAgg&__agg=%list_difference(&&_ctryInAgg&__agg, &ex_ctry);
			%end;
			
			/* we keep a single list containing (merging) all countries listed under any of the aggregate 
			* areas passed in AGGREGATES */
			%let __allCtries=%list_unique(&__allCtries &&_ctryInAgg&__agg);
		%end;

		%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
			%put;
			%put --------------------------------------------------------------------------;
			%put Loop over the list of indicators: &indicators;
			%put --------------------------------------------------------------------------;
		%end;

		/* loop over the list of indicators... */
		%do __i=1 %to &nindicators;
			%let __ind=%scan(&indicators, &__i);

			%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
				%put;
				%put --------------------------------------------------------------------------;
				%put Considering indicator &__ind...;
				%put --------------------------------------------------------------------------;
			%end;

			/* check the existence of the indicator dataset so as to avoid any further processing
			* (note that this kind of checks is actually also perfomed in SILC_AGG_COMPUTE macro) */
			%let __ans=;
			%ds_isempty(&__ind, _ans_=__ans, lib=&ilib);

			%if %error_handle(WarningInputParameter, 
					&__ans NE 0, mac=&_mac,		
					txt=! No input dataset named &__ind found in library &ilib !, verb=warn) %then
				%goto next_indicator; /* skip, do not really exit */

			/* in case the output dataset does not exist already, create it as an empty dataset: do it
			* once only for each indicator __IND (i.e. the first time we enter the loop on years, when
			* __YY=1) */
			%let __ans=;
			%ds_isempty(&__ind, _ans_=__ans, lib=&olib);

			%if NOT %error_handle(WarningOutputDataset, 
					&__ans EQ 0, mac=&_mac,		
					txt=! Output dataset &__ind exists in library &ilib - Data will be appended !, verb=warn) %then %do;
				/* create an empty output dataset */
				PROC SQL noprint;
					CREATE TABLE &olib..&__ind LIKE &ilib..&__ind; 
				quit;
				/* we could use %ds_copy with MIRROR=LIKE */
				%let _outputHasBeenCreated=YES;
			%end;

			%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
				%put;
				%put --------------------------------------------------------------------------;
				%put Creating temporary table with all necessary (country,year) data pairs...;
				%put --------------------------------------------------------------------------;
			%end;

			/* create the temporary working dataset including only the years used for imputation (that
			* is, all those in the range [__YEAR-MAX_YBACK, __YEAR]) and all the countries composing 
			* the different ("overlapped") aggregate areas in AGGREGATES */
			DATA WORK.&_indTMPin._&__ind._&__year./*%datetime_current()*/;
				SET &ilib..&__ind(WHERE=(&l_TIME>=%eval(&__year-&max_yback) and &l_TIME <=&__year 
					and &l_GEO in %sql_list(&__allCtries))); 
			run; /* i.e., one extraction per _YEAR, per _INDicator and for all AGGREGATES */

			%let __ans=;
			%ds_isempty(&_indTMPin._&__ind._&__year., _ans_=__ans, lib=WORK);
			%if %error_handle(WarningInputDataset, 
					&__ans EQ 1, mac=&_mac,		
					txt=! No data found in dataset &ilib..&__ind - Skip this year !, verb=warn) %then
				%goto next_indicator;

			%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
				%put;
				%put --------------------------------------------------------------------------;
				%put Loop over the list of aggregates: &aggregates;
				%put --------------------------------------------------------------------------;
			%end;

			/* loop over aggregates... */
			%do __a=1 %to &naggregates;
				%let __agg=%scan(&aggregates, &__a);

				%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
					%put;
					%put --------------------------------------------------------------------------;
					%put Considering aggregate &__agg...;
					%put --------------------------------------------------------------------------;
				%end;

				/* check that we actually listed at least one country in the aggregate __AGG, otherwise 
				* skip the rest of the calculation */
				%if %error_handle(WarningInputDataset, 
						%macro_isblank(_ctryInAgg&__agg) EQ 1, mac=&_mac,		
						txt=! Aggregate &__agg not recognised - Skip this aggregate !, verb=warn) %then
					%goto next_aggregate;

				%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
					%put;
					%put --------------------------------------------------------------------------;
					%put Computing aggregate &__agg of indicator &__ind in year &__year...;
					%put --------------------------------------------------------------------------;
				%end;

				/* compute the aggregate for the area __AGG, possibly imputing values from previous years, 
				* and store it (without the country data that were used for its estimation), into the
				* chosen output library */ 
				%silc_agg_compute(				&__agg
								, 				&__year
								, 				&_indTMPin._&__ind._&__year./*%datetime_current()*/	
								, 				&_indTMPout._&__ind._&__year./*%datetime_current()*/					
								, ctrylst=		&&_ctryInAgg&__agg
								, max_yback=	&max_yback
								, thr_min=		&thr_min
								, thr_cum=		&thr_cum
								, agg_only=		YES		
								, mode=			UPDATE
								, force_Nwgh=	NO
								/* , pdsn=			&pdsn */	
								/* , plib=			&plib */
								, ilib=			WORK
								, olib=			WORK
								, code=			&__ind);

				/* check whether an output dataset has been created or not; in particular, the actual
				* calculation may have been skipped in macro SILC_AGG_COMPUTE in the case there is not 
				* enough data to calculate an aggregate */
				%if %error_handle(WarningOutputDataset, 
						%ds_check(&_indTMPout._&__ind._&__year., lib=WORK) NE 0, mac=&_mac,		
						txt=! No values calculated for &ilib..&__ind - Skip this aggregate !, verb=warn) %then
					%goto next_aggregate;
				/* do we need to check whether it is empty or not?
					%let __ans=; %ds_isempty(&_indTMPout._&__ind._&__year., _ans_=__ans, lib=WORK); */

				%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
					%put;
					%put --------------------------------------------------------------------------;
					%put Updating output table with the newly estimated aggregated values...;
					%put --------------------------------------------------------------------------;
				%end;

				/* update the output table with the newly estimated aggregated value stored in the
				* output table */
				DATA &olib..&__ind;
					SET &olib..&__ind(WHERE=(not(&l_TIME=&__year and &l_GEO="&__agg")))
						WORK.&_indTMPout._&__ind._&__year/*%datetime_current()*/; 
				run;
				%let _anythingHasBeenAdded=YES;

				/* always clean your shit, in particular temporary datasets */
				%work_clean(CTRY_&_indTMPout._&__ind._&__year, /* implicitly created in SILC_AGG_COMPUTE */ 
							&_indTMPout._&__ind._&__year); 

				%next_aggregate:
			%end; /* end loop on aggregates... */

			/* still clean a bit... */
			%work_clean(&_indTMPin._&__ind._&__year./*%datetime_current()*/); 

			/* special case of copy from one aggregate into another */
			%if "&_anythingHasBeenAdded" EQ "YES" and &ngeo2geo NE 0 %then %do;
				%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
					%put;
					%put --------------------------------------------------------------------------;
					%put Applying GEO2GEO assignments...;
					%put --------------------------------------------------------------------------;
				%end;

				%do __g2g=1 %to &ngeo2geo;
					%let __geo2geo=%scan(&geo2geo, &__g2g);
					%let __ogeo=%scan(&__geo2geo, 1, %str(=));
					/* clean the output dataset in case __OGEO is already present */
					DATA &olib..&__ind;
						SET &olib..&__ind(WHERE=(not(&l_TIME=&__year and &l_GEO="&__ogeo"))); 
					run;
					/* copy all observations of __IGEO (see below) into __OGEO */
					%obs_geocopy(&__ind, /*__igeo*/%scan(&__geo2geo, 2, %str(=)), &__ogeo, 
						time=&__year, lib=&olib, replace=YES);
				%end;
			%end;

			/* update the output table 
			* this is actually done after every aggregate calculation 
			DATA &olib..&_ind;
				SET &olib..&_ind(WHERE=(not(time=&_year and geo in %sql_list(&aggregates))))
					WORK.&_indTMPout._&_ind._&_year; 
			run; */

			%next_indicator:
		%end; /* end loop on indicators... */

		%next_year:
	%end; /* end loop on years... */

	%if "&_anythingHasBeenAdded" EQ "NO" and "&_outputHasBeenCreated" EQ "YES" %then %do;
		PROC DATASETS library=&olib; DELETE &__ind;
		run;
	%end;

	%exit:
%mend silc_agg_process;


%macro _example_silc_agg_process;
	%if %symexist(G_PING_SETUPPATH) EQ 0 %then %do; 
        %if %symexist(G_PING_ROOTPATH) EQ 0 %then %do;	
			%put WARNING: !!! PING environment not set - Impossible to run &sysmacroname !!!;
			%put WARNING: !!! Set global variable G_PING_ROOTPATH to your PING install path !!!;
			%goto exit;
		%end;
		%else %do;
			%let G_PING_PROJECT=	0EUSILC;
        	%let G_PING_SETUPPATH=&G_PING_ROOTPATH./PING; 
			%let G_PING_DATABASE=	/ec/prod/server/sas/0eusilc;
        	%include "&G_PING_SETUPPATH/library/autoexec/_eusilc_setup_.sas";
        	%_default_setup_;
		%end;
    %end;

	%local tvalue ovalue
		_geo _time _max_year
		_a _agg _yy _year _ii
		_geo2ge _ngeo; 

	/* original source indicator */
	DATA xPeps01;
		geo="AT  "; time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=19.150537375; iflag=""; unrel=0; n=2299; ntot=12982; totwgh=8403374.3246; output;
		geo="AT";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.30013667;  iflag=""; unrel=0; n=2221; ntot=13213; totwgh=8476450.5605; output;
		geo="BE";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=21.230028143; iflag=""; unrel=0; n=3191; ntot=14346; totwgh=11019204.643; output;
		geo="BE";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=21.098161456; iflag=""; unrel=0; n=3103; ntot=14209; totwgh=11073760.023; output;
		geo="BG";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=40.087164957; iflag="b"; unrel=0; n=5136; ntot=12184; totwgh=7255761.5112; output;
		geo="BG";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=41.331116429; iflag=""; unrel=0; n=5155; ntot=12031; totwgh=7214208.9494; output;
		geo="BG";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=40.367240793; iflag="b"; unrel=0; n=7342; ntot=17788; totwgh=7159945.9711; output;
		geo="CH";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.199411908; iflag=""; unrel=0; n=2474; ntot=17164; totwgh=8107903.9994; output;
		geo="CY";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=27.416232332; iflag=""; unrel=0; n=3169; ntot=12027; totwgh=854175.00046; output;
		geo="CY";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=28.941424323; iflag=""; unrel=0; n=3240; ntot=11966; totwgh=843220.99972; output;
		geo="CZ";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=14.8485975;   iflag=""; unrel=0; n=2329; ntot=18210; totwgh=10315418.801; output;
		geo="CZ";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=13.988683088; iflag=""; unrel=0; n=2184; ntot=17714; totwgh=10324059.201; output;
		geo="DE";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=20.638601135; iflag=""; unrel=0; n=4842; ntot=26499; totwgh=79985671.001; output;
		geo="DE";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=19.964605554; iflag=""; unrel=0; n=4742; ntot=26379; totwgh=80556397.001; output;
		geo="DK";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=17.927075087; iflag=""; unrel=0; n=1174; ntot=14075; totwgh=5609556.9736; output;
		geo="DK";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=17.749410329; iflag=""; unrel=0; n=1197; ntot=13969; totwgh=5626658.5346; output;
		geo="EE";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=25.955162568; iflag="b"; unrel=0; n=3770; ntot=15051; totwgh=1303400; output;
		geo="EE";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=24.210814082; iflag=""; unrel=0; n=3431; ntot=14558; totwgh=1300279; output;
		geo="EL";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=36.018819281; iflag=""; unrel=0; n=7386; ntot=20995; totwgh=10785312; output;
		geo="EL";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=35.703780135; iflag=""; unrel=0; n=12145; ntot=34465; totwgh=10723088.999; output;
		geo="ES";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=29.15050205;  iflag=""; unrel=0; n=9031; ntot=31622; totwgh=45976643.999; output;
		geo="ES";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=28.649968121; iflag=""; unrel=0; n=8776; ntot=32380; totwgh=45986380.002; output;
		geo="ES";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=27.912267078; iflag=""; unrel=0; n=9158; ntot=36380; totwgh=45953168; output;
		geo="FI";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=17.251266017; iflag=""; unrel=0; n=3443; ntot=27142; totwgh=5370906.6521; output;
		geo="FI";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=16.762426669; iflag=""; unrel=0; n=3196; ntot=26433; totwgh=5390568.6828; output;
		geo="FI";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=16.582317395; iflag=""; unrel=0; n=3018; ntot=25983; totwgh=5404487.9919; output;
		geo="FR";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.545301996; iflag=""; unrel=0; n=4923; ntot=26787; totwgh=62224953.841; output;
		geo="FR";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=17.689648076; iflag=""; unrel=0; n=4610; ntot=26645; totwgh=62453275.365; output;
		geo="HR";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=29.297509474; iflag=""; unrel=0; n=4455; ntot=14039; totwgh=4242887.8178; output;
		geo="HR";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=29.058186908; iflag=""; unrel=0; n=5538; ntot=17177; totwgh=4184976.0006; output;
		geo="HU";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=31.840594263; iflag=""; unrel=0; n=7595; ntot=22706; totwgh=9725522; output;
		geo="HU";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=28.207859153; iflag=""; unrel=0; n=5764; ntot=18682; totwgh=9695142; output;
		geo="IE";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=27.73285749;  iflag=""; unrel=0; n=3997; ntot=14078; totwgh=4612348.08; output;
		geo="IE";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=26.00181439;  iflag=""; unrel=0; n=3568; ntot=13793; totwgh=4641897.989; output;
		geo="IS";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=11.224150662; iflag=""; unrel=0; n=763; ntot=8841; totwgh=311002.06972; output;
		geo="IS";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=12.991347744; iflag=""; unrel=0; n=855; ntot=8604; totwgh=316430; output;
		geo="IT";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=28.282254351; iflag=""; unrel=0; n=11548; ntot=47136; totwgh=60623575.041; output;
		geo="IT";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=28.710800082; iflag=""; unrel=0; n=10404; ntot=42987; totwgh=60843061.041; output;
		geo="LT";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=27.31991553;  iflag=""; unrel=0; n=3154; ntot=11898; totwgh=2943471.9992; output;
		geo="LT";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=29.348933177; iflag=""; unrel=0; n=3077; ntot=11015; totwgh=2921262; output;
		geo="LU";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=19.003877279; iflag=""; unrel=0; n=1906; ntot=9982; totwgh=507497.9991; output;
		geo="LU";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.471532427; iflag=""; unrel=0; n=1723; ntot=8767; totwgh=514254.00203; output;
		geo="LV";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=32.669369852; iflag=""; unrel=0; n=4856; ntot=14054; totwgh=1975295; output;
		geo="LV";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=30.876643376; iflag=""; unrel=0; n=4676; ntot=13923; totwgh=1961234; output;
		geo="LV";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=28.500467621; iflag=""; unrel=0; n=4374; ntot=13864; totwgh=1942760; output;
		geo="ME";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=52.028880672; iflag=""; unrel=0; n=7461; ntot=14338; totwgh=621531.107; output;
		geo="MK";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=43.26462785;  iflag=""; unrel=0; n=5586; ntot=12610; totwgh=2066974.6994; output;
		geo="MK";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=41.573906423; iflag=""; unrel=0; n=5693; ntot=13458; totwgh=2069751.3799; output;
		geo="MT";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.794423797; iflag=""; unrel=0; n=2850; ntot=11805; totwgh=416222.9989; output;
		geo="MT";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=22.440096193; iflag=""; unrel=0; n=2516; ntot=11252; totwgh=420007.95; output;
		geo="NL";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=16.501118381; iflag=""; unrel=0; n=2180; ntot=24494; totwgh=16673801.291; output;
		geo="NL";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=16.375029558; iflag=""; unrel=0; n=2163; ntot=23338; totwgh=16757719.386; output;
		geo="NO";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=13.461246365; iflag=""; unrel=0; n=1863; ntot=18419; totwgh=5069155.1642; output;
		geo="NO";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=14.975105531; iflag=""; unrel=0; n=1516; ntot=15699; totwgh=5142181.9081; output;
		geo="PL";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=24.696736818; iflag=""; unrel=0; n=9740; ntot=36127; totwgh=37805465.378; output;
		geo="PL";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.440448868; iflag=""; unrel=0; n=8691; ntot=33652; totwgh=37374542.995; output;
		geo="PT";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=27.45750748;  iflag=""; unrel=0; n=5031; ntot=17221; totwgh=10427300.997; output;
		geo="RO";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=40.332289748; iflag=""; unrel=0; n=6621; ntot=17329; totwgh=19942642; output;
		geo="RO";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=37.378288955; iflag=""; unrel=0; n=6345; ntot=17411; totwgh=19890447.122; output;
		geo="RS";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=43.085204863; iflag=""; unrel=0; n=8365; ntot=19094; totwgh=7120232; output;
		geo="RS";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=41.295747684; iflag=""; unrel=0; n=7797; ntot=18270; totwgh=7086011.0024; output;
		geo="SE";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=16.934649562; iflag=""; unrel=0; n=1903; ntot=14026; totwgh=9660191.4062; output;
		geo="SI";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=20.416660128; iflag=""; unrel=0; n=4859; ntot=27697; totwgh=2008424.48; output;
		geo="SI";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=19.158544675; iflag=""; unrel=0; n=4417; ntot=26150; totwgh=2006985.22; output;
		geo="SK";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.402426007; iflag=""; unrel=0; n=2838; ntot=15711; totwgh=5218016.5987; output;
		geo="SK";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.387380132; iflag=""; unrel=0; n=2882; ntot=16181; totwgh=5236123.9886; output;
		geo="UK";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=24.066250916; iflag=""; unrel=0; n=5544; ntot=22474; totwgh=63455243; output;
		geo="PT";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=26.647805513; iflag=""; unrel=0; n=6350; ntot=21965; totwgh=10374822; output;
		geo="TR";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=41.630591986; iflag=""; unrel=0; n=38043; ntot=82666; totwgh=75693282.022; output;
		geo="SE";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.601494147; iflag="b"; unrel=0; n=1614; ntot=14249; totwgh=9746194.2606; output;
		geo="CZ";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=13.301550923; iflag=""; unrel=0; n=2193; ntot=18964; totwgh=10339778.599; output;
		geo="DK";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=16.746851225; iflag=""; unrel=0; n=1196; ntot=13846; totwgh=5657944.0001; output;
		geo="HU";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=26.279107384; iflag=""; unrel=0; n=5362; ntot=18809; totwgh=9669282; output;
		geo="PT";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=25.092160458; iflag=""; unrel=0; n=7506; ntot=26565; totwgh=10341330; output;
		geo="SK";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.111065451; iflag=""; unrel=0; n=3056; ntot=16507; totwgh=5247463.1269; output;
		geo="SI";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.423840525; iflag=""; unrel=0; n=4023; ntot=25637; totwgh=2015471.69; output;
		geo="NO";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=15.287239665; iflag=""; unrel=0; n=1739; ntot=16899; totwgh=5174830.9798; output;
		geo="TR";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=41.299522089; iflag=""; unrel=0; n=36666; ntot=81048; totwgh=76368972.002; output;
		geo="RS";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=38.72723752;  iflag=""; unrel=0; n=7068; ntot=17720; totwgh=7033451.0002; output;
		geo="LT";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=30.148149313; iflag=""; unrel=0; n=3056; ntot=10905; totwgh=2888557.9994; output;
		geo="CH";   time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=16.397694453; iflag="b"; unrel=0; n=2073; ntot=15651; totwgh=8020446.9995; output;
		geo="EE";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=24.436005193; iflag=""; unrel=0; n=3578; ntot=15193; totwgh=1302797; output;
		geo="PL";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=21.91815606;  iflag=""; unrel=0; n=8089; ntot=32609; totwgh=37508480.694; output;
		geo="UK";   time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.450422006; iflag=""; unrel=0; n=5259; ntot=21242; totwgh=63954009; output;
		geo="UK";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=22.183992761; iflag=""; unrel=0; n=5160; ntot=22205; totwgh=64728438; output;
		geo="SE";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.262241496; iflag=""; unrel=0; n=1697; ntot=14072; totwgh=9851017.0002; output;
		geo="CH";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=17.812414122; iflag=""; unrel=0; n=2495; ntot=17881; totwgh=8195862.0004; output;
		geo="FR";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=18.242459865; iflag=""; unrel=0; n=4730; ntot=26647; totwgh=62837901.616; output;
		geo="DE";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=19.692629665; iflag=""; unrel=0; n=4930; ntot=26803; totwgh=81427111.001; output;
		geo="NL";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=16.721634692; iflag="b"; unrel=0; n=3575; ntot=29559; totwgh=16724232; output;
		geo="HR";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=27.941834784; iflag=""; unrel=0; n=5980; ntot=19661; totwgh=4149254.0002; output;
		geo="MT";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=20.075764285; iflag=""; unrel=0; n=2225; ntot=10743; totwgh=424831.0385; output;
		geo="RO";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=38.82528902;  iflag=""; unrel=0; n=6238; ntot=17355; totwgh=19817899.941; output;
		geo="CY";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=27.694735494; iflag=""; unrel=0; n=3018; ntot=11236; totwgh=844558.99955; output;
		geo="EL";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=35.573384618; iflag=""; unrel=0; n=15508; ntot=44094; totwgh=10651929.002; output;
		geo="BE";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=20.718074849; iflag=""; unrel=0; n=2963; ntot=13773; totwgh=11269855.705; output;
		geo="IT";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=29.977842514; iflag=""; unrel=0; n=12337; ntot=48316; totwgh=60500228.844; output;
		geo="IE";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=24.231686205; iflag=""; unrel=0; n=3261; ntot=13186; totwgh=4683666.0134; output;
		geo="LU";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=19.808709705; iflag="b"; unrel=0; n=1986; ntot=10159; totwgh=575993.7133; output;
		geo="AT";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=17.954121748; iflag=""; unrel=0; n=2072; ntot=13049; totwgh=8590169.3826; output;
		geo="MK";   time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=41.101070547; iflag=""; unrel=0; n=5970; ntot=14310; totwgh=2072573.4833; output;
		geo="DK";   time=2017; age="TOTAL"; sex="T"; unit="PC"; ivalue=17.19042374; iflag=""; unrel=0; n=1205; ntot=12727; totwgh=5697896.0001; output;
		geo="HU";   time=2017; age="TOTAL"; sex="T"; unit="PC"; ivalue=25.577996746; iflag=""; unrel=0; n=5075; ntot=18591; totwgh=9637338; output;
	run;
	%ds_print(xPeps01, title="PEPS01 original country table - Excerpt");

	/* true aggregated values */
	DATA oPeps01Agg;
		geo="EA  "; time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.45804985;  iflag=""; unrel=3; n=82119; ntot=369629; totwgh=328386123.95; output;
		geo="EA18"; time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.45804985;  iflag=""; unrel=0; n=82119; ntot=369629; totwgh=328386123.95; output;
		geo="EA19"; time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.492357964; iflag=""; unrel=0; n=85273; ntot=381527; totwgh=331329595.95; output;
		geo="EU"; 	time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=24.414129242; iflag=""; unrel=3; n=129770; ntot=552697; totwgh=499342284.83; output;
		geo="EU27"; time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=24.372279798; iflag=""; unrel=0; n=125315; ntot=538658; totwgh=495099397.02; output;
		geo="EU28"; time=2014; age="TOTAL"; sex="T"; unit="PC"; ivalue=24.414129242; iflag=""; unrel=0; n=129770; ntot=552697; totwgh=499342284.83; output;
		geo="EU28"; time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.786489778; iflag=""; unrel=0; n=128987; ntot=555746; totwgh=500491026.27; output;
		geo="EU27"; time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.742037517; iflag=""; unrel=0; n=123449; ntot=538569; totwgh=496306050.27; output;
		geo="EU"; 	time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.786489778; iflag=""; unrel=3; n=128987; ntot=555746; totwgh=500491026.27; output;
		geo="EA"; 	time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.0593392;   iflag=""; unrel=3; n=87240; ntot=389619; totwgh=332480788.21; output;
		geo="EA18"; time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.003587354; iflag=""; unrel=0; n=84163; ntot=378604; totwgh=329559526.21; output;
		geo="EA19"; time=2015; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.0593392;    iflag=""; unrel=0; n=87240; ntot=389619; totwgh=332480788.21; output;
		geo="EU28"; time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.489319247; iflag=""; unrel=0; n=137631; ntot=593908; totwgh=502508553.33; output;
		geo="EU27"; time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.452248367; iflag=""; unrel=0; n=131651; ntot=574247; totwgh=498359299.33; output;
		geo="EU"; 	time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.489319247; iflag=""; unrel=3; n=137631; ntot=593908; totwgh=502508553.33; output;
		geo="EA"; 	time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.094212485; iflag=""; unrel=3; n=94374; ntot=418599; totwgh=333626513.12; output;
		geo="EA18"; time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.032605689; iflag=""; unrel=0; n=91318; ntot=407694; totwgh=330737955.12; output;
		geo="EA19"; time=2016; age="TOTAL"; sex="T"; unit="PC"; ivalue=23.094212485; iflag=""; unrel=0; n=94374; ntot=418599; totwgh=333626513.12; output;
	run;
	%ds_print(oPeps01Agg, title="PEPS01 aggregate table - Expected");

	%let _geo=EU28;
	%let _time=2016;

	%put;
	%put (i) Simple test of SILC_AGG_COMPUTE macro (declared elsewhere) on PEPS01 - Aggregate: (&_geo,&_time);
	%silc_agg_compute(&_geo, &_time, xPeps01, oPeps01, max_yback=0);
	%var_to_list(oPeps01Agg, IVALUE, _varlst_=tvalue, where=%quote(geo="&_geo" and time=&_time));
	%var_to_list(oPeps01, IVALUE, _varlst_=ovalue, where=%quote(geo="&_geo" and time=&_time));
	%if %sysevalf(%sysfunc(abs(&ovalue-&tvalue))<&G_PING_MACHINE_EPSILON) %then 			
		%put OK: TEST PASSED - PEPS01: &_geo value computed over dataset for &_time is &tvalue;
	%else 						
		%put ERROR: TEST FAILED - PEPS01: &_geo computed value is &ovalue;
		
	%put;
	%put (ii) Simple test of SILC_AGG_PROCESS macro on PEPS01 - Aggregate: (&_geo, &_time);
	DATA dumb; SET xPeps01; run;
	%let ovalue=; %let tvalue=;
	%silc_agg_process(dumb, &_geo, &_time, max_yback=0, ilib=WORK);
	%ds_print(dumb, title="PEPS01 table updated - Aggregate: (&_geo, &_time)");
	%var_to_list(oPeps01Agg, IVALUE, _varlst_=tvalue, where=%quote(geo="&_geo" and time=&_time));
	%var_to_list(dumb, IVALUE, _varlst_=ovalue, where=%quote(geo="&_geo" and time=&_time));
	%if %sysevalf(%sysfunc(abs(&ovalue-&tvalue))<&G_PING_MACHINE_EPSILON) %then 			
		%put OK: TEST PASSED - PEPS01: &_geo value computed over dataset for &_time is &tvalue;
	%else 						
		%put ERROR: TEST FAILED - PEPS01: &_geo computed value for &_time is &ovalue;

	%put;
	%let _geo=EU28 EU27;
	%let _time=2016 2015 2014;
	%put (iii) Test with multiple years and aggregates on PEPS01 - Aggregates: (&_geo, &_time);
	DATA dumb; SET xPeps01; run;
	%let ovalue=;
	%let tvalue=;
	%silc_agg_process(dumb, &_geo, &_time, max_yback=0, ilib=WORK);
	%ds_print(dumb, title="PEPS01 table updated - Aggregates: (&_geo, &_time)");
	%do _yy=1 %to %list_length(&_time);
		%let _year=%scan(&_time, &_yy);
		%do _a=1 %to %list_length(&_geo);
			%let _agg=%scan(&_geo, &_a);
			%let ovalue=; %let tvalue=;
			%var_to_list(dumb, IVALUE, _varlst_=ovalue, where=%quote(geo="&_agg" and time=&_year));
			%if %macro_isblank(ovalue) %then %goto nextcheck1;
			%var_to_list(oPeps01Agg, IVALUE, _varlst_=tvalue, where=%quote(geo="&_agg" and time=&_year));
			%if %sysevalf(%sysfunc(abs(&ovalue-&tvalue))<&G_PING_MACHINE_EPSILON) %then 			
				%put OK: TEST PASSED - PEPS01: &_agg value computed over dataset for &_year is &tvalue;
			%else 						
				%put ERROR: TEST FAILED - PEPS01: &_agg computed value for &_year is &ovalue;
			%nextcheck1:
		%end;
	%end;

	%put;
	%let _geo=EU28 EU27;
	%let _time=2017;
	%let _max_year=1;
	%put (iv) Test with imputation years on PEPS01 - Aggregates: (&_geo,&_time) - Imputation: &_max_year year;
	DATA dumb1; SET xPeps01; run;
	%let ovalue=;
	%let tvalue=;
	%silc_agg_process(dumb1, &_geo, &_time, thr_min=0/* make sure we run the test anyway*/, max_yback=&_max_year, ilib=WORK);
	%ds_print(dumb1, title="PEPS01 table updated - Aggregates: (&_geo, &_time) - Imputation: &_max_year year");

	%put;
	%let _time=2016 2015 2014;
	%let _geo2geo=(EU=EU28) (EA=EA19);
	%let _ngeo=&_geo EU EA;
	%put (v) Test with multiple years and aggregates/copies on PEPS01 - Aggregates: (&_geo,&_time) - Copy: (&_geo2geo);
	DATA dumb2; SET xPeps01; run;
	%silc_agg_process(dumb2, &_geo, &_time, geo2geo=&_geo2geo, max_yback=0, ilib=WORK);
	%ds_print(dumb2, title="PEPS01 table updated - Aggregates: (&_geo,&_time) - Copy: (&_geo2geo)");
	%do _yy=1 %to %list_length(&_time);
		%let _year=%scan(&_time, &_yy);
		%do _a=1 %to %list_length(&_ngeo);
			%let _agg=%scan(&_ngeo, &_a);
			%let ovalue=; %let tvalue=;
			%var_to_list(dumb2, IVALUE, _varlst_=ovalue, where=%quote(geo="&_agg" and time=&_year));
			%if %macro_isblank(ovalue) %then %goto nextcheck2;
			%var_to_list(oPeps01Agg, IVALUE, _varlst_=tvalue, where=%quote(geo="&_agg" and time=&_year));
			%if %sysevalf(%sysfunc(abs(&ovalue-&tvalue))<&G_PING_MACHINE_EPSILON) %then 			
				%put OK: TEST PASSED - PEPS01: &_agg value computed over dataset for &_year is &tvalue;
			%else 						
				%put ERROR: TEST FAILED - PEPS01: &_agg computed value for &_year is &ovalue;
			%nextcheck2:
		%end;
	%end;

	DATA xPeps02;
		geo="BG  "; time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=24.539736002; iflag="";  unrel=0; n=1133; ntot=4409;  totwgh=2883737.6386; output;
		geo="FI";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=4.234543496 ; iflag="";  unrel=0; n=462;  ntot=10945; totwgh=2092809.6614; output;
		geo="HU";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=18.765921602; iflag="";  unrel=0; n=1453; ntot=6956;  totwgh=4016163; output;
		geo="ES";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=15.723466013; iflag="";  unrel=0; n=1506; ntot=10961; totwgh=16674216.932; output;
		geo="DK";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=6.4224943127; iflag="";  unrel=0; n=184;  ntot=6207;  totwgh=2306609.082; output;
		geo="SI";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=9.5774901322; iflag="";  unrel=0; n=859;  ntot=10320; totwgh=801605.42; output;
		geo="IS";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=7.7391775948; iflag="";  unrel=0; n=238;  ntot=4248;  totwgh=156169.66259; output;
		geo="EE";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=11.809848587; iflag="";  unrel=0; n=721;  ntot=5989;  totwgh=582580.55993; output;
		geo="CZ";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=6.3259326165; iflag="";  unrel=0; n=428;  ntot=7331;  totwgh=4514247.5534; output;
		geo="FR";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=9.4262474651; iflag="";  unrel=0; n=913;  ntot=10141; totwgh=24813788.536; output;
		geo="SK";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=9.977699408;  iflag="";  unrel=0; n=617;  ntot=6671;  totwgh=2352867.5722; output;
		geo="LU";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=12.226011196; iflag="";  unrel=0; n=498;  ntot=3967;  totwgh=233731.08484; output;
		geo="CY";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=18.6882212;   iflag="";  unrel=0; n=769;  ntot=4355;  totwgh=337434.46283; output;
		geo="PL";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=14.502148017; iflag="";  unrel=0; n=1893; ntot=11497; totwgh=13746254.34; output;
		geo="BE";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=6.0481270929; iflag="";  unrel=0; n=362;  ntot=5291;  totwgh=4299535.9723; output;
		geo="MT";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=9.3726215826; iflag="";  unrel=0; n=405;  ntot=4319;  totwgh=170223.484; output;
		geo="NL";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=6.1030056193; iflag="";  unrel=0; n=314;  ntot=10806; totwgh=7151232.2909; output;
		geo="EL";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=22.423745241; iflag="";  unrel=0; n=2262; ntot=10095; totwgh=3329699.0261; output;
		geo="RO";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=27.745962902; iflag="";  unrel=0; n=1960; ntot=6905;  totwgh=8328134.1988; output;
		geo="MK";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=25.896106432; iflag="";  unrel=0; n=1058; ntot=4088;  totwgh=679233.68737; output;
		geo="IT";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=16.88289643;  iflag="";  unrel=0; n=2139; ntot=15772; totwgh=21938078.045; output;
		geo="LT";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=14.720476131; iflag="";  unrel=0; n=625;  ntot=4396;  totwgh=1252183.9679; output;
		geo="LV";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=16.550822743; iflag="";  unrel=0; n=946;  ntot=5292;  totwgh=820910.20467; output;
		geo="DE";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=10.106923031; iflag="";  unrel=0; n=1046; ntot=11200; totwgh=35962171.706; output;
		geo="IE";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=8.2677641286; iflag="";  unrel=0; n=400;  ntot=4635;  totwgh=1680998.8478; output;
		geo="NO";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=6.3031101485; iflag="";  unrel=0; n=294;  ntot=7295;  totwgh=2377187.0424; output;
		geo="HR";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=11.74427133;  iflag="";  unrel=0; n=668;  ntot=5206;  totwgh=1398215.196 ; output;
		geo="AT";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=9.304402112;  iflag="";  unrel=0; n=475;  ntot=5703;  totwgh=3778692.9623; output;
		geo="CH";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=8.7349960578; iflag="";  unrel=0; n=473;  ntot=7429;  totwgh=3635374.8049; output;
		geo="PT";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=14.759145007; iflag="";  unrel=0; n=1359; ntot=16118; totwgh=8119306.6706; output;
		geo="PT";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=14.759145007; iflag="";  unrel=0; n=1359; ntot=16118; totwgh=8119306.6706; output;
		geo="RS";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=23.618273382; iflag="";  unrel=0; n=1308; ntot=5075;  totwgh=2043890.5189; output;
		geo="SE";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=8.3597710628; iflag="b"; unrel=0; n=329;  ntot=6303;  totwgh=4341512.7391; output;
		geo="TR";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=27.623636076; iflag="";  unrel=0; n=7425; ntot=24065; totwgh=24007213.665; output;
		geo="UK";   time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=10.435781949; iflag="";  unrel=0; n=934;  ntot=8512;  totwgh=28555359; output;
	run;
	%ds_print(xPeps02, title="PEPS02 original country table - Excerpt");

	DATA oPeps02Agg;
		geo="EU28"; time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=12.689901187; iflag=""; unrel=0; n=27019; ntot=236420; totwgh=214601606.82; output;
		geo="EU27"; time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=12.696102749; iflag=""; unrel=0; n=26351; ntot=231214; totwgh=213203391.63; output;
		geo="EU	 "; time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=12.689901187; iflag=""; unrel=3; n=27019; ntot=236420; totwgh=214601606.82; output;
		geo="EA	 "; time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=12.128001257; iflag=""; unrel=3; n=18037; ntot=173094; totwgh=144511374.08; output;
		geo="EA18"; time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=12.105341241; iflag=""; unrel=0; n=17412; ntot=168698; totwgh=143259190.11; output;
		geo="EA19"; time=2015; age="Y18-64"; sex="T"; wstatus="EMP"; unit="PC"; ivalue=12.128001257; iflag=""; unrel=0; n=18037; ntot=173094; totwgh=144511374.08; output;
	run;
	%ds_print(oPeps02Agg, title="PEPS02 aggregate table - Expected");

	%put;
	%let _geo=EU28 EA19;
	%let _time=2015;
	%put (vi) Test with multiple indicators (PEPS01,PEPS02) - Aggregates: (&_geo,&_time);
	%silc_agg_process(xPeps01 xPeps02, &_geo, &_time, max_yback=0, ilib=WORK);
	%ds_print(xPeps01, title="PEPS01 table updated - Aggregates: (&_geo,&_time)");
	%ds_print(xPeps02, title="PEPS02 table updated - Aggregates: (&_geo,&_time)");
	%do _ii=1 %to 2; 
		%do _yy=1 %to %list_length(&_time);
			%let _year=%scan(&_time, &_yy);
			%do _a=1 %to %list_length(&_ngeo);
				%let _agg=%scan(&_ngeo, &_a);
				%let ovalue=; %let tvalue=;
				%var_to_list(xPeps0&_ii., IVALUE, _varlst_=ovalue, where=%quote(geo="&_agg" and time=&_year));
				%if %macro_isblank(ovalue) %then %goto nextcheck3;
				%var_to_list(oPeps0&_ii.Agg, IVALUE, _varlst_=tvalue, where=%quote(geo="&_agg" and time=&_year));
				%if %sysevalf(%sysfunc(abs(&ovalue-&tvalue))<&G_PING_MACHINE_EPSILON) %then 			
					%put OK: TEST PASSED - PEPS0&_ii.: &_agg value computed over dataset for &_year is &tvalue;
				%else 						
					%put ERROR: TEST FAILED - PEPS0&_ii.: &_agg computed value for &_year is &ovalue;
				%nextcheck3:
			%end;
		%end;
	%end;

	%work_clean(xPeps01, xPeps02, oPeps01Agg, oPeps02Agg, dumb, dumb1, dumb2);

	%exit:
%mend _example_silc_agg_process;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_agg_process;
*/

/** \endcond */
