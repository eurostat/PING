/** 
## file_import {#sas_file_import}
Import (convert) a file from any format accepted by `PROC IMPORT` into a SAS dataset.

~~~sas
	%file_import(ifn, odsn=, idir=, fmt=csv, _ods_=, olib=, guessingrows=, getnames=yes);
~~~

### Arguments
* `ifn` : file name to import;
* `fmt` : (_option_) format for import, _i.e._ extension of the input file; it can be any format 
	(_e.g._, csv) accepted by the DBMS key in `PROC import`;
* `idir` : (_option_) input directory where the file is stored; note that it may be also passed
	directly in `ifn`; default: empty, the location depends on `ifn`;
* `olib` : (_option_) output  library where the dataset will be stored; by default, `olib=WORK` 
    is selected as output library;
* `guessingrows` : flag set to the number of rows (observations) to be read so as to guess the type 
	of a column (variable); `guessingrows` must be an integer >0, or `_MAX_` when all the rows need
	to be read so as to define the type of the variable that is imported (in practice, `_MAX_` 
	corresponds to the integer value 2147483647); default: `guessingrows` is not set and the first 
	row is used to guess the type of the variable;
* `getnames` : boolean flag (`yes/no`) set to import the variable names; default: `getnames=yes`.
 
### Returns
* `odsn` : (_option_) name of the output dataset; otherwise, `odsn` is automatically built from 
	the basename of the input file name `ifn`;
* `_ods_` : (_option_) name (string) of the macro variable storing the name of the output dataset;
	useful when `odsn` has not been set.
 
### Example
Run macro `%%_example_file_import` for examples.

### Notes
1. There is no format/existence checking, hence if the output selected type is the same as 
the type of the input dataset, or if the output dataset already exists, a new dataset will be 
produced anyway. If the `REPLACE` option is not specified, the `PROC IMPORT` procedure does 
not overwrite an existing data set.
2. In debug mode (_e.g._, `G_PING_DEBUG=1`), the import process is aborted; still it can checked
that the output dataset will be created with the correct name and location using the option 
`_ods_`. Consider using this option for checking before actually importing. 
3. When trying to guess the types of the input variables, there is a *SAS issue with 
the type of the last column/variable*, _e.g._ setting `guessingrows=MAX`. For instance, 
let us consider the following CSV table: 
    var1,var2,var3,var4,var5,var6
    ,,,,,
    1,,X,,1,1
    X,1,,,,
    X,1,,,,
    ,,,,,
    ,,1,1,,

the variables `var5` and `var6` (while equal) are imported as numerical and alphanumerical 
respectively, though they should bot be imported as numerical.
*This issue occurs when the file has been created on a Windows PC and SAS is running on 
Unix/Linux*. 
One difference between both operating systems is the newline char. While Windows uses 
Carriage Return and Line Feed, the *nix-systems use only one of the chars. The problem 
can be solved in different manners:
	* by using, instead of the `PROC IMPORT`, `INFILE` statement together with the `TERMSTR`
	option, which shall take the value: 
		+ `TERMSTR=CRLF` (Carriage Return Line Feed) to read Windows formatted files (default
			on Windows platforms),
		+ `TERMSTR=LF` (Line Feed) to read UNIX formatted files (default on UNIX systems),     
		+ `TERMSTR=CR` (Carriage Return) to read MAC formatted files;

	* by using dos2unix in the shell of the unix-box to transform the newline chars,

Instead, we will use the macro `%%handle_crlf` implemented by V.Nguyen which reads like:

~~~sas
	%macro handle_crlf(file, handle_name, other_filename_options=) ;
		%sysexec head -n 1 "&file" | awk '/\r$/ { exit(1) }' ;
		%if &SYSRC=1 %then %let termstr=crlf ;
		%else %let termstr=lf ;
		filename &handle_name "&file" termstr=&termstr &other_filename_options ;
	%mend ;
~~~
which automatically detect line break options with termstr as `CRLF` or `LF` (also default)
when importing data. This assumes SAS is running on a UNIX server with access to the `head` 
and `awk` commands. 
Original source code (no license, no disclaimer) is available at 
<http://blog.nguyenvq.com/blog/2015/10/09/automatically-specify-line-break-options-with-termstr-as-crlf-or-lf-in-sas-when-importing-data/>.

4. Variable names should be alphanumeric strings, not numeric values (otherwise converted).

### See also
[%ds_export](@ref sas_ds_export), [%file_check](@ref sas_file_check),
[%handle_crlf](http://blog.nguyenvq.com/blog/2015/10/09/automatically-specify-line-break-options-with-termstr-as-crlf-or-lf-in-sas-when-importing-data/),
[IMPORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000308090.htm).
*/ /** \cond */

