/** 
## dir_create {#sas_dir_create}
Create a directory, if needed.

~~~sas
	%dir_create(dir, recursive = FALSE);
~~~

### Arguments
* `recursive` : (_option_) boolean flag (`yes/no`) set to decide whether elements of the path other than the last one have to be created.

### Returns
* `dir` : a full path directory;

### Example
Just try on your "root" path:

~~~sas
	%dir_create(&G_PING_ROOTPATH);
~~~

Run macro `%%_example_dir_check` for more examples.

### Note

### See also
[%dir_check](@ref sas_dir_check), [%ds_check](@ref sas_ds_check), [%lib_check](@ref sas_lib_check), [%file_check](@ref sas_file_check),
[FEXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210817.htm),
[FILENAME](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210819.htm),
[DOPEN](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000209538.htm).
*/ /** \cond */

/* credits: pierre-lamarche */


%macro dir_create(dir	/* Name of directory to be created					 														(REQ) */
				, recursive=/* Boolean flag set to decide whether elements of the path other than the last one have to be created.	(OPT) */
				) ;
	%local _mac __ans;
	%let _mac=&sysmacroname;
	/* !!! NO %macro_put(&_mac); - This prevents the macro from returning a result */

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* warning on existence of the folder */

	%let __ans = %dir_check(&dir, mkdir = NO) ;
	%if &__ans EQ 0 %then %put WARNING: the folder &dir already exists ;
	
	/* recursive: check/set */
	%if %macro_isblank(recursive) %then 	%let recursive=NO;
	%else									%let recursive=%upcase(&recursive);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&recursive, type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong value for boolean flag RECURSIVE: must be YES or NO !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%if "&recursive"="YES" %then %do;
		%sysexec mkdir /* md */ -p &dir;
		/* note the use of the "-p" option... */
		/* %put %sysfunc(sysmsg()) The directory has been created. ;*/
	%end;
	%else %do ;
		%sysexec mkdir &dir;
	%end ;

	%let __ans = %dir_check(&dir, mkdir = NO) ;
	%if &__ans EQ 0 %then %goto exit;
	%if &__ans EQ -1 %then %put WARNING: Impossible to browse in the folder &dir.. ;
	%if &__ans EQ 1 %then %put ERROR: The creation of the folder &dir has failed. ;

	%exit:

%mend dir_check ;

%macro _example_dir_create;	
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
	
	%local res;

	%let dir=&G_PING_ROOTPATH;
	%put;
	%put (i) Test EU-SILC production path: &G_PING_ROOTPATH;
	%dir_create(&dir);


%mend _example_dir_check;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dir_create; 
*/

/** \endcond */
