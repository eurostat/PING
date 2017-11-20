/**
## _default_meta_config_ {#sas__default_meta_config_}
Configuration file used to automatically generate metadata files.

### Usage
Launch/include this file so as to run the `%%_default_meta_config_` macro alone. 
Note that you will not need to launch the `%%_setup_` macro prior to this one, this is
automatically done.

*/ /** \cond */

%macro _default_meta_config_;
	%if %symexist(G_PING_SETUPPATH) EQ 0 %then %do; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	/* metadata related to processes in 5.1_Integration */ 
	%meta_transmissionxyear(clib=&G_PING_LIBCFG);
	
	/* metadata related to processes in 5.5_Estimation */ 
	%meta_variablexindicator(clib=&G_PING_LIBCFG);
	%meta_variable_dimension(clib=&G_PING_LIBCFG);
	%meta_indicator_contents(clib=&G_PING_LIBCFG);
	%meta_indicator_codes(clib=&G_PING_LIBCFG);
	%meta_country_order(clib=&G_PING_LIBCFG);

	/* metadata related to processes in 5.5_Extraction */ 
	%meta_variablexvariable(clib=&G_PING_LIBCFG);

	/* metadata related to processes in 5.7_Aggregates */ 
	%meta_zonexyear(clib=&G_PING_LIBCFG);
	%meta_populationxcountry(clib=&G_PING_LIBCFG);
	%meta_countryxzone(clib=&G_PING_LIBCFG);

%mend _default_meta_config_;

%_default_meta_config_;
