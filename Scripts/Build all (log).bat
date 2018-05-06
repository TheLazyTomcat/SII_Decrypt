@echo off

>log.txt (
call "Build library.bat"
call "Build console program.bat"
call "Build GUI program.bat"
call "Build tester.bat"
)