/** 
## SAS silc_db_locate {#sas_silc_db_locate}
~~~sas
	%silc_db_locate(survey, time, geo=, db=, src=, 
					_ftyp_=, _ds_=, _path_=, 
					cds_transxyear=META_TRANSMISSIONxYEAR, clib=LIBCFG);
~~~

### Arguments
* `survey` : type of the survey; this is represented by any of the character values defined in the 
	global variable `G_PING_SURVEYTYPES`, _i.e._ as:
		+ `X`. `C` or `CROSS` for a cross-sectional survey,
		+ `L` or `LONG` for a longitudinal survey,
		+ `E` or `EARLY` for an early survey,
* `time` : a single selected year of interest; 
* `geo` : (_option_) string(s) representing the ISO-code(s) of (a) country(ies); note that when `geo`
	is not passed and `&src=raw` (see below), the output parameters `_path_` and `_ds_` cannot be defined: 
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
		+ `raw` so that the path of the search directory is set to the value of `G_PING_RAWDB`,
		+ `bdb`, ibid with the value of `G_PING_BDB`,
		+ `pdb`, ibid with the value of `G_PING_PDB`,
		+ `idb`, ibid with the value of `G_PING_IDB`,
		+ `udb`, ibid with the value of `G_PING_UDB`;

	note that the latter four cases are independent of the parameter chosen for `geo`;	note also
	that `src=bdb` and `src=idb` are incompatible with `survey<>X`; furthermore, when `src=idb`, 
	the parameter `db` is ignored; by default, `src` is set to `&G_PING_RAWDB` (_e.g._ 
	`&G_PING_ROOTPATH/main`) so as to look for raw data;
* `cds_transxyear, clib` : (_options_) configuration file storing the the yearly definition of
	microdata transmission files' format, and library where it is actually stored; for further 
	description of the table, see [%meta_transmissionxyear](@ref meta_transmissionxyear); this 
	will be essentially used when `src=RAW`.
 
### Returns
* `_ftyp_` : (_option_) longitudinal, cross-sectional or reconsilied/regular
* `_ds_` : (_option_) name(s) of the bulk dataset(s) extracted from the databases in `db`; in 
	practice, all bulk datasets (files) have generic name of the form:
		+ `&ts.&yy.&db` when `src` is in (`pdb`,`udb`),
		+ `bdb_&ts.&yy.&db` when `src=bdb` (`bdb_c` available only),
		+ `idb.&yy` when `src=idb`,
		+ `&ts.&geo.&yy.&db` when `src=bdb`,

	where:
		+ `ts` is the type of the tranmission file whose definition depends on `survey` (_i.e._ 
		either `C, L, E`, or `R`),
		+ `db` is any element of `db` (_i.e._ either `D, H, P`, or `R`),
		+ `geo` is any ISO-code represented in `geo`,
		+ `yy` is composed of the last two digits of a`time` (_i.e._ if `time=2014`, then `yy=14`)

	and are retrieved from the database library associated to `src`;
* `_path_` : (_option_) path to longitudinal, cross-sectional or reconsilied/regular database(s), 
	set depending on `src`.

### Examples
Let us consider the following simple example:
	
~~~sas
	%let ftyp=;
	%silc_db_locate(X, 2014, _ftyp_=ftyp);
~~~
will return `ftyp=r` because cross-sectional data are normally transmitted via regular (R) files 
since 2014. We can further retrieve the location of the corresponding `H` file:

~~~sas
	%let ds=;
	%let path=;
	%silc_db_locate(X, 2014, geo=AT, db=H, _ds_=ds, _path_=path);
~~~
will set `path=/ec/prod/server/sas/0eusilc/main/at/r14` and `ds=rat14h`, while

~~~sas
	%let ds=;
	%let path=;
	%silc_db_locate(X, 2014, geo=AT DE, db=H, _ds_=ds, _path_=path);
~~~	
will set `path=/ec/prod/server/sas/0eusilc/main/at/r14 /ec/prod/server/sas/0eusilc/main/de/c14` and 
`ds=rat14h cde14h`. It is then possible to reconstruct the full paths:

~~~sas
	%let file=%list_append(&path, &ds, zip=%quote(/), rep=%quote( ));
	%let file=%list_append(&file, %list_ones(%list_length(&file), item=sas7bdat), zip=%quote(.));
~~~
sets `file=/ec/prod/server/sas/0eusilc/main/at/r14/rat14h.sas7bdat /ec/prod/server/sas/0eusilc/main/de/c14/cde14h.sas7bdat`.
Finally:

~~~sas
	%let ftyp=;
	%let ds=;
	%let path=;
	%silc_db_locate(X, 2014, geo=AT DE, db=R H, _ftyp_=ftyp, _ds_=ds, _path_=path);
~~~
sets `ftyp=r c`, `path=/ec/prod/server/sas/0eusilc/main/at/r14 /ec/prod/server/sas/0eusilc/main/at/r14
/ec/prod/server/sas/0eusilc/main/de/c14 /ec/prod/server/sas/0eusilc/main/de/c14` and 
`ds=rat14r rat14h cde14r cde14h`.

Run `%%_example_silc_db_locate` for more examples.

### Notes
1. The existence of returned path (in `_path_`) and dataset (in `_ds_`) is not verified.
2. In order to retrieve the type of the transmission file (returned through `_ftyp_`), this 
macro runs in practice:

~~~sas
	PROC SQL noprint;
		SELECT Y&time
		INTO :&_ftyp_
		%if %list_length(&geo)>0 %then %do;
			SEPARATED BY " "
		%end;
		FROM &clib..&cds_transxyear
		WHERE transmission="%upcase(&survey)" and
		%if %list_length(&geo)>0 and &src=raw %then %do;
			geo in (%list_quote(&geo))
		%end;
		%else %do;
			missing(geo)
		%end;
		;
	quit;
~~~
  Following, to retrieve the common type `ftyp` of transmission files for a given year `time` 
and a survey of type `survey`, simply run:
	
~~~sas
	%let ftyp=;
	%silc_db_locate(&survey, &time, _ftyp_=ftyp);
~~~
3. Note that from the output path and dataset, you can easily reconstruct the full path(s) 
(directory name + dataset name + extension) of the original SAS files, _e.g._ for given `survey, 
db, time` and `geo`: 

~~~sas
	%let ds=;
	%let path=;
	%silc_db_locate(survey, db, time, geo=geo, _ds_=ds, _path_=path);
	%let fullpath=%list_append(&path, &ds, zip=%quote(/), rep=%quote( ));
	%let fullpath=%list_append(&fullpath, %list_ones(%list_length(&fullpath), item=sas7bdat), 
	                              zip=%quote(.), rep=%quote( - ));
~~~
	
### See also
[silc_db_locate (Stata)](@ref stata_silc_db_locate), [%silc_ds_extract](@ref sas_silc_ds_extract),
[%meta_transmissionxyear](@ref meta_transmissionxyear).
*/ /** \cond */

