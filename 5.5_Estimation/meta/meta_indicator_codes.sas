/** 
## META_INDICATOR_CODES {#meta_indicator_codes}
Generate the tables of predefined indicator codes.

### Contents
A table named after the value `&G_PING_INDICATOR_CODES` (_e.g._, `META_INDICATOR_CODES`) shall 
be defined in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as 
to contain the codes of all indicators created in production. 

In practice, the table looks like this:
 code | survey | lib 
:----:|:------:|-----:
 DI01 |	EUSILC | RDB
 DI02 |	EUSILC | RDB
 DI03 |	EUSILC | RDB
 DI04 |	EUSILC | RDB
 DI05 |	EUSILC | RDB
 di06 |	ECHP   |  .
 DI07 |	EUSILC | RDB
 di07h| ECHP   |  .
 DI08 | EUSILC | RDB
 DI09 |	EUSILC | RDB
    
### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

~~~sas
	%meta_indicator_codes(cds_ind_cod=A, cfg=B, clib=C);
~~~
Note that, by default, the command `%%meta_indicator_contents;` runs:

~~~sas
	%meta_indicator_codes(cds_ind_cod=&G_PING_INDICATOR_CODES, 
					cfg=&G_PING_ESTIMATION/meta, 
					clib=&G_PING_LIBCFG, zone=yes);
~~~

### Example
Generate the table `META_INDICATOR_CODES` in the `WORK` directory:

~~~sas
	%meta_indicator_codes(clib=WORK);
~~~

### See also
[%meta_variablexindicator](@ref meta_variablexindicator), [%meta_indicator_contents](@ref meta_indicator_contents), 
[%meta_variablexvariable](@ref meta_variablexvariable), [%meta_variable_dimension](@ref meta_variable_dimension).
*/ /** \cond */

/* credits: grazzja */

%macro meta_indicator_codes(cds_ind_cod=, cfg=, clib=);

	%if %macro_isblank(cds_ind_cod) %then %do;
		%if %symexist(G_PING_INDICATOR_CODES) %then 	%let cds_ind_cod=&G_PING_INDICATOR_CODES;
		%else											%let cds_ind_cod=META_INDICATOR_CODES;
	%end;
	
	%if %macro_isblank(clib) %then %do;
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end;

	%if %macro_isblank(cfg) %then %do;
		%if %symexist(G_PING_ESTIMATION) %then 		%let cfg=&G_PING_ESTIMATION/meta;
		%else										%let cfg=&G_PING_ROOTPATH/5.5_Estimation/meta;
	%end;

	%local FMT_CODE;
	%if %symexist(G_PING_FMT_CODE) %then 		%let FMT_CODE=&G_PING_FMT_CODE;
	%else										%let FMT_CODE=csv;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%file_import(&cds_ind_cod, fmt=&FMT_CODE, idir=&cfg, olib=&clib, 
		getnames=yes, guessingrows=_MAX_);

%mend meta_indicator_codes;


%macro _example_meta_indicator_codes;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Create the table &G_PING_VARIABLE_DIMENSION with variable<=>dimension correspondances in WORK library; 
	%meta_indicator_codes(clib=WORK);
	%ds_print(&G_PING_VARIABLE_DIMENSION);

	%put;
%mend _example_meta_indicator_codes;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_meta_indicator_codes;
*/

/** \endcond */
