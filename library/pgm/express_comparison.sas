/** 
## express_comparison {#sas_list_map}
Calculate the transform of a list given by a mapping table (similarly to a LookUp Transform, LUT).

~~~sas
	express_comparison(arg, _exp_=, force_sql=NO);
~~~

Cassell, L.D. (2005): [*PRX functions and Call routines*](http://www2.sas.com/proceedings/sugi30/138-30.pdf).

comparison operators:
* http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#a000780367.htm
* note:
* Symbols => and <= are accepted for compatibility with previous releases of SAS, but they are not
* supported in WHERE clauses or in PROC SQL
*/

/* credits: gjacopo */

%macro express_comparison(arg
						, _exp_=
						, force_sql=
						);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local OPS MAP
		COPS SOPS
		SEP;
 	%let OPS = GE >= LE <= NE ^= ~= GT >  LT <  EQ =  IN; 
	%let MAP = GE GE LE LE NE NE NE GT GT LT LT EQ EQ IN;
	%let COPS = GE LE NE    EQ GT LT  IN;
	%let SOPS = >= <= ^= ~= =  >  < ;
	%let SEP=%quote( ); 

	/* ARG: check already multiple arguments */

	/* _EXP_: check */
	%if %error_handle(ErrorOutputParameter, 
				%macro_isblank(_exp_) EQ 1, mac=&_mac,		
				txt=%quote(!!! Output parameter _EXP_ not set !!!)) %then
		%goto exit;

	/* FORCE_SQL: set default/update parameter */
	%if %macro_isblank(force_sql)  %then 	%let force_sql=NO; 
	%else									%let force_sql=%upcase(&force_sql);
 
	%if %error_handle(ErrorInputParameter, 
			%par_check(&force_sql, type=CHAR, set=YES NO) NE 0,	
			txt=!!! Parameter FORCE_SQL is boolean flag with values in (yes/no) !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i _ind
		_in _out _isquoted
		op _op _lop
		_pos _nop
		patt _ipatt _npatt
		_res;
	%let _npatt=0;
	%let res=;
	%let _isquoted = NO;

	%do _i=1 %to %list_length(&SOPS);
		%let _op = %scan(&SOPS, &_i, &SEP);
		%let _patt = %sysfunc(prxparse(/&_op/));
		%let _ipatt = %sysfunc(prxmatch(&_patt, &arg));
		/* check whether the operation is the one used in the expression */
		%if &_ipatt EQ 0 %then
			%goto snext;
		/* ensure that multiple operations are not inserted in the expression
		%else %if %error_handle(ErrorInputParameter, 
				&_npatt EQ 1, mac=&_mac,		
				txt=%quote(!!! More than one operator found in expression !!!)) %then
			%goto quit;  /* this cannot deal with the presence of <= and = */
		%else 
			%goto proceed;
		%snext:
	%end;

	%do _i=1 %to %list_length(&COPS);
		%let _op = %scan(&COPS, &_i, &SEP);
		%let _patt = %sysfunc(prxparse(/ &_op /));
		%let _ipatt = %sysfunc(prxmatch(&_patt, &arg));
		/* ibid, check whether the operation is the one used in the expression */
		%if &_ipatt EQ 0 %then
			%goto cnext;
		/* ensure that multiple operations are not inserted in the expression
		%else %if %error_handle(ErrorInputParameter, 
				&_npatt EQ 1, mac=&_mac,		
				txt=%quote(!!! More than one operator found in expression !!!)) %then
			%goto quit;  /* this cannot deal with the presence of <= and = */
		%else /* set the operator */
			%goto proceed;
		%cnext:
	%end;

	/* if we reach that point... problem */
	%if %error_handle(ErrorInputParameter, 
			1, mac=&_mac,		
			txt=%quote(!!! No expression/comparison found in &arg !!!)) %then
		%goto quit;

	%proceed:

	%let _lop = %length(&_op);
	/* define the left-side/input and right-side/output for the operation */
	%let _in = %sysfunc(compbl(%substr(&arg, 1, %eval(&_ipatt-1))));
	%let _out = %sysfunc(compbl(%substr(&arg, %eval(&_ipatt+&_lop+1))));

	%let _pos=%list_find(&OPS, &_op, casense=no, sep=&SEP);
	/* update the output list with correspondance value */
	%let _nop=%list_index(&MAP, &_pos, sep=&SEP);

	%if %list_length(&_out, sep=&SEP) GT 1 %then %do;
		%if "&_nop" EQ "EQ" %then 
			%let _nop=IN;
		%else %if "&_nop" EQ "NE" %then 
			%let _nop=NOT IN;
		%else %if %error_handle(ErrorInputParameter, 
				1, mac=&_mac,		
				txt=%quote(!!! More than one value found with operator &op !!!)) %then
			%goto quit;

		%if %bquote(%substr(%bquote(%sysfunc(reverse(%bquote(&_out)))),1,1)) EQ %str(%")
				and %bquote(%substr(%bquote(&_out),1,1)) EQ %str(%") %then %do;
			%let _isquoted = YES;
			%let _out=%clist_unquote(&_out, sep=_EMPTY_, rep=%quote( ));
		%end;
		
		%if "&_isquoted" = "YES" or "&force_sql" = "YES" %then 
			%let _out=%sql_list(&_out);
		%else
			%let _out=(%list_quote(&_out, sep=%quote( ), rep=%quote(,), mark=_EMPTY_));
	%end;

	%let _res=&_in &_nop &_out;
	data _null_;
		call symput("&_exp_", "%bquote(&_res)");
	run;

	%quit:
	%syscall prxfree(_patt);

	%exit:
%mend express_comparison;


%macro _example_express_comparison;
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

	%local exp iexp oexp;

	%let iexp=age 65;
	%let oexp=;
	%put (i) Dummy test where no operator appears in the expression: &iexp ...;
	%let exp=;
	%express_comparison(%quote(&iexp), _exp_=exp);
	%if %bquote(&exp) EQ %then 					%put OK: TEST PASSED - Dummy input identified;
	%else 										%put ERROR: TEST FAILED - Wrong output;

	%let iexp=age > 65;
	%let oexp=age GT 65;
	%put (ii) Test a simple expression with ">" symbol: &iexp ...;
	%let exp=;
	%express_comparison(%quote(&iexp), _exp_=exp);
	%if %bquote(&exp) EQ %bquote(&oexp) %then 	%put OK: TEST PASSED - Expression recognised: &oexp;
	%else 										%put ERROR: TEST FAILED - Wrong expression output: &exp;

	%let iexp=ht1 = 3 4 7;
	%let oexp=ht1 IN (3,4,7);
	%put (iii) Test an "=" expression with a list of values: &iexp ...;
	%let exp=;
	%express_comparison(%quote(&iexp), _exp_=exp);
	%if %bquote(&exp) EQ %bquote(&oexp) %then 	%put OK: TEST PASSED - Expression recognised: &oexp;
	%else 										%put ERROR: TEST FAILED - Wrong expression output: &exp;

	%let iexp=geo = "AT" "BE";
	%let oexp=geo IN ("AT","BE");
	%put (iv) Test an "=" expression with a list of CHAR values: &iexp ...;
	%let exp=;
	%express_comparison(%quote(&iexp), _exp_=exp);
	%if %bquote(&exp) EQ %bquote(&oexp) %then 	%put OK: TEST PASSED - Expression recognised: &oexp;
	%else 										%put ERROR: TEST FAILED - Wrong expression output: &exp;

	%let iexp=geo EQ AT BE;
	%let oexp=geo IN (AT,BE);
	%put (v) Test a similar "EQ" expression with a list of values: &iexp ...;
	%let exp=;
	%express_comparison(%quote(&iexp), _exp_=exp);
	%if %bquote(&exp) EQ %bquote(&oexp) %then 	%put OK: TEST PASSED - Expression recognised: &oexp;
	%else 										%put ERROR: TEST FAILED - Wrong expression output: &exp;

	%let oexp=geo IN ("AT","BE");
	%put (v) Test that same expression: &iexp, but forcing a SQL-like output ...;
	%let exp=;
	%express_comparison(%quote(&iexp), _exp_=exp, force_sql=YES);
	%if %bquote(&exp) EQ %bquote(&oexp) %then 	%put OK: TEST PASSED - Expression recognised: &oexp;
	%else 										%put ERROR: TEST FAILED - Wrong expression output: &exp;

	%let iexp=time >= 2010;
	%let oexp=time GE 2010;
	%put (vi) Test a numeric expression: &iexp ...;
	%let exp=;
	%express_comparison(%quote(&iexp), _exp_=exp);
	%if %bquote(&exp) EQ %bquote(&oexp) %then 	%put OK: TEST PASSED - Expression recognised: &oexp;
	%else 										%put ERROR: TEST FAILED - Wrong expression output: &exp;

	%let iexp=time = 2010 2011 2012;
	%let oexp=time IN (2010,2011,2012);
	%put (vii) Test another numeric expression with a list of values: &iexp ...;
	%let exp=;
	%express_comparison(%quote(&iexp), _exp_=exp);
	%if %bquote(&exp) EQ %bquote(&oexp) %then 	%put OK: TEST PASSED - Expression recognised: &oexp;
	%else 										%put ERROR: TEST FAILED - Wrong expression output: &exp;

	%put;

	%exit:
%mend _example_express_comparison;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_check_expression; 
*/
%_example_express_comparison; 


/** \endcond */
