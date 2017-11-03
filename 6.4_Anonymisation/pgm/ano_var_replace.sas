/** 
## ano_var_replace {#sas_ano_var_replace}
Replace some old values of (personal or household) variables with new ones for a given list
of countries and given conditions.

~~~sas
	%ano_var_replace(geo, iudb, var=, vartype=, where=, old=, new=, lib=WORK);
~~~

### Arguments
* `geo` : list of (blank separated) countries ISO-codes; note that when `geo=_ALL_`, all
	countries will be processed, _i.e._ no condition on ISO-code will be imposed;
* `iudb` : input temporary UDB table; 
* `var` : (_option_) variable to replace `.`; if empty, nothing is done (_i.e._, masking is skipped);
* `vartype` : (_option_) type of variables passed, either personal (`P`), household (`H`)
	register (`R`) or (`D`); if empty (not recommended), the first letter of the first variable 
	in `var` will be used in place of `vartype`;
* `new` : (_option_) new replacement value; if both `new` and `expr` (see below) are emtpy, the 
	macro will replace the observations with old values (defined using the `old` or `where` arguments
	below) for `var` with this `new` value; incompatible with `expr`;
* `where` : (_option_) additional `WHERE` clause used to further refine the conditions applied
	to select the values (observations) to be replaced;
* `expr` : (_option_) replacement expression; it will be used to formulate the new values for 
	`var`; incompatible with `expr`;
* `old` : (_option_) list of old values to be replaced; if both `old` and `where` are emtpy, the macro 
	will replace missing values for `var`; this is equivalent to passing `where=%quote(&var = &old)`;
* `lib` : (_option_) input library; default: `lib=WORK`.

### Return
Update the table `iudb` by replacing any/all of the variables that are passed to `var`.
	
### Note
Let us consider the variable `DB040` where 'FI20' values need to be replaced with 'FI1B'
in `UDB_D1` for FI:

~~~sas
	%let var = DB040;
	%let old='FI20';
	%let new='FI1B';
	%ano_var_replace(FI, UDB_D1, var=&var, old=&old, new=&new, lib=WORK);
~~~ 
This is actually operating the following:
~~~sas
	PROC SQL;
		Update WORK.UDB_D1
			set DB040 = 'FI1B'
		where DB040 = 'FI20' and DB020 in ('FI');
	quit;
~~~ 
Note that one could also have ran the equivalent instructions:
~~~sas
	%ano_var_replace(FI, UDB_D1, var=&var, where=%quote(&var = &old), new=&new, lib=WORK);
~~~ 

### See also
[%ano_var_round](@ref sas_ano_var_round), [%ano_var_mask](@ref sas_ano_var_mask).
*/ /** \cond */

/* credits: grazzja */