/* credits: gjacopo */
	
%macro file_import(ifn			/* Input filename 															(REQ) */
				, idir=			/* Full path of input directory 											(OPT) */
				, fmt=			/* Format of import 														(OPT) */
				, odsn=			/* Name of the output dataset 												(OPT) */
				, _ods_=		/* Name of the macro variable storing the built name of the output dataset	(OPT) */
				, olib=			/* Output  library 															(OPT) */
				, guessingrows=	/* Flag defining the number of rows used to guess the format of a variable	(OPT) */
				, getnames=		/* Boolean flag set to get names 											(OPT) */
				);
 	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local DEBUG /* boolean flag used for debug mode */
		MAXROWS
		FMTS;
	%if %symexist(G_PING_DEBUG) %then 		%let DEBUG=&G_PING_DEBUG;
	%else									%let DEBUG=0;
	%let FMTS = CSV TAB DLM EXCEL DBF ACCESS;
	%let MAXROWS = 2147483647;
	
	/* OLIB */
	%if %macro_isblank(olib) %then 			%let olib=WORK;

	/* FMT: set default/update parameter */
	%if %macro_isblank(fmt)  %then 			%let fmt=CSV; 
	%else									%let fmt=%upcase(&fmt);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&fmt, type=CHAR, set=&FMTS) NE 0, mac=&_mac,	
			txt=!!! Parameter FMT is an identifier in &FMTS !!!) %then
		%goto exit; 

	/* GETNAMES: set default/update parameter */
	%if %macro_isblank(getnames)  %then 	%let getnames=YES; 
	%else									%let getnames=%upcase(&getnames);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&getnames, type=CHAR, set=YES NO) NE 0, mac=&_mac,	
			txt=!!! Parameter GETNAMES is boolean flag with values in (yes/no) !!!) %then
		%goto exit; 

	/* GUESSINGROWS: set default/update parameter */
	%if %upcase("&guessingrows") = "_MAX_"  %then 	%let guessingrows=&MAXROWS; 
	%else %if not %macro_isblank(guessingrows) %then %do;
		%if %error_handle(ErrorInputParameter, 
				%par_check(&guessingrows, type=INTEGER, range=0 &MAXROWS, set=&MAXROWS) NE 0, mac=&_mac,	
				txt=!!! Parameter GUESSINGROWS is integer with values in range ]0, &MAXROWS] !!!) %then
			%goto exit; 
	%end;

	%local _file 	/* full path of the input file */
		_dir 		/* name of the input file directory */
		_base 		/* basename of the input file */
		_ext		/* extension of the input file */
		_fn			/* filename of the input file without its directory path if any */
		isbl_idir 	/* test of existence of input directory parameter */
		isbl_dir; 	/* test of existence of directory in input filename */
	%let _file=&ifn;

	%let _base=%file_name(&ifn, res=base); /* we possibly have _base = _file */
	%let _dir=%file_name(&ifn, res=dir);
	%let _ext=%file_name(&ifn, res=ext);
	%let _fn=%file_name(&ifn, res=file);

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

	%if not %macro_isblank(fmt) %then %do;
		%let fmt=%lowcase(&fmt);
		%if %error_handle(ErrorInputParameter, 
			not %macro_isblank(_ext) and %quote(&_ext) NE %quote(&fmt), mac=&_mac,	
			txt=!!! Incompatible parameter FMT with extension %upcase(&_ext) !!!) %then
		%goto exit;
		/* else: do nothing, change nothing */
	%end;

	/* reset the full input file path */
	%if not %macro_isblank(fmt) and %macro_isblank(_ext) %then 	%let _file=&idir./&_base..&fmt;
	%else 														%let _file=&idir./&_fn;

	%if %error_handle(ErrorInputFile, 
			%file_check(%quote(&_file)) EQ 1, mac=&_mac,	
			txt=%quote(!!! File %upcase(&_file) does not exist !!!)) %then
		%goto exit;

	%if %macro_isblank(odsn) %then 			%let odsn=%sysfunc(compress(&_base));

	%if &G_PING_DEBUG=1 %then 
		%goto quit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* check the type of the input file, possibly using CRLF */
	%local fh;
	%macro handle_crlf(file, handle_name, other_filename_options=);
		%local termstr;
		%if &sysscp = WIN %then 
			%let termstr=LF; /* we assume everything is Windows */
		%else %do;
			/* if there is a carriage return at the end, then return 1 (stored in SYSRC) */
			%sysexec head -n 1 "&file" | awk '/\r$/ { exit(1) }' ;
			%if &SYSRC=1 %then 		%let termstr=CRLF;
			%else 					%let termstr=LF;
		%end;
		FILENAME &handle_name "&file" termstr=&termstr &other_filename_options;
	%mend ;
	%handle_crlf(file=%quote(&_file), handle_name=fh) ;

	/* do the actual import */
	PROC IMPORT DATAFILE=fh OUT=&olib..&odsn REPLACE 
		DBMS=&fmt;
		GETNAMES=&getnames;
		%if not %macro_isblank(guessingrows) %then %do;
			GUESSINGROWS = &guessingrows; /* see http://support.sas.com/kb/46/530.html */
		%end;
		/* MIXED = yes; /* works only on Windows system (http://support.sas.com/kb/32/619.html) */
	quit;

	%quit:
	%if not %macro_isblank(_ods_) %then %do;
		%let &_ods_=&olib..&odsn;
		/* data _null_;
			* call symput("&_ods_","&olib..&odsn"); ;
			call symput("&_ods_", "&odsn");
		run; */
	%end;

	%exit:
