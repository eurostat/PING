 /** 
## ds_split {#sas_ds_split}

~~~sas
	%ds_split(idsn, var=, num=, oname=, _odsn_=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : ; 
* `var` : (_option_);
* `num` : (_option_);
* `oname` : (_option_);
* `ilib` : (_option_).

### Returns
* `_odsn_` : (_option_);
* `olib` : (_option_).

### References
1. Gerlach, J.R. and Misra, S. (2002): ["Splitting a large SAS dataset"](http://www2.sas.com/proceedings/sugi27/p083-27.pdf).
2. Williams, C.S. (2008): ["PROC SQL for DATA step die-hards"](http://www2.sas.com/proceedings/forum2008/185-2008.pdf).
3. Hemedinger, C. (2012): ["How to split one data set into many"](http://blogs.sas.com/content/sasdummy/2015/01/26/how-to-split-one-data-set-into-many/).
4. Sempel, H. (2012): ["Splitting datasets on unique values: A macro that does it all"](http://support.sas.com/resources/papers/proceedings12/069-2012.pdf).
5. Ross, B. and Bennett, J. (2016): ["PROC SQL for SQL die-hards"](http://support.sas.com/resources/papers/proceedings16/7540-2016.pdf). 

### See also
[%ds_select](@ref sas_ds_select).
*/ /** \cond */
 
/* credits: grillma */

%macro ds_split(idsn
				, var=
				, num=
				, oname=
				, _odsn_=
				, ilib=
				, olib=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(ilib) %then %let ilib=WORK;
	%if %macro_isblank(olib) %then %let olib=WORK;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _run_splits
		typ;

	%if not %macro_isblank(num) %then %do;

		%macro _split_equal(idsn, num, oname, ilib, olib);
			%local _i
				__odsn;
			DATA %do _i = 1 %to &num.; 
					&olib..&oname.&_i.(DROP=x) 
				%end; ;
				RETAIN x;
				SET &ilib..&idsn nobs=nobs;
				if _N_ EQ 1 then do;
					if mod(nobs, &num.) EQ 0 then 	x=int(nobs/&num.);
					else 							x=int(nobs/&num.)+1;
				end;
				if _N_ LE x then output &oname.1;
				%do _i = 2 %to &num.;
					else if _N_ LE (&_i.*x) then output &oname.&_i.;
				%end;
			run;
			%if not %macro_isblank(_odsn_) %then %do;
				%do _i = 1 %to &num.; 
					%let __odsn=&__odsn &oname.&_i;
				%end; 
				 data _null_;
					call symput("&_odsn_","&__odsn");
				run;
			%end; 
		%mend _split_equal;

		%_split_equal(&idsn, &num, &oname, &ilib, &olib);

	%end;

	%else /* %if not %macro_isblank(var) %then */ %do;

		%macro _split_byvar(idsn, var, oname, ilib, olib);
			%local _run_splits
				dsid 
				pos 	
				typ;
			/* retrieve the type of the considered variable */
		 	data _null_;
		  		dsid = open("&ilib..&idsn",'i', , 'D'); /* D:  two-level data set name */
				pos = varnum(dsid, "&var");
			    typ = vartype(dsid, pos);
				call symput("typ",compress(typ,,'s'));
			    rc = close(dsid);
			run;
			/* build a program for each value: create a table with valid char/num from data value */
			PROC SQL noprint;
				SELECT DISTINCT  
			   	CAT("DATA &olib..&oname",
					%if "&typ"="N" /* NUMERIC */ %then %do;
						&var,
			   			"; SET &ilib..&idsn.(WHERE=(&var.=", &var.,"));", 
					%end;
					%else /* %if "&typ"="C" /* CHAR */ %do;
						compress(&var.,,'kad'),
			   			"; SET &ilib..&idsn.(WHERE=(&var.='", strip(&var.),"'));", 
					%end;
					"run;") 
				INTO :_run_splits SEPARATED BY ';' 
			  	FROM &ilib..&idsn;
				%if not %macro_isblank(_odsn_) %then %do;
					SELECT DISTINCT  
				   	CAT("&oname",
						%if "&typ"="N" %then %do;
							&var
						%end;
						%else %do;
							compress(&var.,,'kad')
						%end;
						) 
					INTO :&_odsn_ SEPARATED BY ' ' 
				  	FROM &ilib..&idsn;
				%end;
			quit;
			/* actually create the tables */
			&_run_splits.;
		%mend _split_byvar;

		%_split_byvar(&idsn, &var, &oname, &ilib, &olib);

	%end;

%mend ds_split;
 

%macro _example_ds_split;
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

	%local odsn;

	%_dstest3;

	/* and...run the macro when ready */
	/*%runSteps(cars, origin, name=out_, lib=sashelp);*/
	%ds_split(_dstest3, var=num, oname=out_, _odsn_=odsn);
	%put with var=num, odsn=&odsn;
	%ds_split(_dstest3, var=color, oname=out_, _odsn_=odsn);
	%put with var=color, odsn=&odsn;
	%ds_split(_dstest3, num=2, oname=num_, _odsn_=odsn);
	%put with num=2, odsn=&odsn;

	%exit:
%mend _example_ds_split;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_split; 
*/

/** \endcond */


