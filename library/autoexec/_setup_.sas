/**
## _setup_ {#sas__setup_}
Setup file used for defining environment variables and default macro settings.

### Usage
It is usually necessary to define a global `G_PING_SETUPPATH` variable with the path 
of the directory where the `PING` library is installed, e.g.:

~~~sas
	%let G_PING_SETUPPATH=</path/to/your/install/>/PING;
	%let G_PING_PROJECT=PING;
~~~
where `</path/to/your/install/>` is obviously the path to the directory where `PING` 
is installed, then run the following instructions:

~~~sas
	%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
~~~

Following, a bunch of macros for default settings is made available, _e.g._: 
* `%%_local_or_server_`: retrieve the data repository (on local or server: see
	comment	on variable `G_PING_ROOTPATH` below),
* `%%_setup_loc_`: define various locations related to `PING` install, 
* `%%_setup_auto_`: retrieve the locations of the different macros used in the
	library	and append these locations to `SASAUTOS`, 
* `%%_setup_env_`: define a set of environment variables with dataset location, 
* `%%_setup_lab_`: define various generic labels,
* `%%_setup_var_`: define various default variables names.

In particular, you  will be able to run all those macros together with the default 
setup macro:

~~~sas
	%_default_setup_;
~~~

### Returns
Say that your installation path is `G_PING_SETUPPATH` as defined above. Then, running 
the default settings macro `%%_default_setup_` as described above will set the following 
global variables:
* `G_PING_SETUP` as the path to your project repository _e.g._ 
	you will have. 
  		- `G_PING_SETUP=/ec/prod/server/sas/0eusilc/PING` if you run on the server, or
 		- `G_PING_SETUP=z:` if you run in local and if `z` has been mounted as 
		  `\\s-isis.eurostat.cec\0eusilc`,
* `SASServer` as the locations of the SAS server and the SAS distribution. 

### References
1. Carpenter, A.L. (2002): ["Building and using macro libraries"](http://www2.sas.com/proceedings/sugi27/p017-27.pdf).
2. Jensen, K. and Greathouse, M. (2000): ["The autocall macro facility in the SAS for Windows environment"](http://www2.sas.com/proceedings/sugi25/25/cc/25p075.pdf).
*/ /** \cond */

/* credits: grazzja */

/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/
/** !!! POSSIBLY SET MANUALLY SAS SERVER !!! **/
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/

%global 
	/* SAS server location */
	SASServer 
	/* SAS extension */
	SASext
	/* root directory: may be declared in an external configuration file *
	G_PING_SETUPPATH *
	* project name: may be declared in an external configuration file *
	G_PING_PROJECT *
	* data repository: may be declared in an external configuration file *
	G_PING_DATAPATH */
	/* root directory path */
	G_PING_ROOTPATH
	;
%let SASServer=%sysfunc(pathname(sasroot));
%let SASext=sas;

/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/
/** !!! POSSIBLY ADD YOUR OWN GLOBAL MACRO VARIABLES !!! **/
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/

%global 
	G_PING_INTEGRATION
	G_PING_VALIDATION
	G_PING_EXTRACTION
	G_PING_ESTIMATION
	G_PING_AGGREGATES
	G_PING_MODULES
	G_PING_ANALYSIS
	G_PING_DISSEMINATION
	G_PING_UPLOAD
	G_PING_SERVICES
	G_PING_ANONYMISATION
	G_PING_VISUALISATION
	;

%global	
		/* Full path of the raw data directory 															*
		* default:	&G_PING_ROOTPATH/5.3_Validation/data												*/
		G_PING_RAWDB
		/* Full path of the directory with data to upload												*
		* default:	&G_PING_IDBRDB/7.1_Upload/data														*/
		G_PING_LOADDB
		/* Full path of the directory with test datasets												*
		* default:	&G_PING_ROOTPATH/test/data															*/
		G_PING_TESTDB
		;
/* note: all these variables are defined by default in macro _default_env_ below */

