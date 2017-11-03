/** 
## dir_check {#sas_dir_check}
Check the existence of a directory.

~~~sas
	%let ans=%dir_check(dir, mkdir=NO);
~~~

### Arguments
* `dir` : a full path directory;
* `mdkir` : (_option_) boolean flag (`yes/no`) set to force the creation of 
	the directory when it does not already exist.

### Returns
`ans` : error code for the test of prior existence  of the input directory
	(hence, independent of the `mkdir` option), _i.e._:
		+ `0` when the directory exists (and can be opened), or
    	+ `1` (error) when the directory does not exist, or
    	+ `-1` (error) when the fileref exists but cannot be opened as a directory.

### Example
Just try on your "root" path, so that:

~~~sas
	%let ans=&dir_check(&G_PING_ROOTPATH);
~~~
will return `ans=0`.

Run macro `%%_example_dir_check` for more examples.

### Note
The response `and` returned by the macro relates to the prior existence of
the directory. Therefore, even when a directory is created thanks to the option
`mkdir=YES`, the answer may be `ans=0`. 

### See also
[%ds_check](@ref sas_ds_check), [%lib_check](@ref sas_lib_check), [%file_check](@ref sas_file_check),
[FEXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210817.htm),
[FILENAME](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210819.htm),
[DOPEN](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000209538.htm).
*/ /** \cond */

/* credits: grazzja */

%macro dir_check(dir	/* Name of input directory whose existence is checked 		(REQ) */
				, mkdir=/* Boolean flag set to force the creation of the directory 	(OPT) */
				, verb= /* Legacy parameter - Ignored 								(OBS) */
				) ;
	%local _mac;
	%let _mac=&sysmacroname;
	/* !!! NO %macro_put(&_mac); - This prevents the macro from returning a result */

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/
	
	/* MKDIR: check/set */
	%if %macro_isblank(mkdir) %then 		%let mkdir=NO;
	%else									%let mkdir=%upcase(&mkdir);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&mkdir, type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong value for boolean flag MKDIR: must be YES or NO !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local __ans /* output answer */
		_rc 	/* file identifier */
		_fref 	/* file reference */
		_did;	/* opener reference */

    %let _fref=_TMPFILE;
	/* assign the file ref */
	%let _rc = %sysfunc(filename(_fref, &dir)) ;

	%if not %sysfunc(fexist(&_fref)) %then %do;
		%let __ans=1; 
		/* %if &verb=yes %then %put Directory %upcase(&dir) does not exist; */
		%if "&mkdir"="YES" %then %do;
			%sysexec mkdir /* md */ -p &dir;
			/* note the use of the "-p" option... */
			/* %put %sysfunc(sysmsg()) The directory has been created. ;*/
		%end;
		%goto exit;
	%end;

	%let _did=%sysfunc(dopen(&_fref));
	/* directory opened successfully */
   	%if &_did ne 0 %then %do;
      	%let __ans=0;
 		/* %if &verb=yes %then %put Directory %upcase(&dir) opens; */
     	%let _rc=%sysfunc(dclose(&_did));
   	%end;
	%else %do;
     	%let __ans=-1;
  		/* %if &verb=yes %then %put Directory %upcase(&dir) does not open; */
  	%end;

	/* deassign the file ref */
   	%let _rc=%sysfunc(filename(_fref));

	%exit:
	&__ans

%mend dir_check ;

%macro _example_dir_check;	
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%local res;

	%let dir=&G_PING_ROOTPATH;
	%put;
	%put (i) Test EU-SILC production path: &G_PING_ROOTPATH;
	%let res=%dir_check(&dir);
	%if &res = 0 %then 		%put OK: TEST PASSED - Existing dataset: errcode 0;
	%else					%put ERROR: TEST FAILED - Existing dataset: errcode &res;

	%let dir=&G_PING_ROOTPATH/Certainly_does_not_exist_directory/;
	%put;
	%put (ii) What about this path: %upcase(&dir);
	%let res=%dir_check(&dir);
	%if &res = 1 %then 		%put OK: TEST PASSED - Dummy dataset: errcode 1;
	%else 					%put ERROR: TEST FAILED - Dummy dataset: errcode &res;

	%put;
%mend _example_dir_check;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dir_check; 
*/

/** \endcond */
