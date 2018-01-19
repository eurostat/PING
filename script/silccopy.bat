
@ECHO off
REM 
REM @brief: Robust mirror copy of 0eusilc datasets into 1eusilc datasets.
REM 
REM 	silccopy.bat [idb] [bdb] [pdb]
REM 
REM @notes:  
REM 1. This is a Microsoft Batch Source File 
REM 2. At the moment, the robust copy of IDB (folder IDB_RDB/), BDB (folder BDB/) and
REM  PDB (folder pdb/) datasets is implemented.
REM 3. This script will delete all destination files/folders that no longer exist 
REM  in source folder.
REM
REM @reference
REM https://ss64.com/nt/robocopy.html
REM 
REM @credit:    <mailto:jacopo.grazzini@ec.europa.eu>
REM @date: 	26/06/2017
REM 

SETLOCAL enabledelayedexpansion

REM !!! copy options: review these options !!!
SET _WHAT=/MIR /FFT /Z
:: /FFT : assume FAT File Times
:: /S : copy subfolders
:: /COPYALL :: copy ALL file info
:: /COPY:DAT
:: /XA:[RASHCNETO] : eXclude files with any of the given Attributes:
:: 		R – Read only 
:: 		A – Archive 
:: 		S – System 
:: 		H – Hidden
:: 		C – Compressed 
:: 		N – Not content indexed
:: 		E – Encrypted 
:: 		T – Temporary
:: 		O - Offline
:: /sl : copy symbolic links instead of the target
:: /B :: copy files in Backup mode
:: /Z : Copy files in restartable mode (survive network glitch).
:: /MIR :: MIRror a directory tree = equivalent to /PURGE plus all subfolders /E
:: /XF file [file]... : eXclude Files matching given names/paths/wildcards.
:: /XD dirs [dirs]... : eXclude Directories matching given names/paths.

SET _OPTIONS=/W:5 /XA:H 
:: /R:n : number of Retries
:: /W:n : Wait time between retries
:: /LOG:file : output status to LOG file
:: /NFL : no File List - don’t log file names.
:: /NDL : no Directory List - don’t log directory names.

IF "%SESSIONNAME%"=="Console" (
   	REM ECHO ... Console
	REM GOTO error
) ELSE (
   REM ECHO ... Terminal Server 
   SET _DLOC=!SESSIONNAME:RDP-TCP#=!
   SET DISPLAY=127.0.0.1:!_DLOC!.0
   REM ECHO !DISPLAY!
)

SET IDB=0
SET PDB=0
SET BDB=0
SET HIDMAP=0
SET TEST=0

REM ==============================PARSE=========================================

IF "%~1"=="" (
	MODE CON: COLS=80 LINES=50
	ECHO PROGRAM %~n0 DOES NOT RUN IN STANDALONE MODE 
	ECHO LAUNCH COMMAND LINE %~n0 FROM CONSOLE
	GOTO error
) ELSE IF "%~1"=="help" (
	REM ECHO ... HELP parsed
 	GOTO error
)

ECHO.
ECHO -- Parsing

:parse

REM parse the argument
IF "%~1"=="test" (
	ECHO ... TEST parsed: all other options will be ignored
	SET TEST=1
	REM leave already, other options are ignored
	GOTO endparse 
) ELSE IF "%~1"=="idb" (
	ECHO ... IDB parsed
	SET IDB=1
	GOTO shift
) ELSE IF "%~1"=="pdb" (
	ECHO ... PDB parsed
	SET PDB=1
	GOTO shift
) ELSE IF "%~1"=="bdb" (
	ECHO ... BDB parsed
	SET BDB=1
	GOTO shift
) ELSE IF "%~1"=="hidmap" (
	ECHO ... HIDMAP parsed
	SET HIDMAP=1
	GOTO shift
) ELSE (
   ECHO.
   ECHO COMMAND %~1 NOT RECOGNISED
   GOTO error
   )

