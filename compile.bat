@echo off

set SMDIR=C:\Users\skullingcode\Nextcloud\sourcemod
echo Sourcemod Project Directory set to:
echo %SMDIR%
set SOURCEDIR=%~dp0src
echo Source Directory set to:
echo %SOURCEDIR%
set SMINCLUDES=\decompilerenv\include
echo Includes Directory set to:
echo %SMINCLUDES%
set BUILDDIR=%~dp0build
echo Build Directory set to:
echo %BUILDDIR%
set SPCOMP=\decompilerenv\spcomp.exe
echo Compiler Set to:
echo %SPCOMP%
for %%* in (.) do set PROJECT=%%~n*
echo Current project folder set to:
echo %PROJECT%
SET HOUR=%TIME:~0,2%
IF "%HOUR:~0,1%" == " " SET HOUR=0%HOUR:~1,1%
SET MONTH=%date:~4,2%
IF "%MONTH:~0,1%" == " " SET MONTH=0%MONTH:~1,1%
SET DAY=%date:~7,2%
IF "%DAY:~0,1%" == " " SET DAY=0%DAY:~1,1%

set datetimef=%date:~-4%.%MONTH%.%DAY%_%HOUR%.%time:~3,2%.%time:~6,2%
echo Current Date and Time of Execution Set to:
echo %datetimef%

:: Make build directory.
if not exist "%BUILDDIR%" (
    echo Build directory does not exist.
    echo Creating %BUILDDIR%
    mkdir %BUILDDIR%
)
if not exist "%SMDIR%\build_backups\%PROJECT%" (
    echo Build Backup directory does not exist.
    echo Creating %SMDIR%\build_backups\%PROJECT%
    mkdir %SMDIR%\build_backups\%PROJECT%
)

GOTO COMPILELOOP

:COMPILELOOP
echo.
echo.
echo Starting compiler:
for %%f in (%SOURCEDIR%\*.sp) do (
	echo ........................
	echo Found %%f
	if exist %BUILDDIR%\%%~nf.smx (
		echo File %BUILDDIR%\%%~nf.smx already exists
		pause
		
		echo Renaming %BUILDDIR%\%%~nf.smx to %%~nf_%datetimef%.smx
		rename %BUILDDIR%\%%~nf.smx %%~nf_%datetimef%.smx
		echo Moving %BUILDDIR%\%%~nf_%datetimef%.smx to %SMDIR%\build_backups\%PROJECT%
		move %BUILDDIR%\%%~nf_%datetimef%.smx %SMDIR%\build_backups\%PROJECT%
		echo Compiling %%~nf.sp
		%SMDIR%%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMDIR%%SMINCLUDES% -o%BUILDDIR%\%%~nf.smx %%f
		echo Compiled %BUILDDIR%\%%~nf.smx
		echo.
		echo.
	) else (
		echo Compiling %%~nf.sp
		%SMDIR%%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMDIR%%SMINCLUDES% -o%BUILDDIR%\%%~nf.smx %%f
		echo Compiled %BUILDDIR%\%%~nf.smx
		echo.
		echo.
	)
	
)
echo ........................
pause
echo.
GOTO COMPILELOOP