/** 
## ds_export {#sas_ds_export}
Export (convert) a dataset to any format accepted by `PROC EXPORT`.

~~~sas
	%ds_export(ds, odir=, ofn=, _ofn_=, delim=, dbms=, fmt=csv, ilib=WORK);
~~~

### Arguments
* `ds` : a dataset (_e.g._, a SAS file);
* `fmt` : (_option_) format for export; it can be any format (_e.g._, `csv`) accepted by
	the `PROC EXPORT`; default: `fmt=csv`;
* `dbms` : (_option_) value of DBMS key when different from `fmt`; default: indeed, when 
	`dbms` is not passed, it is set to `dbms=&fmt`;
* `delim` : (_option_) delimiter; can be any argument accepted by the `DELIMITER` key in 
	`PROC EXPORT`; default: none is used
* `ilib` : (_option_) input library where the dataset is stored; by default, `WORK` is 
	selected as input library.
 
### Returns
* `ofn` : (_option_) basename of the output exported file; by default (when not passed),	
	it is set to `ds`;
* `odir` : (_option_) output directory/library to store the converted dataset; by default,
	it is set to:
			+ the location of your project if you are using SAS EG (see [%_egp_path](@ref sas__egp_path)),
			+ the path of `%sysget(SAS_EXECFILEPATH)` if you are running on a Windows 
			server,
			+ the location of the library passed through `ilib` (_i.e._, `%sysfunc(pathname(&ilib))`) 
			otherwise;
* `_ofn_` : name (string) of the macro variable storing the complete pathname of the output 
	file: it will look like a name built as: `&odir./&ofn..&fmt`.

### Example
Run macro `%%_example_ds_export` for examples.

### Notes
1. In short, this macro runs:

~~~sas
	PROC EXPORT DATA=&ilib..&idsn OUTFILE="&odir./&ofn..&fmt" REPLACE
	   DBMS=&dbms
	   DELIMITER=&delim;
   	quit;
	%let _ofn_=&odir./&ofn..&fmt;	
~~~
2. There is no format/existence checking, hence if the output selected type `fmt` is the 
same as the type of the input dataset, or if the output dataset already exists, a new dataset 
will be produced anyway. Please consider using the setting `G_PING_DEBUG=1` for checking 
beforehand actually exporting.
3. In debug mode (_e.g._, `G_PING_DEBUG=1`), the export operation is aborted; still it can 
be checked that the output file will be correctly created, _i.e._ with the correct name and 
location using the option `_ofn_`. Consider using this option for checking before actually 
exporting. 
4. In the case `fmt=dta` (Stata native format), the parameter `dbms` is set to `PCFS`. 
See example 3: _"Export a SAS dataset on UNIX to a Stata file on Microsoft Windows"_ of 
this 
[webpage](https://support.sas.com/documentation/cdl/en/acpcref/63184/HTML/default/viewer.htm#a003103776.htm);
also check this [webpage](http://stats.idre.ucla.edu/other/mult-pkg/faq/how-do-i-use-a-sas-data-file-in-stata/).

### See also
[%ds_check](@ref sas_ds_check), [%file_import](@ref sas_file_import),
[EXPORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/a000393174.htm).
*/ /** \cond */

/* credits: gjacopo, pierre-lamarche, marinapippi */