:shift
SHIFT

REM deal with last iteration of the loop
IF "%~1"==""  (
	GOTO endparse
	)
	
GOTO parse

:endparse


REM ==============================CHEK/SET======================================

ECHO.
ECHO -- Checking/setting

:check 

REM SET DIRSRC=</put/your/source/here>
REM DIRDEST=</put/your/destination/here>
REM SUBTEST=test\DUMMY

IF EXIST %DIRSRC% (
	ECHO ... OK: source directory %DIRSRC%
	REM skip
) ELSE (
	ECHO Error: source directory %DIRSRC% does not exist
	GOTO error
)

IF EXIST %DIRDEST% (
	ECHO ... OK: destination directory %DIRDEST%
	REM skip
) ELSE (
	ECHO Error: destination directory %DIRDEST% does not exist
	GOTO error
)

REM IF %TEST%==1 (
REM 	IF EXIST %DIRSRC%\%SUBTEST% (
REM 		ECHO ... OK: test directory %DIRSRC%\%SUBTEST% found
REM 		GOTO endcheck
REM 	) ELSE (
REM 		ECHO Error: test directory %DIRSRC%\%SUBTEST% does not exist
REM 		GOTO error
REM 	)
REM ) 

:endcheck

REM ==============================ASK===========================================

ECHO.
ECHO -- Validation

ECHO The following operations shall be performed:

IF %TEST%==1 (
	ECHO * test : test this command by mirror copying folder %SUBTEST%
	GOTO ask
	)

IF %IDB%==1 (
	ECHO * idb : mirror copy of IDB datasets stored in IDB_RDB/ folder
	)
IF %PDB%==1 (
	ECHO * pdb : mirror copy of BDB datasets stored in pdb/ folder
	)
IF %BDB%==1 (
	ECHO * bdb : mirror copy of BDB datasets stored in BDB/ folder
	)
IF %HIDMAP%==1 (
	ECHO * hidmap: mirror copy of hidmap datasets stored in 7.3_Dissemination/data/ folder
	)

:ask

ECHO.

SET /p UserAgree=Do you agree to run these operations (Y/N) ?: 

IF /I %UserAgree%==y ( 
	GOTO endask
) ELSE IF /I %UserAgree%==n ( 
	ECHO ... Operation aborted - check program use below
	GOTO error
) ELSE (
	ECHO Incorrect input (only y/n accepted) & GOTO ask
	)
	
:endask

REM GOTO quit


REM ==============================RUN===========================================

ECHO.
ECHO -- Running

:run

IF %TEST%==1 (
	ECHO ... run test and quit
	@ECHO off
	ECHO %time%
	Robocopy %DIRSRC%\%SUBTEST% %DIRDEST%\%SUBTEST% %_WHAT% %_OPTIONS% 
	ECHO %time%
	GOTO quit
	)

IF %IDB%==1 (
	ECHO ... copy IDB
	@ECHO off
	ECHO %time%
	SET LOGFILE=log_IDB_RDB_robocopy.txt
	Robocopy %DIRSRC%\IDB_RDB %DIRDEST%\IDB_RDB %_WHAT% %_OPTIONS% /LOG:%DIRDEST%\IDB_RDB\%LOGFILE% 
	REM ping 127.0.0.1 -n 3 > nul
	timeout 2 > NUL
	ECHO %time%
	)

IF %PDB%==1 (
	ECHO ... copy PDB
	@ECHO off
	ECHO %time%
	SET LOGFILE=log_pdb_robocopy.txt
	Robocopy %DIRSRC%\pdb %DIRDEST%\pdb %_WHAT% %_OPTIONS% /LOG:%DIRDEST%\pdb\%LOGFILE% 
	timeout 2 > NUL
	ECHO %time%
	)

