{==============================================================================
|    _________ _______  _______  ______  _______  Jegas, LLC                  |
|   /___  ___// _____/ / _____/ / __  / / _____/  Jason@jegas.com             |
|      / /   / /__    / / ___  / /_/ / / /____    www.jegas.com               |
|     / /   / ____/  / / /  / / __  / /____  /                                |
|____/ /   / /___   / /__/ / / / / / _____/ /                                 |
/_____/   /______/ /______/ /_/ /_/ /______/                                  |
|         Virtually Everything IT(tm)                                    |
===============================================================================
                       Copyright(c)2016 Jegas, LLC
==============================================================================}

Jegas Backup - Requires JegasAPI to compile

I hope this small but powerfull backup and file version control program is
useful for you and your organization.
--Jason - Jegas, LLC

USE AT YOU OWN RISK! JEGAS, LLC is NOT responsible for your data!
Before implementing ANY kind of back up system... TEST IT FIRST
and MORE IMPORTANTLY: TEST How to RESTORE your data after a disaster BEFORE
you have a disaster so you know just what to do!

---------------------------
Jegas Backup Contents:
---------------------------
jbu.exe    - Windows 32bit Executable
jbu        - Linux 64bit Executable
readme.txt - This file :)
---------------------------

Jegas Backup is a command line backup program that copies entire directories
from one place to another. Files that have been changed since a previous
backup are first renamed with a version number and then the new file is backed
up. This is basically an incremental backup program except you do not need any
tools to see the different file versions... just your file browser.

Versioned files have extension like below:
NewFile.exe
NewFile.exe.jbu001
NewFile.exe.jbu002
etc.

When you have to many versions or you just want them gone for any reason, run
the prune command. Help is available in the program so you just have to run it
without parameters to get started.

Jegas Backup is extremely fast due to its file copying algorithm. It makes
both linux and windows gui based and comand line copy routines seem very slow.
Test it yourself - race em!


HOW DO I USE IT? - "ONLY USE FULL PATHS!"
---------------------------


Example #1:   jegasbackup c:\files\ d:\backup\
-----------------------------------------------
Call this as many times as you like. It will only backup files that have changed
but jegasbackup does not overwrite the old files, it renames them like *.jbu001
where the * is the original filename. This gives you options like reverting to a
previous file version.



Example #2:   jegasbackup --prune  d:\backup\
---------------------------------------------
This commands prunes away the old versioned files but leaves all the current
files alone. This is a good thnig to do periodically, particularly if you
backup folders seem unusually big!





