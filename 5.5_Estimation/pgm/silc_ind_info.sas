/** 
## silc_ind_info {#sas_silc_ind_info}
Provide information regarding the definition/construction of EU-SILC indicators. 

~~~sas
	%silc_ind_info(ind, odsn=, _svy_=, _lib_=, _fmt_=, _var_=, _wght_=, _desc_=, olib=WORK,
					cds_varxind=META_VARIABLExINDICATOR, clib=LIBCFG);
~~~

### Arguments
* `ind` : (list of) indicator(s) whose information is requested;
* `cds_varxind, clib` : (_option_) respectively, name and library of the configuration file 
	storing the correspondance table between the various variables and indicators; by default, 
	these parameters are set to the values `&G_PING_VARIABLExINDICATOR` and `&G_PING_LIBCFG` 
	(_e.g._, `META_VARIABLExINDICATOR` and `LIBCFG` resp.); 
	see [%meta_variablexindicator](@ref meta_variablexindicator) for further description.

### Returns
* `odsn` : (_option_) name of the final output dataset created; if not set, a
* `olib` : (_option_) name of the output library used when `odsn` is passed; 
* `_svy_, _lib_` : (_option_) names of the macro variable where to return the (list of) survey(s)
	and library(ies) the indicator(s) in `ind` was (were) developed for;
* `_var_, _fmt_` : (_option_) names of the macro variables where to return, resp., the (list of)
	variable(s)  and its (their) format(s) used for the estimation of the indicator(s) in `ind`;
* `_wght_` : (_option_) name of the macro variable where to return the (list of) weights used
	for the estimation of the indicator(s) in `ind`;
* `_desc_` : (_option_) name of the macro variable where to return the (list of) indicator(s)'
	description(s)/title(s).

### Example
The instructions:

~~~sas
	%let ind=DI01 DI05 DI17;
	%silc_ind_info(&ind, odsn=odsn);
~~~
will store in the dataset `odsn` the following table:
|indicator |   survey  | lib |    EQ_INC20    |    PPP    |    RATE    |    ACTSTA    |    AGE    |    RB090    |    DB100    | weight | description                                            |
|:--------:|:---------:|:---:|:--------------:|:---------:|:----------:|:------------:|:---------:|:-----------:|:-----------:|:------:|:-------------------------------------------------------|  
|   di01   | ECHP-SILC | RDB | fmt1_EQ_INC20_ | fmt1_PPP_ | fmt1_RATE_ |              |           |             |	    	  | RB050a | Distribution of income by quantiles                    |
|   di05   | ECHP-SILC | RDB | fmt1_EQ_INC20_ | fmt1_PPP_ | fmt1_RATE_ | fmt1_ACTSTA_ | fmt1_AGE_ | fmt1_RB090_ |	    	  | PE040  | Mean and median income by most frequent activity status|
|   di17   |      SILC | RDB | fmt1_EQ_INC20_ | fmt1_PPP_ | fmt1_RATE_ |	    	  | fmt1_AGE_ | fmt1_RB090_ | fmt1_DB100_ | RB050a | Mean and median income by deg_urb status               |

Also note the specific format of the output macro variables set by the macro, depending on the number
of indicators passed in output, _e.g._:

~~~sas
	%let ind=DI01;
	%let osvy=;
	%let olib=;
	%let ovar=;
	%let ofmt=;
	%let owght=;
	%let odesc=;
	%silc_ind_info(&ind, _wght_=owght, _fmt_=ofmt, _desc_=odesc, _svy_=osvy, _lib_=olib, _var_=ovar);
~~~
will return:
* `osvy=ECHP-SILC`,
* `olib=RDB`,
* `ovar=EQ_INC20 PPP RATE`,
* `ofmt=fmt1_EQ_INC20_ fmt1_PPP_ fmt1_RATE_`,
* `owght=RB050a`,
* `odesc=Distribution of income by quantiles`,

while, if one requests information about two indicators insted of one:

~~~sas
    %let ind=DI01 DI05;
	%silc_ind_info(&ind, _wght_=owght, _fmt_=ofmt, _desc_=odesc, _svy_=osvy, _lib_=olib, _var_=ovar);
~~~
the outputs will take the form of lists between parentheses:
* `osvy=(ECHP-SILC,ECHP-SILC)`,
* `olib=(RDB,RDB)`,
* `ovar=("EQ_INC20 PPP RATE","ACTSTA AGE EQ_INC20 PPP RATE RB090")`,
* `ofmt=("fmt1_EQ_INC20_ fmt1_PPP_ fmt1_RATE_","fmt1_ACTSTA_ fmt1_AGE_ fmt1_EQ_INC20_ fmt1_PPP_ fmt1_RATE_ fmt1_RB090_")`,
* `owght=(RB050a,PE040)`,
* `odesc=("Distribution of income by quantiles","Mean and median income by most frequent activity status")`

### Note
The `cds_varxind` configuration dataset defines the correspondance table between the various 
variables and indicators. See [%meta_variablexindicator](@ref meta_variablexindicator) for more details. 
In practice, the table looks like this:
 indicator |  survey   | lib | AGE | RB090 | ARPTXX | EQ_INC20 | ... | weight | description
:---------:|:---------:|:---:|----:|------:|:------:|:--------:|:---:|:------:|:---------------------------------------------------------
   DI01    | ECHP-SILC | RDB |     |       |        |     1    | ... | RB050a | Distribution of income by quantiles      
   DI02    | ECHP-SILC | RDB |     |       |    1   |		   | ... | RB050a | Distribution of income by different income groups             
   DI03    | ECHP-SILC | RDB |  1  |   1   |        |	  1    | ... | RB050a | Mean and median income by age and gender       
   DI04    | ECHP-SILC | RDB |  1  |   1   |        |	  1    | ... | RB050a | Mean and median income by household type        
   DI05    | ECHP-SILC | RDB |  1  |   1   |        |	  1    | ... | PB040  | Mean and median income by most frequent activity status   
   ...     |    ...    | ... | ... |  ...  |   ...  |    ...   | ... |  ...   | ...

### See also
[%meta_variablexindicator](@ref meta_variablexindicator), [%silc_db_select](@ref sas_silc_db_select).
*/ /** \cond */

