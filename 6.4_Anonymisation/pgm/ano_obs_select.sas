/** 
## ano_obs_select {#sas_ano_obs_select}
Select a given observation/set of observations from a UDB dataset.

~~~sas
	%ano_obs_select(geo, time, idsn, odsn, var=, vartype=, where=, flag=, distinct=, ilib=, olib=);
~~~

### Arguments
* `geo` : list of (blank separated) countries ISO-codes; note that when `geo=_ALL_`, all
	countries will be processed, _i.e._ no condition on ISO-code will be imposed;
* `time` : year of interest; note that when `time=_ANY_`, all will be processed, _i.e._ no 
	condition on time will be imposed;
* `idsn` : (_option_) input dataset;
* `odsn` : (_option_) output dataset;
* `var` : (_option_) list of fields/variables of `idsn` upon which the extraction is performed; 
	default: `var` is empty (or `var=_ALL_`) and all variables are selected; 
* `vartype` : (_option_) type of variables passed, either personal (`P`), household (`H`)
	register (`R`) or (`D`); if empty (not recommended), the first letter of the first variable 
	in `var` will be used in place of `vartype`;
* `where` : (_option_) expression used to refine the selection (`WHERE` option); should be passed 
	with `%%str` or `%%quote`; default: empty;
* `flag` : (_option_) name of an additional flag variable (set to 1) added to the output dataset;
	default: ignored;
* `distinct` : (_option_) boolean flag (`yes/no`) set to use the `DISTINCT` option of the `PROC SQL` 
	selection procedure;
* `ilib` : (_option_) input library; default: `ilib=WORK`;
* `olib` : (_option_) output library; default: `olib=WORK`.

### Returns

### Example
Imagine one needs to create a table with UK households containing more than 10 members (`HHsize>=10`), 
_e.g._:
~~~sas
	PROC SQL:
	 	CREATE TABLE work.removeH AS 
		SELECT DISTINCT
		 	HB020, HB030,
			(1) as remove
	 	FROM pdb.udbh 
	 	WHERE HB020 = 'UK' AND HHSIZE >= 10;
	quit;
~~~

The procedure above can be ran equivalently using the following command:
~~~sas
	%ano_obs_select(UK, _ANY_, udbh, removeH, var=HB020 HB030, vartype=H, 
		where=%quote(HHSIZE>=10), flag=remove, ilib=pdb);
~~~

### See also
[%obs_select](@ref sas_obs_select), [%ano_ds_select](@ref ano_ds_select), 
[%ds_select](@ref sas_ds_select).
*/ /** \cond */

/* credits: gjacopo */

