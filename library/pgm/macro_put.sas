/**
## macro_put {#sas_macro_put}
Display text from inside a macro from level DEBUG>=2.

~~~sas
	%macro_put(macro, txt=, debug=);
~~~

### Example
Let us declare a dummy macro as:

~~~sas
	%macro dummy;
		%local _mac;
		%let _mac=&sysmacroname;
		%macro_put(&_mac, txt=A dummy text, debug=1);
	%mend;
~~~
then running the command:

~~~sas
	%dummy;
~~~

will display:

	--------------------------------------------------------------------------
	In macro DUMMY - A dummy text
	--------------------------------------------------------------------------

Run `%%_example_macro_put` for more examples.

### Notes
1. As stated, the macro `%%macro_put` shall be used inside another macro only.
2. Since this macro uses the macros `%%error_handle` and `%%macro_isblank`, these macros 
should not use any instance of `%%macro_put` so as to avoid recursion (like _"un espece 
de grand trou noir"_). 
*/

/* credits: gjacopo */

%macro macro_put(macro
				, debug=
				, txt=
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(macro) EQ 1, mac=&_mac,		
			txt=!!! Parameter MACRO not passed !!!) %then
		%goto exit;

	%if %macro_isblank(debug) %then %do;
		%if %symexist(G_PING_DEBUG) %then 	%let debug=&G_PING_DEBUG;
		%else 								%let debug=0;
	%end;
	
	/* just in case one did not actually get it... */
	%if %upcase("&debug")="YES" %then %let debug=1; 
	%else %if %upcase("&debug")="NO" %then %let debug=0; 

	%if &debug<=1 %then %goto exit; /* from level 2 on */

	%put;
	%put --------------------------------------------------------------------------;
	%if "&txt" ne "" %then 
		%put In macro &macro - &txt;
	%else	
		%put In macro &macro;
	%put --------------------------------------------------------------------------;
	%put;

	%exit:
%mend macro_put;


%macro _example_macro_put;
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

	%local olddebug;

	%put;
	%put (i) Test a dummy macro;
	%macro dummy;
		%macro_put;
	%mend;
	%dummy;

	%put;
	%put (ii) Test a simple macro forcing to put the macro name;
	%macro test1;
		%local _mac;
		%let _mac=&sysmacroname;
		%macro_put(&_mac, debug=1);
	%mend;
	%test1;
	
	%if %symexist(G_PING_DEBUG) %then 	%let olddebug=&G_PING_DEBUG;
	%else %do;
		%global G_PING_DEBUG;
		%let olddebug=0;
	%end;

	%put;
	%put (iii) Test a simple macro when G_PING_DEBUG variable is set to 1;
	%let G_PING_DEBUG=1;
	%macro test2;
		%local _mac;
		%let _mac=&sysmacroname;
		%macro_put(&_mac);
	%mend;
	%test2;

	%put;
	%put (iv) Ibid with G_PING_DEBUG variable set to 0 this time;
	%let G_PING_DEBUG=0;
	%macro test3;
		%local _mac;
		%let _mac=&sysmacroname;
		%macro_put(&_mac);
	%mend;
	%test3;

	%let G_PING_DEBUG=&olddebug;

	%put;

	%exit:
%mend _example_macro_put;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_macro_put; 
*/

/** \endcond */
