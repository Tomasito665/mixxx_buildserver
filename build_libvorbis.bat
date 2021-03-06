SETLOCAL
echo ---- Building Vorbis ----
set VORBIS_PATH=vorbis-1.3.5
SET VALRETURN=0

if %MACHINE_X86% (
  set PLATFORM=Win32
) else (
  set PLATFORM=x64
)

if %CONFIG_RELEASE% (
  set CONFIG=Release
) else (
  set CONFIG=Debug
)

cd build\%VORBIS_PATH%\win32\VS2015
echo Cleaning both...
%MSBUILD% vorbis_static.sln /p:Configuration=%CONFIG% /p:Platform=%PLATFORM% /t:libvorbis_static:Clean;libvorbisfile:Clean
IF ERRORLEVEL 1 (
    SET VALRETURN=1
	goto END
)
%MSBUILD% vorbis_dynamic.sln /p:Configuration=%CONFIG% /p:Platform=%PLATFORM% /t:libvorbis:Clean;libvorbisfile:Clean
IF ERRORLEVEL 1 (
    SET VALRETURN=1
	goto END
)

echo Building...
if %STATIC_LIBS% (
  %MSBUILD% vorbis_static.sln /p:Configuration=%CONFIG% /p:Platform=%PLATFORM% /t:libvorbis_static:Rebuild;libvorbisfile:Rebuild
) else (
  %MSBUILD% vorbis_dynamic.sln /p:Configuration=%CONFIG% /p:Platform=%PLATFORM% /t:libvorbis:Rebuild;libvorbisfile:Rebuild
)
IF ERRORLEVEL 1 (
    SET VALRETURN=1
	goto END
)

copy %PLATFORM%\%CONFIG%\libvorbis.lib %LIB_DIR%
copy %PLATFORM%\%CONFIG%\libvorbis.pdb %LIB_DIR%
if NOT %STATIC_LIBS% (
  copy %PLATFORM%\%CONFIG%\libvorbis.dll %LIB_DIR%
  copy %PLATFORM%\%CONFIG%\libvorbisfile.dll %LIB_DIR%
)
copy %PLATFORM%\%CONFIG%\libvorbisfile.lib %LIB_DIR%
copy %PLATFORM%\%CONFIG%\libvorbisfile.pdb %LIB_DIR%
md %INCLUDE_DIR%\vorbis
copy ..\..\include\vorbis\*.h %INCLUDE_DIR%\vorbis\

:END
cd %ROOT_DIR%
REM the GOTO command resets the errorlevel and the endlocal resets the local environment,
REM so I have to use this workaround
ENDLOCAL & SET VALRETURN=%VALRETURN%
exit /b %VALRETURN%