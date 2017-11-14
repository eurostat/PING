%macro quantile(var                     /* Name of the input variable/list              (REQ) */
, probs=                /* List of probabilities                        (OPT) */
, type=                 /* Type of interpolation considered             (OPT) */
, method=               /* Flag used to select the estimation method    (OPT) */
, names=                /* Output name of variable/dataset              (OPT) */
, _quantiles_=          /* Name of the output variable                  (OPT) */
, idsn=                 /* Name of input dataset                        (OPT) */
, ilib=                 /* Name of input library                        (OPT) */
, odsn=                 /* Name of output dataset                       (OPT) */
, olib=                 /* Name of output library                       (OPT) */
, na_rm =               /* Dummy variable                               (OPT) */
) / store ;
%local _mac;
%let _mac=&sysmacroname;
 
%if &_FORCE_STANDALONE_ EQ %then %let _FORCE_STANDALONE_=1;
 
%if %symexist(G_PING_ROOTPATH) EQ 1 %then %do;
%macro_put(&_mac);
%end;
%else %if %symexist(G_PING_ROOTPATH) EQ 0 or &_FORCE_STANDALONE_ EQ 1 %then %do;
/* "dummyfied" macros */
%macro error_handle/parmbuff;   0 /* always OK, nothing will ever be checked */
%mend;
/*%macro ds_check(d, lib=) / store ;
%if %sysfunc(exist(&lib..&d, data)) or %sysfunc(exist(&lib..&d,view)) %then %do;        0
%end;
%else %do;                                                                              1
%end;
%mend;*/
%macro par_check/parmbuff / store ;              0 /* always OK */
/*%macro par_check(p, type=, range=, set=);
%list_ones(%list_length(&p), item=0)
%mend;*/
%macro macro_isblank(v) / store ;
%let __v = %superq(&v);
%let ___v = %sysfunc(compbl(%quote(&__v)));
%if %sysevalf(%superq(__v)=, boolean) or %nrbquote(&___v) EQ    %then %do;                      1
%end;
%else %do;                                                                                      0
%end;
%mend;
%macro list_length(l, sep=%quote( )) / store ;
%sysfunc(countw(&l, &sep))
%mend;
%macro list_apply(l, macro=, _applst_=, sep=%quote( )) / store ;
%let ol=%&macro(%scan(&l, 1, &sep));
%do i=2 %to %list_length(&l, sep=&sep);
%let ol=&ol %&macro(%scan(&l, &i, &sep));
%end;
data _null_;    call symput("&_applst_","&ol");
run;
%mend;
%macro list_to_var(v, n, d, fmt=, sep=%quote( ), lib=WORK) / store ;
DATA &lib..&d;
ATTRIB &n FORMAT=&fmt;
i=1;
do while (scan("&v",i,"&sep") ne "");
&n=scan("&v",i,"&sep"); output;
i + 1;
end;
drop i eof;
run;
%mend;
%macro _quantile_univariate(var, probs=, type=, qname=, idsn=, ilib=, odsn=, olib=) / store ;
 
%local tmp
pctlpts
pctldef;
%let tmp=TMP&sysmacroname;
%let pctlpts=;
 
/* define the quantiles according to SAS format (statement pctlpts) */
%macro defquant(x); %sysevalf(&x*100.) %mend;
%list_apply(&probs, macro=defquant, _applst_=pctlpts);
%let pctlpts=%list_quote(&pctlpts, mark=_EMPTY_, rep=%quote(, ));
 
/* define the method according to SAS definition (statement pctldef) */
%macro deftype(type);
/* DATA _map_method;
type=1; sas_type=3; output;
type=2; sas_type=5; output;
type=3; sas_type=2; output;
type=4; sas_type=1; output;
type=6; sas_type=4; output;
run; */
%if &type=1 %then %do;
3
%end;
%else %if &type=2 %then %do;
5
%end;
%else %if &type=3 %then %do;
2
%end;
%else %if &type=4 %then %do;
1
%end;
%else %if &type=6 %then %do;
4
%end;
%mend;
%macro _quantile_canonical(var, probs=, type=, qname=, idsn=, ilib=, odsn=, olib=) / store ;
 
