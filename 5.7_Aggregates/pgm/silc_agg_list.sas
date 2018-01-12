/**  
## silc_agg_list {#sas_silc_agg_list}
List default aggregates calculated when estimating EU-SILC indicators in a given year. 

~~~sas
	%silc_agg_list(time, _agg_=, _eu_=, _ea_=);
~~~

### Arguments
`time` : any single year of interest.

### Returns
* `_agg_` : (_option_) variable storing the default list of aggregates to be computed
	in survey year `time`; 
* `_eu_` : (_option_) variable storing the actual aggregate (_e.g._, either EU28, or EU27, or
	EU25, ...) to be calculated in place of EU;
* `_ea_` : (_option_) variable storing the actual aggregate (_e.g._, either EA19, or EA18, or
	EA17, ...) to be calculated in place of EA.

### Example
Running for instance:

~~~sas
	%let Agg=;
	%let EU=;
	%let EA=;
	%silc_agg_list(2006, _agg_=Agg, _eu_=EU, _ea_=EA);
~~~
will return: `Agg=EA18 EA19`, `EA=EA12` and `EU=EU25`.

See `%%_example_silc_agg_list` for more examples.

### Notes
1. One at least of the parameters `_agg_`, `_eu_` or `_ea_` should be set.
2. This macro should be implemented through a metadata table, instead of being hard encoded 
as is the case now, _e.g._ something like:
|       |EU15	|EU25	|EU27	|EU28	|EA12	|EA13	|EA15	|EA16	|EA17	|EA18	|EA19   |
|------:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
|2003	| X		|       |		|	    | X	    |	    |	    |	    |	    |	    |	    | 		
|2004	|		| X	  	|		|	    | X     |	    |	    |	    |	    |	    |	    | 
|2005	|		| X	  	|		|	    | X	    |	    |	    |	    |	    |	    |	    | 		  
|2006	|		| X	  	|		|	    | X	    |	    |	    |	    |	    |	    |	    |   
|2007	|		|	  	|   X	|		|	    | X	    |	    |	    |	    |	    |	    |			  
|2008	|		|	  	|   X	|		|	    | 		| X	    |	    |	    |	    |	    |	    	  
|2009	|		|	  	|   X	|		|	    | 		|		| X	    |	    |	    |	    |
|2010	|		|	  	|   	| X		|		|		|  		| X	    |	    |	    |	    |
|2011	|		|	  	|   	| X		|		|		|  		|  		| X	    |	    |	    |
|2012	|		|	  	|   	| X		|		|		|  		|  		| X	    |	    |	    |
|2013	|		|	  	|   	| X		|		|		|  		|  		| X	    |	    |	    |
|2014	|		|	  	|   	| X		|		|		|		|  		|  		| X	    |	    |
|2015	|		|	  	|   	| X		|		|		|		|		|  		|  		| X	    |
|2016	|		|	  	|   	| X		|		|		|		|		|  		|  		| X	    |
|2017	|		|	  	|   	| X		|		|		|		|		|  		|  		| X	    | 	
|... 	|...	|...	|...	|...	|...	|...	|...	|...	|...	|...	|...	|	
should be used to retrieve the desired global variables 
	
### Reference
Eurostat [geography glossary](http://ec.europa.eu/eurostat/statistics-explained/index.php/Category:Geography_glossary).
	
### See also
[%silc_agg_process](@ref sas_silc_agg_process), [%silc_agg_compute](@ref sas_silc_agg_compute).
*/

/* credits: gjacopo */

