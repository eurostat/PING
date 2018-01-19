## silc_db_export {#sas_silc_db_export}
Export EU-SILC bulk datasets from SAS format (`.sas7bdat`) to any format supported by `PROC FORMAT`.

~~~sas
	%silc_db_export(survey, time, geo=, db=, src=, _ds_=, _path_=, 
					cds_transxyear=META_TRANSMISSIONxYEAR, clib=LIBCFG);
~~~

### Arguments
* `survey` : type of the survey; this is represented by any of the character values defined in the 
	global variable `G_PING_SURVEYTYPES`, _i.e._ as:
		+ `X`. `C` or `CROSS` for a cross-sectional survey,
		+ `L` or `LONG` for a longitudinal survey,
		+ `E` or `EARLY` for an early survey,
* `time` : a single selected year of interest; 
* `geo` : string(s) representing the ISO-code(s) of (a) country(ies); note that when `geo`is not 
	passed and `src=raw` (see below), the output parameters `_path_` and `_ds_` cannot be defined: 
	only `_ftyp_` can be returned (see below); in all other cases, `geo` is ignored;
* `db` : (_option_) database(s) to retrieve; it can be any of the character values defined through 
	the global variable `G_PING_BASETYPES`, _i.e._:
		+ `D` for household register/D file,
		+ `H` for household/H file,
		+ `P` for personal register/P file,
		+ `R` for register/R file,
	so as to represent the corresponding bulk databases (files); by default,`db=&G_PING_BASETYPES`; 
* `src` : (_option_) string defining the source location where to look for bulk database; this can 
	be either the full path of the directory where to search in, or any of the following strings:
		+ `bdb`, ibid with the value of `G_PING_BDB`,
		+ `pdb`, ibid with the value of `G_PING_PDB`,
		+ `idb`, ibid with the value of `G_PING_IDB`,
		+ `udb`, ibid with the value of `G_PING_UDB`;
	note that the latter four cases are independent of the parameter chosen for `geo`;	note also
	that `src=bdb` and `src=idb` are incompatible with `survey<>X`; furthermore, when `src=idb`, 
	the parameter `db` is ignored; by default, `src` is set to the value of `G_PING_RAWDB` (_e.g._ 
	`&G_PING_ROOTPATH/main`) so as to look for raw data;
* `cds_transxyear, clib` : (_options_) configuration file storing the the yearly definition of
	microdata transmission files' format, and library where it is actually stored; for further 
	description of the table, see [%meta_transmissionxyear](@ref meta_transmissionxyear) and 
	[%silc_db_locate](@ref sas_silc_db_locate).

### Returns
* `_ofn_` : name (string) of the macro variable storing the output exported file name.
* `odir` : (_option_) output directory/library to store the converted dataset; by default,
	it is set to:
			+ the location of your project if you are using SAS EG (see [%_egp_path](@ref sas__egp_path)),
			+ the path of `%sysget(SAS_EXECFILEPATH)` if you are running on a Windows server,
			+ the location of the library passed through `ilib` (_i.e._, `%sysfunc(pathname(&ilib))`) 
			otherwise.

## Example
Let us export some bulk datasets from the so-called BDB into `Stata` native format (`dta`):

~~~sas
	%let survey=CROSS;
	%let time=2015;
	%let src=BDB;
	%let db=D H R;
	%let fmt=dta;
	%let odir=&G_PING_ROOTPATH;
	%silc_db_export(CROSS, 2015, odir=&odir, _ofn_=ofn, fmt=&fmt, db=&db, src=&src);
~~~

In our current environment (see `G_PING_ROOTPATH` definition), the following output files will be created:
* 0eusilc/bdb_c15d.dta
* 0eusilc/bdb_c15h.dta
* 0eusilc/bdb_c15r.dta
	
### See also
[%silc_ds_extract](@ref sas_silc_ds_extract), [%silc_db_locate](@ref sas_silc_db_locate),
[%ds_export](@ref sas_ds_export), [%meta_transmissionxyear](@ref meta_transmissionxyear).
**/ 

/* credits: gjacopo */

