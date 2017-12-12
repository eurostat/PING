/** 
## ctry_population {#sas_ctry_population}
Compute the cumulated population of a list of countries.

~~~sas
	%ctry_population(ctry_list, time, _pop_size_=, cds_popxctry=META_POPULATIONxCOUNTRY, clib=LIBCFG);
~~~

### Arguments
* `ctry_list` : list of desired countries defined by their ISO codes (_e.g._, list of MS in EU28);
* `time` : period of interest; 
* `cds_popxctry` : (_option_) configuration file storing the population of different countries; by default,
	it is named after the value `&G_PING_POPULATIONxCOUNTRY` (_e.g._, `META_POPULATIONxCOUNTRY`); for further 
	description, see [%meta_populationxcountry](@ref meta_populationxcountry);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.
 
### Returns
`_pop_size_` : name of the macro variable storing the output figure, _i.e._ the total (cumulated) 
	population of the given list of countries for the given year.

### Note
The table in the configuration dataset `cds_popxctry` contains in fact for each country in the EU+EFTA 
geographic area the total population for any year from 2003 on (_e.g._, what used to be `CCWGH60`). 
Considering the way `cds_popxctry` is structured, the variable `Y&time` needs to exist in the table.

### Examples

~~~sas
	%let popsize=;
	%let ctry_list=BE BG;
	%let year=2007;
	%ctry_population(&ctry_list, &year, _pop_size_=popsize);
~~~
returns (with the table defined as above): `popsize=18157207` (sum of values `10584534+7572673` above).

Run macro `%%_example_ctry_population` for more examples.

### See also
[%zone_population](@ref sas_zone_population), [%meta_populationxcountry](@ref meta_populationxcountry).
*/ /** \cond */

/* credits: grazzja, grillma */

%macro ctry_population(ctry_list	/* List of country ISO codes										(REQ) */
					, time 			/* Year of interest													(REQ) */
					, _pop_size_=	/* Name of the macro variable storing the output population size 	(REQ) */
					, cds_popxctry=	/* Configuration dataset storing population figures					(OPT) */
					, clib=			/* Name of the library storing configuration file					(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* _POP_SIZE_: check */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_pop_size_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _POP_SIZE_ not set !!!) %then 
		%goto exit;

	/* CLIB/CDS_POPXCTRY: check the population file: the name should be defined globally (e.g. 
	 * in the _startup_default_), otherwise set it locally */
	%if %macro_isblank(clib) %then %do; 			
		%if %symexist(G_PING_LIBCFG) %then 				%let clib=&G_PING_LIBCFG;
		%else											%let clib=LIBCFG/*SILCFMT*/;
	%end; 

	%if %macro_isblank(cds_popxctry) %then %do; 			
		%if %symexist(G_PING_POPULATIONxCOUNTRY) %then 	%let cds_popxctry=&G_PING_POPULATIONxCOUNTRY;
		%else											%let cds_popxctry=POPULATIONxCOUNTRY;
	%end; 

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&cds_popxctry, lib=&clib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Population dataset %upcase(&cds_popxctry) not found !!!))
		or 
		%error_handle(ErrorInputParameter, 
			%var_check(&cds_popxctry, Y&time, lib=&clib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Variable %upcase(Y&time) does not exist in dataset %upcase(&cds_popxctry) !!!)) %then 
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local l_geo	/* variable considered */
		_popsize 	/* output returned */
		TMP;		/* temporary table */	
	/* note that there may border effect when the _popsize local variable has the same name as
	 * the macro variable passed to the _popsize_ argument: SAS is a shitty language!!! */

	%let TMP=TMP%upcase(&sysmacroname);
	%if %symexist(G_PING_LAB_GEO) %then 				%let l_geo=&G_PING_LAB_GEO;
	%else												%let l_geo=geo;

	PROC SQL noprint;
		/* create a table with all desired countries and calculate the total aggregated
		 * population for these countries */
		CREATE TABLE &TMP AS 
			SELECT DISTINCT 
				sum(Y&time) AS popsize 
			FROM &clib..&cds_popxctry AS ccwgh60 /* this name that no-one understands is legacy... */
			WHERE &l_geo in %sql_list(&ctry_list);
	
			SELECT popsize INTO:_popsize /*&_pop_size_ */
			FROM &TMP;
		run;

	data _null_;
		call symput("&_pop_size_",%sysevalf(&_popsize));
	run;

	/* clean */
	%work_clean(&TMP)

	%exit:
%mend ctry_population;


%macro _example_ctry_population();
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

	%local var  pop_file clib;
	%let var=&G_PING_LAB_GEO; /*GEO; */
	%let pop_file=&G_PING_POPULATIONxCOUNTRY;
	%let clib=&G_PING_LIBCFG;

	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */ 

	%local pop_size pop_glob pop_part;
	%let pop_size=;

	%let year=2014;
	%let ctry_code=EU28;
	%let ctry_glob=AT BE BG CY CZ DE DK EE ES FI FR EL HU IE 
					IT LT LU LV MT NL PL PT RO SE SI SK UK HR;
	%put;
	%put (i) Compare, for year &year, the aggregated population of EU28 countries: &ctry_glob;
	PROC SQL noprint;
		SELECT sum(Y&year) as pop_glob
		INTO :pop_glob
		FROM &clib..&pop_file as pop
		WHERE pop.&var in %sql_list(&ctry_glob);
		quit;
	%ctry_population(%quote(&ctry_glob), &year, _pop_size_=pop_size, cds_popxctry=&pop_file, clib=&clib);
	%put The aggregated population of EU28 countries found is: &pop_size compared to actual value: &pop_glob;
	
	%let year=2015;
	%local ctry_part tab_part dsn;
	%let tab_part=tab_example_ctry_population;
	%let dsn=LI01;
	%put;
	%ctry_find(&dsn, &year, &tab_part, ctrylst=&ctry_glob, ilib=rdb);
	%var_to_list(&tab_part, geo, _varlst_=ctry_part);
	%put (ii) Let us now consider the dataset dsn=&dsn for year=&year nd available countries: &ctry_part...;
	PROC SQL noprint;
		SELECT sum(Y&year) as pop_part
		INTO :pop_part
		FROM &clib..&pop_file as pop
		WHERE pop.&var in %sql_list(&ctry_part);
		quit;
	%ctry_population(%quote(&ctry_part), &year, _pop_size_=pop_size, cds_popxctry=&pop_file, clib=&clib);
	%put The aggregated population of available countries found is: &pop_size compared to actual value: &pop_part;

	%work_clean(&tab_part);

	%exit:
%mend _example_ctry_population;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ctry_population;  
*/

/** \endcond */