%macro silc_agg_list(time		/* Year of interest 												(REQ) */
					, _agg_=	/* Name of the variable storing the output list of aggregate areas	(OPT) */
					, _eu_=		/* Name of the variable storing the actual EU aggregate area		(OPT) */
					, _ea_=		/* Name of the variable storing the actual EA aggregate area		(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local yearinit G_YEARINIT;
	%let G_YEARINIT=2002;

	/* TIME: check/set */
	%if %symexist(G_PING_INITIAL_YEAR) %then 	%let yearinit=&G_PING_INITIAL_YEAR;
	%else										%let yearinit=&G_YEARINIT;
	
	/* check that TIME>YEARINIT, i.e. it is in the range ]YEARINIT, infinity[ */
	%if %error_handle(ErrorInputParameter, 
			%list_length(&time) NE 1, mac=&_mac,		
			txt=%quote(!!! Only one year accepted !!!)) %then
		%goto exit;
	%else %if %error_handle(ErrorInputParameter, 
			%par_check(&time, type=INTEGER, range=&yearinit) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong types/values for input TIME period !!!)) %then
		%goto exit;

	/* _AGG_/_EU_/_EA_: check/set */
	%if %error_handle(ErrorInputParameter,
			%macro_isblank(_agg_) EQ 1 and %macro_isblank(_eu_) EQ 1 and %macro_isblank(_ea_) EQ 1, mac=&_mac,
			txt=%quote(!!! At least one of the parameters _AGG_, _EU_ or _EA_ needs to be set !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%let &_agg_=;
	/* EA18/EA19: period [2005, ????] */
	%if &time >= 2005 /* and &time<= ???? */ %then 			%let &_agg_=EA18 EA19;

	/* EU27: period [2007, ????] 
	* EU28: period [2010, ????] */
	/*%if &time < 2004 %then									%let &_agg_=&&&_agg_ EU15;
	%else %if &time <= 2006 %then							%let &_agg_=&&&_agg_ EU25;
	%else */ %if &time >= 2007 /* and &time<= ???? */ %then	%let &_agg_=&&&_agg_ EU27;
	%if &time >= 2010 /* and &time<= ???? */ %then			%let &_agg_=&&&_agg_ EU28;

	%let &_agg_=%list_unique(&&&_agg_);

	/* EA: period ]-inf, ????] */
	%if &time <= 2006 %then %do;							%let &_ea_=EA12; 
	%end;
	%else %if &time = 2007 %then %do;						%let &_ea_=EA13; 
	%end;
	%else %if &time = 2008 %then %do;						%let &_ea_=EA15;
	%end;
	%else %if &time <= 2010 %then %do;						%let &_ea_=EA16;
	%end;
	%else %if &time < 2014  %then %do;						%let &_ea_=EA17;
	%end;
	%else %if &time = 2014  %then %do;						%let &_ea_=EA18; 
	%end;
	%else /* %if &time <= ???? %then */ %do;				%let &_ea_=EA19; 
	%end;

	/* EU: period ]-inf, ????] */
	%if &time < 2004 %then %do;								%let &_eu_=EU15; 
	%end;
	%else %if &time <= 2006 %then %do;						%let &_eu_=EU25;
	%end;
	%else %if &time <= 2009 %then %do;						%let &_eu_=EU27; 
	%end;
	%else /* %if &time <= ???? %then */ %do;				%let &_eu_=EU28; 
	%end;

	%exit:
%mend silc_agg_list;

%macro _example_silc_agg_list;
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

	%local Agg EU EA
		oAgg oEU oEA;
	%let Agg=;
	%let EU=;
	%let EA=;

	%put;
	%put (i) Retrieve default aggregates for year 2006;
	%silc_agg_list(2006, _agg_=Agg, _eu_=EU, _ea_=EA);
	%let oAgg=EA18 EA19; 
	%let oEA=EA12;
	%let oEU=EU25;
	%if "&Agg"="&oAgg" and "&EU"="&oEU" and "&EA"="&oEA" %then 			
		%put OK: TEST PASSED - Default 2006 aggregates: Agg=&oAgg - EU=&oEU - EA=&oEA;
	%else 						
		%put ERROR: TEST FAILED - Wrong 2006 aggregates: Agg=&Agg - EU=&EU - EA=&EA;

	%put;
	%put (ii) Retrieve default aggregates for year 2016;
	%silc_agg_list(2016, _agg_=Agg, _eu_=EU, _ea_=EA);
	%let oAgg=EA18 EA19 EU27 EU28; 
	%let oEA=EA19;
	%let oEU=EU28;
	%if "&Agg"="&oAgg" and "&EU"="&oEU" and "&EA"="&oEA" %then 			
		%put OK: TEST PASSED - Default 2016 aggregates: Agg=&oAgg - EU=&oEU - EA=&oEA;
	%else 						
		%put ERROR: TEST FAILED - Wrong 2016 aggregates: Agg=&Agg - EU=&EU - EA=&EA;

	%exit:
%mend _example_silc_agg_list;


/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_agg_list;
*/

/** \endcond */