%macro ano_var_replace(geo		/* Input list of country(ies) ISO-code					(REQ) */
					, iudb		/* Input bulk dataset 									(REQ) */
					, var= 		/* List of variables to set to missing					(OPT) */
					, vartype= 	/* List of variables to set to missing					(OPT) */
					, new= 		/* New value assigned to VAR 							(OPT) */
					, expr=		/* Replacement expression								(OPT) */
					, where=	/* Where clause used to select the values to replace 	(OPT) */
					, old= 		/* Old value of VAR to replace 							(OPT) */
					, lib= 		/* Input library 										(OPT) */
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

	/* GEO/VAR : check */
	%if %macro_isblank(geo) or %macro_isblank(var)  %then 	
		%goto exit;
	%else %do;
		%let var=%upcase(&var);
		%let geo=%upcase(&geo);
	%end;

	/* ILIB/OLIB : check/default set */
	%if %macro_isblank(lib) %then 	%let lib=WORK;

	/* NEW : default set */
	%if %macro_isblank(expr) and %macro_isblank(new) %then 		%let new=.;

	/* VARTYPE : default set */
	%if %macro_isblank(vartype) %then 		%let vartype=%substr(&var,1,1);

	%if %symexist(G_DEBUG) EQ 0 %then 	%goto check_skip; 
	%else %if &G_DEBUG EQ 0 %then 		%goto check_skip; 

	%local _lvar;
 	%let _lvar=;

	/* VAR : check */
	%if %error_handle(ErrorInputParameter,
			%list_length(&var) GT 1, mac=&_mac,
			txt=%quote(!!! Only one variable can be passed in VAR !!!)) %then 
		%goto exit;	

	/* NEW/EXPR : check */
	%if %error_handle(ErrorInputParameter,
			%macro_isblank(new) NE 1 and %macro_isblank(expr) NE 1, mac=&_mac,
			txt=%quote(!!! Incompatible options EXPR and NEW !!!)) %then 
		%goto exit;	

	/* IUDB : check */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&iudb, lib=&lib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Input dataset %upcase(&iudb) not found !!!)) %then
		%goto exit;

  %put in &_mac: ds_contents;
  %ds_contents(&iudb, _varlst_=_lvar, lib=&lib);
  %put %list_difference(&var, &_lvar);
  %put in &_mac: error_handle: &var AND &_lvar;
	%if %error_handle(ErrorInputParameter,
			%list_difference(&var, &_lvar) NE , mac=&_mac,
			txt=%quote(!!! Variables &var not found in dataset %upcase(&iudb) !!!)) %then 
		%goto exit;	

	/* VARTYPE : check */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&vartype, type=CHAR, set=P H D R) EQ 0, mac=&_mac,		
			txt=%quote(!!! Wrong value for VARTYPE - Must be either P or H !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
	
	%check_skip:

	%local _v _i  _o
		typ;
	%let typ=;

	/* use %var_info instead */
	data _null_;
	   	dsid = open("&lib..&iudb",'i', , 'D'); 
		pos = varnum(dsid, "&var");
		typ = vartype(dsid, pos);
		call symput("typ",compress(typ,,'s'));
	run;

	PROC SQL;
		UPDATE &lib..&iudb
		SET 	
			%if not %macro_isblank(new) %then %do;
				%if "&typ"="C" and not (%sysfunc(find(&new,%str(%"))) or %sysfunc(find(&new,%str(%')))) %then %do;
					&var = "&new" 
				%end;
				%else %do;
					&var = &new
				%end;
			%end;
			%else %if not %macro_isblank(expr) %then %do;
				&var = &expr
			%end;
	 	WHERE 
			%if "&geo"^="_ALL_" %then %do;
				&vartype.B020 in %sql_list(&geo) 
				%if not (%macro_isblank(where) and %macro_isblank(old)) %then %do;
					AND
				%end;
			%end;
			%if not %macro_isblank(where) %then %do;
				&where
				%if not %macro_isblank(old) %then %do;
					AND
				%end;
			%end;
			%if not %macro_isblank(old) %then %do;
				&var in %sql_list(&old) 
			%end;
			;
	quit;

	%exit:
%mend ano_var_replace;

%macro _example_ano_var_replace;
	/*%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;*/

	%local year nyear;

	DATA UDB_H1;
		HB020='SI'; HH030=10; oHH030=6; 	HX040=10; oHX040=6; 	HH031=1920; oHH031=1945; 	value=0; output;
		HB020='SI'; HH030=2; oHH030=2; 		HX040=2; oHX040=2; 		HH031=1980; oHH031=1980; 	value=1; output;
		HB020='SI'; HH030=3; oHH030=3; 		HX040=3; oHX040=3; 		HH031=1930; oHH031=1945; 	value=2; output;
		HB020='PT'; HH030=6; oHH030=6; 		HX040=4; oHX040=4; 		HH031=2010; oHH031=2010; 	value=3; output;
		HB020='FR'; HH030=8; oHH030=6; 		HX040=7; oHX040=7; 		HH031=1980; oHH031=1980; 	value=4; output;
		HB020='UK'; HH030=9; oHH030=6; 		HX040=6; oHX040=6; 		HH031=1980; oHH031=1980; 	value=5; output;
		HB020='PT'; HH030=1; oHH030=1; 		HX040=0; oHX040=0; 		HH031=1920; oHH031=1945; 	value=4; output;
		HB020='SK'; HH030=2; oHH030=2; 		HX040=7; oHX040=7; 		HH031=1939; oHH031=1945; 	value=5; output;
		HB020='EE'; HH030=5; oHH030=5; 		HX040=8; oHX040=8; 		HH031=2000; oHH031=2000; 	value=4; output;
		HB020='MT'; HH030=8; oHH030=6; 		HX040=3; oHX040=3; 		HH031=1990; oHH031=1990; 	value=5; output;
		HB020='MT'; HH030=2; oHH030=2; 		HX040=10; oHX040=6; 	HH031=2000; oHH031=2000; 	value=3; output;
	run;

	%ano_var_replace(_ALL_, UDB_H1, var=HH030, where=%quote(HH030 GT 6), new=6, lib=WORK);

	%let year=16; /* e.g., %let year=%substr(2016,3,2); */
	%let nyear=%eval (2000 + &year -55);
	%ano_var_replace(PT, UDB_H1, var=HH031, new=&nyear, where=%quote(HH031 LE &nyear));
	%let nyear=%eval (2000 + &year -71);
	%ano_var_replace(SI, UDB_H1, var=HH031, new=&nyear, where=%quote(HH031 LE &nyear));
	%ano_var_replace(MT, UDB_H1, var=HX040, new=6, where=%quote(HX040 GT 6));

	DATA UDB_D1;
		DB020='FI'; DB040='FI20'; DB100=2; value=0; output;
		DB020='FI'; DB040='FI10'; DB100=1; value=1; output;
		DB020='FI'; DB040='FI20'; DB100=3; value=2; output;
		DB020='FI'; DB040='FI10'; DB100=2; value=3; output;
		DB020='FR'; DB040='FR20'; DB100=0; value=4; output;
		DB020='UK'; DB040='UK20'; DB100=-1; value=5; output;
		DB020='MT'; DB040='MT20'; DB100=4; value=0; output;
		DB020='MT'; DB040='MT10'; DB100=3; value=1; output;
		DB020='BG'; DB040='BG20'; DB100=1; value=2; output;
		DB020='HU'; DB040='HU10'; DB100=-1; value=3; output;
		DB020='FR'; DB040='FR10'; DB100=0; value=4; output;
		DB020='SK'; DB040='SK20'; DB100=-1; value=5; output;
		DB020='EE'; DB040='EE10'; DB100=2; value=4; output;
		DB020='MT'; DB040='MT30'; DB100=3; value=5; output;
	run;

	%ano_var_replace(AT BE BG CH CY DK EE EL HR HU IE IS IT LT LU LV MT NO PL RO SE SI SK UK, UDB_D1, 
		var=DB040, expr=%quote(LEFT(SUBSTR(DB040,1,3))));
	%ano_var_replace(FI, UDB_D1, var=DB040, old="FI20", new="FI1B");
	/* note that:
		%ano_var_replace(FI, tmp, var=DB040, old="FI20", new="FI1B", lib=WORK);
		%ano_var_replace(FI, tmp, var=DB040, where=%quote(DB040 EQ "FI20"), new="FI1B", lib=WORK);
	* will also work */

	%ano_var_replace(EE LV, UDB_D1, var=DB100, old=2, new=1);

	%ano_var_replace(MT, UDB_D1, var=DB100, old=3, new=2);

	%ano_var_replace(_ALL_, UDB_D1, var=value, old=0 1 2, new=-1);

%mend _example_ano_var_replace;
