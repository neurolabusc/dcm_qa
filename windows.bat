ECHO off

REM MSVC has different rounding than GCC/CLANG descrip="TE=84;Time=153031.313" vs "TE=84;Time=153031.312"
REM find required files and folders
SET basedir=%cd%
SET indir=%basedir%\In
SET outdir=%basedir%\Out
SET refdir=%basedir%\Ref
SET exenam=
for %%X in (dcm2niix.exe) do (
	if not defined exenam (
		SET exenam=%%~$PATH:X
	)
)
REM test dependencies
IF NOT EXIST "%exenam%" (
	ECHO Error: Unable to find dcm2niix.exe in path
	EXIT /b 1
)
IF NOT EXIST "%indir%" (
	ECHO Error: Unable to find %indir%
	EXIT /b 2
)
IF NOT EXIST "%refdir%" (
	ECHO Error: Unable to find %refdir%
	EXIT /b 3
)
REM remove prior output
IF EXIST "%outdir%" (
	ECHO Cleaning output directory: %outdir%
	RMDIR /S /Q %outdir% 
)
MKDIR %outdir%
REM convert files
SET cmd="%exenam%" -b y -z n -f %%p_%%s -o "%outdir%" "%indir%"
ECHO Running command: %cmd%
REM START /B /W %cmd%
START /B /W "" %cmd%

REM test output
SET gitexe=
for %%X in (git.exe) do (
	if not defined gitexe (
		SET gitexe=%%~$PATH:X
	)
)
IF NOT EXIST "%gitexe%" (
	ECHO Error: Unable to find git: "%gitexe%"
	EXIT /b
)
REM C:\Git\cmd\git.exe -> C:\Git\usr\bin\diff
SET temp=
FOR %%i IN ("%gitexe%") DO (SET temp=%%~dpi)
SET difexe=
FOR %%i IN ("%temp:~0,-1%") DO (SET difexe=%%~dpi%usr\bin\diff.exe)
IF NOT EXIST "%difexe%" (
	ECHO Error: Unable to find diff "%difexe%"
	EXIT /b 1
)

REM SET difcmd="C:\Program Files\Git\usr\bin\diff" -x '.*' -br "%refdir%" "%outdir%" -I ConversionSoftwareVersion
SET difcmd="%difexe%" -x '.*' -br "%refdir%" "%outdir%" -I ConversionSoftwareVersion
ECHO Running command: %difcmd%
START /B /W "" %difcmd%