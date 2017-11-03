/** 
## udb_file_split {#sas_udb_file_split}
Split a (csv) file of EU-SILC microdata into a hierarchical directory structure where each
(sub)folder stores the files that contain microdata (sub)sets for a given country and a given
year.
 
~~~sas
	%udb_file_split(geo, time, ifn, ofn=, idir=, odir=, fext=, dirby=);
~~~

### Arguments
* `geo` : list of desired countries ISO-codes		
* `time` : list of desired years 					
* `idsn` : input dataset 							
* `ilib` : input library name 				

### Returns

### Note
The following AWK command:

~~~sh
	awk -F ',' 'NR==1{h=$0; next};!seen[$2]++{f=$2".csv"; print h > f};{f=$2".csv"; print >> f; close(f)}' input.csv
~~~

### See also
[%file_import](@ref sas_file_import), [%udb_db_split](@ref sas_udb_db_split).
*/ /** \cond */

/* credits: grazzja */

%macro udb_file_split(geo		/* List of extracted countries ISO-codse 	(REQ) */
					, time	/* List of extracted years 					(REQ) */
					, ifn	/* */
					, ofn=
					, idir= /* */
					, odir=	/* */
					, fext=
					, dirby=
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local ibase;

	%if %macro_isblank(geo) or %macro_isblank(time) or %macro_isblank(ifn) %then 
		%goto exit;

	/* IDIR/IFN: check/set default */
	%if %macro_isblank(idir) %then 
		/* redecompose the filename ... though it is not really necessary, since it can also 
		* be done in file_import */
		%let idir=%file_name(&ifn, res=dir);
	%let ibase=%file_name(&ifn, res=base); /* we possibly have _base = ifn */

	/* ODIR/OFN: checking */
	%if %macro_isblank(odir) %then 					%let odir=&idir;
	%if %macro_isblank(ofn) %then 					%let ofn=&ibase._;

	/* GEO/CTRIES: check/set 
	* TIME: check/set 
	* DIRBY: set default/update parameter 
	* this is actually tested in UDB_DS_SPLIT */

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _l _c _b _y
		_tmpds _idsn _ofn _yy
		_vars _where _diff
		idsn _odir
		_years _year 
		_ctries _ctry;

	/* let us define an intermediary dataset _TMPDS whose name derives from the input IBASE 
	* filename */
	%let _tmpds=%sysfunc(compress(&ibase, ,kad));

	/* import the file IFN=&IDIR/&IBASE into the bulk dataset &_TMPDS */
	%file_import(&ibase, idir=&idir, odsn=&_tmpds, fmt=&fext, olib=WORK, guessingrows=_MAX_, getnames=YES);

	/* from the imported file &TMPDS, extract (in one shot) the subsets of data per year/country 
	* this will create several subsets, one for each country, each year	*/
	%udb_ds_split(&geo, &time, &_tmpds, ofn=&ofn, odir=&odir, dirby=&dirby, ilib=WORK);
	/* the list of countries/years actually extracted is returned in the variables _CTRIES and _YEARS */

	/* clean bulk temporary dataset &_TMPDS */
	%work_clean(&_tmpds);
	
	%exit:
%mend udb_file_split;


%macro _example_udb_file_split;
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
	
	%let _tmpdir=%quote(&G_PING_ROOTPATH/test/DUMMY);

	%ds_export(dbp, ofn=DUMB, odir=&_tmpdir);

	%udb_file_split(_ALL_, _ALL_, DUMB.csv, ofn=test_, dirby=FLAT, idir=&_tmpdir);
	/* other examples: 
	* %udb_file_split(_ALL_, _ALL_, DUMB.csv, ofn=test_, dirby=TIME, idir=&_tmpdir);
	* %udb_file_split(_ALL_, _ALL_, DUMB.csv, ofn=test_, dirby=GEO, idir=&_tmpdir);*/

%mend _example_udb_file_split;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_udb_file_split; 
*/

/** \endcond */

