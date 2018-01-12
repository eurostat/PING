/**  
## silc_ref2lib {#sas_silc_ref2lib}
Retrieve the actual (physical) library associated to a EU-SILC reference. 

~~~sas
	%let lib=%silc_ref2lib(ref);
~~~

### Argument
`ref` : input library reference, _e.g._ any string in `RDB`, `RDB2`, `EDB`, `LDB`.

### Returns
`lib` : library associated to the reference `ref`.

### Example
Running for instance:

~~~sas
	%let lib=%silc_ref2lib(RDB);
~~~
will set: `lib=LIBCRDB`.

See `%%_example_silc_ref2library` for more examples.
	
### See also
[%silc_db_locate](@ref sas_silc_db_locate), [%silc_ind_ref](@ref sas_silc_ind_ref).
*/

/* credits: gjacopo */

%macro silc_ref2lib(ref	/* Name of the library reference		(REQ) */
						);
	%local _mac;
	%let _mac=&sysmacroname;

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local __lib
		REFTYPES;
	%let __lib=;

	/* REFERENCE: check  */
	%if %symexist(G_PING_REFTYPES) %then 		%let REFTYPES=&G_PING_REFTYPES;
	%else										%let REFTYPES=RDB RDB2 EDB LDB;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(ref) EQ 1, mac=&_mac,
			txt=!!! Reference not provided !!!) %then
		%goto exit;
	%else %if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&ref), type=CHAR, set=&REFTYPES) NE 0, mac=&_mac,
			txt=!!! Reference &ref not recognised !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%if "%upcase(&ref)"="RDB" %then %do;
		%let __lib=&G_PING_LIBCRDB;
	%end;
	%else %if "%upcase(&ref)"="RDB2" %then %do;
		%let __lib=&G_PING_LIBCRDB2;
	%end;
	%else %if "%upcase(&ref)"="EDB" %then %do;
		%let __lib=&G_PING_LIBCERDB;
	%end;
	%else %if "%upcase(&ref)"="LDB" %then %do;
		%let __lib=&G_PING_LIBCLRDB;
	%end;

	%exit:
	&__lib
%mend silc_ref2lib;

%macro _example_silc_ref2lib;
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

	%local olib;

	%put;
	%put (i) Retrieve the library associated to reference RDB;
	%let lib=%silc_ref2lib(RDB);
	%if "&lib"="LIBCRDB" and "%sysfunc(pathname(&lib))"="&G_PING_C_RDB" %then 			
		%put OK: TEST PASSED - Reference library is: lib=LIBCRDB - pathname(lib)=&G_PING_C_RDB;
	%else 						
		%put ERROR: TEST FAILED - Wrong reference library: lib=&lib - pathname(lib)=%sysfunc(pathname(&lib));

	%put;
	%put (ii) Retrieve the library associated to reference RDB2;
	%let lib=%silc_ref2lib(RDB2);
	%if "&lib"="LIBCRDB2" and "%sysfunc(pathname(&lib))"="&G_PING_C_RDB2" %then 			
		%put OK: TEST PASSED - Reference library is: lib=LIBCRDB2 - pathname(lib)=&G_PING_C_RDB2;
	%else 						
		%put ERROR: TEST FAILED - Wrong reference library: lib=&lib - pathname(lib)=%sysfunc(pathname(&lib));

	%exit:
%mend _example_silc_ref2lib;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_ref2lib;
*/

/** \endcond */