%global 
		G_PING_DIRREPORT
		/* Full path of the log directory																*
		* default:	&G_PING_ROOTPATH/log/																*/
	 	G_PING_LOGDIR 
		G_PING_LIBLOG
		/**/
	 	G_PING_HTMLDIR
		/**/
		G_PING_LISTDIR
		;	

%global 
		/* Name of the variable defining countries; 
		* default: GEO */
		G_PING_LAB_GEO
		G_PING_LEN_GEO
		/* Name of the variable defining geographic zones/areas/; 
		* default: ZONE */
		G_PING_LAB_ZONE
		/* Name of the variable defining the temporal frame; 
		* default: TIME */
		G_PING_LAB_TIME
		G_PING_LEN_TIME
		/* Name of the variable defining the common unit; 
		* default: UNIT */
		G_PING_LAB_UNIT
		G_PING_LEN_UNIT
		/* Name of the variable defining the actual measured value; 
		* default: IVALUE */
		G_PING_LAB_VALUE
		/* Name of the reliability flag; 
		* default: UNREL */
		G_PING_LAB_UNREL
		/* Name of the variable storing the size of the target population; 
		* default: N */
		G_PING_LAB_N
		/* Name of the variable storing the size of the weighted target population; 
		* default: NWGH */
		G_PING_LAB_NWGH
		/* Name of the variable storing the size of the total reference population; 
		* default: NTOT */
		G_PING_LAB_NTOT
		/* Name of the variable storing the size of the total weighted reference population; 
		* default: TOTWGH */
		G_PING_LAB_TOTWGH
		/* Name of the flag; 
		* default: IFLAG */
		G_PING_LAB_IFLAG
		G_PING_LEN_IFLAG
		/* Name of the weight variable; 
		* default: WEIGHT */
		G_PING_LAB_WEIGHT
		;
/* note: all these variables can be set to default values by running the macro _default_setup_lab_ below */
		
%global G_PING_VERBOSE
		G_PING_DEBUG
		/* Error handling macro variables */
		G_PING_ERROR_MSG					/* default: empty 											*/
		G_PING_ERROR_CODE				/* default: empty 												*/
		G_PING_ERROR_MACRO				/* default: empty 												*/
		/* Machine epsilon 																				*/
		G_PING_MACHINE_EPSILON
		/* Specific separator used as a delimiter between the values listed as output by a 				*
	 	* multiple-choices prompt																		*
		* default: _ 																					*/
		G_PING_LIST_SEPARATOR
		/* Unlikely character 																			*/
		G_PING_UNLIKELY_CHAR
		/* Format commonly adopted for export (note: SAS servers are UNIX, xls/xlsx should be avoided).	*
		* default: csv 																					*/
	 	G_PING_FMT_CODE
		/* String specifying the identity operator (that sends a variable to itself).					*
		* default: _ID_ 																					*/
		G_PING_IDOP
		/* Name of the file which contain the protocol order of EU countries' 							*
		* default: COUNTRY_ORDER 																		*/
		G_PING_COUNTRY_ORDER
		/* Name of the file with the list of files with country zones 									*/
		G_PING_COUNTRYXZONE			/* default: COUNTRYxZONE											*/
		G_PING_COUNTRYXZONEYEAR		/* default: COUNTRY_COUNTRYxZONEYEAR 								*/
		/* Name of the file with the list of yearly populations per country 							*
		* default: POPULATIONxCOUNTRY 																	*/
		G_PING_POPULATIONXCOUNTRY							/* note the use of capital X in the name... */
		/* Name of the file with the history of zones 													*
		* default: ZONExYEAR 																			*/
		G_PING_ZONEXYEAR									/* note the use of capital X in the name... */
		/* Name of the file storing the common dimensions of indicators */
		G_PING_INDICATOR_CONTENTS
		G_PING_INDICATOR_CONTENTS_SEX
		/* Name of the file storing the correspondance between EU-SILC variables and Eurobase dimensions*/
		G_PING_VARIABLE_DIMENSION
		/* Name of the file storing the correspondance between EU-SILC variables and Eurobase indicators*
		* and format*/ /* added by nobody on 07/12/2016*/
		G_PING_VARIABLExINDICATOR
		G_PING_VARIABLE_DIMENSION
		/* Name of the file storing the correspondance between EU-SILC variables and derived variables 	*/ 
		G_PING_VARIABLExVARIABLE
		/* Threshold used to decide whether to compute an aggregate or not for a given indicator and	*
		* a given area: the cumulated population of available countries for this indicator is tested	*
	 	* against the total population of the considered area. 											*
		* default: 0.7 which means that an indicator will be computed whenever the population of 		*   
	 	* available countries sums up to more than 70% of the total population of the area 				*/
		G_PING_AGG_POP_THRESH
		; 	
