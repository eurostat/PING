/**
## ano_var_rename {#sas_ano_var_rename}
Rename variables of a dataset.

~~~sas
	%ano_var_rename(dsn, lib=WORK, old1=new1, old2=new2, ...);
~~~

### Arguments
* `dsn` : input dataset where variables to be renamed;
* `lib` : (_option_) input library; default: `lib=WORK`; note that when this is passed,
	it should be set in 2nd position;
* `old1=new1, old2=new2` : (_option_) set of renaming couple of the form `old=new` so that
	the variable `old` shall be renamed into `new`.

### See also
[%ano_ds_select](@ref sas_ano_ds_select), [%ano_var_mask](@ref sas_ano_var_mask).
*/ /** \cond */

/* credits: gjacopo */

%macro ano_var_rename/parmbuff;
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

	%local SEP
		arg libarg lib
		varargs;
	%let SEP=%quote(,);

	/* get rid of the parentheses */
	%let syspbuff=%substr(&syspbuff, 2, %eval(%length(&syspbuff)-2));

	/* retrieve the dataset name */
	%let dsn=%scan(%quote(&syspbuff), 1, &SEP);

	/* retrieve the library name and all other arguments */
	%let libarg=%scan(%quote(&syspbuff), 2, &SEP);
	%let arg=%upcase(%scan(&libarg, 1, %quote(=)));
	%if "&arg" EQ "LIB" %then %do;
		%let lib=%scan(&libarg, 2, %quote(=));
 		%let varargs=%list_slice(%quote(&syspbuff), ibeg=3, sep=&SEP);
	%end;
	%else %do;
		%let lib=WORK;
 		%let varargs=%list_slice(%quote(&syspbuff), ibeg=2, sep=&SEP);
	%end;

	%if %symexist(G_DEBUG) EQ 0 %then 	%goto check_skip; 
	%else %if &G_DEBUG EQ 0 %then 		%goto check_skip; 

	%local _lvar _vars;

	/* DSN : check/set */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Input dataset %upcase(&dsn) not found !!!)) %then
		%goto exit;

	%let _vars=;
	%do _k = 1 %to %list_length(&varargs, sep=&SEP);
		%let _vars=&_vars %scan(&varargs, 2, %quote(=));
	%end;

  	%let _lvar=;
	%ds_contents(&dsn, _varlst_=_lvar, lib=&lib);
	%if %error_handle(ErrorInputParameter,
			%list_difference(&_vars, &_lvar) NE , mac=&_mac,
			txt=%quote(!!! Variables &_vars not found in dataset %upcase(&dsn) !!!)) %then 
		%goto exit;	

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%check_skip:

	%local _k 
		Nvar;
	%let Nvar = %list_length(%quote(&varargs), sep=&SEP);

	%if &Nvar=0 %then 
		%goto exit;

	DATA &lib..&dsn ;
		SET &lib..&dsn ;
		RENAME 
		%do _k = 1 %to &Nvar;
			%scan(%quote(&varargs), &_k, &SEP)
		%end;
		;
	run;

%mend ano_var_rename;

%macro _example_ano_var_rename;
	/*%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;*/

	%local renamed_var;

	DATA UDB_H1;
		HB020='SI'; rate=10; HHSIZE=6; EQ_SS=10; HT=6; TENSTA=1920; ARPT60=1; EQ_INC=0; OVERCROWDED=0;	output;
		HB020='SI'; rate=2; HHSIZE=2; EQ_SS=2; HT=2; TENSTA=1980; ARPT60=2; EQ_INC=1; OVERCROWDED=1; 	output;
		HB020='SI'; rate=3; HHSIZE=3; EQ_SS=3; HT=3; TENSTA=1930; ARPT60=3; EQ_INC=2; OVERCROWDED=2; 	output;
		HB020='PT'; rate=6; HHSIZE=6; EQ_SS=4; HT=4; TENSTA=2010; ARPT60=4; EQ_INC=3; OVERCROWDED=3; 	output;
		HB020='FR'; rate=8; HHSIZE=6; EQ_SS=7; HT=7; TENSTA=1980; ARPT60=5; EQ_INC=4; OVERCROWDED=4; 	output;
		HB020='UK'; rate=9; HHSIZE=6; EQ_SS=6; HT=6; TENSTA=1980; ARPT60=6; EQ_INC=5; OVERCROWDED=5; 	output;
		HB020='PT'; rate=1; HHSIZE=1; EQ_SS=0; HT=0; TENSTA=1920; ARPT60=7; EQ_INC=4; OVERCROWDED=4; 	output;
		HB020='SK'; rate=2; HHSIZE=2; EQ_SS=7; HT=7; TENSTA=1999; ARPT60=8; EQ_INC=5; OVERCROWDED=5; 	output;
		HB020='EE'; rate=5; HHSIZE=5; EQ_SS=8; HT=8; TENSTA=2000; ARPT60=9; EQ_INC=4; OVERCROWDED=4; 	output;
		HB020='MT'; rate=8; HHSIZE=6; EQ_SS=3; HT=3; TENSTA=1990; ARPT60=10; EQ_INC=5; OVERCROWDED=5;	output;
		HB020='MT'; rate=2; HHSIZE=2; EQ_SS=10; HT=6; TENSTA=2000; ARPT60=11; EQ_INC=3; OVERCROWDED=3; 	output;
	run;

	%let renamed_var=%quote(
			rate=		HX010
			HHSIZE=		HX040
			EQ_SS=		HX050
			HT=			HX060
			TENSTA=		HX070
			ARPT60=		HX080
			EQ_INC=		HX090
			OVERCROWDED=HX120
			);
	%ano_var_rename(UDB_H1, lib=WORK, &renamed_var);

	/*this is equivalent to running: 
	%ano_var_rename(UDB_H1, lib=WORK, rate=HX010, HHSIZE=HX040, EQ_SS=HX050, HT=HX060,
		TENSTA=HX070, ARPT60=HX080, EQ_INC=HX090, OVERCROWDED=HX120);
	*/

%mend _example_ano_var_rename;


