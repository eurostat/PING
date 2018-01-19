/**
## _silc_setup_ {#sas__silc_setup_}
Setup file used for defining environment variables and default macro settings associated
with EU-SILC production.

### Usage
It is usually necessary to define a global `G_PING_SETUPPATH` variable with the path 
of the directory where the `PING` library is installed, e.g.:

~~~sas
	%let G_PING_SETUPPATH=</Server/Path/to/PING/>/PING;
	%let G_PING_PROJECT=EUSILC;
~~~
then run the following instructions for the complete install:

~~~sas
	%include "&G_PING_SETUPPATH/library/autoexec/_eusilc_setup_.sas";
	%_default_setup_; 
~~~

### Note
It is essential for this folder to be located in the same location as the 
[%_setup_](@ref sas__setup_) macro. 
*/ /** \cond */

/* credits: grazzja */

%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		
%global 
		G_PING_VAR_GEO
		G_PING_VAR_TIME
		G_PING_VAR_ID
		/* Name of the file storing the type of transmission file per year 								*/
		G_PING_TRANSMISSIONxYEAR
		/* Names of the files which contain the list of indicator codes and their description 			*/
		G_PING_INDICATOR_CODES
 		G_PING_INDICATOR_CODES_RDB 		/* default: INDICATOR_CODES_RDB 								*/
		G_PING_INDICATOR_CODES_RDB2 		/* default: INDICATOR_CODES_RDB2 							*/
		G_PING_INDICATOR_CODES_LDB 		/* default: INDICATOR_CODES_LDB 								*/
		G_PING_INDICATOR_CODES_EDB		/* default: INDICATOR_CODES_EDB 								*/
		/* First year of EU-SILC implementation 														*/
		G_PING_INITIAL_YEAR
		; 	
/* note: the variables above can be set to default values when running the macro _SETUP_EUSILC_PAR_ below */

%global /* specific EU-SILC variables 																	*/
		G_PING_IS_LEGACY /* set through the call to macro _setup_env_ below */
		G_PING_IS_IN_TEST
		/* Full path of the BDB database  																*
		* default:	&G_PING_ROOTPATH/5.5_Extraction/data/BDB											*/
		G_PING_BDB
		G_PING_LIBBDB
		/* Full path of the PDB database  																*
		* default:	&G_PING_ROOTPATH/5.5_Extraction/data/PDB											*/
		G_PING_PDB
		G_PING_LIBPDB
		/* Full path of the IDB_RDB directory  															*
		* default:	&G_PING_ROOTPATH																	*/
		G_PING_IDBRDB
		/* Full path of the C_IDB (cross-sectional) database  											*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/C_IDB											*/
		G_PING_C_IDB
		G_PING_LIBCIDB
		/* Full path of the E_IDB (early data) database  												*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/E_IDB											*/
		G_PING_E_IDB
		G_PING_LIBEIDB
		/* Full path of the C_IDB (longitudinal)  database  											*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/L_IDB											*/
		G_PING_L_IDB
		G_PING_LIBLIDB
		/* Full path of the C_RDB database  															*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/C_RDB											*/
		G_PING_C_RDB
		G_PING_LIBCRDB
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/C_RDB2											*/
		G_PING_C_RDB2
		G_PING_LIBCRDB2
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/C_RDB1											*/
		G_PING_C_RDB1
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/E_RDB											*/
		G_PING_E_RDB
		G_PING_LIBCERDB
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/E_RDB1											*/
		G_PING_E_RDB1
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/L_RDB											*/
		G_PING_L_RDB
		G_PING_LIBCLRDB
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/L_RDB1											*/
		G_PING_L_RDB1
		/* Full path of the UDB database  																*
		* default:	&G_PING_IDBRDB/7.3_Dissemination/data												*/
		G_PING_UDB
		;
/* note: the variables above can be set to default values when running the macros _SETUP_EUSILC_LOC_  
* and _SETUP_EUSILC_LIB_ below */

