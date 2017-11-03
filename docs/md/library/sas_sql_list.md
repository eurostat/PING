## sql_list {#sas_sql_list}
Transform an unformatted list of items into a SQL-compatible list of comma-separated 
and/or quote-enhanced items. 

~~~sas
	%let sqllist = %sql_list(list, type=);
~~~

### Arguments
* `list` : a list of blank separated items/char;
* `type` : (_option_) flag set to force the type of the items in `list`; it is either 
	`NUMERIC` for items regarded as all numeric or `CHAR` for items regardard as 
	alphanumeric items; default (empty): the type will be determined (using `%datatyp`) 
	depending on the type of the first item.
 
### Returns
`sqllist` : output formatted list of comma-separated, quoted items, in between parentheses.

### Examples
The simple examples below:

~~~sas
	%let list1=DE AT BE NL UK SE;
	%let olist1=%sql_list(&list1);
	%let list2=1 2 3 4 5 6;
	%let olist2=%sql_list(&list2);
~~~
return `olist1=("DE","AT","BE","NL","UK","SE")` and `olist2=(1,2,3,4,5,6)` respectively, while:

~~~sas
	%let olist2p=%sql_list(&list2, type=CHAR);
~~~
return `olist2p=("1","2","3","4","5","6")`.

### Note
This is nothing else than a wrapper to [%list_quote](@ref sas_list_quote), where parentheses
`()` are added around the output list, _i.e._ the command `%let sqllist = %%sql_list(&list)` 
is equivalent to:

~~~sas
	%let sqllist = (%list_quote(&list, sep=%quote( ), rep=%quote(,), mark=%str(%")));
~~~
when `list` is of type `CHAR`, otherwise, when `list` if of type `NUMERIC`:

~~~sas
	%let sqllist = (%list_quote(&list, sep=%quote( ), rep=%quote(,), mark=_EMPTY_));
~~~

### See also
[%list_quote](@ref sas_list_quote).