%macro ano_obs_select(geo		/* Input list of country(ies) ISO-code						(REQ) */
					, time		/* Year of interest 										(REQ) */
					, idsn		/* Input dataset from where observations are selected		(REQ) */
					, odsn		/* Output dataset where selected observations are stored 	(OPT) */
					, var=		/* Input list of variables to extract 						(OPT) */
					, vartype= 	/* Type of the variables to be set to missing				(OPT) */
					, where=	/* WHERE clause used to select the observations 			(OPT) */
					, flag=		/* Name of flag variable when requested 					(OPT) */
					, distinct= /* Boolean flag set to use DISTINCT clause 					(OPT) */
					, orderby=
					, ilib=		/* Input library 											(OPT) */
					, olib=		/* Output library 											(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;

	/************************************************************************************/
	/**                 stand-alone declarations/PING not available                    **/
	/************************************************************************************/

	/* this is what happens when PING library is not loaded: no check is performed */
	%if %symexist(G_PING_ROOTPATH) EQ 1 %then %do; 
		%macro_put(&_mac);
	%end;
	%else %if %symexist(G_PING_PGM_LIGTH_LOADED) EQ 0 %then %do; 
		%if %symexist(G_PING_PGM_LIGTH_PATH) EQ 0 %then 	
			%let G_PING_PGM_LIGTH_PATH=/ec/prod/server/sas/0eusilc/7.3_Dissemination/pgm; 
		%include "&G_PING_SETUPPATH/ping_pgm_light.sas";
	%end;
 
	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* GEO/TIME : check */
	%if %macro_isblank(geo) or %macro_isblank(time) %then 	
		%goto exit;

	/* ILIB: set default */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;

	/* OLIB: set default */
	%if %macro_isblank(olib) %then 	%let olib=WORK /*&ilib*/;

	/* VAR: default set */
	%if %macro_isblank(var) %then 	%let var=_ALL_;
	%else 							%let var=%upcase(&var);

	/* FLAG : default set */
	%if not %macro_isblank(flag) %then 	%let flag=%upcase(&flag);

	/* VARTYPE : default set */
	%if %macro_isblank(vartype) %then 	%let vartype=%substr(&var,1,1);

	/* DISTINCT: default set */
	%if %macro_isblank(distinct)  %then 	%let distinct=NO; 
	%else									%let distinct=%upcase(&distinct);

	%if %symexist(G_DEBUG) EQ 0 %then 	%goto check_skip; 
	%else %if &G_DEBUG EQ 0 %then 		%goto check_skip; 

	%local nvar;

	/* IDSN/ILIB: check the input dataset */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* VAR: check that the variables actually exist in the dataset */
	%if "&var"^="_ALL_" %then %do;
		/* format the var as desired */
		%let nvar=; 
		%sql_clause_as(&idsn, &var, _as_=nvar, lib=&ilib);
		/* check that we indeed still have sthg in there... */
		%if %error_handle(ErrorInputParameter, 
				%macro_isblank(nvar) EQ 1, mac=&_mac,		
				txt=%quote(!!! No variables selected from %upcase(&var) !!!)) %then
			%goto exit;
		/* get back to the format where variables are listed without commas */
		%let var=%sysfunc(tranwrd(%quote(&nvar), %quote(,), %quote( )));
	%end;

	/* DISTINCT: check flag */
	%if %error_handle(ErrorInputParameter, 
				%par_check(&distinct, type=CHAR, set=YES NO) NE 0,	
				txt=!!! Parameter DISTINCT is boolean flag with values in (yes/no) !!!) %then
		%goto exit;

	/* VARTYPE : check */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&vartype, type=CHAR, set=P H D R) EQ 0, mac=&_mac,		
			txt=%quote(!!! Wrong value for VARTYPE - Must be either P or H !!!)) %then
		%goto exit;

	/* ODSN/OLIB: set the default output dataset */
	%if %error_handle(ErrorOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=! Output dataset %upcase(&odsn) already exists: will be replaced!, 
			verb=warn) %then
		%goto warning;
	%warning:

	/************************************************************************************/
	/**                                 actual extraction                              **/
	/************************************************************************************/

	%check_skip:

	/* using obs_select instead: 
	%if "&geo"^="_ALL_" %then %do;
		%if not %macro_isblank(where) %then %do;
			%let where=&where AND;
		%end;
		%let where=&where &vartype.B020 in %sql_list(&geo);
	%end;
	%if "&time"^="_ANY_" %then %do;
		%if not %macro_isblank(where) %then %do;
			%let where=&where AND;
		%end;
		%let where=&where &vartype.B010 in %sql_list(&time) 
	%end;
	%obs_select(&idsn, &odsn, where=&where, var=&var, ilib =&ilib, olib =&olib);
	%if not %macro_isblank(flag) %then %do;
		%ds_alter(&odsn, add=&flag, typ=num, lib=&olib);
		%var_set(&odsn, var=&flag, values=1, ilib=&olib);
	%end;
	*/

	PROC SQL;
	 	CREATE TABLE &olib..&odsn AS 
		SELECT
			%if "&distinct"="YES" %then %do;
				DISTINCT
			%end;
			%if "&var"="_ALL_" %then %do;
				*      
			%end; 
			%else %do;
				%list_quote(&var, rep=%quote(,), mark=_EMPTY_)      
			%end; 
			%if not %macro_isblank(flag) %then %do;
				,
				(1) as &flag
			%end; 
	 	FROM &ilib..&idsn
	 	WHERE 
			%if "&geo"^="_ALL_" %then %do;
				&vartype.B020 in %sql_list(&geo) 
				%if not %macro_isblank(where) or not %macro_isblank(time) %then %do;
					AND
				%end;
			%end;
			%if "&time"^="_ANY_" %then %do;
				&vartype.B010 in %sql_list(&time) 
				%if not %macro_isblank(where) %then %do;
					AND
				%end;
			%end;
			%if not %macro_isblank(where) %then %do;
				&where
			%end;
		;
	quit;

%mend ano_obs_select;

%macro _example_ano_obs_select;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	%put !!! &sysmacroname - Not implemented yet !!!;
%mend _example_ano_obs_select;
