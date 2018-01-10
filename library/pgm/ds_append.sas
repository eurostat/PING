/** 
## ds_append {#sas_ds_append}
Conditionally append reference datasets to a master dataset using multiple occurences of 
`PROC APPEND`.

~~~sas
	%ds_append(dsn, idsn, icond=, cond=, drop=, ikeep=_NONE_, lib=WORK, ilib=WORK);
~~~

### Arguments
* `dsn` : input master dataset;
* `idsn` : (list of) input reference dataset(s) to append to the master dataset;
* `drop` : (_option_) list of variable(s) present in the input master dataset to be removed
	from the final output dataset; default: `drop=`, no variable is dropped;
* `ikeep` : (_option_) list of variable(s) present in the input reference dataset(s) to be 
	kept in the final dataset; note the use of the predefined flag `_ALL_` so that a variable
	present in any of the `idsn` will be kept; default: `ikeep=`, _i.e._ only the variables 
	present in `dsn` (and not listed in `drop`) are kept;
* `cond`: (_option_) `where` condition/filter to apply on the master dataset; default: `cond=`,
	_i.e._ no filtering is applied;
* `icond`: (_option_) `where` condition/filter to apply on (all) the input reference dataset(s); 
	default: `icond=`, _i.e._ no filtering is applied;
* `lib` : (_option_) name of the library with (all) reference dataset(s); default: `lib=WORK`;
* `ilib` : (_option_) name of the library with master dataset; default: `ilib=WORK`.

### Returns
The table `dsn` is updated using datasets in `idsn`.

### Examples
Let us consider test dataset #32 in `WORK`ing library:
geo	   | value  
:-----:|-------:
BE	   |      0 
AT	   |     0.1
BG     |     0.2
LU     |     0.3
FR     |     0.4
IT     |     0.5
and update it using test dataset #33:
geo	   | value  
:-----:|-------:
BE	   |     1 
AT	   |     .
BG     |     2
LU     |     3
FR     |     .
IT     |     4
For that purpose, we can run for the macro `%%ds_append ` using the `drop`, `icond` and `ocond` 
options as follows:

~~~sas
	%let geo=BE;
	%let icond=(geo = "&geo");
	%let cond=(not(geo = "&geo"));
	%let drop=value;
	%ds_append(_dstest32, _dstest33, drop=&drop, icond=&icond, cond=&ocond);
~~~

so as to reset `_dstest32` to the table:
 geo | value  
:---:|-------:
AT	 |     0.1
BG   |     0.2
LU   |     0.3
FR   |     0.4
IT   |     0.5
BE	 |      1 

### Notes
1. The condition/filter on the input master dataset are applied prior to any processing, using the
following when both options `drop` and `cond` are set:

~~~sas
	DATA &lib..&dsn(DROP=&drop);
		SET &lib..&dsn;
		WHERE &cond;
	run;
~~~
2. Then, depending on the setting of option `ikeep`, the macro `%%ds_append` may process several 
occurrences of the `PROC APPEND` procedure like this:

~~~sas
	%do i=1 %to %list_length(&idsn);
		%let _idsn=%scan(&idsn, &_i);
		PROC APPEND
			BASE=&lib..&dsn
			DATA=&ilib..&_idsn(WHERE=&icond)
			FORCE NOWARN;
		run;
	%end;
~~~
when `ikeep=`, otherwise it consists in a `DATA step` similar to this:

~~~sas
	DATA  &lib..&dsn;
		SET &lib..&dsn 	
		%do i=1 %to %list_length(&idsn);
			%let _idsn=%scan(&idsn, &_i);
			%ds_contents(&_idsn, _varlst_=var, lib=&ilib);
			%let _ikeep&i=%list_intersection(&var, &ikeep);
			&ilib..&_idsn(WHERE=&icond KEEP=&&_ikeep&i)
		%end;
		;
	run;
~~~
3. If you aim at creating a dataset with `n`-replicates of the same table, _e.g._ running something like:

~~~sas
	   %ds_append(dsn, dsn dsn dsn); * !!! AVOID !!!;
~~~
so as to append to `dsn` a number `n=3` of copies of itself, you should instead consider to copy beforehand 
the table into another dataset to be used as input reference. Otherwise, you will create, owing to the `do` 
loop above, a table with (2^n-1) replicates instead, _i.e._ if you will append to `dsn` (2^3-1)=7 copies of 
itself in the case above. 

### References
0. SAS institute: ["Combining SAS datasets: Methods"](https://v8doc.sas.com/sashtml/lrcon/z1081414.htm).
1. Zdeb, M.: ["Combining SAS datasets"](http://www.albany.edu/~msz03/epi514/notes/p121_142.pdf).
2. Thompson, S. and Sharma, A. (1999): ["How should I combine my data, is the question"](http://www.lexjansen.com/nesug/nesug99/ss/ss134.pdf).
3. Dickstein, C. and Pass, R. (2004): ["DATA Step vs. PROC SQL: What's a neophyte to do?"](http://www2.sas.com/proceedings/sugi29/269-29.pdf).
4. Philp, S. (2006): ["Programming with the KEEP, RENAME, and DROP dataset options"](http://www2.sas.com/proceedings/sugi31/248-31.pdf).
5. Carr, D.W. (2008): ["When PROC APPEND may make more sense than the DATA STEP"](http://www2.sas.com/proceedings/forum2008/085-2008.pdf).
6. Groeneveld, J. (2010): ["APPEND, EXECUTE and MACRO"](http://www.phusewiki.org/wiki/index.php?title=APPEND,_EXECUTE_and_MACRO).
7. Logothetti, T. (2014): ["The power of PROC APPEND"](http://analytics.ncsu.edu/sesug/2014/BB-18.pdf).

### See also
[APPEND](https://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000070934.htm).
*/ /** \cond */