%mend file_import;


%macro _example_file_import;
	%if %symexist(G_PING_SETUPPATH) EQ 0 %then %do; 
        %if %symexist(G_PING_ROOTPATH) EQ 0 %then %do;	
			%put WARNING: !!! PING environment not set - Impossible to run &sysmacroname !!!;
			%put WARNING: !!! Set global variable G_PING_ROOTPATH to your PING install path !!!;
			%goto exit;
		%end;
		%else %do;
        	%let G_PING_SETUPPATH=&G_PING_ROOTPATH./PING; 
        	%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
        	%_default_setup_;
		%end;
    %end;

	%local idir ifn type
		odsn ds;

	/* we currently launch this example in the highest level (1) of debug only */
	%if %symexist(G_PING_DEBUG) %then 	%let olddebug=&G_PING_DEBUG;
	%else %do;
		%global G_PING_DEBUG;
		%let olddebug=0;
	%end;
	%let G_PING_DEBUG=1;

	%let ds=;
	
	%let idir=&G_PING_ESTIMATION/meta; 
	%let ifn=META_INDICATOR_CONTENTS;
	%let type=csv;
	%put;
	%put (i) Convert csv file (&ifn) from &idir folder into WORK library;
	%file_import(&ifn, idir=&idir, fmt=&type, _ods_=ds, getnames=yes);
	%if "&ds"="WORK.&ifn" %then 		%put OK: TEST PASSED - Expected &ds shall be created;
	%else 										%put ERROR: TEST FAILED - Wrong &ds would be created;

	%put;
	%let LIBCFG=&G_PING_LIBCFG;
	%put (ii) Convert csv file (&ifn) from &idir folder into &LIBCFG library;
	%file_import(&ifn, idir=&idir, fmt=&type, _ods_=ds, getnames=yes, olib=LIBCFG);
	%if "&ds"="LIBCFG.&ifn" %then %put OK: TEST PASSED - Expected &ds shall be created;
	%else 										%put ERROR: TEST FAILED - Wrong &ds would be created;

	%let ifn=META_VARIABLExINDICATOR;
	%put;
	%put (iii) Load and import a csv file (&ifn) into WORK library;
	%file_import(&ifn, idir=&idir, fmt=&type, _ods_=ds, getnames=yes);
	%if "&ds"="WORK.&ifn" %then %put OK: TEST PASSED - Expected &ds shall be created;
	%else 										%put ERROR: TEST FAILED - Wrong &ds would be created;

	%let odsn=TEST;
	%put;
	%put (iv) Ibid, providing an output name;
	%file_import(&ifn, idir=&idir, fmt=&type, odsn=&odsn, _ods_=ds, getnames=yes);
	%if "&ds"="WORK.&odsn" %then %put OK: TEST PASSED - Expected &ds shall be created;
	%else 										%put ERROR: TEST FAILED - Wrong &ds would be created;

	/* reset the debug as it was (if it ever was set) */
	%let G_PING_DEBUG=&olddebug;

	%put;

	%exit:
%mend _example_file_import;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_file_import; 
*/


/** \endcond */
