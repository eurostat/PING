/** 
## file_move {#sas_file_move}
Rename/move a file (or a directory) to another location.

~~~sas
	%file_move(ifn, ofn=, idir=, odir=);
~~~

### Arguments
* `ifn` : name or full path of an input file;
* `idir` : (_option_) input directory where the input file is located; if not passed, the 
	location is derived from `ifn`.

### Returns
* `ofn` : (_option_) new location/name of the file; if empty, the renaming of the file
	uses the timestamp;
* `odir` : (_option_) output directory where the file will be moved; if empty, `odir` is
	set to `idir`.

### Examples

Run macro `%%_example_file_move` for examples.

### See also
[%file_check](@ref sas_file_check), [%file_name](@ref sas_file_name).
*/ /** \cond */

/* credits: grazzja */

%macro file_move(ifn
				, ofn=
				, idir=
				, odir=
				);
 	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _ifile 	/* full path of the input file */
		_dir 		/* name of file directory */
		_ibase 		/* basename of the input file */
		_iext		/* extension of the input file */
		_ifn			/* filename of the input file without its directory path if any */
		isbl_idir 	/* test of existence of input directory parameter */
		isbl_dir 	/* test of existence of directory in input filename */
		PREF TODAY;
	%let PREF=/*_old*/;
	%let TODAY=%sysfunc(today(),yymmddd8.);

	/* IDIR/IFN: check */

	%let _ifile=&ifn;
	%let _ibase=%file_name(&ifn, res=base); /* we possibly have _ibase = _ifn */
	%let _iext=%file_name(&ifn, res=ext);
	%let _ifn=%file_name(&ifn, res=file);
	%let _dir=%file_name(&ifn, res=dir);

	%let isbl_idir=%macro_isblank(idir);
	%let isbl_dir=%macro_isblank(_dir);

	%if &isbl_idir=0 and &isbl_dir=0 %then %do;
		%if %error_handle(ErrorInputParameter, 
			%quote(&_dir) NE %quote(&idir), mac=&_mac,	
			txt=!!! Incompatible parameters IDIR and IFN - Check paths !!!) %then
		%goto exit;
		/* else: do nothing, change nothing - _file as is */
	%end;
	%else %if &isbl_idir=1 and &isbl_dir=1 %then %do;
		/* look in current directory */
		%if %symexist(_SASSERVERNAME) %then /* working with SAS EG */
			%let idir=&G_PING_ROOTPATH/%_egp_path(path=drive);
		%else %if &sysscp = WIN %then %do; 	/* working on Windows server */
			%let idir=%sysget(SAS_EXECFILEPATH);
			%if not %macro_isblank(idir) %then
				%let idir=%qsubstr(&idir, 1, %length(&idir)-%length(%sysget(SAS_EXECFILENAME));
		%end;
	%end;
	%else %if &isbl_idir=1 /* and &isbl_dir=0 */ %then %do;
		%let idir=&_dir;
	%end;
	%else %if &isbl_idir=0 /* and &isbl_dir=1 */ %then %do;
		/* do nothing */ ;
	%end;
		
	%if %error_handle(ErrorInputParameter, 
			%dir_check(&idir) NE 0, mac=&_mac,		
			txt=%quote(!!! Input directory %upcase(&idir) does not exist !!!)) %then
		%goto exit;

	/* IFN : reset the full input file path */
	%let _file=&idir./&_ifn;

	%if %error_handle(ErrorInputFile, 
			%file_check(&_file) EQ 1, mac=&_mac,	
			txt=%quote(!!! File %upcase(&_file) does not exist !!!)) %then
		%goto exit;

	/* OFN : reset the full output file path */

	%let _dir=%file_name(&ofn, res=dir);

	%let isbl_odir=%macro_isblank(odir);
	%let isbl_dir=%macro_isblank(_dir);

	%if &isbl_odir EQ 0 and &isbl_dir EQ 0 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%quote(&_dir) NE %quote(&idir), mac=&_mac,	
				txt=!!! Incompatible parameters ODIR and OFN - Check paths !!!) %then
			%goto exit;
	%end;
	%else %if &isbl_odir EQ 1 and &isbl_dir EQ 1 %then %do;
		%let odir=&idir;
	%end;
	%else %if &isbl_odir EQ 1 /* and &isbl_dir EQ 0 */ %then %do;
		%let odir=&_dir;
	%end;

	/* OFN : reset the full input file path */
	%if %macro_isblank(ofn) %then %do;
		%let ofn=&PREF._&_ibase._&TODAY.;
		%if not %macro_isblank(_ext) %then %let ofn=&ofn..&_iext;
	%end;
	%if &isbl_dir EQ 1 %then %do;
		%let ofn=&odir./&ofn.;		
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local instr1
		instr2;
			
	/* define the mkdir instruction if needed */
	%if %error_handle(WarningOutputFile, 
			%dir_check(&odir) NE 0, mac=&_mac,	
			txt=%quote(! Directory %upcase(&odir) does not exist - Will be created !),
			verb=warn) %then 
			/* create the output directory in case it does not exist 
		    %let _fref=_TMP;
			%let _rc = %sysfunc(filename(_fref, &ndir)) ;
			%if not %sysfunc(fexist(&_fref)) %then %do;
				%sysexec %str(mkdir &ndir);
			%end;
		   	%let _rc=%sysfunc(filename(_fref));  */
		%let instr1=%str(mkdir &odir);
	%else 
		%let instr1=echo; /* dummy */

	/* define the move instruction */
	%let instr2=%str(mv &ifn &ofn);

	%if &G_PING_DEBUG=1 %then 
		%goto debug;

	/* run... */
	%sysexec %str(&instr1; &instr2);
	%goto exit;

	%debug:
	%put %str(&instr1; &instr2);
	
	%exit:
%mend file_move;


%macro _example_file_move;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ifn ofn idir odir;

	/* we currently launch this example in the highest level (1) of debug only */
	%if %symexist(G_PING_DEBUG) %then 	%let olddebug=&G_PING_DEBUG;
	%else %do;
		%global G_PING_DEBUG;
		%let olddebug=0;
	%end;
	%let G_PING_DEBUG=1;

	%if %symexist(_CLIENTPROJECTNAME) %then %do;
		%let file=%scan(&_SASPROGRAMFILE,1,%str(%'));
	%end;
	%else %do;
		/* %let file=%sysget(SAS_EXECFILENAME); /* %sysfunc(getoption(sysin)); */
		%let file=file_move.sas;
	%end;
	%put file=&file;

	%put;
	%put (i) ;
	%file_move(&file, ofn=muf.txt);
	%put;
	%put (ii) ;
	%file_move(&file, odir=/a/b);

	%put;
	%put (iii) ;
	%file_move(%file_name(&file,res=file), ofn=/a/b/muf.txt, idir=%file_name(&file,res=dir));
	
	/* reset the debug as it was (if it ever was set) */
	%let G_PING_DEBUG=&olddebug;

	%put;

%mend _example_file_move;


/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_file_move; 
*/

/** \endcond */
