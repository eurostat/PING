%global G_PING_SETUPPATH;
%let G_PING_SETUPPATH=; #place here the path where PING is stored
%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas"; # in case you preserve the structure as in the repository, it should be fine.
%_default_setup_;
