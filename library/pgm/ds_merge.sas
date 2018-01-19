/** 
## ds_merge {#sas_ds_merge} 
Create a dataset by applying filtering conditions (when it exists), and/or stacking it
with annother dataset (one-to-one or one-to-many merge).

~~~sas
	%ds_merge(ref, rlib=WORK, dsn=, lib=WORK, by=, cond=, if=);
~~~

### Arguments
* `ref` : a master/reference dataset; may exist or not;
* `rlib` : (_option_) name of the library where the master dataset `ref` is stored; by 
	default: empty, _i.e._ `WORK` is used; however, if `ref` does not exist and `dsn` is 
	given, then it is set to `lib` (see below), otherwise it is set to the default value; 
* `dsn` : (_option_) a secondary datasets to stack/merge with the reference dataset;
* `lib` : (_option_) name of the library where the dataset `dsn` is stored; by default: 
	empty and `WORK` is used;
* `by` : (_option_) list of variables to use for (smart) sorted output stack; both datasets 
	`ref` and `dsn` need to be sorted by the same variables beforehand; 
* `cond` : (_option_) condition to apply to dsn data set;
* `if` : (_option_) condition to apply to dsn input data sets.

### Returns
Updates or creates the master dataset `ref`.

### Example
Let us consider both tables `_dstest30` and `_dstest31`, as respectively: 
The following table is stored in `_dstest30`:
geo | value 
----|-------
 BE |  0    
 AT |  0.1  
 BG |  0.2  
 '' |  0.3 
 FR |  0.4  
 IT |  0.5 

The following table is stored in `_dstest31`:
geo | value | unit
----|-------|-----
 BE |  0    | EUR
 AT |  0.1  | EUR
 BG |  0.2  | NAC
 LU |  0.3  | EUR
 FR |  0.4  | NAC
 IT |  0.5  | EUR

then we can "merge" `_dstest30` into `_dstest31` by invoking the macro as follows:
 
~~~sas
    	%let cond=%quote(in=a in=b);
	%let by=%quote(geo );
	%let if=%quote(A and B);
~~~
so that we get the output table:
geo | value | unit
----|-------|-----
AT	|  0.1	| EUR
BE	|  0	| EUR
BG	|  0.2	| NAC
FR	|  0.4	| NAC
IT	|  0.5	| EUR

since the condition `cond` applies on the table `ds_input_vi`.

Run macro `%%_example_ds_merge` for more examples.

### Note
The macro `%%ds_merge` processes several occurrences of the `data setp merge`, _e.g._ in short it runs
something like:

~~~sas
	DATA  &rlib..&ref;
		merge  
	 	%do _i=1 %to &ndsn;
			%let _dsn = %scan(&dsn, &_i);
			%if &nlib >1 %then %do;
				%let _lib = %scan(&lib, &_i);
			%end;
		    &_lib..&_dsn 
			%if &existcond=1 %then %do;
				(%scan(&cond, &_i))
			%end;
		%end; 
		;
       	%if not %macro_isblank(by)  %then   %do;  
	   		by &by;
	   	%end;
        %if not %macro_isblank(cond) and not %macro_isblank(if)  %then %do;
			if &if;
		%end;
 	run; 
~~~

### References
1. Michael J. Wieczkowski, IMS HEALTH, Plymouth Meeting: [Alternatives to Merging SAS Data Sets ... But Be Careful] (http://www.ats.ucla.edu/stat/sas/library/nesug99/bt150.pdf)
2. IDRE Research Technology Group["SAS learning module match merging data files in SAS"](http://www.ats.ucla.edu/stat/sas/modules/merge.htm).

### See also
[%ds_check](@ref sas_ds_check), [%ds_delete](@ref sas_ds_delete), [%ds_sort](@ref sas_ds_sort). 
*/ /** \cond */

/* credits: gjacopo, marinapippi */