/* _SETUP_EUSILC_ENV_
*/
%macro _setup_eusilc_env_;

	%if not %symexist(G_PING_PROJECT) %then %do;
		%global G_PING_PROJECT;
	%end;
	%if "&G_PING_PROJECT"="" %then %let G_PING_PROJECT=0EUSILC; 

	%_setup_env_;

	%if not %symexist(G_PING_DATABASE) %then %do;
		%global G_PING_DATABASE;
	%end;
	%if "&G_PING_DATABASE"="" %then %do;
		%if "&G_PING_PROJECT"="0EUSILC" %then
			%let G_PING_DATAPATH=&G_PING_ROOTPATH; 
		%else %if "&G_PING_DATAPATH"="1EUSILC" %then
			%let G_PING_DATAPATH=&G_PING_ROOTPATH/0eusilc.copy; 
	%end;

%mend _setup_eusilc_env_;


/* _SETUP_EUSILC_LOC_ 
*/
%macro _setup_eusilc_loc_(legacy=yes, test=no); /* default locations */

	%_setup_loc_;

	/* legacy: EUSILC was used in the past, we still use it */
	%global EUSILC;
	%let EUSILC=&G_PING_DATABASE; 

	%if %upcase("&legacy")="NONE" %then 			%let legacy=NO;
	%else 											%let legacy=%upcase(&legacy);
	%let G_PING_IS_LEGACY=&legacy;

	%if %upcase("&test")="ACCEPTANCE" %then 		%let test=YES;
	%else %if %upcase("&test")="TEST" %then 		%let test=YES;
	%else %if %upcase("&test")="PRODUCTION" %then	%let test=NO;
	%else 											%let test=%upcase(&test);
	%let G_PING_IS_IN_TEST=&test;

	%if "&legacy"="YES" %then %do; 
		%if "&test"="YES" %then %do;
			%let G_PING_IDBRDB=	&G_PING_DATABASE/IDB_RDB_TEST;
		%end;
		%else %do;
			%let G_PING_IDBRDB=	&G_PING_DATABASE/IDB_RDB;
		%end;
		%let db_raw=			&G_PING_ROOTPATH/main;
		%let db_valid=			&G_PING_DATABASE/main;
		%let db_extr=			&G_PING_IDBRDB;
		%let db_estim=			&G_PING_IDBRDB;
		%let db_upload=			&G_PING_IDBRDB/newcronos;
		%let G_PING_BDB=		&G_PING_DATABASE/BDB;
		%let G_PING_PDB=		&G_PING_DATABASE/pdb;
	%end;
	%else %do;
		%if "&test"="YES" %then %do;
			%let G_PING_IDBRDB=	&G_PING_DATABASE/test;
		%end;
		%else %do;
			%let G_PING_IDBRDB=	&G_PING_DATABASE;
		%end;
		%let db_raw=			&G_PING_IDBRDB/5.1_Integration/data;
		%let db_valid=			&G_PING_IDBRDB/5.3_Validation/data;
		%let db_extr=			&G_PING_IDBRDB/5.5_Extraction/data;
		%let db_estim=			&G_PING_IDBRDB/5.5_Estimation/data;
		%let db_upload=			&G_PING_IDBRDB/7.1_Upload/data;
		%let G_PING_BDB=		&db_extr/BDB;
		%let G_PING_PDB=		&db_extr/PDB; 
	%end;

	%let G_PING_TESTDB=			&G_PING_LIBTEST/data; /* &G_PING_LIBTESTDATA */
	%let G_PING_RAWDB=			&db_raw;
	%let G_PING_C_IDB=			&db_extr/C_IDB; 
	%let G_PING_E_IDB=			&db_extr/E_IDB; 
	%let G_PING_L_IDB=			&db_extr/L_IDB; 
	%let G_PING_C_RDB=			&db_estim/C_RDB; 
	%let G_PING_C_RDB2=			&db_estim/C_RDB2; 
	%let G_PING_E_RDB=			&db_estim/E_RDB; 
	%let G_PING_L_RDB=			&db_estim/L_RDB; 
	%let G_PING_C_RDB1=			&db_estim/C_RDB1; 
	%let G_PING_L_RDB1=			&db_estim/L_RDB1; 
	%let G_PING_E_RDB1=			&db_estim/E_RDB1; 
	%let G_PING_DIRREPORT=		&G_PING_DATABASE/reports;
	%let G_PING_LOGDIR=			&G_PING_DIRREPORT/log; 
	%let G_PING_HTMLDIR=		&G_PING_DIRREPORT/html;
	%let G_PING_LISTDIR=		&G_PING_DIRREPORT/list;
	%let G_PING_LOADDB=			&db_upload;
	%let G_PING_UDB=			&G_PING_DISSEMINATION/data;

	%exit:
%mend _setup_eusilc_loc_;

/* _SETUP_EUSILC_LIB_
*/
%macro _setup_eusilc_lib_;

	%_setup_lib_;

	libname LIBPDB "&G_PING_PDB";
	%let G_PING_LIBPDB=LIBPDB;
	libname LIBBDB "&G_PING_BDB";
	%let G_PING_LIBBDB=LIBBDB;

	libname LIBCIDB "&G_PING_C_IDB";
	%let G_PING_LIBCIDB=LIBCIDB;
	libname LIBEIDB "&G_PING_E_IDB";
	%let G_PING_LIBEIDB=LIBEIDB;
	libname LIBLIDB "&G_PING_L_IDB";
	%let G_PING_LIBLIDB=LIBLIDB;

	libname LIBCRDB "&G_PING_C_RDB";
	%let G_PING_LIBCRDB=LIBCRDB;
	libname LIBCRDB2 "&G_PING_C_RDB2";
	%let G_PING_LIBCRDB2=LIBCRDB2;
	libname LIBCERDB "&G_PING_E_RDB";
	%let G_PING_LIBCERDB=LIBCERDB;
	libname LIBCLRDB "&G_PING_L_RDB";
	%let G_PING_LIBCLRDB=LIBCLRDB;

	%exit:
%mend _setup_eusilc_lib_; 

/* _SETUP_EUSILC_VAR_
*/
%macro _setup_eusilc_var_(debug=no);

	%_setup_var_(debug=&debug);

	%let G_PING_VAR_TIME=	B010;
	%let G_PING_VAR_GEO=	B020;
	%let G_PING_VAR_ID=		B030;

	%let G_PING_AGG_POP_THRESH=0.7; 

	%let G_PING_TRANSMISSIONxYEAR= 		META_TRANSMISSIONxYEAR;

	%let indicator_generic=META_INDICATOR_CODES;
	%let G_PING_INDICATOR_CODES=		&indicator_generic;
	%let G_PING_INDICATOR_CODES_RDB=	&indicator_generic._RDB;
	%let G_PING_INDICATOR_CODES_RDB2=	&indicator_generic._RDB2;
	%let G_PING_INDICATOR_CODES_LDB=	&indicator_generic._LDB;
	%let G_PING_INDICATOR_CODES_EDB=	&indicator_generic._EDB;

	%let G_PING_INITIAL_YEAR=			2002;

	%exit:
%mend _setup_eusilc_var_;

/* _SETUP_EUSILC_LAB_
*/
%macro _setup_eusilc_lab_;

	%_setup_lab_;

	%let G_PING_LAB_TOTWGH=	totwgh; /* overwrite the "standard" definition (ntotwgh) */

	%exit:
%mend _setup_eusilc_lab_;

/* _DEFAULT_EUSILC_SETUP_
*/
%macro _default_eusilc_setup_(legacy=yes, test=no, debug=no);
	%put -----------------------------;
	%put defining setup environment...;
	%_setup_eusilc_env_;
	%put -----------------------------;
	%put defining setup locations...;
	%_setup_eusilc_loc_(legacy=&legacy, test=&test); 
	%put -----------------------------;
	%put running autocall...;
	%_setup_auto_; /* the one actually defined in _setup_ */
	%put -----------------------------;
	%put defining setup libraries...;
	%_setup_eusilc_lib_;
	%put -----------------------------;
	%put defining global variables...;
	%_setup_eusilc_var_;
	%put -----------------------------;
	%put defining generic labels...;
	%_setup_eusilc_lab_;
	%put -----------------------------;
%mend _default_eusilc_setup_;

/* _DEFAULT_SETUP_
* Overwrite the original _DEFAULT_SETUP_ of _setup_.sas
*/
%macro _default_setup_;
	%_default_eusilc_setup_(legacy=yes, test=no, debug=no);
%mend _default_setup_;

/* _TEST_SETUP_
* Overwrite the original _TEST_SETUP_ of _setup_.sas
*/
%macro _test_setup_; /* legacy and test environment */
	%_default_eusilc_setup_(legacy=yes, test=yes, debug=no);
%mend _test_setup_;

/** \endcond */