/* credits: grillma, grazzja */

%macro silc_ind_info(ind       		/* Name of the input indicator 				               							(REQ)*/
					, _svy_=		/* Macro variable storing the name of the survey 									(OPT)*/
					, _lib_=    	/* Macro variable storing library where the indicator is stored						(OPT)*/
					, _fmt_=    	/* Macro variable storing the formats used by the indicator							(OPT)*/
					, _desc_=  		/* Macro variable storing the description of the indicator 							(OPT)*/
					, _var_=    	/* Macro variable storing the variables used for the indicator's calculation 		(OPT)*/
					, _wght_= 		/* Macro variable storing the weight variable used in the indicator's calculation	(OPT)*/
					, odsn=    		/* Name of the output dataset														(REQ)*/
					, olib=    		/* Name of output library                                   						(OPT)*/ 
					, cds_varxind=	/* Configuration dataset storing indicator information								(OPT) */
					, clib=			/* Name of the input library storing configuration file								(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* IND: check */
	%if %error_handle(ErrorInputParameter, 
		 	%macro_isblank(ind) EQ 1, mac=&_mac,		
			txt=%bquote(!!! Input parameter IND not set !!!)) %then
		%goto exit;	

	/* _SVY_/_LIB_/_FMT_/_DESC_/_VAR_/_WGHT_/ODSN: check whether passed */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_svy_) EQ 1 and %macro_isblank(_lib_) EQ 1
			and %macro_isblank(_fmt_) EQ 1 and %macro_isblank(_desc_) EQ 1
			and %macro_isblank(_var_) EQ 1 and %macro_isblank(_wght_) EQ 1 
			and %macro_isblank(odsn) EQ 1,		
			txt=%quote(!!! Missing input parameters ODSN, _SVY_, _LIB_, _FMT_, _DESC_, _VAR_, and _WGHT_ - Set ODSN at least !!!)) %then 
		%goto exit;

	/* ODSN, OLIB : check/set */
	%if not %macro_isblank(odsn) %then %do;
		%if %macro_isblank(olib) %then	%let olib=WORK;
		%if %error_handle(ExistingOutputDataset, 
				%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,
				txt=%quote(! Output table already exist - Will be overwritten !), verb=warn) %then 
			%goto warning;
		%warning: 
	%end;

	/* CDS_VARxIND, CLIB: check/set the configuration file fo indicators */
	%if %macro_isblank(clib) %then %do;
		%if %symexist(G_PING_LIBCFG) %then 				%let clib=&G_PING_LIBCFG;
		%else											%let clib=LIBCFG;
	%end;
	%if %macro_isblank(cds_varxind) %then %do;
		%if %symexist(G_PING_VARIABLEXINDICATOR) %then 	%let cds_varxind=&G_PING_VARIABLEXINDICATOR;
		%else											%let cds_varxind=VARIABLEXINDICATOR;
	%end;

	%if %error_handle(ErrorConfigurationFile, 
			%ds_check(&cds_varxind, lib=&clib) EQ 1, mac=&_mac,		
			txt=%bquote(!!! Configuration file %upcase(&cds_varxind) not found !!!)) %then
		%goto exit;

   	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i
		_dsn
		__nind
		__varind
		_is_info _ie_info /* position of variables with generic information*/
		_is_var _ie_var
		_is_weight _ie_weight
		_is_desc _ie_desc
		__nvarind
		__info
		__desc
		__weight
		__varlen
		__varlist
		__nobs
		__lvar
		__byvar
		__where
		l_IND
		l_LIB
		l_SVEY
		l_DESC
		l_WGHT;

    %let _dsn=_TMP&_mac;
	%if %symexist(G_PING_LAB_IND) %then 		%let l_IND=&G_PING_LAB_IND;
	%else										%let l_IND=indicator;
	%if %symexist(G_PING_LAB_LIB) %then 		%let l_LIB=&G_PING_LAB_LIB;
	%else										%let l_LIB=lib;
	%if %symexist(G_PING_LAB_SVEY) %then 		%let l_SVEY=&G_PING_LAB_SVEY;
	%else										%let l_SVEY=survey;
	%if %symexist(G_PING_LAB_DESC) %then 		%let l_DESC=&G_PING_LAB_DESC;
	%else										%let l_DESC=description;
	%if %symexist(G_PING_LAB_WGHT) %then 		%let l_WGHT=&G_PING_LAB_WGHT;
	%else										%let l_WGHT=weight;
 
	/* retrieve the variables names from the configuration file */
	%ds_contents(&cds_varxind, _varlst_=__varind, lib=&clib);
	%let __nvarind=%list_length(&__varind);

	%if %error_handle(WarningInputParameter, 
			%upcase("&ind") EQ "_ALL_", mac=&_mac,		
			txt=%bquote(! All indicators are retrieved !), verb=warn) %then %do;
		%let ind=;
		%var_to_list(&cds_varxind, var=&l_IND, _varlst_=ind, lib=&clib);
	%end;

	/* count how many indicators were requested */
	%let __nind=%list_length(&ind);

	%let _is_info = 	2;
	%let _ie_info = 	4;
	%let _is_var = 		4;
	%let _ie_var = 		%eval(&__nvarind-1);
	%let _is_weight = 	%eval(&__nvarind-1);
	%let _ie_weight = 	%eval(&__nvarind-1);
	%let _is_desc = 	%eval(&__nvarind);
	%let _ie_desc = 	%eval(&__nvarind);

	/* generic info about the indicator: name(INDICATOR), SURVEY, and LIB columns */
	%let __info=%list_slice(&__varind, 	ibeg=&_is_info, 	iend=&_ie_info);
	/* list of all variables: all columns between generic info and weight variable */
	%let __var=%list_slice(&__varind, 	ibeg=&_is_var, 	iend=&_ie_var);                        
	/* weight variable: the colum before the last */
	%let __weight=%list_slice(&__varind, 	ibeg=&_is_weight,iend=&_ie_weight);  
	/* description variable: the last colum */
	%let __desc=%list_slice(&__varind, 	ibeg=&_is_desc, 	iend=&_ie_desc);    

	/* build the pivot list of variables that will be kept in the output tables (besides 
	* the variables */
	%let __byvar= %list_append(&l_IND, /**/ &__info &__desc &__weight);

	/* shape the WHERE clause that will help find the row with the desired indicator */
	%let __where = %quote(&l_IND in %sql_list(%lowcase(&ind)));

	/* check that this indicator is actually in the list of possible indicators! */
   	%obs_count(&cds_varxind, where=&__where, pct=no, lib=&clib, _ans_=__nobs);

	%if %error_handle(ErrorInputParameter, 
				&__nobs EQ 0 or %macro_isblank(__nobs) EQ 1, mac=&_mac,		
				txt=%bquote(!!! Indicator %upcase(&ind) not found in configuration file !!!)) 
			or %error_handle(ErrorInputParameter, 
				&__nobs NE &__nind, mac=&_mac,		
				txt=%bquote(!!! Indicators %upcase(&ind) mismatched in configuration file !!!)) %then
		%goto exit;

	/* proceed with the extraction from the configuration table using ds_select */
	%ds_select(&cds_varxind, &_dsn._1, where=&__where, distinct=yes, ilib=&clib, olib=WORK); 
   	/* %ds_alter(&_dsn._1, drop=&_info, lib=WORK); /* we keep the variables */ 

	/* reshape from single row to column using a transpose by _BYVAR */
    %ds_transpose(&_dsn._1, &_dsn._2, var=&__var, by=&__byvar);
 	%work_clean(&_dsn._1)

	/* in the table created this way, new variables appear: _NAME_ and COL1 
	* we could "clean" it for readability, but we skip this stage for efficiency 
	DATA &_dsn._2;
		SET &_dsn._2;
		RENAME COL1=format _NAME_=var;
	run;*/

	/* further trim the table to get rid of the variables which are not used with this
	* indicator, i.e. those for which COL1 is "empty" */
    %let __where=%str(COL1/*format*/ NE  " " and compress(COL1/*format*/) NE ".") ;
	%ds_select(&_dsn._2, &_dsn._1, where=&__where, distinct=YES);     
	%work_clean(&_dsn._2)
	
	/* retrieve the list of variables actually used by the indicator */
	%let __lvar=;
	%var_to_list(&_dsn._1, var=_NAME_/*var*/, _varlst_=__lvar, lib=WORK);
	/* count how many of them */
	%let __nvar=%list_length(&__lvar);
	%if %error_handle(WarningOutputDataset, 
			&__nvar EQ 0, mac=&_mac,		
			txt=%bquote(! No dependency found for indicator %upcase(&ind) !), verb=warn) %then
		%goto quit;

	/* now derive from the stored information the format used for the indicator, which is
	* of the generic form:	fmt<number_in_variable_column>_<name_variable_column>_ */
    DATA &_dsn._1;
		SET &_dsn._1;
	    format=('fmt'||strip(COL1/*format*/)||'_'||upcase(strip(_NAME_/*var*/))||'_');
    run; 

	/* prepare already some output... */
	%if %macro_isblank(_fmt_) EQ 0 %then %do;
		%if &__nind=1 %then %do;
			%var_to_list(&_dsn._1, var=format, _varlst_=&_fmt_, lib=WORK);
		%end;
		%else %do;
			%var_to_clist(&_dsn._1, var=format, by=&l_IND, _varclst_=&_fmt_, lib=WORK);
		%end;
	%end;
	%if %macro_isblank(_var_) EQ 0  %then %do;
		%if &__nind=1 %then %do;
			%var_to_list(&_dsn._1, var=_NAME_, _varlst_=&_var_, lib=WORK);
		%end;
		%else %do;
			%var_to_clist(&_dsn._1, var=_NAME_, by=&l_IND, _varclst_=&_var_, lib=WORK);
		%end;
	%end;

	/* transpose "back" the table using var as a pivot so as to obtain the format name under
	* the corresponding variable */
    %ds_transpose(&_dsn._1, &_dsn._2, var=format, by=&__byvar, pivot=_NAME_/*var*/);
	%work_clean(&_dsn._1); 

	/* some adjustment is still needed since the DS_TRANSPOSE macro concatenates the name of
	* the reference variable (FORMAT) and the pivot (VAR) in the name of the new variable */
	DATA &_dsn._2;
		SET &_dsn._2;
		RENAME 
		%do _i=1 %to &__nvar;
			format%scan(&__lvar, &_i)=%scan(&__lvar, &_i)
		%end;
		;
	run;

	%quit:
	/* set the output macro variables when requested */
	%if not %macro_isblank(_lib_) %then %do;
		%if &__nind=1 %then %do;
			%var_to_list(&_dsn._2, var=&l_LIB, _varlst_=&_lib_, lib=WORK);
		%end;
		%else %do;
			%var_to_clist(&_dsn._2, var=&l_LIB, _varclst_=&_lib_, lib=WORK, mark=_EMPTY_);
		%end;
	%end;
	%if not %macro_isblank(_svy_) %then %do;
		%if &__nind=1 %then %do;
			%var_to_list(&_dsn._2, var=&l_SVEY, _varlst_=&_svy_, lib=WORK);
		%end;
		%else %do;
			%var_to_clist(&_dsn._2, var=&l_SVEY, _varclst_=&_svy_, lib=WORK, mark=_EMPTY_);
		%end;
	%end;
	%if not %macro_isblank(_desc_) %then %do;
		%if &__nind=1 %then %do;
			%var_to_list(&_dsn._2, var=&l_DESC, _varlst_=&_desc_, lib=WORK);
		%end;
		%else %do;
			%var_to_clist(&_dsn._2, var=&l_DESC, _varclst_=&_desc_, lib=WORK);
		%end;
	%end;
	%if not %macro_isblank(_wght_) %then %do;
		%if &__nind=1 %then %do;
			%var_to_list(&_dsn._2, var=&l_WGHT, _varlst_=&_wght_, lib=WORK);
		%end;
		%else %do;
			%var_to_clist(&_dsn._2, var=&l_WGHT, _varclst_=&_wght_, lib=WORK, mark=_EMPTY_);
		%end;
	%end;

	%if not %macro_isblank(odsn) and &__nvar NE 0 %then %do;
		/* finally reorder the variables so as to preserve the order of the original table */
		%ds_order(&_dsn._2, odsn=&odsn, varlst=&l_IND &__info &__lvar &__weight &__desc, ilib=WORK, olib=&olib);
	%end;

	%work_clean(&_dsn._2); 

	%exit:
