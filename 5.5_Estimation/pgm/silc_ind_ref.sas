/**  
## silc_ind_ref {#sas_silc_ind_ref}
List default aggregates calculated when estimating EU-SILC indicators in a given year. 

~~~sas
	%silc_ind_ref( odsn, ref=, ind=, _ref_=, _ind_=, replace=NO,
		cdsn=META_INDICATOR_CODES, clib=LIBCFG, olib=WORK);
~~~

### Arguments
* `ref` : (_option_) input list of library reference(s), _e.g._ any string(s) in `RDB`, 
	`RDB2`, `EDB`, `LDB`; incompatible with any of the parameters `ind` or `_ref_` 
	(below);
* `ind` : (_option_) input list of indicators; incompatible with any of the parameters 
	`ref` (above) or `_ind_` (below);
* `replace` : (_option_) boolean flag (`yes/no`) set when the output table `odsn` (see
	below) shall be overwritten in the case it already exists; default: `replace=NO`, _i.e._
	results will be appended to `odsn`;
* `cdsn` : (_option_) name of the metadata table containing the codes and reference
	libraries of all indicators created in production; it looks like this:
| code  | survey | lib |
|------:|:------:|:---:|
| DI01	| EUSILC | RDB |
| DI02	| EUSILC | RDB |
| DI03	| EUSILC | RDB |
| DI04	| EUSILC | RDB |
| DI05	| EUSILC | RDB |
| di06	| ECHP   |     |
| DI07	| EUSILC | RDB |
| di07h	| ECHP   |     |
| ...   |  ...   | ... |
	default: `cdsn=META_INDICATOR_CODES` (see `clib` below);
* `clib` : (_option_) library where `cdsn` is stored; default: `clib=LIBCFG`.

### Returns
* `odsn` : (_option_) excerpt of the metadata table `cdsn` where the output observations 
	are: 
		+ either all observations in `cdsn` for which the variable `lib` matches any of
		the reference library(ies) listed in `ref` when this argument is passed;
		+ or all observations in `cdsn` for which the variable `code` matches any of
		the indicator(s) listed in `ind` when this argument is passed instead;

* `_ref_` : (_option_) name of the variable storing the output list of all reference 
	libraries that contain any of the indicator(s) passed through `ind` as input; 
	incompatible with any of the parameters `ref` (above) or `_ind_` (below);
* `_ind_` : (_option_) name of the variable storing the output list of indicators contained
	in any of the library(ies) passed through `ref` as input.

### Examples
Given the table `META_INDICATOR_CODES` in `LIBCFG`, the following command:

~~~sas	
	%let list=;
	%silc_ind_ref( dsn, ind=PEPS01 E_MDDD11, _ref_=list, replace=YES);
~~~
will set `list=EDB RDB` and create the following `dsn` table:
| code      | survey    | lib |
|----------:|:---------:|:---:|
| E_MDDD11	| EUSILC	| EDB | 
| PEPS01	| EUSILC	| RDB | 

See `%%_example_silc_ind_ref` for more examples.
	
### See also
[%silc_ref2lib](@ref sas_silc_ref2lib), [%silc_agg_compute](@ref sas_silc_agg_compute).
*/

/* credits: gjacopo */

