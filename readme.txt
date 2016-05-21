================================================================================

                              SII Decrypt library

                                 version 1.0.X

================================================================================

Index
------------------------------

  Index ...................................................   9
  Description .............................................  22
  Parts of the library ....................................  44
  Library files ...........................................  71
  Repositories ............................................ 105
  Licensing ............................................... 118
  Authors, contacts ....................................... 126
  Copyright ............................................... 132


Description
------------------------------
This library is designed to decrypt SII files that are used as a primary mean of
storing save data in truck games developed by SCS Software. It was tested on
saves from Euro Truck Simulator 2 and American Truck Simulator.
The project is primarily developed in Delphi 7 Personal and Lazarus 1.4.4 and
therefore can be compiled by those development tools. But it should be also
possible to compile it in newer versions of mentioned tools/compilers.
All main parts can be compiled into both 32bit and 64bit binaries.

WARNING - Current versions of ETS2 and ATS are no longer storing their saves as
          plaintext, but rather in undisclosed binary format. This library can
          still decrypt such files, but result will be, as mentioned, in binary,
          meaning manually almost uneditable.
          If you want to edit your saves, you have to change settings of the
          game and force it to use text saves again. You can do it by editing
          file config.cfg stored in your user folder
          (eg. documents/Euro Truck Simulator 2/) - change value of
          g_save_format to 2.



Parts of the library
------------------------------
The library can be principally used in three ways - directly as a code, as
a dynamically loaded library (DLL) or as console program.

  If you want to use it directly, simply include .\Source\Decryptor.pas file in
  your project and use classes provided in this unit. Also make sure you add
  folder .\Source\Libs to project's search paths, as decryptor requires units
  that are stored there.

  To use this library as DLL, include header file .\Headers\SII_DecryptLib.pas
  to your project and use functions and constants provided by this unit.
  Don't forget to add compiled DLL to your program.

  If you want to use this library in form of console program, you can do it as
  with almost all other console utilities. Invoke the EXE and pass path to
  a processed file as a first command line parameter. You can also specify
  destination file (file where the decrypted result will be stored) as a second
  parameter, but this is optional. If you do not select destination file, the
  result will be stored back in the source file. Note that destination file does
  not need to exist, but the folder where it will be stored must exists.
  You can use exit code of the program to check processing for errors. The
  result codes are the same as for functions exported by DLL version of this
  library - so refer to DLL headers for details.



Library files
------------------------------
List of folders with description of their content:

  .\
    Root folder. Contains license and readme files.

  .\Headers

    Header files for DLL part of the library.

  .\Source

    Source code of library's core. Also contains other units used throughout the
    whole project.

  .\Library

    DLL part of the library.

  .\Program

    Console program part of the library.

  .\Tester

    Small utility used to test DLL part of the library.

  .\Scripts

    Batch files for automated compilation and cleaning.



Repositories
----------------------------------------
You can get actual copies of SII Decrypt library on either of these git
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



Authors, contacts
----------------------------------------
František Milt, frantisek.milt@gmail.com



Copyright
----------------------------------------
©2016 František Milt, all rights reserved