/* credits: gjacopo */

/* Locate the bulk database (pathname and datasets name) corresponding to given survey (cross-sectional, 
longitudinal or early), a period and/or a country */
%macro silc_db_locate(survey			/* Input type of the survey 												(REQ) */ 
					, time				/* Input year under consideration 											(REQ) */ 
					, geo=				/* Input country under consideration 										(REQ) */ 
					, db=				/* Input database to retrieve 												(OPT) */
					, src=				/* Input location of bulk data source 										(OPT) */
					, _ftyp_=			/* Name of macro variable storing the output type of transmission files 	(OPT) */
					, _ds_=				/* Name of macro variable storing the output name(s) of the bulk datasets 	(OPT) */
					, _path_=			/* Name of macro variable storing the output path to dataset(s) 			(OPT) */
					, cds_transxyear=	/* Name of configuration file storing the type of transmission files 		(OPT) */
					, clib=				/* Name of the configuration library 										(OPT) */
					, lazy=
					);

	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local dir		/* full path */
		YEARINIT	/* initial year of survey */
		BASETYPES 	/* name of all bulk datasets */
		SURVEYTYPES;	/* reference to all survey types */

	/* DEBUG/LAZY modes */
	%if %macro_isblank(lazy) %then %do;
		%if %symexist(G_PING_LAZY) %then 		%let lazy=&G_PING_LAZY;
		%else									%let lazy=NO;
	%end;

	/* TIME: check the year of interest */
	%if %symexist(G_PING_INITIAL_YEAR) %then 	%let YEARINIT=&G_PING_INITIAL_YEAR;
	%else										%let YEARINIT=2002;

	%if %error_handle(ErrorInputParameter, 
			%par_check(&time, type=INTEGER, range=&YEARINIT) NE 0,	mac=&_mac,
			txt=%bquote(!!! Wrong value for TIME parameter: must be integer >&YEARINIT !!!)) %then
		%goto exit;

	/* GEO: check/set input ISO-code */
	%if not %macro_isblank(geo) %then %do; 
		%if %upcase("&lazy")=YES %then %goto skip;
		%local ans;
		%str_isgeo(&geo, _ans_=ans);

		%if %error_handle(ErrorInputParameter, 
				&ans NE %list_ones(%list_length(&geo), item=1), mac=&_mac,
				txt=%bquote(!!! Wrong value(s) for GEO parameter: &geo - Must be country ISO-code(s) !!!)) %then
			%goto exit;		
		%skip:
	%end;
	%else %if "&src" EQ "RAW" %then %do;
		%if %error_handle(WarningOutputParameter, 
				%macro_isblank(_path_) EQ 0 or %macro_isblank(_ds_) EQ 0, mac=&_mac,
				txt=%bquote(! Output parameters _path_ and _ds_ cannot be defined without GEO being passed!), verb=warn) %then
			%goto warning1;
	%end;
	%warning1:

	/* DB: check the bulk database definition  */
	%if %symexist(G_PING_BASETYPES) %then 		%let BASETYPES=&G_PING_BASETYPES;
	%else										%let BASETYPES=D H P R;

	%if "&src" NE "IDB" %then %do; /* otherwise DB is ignored */
		%if %macro_isblank(db) %then 		%let db=&BASETYPES; 
		%if %error_handle(ErrorInputParameter, 
				%list_difference(%upcase(&db),%upcase(&BASETYPES)) NE ,	mac=&_mac,
				txt=%bquote(!!! Table(s) %upcase(&db) do(es) not exist: must be in (%list_quote(&BASETYPES,mark=_EMPTY_)) !!!)) %then
			%goto exit;
	%end;

	/* SURVEY: check/reset the survey type */
	%if %symexist(G_PING_SURVEYTYPES) %then 	%let SURVEYTYPES=&G_PING_SURVEYTYPES;
	%else										%let SURVEYTYPES=L X E;

	%let survey=%upcase(&survey);
	%if "&survey" EQ "C" or "&survey" EQ "CROSS" %then 		%let survey=X;
	%else %if "&survey" EQ "LONG" %then 					%let survey=L;
	%else %if "&survey" EQ "EARLY" %then 					%let survey=E;
	/* %else %if "&survey"="REGULAR" %then 				%let survey=R;*/
	%if %error_handle(ErrorInputParameter, 
			%par_check(&survey, type=CHAR, set=&SURVEYTYPES) NE 0, mac=&_mac,		
			txt=%bquote(!!! Wrong type for SURVEY: must be in (%list_quote(&SURVEYTYPES,mark=_EMPTY_)) !!!)) %then
	    %goto exit;

	/* SRC/DIR: check/set input directory */
	%if %macro_isblank(src) %then 		%let src=RAW;
	%else 								%let src=%upcase(&src);

	%if %error_handle(ErrorInputParameter, 
			%list_length(&src) GT 1, mac=&_mac,		
			txt=%bquote(!!! Wrong input SRC: must be single bulk database identifier !!!)) %then
	    %goto exit;
	%else %if "&src" EQ "RAW" %then %do;
		%if %symexist(G_PING_RAWDB) %then 		%let dir=&G_PING_RAWDB;
		%else									%let dir=&G_PING_ROOTDIR/main; /* &G_PING_ROOTPATH/5.3_Validation/data */
	%end;
	%else %if "&src" EQ "BDB" %then %do;
		%if %symexist(G_PING_BDB) %then 		%let dir=&G_PING_BDB;
		%else									%let dir=&G_PING_ROOTDIR/BDB; /* &G_PING_ROOTPATH/5.5_Extraction/data/BDB */
	%end;
	%else %if "&src" EQ "PDB" %then %do;
		%if %symexist(G_PING_PDB) %then 		%let dir=&G_PING_PDB;
		%else									%let dir=&G_PING_ROOTDIR/pdb; /* &G_PING_ROOTPATH/5.5_Extraction/data/PDB */
	%end;
	%else %if "&src" EQ "IDB" %then %do;
		%if %symexist(G_PING_C_IDB) %then 		%let dir=&G_PING_C_IDB;
		%else									%let dir=&G_PING_ROOTDIR/IDB_RDB/C_IDB;
	%end;
	%else %if "&src" EQ "UDB" %then %do;
		%if %symexist(G_PING_UDB) %then 		%let dir=&G_PING_UDB;
		%else									%let dir=&G_PING_ROOTPATH/7.3_Dissemination/data;
	%end;
	%else %do; /* user transmitted a path */
		%let dir=&src;
		%let src=RAW;
	%end;

	/*  further check */
	%if %error_handle(ExistingOutputDataset, 
			%dir_check(&dir) NE 0, mac=&_mac,
			txt=%quote(!!! Input directory %upcase(&dir) does not exist !!!)) %then 
		%goto exit;
	%else %if %error_handle(ExistingOutputDataset, 
			"&src" EQ "BDB" and "&survey" NE "X",
			txt=%bquote(!!! BDB source compatible with cross-sectional data (SURVEY=X) only !!!)) %then 
		%goto exit;
	%else %if %error_handle(WarningInputParameter, 
			%par_check(&src, type=CHAR, set=BDB PDB UDB) EQ 0 and %macro_isblank(geo) EQ 0, mac=&_mac,		
			txt=%bquote(! Parameter GEO ignored when SRC in (BDB,PDB,UDB) !), verb=warn) %then %do;
		%let geo=;
	    %goto warning2;
	%end;
	%else %if %error_handle(WarningInputParameter, 
			"&src" EQ "IDB" and (%macro_isblank(geo) EQ 0 or %macro_isblank(db) EQ 0), mac=&_mac,		
			txt=%bquote(! Parameter GEO and/or DB ignored when SRC=IDB !), verb=warn) %then %do;
		%let geo=;
		%let db=;
	    %goto warning2;
	%end;
	%warning2:

	/* TRANSxYEAR, CLIB: check/set the configuration file for transmission type when FTYP is not passed */
	%if %macro_isblank(clib) %then %do;
		%if %symexist(G_PING_LIBCFG) %then 				%let clib=&G_PING_LIBCFG;
		%else											%let clib=LIBCFG;
	%end;
	%if %macro_isblank(cds_transxyear) %then %do;
		%if %symexist(G_PING_TRANSMISSIONxYEAR) %then 	%let cds_transxyear=&G_PING_TRANSMISSIONxYEAR;
		%else											%let cds_transxyear=TRANSMISSIONxYEAR;
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* initialisations */
	%local _i _ig _id	/* loop increments */
		_yy
		_ftyp			/*  */
		_typ
		__path
		_pat
		__ds
		_geo
		ngeo
		_db
		l_GEO
		l_TRANSMISSION; /* name of transmission variable in file cds_transxyear */
	%let __ds=;
	%let __path=;
	%let l_TRANSMISSION=data;  /* check that the DATA variable exists in file cds_transxyear */
	%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
	%else										%let l_GEO=geo;

	%let ngeo=%list_length(&geo);

	/* actually retrieve the format of the transmission file for given year */
	%if "&survey" EQ "X" and ("&src" EQ "PDB" or "&src" EQ "UDB") %then %do;
		%if not %macro_isblank(_ftyp_) %then %do;
			DATA _null_;
				call symput ("&_ftyp_", "c");
			run;
		%end;
		%else 									
			%let _ftyp = c;
	%end;
	%else %if "&src" EQ "RAW" or "&src" EQ "PDB" or "&src" EQ "UDB" %then %do;
		PROC SQL noprint;
			SELECT Y&time
			INTO
			%if not %macro_isblank(_ftyp_) %then %do; /* store it already... only way it can work: shitty SAS */ 
				:&_ftyp_
			%end;
			%else %do;
				:_ftyp
			%end;
			%if &ngeo>0 %then %do;
				SEPARATED BY " "
			%end;
			FROM &clib..&cds_transxyear
			WHERE &l_TRANSMISSION="&survey" and
			%if &ngeo>0 and "&src" EQ "RAW" %then %do;
				&l_GEO in (%list_quote(&geo))
			%end;
			%else %do;
				missing(&l_GEO)
			%end;
			;
		quit;
	%end;
	%else %if not %macro_isblank(_ftyp_) %then %do; 
		/* IDB and BDB: cross-sectional data only */
		DATA _null_;
			call symput ("&_ftyp_", "c");
		run;
	%end;

	/* set for use inside here */
	%if not %macro_isblank(_ftyp_) %then 	%let _ftyp=&&&_ftyp_;

	/* extract the last 2 digits of the year */
	%let _yy=%substr(&time,3,2);

	%if &ngeo>0 and "&src" EQ "RAW" %then %do;

		%do _ig=1 %to %list_length(&geo); 
			%let _geo=%lowcase(%scan(&geo, &_ig));
			%let _typ=%lowcase(%scan(&_ftyp, &_ig)); /* _FTYP is the same length as GEO! */
			%let _pat=&dir/&_geo/&_typ.&_yy;
	
			%do _i=1 %to %list_length(&db); 
				%let _db=%lowcase(%scan(&db, &_i));
				%let __ds=&__ds &_typ.&_geo&_yy.&_db; 
				%let __path=&__path &_pat;
			%end;
		%end;
	%end;
	%else %if "&src" EQ "PDB" or "&src" EQ "UDB" %then %do;
		%let _typ=%lowcase(&_ftyp);
		%do _i=1 %to %list_length(&db); 
			%let _db=%lowcase(%scan(&db, &_i));
			%let __ds=&__ds &_typ.&_yy.&_db; 
			%let __path=&__path &dir;
		%end;
	%end;
	%else %if "&src" EQ "BDB" %then %do;
		%let _typ=c;
		%do _i=1 %to %list_length(&db); 
			%let _db=%lowcase(%scan(&db, &_i));
			%let __ds=&__ds bdb_&_typ.&_yy.&_db; 
			%let __path=&__path &dir;
		%end;
	%end;
	%else %if "&src" EQ "IDB" %then %do;
		%let __ds=idb&_yy; 
		%let __path=&dir;
	%end;

	/*	%let &_ds_=%quote(&__ds);
	%let &_path_=%quote(&__path);	*/
	DATA _null_; 
		/* %if not %macro_isblank(_ftyp_) %then %do;
				call symput ("&_ftyp_", "&_ftyp");
			%end; /* done already in the PROC SQL above */
		%if not %macro_isblank(_path_) %then %do;
			call symput ("&_path_", "%quote(&__path)");
		%end;
		%if not %macro_isblank(_ds_) %then %do;
			call symput ("&_ds_", "%quote(&__ds)");
		%end;
		;
	run;

	%exit:
