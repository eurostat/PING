/** 
## list_append {#sas_list_append}
Append (_i.e._, concatenate) a unformatted (char or numeric) list to another, possibly 
interleaving the elements in the lists.

~~~sas
	%let conc=%list_append(list1, list2, zip=no, longest=no, sep=%quote( ), rep=%quote( ));
~~~

### Arguments
* `list1, list2` : two lists of unformatted of numeric/strings;
* `zip` : (_option_) a boolean flag (`yes/no`) or a character separator set to interleave the 
	lists; when `zip=yes`, the i-th element from each of the lists are appended together and 
	put into the 2*i-1 element of the output list; the returned list is truncated in length to 
	the length of the shortest list; similarly, when `zip` is set to a special character, the 
	lists are interleaved as before and this character is used as a separator between the zipped 
	elements; when `zip=_EMPTY_`, items are zipped without separation, while when `zip=_BLANK_`, 
	they are zipped with a blank space; default: `zip=no`, _i.e._ lists are simply appended;
* `longest` : (_option_) a boolean flag (`yes/no`) used when `zip^=NO`; it is set to `yes` when
	the lists are uneven and the zipping (concatenation) shall be operated until the longest list
	is exhausted; in that case, the last item of the shortest list is used in the concatenation
	(see example below); default: `longest=no`;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`;
* `rep` : (_option_) replacement character/string separator in outptu list; default: `rep=&sep`;

### Returns
`conc` : output concatenated list of characters, _i.e._ the list obtained as the union or 
	concatenation of the input lists `list1` and `list2`, which is of the form:
	+  `a11&zip.a21&sep.a12&zip.a22&sep...` when `zip` is not a boolean flag, 
	+`a11 a21&sep.a12 a22&sep...` otherwise, where `a1i` is the `i`-th element of the `list1`, ibid
	for `a2j`;

### Examples

~~~sas
	%let list1=A B C D E;
	%let list2=F G H I J; 
	%let conc=%list_append(&list1, &list2); 
~~~	
returns: `conc=A B C D E F G H I J`. 

~~~sas
	%let list0=1 2 3;
	%let conc=%list_append(&list0, &list1, zip=yes);
~~~	
returns: `conc=1 A 2 B 3 C`, while: 

~~~sas
	%let list0=1 2 3;
	%let conc=%list_append(&list0, &list1, zip=yes, longest=yes);
~~~	
returns: `conc=1 A 2 B 3 C 3 D 3 E`, and: 

~~~sas
	%let conc=%list_append(&list0, &list1, zip=%str(-));
~~~	
returns: `conc=1 - A 2 - B 3 - C`, and: 

~~~sas
	%let conc=%list_append(&list0, &list1, zip=yes, rep=%str(, ));
~~~
returns: `conc=1 A, 2 B, 3 C`. 

Run macro `%%_example_list_append` for more examples.

### See also
[%clist_append](@ref sas_clist_append), [%clist_difference](@ref sas_clist_difference).
*/ /** \cond */

/* credits: grazzja */

