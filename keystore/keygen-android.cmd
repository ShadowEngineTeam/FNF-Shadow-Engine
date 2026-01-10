@echo off
setlocal EnableDelayedExpansion

set ALIAS=fnf-se
set /p INPUT=Key alias name [fnf-se]:
if not "%INPUT%"=="" set ALIAS=%INPUT%

:password_loop
echo Keystore password:
set /p STOREPASS=

echo Confirm keystore password:
set /p STOREPASS_CONFIRM=

if "%STOREPASS%"=="" (
  echo Password cannot be empty.
  goto password_loop
)

if not "!STOREPASS:~5!"=="" goto pass_len_ok
echo Password must be at least 6 characters long.
goto password_loop

:pass_len_ok
if not "%STOREPASS%"=="%STOREPASS_CONFIRM%" (
  echo Passwords do not match.
  goto password_loop
)

set /p CN=Your full name (CN) [Unknown]:
if "%CN%"=="" set CN=Unknown

set /p OU=Organizational unit (OU) [Unknown]:
if "%OU%"=="" set OU=Unknown

set /p O=Organization (O) [Unknown]:
if "%O%"=="" set O=Unknown

set /p L=City or locality (L) [Unknown]:
if "%L%"=="" set L=Unknown

set /p ST=State or province (ST) [Unknown]:
if "%ST%"=="" set ST=Unknown

set /p C=Country code (2 letters) [US]:
if "%C%"=="" set C=US

echo Generating keystore...

set SCRIPT_DIR=%~dp0
set KEYSTORE_PATH=%SCRIPT_DIR%android\key.keystore
set OUTPUT_JSON=%SCRIPT_DIR%android\keystore.json

keytool -genkeypair ^
  -keystore "%KEYSTORE_PATH%" ^
  -alias "%ALIAS%" ^
  -keyalg RSA ^
  -keysize 4096 ^
  -validity 36500 ^
  -storepass "%STOREPASS%" ^
  -keypass "%STOREPASS%" ^
  -dname "CN=%CN%, OU=%OU%, O=%O%, L=%L%, ST=%ST%, C=%C%" ^
  -v

(
echo {
echo   "alias": "%ALIAS%",
echo   "storepass": "%STOREPASS%",
echo   "keypass": "%STOREPASS%"
echo }
) > "%OUTPUT_JSON%"

echo Keystore generated at: %KEYSTORE_PATH%
echo Keystore info saved at: %OUTPUT_JSON%

endlocal