%mend silc_db_locate;

%macro _example_silc_db_locate;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ftyp oftyp ds ods path opath;

	%put;
	%put (i) Locate a bulk DUMMY / RAW / H dataset in year 2014;
	%silc_db_locate(DUMMY, 2014, geo=AT, db=H);

	%put;
	%put (ii) Locate a bulk L / RAW / H dataset in a DUMMY year;
	%silc_db_locate(L, 0, geo=AT, db=H);

	%put;
	%put (iii) Locate a bulk L / RAW / H dataset with a DUMMY country data;
	%silc_db_locate(L, 2014, geo=TA, db=H);

	%put;
	%put (iv) Locate a bulk L / RAW / H dataset with a DUMMY country data in year 2014;
	%silc_db_locate(L, 2014, geo=AT, db=DUMMY);

	%put;
	%put (v) Locate a bulk X / RAW / H dataset with AT data in year 2014;
	%silc_db_locate(X, 2014, geo=AT, db=H, _ftyp_=ftyp, _ds_=ds, _path_=path);
	%put ftyp=&ftyp path=&path ds=&ds;

	%put;
	%put (v) Locate a bulk X / RAW / H dataset with AT and DE data in year 2014;
	%silc_db_locate(X, 2014, geo=AT DE, db=H, _ftyp_=ftyp, _ds_=ds, _path_=path);
	%put ftyp=&ftyp path=&path ds=&ds;
	%let file=%list_append(&path,&ds, zip=%quote(/), rep=%quote( ));

	%put %list_append(&file, %list_ones(%list_length(&file), item=sas7bdat), zip=%quote(.), rep=%quote( - ));

	%put;
	%put (vi) Locate the bulk X / RAW / R and H datasets with AT and DE data in year 2012;
	%silc_db_locate(X, 2012, geo=AT DE, db=R H, _ftyp_=ftyp, _ds_=ds, _path_=path);
	%put ftyp=&ftyp path=&path ds=&ds;
	%let file=%list_append(&path,&ds, zip=%quote(/), rep=%quote( ));
	%put file=&file;
	%put;

	%put (vii) Locate the bulk X / BDB / R and H datasets with AT and DE data in year 2013;
	%silc_db_locate(X, 2013, geo=AT DE, src=bdb, db=R H, _ftyp_=ftyp, _ds_=ds, _path_=path);
	%put ftyp=&ftyp path=&path ds=&ds;

	%put (viii) Locate a bulk X / PDB / R and H datasets in year 2014;
	%silc_db_locate(X, 2014, src=pdb, db=R H, _ftyp_=ftyp, _ds_=ds, _path_=path);
	%put ftyp=&ftyp path=&path ds=&ds;

	%put (ix) Locate a bulk X / IDB dataset in year 2012;
	%silc_db_locate(X, 2012, src=idb, _ftyp_=ftyp, _ds_=ds, _path_=path);
	%put ftyp=&ftyp path=&path ds=&ds;

	%put (x) Locate the bulk X / PDB / R, H, P and D datasets in year 2015;
	%silc_db_locate(X, 2015, src=pdb, _ftyp_=ftyp, _ds_=ds, _path_=path);
	%put ftyp=&ftyp path=&path ds=&ds;

   
%mend _example_silc_db_locate;

/* Uncomment for quick testing
options NOSOURCE NOMRECALL MLOGIC MPRINT NOTES;
%_example_silc_db_locate;
*/


/** \endcond */

