## income_components_gini {#sas_income_components_gini}
Compute the Gini coefficients of composite variable incomes for given geographical area(s)
and period(s). 

~~~sas
	%income_components_gini(geo, year, varadd=, varsub=, weight=, type=G, odsn=GINI_INC, olib=WORK);
~~~

### Arguments
* `geo` : a list of countries or a geographical area; default: `geo=EU28`; 
* `year` : year of interest;
* `varadd` : (_option_) list of (personal and household) income components to be considered  
	as contributing positively to the total income to be calculated; default: `varadd` is empty;
* `varsub` : (_option_) ibid for the list of (personal and household) income components   
	contributing negatively to the total income; default: `varsub` is empty; 
* `weight` : (_option_) personal weight variable used to weighting the distribution; default:
	`weight=RB050a`;
* `type` : (_option_) flag set to 'N' or 'G' to consider net and gross values respectively;
	default: `type=G`.

### Returns
* `odsn` : (_option_) name of the output datasets; default: `odsn=GINI_INC`;
* `olib` : (_option_) name of the output library; by default, when not set, `olib=WORK`.

### Example
Let us consider the following configuration parameters:

~~~sas
	%let year=2015;
	%let geo=AT;
	%let type=G;     	* gross values: this is default by the way;
	%let varadd=HY040 HY080 HY090 HY110  PY010 PY021 PY050 PY080;
	%let varsub=;
	%let weight=RB050a; * this is also the default;
	%let odsn=GINI_INC;
	%let olib=WORK;
~~~

we implicitely compute the Gini coefficient of the market outcome, normally expressed as:

	market = HY040G + HY080G + HY090G + HY110G 
		   + Sum{HH members}(PY010G + PY021G + PY050G + PY080)
	       = HY010 - [HY050G + HY060G + HY070G 
	       + Sum{all HH members}(PY090G +PY100G + PY110G +PY120G + PY130G +PY140G)]
	       = HY023 + (HY120G + HY130G + HY140G)

so as to produce the following `GINI_INC` table in `WORK` library:

| GEO | TIME |    GINI    | FLAG |  NTOT |    NTOTWGH   |
|:---:|-----:|-----------:|-----:|------:|-------------:|
| AT  |	2015 |49.790874267|   0  | 13213 | 8476450.5605 |	

In practice, the example above realises the following stepwise calculations:

~~~sas
	PROC SQL noprint;

		CREATE TABLE dsn1 as 
		SELECT DISTINCT 
			PB010, PB020, PHID, PB030, 
			PY010G, PY021G, PY050G, PY080, 
			SUM(PY010G, PY021G, PY050G, PY080,0) as sum_Pvaradd,
			SUM(calculated sum_Pvaradd) as Psum_add,
			0 as Psum_sub
		FROM bdb.&Pbdb as p
		WHERE PB020="AT" and PB010=2015
		GROUP BY PB020, PHID; 
			
		CREATE TABLE dsn2 as 
		SELECT DISTINCT 
			PB010, PB020, PHID, 
			(HY040G + HY080G + HY090G + HY110G + Psum_add - Psum_sub) as income,
			(calculated income / EQ_SS) as EQ_INC
		FROM dsn1 AS p
		LEFT JOIN bdb.&Hbdb  h 
			ON (p.PB010 = H.HB010) AND (p.PB020 = H.HB020) AND (p.PHID = H.HB030)
		LEFT JOIN idb.&ds as idb 
			ON (idb.DB010 = p.PB010) AND (idb.DB020 = p.PB020) AND (idb.DB030 = p.PHID)
		GROUP BY PB020, PHID;

		CREATE TABLE dsn3 as 
		SELECT DB010 as TIME, 
			DB020 as GEO, 
			DB030, RB030,
			&weight,
			count(RB030) as NTOT,
			sum(&weight) as NTOTWGH, 
			(case when calculated NTOT < 20 then 2
				when calculated NTOT < 50 then 1
				else 0 end) as FLAG, 	* our own rule
			EQ_INC
		FROM idb.&idb as idb
		LEFT JOIN dsn2  p 
			ON (idb.DB010 = p.PB010) AND (idb.DB020 = p.PB020) AND (idb.DB030 = p.PHID)
		WHERE DB020="AT" and DB010=2015;
	quit;

	PROC SORT data=dsn3;
		by EQ_INC;
	run;

	DATA gini(DROP=EQ_INC &weight ss swt swtvar swt2var swtvarcw);
		SET dsn3(DROP=DB030 RB030) end=last;
		RETAIN swt swtvar swt2var swtvarcw ss 0;
		ss + 1;
		swt +&weight;
		swtvar + &weight * EQ_INC;
		swt2var + &weight *&weight * EQ_INC;
		swtvarcw + swt *&weight * EQ_INC;
		if last then do;
			GINI  = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1);
			output;
		end;
	run;
