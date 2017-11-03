## ds_datetime {#sas_ds_datetime}
* Convert date and time (datetime) character variables from dataset or from macro variables in one integer variable.

~~~sas
	%let dt_integer=%ds_datetime_integer(vardate=,vartime=, _dt_integer_=);
~~~

* retrieve time (currentdate variable) and date (lastup variable) from a dsn or from macro variable. Cnvert them in one integer variable.

~~~sas
	%let dt_integer=%ds_datetime_integer(dsn=, _dt_integer_=, currentdate=currentdate, lastup=lastup,lib=WORK);
~~~

### Arguments
* `dsn` : a dataset reference;
* `vardate` : (_option_) variable dataset name for  time;
* `vartime` : (_option_) variable dataset name for  date.
* `currentdate` : (_option_) variable  time;
* `lastup` : (_option_) variable date.
 
### Returns
* `_dt_integer_` :  integer value , _i.e._:
   YYYYMMDDHHMMSS

### Examples
Two semple examples of use, namely: 
Using variables:

~~~sas
	%let vartime=12:52:24;
	%let vardate=09FEB17;	
	%ds_datetime_integer(vardate=&vardate,vartime=&vartime, _dt_integer_=);
~~~

returns: `dt_integer=20170209125224`.
 
Using  test dataset #41:

~~~sas
    %let dsn=_dstest41;
	%ds_datetime_integer(dsn=&dsn,_dt_integer_=, currentdate=currentdate, lastup=lastup,lib=);
~~~
	
returns: `dt_integer=YYYMMDDHHMMSS`	 

Run macro `%%_example_ds_datetime_integer` for more examples.
### Notes
Accepted formats for:
	     vartime is HH:MM:SS
         vardate is DDMMMYY
 
Examples: 
~~~sas
	%let vartime=12:52:24;
    %let vardate=09FEB17;
~~~

### See also
