================================================================================

                               SII Decrypt project

                                 version 1.2.X

================================================================================

Index
------------------------------

  Index ...................................................   9
  Description .............................................  22
  Parts of the project ....................................  41
  Project files ...........................................  68
  Repositories ............................................ 102
  Licensing ............................................... 115
  Authors, contacts ....................................... 123
  Copyright ............................................... 133


Description
------------------------------
This project is primarily designed to decrypt SII files that are used as a mean
of storing save data in truck games developed by SCS Software. It was tested on
saves from Euro Truck Simulator 2 and American Truck Simulator.

It can also decode binary format normally used in these saves into its textual
form. This decoding is done automatically when binary format is encountered.
It means you no longer have to manually change format (g_save_format) the game
is using while writing the saves.

The project is primarily developed in Delphi 7 Personal and Lazarus 1.6.x
(FPC 3.x) and therefore can be compiled by those development tools. But it
should be also possible to compile it in newer versions of mentioned
tools/compilers.
All main parts can be compiled into both 32bit and 64bit binaries.



Parts of the project
------------------------------
The project can be principally used in three ways - directly as a code, as
a dynamically loaded library (DLL) or as console program.

  If you want to use it directly, simply include files from .\Source folder in
  your project and use provided classes. Also make sure you add folder
  .\Source\Libs to project's search paths, as decryptor requires units that are
  stored there.

  To use this project as a library (DLL), include header file
  .\Headers\SII_Decrypt_Header.pas to your project and use functions and
  constants provided by this unit. Don't forget to add compiled DLL to your
  program.

  If you want to use this project in form of console program, you can do it as
  with almost all other console utilities. Invoke the EXE and pass path to
  a processed file as a first command line parameter. You can also specify
  destination file (file where the decrypted result will be stored) as a second
  parameter, but this is optional. If you do not select destination file, the
  result will be stored back in the source file. Note that destination file does
  not need to exist, but the folder where it will be stored must exist.
  You can use exit code of the program to check processing for errors. The
  result codes are the same as for functions exported by DLL version of this
  project - so refer to DLL headers for details.



Project files
------------------------------
List of folders with description of their content:

  .\
    Root folder. Contains license and readme files.

  .\Headers

    Header files for DLL part of the project.

  .\Source

    Source code of project's core. Also contains other units used throughout the
    whole project.

  .\Library

    Library (DLL) part of the project.

  .\Program

    Console program part of the project.

  .\Tester

    Small utility used to test library part of the project.

  .\TesterDirect

    Utility used to directly test implementation of library part.

  .\Scripts

    Batch files for automated compilation and cleaning.



Repositories
----------------------------------------
You can get actual copies of SII Decrypt project on either of these git
repositories:

https://github.com/ncs-sniper/SII_Decrypt
https://bitbucket.org/ncs-sniper/sii_decrypt

Note - master branch does not contain binaries, you can find them in a branch
       called "bin".



Licensing
----------------------------------------
Everything (source codes, executables/binaries, configurations, etc.) is
licensed under Mozilla Public License Version 2.0. You can find full text of
this license in file license.txt or on web page https://www.mozilla.org/MPL/2.0/.



Authors, contacts, links
----------------------------------------
František Milt, frantisek.milt@gmail.com

If you find this project useful and don't know what to do with your money ;),
consider making a small donation using the following link:
https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=WE33UXX9ASCCJ



Copyright
----------------------------------------
©2016-2017 František Milt, all rights reserved