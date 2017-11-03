## ano_var_btcode {#sas_ano_var_btcode}

~~~sas
%ano_var_btcode(geo, time, db, var, wgt, db_d=, vartype=, coding=T, nobs=10, lib=WORK);
~~~

### Examples
In the following, we consider the example of anonymisation applied in practice 
for `geo=SI`. The input datasets are the common `UDB` files whose extension states 
whether they contain `R`, `P`, `H` or `D` variables.
1. Variable top-coding: say for the highest 10 original values of the variable 
`PY031G`, you want to replace the original values with their weighted average. 
Run:

~~~sas
%ano_var_btcode(SI, UDB_P, PY031G, PB040, coding=TOP, vartype=P, nobs=10);
~~~
2. Combined variables top-coding: say you want to replace the values of `PY030G` 
variable for observations that are highest for either `PY030G` or the related 
variable `PY031G`, doing the following: 
	* selecting the 10 IDs with the highest values of variable `PY030G`;
	* selecting the 10 IDs with the highest values of related variable `PY031G`;
	* considering the union of selected IDs (at least 10 observations, not more 
	than 20),

then replacing the original values for observations in the union above with 
weighted average, you can then run the following:

~~~sas
%ano_var_btcode(SI, UDB_P, PY030G, PB040, coding=TOP, relvar=PY031G, nobs=10, vartype=P);
~~~
3. Gross/net variables top-coding: say you want to simultaneously replace the 
highest original values of gross/net variables HY040G/HY040N, doing the following: 
	* selecting the 10 IDs with the highest original values of gross variable 
	`HY040G`;
	* selecting the 10 IDs with the highest original value of net variable `HY040N`;
	* considering the union of selected IDs (at least 10 observations, not more 
	than 20);

then replacing the original values of both gross/net variables for observations 
in the union above with their respective weighted averages, you can then run the 
following:

~~~sas
%ano_var_btcode(SI, UDB_H, HY040G HY040N, DB090, coding=TOP, db_d=UDB_D, nobs=10, vartype=H);
~~~
