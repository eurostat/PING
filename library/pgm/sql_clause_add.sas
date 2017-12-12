/** 
## sql_clause_add {#sas_sql_clause_add}
Generate a statement that can be interpreted by the `ADD` clause of a SQL procedure.

~~~sas
	%sql_clause_add(dsn, var, _add_=, typ=CHAR, lib=WORK);
~~~

### Arguments
* `dsn` : a dataset reference;
* `var` : list of fields/variables that will be added to `dsn` (if they don't already exist
	in the dataset)through 'ADD' clause;
* `typ` : (_option_) type(s) of the `var` fields/variables added to the dataset; it must be
	of length 1 or of the same lenght as `var`: in the former case, it will be replicated to
	the lenght of `var`; default: `type=CHAR`;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
`_add_` : name of the macro variable storing the SQL-like expression based on `var` and `typ` 
	input parameters and that can be used by in an `ADD` clause of a SQL-procedure (_e.g._, 
	`PROC ALTER`).

### Examples
The simple example below:

~~~sas
	%_dstest6;
	%let var=a b y z h;
	%let typ=char;
	%let expradd=;
	%sql_clause_add(_dstest6, &var, typ=&typ, _add_=expradd);
~~~
returns `expradd=y char, z char` since variables `y` and `z` are the only ones not already present 
in `_dstest6`.

### See also
[%ds_alter](@ref sas_ds_alter), [%sql_clause_modify](@ref sas_sql_clause_modify), [%sql_clause_as](@ref sas_sql_clause_as),
[%sql_clause_by](@ref sas_sql_clause_by), [%sql_clause_where](@ref sas_sql_clause_where).
*/ /** \cond */

/* credits: grazzja */

%macro sql_clause_add(dsn		/* Input dataset 											(REQ) */
					, var		/* List of variables to add to the input dataset 			(REQ) */
					, _add_=	/* Name of the macro variable storing the output expression	(REQ) */
					, typ=		/* Types of the variables to be added to the input dataset 	(OPT) */
					, lib=		/* Name of the input library 								(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* VAR, _ADD_: check/set */
	%if %error_handle(ErrorMissingInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=%quote(!!! Missing input parameter VAR !!!))
			or
			%error_handle(ErrorMissingOutputParameter, 
				%macro_isblank (_add_) EQ 1, mac=&_mac,		
				txt=!!! Missing output parameter _ADD_ !!!) %then
		%goto exit;

	%local SEP
		DEF_TYPE
		_varlen;
	%let SEP=%str( );

	/* check compatibility of ADD TYP LEN (lengths of the list equal? equal to 1? 
	see %ds_create for that */
	%if %symexist(G_PING_VAR_TYPE) %then 		%let DEF_TYPE=&G_PING_VAR_TYPE;
	%else										%let DEF_TYPE=char;

	/* define the lenght of the variables passed */
	%let _varlen=%list_length(&var, sep=&SEP);

	/* TYP: check/set */
	%if %macro_isblank(typ) %then %let typ=&DEF_TYPE;

	%if %list_length(&typ, sep=&SEP)=1 and &_varlen>1 %then  		
		%let typ=%list_ones(&_varlen, item=&typ);
	%if %error_handle(ErrorInputParameter, 
			%list_length(&typ, sep=&SEP) NE &_varlen, mac=&_mac,		
			txt=!!! Incompatible TYP and VAR parameters: lengths must be equal !!!) %then
		%goto exit;

	/* DSN/LIB: check/set */
	%if %macro_isblank(lib) %then 	%let lib=WORK;		

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i
		SEP REP
		_var
		_typ
		_newvar
		_newtyp; 
	%let SEP=%str( );
	%let REP=%str(,);
	%let _newvar=; 
	%let _newtyp=; 

	/* trim: get rid of those variables which are not in the input dataset */
	%do _i=1 %to %list_length(&var, sep=&SEP);
		%let _var=%scan(&var, &_i, &SEP);
		%let _typ=%scan(&typ, &_i, &SEP);
		%if %error_handle(WarningInputParameter, 
				%var_check(&dsn, &_var, lib=&lib) EQ 0, mac=&_mac,		
				txt=%quote(! Variable %upcase(&_var) already exists in dataset %upcase(&dsn) !),  
				verb=warn) %then 
			%goto next;
		%else %do;
			%let _newvar=&_newvar.&SEP.&_var;
			%let _newtyp=&_newtyp.&SEP.&_typ;
		%end;
		%next:
	%end;

	/* shape */
	%let _newvar =%list_append(&_newvar, &_newtyp, zip=yes, rep=&REP.&SEP);
	data _null_;
		call symput("&_add_","&_newvar");
	run;

	%exit:
%mend sql_clause_add;

%macro _example_sql_clause_add;
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

	%local var oexpradd expradd;

	%_dstest6; /* where variables a, b and h already exist */
	
	%let var=a b y z h;
	%let typ=char;
	%put;
	%put (i) Simple test over test dataset #6, adding var=&var of type &typ;
	%let expradd=;
	%sql_clause_add(_dstest6, &var, _add_=expradd);
	%let oexpradd=y char, z char;
	%if %quote(&expradd) EQ %quote(&oexpradd) %then 	%put OK: TEST PASSED - returns: %bquote(&oexpradd);
	%else 												%put ERROR: TEST FAILED - wrong list returned: %bquote(&expradd);

	%work_clean(_dstest6);

	%put;

	%exit:
%mend _example_sql_clause_add;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_sql_clause_add; 
*/

/** \endcond */
