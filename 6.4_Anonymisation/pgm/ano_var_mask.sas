/** 
## ano_var_mask {#sas_ano_var_mask}
Set (personal or household) variables to missing for a given list of countries.

~~~sas
	%ano_var_mask(geo, iudb, var=, vartype=, where=, flag=yes, lib=WORK);
~~~

### Arguments
* `geo` : list of (blank separated) countries ISO-codes; note that when `geo=_ALL_`, all
	countries will be processed, _i.e._ no condition on ISO-code will be imposed;
* `iudb` : input temporary UDB table; 
* `var` : (_option_) list of variables to set to missing value `.`; if empty, nothing is 
	done (_i.e._, masking is skipped);
* `vartype` : (_option_) type of variables passed, either personal (`P`), household (`H`)
	register (`R`) or (`D`); this is used to define the georeferencing variable as `&vartype.B020`; 
	if empty (not recommended), the first letter of the first variable in `var` will be used in 
	place of `vartype`; 
* `where` : (_option_) additional `WHERE` clause used to further refine the conditions applied
	to select the values (observations) to set to missing;
* `flag` : (_option_) numeric or boolean (`yes/no`) value defined when the corresponding flag 
	variable shall also be masked (`flag=yes` or any value) or not (`flag=no`); when `flag=yes`,
	the value used for the flag is -1;
* `lib` : (_option_) input library; default: `lib=WORK`.

### Return
Update the table `iudb` by masking any/all of the (personal or household) variables 
that are passed to `var`.
	
### Note
Let us consider two personal income variables to set to missing for SI in the personal 
dataset `UDB_P`:

~~~sas
	%let list_of_vars = PY091G PY092G;
	%udb_var_mask(SI, UDB_P, var=&list_of_vars, flag=-1, vartype=P, lib=WORK);
~~~ 
This is actually operating the following:
~~~sas
	PROC SQL;
		UPDATE WORK.UDB_P
		SET 	
			PY091G=., PY091G_F=-1,
			PY092G=., PY092G_F=-1
		 WHERE PB020 in ("SI"); 
	quit;
~~~ 

### See also
[%ano_var_round](@ref ano_var_round).
*/ /** \cond */

/* credits: grazzja */

%macro ano_var_mask(geo			/* Input list of country(ies) ISO-code								(REQ) */
					, iudb		/* Input bulk dataset 												(REQ) */
					, var= 		/* List of variables to be set to missing							(OPT) */
					, vartype= 	/* Type of the variables to be set to missing						(OPT) */
					, where=	/* Where clause used to select the variables to be set to missing 	(OPT) */
					, flag= 	/* Boolean flag set to mask flags									(OPT) */
					, lib= 		/* Input library 													(OPT) */
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
	%if %macro_isblank(lib) %then 	%let lib=WORK;

	/* FLAG : default set */
	%if %macro_isblank(flag) %then 	%let flag=-1;
	%else 							%let flag=%upcase(&flag);
	%if "&flag"="YES" %then 		%let flag=-1;
	%else %if "&flag"="NO"	%then 	%let flag=; /* blank */

	/* VARTYPE : default set */
	%if %macro_isblank(vartype) %then 		%let vartype=%substr(&var,1,1);

	/* VAR : default income set
	%if "&var"="_P_DEFAULT_" %then 		
		%let var=	PY091G PY092G PY093G PY094G PY101G PY102G PY103G PY104G 
					PY111G PY112G PY113G PY114G PY121G PY122G PY123G PY124G 
					PY131G PY132G PY133G PY134G PY141G PY142G PY143G PY144G;
	%else %if "&var"="_H_DEFAULT_" %then 	
		%let var=	HY051G HY052G HY053G HY054G
					HY061G HY062G HY063G HY064G
					HY071G HY072G HY073G HY074G;
 	*/

	%if %symexist(G_DEBUG) EQ 0 %then 	%goto check_skip; 
	%else %if &G_DEBUG EQ 0 %then 		%goto check_skip; 

	%local _lvar;
 	%let _lvar=;

	/* IUDB : check */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&iudb, lib=&lib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Input dataset %upcase(&iudb) not found !!!)) %then
		%goto exit;

    %ds_contents(&iudb, _varlst_=_lvar, lib=&lib);
	%if %error_handle(ErrorInputParameter,
			%list_difference(&var, &_lvar) NE , mac=&_mac,
			txt=%quote(!!! Variables &var must be present in input dataset %upcase(&iudb) !!!)) %then 
		%goto exit;	

	/* FLAG : check */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&flag, type=CHAR, set=YES NO) EQ 0, mac=&_mac,		
			txt=%quote(!!! Wrong boolean value for FLAG !!!)) %then
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
		_typ _len typ
		Nvar;
	%let typ=;
	%let Nvar = %list_length(&var);

	%do _i=1 %to &Nvar;
		%let _v=%scan(&var, &_i);
		%let _typ=; %let _len=;
		/* use %var_info instead */
		data _null_;
	   		dsid = open("&lib..&iudb",'i', , 'D'); 
			pos = varnum(dsid, "&_v");
		    typ = vartype(dsid, pos);
			call symput("_typ",compress(typ,,'s'));
		run;
		%let typ=&typ &_typ;
	%end;

	PROC SQL;
		UPDATE &lib..&iudb
		SET 	
			%do _i=1 %to &Nvar;
				%let _v=%scan(&var, &_i);
				%let _t=%scan(&typ, &_i);
				%if "&_t"="C" %then %do;
					&_v=''
				%end;
				%else %do;
					&_v=.
				%end;
				%if not %macro_isblank(flag) %then %do;
					, &_v._F=&flag
				%end;
				%if &_i < &Nvar %then %do;
					, 
				%end;
			%end;
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
				;
	quit;

	%exit:
%mend ano_var_mask;

%macro _example_ano_var_mask;
	/*%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;*/

	DATA tmp;
		DB020='FI'; DB040='FI20'; DB040_F=2; value=0; output;
		DB020='FI'; DB040='FI10'; DB040_F=1; value=1; output;
		DB020='DE'; DB040='DE20'; DB040_F=3; value=2; output;
		DB020='UK'; DB040='UK10'; DB040_F=0; value=3; output;
		DB020='NL'; DB040='NL20'; DB040_F=1; value=4; output;
		DB020='PT'; DB040='PT20'; DB040_F=2; value=5; output;
	run;

	%ano_var_mask(DE PT NL, tmp, var=DB040, flag=yes, vartype=D, lib=WORK);
	/* as if we were running: 
		Update WORK.UDB_D1
		set DB040 ='', DB040_F=-1
	where DB020 in ('DE','PT','NL');
	*/

%mend _example_ano_var_mask;