%mend silc_ind_info;

%macro _example_silc_ind_info ;

	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
	%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local odsn fmt avar wght fmt desc alib var svy;
	%let odsn=TMP_&sysmacroname;

    %let ind=;
	%put (o): Empty indicator;
	%silc_ind_info(&ind, odsn=&odsn);

    %let ind=DI01;
	%put (i): Empty indicator;
    %let osvy=ECHP-SILC;
    %let olib=RDB;
   	%let ovar=EQ_INC20 PPP RATE;
  	%let ofmt=fmt1_EQ_INC20_ fmt1_PPP_ fmt1_RATE_;
    %let owght=RB050a;
	%let odesc=Distribution of income by quantiles;
	%silc_ind_info(&ind, odsn=&odsn, _wght_=wght, _fmt_=fmt, _desc_=desc, _svy_=svy, _lib_=alib, _var_=avar);
	%ds_print(&odsn, title=result for indicator &ind);
	%if %quote(&wght) EQ %quote(&owght) and %quote(&fmt) EQ %quote(&ofmt) and %quote(&desc) EQ %quote(&odesc)
			and %quote(&svy) EQ %quote(&osvy) and %quote(&alib) EQ %quote(&olib) and %quote(&avar) EQ %quote(&ovar) %then 	
		%put OK: TEST PASSED - Correct information retrieved from indicator &ind;
	%else 														
		%put ERROR: TEST FAILED - Wrong information retrieved from indicator &ind;

    %let ind=DI01 DI05;
	%put (ii): Empty indicator;
   	%let osvy=(ECHP-SILC,ECHP-SILC);
    %let olib=(RDB,RDB);
 	%let ovar=("EQ_INC20 PPP RATE","ACTSTA AGE EQ_INC20 PPP RATE RB090");
	%let ofmt=("fmt1_EQ_INC20_ fmt1_PPP_ fmt1_RATE_","fmt1_ACTSTA_ fmt1_AGE_ fmt1_EQ_INC20_ fmt1_PPP_ fmt1_RATE_ fmt1_RB090_");
   	%let owght=(RB050a,PE040);
	%let odesc=("Distribution of income by quantiles ","Mean and median income by most frequent activity status");
	%silc_ind_info(&ind, odsn=&odsn, _svy_=svy, _lib_=alib, _wght_=wght, _var_=avar, _fmt_=fmt, _desc_=desc);
 	%ds_print(&odsn, title=result for indicators &ind);
	%if %quote(&wght) EQ %quote(&owght) and %quote(&fmt) EQ %quote(&ofmt) and %quote(&desc) EQ %quote(&odesc)
			and %quote(&svy) EQ %quote(&osvy) and %quote(&alib) EQ %quote(&olib) and %quote(&avar) EQ %quote(&ovar) %then 	
		%put OK: TEST PASSED - Correct information retrieved from indicator &ind;
	%else 														
		%put ERROR: TEST FAILED - Wrong information retrieved from indicator &ind;

	%let ind=DI01 DI05 DI17;
	%put;
    %put (iii): look for ind=&ind indicator;
	%silc_ind_info(&ind, odsn=&odsn);
 	%ds_print(&odsn, title=result for indicators &ind);

	*%work_clean(&odsn);

%mend _example_silc_ind_info;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_ind_info ;
*/
%_example_silc_ind_info ;

/** \endcond */
				

 /*
%let desc=;
PROC SQL noprint;
SELECT distinct description
INTO :desc  SEPARATED BY " " 
FROM WORK.test;
quit;
%put 1) desc=&desc;

%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
%let _desc_=desc;
%var_to_list(test, var=description, _varlst_=&_desc_, lib=WORK);
%put 2) desc=&desc;
*/
