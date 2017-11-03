/** 
## list_apply {#sas_list_apply}
Calculate the transform of a list given by a mapping table (similarly to a LookUp Transform, LUT).

~~~sas
	%list_apply(map, list, _applst_=, var=, casense=no, sep=%quote( ), lib=WORK);
~~~

### Arguments
* `list` : list of unformatted strings;
* `sep` : (_option_) character/string used as a separator in the input lists; default: `sep=%%quote( )`, 
	_i.e._ the input `list1` and `list2` are both blank-separated lists of items.
 
### Returns
`_applst_` : name of the variable storing the output list built as the list of items obtained through
	the transform defined by the variables `var` of the table `map`, namely: assuming all elements
	in `list` can be found in the (unique) observations of the origin variable, the element in the `i`-th 
	position of the output list is the `j`-th element of the destination variable when `j` is the position
	of the `i`-th element of `list` in the origin variable. 

### Example

~~~sas
	%let list=FR LU BG;
	%let maplst=
	%list_apply(_dstest32, &list, _applst_=maplst, var=1 2);
~~~
returns: `maplst=0.4 0.3 0.2`.	

Run macro `%%_example_list_apply` for more examples.

### Note
It is not checked that the values in the origin variable are unique. 

### See also
[%var_to_list](@ref sas_var_to_list), [%list_find](@ref sas_list_find), [%list_index](@ref sas_list_index),
[%ds_select](@ref sas_ds_select).
*/ /** \cond */

/* credits: grazzja */

%macro list_apply(list 			/* List of blank-separated items 								(REQ) */
        		, _applst_= 	/* Name of the macro variable storing the output list 			(REQ) */
        		, func= 		/*  	(OPT) */
				, macro=		/*  				(OPT) */
				, args= 		/* */
				, sep=			/* Character/string used as list separator 						(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/
	
	%local 	_varlst; /* temporary used list of variables for conversion */

	/* deal with simple cases */
	%if %macro_isblank(list) %then 
		%goto exit;

	/* SEP: default value */
	%if %macro_isblank(sep) %then 	%let sep=%quote( ); /* list separator */

	/* FUNC/MACRO: set/check */
	%if %error_handle(ErrorInputParameter, 
		%macro_isblank(func) EQ 0 and %macro_isblank(macro) EQ 0, mac=&_mac,
		txt=%quote(!!! Parameters FUNC and MACRO are incompatible !!!)) 
			or
			%error_handle(ErrorInputParameter, 
			%macro_isblank(func) EQ 1 and %macro_isblank(macro) EQ 1, mac=&_mac,
			txt=%quote(!!! One at least among parameters FUNC and MACRO must be set !!!)) %then 
		%goto exit;

	/* MACRO: check */
	%if not %macro_isblank(macro) %then %do;
		%local ans;
		%macro_exist(&macro, _ans_=ans);
		%if %error_handle(ErrorInputParameter, 
				&ans EQ 0, mac=&_mac,
				txt=%quote(!!! Macro %upcase(&macro) not recognised !!!)) %then 
			%goto exit;
	%end;

	/* _APPLST_: check/set */
	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(_applst_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _APPLST_ not set !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* start the actual LUT transform */ 
	%local i	/* loop increment */
		item	/* scanned item */
		olist;	/* final output list */
	%let olist=;

	%do i=1 %to %list_length(&list);	
		%let item=%scan(&list, &i, &sep);
		%if not %macro_isblank(macro) %then %do;
			%if %macro_isblank(args) %then %do;
				%let item=%&macro(&item);
			%end;
			%else %do;
				%let item=%&macro(&item, %unquote(&args));
			%end;
		%end;
		%else %if not %macro_isblank(func) %then %do;
			%if %macro_isblank(args) %then %do;
				%let item=%sysfunc(&func(&item));
			%end;
			%else %do;
				%let item=%sysfunc(&func(&item, %unquote(&args)));
			%end;
		%end;
		%let olist=&olist &item;
	%end;

	%if &sep^=%quote( ) %then %do;
		%let olist=%list_quote(&olistolist mark=_EMPTY_, rep=&sep);
	%end;

	/* set the output */
	data _null_;
		call symput("&_applst_","&olist");
	run;

	%exit:
%mend list_apply;

%macro _example_list_apply;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%local list rlist olist;

	%macro double(x); 
		%eval(2*&x) 
	%mend;

	%put;
	%let list=1 2 3 4;
	%let olist=2 4 6 8;
	%put (i) Use variables %upcase(vars) of _dstest32 in LUT transform of list=&list;
	%list_apply(&list, macro=double, _applst_=rlist);
	%if &olist EQ &rlist %then 	%put OK: TEST PASSED - Apply macro returns: &olist;
	%else 						%put ERROR: TEST FAILED - Wrong result returned: &rlist;

	%put;
%mend _example_list_apply;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_apply; 
*/

/** \endcond */

