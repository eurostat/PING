/** 
## udb_ds_split {#sas_udb_ds_split}
Split a EU-SILC dataset into subsets and exports onto the filesystem into a hierarchical directory 
structure where each (sub)folder stores the files that contain microdata (sub)sets for a given 
country and a given year.

~~~sas
	%udb_ds_split(geo, time, idsn, ofn=, idir=, odir=, fext=csv, dirby=GEO);
~~~

### Arguments
* `geo` : list of desired countries ISO-codes		
* `time` : list of desired years 					
* `idsn` : input dataset 
* `dirby` : 	
* `fext` : 	
* `ilib` : 

### Returns
* `ofn` : 
* `odir` : 

### See also
[%silc_ds_split](@ref sas_silc_ds_split).
*/ /** \cond */

/* credits: grazzja */

%macro udb_ds_split(geo			/* List of desired countries ISO-codse 			(REQ) */
					, time		/* List of desired years 						(REQ) */
					, idsn		/* Input dataset 								(REQ) */
					, ofn=
					, fext=
					, dirby=
					, ilib= 	/* Input library name 							(OPT) */
					, odir=		/* */
					);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %macro_isblank(geo) or %macro_isblank(time) or %macro_isblank(idsn) %then 
		%goto exit;

	/************************************************************************************/
	/**                         some useful macro declaration                          **/
	/************************************************************************************/

	/* _DIR_CHECKANDCREATE
	* Check the existence of a given directory, and possibly create it in case it does not exist 
	* already:
	*  - 0: the directory already exists,
	*  - -1: the directory does not exist and has not been created,
	*  - 1: the directory did not exist but has been created using the option MAKE=YES.	
	%macro _dir_checkAndCreate(dir	, make=);
		%local rc fref did ans;
		%let ans=0; %let fref=;
		%if "&make" EQ "" %then 		%let make=NO;
		%else 							%let make=%upcase(&make);
		%let rc = %sysfunc (filename(fref, &dir));
		%if not %sysfunc(fexist(&fref)) %then %do;
			%let ans=-1;
			%if "&make"="YES" %then %do;
				%sysexec mkdir &dir;
				%let ans=1;
			%end;
		%end;
		%else %do;
			%let did=%sysfunc(dopen(&fref));
		   	%if &did NE 0 %then %do;
				%let ans=-1;
		     	%let rc=%sysfunc(dclose(&did));
			%end;
		%end;
	   	%let rc=%sysfunc(filename(fref));
		%exit:
		&ans
	%mend _dir_checkAndCreate;*/

	/* _DS_CHECK - Use DS_CHECK instead
	* Check the existence of a given dataset
	%macro _ds_check(ds);
		%local rc fref did ans;
		%let ans=0; %let fref=;
		%if not %sysfunc(exist(&ds)) %then		%let ans=1;
		%else %do;
			%let did = %sysfunc( open(&ds) );
			%if %sysfunc( attrn(&did, nobs) ) EQ 0 %then	%let ans=1;
		%end;
	   	%let rc=%sysfunc(filename(fref));
		%exit:
		&ans
	%mend _ds_check; */

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* ILIB/IDSN: check/set default */
	%if %macro_isblank(ilib) %then 					%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* ODIR/OFN: checking */
	%if %macro_isblank(odir) %then 					%let odir=&idir;
	%if %macro_isblank(ofn) %then 					%let ofn=&idsn._;

	%if %error_handle(WarningOutputParameter, 
			%dir_check(&odir, mkdir=YES) EQ 1, mac=&_mac,		
			txt=%quote(! Output directory %upcase(&odir) will be created !), verb=warn) %then
		%goto warning0;
	%warning0:

	/* GEO/CTRIES: check/set 
	* TIME: check/set 
	* test is performed in SILC_DS_SPLIT */

	/* DIRBY: set default/update parameter */
	%if %macro_isblank(dirby)  %then 			%let dirby=GEO; 
	%else										%let dirby=%upcase(&dirby);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&dirby, type=CHAR, set=GEO TIME FLAT) NE 0, mac=&_mac,		
			txt=%quote(!!! Structure directory DIRBY should be either GEO, TIME, or FLAT !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _l _c _b _y _ans
		_vars _where _diff
		db idsn _odir _db
		__years _year _yy
		__ctries _ctry;

	/* from the imported file &IDSN, extract (in one shot) the subsets of data per year/country 
	* this will create several subsets, one for each country, each year	*/
	%let __years=;
	%let __ctries=;
	%let _db=;
	/* also use &IDSN as a generic name for the output extracted file */
	%silc_ds_split(&geo, &time, &idsn, odsn=&idsn, _db_=_db, _ctrylst_=__ctries, _yearlst_=__years, 
		ilib=&ilib, olib=WORK);
	/* the list of countries/years actually extracted is returned in the variables __CTRIES and __YEARS */

	/* loop... */
	%do _y=1 %to %list_length(&__years);
		%let _year=%scan(&__years, &_y);
		%let _yy=%substr(&_year,3,2);

		%do _c=1 %to %list_length(&__ctries);
			%let _ctry=%scan(&__ctries, &_c);

			/* build the input file name &_IDSN using the generic IDSN argument */
			%let _idsn=&idsn.&_ctry.&_yy.&_db;
			/* the file _IDSN has been created through the call to the macro UDB_DS_SPLIT */

			/* since you are here, also build the output file name _OFN using the generic OFN 
			* argument */
			%let _ofn=&ofn.&_ctry.&_yy.&_db;

			%if %error_handle(WarningOutputDataset, 
					%ds_check(&_idsn, lib=WORK) EQ 1, mac=&_mac,		
					txt=! No data available for geo=&_ctry and time=_year !, verb=warn) %then 
				%goto next;

			/* initialise the current directory */
			%let _odir=&odir;
			%if "&dirby" ^= "FLAT" %then %do;
				/* define the subdirectory */
				%do _b=1 %to 2;
					%if "&dirby"="GEO" %then %do;
						%if &_b=1 %then 	%let _sub=&_ctry;
						%else 				%let _sub=&_year;
					%end;
					%else %do;
						%if &_b=1 %then 	%let _sub=&_year;
						%else  				%let _sub=&_ctry;
					%end;
					%let _odir=&_odir/&_sub;

					%if %error_handle(WarningFileOperation, 
							%dir_check(&_odir, mkdir=YES) NE 0, mac=&_mac,		
							txt=%quote(! Output subdirectory %upcase(&_odir) will be created !), verb=warn) %then
						%goto warning2;
					%warning2:
				%end;
			%end;

			/* export the data for given TIME/GEO to the desired _ODIR folder */
			%ds_export(&_idsn, odir=&_odir, ofn=&_ofn, fmt=&fext, ilib=WORK);

			/* clean temporary dataset _IDSN */
			%work_clean(&_idsn);
			%next:
		%end;
	%end;
	
	%exit:
%mend udb_ds_split;


%macro _example_udb_ds_split;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	DATA dbp;
		PB010=2016; PB020="AT"; PB030=1;  output;
		PB010=2016; PB020="AT"; PB030=2;  output;
		PB010=2016; PB020="AT"; PB030=3;  output;
		PB010=2016; PB020="BE"; PB030=4;  output;
		PB010=2016; PB020="BE"; PB030=5;  output;
		PB010=2016; PB020="BG"; PB030=6;  output;
		PB010=2016; PB020="BG"; PB030=7;  output;
		PB010=2015; PB020="AT"; PB030=14; output;
		PB010=2015; PB020="AT"; PB030=15; output;
		PB010=2015; PB020="BE"; PB030=8;  output;
		PB010=2015; PB020="BE"; PB030=9;  output;
		PB010=2015; PB020="BG"; PB030=10; output;
		PB010=2014; PB020="AT"; PB030=11; output;
		PB010=2014; PB020="BE"; PB030=12; output;
		PB010=2014; PB020="BE"; PB030=13; output;
	run;
	
	%udb_ds_split(_ALL_, _ALL_, dbp, ofn=test_, dirby=FLAT, odir=%quote(&G_PING_ROOTPATH/test/DUMMY));

	/* %udb_ds_split(_ALL_, _ALL_, dbp, ofn=test_, dirby=TIME, odir=%quote(&G_PING_ROOTPATH/test/DUMMY)); */
	/* %udb_ds_split(BE, 2014, dbp, ofn=test_, dirby=FLAT, odir=%quote(&G_PING_ROOTPATH/test/DUMMY));*/

%mend _example_udb_ds_split;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_udb_ds_split; 
*/

/** \endcond */
