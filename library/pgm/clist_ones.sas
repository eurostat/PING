/** 
## clist_ones {#sas_clist_ones}
Create a simple list of replicated items with given length.

~~~sas
	%let clist=%clist_ones(len, item=, sep=%str(,), mark=%str(%"));
~~~

### Arguments
* `len` : desired length of the output list;
* `item` : (_option_) item to replicate in the list; default: `item=1`, _i.e._ the list 
	will be composed of 1 only;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details.
 
### Returns
`list` : output list where `item` is replicated and concatenated `len` times.

### Examples
Simple examples like:

~~~sas
	%let res1= %clist_ones(5);
	%let res2= %clist_ones(3, a);
~~~
return `res1=("1","1","1","1","1")` and `res2=("a","a","a")` respectively, while it is also possible:

~~~sas
	%let x=1 2 3;
	%let res1=%clist_ones(5, item=&x);
~~~
returns `res1=("1","2","3","1","2","3","1","2","3","1","2","3","1","2","3")`.

Run macro `%%_example_clist_ones` for more examples.

### Note
The macro will not return exactly what you want if the symbol $ appears somewhere in the list.

### See also
[%list_ones](@ref sas_list_ones), [%list_append](@ref sas_list_append), [%list_index](@ref sas_list_index).
*/ /** \cond */

/* credits: grazzja, grillma */

%macro clist_ones(len 	/* Lenght of output list 								(REQ) */
				, item= /* Element to replicate in output list 					(OPT) */ 
				, mark=	/* Character/string used to quote items in input lists 	(OPT) */
				, sep=	/* Character/string used as list separator 				(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
 	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local REP;	/* intermediary replacement of list separator */

	/* MARK, SEP: default settings */
	%if %macro_isblank(mark) %then 							%let mark=%str(%"); /* mark */
	%else %if &mark EQ _EMPTY_ or &mark EQ _empty_ %then 	%let mark=%quote(); 
	%if %macro_isblank(sep) %then 							%let sep=%quote(,);  /* clist separator */
	/* note that all types of checkings are already performed in clist_unquote/list_slice */
	
	/* REP: setting */
	%if %symexist(G_PING_UNLIKELY_CHAR) %then 		%let REP=%quote(&G_PING_UNLIKELY_CHAR);
	%else											%let REP=$;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* 2. form the desired list of characters using %list_quote */
	(%list_quote(
		/* 1. compute the actual ones-like list */
			%list_ones(&len, item=&item, sep=&REP), 
		sep=&REP, rep=&sep, mark=&mark)) /*Lisp-like implementation :) */
	
%mend clist_ones;

%macro _example_clist_ones;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Crash test;
	%if %macro_isblank(%clist_ones(0)) %then	%put OK: TEST PASSED - Empty list returned;
	%else 										%put ERROR: TEST FAILED - Non empty list returned;

	%put;
	%let item=nessuno;
	%let len=1;
	%put (ii) Initialise a list of lenght &len with item &item;
	%if %clist_ones(&len, item=&item)=("&item") %then	%put OK: TEST PASSED - List of length 1 equal to the item;
	%else 											%put ERROR: TEST FAILED - Wrong list of length 1;

	%put;
	%let len=5;
	%put (iii) Define a default list of lenght &len;
	%let res=("1","1","1","1","1");
	%if %clist_ones(&len)=&res %then		%put OK: TEST PASSED - Default list of length &len: return &res;
	%else 								%put ERROR: TEST FAILED - Wrong default list of length &len returned;

	%put;
%mend _example_clist_ones;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_ones; 
*/

/** \endcond */