/* credits: gjacopo, marinapippi */

%macro ds_append(dsn		/* Input master dataset to be updated					(REQ) */
				, idsn		/* Input reference dataset(s)          					(REQ) */
				, cond=  	/* Condition to apply to master dataset   				(OPT) */    
			    , icond=	/* Condition to apply to reference dataset(s) 			(OPT) */  
			  	, drop=   	/* Name of variables to remove from master dataset 		(OPT) */
			    , ikeep=	/* Name of variables to keep from reference dataset(s) 	(OPT) */  
			    , lib=	 	/* Name of the output library	        				(OPT) */
			    , ilib=		/* Name of the input library 	            			(OPT) */
			    );
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _idsn   	 /* temporary dataset */
		nidsn		/* number of input reference dataset(s) */
		_var 		/* list of variables */
		_sep        /* separetor         */ 
		;

    %let _sep=%str(-);

	/* DSN/LIB: check/set */
	%if %macro_isblank(lib)	%then 	%let lib=WORK;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=!!! Master dataset %upcase(&dsn) not found !!!) %then
		%goto exit;

	/* IDSN/ILIB: check/set */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
	%ds_check(&idsn, _dslst_=_idsn, lib=&ilib);		

	%if %error_handle(ErrorInputParameter,
			%macro_isblank(_idsn), mac=&_mac,
			txt=!!! No reference dataset found !!!) %then	
		%goto exit;

	/* update the list of input reference dataset(s) */
	%let idsn=&_idsn;
	%let nidsn=%list_length(&idsn);
		
	/* DROP: format/update */
	%if not %macro_isblank(drop) %then 		%let drop=%upcase(&drop);

	/* IKEEP: format/update */
	%if not %macro_isblank(ikeep) %then 	%let ikeep=%upcase(&ikeep);

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i	/* local increment counter */
		_j	/* local increment counter */
		ans
		SEP		/* separator                               */
      	_ivar	/* intermediary list of input variables    */
		_ilvar;	/* list of all (unique) variables present in all input datasets */
	%let _ilvar=;
	%let SEP=%quote( );

	/* retrieve the list _VAR of variables actually present in the master dataset DSN */
	%ds_contents(&dsn, _varlst_=_var, varnum=yes, lib=&lib);
	/* update this list whenever DROP is passed */
	%if &drop^= %then %do;	
		%let _var=%list_difference(&_var, &drop); 
	%end; /* now: DROP &drop is equivalent to KEEP &_VAR */
	/* %else %do: nothing */

	/* build a KEEP variable for each input reference dataset */
	%if  not %macro_isblank(ikeep) %then %do;
		%do _i=1 %to &nidsn;
			%local _ikeep&_i;
			%let _idsn=%scan(&idsn, &_i);
			%let _ivar=; /* reset */
			%ds_contents(&_idsn, _varlst_=_ivar, varnum=yes, lib=&ilib);
			/* %if %list_compare(&var, &ivar) NE 0 %then %do */
			%if "&ikeep"="_ALL_" %then %do;
				/* all variables of IDSN are kept */
				%let _ikeep&_i=&_ivar; 
			%end;
			%else %do;
				/* all variables passed through IKEEP wich are present in IDSN are dropped */
				%let _ikeep&_i=%list_intersection(&_ivar, &ikeep);
			%end;
			%let _ikeep&_i=%list_unique(&_var.&SEP.&&_ikeep&_i);
			/* update the list of variables actually appended to the master dataset */
			%let _ilvar=%list_unique(&_ilvar.&SEP.&_ivar);
			/* update the list of variables common to both the master and the reference datasets */
			%let _ivar=%list_intersection(&_ivar, &_var); 
			/* further check the type compatibility of the files to append */
			%var_compare(&_idsn, &_ivar, _ans_=ans, dsnc=&dsn, typ=YES, len=NO, fmt=NO, lib=&lib, libc=&ilib);
			%if %error_handle(ErrorInputParameter,
					%list_count(&ans, 1) GT 0, mac=&_mac,
					txt=%quote(!!! Variables %upcase(&_ivar) have different types in datasets &dsn and &_idsn !!!)) %then 
				%goto exit;
		%end;
	%end;

	/* apply first the COND condition and/or DROP filtering on the master dataset */
	%if not (%macro_isblank(cond) and %macro_isblank(drop)) %then %do;
		DATA &lib..&dsn
			%if not %macro_isblank(drop) %then %do;
				(DROP=&drop)
			%end;
			;
			SET &lib..&dsn;
			%if not %macro_isblank(cond) %then %do;
				WHERE &cond
			%end; /* applying this condition directly in the PROC APPEND (below) runs into error */
			;
		run;
	%end;	

	/* approach based on PROC APPEND */
	%if %macro_isblank(ikeep) %then %do;

		/* loop over the updating datasets */
		%do _i=1 %to &nidsn;
			%let _idsn=%scan(&idsn, &_i);
			/*%let _iprev=%eval(&_i - 1);*/
			/* note that with PROC APPEND, the order of the variables in the output dataset depends
			* on the order of the first dataset passed to BASE, _i.e._ the master in this case */
			PROC APPEND
				BASE=&lib..&dsn 	
				/* OBSOLETE: if the DATA= dataset contains a variable that is not in the BASE= data set, 
				* the FORCE option in PROC APPEND forces the procedure to concatenate the two data sets. 
				* But because that variable is not in the descriptor portion of the BASE= data set, the 
				* procedure cannot include it in the concatenated data set. 
				* 
				* if the DROP clause is present, we get rid of the variables that were possibly added
				* to the master dataset through previous APPEND operation with dataset in position (_i - 1)
				* in the list of reference datasets 
				%if %eval(&_i GT 1) and %macro_isblank(drop) EQ 0 %then %do;
					%if not %macro_isblank(_drop&_iprev) %then %do;
					(DROP=&&_drop&_iprev)
					%end;
				%end;
				*/
				DATA=&ilib..&_idsn
				/* if the ICOND condition is present, filter the reference dataset */	
	            %if  not %macro_isblank(icond) %then %do;	
					(WHERE=&icond) 
				%end;
				FORCE NOWARN
				;
			run;

		%end;

	%end;

	/* if we want to keep some variable from the reference dataset, PROC APPEND is not appropriate:
	* if the BASE= data set contains a variable that is not in the DATA= data set, then PROC APPEND
	* concatenates the data sets and assigns a missing value to that variable in the observations  
	* that are taken from the DATA= data set.
	* Therefore, we use an alternative approach based on DATA step. Note some drawbacks of this
	* approach:
	*	- efficiency reasons: see articles mentioned in list of references
	* 	- issue with the contemporaneous use of KEEP and WHERE when the condition in WHERE 
	* 	  uses some variables not in KEEP (?!!!) */
	%else %do;

		DATA  &lib..&dsn;
			SET &lib..&dsn 	
			%do _i=1 %to %list_length(&idsn);
			   	%let _idsn=%scan(&idsn, &_i);
			    &ilib..&_idsn
				%if not (%macro_isblank(icond) and %macro_isblank(ikeep)) %then %do;
				(
				%end;
				%if  not %macro_isblank(icond) %then %do;
					WHERE=&icond
				%end;
				%if  not %macro_isblank(ikeep) %then %do;
					%if  not %macro_isblank(_ikeep&_i) %then %do;
						%put ------------ KEEP=&&_ikeep&_i;
						KEEP=&&_ikeep&_i
					%end;
				%end;
				%if not (%macro_isblank(icond) and %macro_isblank(ikeep)) %then %do;
				)
				%end;
			%end; 
			;
		 run;

	%end;

	/* update the list of variables: it is possible that we already cleaned the input dataset,
	* hence no need to do it again... 
	%ds_contents(&dsn, _varlst_=_var, varnum=yes, lib=&lib);
	/* reduce the list of variables to those present in the list above, so as to avoid any message like:
			WARNING: The variable [...] in the DROP, KEEP, or RENAME list has never been referenced 
	* for that purpose, we intersect the variables to drop from the last reference dataset with the variables
	* in the master dataset
	%let _drop&nidsn=%list_intersection(&_var, &&_drop&nidsn);
	/* actually drop the desired variables from the master dataset 
	%if not %macro_isblank(_drop&nidsn) %then %do;
	   	PROC SQL;
			ALTER TABLE &lib..&dsn DROP &&_drop&nidsn;	
		quit;
	%end;*/
 
	%exit:
%mend ds_append;

%macro _example_ds_append;
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

	%work_clean(_dstest25, _dstest26, _dstest31, _dstest32, _dstest33, _dstest37, _dstest38, _dstest39);
	%local TMP dsn idsn;

 	%_dstest25;
   	%put;
	%put (i) Crash test: update a master dataset (test #25) using a DUMMY non-existing dataset;
	%ds_append(_dstest25, DUMMY); 

   	%put;
	%put (ii) Crash test: ibid, update a DUMMY master dataset with an existing one (test #25);
	%ds_append(DUMMY, _dstest25); 

	%_dstest26;
 	%ds_print(_dstest26, title="Test (iii): _dstest26");
   %put;
	%put (iii) Update a master dataset (test #26) with two datasets, one of which is DUMMY;
	%ds_append(_dstest26, DUMMY _dstest26); 
	%ds_print(_dstest26, title="Output: APPEND(_dstest26, DUMMY _dstest26)");

	%_dstest32;
	%ds_print(_dstest32, title="Test (iv): _dstest32");
	%let drop=geo;
	%put; 
	%put (iv) Update a master dataset (test #32) with two datasets;
	%ds_append(_dstest32, _dstest32 _dstest32, drop=&drop); 
	%ds_print(_dstest32, title="Output: APPEND(_dstest32, _dstest32 _dstest32) AND %bquote(drop=&drop)");

	%_dstest31;
	%ds_print(_dstest31, title="Test (v): _dstest31");
	%_dstest33;
	%ds_print(_dstest33);
	%let ikeep=unit;
    %put;
	%put (v) Update master dataset (test #33) with dataset #31 keeping &ikeep variable;
	%ds_append(_dstest33, _dstest31, ikeep=&ikeep);
 	%ds_print(_dstest33, title="Output: APPEND(_dstest33, _dstest31) AND %bquote(ikeep=&ikeep)");

	%work_clean(_dstest32); 
	%_dstest32;  
	%ds_print(_dstest32, title="Test (vi): _dstest32");
	%let geo=BE;
	%let icond=(geo = "&geo");
	%let cond=(not(geo = "&geo"));
    %put;
   	%put (vi) Update master dataset (test #32) with conditions:  icond=&icond and cond=&cond;
	%ds_append(_dstest32, _dstest31, cond=&cond, icond=&icond); 
 	%ds_print(_dstest32, title="Output: APPEND(_dstest32, _dstest31) WITH %bquote(icond=&icond) AND %bquote(cond=&cond)"); 

	%_dstest37;
	%ds_print(_dstest37, title="Test (vii): _dstest37");
	%_dstest38;
 	%ds_print(_dstest38);
	%let icond=(time = 2013);
    %put;
	%put (vii) Update master dataset (test #38) with condition on reference input datasets;
	%ds_append(_dstest38, _dstest37 _dstest37, icond=&icond);   
 	%ds_print(_dstest38, title="Output: APPEND(_dstest38, _dstest37 _dstest37) WITH %bquote(icond=&icond)");

	%put;
	%_dstest26;
	%ds_print(_dstest26, title="Test (viii): _dstest26");
	%_dstest27;
	%ds_print(_dstest27);
    %let cond=(not(time = 2013));
	%put (viii) Update master dataset (test #26) with condition on master dataset;
	%ds_append(_dstest26, _dstest27, cond=&cond);   
 	%ds_print(_dstest26, title="Output: APPEND(_dstest26, _dstest27) WITH %bquote(cond=&cond)"); 

	%_dstest37;
	%ds_print(_dstest37, title="Test (ix): _dstest37");
	%_dstest38;
	%ds_print(_dstest38);
	%_dstest39;
	%ds_print(_dstest39);
	%let geo=BE;
	%let drop=geo;
    %let cond=(not(geo = "&geo"));
	%put (ix) Update master dataset (test #38) with two datasets having condition input condition and a drop (applied for dataset #37)  ;
	%let icond=(not(geo = "&geo"));
	%ds_append(_dstest38, _dstest37,  drop=&drop, cond=&cond, icond=&icond);   
 	%ds_print(_dstest38, title="Interim: APPEND(_dstest38, _dstest37) WITH %bquote(cond=&cond AND icond=&icond AND drop=&drop)");
	%let icond=(geo ="&geo");
	%ds_append(_dstest38, _dstest39,  icond=&icond); 
 	%ds_print(_dstest38, title="Output: APPEND(_dstest38, _dstest39) WITH %bquote(icond=&icond)");

	%work_clean(_dstest25, _dstest26, _dstest27, _dstest31, _dstest32, _dstest33, _dstest37, _dstest38, _dstest39);

	%exit:
%mend _example_ds_append;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_append; 
*/

/** \endcond */
