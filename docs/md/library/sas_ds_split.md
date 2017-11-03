## ds_split {#sas_ds_split}

~~~sas
	%ds_split(idsn, var=, num=, oname=, _odsn_=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : ; 
* `var` : (_option_);
* `num` : (_option_);
* `oname` : (_option_);
* `ilib` : (_option_).

### Returns
* `_odsn_` : (_option_);
* `olib` : (_option_).

### References
1. Gerlach, J.R. and Misra, S. (2002): ["Splitting a large SAS dataset"](http://www2.sas.com/proceedings/sugi27/p083-27.pdf).
2. Williams, C.S. (2008): ["PROC SQL for DATA step die-hards"](http://www2.sas.com/proceedings/forum2008/185-2008.pdf).
3. Hemedinger, C. (2012): ["How to split one data set into many"](http://blogs.sas.com/content/sasdummy/2015/01/26/how-to-split-one-data-set-into-many/).
4. Sempel, H. (2012): ["Splitting datasets on unique values: A macro that does it all"](http://support.sas.com/resources/papers/proceedings12/069-2012.pdf).
5. Ross, B. and Bennett, J. (2016): ["PROC SQL for SQL die-hards"](http://support.sas.com/resources/papers/proceedings16/7540-2016.pdf). 

### See also
[%ds_select](@ref sas_ds_select).
