@echo off

>build.log (
call "Build library.bat"
call "Build console program.bat"
call "Build GUI program.bat"
call "Build tester.bat"
)