/** 
## ano_var_round {#sas_ano_var_round}
Round (personal or household) variables for a given list of countries.

~~~sas
	%ano_var_round(geo, iudb, var=, vartype=, where=, round=1, lib=WORK);
~~~

### Arguments
* `geo` : list of (blank separated) countries ISO-codes;
* `iudb` : input temporary UDB table; note that variables `DB010`, `DB020`, `&psuvar`
	and `&psuvar._F` must exist in the table;
* `var` : (_option_) list of variables to round; if empty, nothing is done (masking is
	skipped); 
* `vartype` : (_option_) type of variables passed, either personal (`P`), household (`H`)
	register (`R`) or (`D`); if empty (not recommended), the first letter of the first variable 
	in `var` will be used in place of `vartype`; 
* `where` : (_option_) additional `WHERE` clause used to further refine the conditions applied
	to select the values (observations) where the rounding occurs;
* `round` : (_option_) rounding value; default: `round=1` (integer rounding); 
* `lib` : (_option_) input library; default: `lib=WORK`.

### Return
Update the table `iudb` by rounding any/all of the (personal or household) variables that 
are passed to `var`.
	
### Example
Let us consider the following list of income variables to be rounded to the closest 50 euros
for UK:

~~~sas
	%let list_of_vars = PY010N PY010G; 
	%ano_var_round(UK , UDB_P, round=50, var=&list_of_vars, vartype=P, lib=WORK);
~~~ 
This is actually operating the following:
~~~sas
	PROC SQL;
		UPDATE WORK.UDB_P
		SET 	
			PY010N=(ROUND(&PY010N, 50)),
			PY010G=(ROUND(&PY010G, 50))
		 WHERE PB020 in ("UK"); 
	quit;
~~~ 

### See also
[%ano_var_mask](@ref sas_ano_var_mask).
*/ /** \cond */

/* credits: gjacopo */

%macro ano_var_round(geo		/* Input list of country(ies) ISO-code									(REQ) */
					, iudb 		/* Input bulk dataset 													(REQ) */
					, vartype= 	/* List of variables to round											(OPT) */
					, where=	/* Where clause used to select observations where the rounding occurs 	(OPT) */
					, typ=		/* Input flag for personal/household variables 							(OPT) */
					, lib= 		/* Input library 														(OPT) */
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
	%else 
		%let var=%upcase(&var);

	/* ILIB/OLIB : check/default set */
	%if %macro_isblank(lib) %then 		%let lib=WORK;

	/* VARTYPE : default set */
	%if %macro_isblank(vartype) %then 		%let vartype=%substr(&var,1,1);

	%if %symexist(G_DEBUG) EQ 0 %then 	%goto check_skip; 
	%else %if &G_DEBUG EQ 0 %then 		%goto check_skip; 

	%local _lvar;

	/* IUDB : check */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&iudb, lib=&lib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Input dataset %upcase(&iudb) not found !!!)) %then
		%goto exit;

 	%let _lvar=;
    %ds_contents(&iudb, _varlst_=_lvar, lib=&lib);
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

	%local _v _i Nvar;
	%let Nvar = %list_length(&var);
		
	PROC SQL;
		UPDATE &lib..&iudb
		SET 	
			%do _i=1 %to %eval(&Nvar - 1);
				%let _v=%scan(&var, &_i);
				&_v=(ROUND(&_v, &round)),
			%end;
			%let _v=%scan(&var, &Nvar);
			&_v=(ROUND(&_v, &round))
	 	WHERE 
			%if "&geo"^="_ALL_" %then %do;
				&vartype.B020 in %sql_list(&geo) 
				%if not %macro_isblank(where) %then %do;
					AND
				%end;
			%end;
			%if not %macro_isblank(where) %then %do;
				&where
			%end;
	quit;

	%exit:
%mend ano_var_round;

%macro _example_ano_var_round;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	%put !!! &sysmacroname - Not implemented yet !!!;
%mend _example_ano_var_round;
