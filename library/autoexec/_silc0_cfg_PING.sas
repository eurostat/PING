%global G_PING_SETUPPATH 
	G_PING_PROJECT 
	G_PING_DATABASE;
%let G_PING_PROJECT=	0EUSILC;
%let G_PING_SETUPPATH=	/ec/prod/server/sas/0eusilc/PING; 
%let G_PING_DATABASE=	/ec/prod/server/sas/0eusilc;

%include "&G_PING_SETUPPATH/library/autoexec/_silc_setup_.sas";
%_default_setup_;
