SETLOCAL
echo.
echo ---- Building Qt5 ----
SET QT5_PATH=qt-everywhere-opensource-src-5.7.1
SET VALRETURN=0

if %MACHINE_X86% (
  set PLATFORM=Win32
) else (
  set PLATFORM=x64
)

if %CONFIG_RELEASE% (
  set CONFIG=-release
) else (
  set CONFIG=-debug
)

cd build\%QT5_PATH%
IF ERRORLEVEL 1 (
echo could not find QT5 on %CD%\build\%QT5_PATH%
    SET VALRETURN=1
	goto END
)

REM nmake distclean or nmake confclean are not present in the Makefile, so we delete these files and hope it rebuilds.
del qtbase\.qmake.cache
del qtbase\config.log
del /S /Q qtbase\mkspecs\modules\*.pri
del /S /Q qtbase\mkspecs\modules-inst\*.pri

echo Building...

set QT_NOMAKE=-nomake examples -nomake tests
REM skips can be any directory starting with 'qt' at the root of the repo -- keep list alphabetized.
REM skipping qttools skips building translations (since it doesn't have lrelease)
set QT_SKIP=-skip qt3d -skip qtdoc -skip qtmultimedia -skip qtwebengine -skip qtwebview

REM We link against the system SQLite so that Mixxx can link with and use the 
REM same instance of the SQLite library in our binary (for example, so we 
REM can install custom functions).
REM -D NOMINMAX https://forum.qt.io/topic/21605/solved-qt5-vs2010-qdatetime-not-enough-actual-parameters-for-macro-min-max
set QT_COMMON=-prefix %ROOT_DIR% -opensource -confirm-license -platform win32-msvc2015 -force-debug-info -no-strip -mp -system-sqlite -qt-sql-sqlite -system-zlib -ltcg -D NOMINMAX -D _USING_V110_SDK71_ -D SQLITE_ENABLE_FTS3 -D SQLITE_ENABLE_FTS3_PARENTHESIS -D ZLIB_WINAPI %QT_NOMAKE% %QT_SKIP% -no-dbus -no-audio-backend
 
if %STATIC_LIBS% (
call configure.bat %CONFIG% %QT_COMMON% -static -openssl-linked OPENSSL_LIBS="-luser32 -ladvapi32 -lgdi32 -lcrypt32 -lssleay32 -llibeay32"
) else (
call configure.bat %CONFIG% %QT_COMMON% -shared -openssl -separate-debug-info 
)

IF ERRORLEVEL 1 (
    SET VALRETURN=1
	goto END
)

rem /K keeps building things not affected by errors
nmake /nologo
IF ERRORLEVEL 1 (
    SET VALRETURN=1
	goto END
)

rem Now install to %ROOT_DIR%.
nmake install 
IF ERRORLEVEL 1 (
    SET VALRETURN=1
	goto END
)

rem Note, we do not run nmake clean because it deletes files we need (e.g. compiled translations).

:END
cd %ROOT_DIR%
REM the GOTO command resets the errorlevel and the endlocal resets the local environment,
REM so I have to use this workaround
ENDLOCAL & SET VALRETURN=%VALRETURN%
exit /b %VALRETURN%