/** 
## ds_change {#sas_ds_change}
Rename one or more datasets in the same SAS library.

~~~sas
	%ds_change(olddsn, newdsn, lib=WORK);
~~~

### Arguments
* `olddsn` : (list of) old name(s) of reference dataset(s);
* `newdsn` : (list of) new name(s); must be of the same length as `olddsn`;
* `lib` : (_option_) name of the library where the dataset(s) is (are) stored; default: `lib=WORK`.
	
### Note
In short, this macro runs:
~~~sas
	PROC DATASETS lib=&lib;
		%do i=1 %to %list_length(&olddsn);
			CHANGE %scan(&olddsn,&i)=%scan(&newdsn,&i);
		%end;
	quit;
~~~

### See also
[%ds_rename](@ref sas_ds_rename), 
[CHANGE](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000247645.htm).
*/ /** \cond */

/* credits: gjacopo, marinapippi */

%macro ds_change(olddsn		/* (List of) old name(s) of datasets 					(REQ) */
				, newdsn	/* (List of) new name(s) of datasets 					(REQ) */
				, lib=		/* Name of the library where the datasets are stored 	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local i 	/* local increment counter */
		num; 	/* length of input lists */

	/* LIB */
	%if %macro_isblank(lib)	%then 	%let lib=WORK;

	/* NEWDSN/OLDDSN: check length compatibility */
	%let num=%list_length(&olddsn);
	%if %error_handle(ErrorInputParameter, 
			&num NE %list_length(&newdsn), mac=&_mac,		
			txt=!!! Input parameters OLDDSN and NEWDSN must be of same length !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                  actual operation                              **/
	/************************************************************************************/

	PROC DATASETS lib=&lib nolist;
		%do i=1 %to %list_length(&olddsn);
			%let _odsn=%scan(&olddsn,&i);
			%let _ndsn=%scan(&newdsn,&i);
			%if %error_handle(WarningInputParameter, 
					%ds_check(&_ndsn, lib=&lib) EQ 0, mac=&_mac,		
					txt=%bquote(!!! Dataset %upcase(&_ndsn) already exists in &lib - Skip renaming of %upcase(&_odsn) !!!),
					verb=warn) %then
				%goto next;
			CHANGE &_odsn=&_ndsn;
			%next:
		%end;
	quit;

	%exit:
%mend ds_change;

%macro _example_ds_change;
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

	%put;
	%put (i) Create test dataset #1 and rename it;
	%_dstest1;
	%ds_rename(_dstest1, _dummy1);
	%if %ds_check(_dummy1) EQ 0 and %ds_check(_dstest1) EQ 1 %then 	
		%put OK: TEST PASSED - Dataset renamed: _dummy1;
	%else 									
		%put ERROR: TEST FAILED - Dataset not renamed;

	%put;
	%put (ii) Create three datasets: test datasets #1, #2 and #3, and try to rename them;
	%_dstest1;
	%_dstest2;
	%_dstest5;
	%ds_change(_dstest1 _dstest2 _dstest5, _dummy1 _dummy2 _dummy5);
	%if %ds_check(_dstest1) EQ 0 and %ds_check(_dummy1) EQ 0 and %ds_check(_dummy2) EQ 0 and %ds_check(_dummy5) EQ 0 %then 	
		%put OK: TEST PASSED - Datasets dstest2 and _dstest5 renamed: _dummy2 and _dummy5, _dstest1 unchanged;
	%else 									
		%put ERROR: TEST FAILED - Datasets not properly renamed;

	%put;

	%work_clean(_dummy1, _dummy2, _dummy5, _dstest1);

	%exit:
%mend _example_ds_change;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_change; 
*/

/** \endcond */