%macro silc_db_export(survey			/* Input type of the survey 											(REQ) */ 
					, time				/* Input year under consideration 										(REQ) */ 
					, geo=				/* Input country under consideration 										(REQ) */ 
					, odir=				/* Full path of output directory 										(OPT) */
					, _ofn_=			/* Name of the variable storing the output filename 					(OPT) */
					, fmt=				/* Format of import 													(OPT) */
					, db=				/* Input database to retrieve 											(OPT) */
					, src=				/* Input location of bulk data source 									(OPT) */
					, cds_transxyear=	/* Name of configuration file storing the type of transmission files 	(OPT) */
					, clib=				/* Name of the configuration library 								 	(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local YEARINIT;

	/* GEO: check/set input ISO-code 
	* DB: check the bulk database definition  
	* SURVEY: check/reset the survey type 
	* SRC/DIR: check/set input directory 
	* the default settings + basic checkings are made in silc_db_locate below */

	/* TIME: check/set */
	%if %symexist(G_PING_INITIAL_YEAR) %then 	%let YEARINIT=&G_PING_INITIAL_YEAR;
	%else										%let YEARINIT=2002;

	%if %error_handle(ErrorInputParameter, 
			%par_check(&time, type=INTEGER, range=&YEARINIT) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input TIME !!!)) %then
		%goto exit;
	%else
		%let yy=%substr(&time,3,2);

	/* ODIR:  default setting and checking odir */
	%if %macro_isblank(odir) %then %do; 
		%if %symexist(_SASSERVERNAME) %then /* working with SAS EG */
			%let odir=&G_PING_ROOTPATH/%_egp_path(path=drive);
		%else %if &sysscp = WIN %then %do; 	/* working on Windows server */
			%let odir=%sysget(SAS_EXECFILEPATH);
			%if not %macro_isblank(odir) %then
				%let odir=%qsubstr(&odir, 1, %length(&odir)-%length(%sysget(SAS_EXECFILENAME));
		%end;
	%end;
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(odir) EQ 1, mac=&_mac,		
			txt=%quote(!!! Output directory %upcase(&odir) not set !!!))
			or %error_handle(ErrorInputParameter, 
				%dir_check(&odir) NE 0, mac=&_mac,		
				txt=%quote(!!! Output directory %upcase(&odir) does not exist !!!)) %then
		%goto exit;

	/* FMT */
	%if %macro_isblank(fmt) %then 		%let fmt=csv;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i _ofn
		ds path
		SEP;
	%let SEP=%quote( );
	%let _ofn=;

	%silc_db_locate(&survey, &time, geo=&geo, db=&db, src=&src, _ds_=ds, _path_=path, 	
					cds_transxyear=&cds_transxyear, clib=&clib, lazy=YES);

	%if not %macro_isblank(_ofn_) %then 	%let &_ofn_=;

	%do _i=1 %to %list_length(&ds);
		libname tmplib "%scan(&path,&_i, &SEP)";
		%let idsn=%scan(&ds, &_i);
		%ds_export(&idsn, odir=&odir, _ofn_=_ofn, fmt=&fmt, ilib=tmplib);
		libname tmplib clear;
		%if not %macro_isblank(_ofn_) %then %let &_ofn_=&&&_ofn_ &_ofn;
	%end;

	%exit:
%mend silc_db_export;

%macro _example_silc_db_export;
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

	%local _i survey time src ofn odir fmt db;
	%let ofn=;

	/* we currently launch this example in the highest level (1) of debug only */
	%if %symexist(G_PING_DEBUG) %then 	%let olddebug=&G_PING_DEBUG;
	%else %do;
		%global G_PING_DEBUG;
		%let olddebug=0;
	%end;
	%let G_PING_DEBUG=1;

	%let survey=CROSS;
	%let time=2015;
	%let src=BDB;
	%let db=D H R;
	%let fmt=dta;
	%let odir=/ec/prod/server/sas/0eusilc;
	%put Given the following parameters:; 
	%put -         survey=&survey;
	%put -         time=&time;
	%put -         src=&src;
	%put -         db=&db;
	%put -         fmt=&fmt;
	%put -         odir=&odir; 
	%silc_db_export(&survey, &time, odir=&odir, _ofn_=ofn, fmt=dta, db=&db, src=&src);
	%put the following output files will be created:;
	%do _i=1 %to %list_length(&ofn);
		%put -         %scan(&ofn, &_i, %quote( ));
	%end;

	/* reset the debug as it was (if it ever was set) */
	%let G_PING_DEBUG=&olddebug;

	%put;

	%exit:
%mend _example_silc_db_export;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_db_export; 
