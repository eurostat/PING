/** 
## silc_ind_create {#sas_silc_ind_create}
Create an indicator table from a common variable template and a list of additional labels.

~~~sas
	%silc_ind_create(dsn, dim=, var=, type=, len=, 
		ignore_var_dim=no, force_Nwgh=no, 
		cds_ind_con=META_INDICATOR_CONTENTS, cds_var_dim=META_VARIABLE_DIMENSION, 
		lib=WORK);
~~~
  
### Arguments
* `dsn` : name of the output (created) dataset;
* `dim` : (_option_) names of the (additional, Eurobase compatible) dimensions present in 
	the generated dataset, _i.e._ used as breadowns for the indicator; `dim` is incompatible 
	with `var` parameter (see below); default: `dim` is empty, _i.e._ the common template alone 
	is used (see `cds_ind_con` below);
* `var` : (_option_) when `dim` is not passed, it is possible to provide with the names of 
	the EU-SILC source variables used as breadowns for the indicator; then, corresponding 
	dimensions will be searched for in the configuration file that stores the correspondance 
	table between EU-SILC variable and Eurobase dimensions (see `cds_var_dim` below); `var` 
	is incompatible with `dim` parameter (see above); by default, `var` is empty and `dim` is
	used;
* `ignore_var_dim` : (_option_) 
* `type` , `len` : (_option_) types and lengths of the (additional) fields; must be the same 
	length as `var` or `dim`; see examples in [%ds_create](@ref sas_ds_create) for further 
	description; these are compatible with `ignore_var_dim=YES` only;
* `cds_ind_con` : (_option_) configuration file storing the template for the indicator, _i.e._
	generic variables common to EU-SILC indicators; by default,	it is named after the value 
	`&G_PING_INDICATOR_CONTENTS` (_e.g._, `META_INDICATOR_CONTENTS`); for further description, 
	see [%meta_indicator_contents](@ref meta_indicator_contents);
* `cds_var_dim` : (_option_) configuration file storing the correspondance table between EU-SILC
	variables and Eurobase dimensions; by default,	it is named after the value 
	`&G_PING_VARIABLE_DIMENSION` (_e.g._, `META_VARIABLE_DIMENSION`); for further description, 
	see [%meta_variable_dimension](@ref meta_variable_dimension);
* `force_Nwgh` : (_option_) additional boolean flag (`yes/no`) set when an additional
	variable `nwgh` (representing the weighted sample) is added to the indicator
	dataset; default: `force_Nwgh=no`, hence the variable `nwgh` will not be present in the 
	output indicator;
* `lib` : (_option_) name of the output library where `dsn` shall be stored; by default: 
	empty, _i.e._ `WORK` is used;
* `clib` : (_option_) name of the library where the configuration files are stored; default to 
	the value `&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.

### Returns
In `dsn`, an empty dataset where the (list of) variable(s) provided in `dim` has(ve) been added 
to the following template table: 
| geo | time | unit | ivalue | iflag | unrel | n | nwgh |ntot | ntotwgh | lastup | lastuser |
|-----|------|------|--------|-------|-------|---|------|-----|---------|--------|----------|
|     |      |      |        |       |       |   |      |     |         |        |          |
In practice, the variable(s) in `dim` is(are) added in between `unrel` and `n` variables of the
template.

### Examples
Running for instance

~~~sas
	%let dims=AGE 	RB090 	HT1;
	%silc_ind_create(dsn, dim=&dims);
~~~

creates the table `dsn` in the `WORK`ing library as:
| geo | time | unit | ivalue | iflag | unrel | AGE | SEX | HHTYP | n | nwgh | ntot | ntotwgh | lastup | lastuser |
|-----|------|------|--------|-------|-------|-----|-----|-------|---|------|------|---------|--------|----------|
|     |      |      |        |       |       |     |     |       |   |      |      |         |        |          |
where all dimensions `AGE, SEX, HHTYP` are of type `CHAR` and length 15. 

Run macro `%%_example_silc_ind_create` for examples.

### Notes
1. The common variables in the template dataset `cds_ind_con` are defined by default. However, 
they may be parameterised since their names derived from the following global variables:
|        |                     |
|:------:|:-------------------:|
| geo    | `G_PING_LAB_GEO`    |
| time   | `G_PING_LAB_TIME`   |
| unit   | `G_PING_LAB_UNIT`   |
| ivalue | `G_PING_LAB_VALUE`  |
| iflag  | `G_PING_LAB_IFLAG`  |
| unrel  | `G_PING_LAB_UNREL`  |
| n      | `G_PING_LAB_N`      |
| ntot   | `G_PING_LAB_NTOT`   |
|ntotwgh | `G_PING_LAB_TOTWGH` |

In addition a column:
| nwgh   | `G_PING_LAB_NWGH`   |

can be added when the flag `force_Nwgh` is set to `yes`.
2. Since the type and length of the variables to insert are searched for in configuration dataset
`cds_var_dim` (that stores the correspondance table between EU-SILC variables and Eurobase dimensions), 
either variablse `var` or dimensions `dim` must exist in the configuration file. 

### See also
[%meta_variable_dimension](@ref meta_variable_dimension), [%meta_indicator_contents](@ref meta_indicator_contents),
[%ds_create](@ref sas_ds_create).
*/ /** \cond */