%macro silc_ind_ref( odsn
					, ref=
					, ind=
					, _ref_=
					, _ind_=
					, olib=
					, cdsn=
					, clib=
					, replace=
					);
	%local _mac;
	%let _mac=&sysmacroname;

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* REF/_IND_/_REF_/IND: check compatibility */
	%if %error_handle(ErrorInputParameter, 
				%macro_isblank(ref) EQ 1 and %macro_isblank(ind) EQ 1, mac=&_mac,
				txt=!!! At least one of the parameters IND or REF need to be set !!!) 
			or %error_handle(ErrorInputParameter, 
				%macro_isblank(ref) EQ 0 and %macro_isblank(_ref_) EQ 0, mac=&_mac,
				txt=!!! Parameters REF and _REF_ are incompatible !!!) 
			or %error_handle(ErrorInputParameter, 
				%macro_isblank(ind) EQ 0 and %macro_isblank(_ind_) EQ 0, mac=&_mac,
				txt=!!! Parameters IND and _IND_ are incompatible !!!) %then
		%goto exit;

	/* CDSN/CLIB: check/set */
	%if %macro_isblank(cdsn) %then %do;
		%if %symexist(G_PING_INDICATOR_CODES) %then 	%let cdsn=&G_PING_INDICATOR_CODES;
		%else 											%let cdsn=META_INDICATOR_CODES;
		%if %symexist(G_PING_LIBCFG) %then 				%let clib=&G_PING_LIBCFG;
		%else 											%let clib=LIBCFG/*WORK*/;
	%end;

	%if %error_handle(WarningInputDataset, 
			%ds_check(&cdsn, lib=&clib) NE 0, mac=&_mac,
			txt=%quote(!!! Metadata table &cdsn not found !!!)) %then
		%goto exit;

	/* REPLACE: check/set */
 	%if %macro_isblank(replace) %then 		%let replace=NO;
	%else 									%let replace=%upcase(&replace);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&replace, type=CHAR, set=YES NO) NE 0, mac=&_mac,
			txt=!!! Wrong boolean value for flag REPLACE - Must be YES/NO !!!) %then
		%goto exit;

	/* OLIB/ODSN: check */
	%if %macro_isblank(olib) %then %let olib=WORK;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(odsn) EQ 1, mac=&_mac,
			txt=!!! Output table not provided !!!) %then
		%goto exit;

	%if %error_handle(WarningInputDataset, 
			"&replace" EQ "NO" and %ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,
			txt=%quote(! Output table already exists - Results will be appended !), verb=warn) %then
		%goto warning;
	%warning:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local l_CODE l_LIB l_SURVEY; /* those are dependent on the contents of META_INDICATOR_CODES table */
	%if %symexist(G_PING_LAB_CODE) %then 			%let l_CODE=&G_PING_LAB_CODE;
	%else											%let l_CODE=CODE;
	%if %symexist(G_PING_LAB_LIB) %then 			%let l_LIB=&G_PING_LAB_LIB;
	%else											%let l_LIB=LIB;
	%if %symexist(G_PING_LAB_SURVEY) %then 			%let l_SURVEY=&G_PING_LAB_SURVEY;
	%else											%let l_SURVEY=SURVEY;

	%local TMP
		__input __search;
	%let TMP=__tmp;

	/* define the search query depending on the input provided */
	%if not %macro_isblank(ref) %then %do;
		%let __input=&ref;
		%let __search=%quote(&l_LIB in %sql_list(&ref) /* and &l_SURVEY="EUSILC"*/);
	%end;
	%else %do;
		%let __input=&ind;
		%let __search=%quote(&l_CODE in %sql_list(&ind) /* and &l_SURVEY="EUSILC"*/);
	%end;

	/* check that this is actually an indicator ! */
	%obs_select(&cdsn, &TMP,  where=&__search, ilib=&clib, olib=WORK);
	%if %error_handle(ErrorInputParameter, 
			%ds_check(&TMP, lib=WORK) NE 0, mac=&_mac,		
			txt=%bquote(!!! Observation(s) &__input not found in metadata table !!!)) %then
		%goto exit;
	/* do we need to check whether it is empty or not?
		%let __ans=; %ds_isempty(&TMP, _ans_=__ans, lib=WORK); */

	/* retrieve the name of the output library */
	%if not %macro_isblank(_ind_) %then %do;
		%let &_ind_=;
		%var_to_list(&TMP, &l_CODE, _varlst_=&_ind_, lib=WORK);
	%end;
	%else %if not %macro_isblank(_ref_) %then%do;
		%let &_ref_=;
		%var_to_list(&TMP, &l_LIB, _varlst_=&_ref_, lib=WORK);
	%end;

	/* update/set the output table */
	DATA &olib..&odsn;
		SET 
		%if "&replace"="NO" and %ds_check(&odsn, lib=&olib) EQ 0 %then %do;
			&olib..&odsn
		%end;
			&TMP; 
	run;

	%work_clean(&TMP);

	%exit:
%mend silc_ind_ref;

%macro _example_silc_ind_ref;
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

	%local list olist;

	%put;
	%put (i) Retrieve all indicators associated to the reference library RDB;
	%let list=;
	%silc_ind_ref( TEST1, ref=RDB, _ind_=list, replace=YES);
	%let olist=DI01 DI02 DI03 DI04 DI05 DI07 DI08 DI09 DI10 DI11 DI12 DI12b DI12c DI13 DI13b DI14 DI14b DI15 DI16 DI17 DI20 DI23 DI27 IW01 
	IW02 IW03 IW04 IW05 IW06 IW07 IW15 IW16 LI01 LI02 LI03 LI04 LI06 LI07 LI08 LI09 LI09b LI10 LI10b LI11 LI22 LI22b LI31 LI41 LI45 
	LI48 LI60 LVHL11 LVHL12 LVHL13 LVHL14 LVHL15 LVHL16 LVHL17 LVHL21 LVHL60 LVHO05a LVHO05b LVHO05c LVHO05d LVHO05q LVHO06 LVHO06q 
	LVHO07a LVHO07b LVHO07c LVHO07d LVHO07e LVHO08a LVHO08b LVHO15 LVHO16 LVHO25 LVHO26 LVHO27 LVHO28 LVHO29 LVHO30 LVHO50a LVHO50b 
	LVHO50c LVHO50d Li32 MDDD11 MDDD12 MDDD13 MDDD14 MDDD15 MDDD16 MDDD17 MDDD21 MDDD60 MDHO05 MDHO06a MDHO06b MDHO06c MDHO06q OV9B1 
	OV9B2 PEES01 PEES02 PEES03 PEES04 PEES05 PEES06 PEES07 PEES08 PEPS01 PEPS02 PEPS03 PEPS04 PEPS05 PEPS06 PEPS07 PEPS11 PEPS60 PNP10 
	PNP11 PNP2 PNP3 PNP9 PNS11 PNS2; /* !!!  Note that this may change when adding new indicators !!! */
	%if %list_difference(&list, &olist) EQ  %then 			
		%put OK: TEST PASSED - Indicators associated with reference library RDB: &olist;
	%else 						
		%put ERROR: TEST FAILED - Wrong indicators associated with reference library RDB: &list;

	%put;
	%put (i) Retrieve the reference libraries associated to the indicators PEPS01 E_MDDD11;
	%let list=;
	%silc_ind_ref( TEST2, ind=PEPS01 E_MDDD11, _ref_=list, replace=YES);
	%let olist=EDB RDB;
%put list=&list============;
	%if %list_difference(&list, &olist) EQ  %then 			
		%put OK: TEST PASSED - Reference libraries associated to indicators PEPS01 E_MDDD11: &olist;
	%else 						
		%put ERROR: TEST FAILED - Wrong reference libraries associated to indicators PEPS01 E_MDDD11: &list;

	%exit:
%mend _example_silc_ind_ref;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_ind_ref;
*/
%_example_silc_ind_ref;

/** \endcond */
