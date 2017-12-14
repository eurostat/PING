/* TODO ANO_DATE_RANGE
* Build basic equally-spaced (in number of years) sequences of dates 
*/

/* credits: gjacopo */

%macro ano_date_range(time	/* Date of the survey 						(REQ) */
					, nyears=	/* Maximum length of the designed range		(REQ) */
					, bin_step=	/* Length of the bins (class intervals)		(OPT) */
					, bin_ref=	/* Fixed/imposed bin						(REQ) */
					, order=	/* Order (ascending/descending) of the bins (OPT) */
					);
	%local __i __len 
		__bound __range
		__lower;

	%if &order= %then 					%let order=DESC;
	%else 								%let order=%upcase(&order);
	%if &bin_step= %then 				%let bin_step=5;
	%if &bin_ref= %then 			%let bin_ref=&time;

	%let __lower=%eval(&time - &nyears); 
	%let __range=&time;
	
	/* years after &bin_ref */
	%before_bin_ref:
	%if &time<=&bin_ref %then 	
		%goto after_bin_ref;
	%let __len= %sysevalf((&time - &bin_ref)/&bin_step, floor);
	%do __i=0 %to &__len;
		%let __bound=%sysevalf(&bin_ref + %eval(&__len-&__i) * &bin_step);
		%if &__bound>=&__lower %then
			%let __range=&__range &__bound;
	%end;

	/* years prior to &bin_ref */
	%after_bin_ref:
	%if %eval(&__lower>&bin_ref) %then 	
		%goto quit;
	%let __len= %sysevalf((&bin_ref - &__lower)/&bin_step + 1, floor);
	%do __i=1 %to %eval(&__len-1);
		%let __bound=%sysevalf(&bin_ref - &__i * &bin_step);
		%if &__bound>=&__lower %then
			%let __range=&__range &__bound;
	%end;

	%quit:
	%if %scan(&__range, %sysfunc(countw(&__range))) NE &__lower %then 
		%let __range=&__range &__lower;

	%if "&order"="ASC" %then %do;
		%local ___range;
		%let ___range=;
		%do __i=%sysfunc(countw(&__range)) %to 1 %by -1;
			%let ___range=&___range %scan(&__range, &__i);
		%end;
		%let __range=&___range;
	%end;

	&__range

%mend ano_date_range;

%macro _example_ano_date_range;
	%local olist rlist;

	%put;
	%let olist=2008 2010 2005 2000 1995 1990 1985 1980 1975 1970 1965 1960 1955 1950 1945 1942;
	%put (i) Test parameters BIN_REF=2015, NYEARS=66, BIN_STEP=5 with year=2008, prior to BIN_REF;
	%let rlist=%ano_date_range(2008, nyears=66, bin_ref=2015, bin_step=5);
	%if &rlist EQ &olist  %then 	%put OK: TEST PASSED - List &olist retrieved;
	%else 							%put ERROR: TEST FAILED - Wrong list retrieved: &rlist;

	%put;
	%let olist=2022 2020 2015 2010 2005 2000 1995 1990 1985 1980 1975 1970 1965 1960 1956;
	%put (ii) Test with same parameters and year=2022, after BIN_REF;
	%let rlist=%ano_date_range(2022, nyears=66, bin_ref=2015, bin_step=5);
	%if &rlist EQ &olist  %then 	%put OK: TEST PASSED - List &olist retrieved;
	%else 							%put ERROR: TEST FAILED - Wrong list retrieved: &rlist;

	%put;
	%let olist=2083 2080 2075 2070 2065 2060 2055 2050 2045 2040 2035 2030 2025 2020 2017;
	%put (iii) Test with same parameters and year=2083, after BIN_REF+NYEARS;
	%let rlist=%ano_date_range(2083, nyears=66, bin_ref=2015, bin_step=5);
	%if &rlist EQ &olist  %then  	%put OK: TEST PASSED - List &olist retrieved;
	%else 							%put ERROR: TEST FAILED - Wrong list retrieved: &rlist;

	%put;
	%let olist=2017 2020 2025 2030 2035 2040 2045 2050 2055 2060 2065 2070 2075 2080 2083;
	%put (iv) Test with same parameters and year=2083, after BIN_REF+NYEARS;
	%let rlist=%ano_date_range(2083, nyears=66, bin_ref=2015, bin_step=5, order=ASC);
	%if &rlist EQ &olist  %then 	%put OK: TEST PASSED - List &olist retrieved;
	%else 							%put ERROR: TEST FAILED - Wrong list retrieved: &rlist;

%mend _example_ano_date_range;
/*
%_example_ano_date_range; 
*/