~~~
where the datasets `&idb`, `&Hbdb`, and `&Pbdb` that appear above store the input personal 
and household data. These datasets, as well as the libraries `bdb` and `idb`, can be retrieved 
using the macro [%silc_db_locate](@ref sas_silc_db_locate).

### Notes
1. This macro will enable you to estimate the decomposition of disposable income Gini variation 
according to the contribution of different income sources.
2. The list of (net and gross) income components normally considered as positively contributing 
to the total income (hence listed in `varadd`) are to be chosen among: 
`HY040G/N`, `HY050G/N`, `HY051G`, `HY052G`, `HY053G`, `HY054G`, `HY060G/N`, `HY061G`, `HY062G`, 
`HY063G`, `HY064G`, `HY070G/N`, `HY071G`, `HY072G`, `HY073G`, `HY074G`, `HY080G/N`, `HY081G/N`, 
`HY090G/N`, `HY100G/N`, `HY110G/N`, `HY145N`, `HY170G/N`, `PY010G/N`, `PY021G/N`, `PY050G/N`, 
`PY080G/N`, `PY090G/N`, `PY100G/N`, `PY110G/N`, `PY120G/N`, `PY130G/N`, `PY140G/N`.
3. Ibid, the list of (net and gross) income components normally considered as negatively 
contributing to the total income (hence listed in `varsub`) are to be chosen among:
`HY120G/N`, `HY130G/N`, `HY131G/N`, `HY140G/N`.
4. By using specific configuration, it is possible to compute Gini coefficients over typical 
incomes, namely:
* total income _HY010_ as:
~~~sas
	%let varadd = HY040 HY050 HY060 HY070 HY080 HY090 HY110
		PY010 PY021 PY050 PY080 PY090 PY100 PY110 PY120 PY130 PY140;
	%let varsub =;
~~~	
* market income (see example above) as:
~~~sas
	%let varadd = HY040 HY080 HY090 HY110 PY010 PY021 PY050 PY080;
	%let varsub =;
~~~	
*  total disposable income _HY020_:
~~~sas
	%let varadd = HY040 HY050 HY060 HY070 HY080 HY090 HY110
		PY010 PY021 PY050 PY080 PY090 PY100 PY110 PY120 PY130 PY140;
	%let varsub = HY120 HY130 HY140;
~~~	
* intermediate disposable income _HY022_ (before social transfers other than old-age and 
survivor's benefits): 
~~~sas
	%let varadd = HY040 HY080 HY090 HY110
		PY010 PY021 PY050 PY080 PY090 PY100 PY110;
	%let varsub = HY120 HY130 HY140;
~~~	
* intermediate disposable income _HY023_ (before social transfers including old-age and 
survivor's benefits):
~~~sas
	%let varadd = HY040 HY080 HY090 HY110
		PY010 PY021 PY050 PY080;
	%let varsub = HY120 HY130 HY140;
~~~	

### References
1. EU-SILC survey reference document [doc65](https://circabc.europa.eu/sd/a/2aa6257f-0e3c-4f1c-947f-76ae7b275cfe/DOCSILC065%20operation%202014%20VERSION%20reconciliated%20and%20early%20transmission%20October%202014.pdf).
2. DG EMPL (2015): ["Wage and income inequality in the European Union"](http://ec.europa.eu/eurostat/cros/system/files/05-2014-wage_and_income_inequality_in_the_eu_0.pdf).

### See also
[income_components_disaggregated](@ref sas_income_components_disaggregated).