/* note: all these variables can be set to default values by running macro _setup_par_ below */

%global 
		/* Full path of the library directory 															*
		* default:	&G_PING_ROOTPATH/library								   							*/
		G_PING_LIBRARY
		/* Full path of the autoexec directory 															*
		* default: &G_PING_ROOTPATH/library/autoexec/													*/ 
		G_PING_LIBAUTO
		/* Full path of the directory with generic programs												*
		* default: &G_PING_ROOTPATH/library/pgm/ 														*/ 
		G_PING_LIBPGM
		/* Full path of the data in library directory													*
		* default: &G_PING_ROOTPATH/library/data 														*/ 
		G_PING_LIBDATA
		/* Full path for the default library of configuration files (e.g. used for environment			*
		* settings)																						*
		* default: value of &G_PING_ROOTPATH/library/config 											*/ 
		G_PING_LIBCONFIG
		/* Variable set to the full path for the default catalog of format files 						*
		* default: value of &G_PING_ROOTPATH/library/catalog 											*/ 
		G_PING_CATFORMAT
		/* Full path of the test directory																*
		* default: &G_PING_ROOTPATH/test/ 																*/ 
		G_PING_LIBTEST
		/* Full path of the programs in test directory													*
		* default: &G_PING_ROOTPATH/test/pgm 															*/ 
		G_PING_LIBTESTPGM
		/* Full path of the data in test directory														*
		* default: &G_PING_ROOTPATH/test/data 															*/ 
		G_PING_LIBTESTDATA
		/* Default directory used to store output html reports */
		G_PING_DIRREPORT
		; 	
/* note: all these variables can be set to default values by running macro _setup_env_ below */

%global 
		/* Variable set to the name (reference) of the library of configuration files 					*
		* default: value of SILCFMT 																	*/ 
		G_PING_LIBCFG 
		/* Full path of the raw data directory 															*
		* default:	&G_PING_ROOTPATH/5.3_Validation/data												*/
		G_PING_RAWDB
		G_PING_LIBRAW
		/* Variable set to the name (reference) of the catalog library of format files					*
		* default: not defined 																*/ 
		G_PING_CATFORMAT 
		/* Full path of the directory with data to upload												*
		* default:	&G_PING_IDBRDB/7.1_Upload/data														*/
		G_PING_LOADDB
		/* Full path of the directory with test datasets												*
		* default:	&G_PING_ROOTPATH/test/data															*/
		G_PING_TESTDB
		;

