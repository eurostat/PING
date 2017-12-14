/** 
## list_difference {#sas_list_difference}
Calculate the (asymmetric) difference between two unformatted lists of char.

~~~sas
	%let diff=%list_difference(list1, list2, casense=no, sep=%quote( ));
~~~

### Arguments
* `list1, list2` : two lists of unformatted strings;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case elements in both lists need to differ;
* `sep` : (_option_) character/string used as a separator in the input lists; default: `sep=%%quote( )`, 
	_i.e._ the input `list1` and `list2` are both blank-separated lists of items.
 
### Returns
`diff` : output concatenated list of characters, namely the list of strings obtained as the asymmetric 
	difference: `list1 - list2`.

### Examples

~~~sas
	%let list1=A B C D E F;
	%let list2=A B C;
	%let diff=%list_difference(&list1, &list2);
~~~	
returns: `diff=D E F`, while:

~~~sas
	%let diff=%list_difference(&list2, &list1);
~~~	
returns: `diff=`.
 
Run macro `%%_example_list_difference` for more examples.

### Notes
1. This is a setwise operation to be understood as `list1 \ list2`.
2. Items are matched exactly since the macro `FINDW` is used. 

### See also
[%list_intersection](@ref sas_list_intersection), [%clist_difference](@ref sas_clist_difference), 
[%list_compare](@ref sas_list_compare), [%list_append](@ref sas_list_append), 
[%list_find](@ref sas_list_find), 
[FINDW](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002978282.htm).
*/ /** \cond */

/* credits: gjacopo */

%macro list_difference(list1, list2	/* Lists of blank-separated items 							(REQ) */
					, casense=		/* Boolean flag set for case sensitive comparison 			(OPT) */
					, sep=			/* Character/string used as string separator in input list	(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* set default output to empty */
	%local _diff;	/* output list */
	%let _diff=;

	/* CASENSE: set default/update parameter */
	%if %macro_isblank(casense)  %then 	%let casense=NO; 
	%else								%let casense=%upcase(&casense);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&casense, type=CHAR, set=YES NO) NE 0, mac=&_mac,	
			txt=!!! Parameter CASENSE is boolean flag with values in (yes/no) !!!) %then
		%goto exit;

	/* SEP: set default */
	%if %macro_isblank(sep) %then 	%let sep=%quote( );  /* list separator */

	/************************************************************************************/
	/**                                  actual operation                              **/
	/************************************************************************************/

	%local _i	/* increment counter */
		_list1
		item1
		_item1;	/* temporary element used for comparison */

	/* upcase the strings to look for/to when requested */
	%if "&casense"="NO" %then %do;
		%let _list1=%upcase(&list1); /* note that we preserve list1 as is */
		%let list2=%upcase(&list2);
	%end;

	/* deal with simple cases */
	%if %macro_isblank(list1) or %list_compare(&_list1, &list2, sep=&sep)=0 %then %do;
		%goto exit;
	%end;
	%else %if %macro_isblank(list2) %then %do;
		%let _diff=&list1;
		%goto exit;
	%end;

	/* calculate the actual difference, i.e. the set of items of list1
	 * which are not present in list2 */
	%do _i=1 %to %list_length(&list1, sep=&sep);
		%let item1=%scan(&list1, &_i, &sep);
		%let _item1=%scan(&_list1, &_i, &sep);
		%if &sep= %then %let _pos=%sysfunc(findw(&list2, &_item1));
		%else 			%let _pos=%sysfunc(findw(&list2, &_item1, &sep));
		/* we use the macro FINDW for an exact match */
		%if &_pos <= 0 %then %do; /* item1 has not been found */
			%if %macro_isblank(_diff) %then 	%let _diff=&item1; /* the item is inserted as it appears in list1 */
			%else 								%let _diff=&_diff.&sep.&item1;
		%end;
	%end;

	%exit:
	&_diff
%mend list_difference;


%macro _example_list_difference;
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
	
	%local list1 list2 rlist olist olist2;

	%let list1=DE AT BE NL UK SE;
	%let list2 =;
	%put;
	%put (i) Test the difference "list1-list2" with an empty list list2 ...;
	%let rlist=%list_difference(&list1, &list2);
	%if &rlist EQ &list1 %then 		%put OK: TEST PASSED - Difference with empty list returns: list=&list1;
	%else 							%put ERROR: TEST FAILED - Wrong difference "list1 - list2" returned: &rlist;

	%put;
	%put (ii) Test the difference "list2-list1" with an empty list list2 ...;
	%let olist=();
	%let rlist=%list_difference(&list2, &list1);
	%if &rlist EQ &olist %then 		%put OK: TEST PASSED - Difference from empty list returns: empty list;
	%else 							%put ERROR: TEST FAILED - Wrong difference "list2 - list1" returned: &rlist;

	%let list2=AT BE NL;
	%put;
	%put (iii) Test the difference "list1-list2" with list1=&list1 and list2=&list2 ...;
	%let olist2=DE UK SE;
	%let rlist=%list_difference(&list1, &list2);
	%if &rlist EQ  &olist2 %then 	%put OK: TEST PASSED - "list1 - list2" returns: &olist2;
	%else 							%put ERROR: TEST FAILED - Wrong difference "list1 - list2" returned: &rlist;

	%put;
	%put (iv) Test then the asymetric difference "list2 - list1"...;
	%let olist=();
	%let rlist=%list_difference(&list2, &list1);
	%if &rlist EQ  &olist %then 	%put OK: TEST PASSED - "list2 - list1" returns: &olist;
	%else 							%put ERROR: TEST FAILED - Wrong difference "list2 - list1" returned: &rlist;

	%let list1 =AT BE NL;
	%let list2=NL BE AT;
	%put;
	%put (v) Test the difference "list1-list2" with list1=&list1 and list2=&list2 ...;  
	%let rlist=%list_difference(&list1, &list2);
	%if &rlist EQ  &olist %then 	%put OK: TEST PASSED - "list1 - list2" returns: &olist;
	%else 							%put ERROR: TEST FAILED - Wrong difference "list1 - list2" returned: &rlist;

	%put;
	%let list1 =AT BE dNL;
	%let list2=NL BE AT12;
	%put (vi) Test the difference "list1-list2" with list1=&list1 and list2=&list2 ...; /* to verify */
	%let olist=AT dNL;
	%let rlist=%list_difference(&list1, &list2);
	%if &rlist EQ &olist %then 		%put OK: TEST PASSED - "list1 - list2" returns: &olist;
	%else 							%put ERROR: TEST FAILED - Wrong difference "list1 - list2" returned: &rlist;

	%put;

	%exit:
%mend _example_list_difference;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_difference; 
*/

/** \endcond */
