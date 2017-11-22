/** 
## sql_clause_case {#sas_sql_clause_case}
Generate a quoted text that can be interpreted by the `CASE` clause of a SQL procedure.

~~~sas
	%sql_clause_case(dsn, var, _case_=, when=, then=, lib=);
~~~

### Arguments
* `dsn` : a dataset reference;
* `var` : list of fields/variables that will be added to `dsn` through 'ADD' clause;
* `when` : list of expressions to use as conditions (`WHEN`) in `CASE` statement; it 
	should be of same length, or length+1/-1, as `then`; 
* `then` : (_option_) list of expressions to use as executions (`THEN` values) in `CASE` 
	statement; it should be of same length, or length+1/-1, as `then`; when of length -1, 
	then an empty value is used;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.

### Returns
`_case_` : name of the macro variable storing the SQL-like expression based on `var`, 
	`when`, and `then` input parameters and that can be used as is in a `CASE` expression.

### Examples
The simple example below:

~~~sas
~~~
returns .

### Note
The macro will not return exactly what you want if the symbol `$` appears somewhere in the `when` or `then` lists. 
If you need to use `$` in there, you can reset the global macro variable `G_PING_UNLIKELY_CHAR` (see `_setup_` 
file) to another dumb (unlikely) character of your own.

### See also
[%ds_select](@ref sas_ds_select), [%sql_clause_where](@ref sas_sql_clause_where), 
[%sql_clause_as](@ref sas_sql_clause_as), [%sql_clause_add](@ref sas_sql_clause_add), 
[%sql_clause_by](@ref sas_sql_clause_by), [%sql_clause_modify](@ref sas_sql_clause_modify). 
*/ /** \cond */

/* credits: grazzja */

%macro sql_clause_case(dsn		/* Input dataset 											(REQ) */
					, var		/* Variable to apply the operation upon 					(REQ) */
					, _case_=	/* Name of the macro variable storing the output expression	(REQ) */
					, when=		/* List of WHEN conditions of the CASE statement			(OPT) */
					, then=		/* List of THEN executions of the CASE statement			(OPT) */
					, lib=		/* Name of the input library 								(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* VAR, _CASE_: check/set */
  	%if  %error_handle(ErrorMissingInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=%quote(!!! Missing input parameter VAR !!!))
			or %error_handle(ErrorInputParameter, 
				%list_length(&var, sep=%str( )) GT 1, mac=&_mac,		
				txt=%quote(!!! Only one VAR variable accepted !!!)) %then
		%goto exit;

	/* DSN/LIB: check/set */
	%if %macro_isblank(lib) %then 	%let lib=WORK;		

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%if %error_handle(WarningInputParameter, 
			%var_check(&dsn, &_var, lib=&lib) NE 0, mac=&_mac,		
			txt=%quote(! Variable %upcase(&_var) does not exist in dataset &dsn - Will be created !), 
			verb=warn) %then 
		%goto next;
	%else %do;
			%let tmpvar=&tmpvar.&SEP&_var;
			%if not %macro_isblank(op) %then		%let newop=&newop.&SEP&_op;
			%if not %macro_isblank(as) %then		%let newas=&newas.&SEP&_as;
		%end;

	%local REP
		nthen nwhen ncase
		_i _ithen _iwhen
		_lithen _liwhen
		case_clause;
	/* initialise the output CASE clause */
	%let case_clause=;

	/* compress */
	%let then=%sysfunc(compbl(%quote(&then)));
	%let when=%sysfunc(compbl(%quote(&when)));
	
	/* replace with dummy improbable char */
	%if %symexist(G_PING_UNLIKELY_CHAR) %then 		%let REP=%quote(&G_PING_UNLIKELY_CHAR);
	%else							%let REP=%str($);
	%let when=%quote(%sysfunc(tranwrd(%bquote(&when), %str(%), %(), &REP)));
	%let then=%quote(%sysfunc(tranwrd(%bquote(&then), %str(%), %(), &REP)));

	/* count the number of conditions */
	%let nwhen=%sysfunc(countw(%quote(&when), &REP)); /* some error with list_length */
	%let nthen=%sysfunc(countw(%quote(&then), &REP));

	/* define the number of cases as the minimum size */
	%if &nwhen>&nthen %then %do;
		%let else_clause=-1;
		%let ncase=&nthen;
	%end;
	%else %if &nthen>&nwhen %then %do;
		%let else_clause=1;
		%let ncase=&nwhen;
	%end;
	%else %do;
		%let else_clause=0;
		%let ncase=&nthen; /* whatever */
	%end;
	
	%do _i=1 %to &ncase;
	
		/* define the corresponding items and their length */
		%let iwhen=%scan(%bquote(&when), &_i, &REP);
		%let _liwhen=%length(%bquote(&iwhen));
		%let ithen=%scan(%bquote(&then), &_i, &REP);
		%let _lithen=%length(%bquote(&ithen));

		/* check for the presence of special character ( or ) in the items */
		%if &_i EQ 1 %then %do;
			%if %bquote(%substr(%bquote(&iwhen), 1, 1)) EQ %str(%() %then 
				%let iwhen=%substr(%bquote(&iwhen),2);
			%if %bquote(%substr(%bquote(&ithen), 1, 1)) EQ %str(%() %then 
				%let ithen=%substr(%bquote(&ithen),2);
		%end;
		%else %if &_i EQ &ncase %then %do;
			%if %bquote(%substr(%bquote(&iwhen), &_liwhen)) EQ %str(%)) %then 
				%let iwhen=%substr(%bquote(&iwhen), 1, %eval(&_liwhen-1));
			%if %bquote(%substr(%bquote(&ithen), &_lithen)) EQ %str(%)) %then 
				%let ithen=%substr(%bquote(&ithen), 1, %eval(&_lithen-1));
		%end;

		/* update the CASE clause with the WHEN/THEN items */
		%let case_clause=&case_clause WHEN &iwhen THEN &ithen;

	%end;

	/* last round... */
	%if &else_clause EQ 1 %then %do;
		%let ithen=%scan(%bquote(&then), &nthen, &REP);
		%let _lithen=%length(%bquote(&ithen));
		%if %bquote(%substr(%bquote(&ithen), &_lithen)) EQ %str(%)) %then 
			%let ithen=%substr(%bquote(&ithen), 1, %eval(&_lithen-1));
		%let case_clause=&case_clause ELSE &ithen;
	%end;
	%else %if &else_clause EQ -1 %then %do; 
		%let iwhen=%scan(%bquote(&when), &nwhen, &REP);
		%let _liwhen=%length(%bquote(&iwhen));
		%if %bquote(%substr(%bquote(&iwhen), &_liwhen)) %then 
			%let iwhen=%substr(%bquote(&iwhen), 1, %eval(&_liwhen-1));
		%let case_clause=&case_clause WHEN &iwhen THEN ".";
	%end;

	/* store the output */
	data _null_;
		call symput("&_case_","&case_clause");
	run;

	%exit:
