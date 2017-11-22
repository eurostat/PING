%global G_PING_SETUPPATH;
%let G_PING_SETUPPATH=/ec/prod/server/sas/1eusilc/2.Personal_folders/Pierre/sas/PING; /*place here the path where PING is stored */
%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas"; /* in case you preserve the structure as in the repository, it should be fine. */
%_default_setup_;
