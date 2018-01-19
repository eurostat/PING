%global G_PING_SETUPPATH 
	G_PING_PROJECT 
	G_PING_DATABASE;
%let G_PING_SETUPPATH=	/* define PING's location */; 
%let G_PING_PROJECT=	/* define your project's name */;
%let G_PING_DATABASE=	/* define your databse's location */;

/* this will work as long as you preserve the original repository's structure */
%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas"; 
%_default_setup_;
