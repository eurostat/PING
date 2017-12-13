/** 
## var_missing_remove {#sas_var_missing_remove}
Remove missing variables  numeric or character from a given dataset.

~~~sas
	%var_missing_remove(idsn, odsn,len=1400, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : a dataset reference;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
* `len`  : (_option_) max length of macro variable ; by default: 1400 is used ( max value available is 32767) .

  
### Returns
* `odsn` : name of the output dataset (in `WORK` library); it will contain the selection operated on the 
	original dataset;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also used;

### Examples
Let us consider the test dataset #22:
 breakdown | variable | start | end | fmt1_dummy | fmt2_dummy | fmt3_dummy | fmt4_dummy | fmt5_dummy | fmt6_dummy
-----------|----------|-------|-----|------------|------------|------------|------------|------------------------
  label1   |   DUMMY  |   1   |  5	|      1	 |      0	  |      1	   |      0		|            |      .      
  label2   |   DUMMY  |   1   |  3	|      1	 |      1	  |      0	   |      0     |            |      . 
  label2   |   DUMMY  |   5   |  5	|      1	 |      1 	  |      0	   |      0     |            |      . 
  label2   |   DUMMY  |   8   |  10	|      1	 |      1 	  |      0	   |      0     |            |      . 
  label2   |   DUMMY  |   12  |  12	|      1	 |      1 	  |      0	   |      0     |            |      . 
  label3   |   DUMMY  |   1   |  10	|      0	 |      1 	  |      1	   |      0     |            |      . 
  label3   |   DUMMY  |   20  |HIGH |      0	 |      1	  |      1	   |      0     |            |      . 
  label4   |   DUMMY  |   10  |  20	|      0	 |      0	  |      0	   |      1     |            |      . 
  label5   |   DUMMY  |   10  |  12	|      0	 |      1	  |      1	   |      0     |            |      . 
  label5   |   DUMMY  |   15  |  17	|      0	 |      1	  |      1	   |      0     |            |      . 
  label5   |   DUMMY  |   19  |  20	|      0	 |      1	  |      1	   |      0     |            |      . 
  label5   |   DUMMY  |   30  |HIGH	|      0	 |      1	  |      1	   |      0     |            |      . 

and run the following:
	
~~~sas
	%_dstest22;
	%var_missing_remove(_dstest22, TMP);
~~~

to create the output table `TMP`:
 breakdown | variable | start | end | fmt1_dummy | fmt2_dummy | fmt3_dummy | fmt4_dummy
-----------|----------|-------|-----|------------|------------|------------|------------
  label1   |   DUMMY  |   1   |  5	|      1	 |      0	  |      1	   |      0
  label2   |   DUMMY  |   1   |  3	|      1	 |      1	  |      0	   |      0  
  label2   |   DUMMY  |   5   |  5	|      1	 |      1 	  |      0	   |      0
  label2   |   DUMMY  |   8   |  10	|      1	 |      1 	  |      0	   |      0
  label2   |   DUMMY  |   12  |  12	|      1	 |      1 	  |      0	   |      0
  label3   |   DUMMY  |   1   |  10	|      0	 |      1 	  |      1	   |      0
  label3   |   DUMMY  |   20  |HIGH |      0	 |      1	  |      1	   |      0
  label4   |   DUMMY  |   10  |  20	|      0	 |      0	  |      0	   |      1
  label5   |   DUMMY  |   10  |  12	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   15  |  17	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   19  |  20	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   30  |HIGH	|      0	 |      1	  |      1	   |      0

Run macro `%%_example_ds_select` for examples.

### Notes
All character or numeric variables having missing values for alll observation in teh dataset will be removed.

### References

### See also
*/ /** \cond */

/* credits: grillma */

