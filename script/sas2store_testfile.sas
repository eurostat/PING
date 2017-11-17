/** 
## sas2store_testfile {#sas_sas2store_testfile}
File to be used for testing of the script `sas2store.sh`.
This is another dummy line for description.

~~~
	fake syntax, not part of the description
~~~

### Arguments
Nothing relevant.
 
### Returns
The script `sas2store.sh` will be run with this file so as to actually check that
the macros declared herein are all transformed into store-able macros.
 
### Example
None.

### Note
None. 
*/ /** \cond */
	
%put +++++++++++++++++++++++++++++++++++++;
%put Basic macro a, named like the file: / store should be added, as well as desc in case the option is selected;
%macro sas2store_testfile(dumb, dumber);
	%put &dumb &dumber;
%mend sas2store_testfile;

%put +++++++++++++++++++++++++++++++++++++;
%put Ibid basic macro b, declaration on multiple lines: / store should be added, as well as desc in case the option is selected;
%macro sas2store_testfile(dumb
						, dumber
						)
						;
	%put &dumb &dumber;
%mend sas2store_testfile;


%put +++++++++++++++++++++++++++++++++++++;
%put Basic macro example:  / store should be added, as well as desc Example in case the option is selected;
%macro _example_sas2store_testfile; 
	%sas2store_testfile(1, 2); 
%mend _example_sas2store_testfile;

	
%put +++++++++++++++++++++++++++++++++++++;
%put Basic macro #1, comments, commas and nesting: / store should be added;
%macro sas2store_testfile1(dumb 	/* some comments	(REQ) */
						, dumber=	/* More comments	(OPT) */
				);
	
	; ; ; /* many commas: anything wrong? */

	%macro nested_weird(thedumb); /* some nested macro: anything going wrong? */
		%put &thedumb;
	%mend ;

	%nested_weird(&dumb);
	%nested_weird(&dumber);
%mend;

/*** dummy comments 
*/

%put +++++++++++++++++++++++++++++++++++++;
%put Basic macro #2, keyword occurence: / store should be added;
%macro _example_sas2store_testfile2 (dumb, dumber=);
 	%macro_weird(&dumb, &dumber); /* some macro starting with macro keyword: anything going wrong? */
	%mend_weird(&dumb, &dumber) /* some macro starting with mend keyword: anything going wrong? */
	
	%put &dumb &dumber;
%mend _example_sas2store_testfile2;

%put - Are we really dumb?;
	
%put +++++++++++++++++++++++++++++++++++++;
%put Basic macro #3, nultiple nesting: / store should be added;
%macro sas2store_testfile3(dumb, dumber=);
	%macro nested_weird(thedumb); /* some nested macro: anything going wrong? */
		%macro super_nested_weird(thedumb); /* multiple nested macros: anything going wrong? */
			%put &thedumb;
		%mend;
		%super_nested_weird(&thedumb);
	%mend;

	%nested_weird(&dumb);
	%nested_weird(&dumber);
%mend;
	
	
%put - Or maybe just dumber?;
	
%put +++++++++++++++++++++++++++++++++++++;
%put Basic macro #4a, no arguments: / store should be added;
%macro sas2store_testfile4a; 
	%put &dumb &dumber; 
%mend      ;

%put Basic macro #4b, on-line declaration: anything going wrong?;
%macro sas2store_testfile4b(dumb, dumber=); %put &dumb &dumber; %mend sas2store_testfile3;
	
%put - Actually, we are not sure, still let us skip some line here;
	 
	 
	
	
%put +++++++++++++++++++++++++++++++++++++;
%put Basic macro #5, weird indentation: / store should be added;
%macro 
sas2store_testfile5
	(
dumb
		, dumber=
		)
; 
%put &dumb &dumber
; 

%mend 

sas2store_testfile5;

%put +++++++++++++++++++++++++++++++++++++;
%put Basic #6a, already store-able: nothing should be added, it is already here;
%macro _example_sas2store_testfile6a (dumb, dumber=) / store;
 	%macro_weird(&dumb, &dumber); /* some macro starting with macro keyword: anything going wrong? */
	%mend_weird(&dumb, &dumber) /* some macro starting with mend keyword: anything going wrong? */
	
	%put &dumb &dumber;
%mend _example_sas2store_testfile6a;

%put +++++++++++++++++++++++++++++++++++++;
%put Ibid basic #6b, comma on different line: nothing should be added, it is already here;
%macro _example_sas2store_testfile6b (dumb, dumber=) / store
	;	
	%put &dumb &dumber;
%mend _example_sas2store_testfile6b;

%put +++++++++++++++++++++++++++++++++++++;
%put Ibid basic #6c, comma on different line: nothing should be added, it is already here;
%put !!! This one will fail however !!!;
%macro _example_sas2store_testfile6c (dumb, dumber=) / 
	store;	
	%put &dumb &dumber;
%mend _example_sas2store_testfile6c;

/** \endcond */