/* _CHECK_LOCAL_OR_SERVER_
* Automatically retrieve the repository containing a given file 
* In particular, the SAS EG predefined variable _SASSERVERNAME is used for defining 
* if SAS is ran in local or on a local server, instead of SYSSCP (which defines the
* running operating system).  
* This will be used in the following so as to set the variable G_PING_SETUPPATH that
* defines the location of the PING library   */
%macro _check_local_or_server_(file_to_check);

	/* initialise */
	%local _path;
	%let _path=;  
	
	/* but you may run in local... let's check */
	%if %symexist(_SASSERVERNAME) %then %do; /* e.g.: you are running on SAS EG */
		%if &_SASSERVERNAME='Local' %then %do; 
			/* Look for a given file 
			 * unfortunately &_SASPROGRAMFILE is not recognised...
			 */

			/* eet the path of the working directory: 
			* 		are you working using SAS local or SAS server? 
			* This is set automatically */
			/* drives to look through */
			%let lst=Z Y C A B D E F G H I J K L M N O P Q R S T U V W X;
			/* we start at Z, then Y, then C for our setup... it will be faster in this order since that's  
			* the one we use by default... the most common */
			%let start=%sysfunc(indexc(%sysfunc(compress(&lst)),A));
			%let finish=%sysfunc(indexc(%sysfunc(compress(&lst)),Z));

			%if &sysscp = WIN %then %do;  /* local windows */
				%let file_to_check=%sysfunc(translate(&file_to_check, \, /));
				%do i = &start %to &finish;
					%let drv = %scan(&lst,&i);
					%if %sysevalf(%sysfunc(fileexist(&drv.:/&file_to_check))) %then
						/* maybe on your drive...? */                        
						%let _path=&drv.:;
					%else %if %sysevalf(%sysfunc(fileexist(&drv.:\home\&file_to_check))) %then
						/* let us give it a second chance: maybe on your home directory...? */
						%let _path=&drv.:/home;
					%if &_path^= %then %goto quit;
				%end;
			%end;
			%else %do; /* e.g., local linux/solaris server */
				%do i = &start %to &finish;
					%let drv = %scan(&lst,&i);
					%if %sysevalf(%sysfunc(fileexist(/&drv./&file_to_check))) %then
						/* maybe on your drive...? */                        
						%let _path=/&drv;
					%else %if %sysevalf(%sysfunc(fileexist(/&drv./local/&file_to_check))) %then 
						/* let us give it a second chance: maybe on your local directory...? */                        
						%let _path=/&drv./local;
					%if &_path^= %then %goto quit;
				%end;
			%end;
			%goto quit; /* skip the next "%let" instruction */
		%end;

	%end;

	/* at this stage:
	 * - either you do not run on SAS EG (_SASSERVERNAME is not defined), 
	 * - or you run on the server: _SASSERVERNAME=SASMain 
	 * in both cases we define _path as the following */
	%let _path=&SASMain;

	%quit:
	/* "return" the path */
	/*data _null_;
		call symput("&_root_","&_path");
	run;*/
	&_path

	%exit:
%mend _check_local_or_server_;
	
/* _SETUP_ENV_
* Set the (global) environment variables G_PING_SETUPPATH, G_PING_PROJECT and 
* G_PING_DATAPATH for  SAS setup/install, as well as the (global) variable 
* G_PING_ROOTPATH */
%macro _setup_env_;
	
	/* retrieve of define the directory where PING is installed */
	%if not %symexist(G_PING_SETUPPATH) %then %do;
		%global G_PING_SETUPPATH;	 
		%let G_PING_SETUPPATH=;
	%end;
	%if "&G_PING_SETUPPATH"="" %then %do;
		%let SASMain=%substr(&SASServer,1,%eval(%index(&SASServer,/sas/)+3));
		%let G_PING_ROOTPATH=%_check_local_or_server_(PING/library/autoexec/_setup_.&SASext);
	 	%let G_PING_SETUPPATH=&G_PING_ROOTPATH./PING;
	%end;
	%else %do;
		%let G_PING_ROOTPATH=%substr(&G_PING_SETUPPATH,1,%eval(%index(&G_PING_SETUPPATH,/PING)-1)); 
	%end;

	/* retrieve of define the name of the project */
	%if not %symexist(G_PING_PROJECT) %then %do;
		%global G_PING_PROJECT;
		%let G_PING_PROJECT=;	
	%end;
	/* some arbitrary default... */
	%if "&G_PING_PROJECT"="" %then %let G_PING_PROJECT=PING; 

	/* retrieve of define the repository where data are stored */
	%if not %symexist(G_PING_DATABASE) %then %do;
		%global G_PING_DATABASE;
		%let G_PING_DATABASE=;	
	%end;
	/* some arbitrary default... */
	%if "&G_PING_DATABASE"="" %then %let G_PING_DATABASE=&G_PING_ROOTPATH; 