%mend sql_clause_case;

%macro _example_sql_clause_case;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let when=  (PL111 between 1 and 3),	 
			  	(PL111 between 5 and 39),  
			  	(PL111 = 84),			  
			  	(PL111 = 85),			  
			  	(PL111 between 86 and 88)
				;

	%let then=  ("    a"),
			    ("b - e"), 
			  	("    f"),  
			  	("    g"), 
			  	("    h"),  
				(" ");
	%put %sql_clause_case(when=%quote(&when), then=%quote(&then));

%mend _example_sql_clause_case;

/* 
%_example_sql_clause_case;
*/

%macro _obsolete_sql_clause_case(var, case);
	%local ncase
		else_clause
		case_clause;

	%let ncase=%sysfunc(countw(&case, %str(,))); /* error with list_length */
	%let else_clause=%sysfunc(mod(&ncase,2));

	%let case_clause=;
	%do i=1 %to &ncase;
		%let icase=%scan(&case, &i, %str(%),));
		%let _il = %bquote(%substr(%bquote(&icase),1,1));
		%if &_il EQ %str(%() %then %do;
			%if &i=&ncase AND &else_clause %then 
				%let case_clause=&case_clause ELSE %bquote(%sysfunc(tranwrd(%bquote(&icase),%str(%(),%str()))); 
			%else 
				%let case_clause=&case_clause WHEN %bquote(%sysfunc(tranwrd(%bquote(&icase),%str(%(),%str()))); 
		%end;
		%else %do;
			%let case_clause=&case_clause THEN %bquote(%sysfunc(tranwrd(%bquote(&icase),%str(%(),%str()))); 
		%end;
	%end;

	%let case_clause=CASE (&case_clause) AS &var;

	%exit:
	&case_clause	
%mend _obsolete_sql_clause_case;
