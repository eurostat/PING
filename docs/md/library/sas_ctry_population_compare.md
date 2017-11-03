## ctry_population_compare {#sas_ctry_population_compare}
Compare the population ratio of two list of countries for a given threshold.

~~~sas
	%ctry_population_compare(ctry_glob, ctry_part, time, _pop_infl_=, _ans_=, pop_thres=0.7, 
			cds_popxctry=META_POPULATIONxCOUNTRY, clib=LIBCFG);
~~~

### Arguments
* `ctry_glob, ctry_part` : two lists of (blank-separated) strings representing countries' ISO-codes; 
	in practice, countries listed in `ctry_part` are also `ctry_glob`;
* `time` : period of interest;
* `pop_thres` : (_option_) value (in range [0,1]) of the threshold to test whether:
		`pop_part / pop_glob >= pop_thres` ?	
	default to 0.7 (_i.e._ `pop_part` should be at least 70% of `pop_glob`); 
* `cds_popxctry, clib` : (_option_) respectively, name and library of the configuration file storing 
	the population of different countries; by default, these parameters are set to the values 
	`&G_PING_POPULATIONxCOUNTRY` and `&G_PING_LIBCFG`' (_e.g._, `META_POPULATIONxCOUNTRY` and `LIBCFG`
	resp.); see [%meta_populationxcountry](@ref meta_populationxcountry)	for further description.

### Returns
* `_pop_infl_` : name of the macro variables storing the 'inflation' rate between both global and
	partial population, _i.e._ the ratio `pop_glob / pop_part`;
* `_ans_` : name of the macro variables storing the result of the test whether some aggregates
	shall be computed or not, _i.e._ the result (`yes/no`) of the test:
		`pop_part / pop_glob >= pop_thres` ?

### Examples
Let us consider a large country (DE) and a small one (MT). For the area (DE,MT) and year 2010, we 
assume that only DE is available. 
Then, will a threshold of 90% of the population be reached? Considering the actual
figures (found in the `cds_popxctry` table: population of DE is: 81.802.257, that of MT is: 10.014.324) 
it seems obvious that this is actually reached. Let's check:

~~~sas
	%let ans=;
	%let pop_infl=;
	%let year=2010;
	%let thres=0.9; 	*our 90% threshold to check;
	%let ctry_part=DE;
	%let ctry_glob=DE MT;
	%ctry_population_compare(&ctry_glob, &ctry_part, &year, pop_thres=&thres, _pop_infl_=pop_infl, _ans_=ans);
~~~
returns indeed the answer `ans=yes` (and `pop_infl=1.0050613151`). Instead, let's consider another large 
country, say FR (whose population in 2010 amounts to 64.658.856):

~~~sas
	%let ctry_glob=DE FR;  *other variables unchanged;
	%ctry_population_compare(&ctry_glob, &ctry_part, &year, pop_thres=&thres, _pop_infl_=pop_infl, _ans_=ans);
~~~
returns the answer `ans=no` (and `pop_infl=1.7904151471`).

Run macro `%%_example_ctry_population_compare` for more examples.

### Note
The table `cds_popxctry` contains for each country in the EU+EFTA geographic area the total population
for any year from 2003 on (_e.g._, what used to be `CCWGH60`). 

### See also
[%ctry_population](@ref sas_ctry_population), [%zone_population](@ref sas_zone_population), 
[%population_compare](@ref sas_population_compare), [%meta_populationxcountry](@ref meta_populationxcountry).