%local i i1 i2
SEP
tmp
N Q gamma
p m j g
nprobs;
%let SEP=%quote( );
%let nprobs=%list_length(&probs, sep=&SEP);
%let tmp=TMP&sysmacroname;
 
/* some macro definition */
%macro p_indice(k, alphap, betap, n);   /* p(k) = (k - alphap)/(n + 1 - alphap - betap) */
%sysevalf((&k - &alphap)/(&n + 1 - &alphap - &betap))
/* (alphap, betap) =
* (0,1) : p(k) = k/n : linear interpolation of cdf (R type 4)
* (.5,.5) : p(k) = (k - 1/2.)/n : piecewise linear function (R type 5)
* (0,0) : p(k) = k/(n+1) : (R type 6)
* (1,1) : p(k) = (k-1)/(n-1): p(k) = mode[F(x[k])]. (R type 7, R default)
* (1/3,1/3): p(k) = (k-1/3)/(n+1/3): Then p(k) ~ median[F(x[k])]; resulting quantile
estimates are approximately median-unbiased regardless of the distribution of x
(R type 8)
* (3/8,3/8): p(k) = (k-3/8)/(n+1/4): Blom. The resulting quantile estimates are
approximately unbiased if x is normally distributed (R type 9) */
%mend p_indice;
%macro m_indice(p, i=, alphap=, betap=) / store ;        /* m = alphap + p*(1 - alphap - betap) */
%local m;
%if "&i"^="" %then %do;
%if &i=1 or &i=2 or &i=4 %then                          %let m=0;
%else %if &i=3 %then                                            %let m=-0.5;
%else %if &i=5 %then                                            %let m=0.5;
%else %if &i=6 %then                                            %let m=&p;
%else %if &i=7 %then                                            %let m=%sysevalf(1-&p);
%else %if &i=8 %then                                            %let m=%sysevalf((&p+1)/3);
%else %if &i=9 %then                                            %let m=%sysevalf((2*&p+3)/8);
%end;
%else %if "&alphap"^="" and "&betap"^="" %then
%let m = %sysevalf(&alphap + &p*(1 - &alphap - &betap));
&m
%mend m_indice;
%macro j_indice(p, n, m) / store ;                               /* j = floor(n*p + m) */
%sysfunc(floor(%sysevalf(&n*&p + &m)))
%mend j_indice;
%macro g_indice(p, n, m, j) / store ;                    /* g = n*p + m - j */
%sysevalf(&n*&p + &m - &j)
%mend g_indice;
%macro _example_quantile / store ;
%if %symexist(G_PING_ROOTPATH) EQ 0 and &_FORCE_STANDALONE_ EQ 0 %then %do;
%if %symexist(G_PING_SETUPPATH) EQ 0 %then      %let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING;
%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
%_default_setup_;
%end;
 
%local dsn N;
%let dsn=TMP&sysmacroname;
%let N=1000;
 
data &dsn;
call streaminit(123);       /* set random number seed */
do i = 1 to &N;
u = rand("Uniform");     /* u ~ U(0,1) */
output;
end;
run;
 
%let quantiles=;
%let type=1;
%let probs=0.001 0.005 0.01 0.02 0.05 0.10 0.50;
%put (i) Test with probs=&probs, type=&type and method=INHERIT;
%quantile(u, probs=&probs, _quantiles_=quantiles, type=&type, idsn=&dsn, ilib=WORK, method=INHERIT);
%put quantiles=&quantiles;
 
%let quantiles=; /* reset */
%let probs=0.00 0.25 0.50 0.75 1.00;
%put (ii) Test with probs=&probs, type=&type and method=DIRECT;
%quantile(u, probs=&probs, _quantiles_=quantiles, type=&type, idsn=&dsn, ilib=WORK, method=DIRECT);
%put quantiles=&quantiles;
 
%put;
PROC DATASETS lib=WORK nolist; DELETE &dsn; quit;
%mend _example_quantile;
