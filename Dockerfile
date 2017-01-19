FROM microsoft/windowsservercore
# windowsservercore :10.0.14393.576_de-de
# $ProgressPreference: https://github.com/PowerShell/PowerShell/issues/2138#issuecomment-251261324
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG JAVA_VERSION
ARG JAVA_BUILD
ENV JAVA_VERSION=${JAVA_VERSION:-8} JAVA_BUILD=${JAVA_BUILD:-112}
ENV JAVA_FILENAME server-jre-${JAVA_VERSION}u${JAVA_BUILD}-windows-x64
ENV JAVA_DOWNLOAD_URL=http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}u${JAVA_BUILD}-b15/${JAVA_FILENAME}.tar.gz
ENV CURL_DOWNLOAD_URL=https://bintray.com/artifact/download/vszakats/generic/curl-7.52.0-win64-mingw.7z
ENV 7ZIP_DOWNLOAD_URL=http://www.7-zip.org/a/7z1604-x64.exe
RUN Write-Host ('Downloading {0} ...' -f $env:7ZIP_DOWNLOAD_URL); \
  Invoke-WebRequest -Uri $env:7ZIP_DOWNLOAD_URL -OutFile '7zSetup.exe'; \
	Write-Host 'Install 7-Zip'; \
  $process = (Start-Process '7zSetup.exe' '/S' -PassThru); \
	Write-Host 'Updating PATH ...'; \
	$env:PATH = ('{0}\7-Zip;' -f $env:ProgramFiles) + $env:PATH; \
	[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine); \
  \
# At the moment cUrl is used to download the Java archive, because i couldn't figure out, how to do that with Cookies/Header and Invoke-WebRequest
  Write-Host ('Downloading {0} ...' -f $env:CURL_DOWNLOAD_URL); \
  Invoke-WebRequest -Uri $env:CURL_DOWNLOAD_URL -OutFile 'curl.7z'; \
  $process.WaitForExit(); \
  7z.exe e curl.7z curl.exe libcurl.dll curl-ca-bundle.crt -r; \
  Rename-Item curl.exe rcurl.exe; \
  \
  Write-Host ('Downloading {0} ...' -f $env:JAVA_DOWNLOAD_URL); \
  .\rcurl.exe -v -j -k -L -H \"Cookie: oraclelicense=accept-securebackup-cookie\" ('{0}' -f $env:JAVA_DOWNLOAD_URL) -o ('{0}.tar.gz' -f $env:JAVA_FILENAME); \
	\
	Write-Host 'Installing Java ...'; \
  7z.exe x ('{0}.tar.gz' -f $env:JAVA_FILENAME); \
  7z.exe x ('{0}.tar' -f $env:JAVA_FILENAME); \
	\
	Write-Host 'Updating PATH ...'; \
	$env:PATH = ('C:\jdk1.{0}.0_{1}\bin;' -f $env:JAVA_VERSION, $env:JAVA_BUILD) + $env:PATH; \
	[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine); \
	\
	Write-Host 'Setting JAVA_HOME ...'; \
	$env:JAVA_HOME = ('C:\jdk1.{0}.0_{1}' -f $env:JAVA_VERSION, $env:JAVA_BUILD); \
	[Environment]::SetEnvironmentVariable('JAVA_HOME', $env:JAVA_HOME, [EnvironmentVariableTarget]::Machine); \
	\
	Write-Host 'Verifying install ...'; \
	Write-Host '  java -version'; java -version; \
	\
	Write-Host 'Removing installer ...'; \
	Remove-Item ('{0}.tar.gz' -f $env:JAVA_FILENAME) -Force; \
	Remove-Item ('{0}.tar' -f $env:JAVA_FILENAME) -Force; \
	Remove-Item curl.7z -Force; \
	Remove-Item 7zSetup.exe -Force; \
	\
  Write-Host 'Complete.';

CMD ["java"]  