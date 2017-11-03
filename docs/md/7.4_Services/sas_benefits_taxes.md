## benefits_taxes {#sas_benefits_taxes}
Compute the per-capita benefits and taxes (benefits/allowances; taxes and social security contributions) for given 
geographical area(s) and period(s). 

~~~sas
	%benefits_taxes(geo, year, varaddh=, varaddp=,vartaxes= ,breakdowns1=, breakdowns2=, weight=, 
		type=G, yes_or_not=YES, odsn=Benefits_Taxes_YES, olib=WORK);
~~~

### Arguments
* `geo`  : a list of countries or a geographical area; default: `geo=EU28`; 
* `year` : year of interest;
* `varaddh` : (_option_) list of  social benefits, at household level; default: `varaddh` is empty;
              The fiscal aggregate is attributed to each family  member proportionally to their gross total personal income
* `varaddp` : (_option_) list of social benefits, at personal level;default: `varaddp` is empty; 
* `vartaxes`: (_option_) list of tax/income;default: `vartaxes` is empty; 
* `breakdowns1`:(_option_) list of tax and contribution component;
* `breakdowns2`:(_option_) list of breakdowns variable: default: age and sex.
* `weight` : (_option_) personal weight variable used to weighting the distribution; default:
			`weight=RES_WGT`;
* `type`   : (_option_) flag set to 'N' or 'G' to consider net and gross values respectively;
			default: `type=G`;
* `yes_or_not`:(_option_) flag set to 'YES' or 'NOT' to consider ZERO and NOT ZERO values for benefits/taxes 
				variables respectively;
* `odsn`   : (_option_) generic name of the output datasets; default: `odsn=Ben_taxes`;
* `olib`   : (_option_) name of the output library; by default, when not set, `olib=WORK`;

### Returns
* `odsn` : (_option_) name of the output datasets; default: `odsn=Ben_taxes.&zero`;
* `olib` : (_option_) name of the output library; by default, when not set, `olib=WORK`;

### Example
Let us consider the following configuration parameters:
~~~sas
	%let year=2015;
	%let geo=AT;
	%let type=G;     	* gross values: this is default by the way;
	%let varaddh=HY050 HY060 HY070;
	%let varaddp=PY090G PY100G PY110G PY120G PY130G PY140G;
	%let vartaxes=HY040 HY080 HY090 HY110  PY010 PY021 PY050 PY080;
	%let breakdowns1=HY050 ;
	%let breakdowns2=AGE SEX;
	%let yes_or_not=NOT;  * then %let zero=YES the zero values are included;
	%let weight=RES_WGT ;  * this is the default;
	%let odsn=Ben_taxes.NotZero;
	%let olib=WORK;
~~~

we implicitely compute the Benefits and taxes, normally expressed as:
~~~sas
	%let var=HY050;
	SUM(PY010G,PY020G,PY050G,PY080G,PY090G,PY100G,PY110G,PY130G,PY140G) as totgross at personal level
	SUM(totgross) as tot_H by HH
	&var/tot_H as allowratio_&vars
	allowratio_&var * totgross as new &var
~~~

so as to produce the following `Ben_taxes.NotZero` table in `WORK` library:
| GEO | TIME |  AGE  |  SEX  | BENEFIT_TAX  | MEAN   | FLAG  |  N    |  NTOT |   NTOTWGH   |
|:---:|:----:|:-----:|:-----:|:------------:|:------:|:-----:|:-----:|:-----:|:-----------:|
| AT  |	2015 | Y15-19|  T    |      HY050   | 350.4  |       |  742  |  742  | 518055.49   |	

In practice, the example above realises the following stepwise calculations:
~~~sas
	PROC SQL;  
		CREATE TABLE work.dsn AS
		SELECT *,
    	sum(totgross) as tot_H,
		&var/(calculated tot_H) as allowratio_&var,
		(calculated allowratio_&var)*totgross as tax_&var  
    	FROM BASE 
		where &var>0 
		GROUP BY DB020, DB030
   	 ; 
	QUIT;
	data dsn (drop=tax_&var) ;
		set dsn;
 		&var=tax_&var;
	run;
	PROC TABULATE data=work.dsn out=&var ;
 	   FORMAT AGE f_age9.;
		FORMAT RB090 f_sex.;
 		CLASS DB020;
 		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		VAR &var ;
		weight &weight;
		TABLE DB020 * AGE * RB090, &var  * ( N mean sum sumwgt) /printmiss;
	RUN;
~~~
where the datasets `&idb`, `&Hpdb`, and `&Ppdb` that appear above store the input personal 
and household data. These datasets, as well as the libraries `bdb` and `idb`, can be retrieved 
using the macro [%silc_db_locate](@ref sas_silc_db_locate).

### Notes
1. The list of (net and gross) benefits and taxes components normally considered (hence listed in `varaddp/h` 
and `vartaxes` variables) are to be chosen among: 
	+ social benefits, at personal level (`varaddp`):
		-`PY090G`: unemployment benefits,
		- `PY100G`: old-age benefits,
		- `PY110G`: survivors' benefits,
		- `PY120G`: sickness benefits,
		- `PY130G`: disability benefits,
		- `PY140G`: education-related allowances,
		
	+ social benefits, at household level (`varaddh`):
		-`HY050G`: family/children-related allowances),
		-`HY060G`: social exclusion not elsewhere classified),
		-`HY070G`: housing allowances),
		
	+ tax/income (`vartaxes`):
		-`HY140G`: tax on income and social insurance contributions, tax vs. benefit components separately,
		-`HY120G`: regular taxes on wealth,
		-`PY030G`: employers' social insurance contributions.
		
2. The breakdowns to be considered are generally:
	+ `breakdowns1`: all benefits and taxes variables,
	+ `breakdowns2: `age` (0-4, ........., 95+) and `sex`, e.g. using the following formats:
~~~sas
      VALUE f_age_ (multilabel)
            0 - 4 = "Y0-4"
			5 - 9 = "Y5-9"
			10 - 14 = "Y10-14"
			15 - 19 = "Y15-19"
			20 - 24 = "Y20-24"
			25 - 29 = "Y25-29"
	 	  	30 - 34 = "Y30-34"
			35 - 39 = "Y35-39"
			40 - 44 = "Y40-44"
			45 - 49 = "Y45-49"
			50 - 54 = "Y50-54"
			55 - 59 = "Y50-59"
			60 - 64 = "Y60-64"
			65 - 69 = "Y65-69"
			70 - 74 = "Y70-74"
			75 - 79 = "Y75-79"
			80 - 84 = "Y80-84"
			85 - 89 = "Y85-89"
			90 - 94 = "Y90-94"
	      	95 - HIGH = "Y_GE95"
				;
 	  VALUE f_RB090_ (multilabel)
			1 = "M"
			2 = "F"
			1 - 2 = "T";
~~~	

### References
1. EU-SILC survey reference document [doc65](https://circabc.europa.eu/sd/a/2aa6257f-0e3c-4f1c-947f-76ae7b275cfe/DOCSILC065%20operation%202014%20VERSION%20reconciliated%20and%20early%20transmission%20October%202014.pdf).
2. DG EMPL (2015): ["Wage and income inequality in the European Union"](http://ec.europa.eu/eurostat/cros/system/files/05-2014-wage_and_income_inequality_in_the_eu_0.pdf).
