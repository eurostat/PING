## express_comparison {#sas_list_map}
Calculate the transform of a list given by a mapping table (similarly to a LookUp Transform, LUT).

~~~sas
	express_comparison(arg, _exp_=, force_sql=NO);
~~~

Cassell, L.D. (2005): [*PRX functions and Call routines*](http://www2.sas.com/proceedings/sugi30/138-30.pdf).

comparison operators:
* http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#a000780367.htm
* note:
* Symbols => and <= are accepted for compatibility with previous releases of SAS, but they are not
* supported in WHERE clauses or in PROC SQL
