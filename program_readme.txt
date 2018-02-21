================================================================================

                      SII Decrypt project - console program

                                  version 1.3.2

================================================================================

Index
------------------------------

  Index ...................................................   9
  Description .............................................  23
  Use of the program ......................................  39
  Changelog ...............................................  86
  Known problems and limitations .......................... 113
  Repositories ............................................ 124
  Licensing ............................................... 137
  Authors, contacts ....................................... 145
  Copyright ............................................... 158


Description
------------------------------
This program is designed to decrypt and/or decode SII files that are used as a
mean of storing save data in truck games developed by SCS Software. It was
successfuly tested on saves from Euro Truck Simulator 2 and American Truck
Simulator and therefore should work for those games.
Unlike in previous version, you do not need to change save format the game is
using. Current version of this program can understand the now used binary format
and will convert it to a human-readable textual form. However, as the binary
format specification is not public, the decoding cannot be fully tested and
therefore might not work in rare circumstances or in future games. If that
happens, you can disable it by command no_decode (but in that case, you have to
configure the game to again store the saves in textual form).



Use of the program
------------------------------
This progam is a command line utility, meaning it does not have any graphical
user interface - you are supposed to use it by running it with proper command
line parameters.
For normal user not familiar with command line, it simple means dropping file
that has to be decrypted on the utility icon.
More advanced user can use one of two available parameter schemes - simple and
extended.

Simple scheme

    SII_Decrypt.exe InputFile [OutputFile]

  There are no commands awailable in the simple scheme. Program just takes first
  parameter as input file path and secod parameter, if present, as an output
  file path. If output path is not specified, the result is stored back into
  input file.

Extended scheme

    SII_Decrypt.exe [commands] -i InputFile [-o OutputFile]

  Extended scheme allows you to use commands when invoking the utility. Output
  file is optional and when not specified, the result is stored back into input
  file.
  Available commands are:

    --no_decode     When present, the program will not attempt to decode the
                    file, only decryption will be done. Can be used when there
                    are problems with the decoding.

    --sw_aes        AES decryption will be done completely in software.
                    Normally, AES can use hardware acceleration when supported
                    by hardware, this command disables it.

    --on_file       All processing will be done directly on the file. When not
                    present, entire file is loaded into memory and processed
                    there, this command can therefore lower memory use (but not
                    by a much).

    --wait          Program will not close the console when processing is done
                    and will wait for user input. Can be used when you want to
                    see possible error code.



Changelog
----------------------------------------
List of changes between individual versions of this program.

SII Decrypt program 1.3.1 -> SII Decrypt program 1.3.2
  - changed decoding of encoded strings


SII Decrypt program 1.3.0 -> SII Decrypt program 1.3.1
  - corrected managing of erroneous data in IDs


SII Decrypt program 1.2.2 -> SII Decrypt program 1.3.0
  - added support BSII file of format version 1
  - some minor internal changes


SII Decrypt program 1.2.1 -> SII Decrypt program 1.2.2
  - added support for new value types (0x37)


SII Decrypt program 1.2 -> SII Decrypt program 1.2.1
  - small optimizations
  - internal and implementation changes



Known problems and limitations
----------------------------------------
The program has rather large memory footprint - it can use tens to hundreds
megabytes of memory (but rarely more than 120MiB). Currently, it is not seen as
a problem, but in case anyone will have problem with that, please contact the
author.
Also, as mentioned before, decoding might not be 100% reliable. In case of
problems, contact author or run the tool with command no_decode.



Repositories
----------------------------------------
You can get actual copies of complete SII Decrypt project, including source code
of this progam, on either of these git repositories:

https://github.com/ncs-sniper/SII_Decrypt
https://bitbucket.org/ncs-sniper/sii_decrypt

Note - master branch does not contain binaries, you can find them in a branch
       called "bin".



Licensing
----------------------------------------
Program is licensed under Mozilla Public License Version 2.0. You can find full
text of this license in file license.txt or on web page
https://www.mozilla.org/MPL/2.0/.



Authors, contacts, links
----------------------------------------
František Milt, frantisek.milt@gmail.com

Forum thread: https://forum.scssoft.com/viewtopic.php?f=34&t=245874

If you find this program useful and don't know what to do with your money ;),
consider making a small donation using one of the following links:
https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=WE33UXX9ASCCJ
https://www.paypal.me/FMilt



Copyright
----------------------------------------
©2016-2018 František Milt, all rights reserved