%mend _setup_env_;


/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/
/** !!! NO NEED TO MODIFY THE SETUP FILE BELOW !!! **/
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/

/* _SETUP_LOC_
*/
%macro _setup_loc_(debug=no); /* default locations */

	%let G_PING_LIBRARY=		&G_PING_SETUPPATH/library; 
	%let G_PING_LIBAUTO=		&G_PING_LIBRARY/autoexec; 
	%let G_PING_LIBPGM=			&G_PING_LIBRARY/pgm; 
	%let G_PING_LIBDATA=		&G_PING_LIBRARY/data; 
	%let G_PING_LIBCONFIG=		&G_PING_LIBRARY/config;
	%let G_PING_CATFORMAT=		&G_PING_LIBRARY/catalog;

	%let G_PING_INTEGRATION=	&G_PING_SETUPPATH/5.1_Integration;
	%let G_PING_VALIDATION=		&G_PING_SETUPPATH/5.3_Validation;
	%let G_PING_EXTRACTION=		&G_PING_SETUPPATH/5.5_Extraction;
	%let G_PING_ESTIMATION=		&G_PING_SETUPPATH/5.5_Estimation;
	%let G_PING_MODULES=		&G_PING_SETUPPATH/5.5_Modules;
	%let G_PING_AGGREGATES=		&G_PING_SETUPPATH/5.7_Aggregates;
	%let G_PING_ANALYSIS=		&G_PING_SETUPPATH/6.3_Analysis;
	%let G_PING_VISUALISATION=	&G_PING_SETUPPATH/6.3_Visualisation;
	%let G_PING_ANONYMISATION=	&G_PING_SETUPPATH/6.4_Anonymisation;
	%let G_PING_SERVICES=		&G_PING_SETUPPATH/7.4_Services;
	%let G_PING_UPLOAD=			&G_PING_SETUPPATH/7.1_Upload;
	%let G_PING_DISSEMINATION=	&G_PING_SETUPPATH/7.3_Dissemination;

	%let G_PING_LIBTEST=		&G_PING_SETUPPATH/test; 
	%let G_PING_LIBTESTPGM=		&G_PING_LIBTEST/pgm;
	%let G_PING_LIBTESTDATA=	&G_PING_LIBTEST/data; /* see G_PING_TESTDB */

%mend _setup_loc_;

/* _SETUP_AUTO_
* Automatically load all macros available through the PING environment defined by 
* the global variable G_PING_SETUPPATH */
%macro _setup_auto_; 

	options MRECALL;
	options MAUTOSOURCE;
	options SASAUTOS =(SASAUTOS 
						/*"&G_PING_LIBAUTO/autoexec/"*/
						"&G_PING_LIBRARY/pgm/" 		
						"&G_PING_SETUPPATH/library/test" 			
						"&G_PING_INTEGRATION/pgm/"
						"&G_PING_INTEGRATION/meta/"
						/*"&G_PING_VALIDATION/pgm/"
						"&G_PING_VALIDATION/meta/"*/
						"&G_PING_EXTRACTION/pgm/"
						"&G_PING_EXTRACTION/meta/"
						"&G_PING_ESTIMATION/pgm/"
						"&G_PING_ESTIMATION/meta/"
						"&G_PING_AGGREGATES/pgm/"
						"&G_PING_AGGREGATES/meta/"
						"&G_PING_ANALYSIS/pgm/"
						/*"&G_PING_ANALYSIS/meta/"*/
						"&G_PING_ANONYMISATION/pgm/"
						/*"&G_PING_ANONYMISATION/meta/"*/
						"&G_PING_UPLOAD/pgm/"
						/*"&G_PING_UPLOAD/meta/"*/
						"&G_PING_DISSEMINATION/pgm/"
						/*"&G_PING_DISSEMINATION/meta/"*/
						"&G_PING_SERVICES/pgm/"
						/*"&G_PING_SERVICES/meta/"*/
						"&G_PING_VISUALISATION/pgm/"
						/*"&G_PING_VISUALISATION/meta/"*/
						);
	options NOMRECALL;

