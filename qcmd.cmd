@echo off
:: Usage: %0 QDIR SRC
setlocal
if "%1"=="-" (
  echo Missing queue folder specification. Command will be directly executed.>&2
  set queue=.
) else (
  set queue=%1
)
if "%2"=="" echo Missing source specification.>&2 & exit /b 1
copy %2 %1
