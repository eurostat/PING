options minoperator mlogic;
OPTION SYMBOLGEN SPOOL;
proc datasets lib=work kill nolist memtype=data;
quit;

libname pdb "&G_PING_PDB";                  
libname idb "&G_PING_C_IDB"; 
%let year=15;
%let cty_lst=DK PT LT;  /*'PT' 'CY' 'PL' 'SK' 'CH' 'DK' 'LT' 'LU';  */

PROC SQL;
 CREATE TABLE ADAT AS SELECT 
	 idb.AROPE,
	 idb.DB020,
	 idb.DB030,
	 idb.RB090,
	 idb.AGE,
	 cdb.DB040,
	 cdb.DB050,
	 cdb.DB060,
	 idb.RB050a
 FROM idb.IDB&year AS idb,  pdb.C&year.D AS cdb
 WHERE (idb.DB010 = cdb.DB010 AND idb.DB020 = cdb.DB020 AND idb.DB030 = cdb.DB030) AND (idb.DB020 IN (%list_quote(&cty_lst)));
QUIT;

%var_est_data_prep (IDSN = adat , CTY_VAR= DB020 , BD_VAR= RB090, WGHT_VAR = RB050a, 
	STRT_VAR = DB050, SRS_SOS_CLSTR_VAR = DB030, STS_CLSTR_VAR = DB060, IND_COND_T = "AROPE>0", IND_COND_F = "AROPE=0", IND_NAME = arope, ODSN = adat_prep);
%var_est_srvyfrq (IDSN = adat_prep, YR=2000+&year, CTY_VAR= DB020, STRT = strt, CLSTR = clstr, WGHT = wght, PRP_IND = arope, BDOWN = RB090, ODSN = srvyfrqt0);
%var_est_mvrg (IDSN = adat_prep, YR=%eval(2000+&year), CTY_VAR= DB020, STRT = strt, CLSTR = clstr, WGHT = wght, PRP_IND = arope, ODSN = mvrgt0);


%let year2 = %eval(&year+1);
%put &year2;
PROC SQL;
 CREATE TABLE ADAT AS SELECT 
	 idb.AROPE,
	 idb.DB020,
	 idb.DB030,
	 idb.RB090,
	 idb.AGE,
	 cdb.DB040,
	 cdb.DB050,
	 cdb.DB060,
	 idb.RB050a
 FROM idb.IDB&year2 AS idb,  pdb.C&year2.D AS cdb
 WHERE (idb.DB010 = cdb.DB010 AND idb.DB020 = cdb.DB020 AND idb.DB030 = cdb.DB030) AND (idb.DB020 IN (%list_quote(&cty_lst)));
QUIT;

%var_est_data_prep (IDSN = adat , CTY_VAR= DB020 , BD_VAR= RB090, WGHT_VAR = RB050a, STRT_VAR = DB050, SRS_SOS_CLSTR_VAR = DB030, STS_CLSTR_VAR = DB060, IND_COND_T = "AROPE>0", IND_COND_F = "AROPE=0", IND_NAME = arope, ODSN = adat_prep);
%var_est_srvyfrq (IDSN = adat_prep, YR=2000+&year2, CTY_VAR= DB020, STRT = strt, CLSTR = clstr, WGHT = wght, PRP_IND = arope, BDOWN = RB090, ODSN = srvyfrqt1);
%var_est_mvrg (IDSN = adat_prep, YR=%eval(2000+&year2), CTY_VAR= DB020, STRT = strt, CLSTR = clstr, WGHT = wght, PRP_IND = arope, ODSN = mvrgt1);

%var_mvrg_cmpr(IDSN0 = outdata_mvrgt0, YR0=%eval(2000+&year), IDSN1 = outdata_mvrgt1, YR1=%eval(2000+&year2), CTY_VAR= DB020, STRT = strt, CLSTR = clstr, PRP_IND = arope, ODSN = mvrg_comparison);