%macro var_missing_remove(idsn	/* Input dataset 														(REQ) */
				, odsn 			/* Output dataset 														(REQ) */ 
				, len           /* length of macro variable                                             (OPT) */
			   	, ilib=			/* Name of the input library 											(OPT) */
				, olib=			/* Name of the output library 											(OPT) */
				);

	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* IDSN/ILIB: check/set */


	%if %error_handle(ErrorInputDataset, 
		%macro_isblank(idsn), mac=&_mac,		
		txt=!!! no input dataset passed !!!) %then
       	%goto exit;

    %if %macro_isblank(ilib)	%then 	%let ilib=WORK;
	%if %error_handle(ErrorInputDataset, 
		%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
		txt=!!! input dataset %upcase(&idsn) not found !!!) %then
       	%goto exit;

	/* LEN/ODSB/OLIB: check/set */
	%if %macro_isblank(len)   %then 	%let len=1400;
	%if %macro_isblank(olib)   %then 	%let olib=WORK;
	%if %macro_isblank(odsn)   %then 	%let odsn=TMP%upcase(&sysmacroname);;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local i	    /* increment counter                       */
		 ;

	/*data missing ;set _TMPSILC_DEV_VAR_INFO;run;*/
	*options symbolgen;

	/* Create two macro variables, NUM_QTY and CHAR_QTY, to hold */
	/* the number of numeric and character variables, respectively. */
	/* These will be used to define the number of elements in the arrays */
	/* in the next DATA step. */
	data _null_;
   		set &ilib..&idsn(obs=1);
   		array num_vars[*] _NUMERIC_;
  		array char_vars[*] _CHARACTER_;
   		call symputx('num_qty', dim(num_vars));
   		call symputx('char_qty', dim(char_vars));
	run;
	
	data _null_ ;
   		set &ilib..&idsn end=finished;

   	/* Use the reserved word _NUMERIC_ to load all numeric variables  */
    /* into the NUM_VARS array.  Use the reserved word _CHARACTER_ to */ 
   	/* to load all character variables into the CHAR_VARS array.      */
   	    array num_vars[*] _NUMERIC_;
   	    array char_vars[*] _CHARACTER_;

   	/* Create 'flag' arrays for the variables in NUM_VARS and CHAR_VARS. */
   	/* Initialize their values to 'missing'.  Values initialized in an   */
   	/* ARRAY statement are retained.                                     */
    	array num_miss [&num_qty] $ (&num_qty * 'missing');
    	array char_miss [&char_qty] $ (&char_qty * 'missing'); 
  
   	/* LIST will contain the list of variables to be dropped. */
   	/* Ensure that its length is sufficient. */
   	    length list $ &len;       /*max value is 32767*/
    /* Check for non-missing values.  Reassign the corresponding 'flag' */
   	/* value accordingly.                                               */
   		do i=1 to dim(num_vars);
       		if num_vars(i) ne . then num_miss(i)='non-miss';
		end;
    	do i=1 to dim(char_vars);
       		if compress(char_vars(i),'','s') ne '' then char_miss(i)='non-miss';
   		end;

    /* On the last observation of the data set, if a 'flag' value is still */
    /* 'missing', the variable needs to be dropped.  Concatenate the       */
    /* variable's name onto LIST to build the values of a DROP statement   */
    /* to be executed in another step.                                     */
   		if finished then do;
      		do i= 1 to dim(num_vars);
         		if num_miss(i) = 'missing' then list=trim(list)||' '||trim(vname(num_vars(i)));
      		end;
      		do i= 1 to dim(char_vars);
         		if char_miss(i) = 'missing' then list=trim(list)||' '||trim(vname(char_vars(i)));
	  		end;
      		call symput('mlist',list);
   		end;
 
	run;
	/* Use the macro variable MLIST in the DROP statement.  PROC DATASETS can */
	/* be used to drop the variables instead of a DATA step.                  */
	data &olib..&odsn;
   		set &ilib..&idsn;
	  		drop &mlist;
	run;

	proc print;
	run;

	%exit:
%mend var_missing_remove;

%macro _example_var_missing_remove;
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

	%local list_1 /* variables list in input  (&idsn)  file */
		 list_2   /* variables list in output (&odsn)  file */
		 ans      /* answer to the test */
			;
	%put;
    %put (i) input dataset does not exist ;
	%let idsn=;
    %var_missing_remove(&idsn);
    %put;
    %put (ii)  Two variables have to be removed ;
    %_dstest22;
	%let idsn=_dstest22;
	%let odsn=TMP;
	%ds_contents(&idsn, _varlst_=list_1, varnum=yes); 
  	%var_missing_remove(&idsn, &odsn);
 
	%ds_contents(&odsn, _varlst_=list_2, varnum=yes);
	%let ans=%list_compare(&list_1, &list_2);
    %put (ii) Compare lists list1=&list_1 and list2=&list_2 two variable have been removed ;
	%if %list_compare(&list_1, &list_2)=1 %then 	%put OK: TEST PASSED - list1>list2: result 1;
	%else 											%put ERROR: TEST FAILED - list1<list2: wrong result; 

	%work_clean(_dstest22,TMP);

	%exit:
%mend _example_var_missing_remove;
 
/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_missing_remove; 
*/

/** \endcond */
