%global G_PING_SETUPPATH 
	G_PING_PROJECT 
	G_PING_DATABASE;
%let G_PING_PROJECT=	1EUSILC;
 /* if you have access to both 0eusilc and 1eusilc, use: */
%let G_PING_SETUPPATH=	/ec/prod/server/sas/0eusilc/PING; 
/* otherwise use:
%let G_PING_SETUPPATH=	???; 
*/
%let G_PING_DATABASE=	/ec/prod/server/sas/1eusilc/0eusilc.copy;

%include "&G_PING_SETUPPATH/library/autoexec/_eusilc_setup_.sas";
%_default_setup_;