%macro list_append(list1, list2	/* Lists of blank-separated items 							(REQ) */
				, zip=			/* Boolean flag used to interleave the lists 				(OPT) */
				, sep=			/* Character/string used as string separator in input lists	(OPT) */
				, rep=			/* Replacement character/string								(OPT) */
				, longest=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* set default output to empty */
	%local _list; 
	%let _list=;

	/* SEP/REP: check/set */
	%if %macro_isblank(sep) %then 			%let sep=%quote( ); /* list separator */
	%if %macro_isblank(rep) %then 			%let rep=&sep; 
	%else %if &rep=_EMPTY_ %then 			%let rep=%quote( ); 

	/* ZIP: set default/update parameter */
	%if %macro_isblank(zip)  %then 			%let zip=NO; 
	%else									%let zip=%upcase(&zip);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&zip, type=CHAR) NE 0, mac=&_mac,	
			txt=!!! Parameter ZIP is a CHAR parameter !!!) %then
		%goto exit; 

	/* LONGEST: set default/update parameter */
	%if %macro_isblank(longest)  %then 			%let longest=NO; 
	%else										%let longest=%upcase(&longest);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&longest, type=CHAR, set=YES NO) NE 0, mac=&_mac,	
			txt=!!! Parameter LONGEST is boolean flag with values in (yes/no) !!!) %then
		%goto exit; 

	%if %error_handle(WarningInputParameter, 
			"&zip" EQ "NO" and "&longest" EQ "YES", mac=&_mac,	
			txt=! Parameter LONGEST=YES ignored when ZIP=NO !, verb=warn) %then
		%goto warning; 
	%warning:
	
	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%if "&zip"="NO" %then %do;
		/* simply append */
		%let _list=&list1.&sep.&list2;
	%end;

	%else %do;
		%local _len1 _len2
			_len 
			_i;
		%if "&zip"="_EMPTY_" %then 			%let zip=%quote();
		%else %if "&zip"="_BLANK_" %then 	%let zip=%quote( );
		%else %if "&zip"="YES" %then 		%let zip=&sep;
		%let _len1=%list_length(&list1, sep=&sep);
		%let _len2=%list_length(&list2, sep=&sep);

		%if "&longest"="NO" %then %do; /* take the min */
			%if &_len1>&_len2 %then 	%let _len=&_len2;
			%else						%let _len=&_len1;
		%end;
		%else %do; /* take the max */
			%if &_len1>&_len2 %then 	%let _len=&_len1;
			%else						%let _len=&_len2;
		%end;
		
		/* initialise */
		%let _item1=%scan(&list1, 1, &sep);
		%let _item2=%scan(&list2, 1, &sep);
		%let _list=&_item1.&zip.&_item2;
		%let _i=1;
		/* loop over the min/max lenght */
		%do _i=2 %to &_len;
			/*%if "&longest"="NO" and &_i>&_len1 %then %goto break;*/
			%if &_i<=&_len1 %then 	%let _item1=%scan(&list1, &_i, &sep);
			%if &_i<=&_len2 %then 	%let _item2=%scan(&list2, &_i, &sep);
			%let _list=&_list.&rep.&_item1.&zip.&_item2;
		%end;
	%end;

	/* then transform back into the desired format */
	%let _list=%sysfunc(trim(&_list));

	%exit:
	&_list
%mend list_append;

%macro _example_list_append;
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

	%local list1 list2 olist1 olist2;

	%let list1=A B C D E F;	
	%let list2=G H I J K L M N O;	

	%put;
	%put (i) Append lists list1=&list1 and list2=&list2 ...; 
	%let olist=A B C D E F G H I J K L M N O;
	%put %list_append(&list1, &list2);
	%if %list_append(&list1, &list2) EQ %quote(&olist) 	%then 	%put OK: TEST PASSED - Appended "list1 + list2" returns: &olist;
	%else 															%put ERROR: TEST FAILED - Wrong concatenated list "list1 + list2" returned;

	%put;
	%put (ii) Append lists list1=&list1 and list2=&list2 ...; 
	%let olist=G H I J K L M N O A B C D E F;
	%if %list_append(&list2, &list1) EQ %quote(&olist) %then 	%put OK: TEST PASSED - Appended "list2 + list1" returns: &olist;
	%else 														%put ERROR: TEST FAILED - Wrong concatenated list "list2 + list1" returned;

	%let list1=1 2 3 4;	
	%put;
	%put (iii) Zip (append and interleave) lists list1=&list1 and list2=&list2 ...; 
	%let olist=1 G 2 H 3 I 4 J;
	%if %list_append(&list1, &list2, zip=yes) EQ %quote(&olist) 	%then 	
		%put OK: TEST PASSED - Zipped "list1 + list2" returns: &olist;
	%else 															
		%put ERROR: TEST FAILED - Wrong concatenated list "list1 + list2" returned;

	%put;
	%put (iv) Ibid using the option longest=yes ...; 
	%let olist=1 G 2 H 3 I 4 J 4 K 4 L 4 M 4 N 4 O;
	%if %quote(%list_append(&list1, &list2, zip=yes, longest=yes)) EQ %quote(&olist) 	%then 	
		%put OK: TEST PASSED - Zipped "list1 + list2" returns: &olist;
	%else 															
		%put ERROR: TEST FAILED - Wrong concatenated list "list1 + list2" returned;

	%let start=1 1 5 8  12 1  20   19 19 15 19 30;	
	%let end=  5 3 5 10 12 10 HIGH 20 12 17 20 HIGH;	
	%let zip=%str(-);
	%put;
	%put (v) Zip (append and interleave) lists start=&start and end=&end with the special character "&zip" ...; 
	%let olist=1-5 1-3 5-5 8-10 12-12 1-10 20-HIGH 19-20 19-12 15-17 19-20 30-HIGH;
	%if %quote(%list_append(&start, &end, zip=&zip)) EQ %quote(&olist) 	%then 	
		%put OK: TEST PASSED - Zipped "start + end" returns: &olist;
	%else 															
		%put ERROR: TEST FAILED - Wrong concatenated list "start + end" returned;

	%put;

	%exit:
%mend _example_list_append;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_append; 
*/

/** \endcond */