/* credits: grazzja */

%macro silc_ind_create(dsn				/* Name of final output dataset 											(REQ) */
						, var=			/* Names of the variables used as breadowns for the indicator				(OPT) */
						, dim=			/* Ibid with Eurobase-compatible dimensions 								(OPT) */
						, lib=			/* Name of the output library where odsn will be stored 					(OPT) */
						, type=			/* Types of the dimensions 													(OPT) */
						, len=			/* Lenghts of the dimensions 												(OPT) */
						, ignore_var_dim=/* Boolean flag set to ignore configuration flag 							(OPT) */
						, cds_ind_con=	/* Configuration file with common indicator dimensions 						(OPT) */
						, cds_var_dim=  /* Configuration file with correspondance between variables and dimensions 	(OPT) */
						, force_Nwgh=NO	/* Boolean flag used to add a NWGH variable 								(REQ) */
						, clib=			/* Name of the configuration library 										(OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _existvardim	/* boolean flag used for the existence of the correspondance table */
		_existindcon;	/* boolean flag used for the existence of the indicator template */

	/* VAR, DIM : check/set and compatibility check*/
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 0 and %macro_isblank(dim) EQ 0, mac=&_mac,
			txt=%quote(!!! Parameters VAR and DIM are incompatible !!!)) 
			or
			%error_handle(ErrorInputParameter, 
				%macro_isblank(var) EQ 1 and %macro_isblank(dim) EQ 1, mac=&_mac,
				txt=%quote(!!! One at least among parameters VAR and DIM must be set !!!)) %then 
		%goto exit;

	/* DSN, LIB : check/set */
	%if %macro_isblank(lib) %then	%let lib=WORK;
	/* done in %ds_create
		%if %error_handle(ExistingOutputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 0, mac=&_mac,
			txt=%quote(! Output table already exist - Will be overwritten !), verb=warn) %then 
		%goto warning;
		%warning: */

	/* IGNORE_VAR_DIM: check/set */
	%if %macro_isblank(ignore_var_dim) %then	%let ignore_var_dim=NO;
	%else 										%let ignore_var_dim=%upcase(&ignore_var_dim);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&ignore_var_dim, type=CHAR, set=YES NO) NE 0, mac=&_mac,
			txt=%quote(!!! Wrong value for boolean flag IGNORE_VAR_DIM !!!)) %then
		%goto exit;

	/* TYPE/LEN: compatibility check with IGNORE_VAR_DIM */
	%if %error_handle(ErrorInputParameter, 
			"&ignore_var_dim" EQ "NO" and (%macro_isblank(type) EQ 0 or %macro_isblank(len) EQ 0), mac=&_mac,
			txt=%quote(!!! Parameters TYPE and LEN compatible with IGNORE_VAR_DIM=YES only !!!)) %then
		%goto exit;
	/* note: full checks made in DS_CREATE */

	/* CDS_IND_CON, CLIB : check/set */
	%if %macro_isblank(clib) %then	%do;
		%if %symexist(G_PING_LIBCFG) %then 					%let clib=&G_PING_LIBCFG;
		%else												%let clib=LIBCFG;
	%end;

	%if %macro_isblank(cds_ind_con) %then	%do;
		%if %symexist(G_PING_INDICATOR_CONTENTS) %then 		%let cds_ind_con=&G_PING_INDICATOR_CONTENTS;
		%else												%let cds_ind_con=INDICATOR_CONTENTS;
	%end;

	/* FORCE_NWGH: set default  */
	%if %macro_isblank(force_Nwgh) %then		%let force_Nwgh=NO; 
	%else 										%let force_Nwgh=%upcase(&force_Nwgh); 

	%if %error_handle(ErrorInputParameter, 
			%par_check(&force_Nwgh, type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong value for boolean flag FORCE_NWGH - Must be in YES or NO !!!)) %then 
		%goto exit;

	%if "&ignore_var_dim"="YES" %then %goto ignore_var_dim;

	%let _existindcon= %ds_check(&cds_ind_con, lib=&clib);
	%if %error_handle(MissingConfigurationFile, 
			&_existindcon NE 0, mac=&_mac,
			txt=%quote(! Temporary configuration file %upcase(&cds_ind_con) does not exist: default values to be used !), 
			verb=warn) %then;
		%goto warning1;
	%warning1:

	/* CDS_VAR_DIM, CLIB : check/set */
	%if %macro_isblank(cds_var_dim) %then %do;
		%if %symexist(G_PING_VARIABLE_DIMENSION) %then 		%let cds_var_dim=&G_PING_VARIABLE_DIMENSION;
		%else												%let cds_var_dim=VARIABLE_DIMENSION;
	%end;

	%let _existvardim= %ds_check(&cds_var_dim, lib=&clib);
	%if %error_handle(MissingConfigurationFile, 
			&_existvardim NE 0, mac=&_mac,
			txt=%quote(! Temporary configuration file %upcase(&cds_var_dim) does not extist: default values to be used !), 
			verb=warn) %then %do;
		%if %error_handle(ErrorMissingParameter, 
				%macro_isblank(var) EQ 0, mac=&_mac,
				txt=%quote(!!! Configuration file requested when passing VAR instead of DIM !!!)) %then 
			%goto exit;
		%else 
			%goto warning2;
		%warning2:
	%end;

	%ignore_var_dim:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _typ _len
		/* types and lengths of the (additional) dimensions: they are searched for in configuration 
		* file that stores the correspondance table between EU-SILC variables and Eurobase dimensions */
		l_NWGH			/* name of NWGH label */
		l_TOTWGH		/* ibid, TOTWGH */
		;
	%let _typ=;
	%let _len=;

	%if not %macro_isblank(var) %then %do; /* note that CDS_VAR_DIM must exist at this stage */
		%local variables; /* accepted variables */
		%let variables=;

		/* retrieve the list of existing variables from CDS_VAR_DIM */
		%var_to_list(&cds_var_dim, VARIABLE, _varlst_=variables, lib=&clib);
		/* and check... */
		%if %error_handle(UnmatchedInputVariable, 
				%list_difference(&var, &variables) NE , mac=&_mac,
				txt=%quote(!!! Unmatched variables %upcase(&var) in %upcase(&cds_var_dim) !!!)) %then 
			%goto exit;
		
		/* we retrieve the corresponding dimensions in DIM */
		%list_map(&cds_var_dim, &var, var=VARIABLE DIMENSION, _maplst_=dim, lib=&clib);		
	%end;

	/* retrieve the format (type/length) of SILC variables/dimensions */ 
	%if &_existvardim=0 and "&ignore_var_dim"="NO" %then %do;
		%local dimensions; /* accepted dimensions */;
		%let dimensions=;

		/* retrieve the list of existing dimensions from CDS_VAR_DIM */
		%var_to_list(&cds_var_dim, DIMENSION, _varlst_=dimensions, lib=&clib);

		/* and check... */
		%if %error_handle(UnmatchedInputDimension, 
				%list_difference(&dim, &dimensions) NE , mac=&_mac,
				txt=%quote(!!! Unmatched dimensions %upcase(&dim) in %upcase(&cds_var_dim) !!!)) %then 
			%goto exit;

		/* we retrieve the corresponding types/lengtsh in TYP/LEN */
		%list_map(&cds_var_dim, &dim, var=DIMENSION type, _maplst_=_typ, lib=&clib);
		%list_map(&cds_var_dim, &dim, var=DIMENSION length, _maplst_=_len, lib=&clib);
	%end;
	%else %if "&ignore_var_dim"="YES" %then %do;
		%if not %macro_isblank(type) %then %let _typ=&type;
		%if not %macro_isblank(len) %then %let _len=&len;
	%end;

	/* note those two are declared here because they are used in specific cases */
	%if %symexist(G_PING_LAB_NWGH) %then 		%let l_NWGH=&G_PING_LAB_NWGH;
	%else										%let l_NWGH=nwgh;
	%if %symexist(G_PING_LAB_TOTWGH) %then 		%let l_TOTWGH=&G_PING_LAB_TOTWGH;
	%else										%let l_TOTWGH=totwgh;

	/* note that at this stage, TYP and LEN may be empty */

	/* create the common template/contents of SILC X indicators */ 
	%if &_existindcon NE 0 %then %do;
		%local _ISTEMP_		/* flag of temporary creation */
			l_GEO			/* name of GEO label */
			GEO_LENGTH		
			l_TIME			/* ibid, TIME */
			TIME_LENGTH			
			l_UNIT			/* ibid, UNIT */
			UNIT_LENGTH		
			l_VALUE			/* ibid, VALUE */
			l_UNREL			/* ibid, UNREL */
			l_N				/* ibid, N */
			l_NTOT			/* ibid, NTOT */
			l_IFLAG			/* ibid, IFLAG */
			IFLAG_LENGTH;
		%let _ISTEMP_=YES;

		/* retrieve global setting whenever it exitsts */
		%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
		%else										%let l_GEO=geo;
		%if %symexist(G_PING_LEN_GEO) %then 		%let GEO_LENGTH=&G_PING_LEN_GEO;
		%else										%let GEO_LENGTH=15;
		%if %symexist(G_PING_LAB_TIME) %then 		%let l_TIME=&G_PING_LAB_TIME;
		%else										%let l_TIME=time;
		%if %symexist(G_PING_LEN_TIME) %then 		%let TIME_LENGTH=&G_PING_LEN_TIME;
		%else										%let TIME_LENGTH=4;
		%if %symexist(G_PING_LAB_UNIT) %then 		%let l_UNIT=&G_PING_LAB_UNIT;
		%else										%let l_UNIT=unit;
		%if %symexist(G_PING_LEN_UNIT) %then 		%let UNIT_LENGTH=&G_PING_LEN_UNIT;
		%else										%let UNIT_LENGTH=8;
		%if %symexist(G_PING_LAB_VALUE) %then 		%let l_VALUE=&G_PING_LAB_VALUE;
		%else										%let l_VALUE=ivalue;
		%if %symexist(G_PING_LAB_UNREL) %then 		%let l_UNREL=&G_PING_LAB_UNREL;
		%else										%let l_UNREL=unrel;
		%if %symexist(G_PING_LAB_N) %then 			%let l_N=&G_PING_LAB_N;
		%else										%let l_N=n;
		%if %symexist(G_PING_LAB_NTOT) %then 		%let l_NTOT=&G_PING_LAB_NTOT;
		%else										%let l_NTOT=ntot;
		%if %symexist(G_PING_LAB_IFLAG) %then 		%let l_IFLAG=&G_PING_LAB_IFLAG;
		%else										%let l_IFLAG=iflag;
		%if %symexist(G_PING_LEN_IFLAG) %then 		%let IFLAG_LENGTH=&G_PING_LEN_IFLAG;
		%else										%let IFLAG_LENGTH=8;

		DATA WORK.&cds_ind_con;
			length LABEL $15;
			length TYPE $4;
			LABEL="&l_GEO"; 	TYPE="char"; 	LENGTH=&GEO_LENGTH; 	ORDER=1; 	output;
			LABEL="&l_TIME "; 	TYPE="num"; 	LENGTH=&TIME_LENGTH; 	ORDER=2; 	output;
			LABEL="&l_UNIT"; 	TYPE="char"; 	LENGTH=&UNIT_LENGTH; 	ORDER=-10; 	output;
			LABEL="&l_VALUE"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-9; 	output;
			LABEL="&l_IFLAG"; 	TYPE="char"; 	LENGTH=&IFLAG_LENGTH; 	ORDER=-8; 	output;
			LABEL="&l_UNREL"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-7; 	output;
			LABEL="&l_N"; 		TYPE="num"; 	LENGTH=8; 				ORDER=-6; 	output;
			LABEL="&l_NWGH"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-5; 	output;
			LABEL="&l_NTOT"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-4; 	output;
			LABEL="&l_TOTWGH"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-3; 	output;
			LABEL="lastup"; 	TYPE="char"; 	LENGTH=8; 				ORDER=-2; 	output;
			LABEL="lastuser"; 	TYPE="char"; 	LENGTH=8; 				ORDER=-1; 	output;
		run;
		%let clib=WORK;
	%end;
	%else %let _ISTEMP_=NO;

	/* run the standard ds_create macro with newly created table */
	%ds_create(&dsn
			, idsn=&cds_ind_con
			, var=&dim
			, type=&_typ
			, len=&_len
			, ilib=&clib
			, olib=&lib
			);

	/* actually, the cases below are very SILC specific, the tests are not really needed */
	DATA &lib..&dsn
		%if %var_check(&dsn, &l_TOTWGH, lib=&lib) NE 0 %then %do;
			(rename=(n&l_TOTWGH=&l_TOTWGH)) /* we clean up a bit... */
		%end;
		;
		SET &lib..&dsn
		%if "&force_Nwgh" EQ "NO" and %var_check(&dsn, &l_NWGH, lib=&lib) EQ 0 %then %do;
				(DROP=&l_NWGH)
		%end;
		;
	run;

	%if &_ISTEMP_=YES %then %do;
		%work_clean(&cds_ind_con);
	%end; 

	%exit:
%mend silc_ind_create;


%macro _example_silc_ind_create;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local dsn;
	%let dsn=TMP&sysmacroname;
	
	%put;
	%put (i) Create a table with additional dimensions format retrieved from configuration tables;
	%silc_ind_create(&dsn 
					, dim= 	TENURE 	DEG_URB 	WSTATUS
					);
	%ds_print(&dsn, title=(i) &dsn);
	%work_clean(&dsn);

	%put;
	%put (ii) Create a table with additional dimensions explicitly set;
	%silc_ind_create(&dsn
					, var= 	AGE 	RB090 	HT1
					);
	%ds_print(&dsn, title=(ii) &dsn);
	%work_clean(&dsn);

	%put;
	%put (iii) Ibid, adding also a variable NWGH;
	%silc_ind_create(&dsn
					, var= 	AGE 	RB090 	HT1
					, force_Nwgh=yes);
	%ds_print(&dsn, title=(iii) &dsn);
	%work_clean(&dsn);

	%put;

	%work_clean(&dsn);
%mend _example_silc_ind_create;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_ind_create; 
*/

/** \endcond */
