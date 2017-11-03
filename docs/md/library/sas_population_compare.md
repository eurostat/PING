## population_compare {#sas_population_compare}
Compare the ratio of two populations (given as figures) with a given threshold.

~~~sas
	%population_compare(pop_den, pop_num, _pop_infl_=, _ans_=, pop_thres=0.7);
~~~

### Arguments
* `pop_den, pop_num` : two (string/numeric) variables, usually storing respectively 
	the global and partial population figures to compare;
* `pop_thres` : (_option_) value (in range [0,1]) of the threshold to test whether:
		`pop_num / pop_den >= pop_thres` ?
	default to 0.7 (_i.e._ we assume `pop_den > pop_num` and `pop_num` should be at 
	least 70% of `pop_den`).
 
### Returns
* `_pop_infl_` : name of the macro variables storing the 'inflation' rate between both 
	global and partial population, _i.e._ the ratio `pop_den / pop_num`;
* `_ans_` : name of the macro variables storing the result of the test whhether some 
	aggregates shall be computed or not, _i.e._ the result (`YES/NO`) of the test:
		`pop_num / pop_den >= pop_thres` ?

### Examples
_Alleluia!!!_
	
~~~sas
	%let pop_infl=;
	%let ans=;
	%population_compare(1, 0.1, _pop_infl_=pop_infl, _ans_=ans, pop_thres=0.2);
~~~
returns `pop_infl=10` and `ans=no`.

~~~sas
	%population_compare(1, 0.2, _pop_infl_=pop_infl, _ans_=ans, pop_thres=0.2);
~~~
returns `pop_infl=5` and `ans=yes` (note that we indeed test `>=`).

~~~sas
	%population_compare(1, 0.5, _pop_infl_=pop_infl, _ans_=ans, pop_thres=0.2);
~~~
returns `pop_infl=2` and `ans=yes`.

Run macro `%%_example_population_compare` for more examples.

### See also
[%ctry_population_compare](@ref sas_ctry_population_compare)