%macro ds_merge(ref    		/*  master/reference dataset                                      (REQ)*/
			 ,rlib=         /* name of the library where the master dataset `ref` is stored   (OPT)*/
			 ,dsn=          /* a secondary datasets to stack/merge with the reference dataset (OPT)*/
			 ,lib=          /* name of the library where the dataset `dsn` is stored          (OPT)*/
			 ,by=           /* list of variables to use for (smart) sorted output stack       (OPT)*/
			 ,cond=      /* condition to apply to dsn data set   						  (OPT)*/
			 ,if=           /* condition to apply to dsn input data sets 					  (OPT)*/
			 );

	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac); /* avoid conflict with returned value (see __ans below) */

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/
	%local nlib				/* number of input library                                  */
		 _existRef          /* result of check whether refrence dataset already exits   */
		 ndsn    		    /* number of input dataset(s)                               */
		 nref    		    /* number of reference dataset(s)                           */
		 nlib    		    /* number of input library (ies)                            */
		 nrlib    		    /* number of output library (ies)                           */
		 _i					/* loop increment                                           */
	 	 _dsn         		/* scanned input dataset                                    */
		 _lib         		/* scanned input libname                                    */
		 ;

	/* checking input */

	%let ndsn=%sysfunc(countw(&dsn));  			     /* %list_length(&dsn)         */
	%let nref=%sysfunc(countw(&ref));  			     /* %list_length(&ref)         */
	%let nlib=0;                                     /* setting of nlib variable   */ 

    /* check &cond variable and &ndsn variable                                     */ 
	/* if cond exists the number of cond(s) Must be equal to the number of dsn(s)  */
   	%if not %macro_isblank(cond) %then %do;          
		%let ncond=%list_length(&cond, sep=%quote( ));
		%put &ncond=ncond &cond=cond nref=&nref marina;

		%if %error_handle(ErrorInputDataset, 
				%list_compare(&ndsn,&ncond) NE 0,		
				txt=!!! number of condition (cond) is different from number of dsn to merge !!!) %then
			%goto exit;
 	%end;
   
	%if %macro_isblank(lib)  %then 	%let lib=WORK;
	%else %do;
		%let nlib=%sysfunc(countw(&lib)); 		        /* %list_length(&lib) */
	/* check if number of libname are equal to the number of input datasets                              */
	/* if number of input libname is greater than 1,the number  MUST be equal to the number of input dsn */
		%if &nlib>1 %then %do;
        	%if %error_handle(ErrorInputDataset,        
					%list_compare(&ndsn,&nlib) NE 0,		
					txt=!!! number of libname  (lib) is different from number of dsn  !!!) %then
				%goto exit;
		%end;
	%end;
 	 /* check if input datasets exit */
	%do _i=1 %to &ndsn;                               
		%let _dsn = %scan(&dsn, &_i);
		%if &nlib >1 %then 	%let _lib = %scan(&lib, &_i);
		%else 				%let _lib = &lib;
		%if %error_handle(ErrorInputDataset, 
				%ds_check(&_dsn, lib=&_lib) NE 0,		
				txt=%bquote(!!! Dataset in position &_i does not exist !!!)) %then
			%goto exit;
	%end;


    /* check if output  dataset already exits */

	%if %macro_isblank(rlib) %then 	%let rlib=WORK;
	%else %do;
		%let nrlib=%sysfunc(countw(&rlib)); 		        /* %list_length(&rlib) */
	/* check if number of libname are equal to the number of input datasets                              */
	/* if number of input libname is greater than 1,the number  MUST be equal to the number of input dsn */
		%if &nrlib>1 %then %do;
        	%if %error_handle(ErrorInputDataset,        
					%list_compare(&ndsn,&nlib) NE 0,		
					txt=!!! number of libname  (lib) is different from number of dsn  !!!) %then
				%goto exit;
		%end;
	%end;

	%do _i=1 %to &nref; 
	 %if &nref >1 %then 	%let _ref = %scan(&ref, &_i);
	 %else                  %let _ref = &ref;

		%let _existRef=%ds_check(&ref, lib=&rlib);  
   
   
 		%if &_existRef=0 %then %do;
			%if %error_handle(ErrorInputDataset, 
				%ds_check(&ref, lib=&rlib)  EQ 0,		
				txt=!!! Output dataset already exists will be replicated !!!, verb=warn) %then
			%goto WARNING;
		%end;
	%end;

	%WARNING:
	
	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
	%local existcond  /* boolean variable: test if  'cond' variabale is passed  */ 
				;
    /* sort input datasets  if by variable is passed */
	%if not %macro_isblank(by)  %then   %do;   
      
		%do _i=1 %to &ndsn;
	    	%let _dsn = %scan(&dsn, &_i);
		    %ds_sort(&_dsn, asc=&by, ilib=&lib);
		 %end;
	%end;
   
	%let existcond=0;
    %if not %macro_isblank(cond)  %then %let existcond=1;

	DATA  &rlib..&ref;
		merge  
	 	%do _i=1 %to &ndsn;
			%let _dsn = %scan(&dsn, &_i);
			%if &nlib >1 %then %do;
				%let _lib = %scan(&lib, &_i);
			%end;
		    &_lib..&_dsn 
			%if &existcond=1 %then %do;
				(%scan(&cond, &_i))
			%end;
		%end; 
		;
       	%if not %macro_isblank(by)  %then   %do;  
	   		by &by;
	   	%end;
        %if not %macro_isblank(cond) and not %macro_isblank(if)  %then %do;
			if &if;
		%end;
 	run; 
	%exit:
%mend ds_merge;

%macro _example_ds_merge;
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

	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac); /* avoid conflict with returned value (see __ans below) */

	%local yyyy cond;
	%let yyyy=2015;

	%put (i) Invoke the macro, pass two not-existent input data set   ...;
	%ds_merge(ds_input_i, rlib=work, dsn=DIXX DIYY, lib=LIBCRDB);
    
	%put (ii) Invoke the macro, pass two existent input data set in two different libraries  ...;
	%ds_merge(ds_input_ii, rlib=work, dsn=DI01 LI33, lib=LIBCRDB LIBCRDB2);
 
 	%put (iii) Invoke the macro, pass two existent input data set name stored in the same libname  ...;
	%let cond=%quote(in=a in=b);
	%let by=%quote(geo time);
	%let if=%quote(A and B);
	%ds_merge(ds_input_iii, rlib=work, dsn=DI01 DI02, lib=LIBCRDB,by=&by, cond=&cond,if=&if);

    %put (iv) Invoke the macro, pass two existent input data set name stored in the same libname  ...;
	%let cond=%quote(in=a in=b);
	%ds_merge(ds_input_iv, rlib=work, dsn=DI01 DI02, lib=LIBCRDB,by=&by, cond=&cond,if=&if);

	%put (v) Invoke the macro, pass two existent input data set name stored in the same WORK libname  ...;
	%_dstest30;
	%_dstest31;
	%let cond=%quote(in=a in=b);
	%let by=%quote(geo );
	%let if=%quote(A or B);
	%ds_merge(ds_input_v,ds_input_iv,ds_input_iii,ds_input_ii,dsn=_dstest30 _dstest31,by=&by, cond=&cond,if=&if);
 	 
	%work_clean();

	%exit:
%mend _example_ds_merge;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;*/
/*

%_example_ds_merge; 

/** \endcond */