%mend _setup_auto_;

/* _SETUP_LIB_
*/
%macro _setup_lib_;

	libname LIBCFG "&G_PING_LIBCONFIG";
	libname SILCFMT "&G_PING_LIBCONFIG"; /* that's our own: legacy */
	%let G_PING_LIBCFG=LIBCFG;

	libname LIBRAW "&G_PING_RAWDB";
	%let G_PING_LIBRAW=LIBRAW;

	libname LIBLOG "&G_PING_LOGDIR";
	%let G_PING_LIBLOG=LIBLOG;

	libname CATFMT "&G_PING_CATFORMAT"; 
	%let G_PING_CATFMT=CATFMT;

%mend _setup_lib_; 

/* _SETUP_VAR_
*/
%macro _setup_var_(debug=no);

	%let debug=%upcase(&debug);
	%if "&debug"="YES" %then  			%let G_PING_DEBUG=0;
	%else %if "&debug"="YES" %then 		%let G_PING_DEBUG=1;
	/* %else: should be numeric */

	%let G_PING_MACHINE_EPSILON=		%sysevalf(1./10**14);
	%let G_PING_LIST_SEPARATOR=			_; /*:*/
	%let G_PING_UNLIKELY_CHAR=			£; /* most unlikely to be used in a list: there is something good about the Brexit... */

	%let G_PING_IDOP=					_ID_; 
	%let G_PING_FMT_CODE=				csv;

	%let G_PING_ERROR_MSG=;
	%let G_PING_ERROR_CODE=;
	%let G_PING_ERROR_MACRO=;

	%let G_PING_COUNTRY_ORDER=			META_COUNTRY_ORDER;
	%let G_PING_POPULATIONXCOUNTRY=		META_POPULATIONxCOUNTRY; 
	%let G_PING_ZONEXYEAR=				META_ZONExYEAR;

	%let countryx=                      META_COUNTRYx;
	%let G_PING_COUNTRYXZONE=			&countryx.ZONE;
	%let G_PING_COUNTRYXZONEYEAR=		&countryx.ZONEYEAR;

	%let G_PING_INDICATOR_CONTENTS=		META_INDICATOR_CONTENTS;
	%let G_PING_VARIABLE_DIMENSION=		META_VARIABLE_DIMENSION;
	%let G_PING_VARIABLExINDICATOR=		META_VARIABLExINDICATOR;  
	%let G_PING_VARIABLExVARIABLE=		META_VARIABLExVARIABLE;
	%let G_PING_INDICATOR_CONTENTS_SEX= META_INDICATOR_CONTENTS_SEX;

%mend _setup_var_;

/* _SETUP_LAB_
*/
%macro _setup_lab_;
	%let G_PING_LAB_GEO=	geo;
	%let G_PING_LAB_TIME=	time; /* year? */
	%let G_PING_LAB_ZONE=	zone;
	%let G_PING_LAB_UNIT=	unit;
	%let G_PING_LAB_VALUE=	ivalue;
	%let G_PING_LAB_UNREL=	unrel;
	%let G_PING_LAB_N=		n;
	%let G_PING_LAB_NWGH=	nwgh;
	%let G_PING_LAB_NTOT=	ntot;
	%let G_PING_LAB_TOTWGH=	ntotwgh;
	%let G_PING_LAB_IFLAG=	iflag;
	%let G_PING_LAB_WEIGHT= weight;

	%let G_PING_LEN_GEO=15;
	%let G_PING_LEN_TIME=4;
	%let G_PING_LEN_UNIT=8;
	%let G_PING_LEN_IFLAG=8;
%mend _setup_lab_;

/* _DEFAULT_SETUP_
* Launch "everything" together in one single macro
*/
%macro _default_setup_;
	%_setup_env_;
	%_setup_loc_(debug=no); /* legacy environment and no test */
	%_setup_auto_;
	%_setup_lib_;
	%_setup_lab_;
	%_setup_var_;
%mend _default_setup_;


/** \endcond */