%macro ds_export(idsn		/* Input reference dataset 							(REQ) */
				, ofn=		/* Name of the output filename						(OPT) */
				, odir=		/* Full path of output directory 					(OPT) */
				, _ofn_=	/* Name of the variable storing the output filename (OPT) */
				, fmt=		/* Format of import 								(OPT) */
				, dbms=	 	/* DBMS key 										(OPT) */
				, ilib=		/* Input  library 									(OPT) */
				, delim=	/* Any argument of DELIMITER key in PROC EXPORT 	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/
	
	%local Ufmt
		DEBUG; /* boolean flag used for debug mode */
	%if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
	%else								%let DEBUG=0;

	%local __file; /* full path of the output file */
	%let __file=;

	/* FMT */
	%if %macro_isblank(fmt) %then 		%let fmt=csv;
	%let Ufmt=%upcase(&fmt);

	/* deal with Stata case */
	%if "&Ufmt"="DTA" %then 				%let dbms=STATA; /*PCFS;*/

	/* DBMS */
	%if %macro_isblank(dbms) %then 		%let dbms=&Ufmt;
	%else 								%let dbms=%upcase(&dbms);

	/* ILIB/IDSN: default setting and checking ILIB */
	%if %macro_isblank(ilib) %then 		%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* ODIR:  default setting and checking ODIR */
	%if %macro_isblank(odir) %then %do; 
		%if %symexist(_SASSERVERNAME) %then /* working with SAS EG */
			%let odir=&G_PING_ROOTPATH/%_egp_path(path=drive);
		%else %if &sysscp = WIN %then %do; 	/* working on Windows server */
			%let odir=%sysget(SAS_EXECFILEPATH);
			%if not %macro_isblank(odir) %then
				%let odir=%qsubstr(&odir, 1, %length(&odir)-%length(%sysget(SAS_EXECFILENAME));
		%end;
		%if %macro_isblank(odir) %then
			%let odir=%sysfunc(pathname(&ilib));
	%end;
	%if %error_handle(ErrorOutputParameter, 
			%dir_check(&odir) NE 0, mac=&_mac,		
			txt=%quote(!!! Output directory &odir does not exist !!!)) %then
		%goto exit;

	/* OFN: set default file basename */
	%if %macro_isblank(ofn) %then 		%let ofn=&idsn;
	%if %error_handle(ErrorInputParameter, 
			%index(%upcase(&ofn),/) NE 0, mac=&_mac,		
			txt=%quote(!!! Parameter OFN contains output basename only - Set ODIR for output pathname !!!)) %then
		%goto exit;

	/* ODIR/IDSN/FMT: set the full output file path */
	%if %index(%upcase(&ofn),.CSV) EQ 0 %then 	
		%let __file=&ofn..&fmt;
	%else 								
		%let __file=&ofn;
	%if "&odir" NE "_EMPTY_" %then 		%let __file=&odir./&__file;

	%if &DEBUG=1 %then 
		%goto quit;
	
	/* warning if it exists already... process anyway */
	%if %error_handle(WarningOutputFile, 
			%file_check(&__file) EQ 0, mac=&_mac,		
			txt=%quote(! Output file %upcase(&__file) already exist - Will be overwritten !), verb=warn) %then
		%goto warning;
	%warning:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	PROC EXPORT DATA=&ilib..&idsn OUTFILE="&__file" REPLACE
		DBMS=&dbms
		%if not %macro_isblank(delim) %then %do;
			 DELIMITER=&delim
		%end;
		;
	quit;

	%quit:

	%if not %macro_isblank(_ofn_) %then %do;
		%let &_ofn_=&__file;
		/*DATA _null_;
			call symput("&_ofn_","&__file");
		run;*/
	%end;

	%exit:
%mend ds_export;

%macro _example_ds_export;
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

	/* we currently launch this example in the highest level (1) of debug only */
	%if %symexist(G_PING_DEBUG) %then 	%let olddebug=&G_PING_DEBUG;
	%else %do;
		%global G_PING_DEBUG;
		%let olddebug=0;
	%end;
	%let G_PING_DEBUG=1;

	%local curdir ilib fmt oname;
	%let fname=;
	%if %symexist(_SASSERVERNAME) %then /* e.g.: you are running on SAS EG */
		%let curdir=&G_PING_ROOTPATH/%_egp_path(path=drive);
	%else
		%let odir=&G_PING_LIBDATA;

	%_dstest36;
	%*ds_print(_dstest36);

	%let ilib=WORK;
	%let fmt=csv;
	%let odir=%sysfunc(pathname(&ilib));
	%put;
	%put (i) Convert _dstest36 dataset into &fmt format and save it to WORK directory;
	%let resname=&odir/_dstest36.&fmt;
	%ds_export(_dstest36, ilib=&ilib, odir=&odir, _ofn_=fname, fmt=&fmt);
	%if "&fname"="&resname" %then 	%put OK: TEST PASSED - Expected &fname shall be created;
	%else 							%put ERROR: TEST FAILED - Wrong &fname would be created;

	%let ilib=&G_PING_LIBCFG;
	%_dstest36(lib=&ilib);

	%put;
	%put (ii) Convert test dataset into &fmt format and save it to default directory;
	%let resname=&curdir/_dstest36.&fmt;
	%ds_export(_dstest36, ilib=&ilib, _ofn_=fname, fmt=&fmt);
	%if "&fname"="&resname" %then 	%put OK: TEST PASSED - Expected file &fname shall be created;
	%else 							%put ERROR: TEST FAILED - Wrong file &fname would be created;
	
	%let odir=&G_PING_LIBCONFIG;
	%let fmt=xls;
	%put;
	%put (iii) Convert test dataset into &fmt format and save it to &odir directory;
	%let resname=&G_PING_LIBCONFIG/_dstest36.&fmt;
	%ds_export(_dstest36, ilib=&ilib, odir=&odir, _ofn_=fname, fmt=&fmt);
	%if "&fname"="&resname" %then 	%put OK: TEST PASSED - Expected file &fname shall be created;
	%else 							%put ERROR: TEST FAILED - Wrong file &fname would be created;

	/* reset the debug as it was (if it ever was set) */
	%let G_PING_DEBUG=&olddebug;
	%work_clean(_dstest36);

	%put;
	
	%exit:
%mend _example_ds_export;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_export; 
*/

/** \endcond */