IF %BDB%==1 (
	ECHO ... copy BDB
	@ECHO off
	ECHO %time%
	SET LOGFILE=log_BDB_robocopy.txt
	Robocopy %DIRSRC%\BDB %DIRDEST%\BDB %_WHAT% %_OPTIONS% /LOG:%DIRDEST%\BDB\%LOGFILE% 
	timeout 2 > NUL
	ECHO %time%
	)

IF %HIDMAP%==1 (
	ECHO ... copy HIDMAP
	ECHO hidmap: mirror copy of hidmap datasets stored in 7.3_Dissemination/data/ folder
	@ECHO off
	ECHO %time%
	SET SUBDIRHIDMAP=\\s-isis.eurostat.cec\0eusilc\7.3_Dissemination\data
	SET LOGFILE=log_hidmap_robocopy.txt
	REM Robocopy %SUBDIRHIDMAP%/hidmap ????? %_WHAT% %_OPTIONS% /LOG:%DIRDEST%\BDB\%LOGFILE%
	timeout 2 > NUL
	ECHO %time%
	)

REM reminder:
REM  	/MIR specifies that Robocopy should mirror the source directory and the destination directory. 
REM 	     Note that this will delete files at the destination if they were deleted at the source.
REM     /FFT uses fat file timing instead of NTFS. This means the granularity is a bit less precise. 
REM 	     For across-network share operations this seems to be much more reliable - just don't rely 
REM 	     on the file timings to be completely precise to the second.
REM     /Z ensures Robocopy can resume the transfer of a large file in mid-file instead of restarting.
REM     /XA:H makes Robocopy ignore hidden files, usually these will be system files that we're not 
REM 	     interested in.
REM     /W:10 reduces the wait time between failures to 10 seconds instead of the 30 second default. 

GOTO quit

:endrun

REM ==============================ERROR=========================================

:error

ECHO. 
ECHO ===========================================================================    
ECHO %~n0 : Robust mirror copy of EUSILC datasets from 0eusilc server to  
ECHO 1eusilc server
ECHO ===========================================================================    
ECHO. 
ECHO Syntax
 	
ECHO ------
    
ECHO       %~n0%~x0 [idb] [bdb] [pdb] [hidmap] [test] [help]
ECHO. 
ECHO Parameters
  	
ECHO ----------

ECHO * test : test dummy mirror copy from test/DUMMY; when set, all other options
ECHO        are ignored (i.e., in practice only the test directory is mirrored);
ECHO * idb : mirror copy of IDB datasets stored in IDB_RDB/ folder;
ECHO * bdb : mirror copy of BDB datasets stored in BDB/ folder;
ECHO * pdb : mirror copy of PDB datasets stored in pdb/ folder;
ECHO * hidmap : mirror copy of hidmap datasets stored in hid_map/ folder;
ECHO * help : display this help.
ECHO.
ECHO Examples	
ECHO -------
-
ECHO * %~n0%~x0 test : test this command, e.g. add/delete files in test folder
ECHO 	test/DUMMY/ located on 0eusilc drive (note: this folder must exist)  
ECHO 	and check the corresponding outputs (files with same name) on 1eusilc 
ECHO 	drive
ECHO * %~n0%~x0 idb bdb : this command will mirror copy both IDB and BDB 
ECHO 	databases
ECHO * %~n0%~x0 idb bdb : this command will mirror copy BDB databases only
ECHO.
ECHO Notes
ECHO ----
-
ECHO All datasets are mirror copied, there is currently no selection of data 
ECHO "per year/per country". 
ECHO This script uses Robocopy with the following options: /MIR /FFT /Z /XA:H.
ECHO This script needs to be ran from the terminal (command line).
ECHO.
ECHO      European Commission  -   DG ESTAT   -   The EU-SILC team  -  2017        
    
ECHO ===========================================================================    
ECHO. 

@ECHO off
timeout 10 > NUL

GOTO exit

:enderror

REM ==============================QUIT==========================================

:quit

ECHO.
ECHO -- Quit

REM ==============================EXIT==========================================

:exit
