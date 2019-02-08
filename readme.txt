================================================================================

                              SII Decrypt project

                                 version 1.5.x

================================================================================

Index
------------------------------

  Index ................................................... 9
  Description ............................................. 22
  Parts of the project .................................... 46
  Project files ........................................... 78
  Repositories ............................................ 117
  Licensing ............................................... 131
  Authors, contacts ....................................... 139
  Copyright ............................................... 150


Description
------------------------------
This project is primarily designed to decrypt SII files that are used as a mean
of storing save data in truck games developed by SCS Software. It was tested on
saves from Euro Truck Simulator 2 and American Truck Simulator.

It can also decode binary format normally used in these saves into its textual
form. This decoding is done automatically when binary format is encountered.
It means you no longer have to manually change format (g_save_format) the game
is using while writing the saves.

Since version 1.4, it is also possible to decode 3nK-encoded files. This
encoding is usually used in localization SII files. See project 3nK Transcode
(https://github.com/ncs-sniper/3nK_Transcode) for further details on this
format.

The project is primarily developed in Delphi 7 Personal and Lazarus 1.8.x
(FPC 3.x) and therefore can be compiled by those development tools. But it
should be also possible to compile it in newer versions of mentioned
tools/compilers.
All main parts can be compiled into both 32bit and 64bit binaries.



Parts of the project
------------------------------
The project can be principally used in four ways - directly as a code, as
a dynamically loaded library (DLL), as console program or as a GUI program.

  If you want to use it directly, simply include files from .\Source folder in
  your project and use provided classes. Also make sure you add folders
  .\Source\Libs and .\Source\ValuNodes to project search paths, as decryptor
  requires units that are stored there.

  To use this project as a library (DLL), include header file
  .\Library\SII_Decrypt_Library_Header.pas to your project and use functions
  and constants provided by this unit. Don't forget to add compiled DLL to your
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

  Using the GUI program is straight forward - run the program and use its
  controls (buttons, edits, ...) to select input file, output file, set options
  and then run the processing and wait for it to finish.



Project files
------------------------------
List of folders with description of their content:

  .\

    Root folder. Contains license and readme files.

  .\Documents

    Documentation of binary SII file format.

  .\Source

    Source code of project's core. Also contains other units used throughout the
    whole project.

  .\Library

    Library (DLL) part of the project, also contains header files for the DLL.

  .\Program_Console

    Console program part of the project.

  .\Program_GUI

    GUI program part of the project.

  .\Tester

    Small utility used to test the project.

  .\Scripts

    Batch files for automated compilation and cleaning.



Repositories
----------------------------------------
You can get actual copies of SII Decrypt project on either of these git
repositories:

https://github.com/ncs-sniper/SII_Decrypt
https://bitbucket.org/ncs-sniper/sii_decrypt
https://gitlab.com/ncs-sniper/SII_Decrypt

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
https://www.paypal.me/FMilt



Copyright
----------------------------------------
©2016-2019 František Milt, all rights reserved