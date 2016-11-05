del jbu_output.txt
rm -R c:\files\code\jas\src\t\*
rm -R c:\files\code\jas\src\t2\*
rm -R c:\files\code\jas\src\pull\*




ECHO      jbu -backup       [OPTIONS] [source directory] [destination directory]
ECHO  jbu -r -backup          c:\files\code\satdatsplat\ c:\files\code\jas\src\t\
      jbu -r -backup          c:\files\code\satdatsplat\ c:\files\code\jas\src\t\
ECHO  jbu -backup -CRC64   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -backup -CRC64   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -backup -SIZE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -backup -SIZE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -backup -DATE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -backup -DATE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -backup -QUIET   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -backup -QUIET   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -backup -RECURSE c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -backup -RECURSE c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\



ECHO      jbu -copy                   [source directory] [destination directory]
ECHO  jbu -r -copy          c:\files\code\satdatsplat\ c:\files\code\jas\src\t\
      jbu -r -copy          c:\files\code\satdatsplat\ c:\files\code\jas\src\t\
ECHO  jbu -copy -CRC64   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -copy -CRC64   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -copy -SIZE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -copy -SIZE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -copy -DATE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -copy -DATE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -copy -QUIET   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -copy -QUIET   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -copy -RECURSE c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -copy -RECURSE c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\



ECHO      jbu -move                   [source directory] [destination directory]
REM ECHO  jbu -r -move          c:\files\code\satdatsplat\ c:\files\code\jas\src\t\
REM       jbu -r -move          c:\files\code\satdatsplat\ c:\files\code\jas\src\t\
ECHO  jbu -move -CRC64   c:\files\code\jas\src\t2\   c:\files\code\jas\src\pull\
      jbu -move -CRC64   c:\files\code\jas\src\t2\   c:\files\code\jas\src\pull\
ECHO  jbu -move -SIZE    c:\files\code\jas\src\pull\   c:\files\code\jas\src\t2\
      jbu -move -SIZE    c:\files\code\jas\src\pull\   c:\files\code\jas\src\t2\
ECHO  jbu -move -DATE    c:\files\code\jas\src\t2\   c:\files\code\jas\src\pull\
      jbu -move -DATE    c:\files\code\jas\src\t2\   c:\files\code\jas\src\pull\
ECHO  jbu -move -QUIET   c:\files\code\jas\src\pull\   c:\files\code\jas\src\t2\
      jbu -move -QUIET   c:\files\code\jas\src\pull\   c:\files\code\jas\src\t2\
ECHO  jbu -move -RECURSE c:\files\code\jas\src\t2\   c:\files\code\jas\src\t1\
      jbu -move -RECURSE c:\files\code\jas\src\t2\   c:\files\code\jas\src\t1\


ECHO      jbu -sync         [OPTIONS] [source directory] [destination directory]
ECHO  jbu -r -sync          c:\files\code\satdatsplat\ c:\files\code\jas\src\t\
      jbu -r -sync          c:\files\code\satdatsplat\ c:\files\code\jas\src\t\
ECHO  jbu -sync -CRC64   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -sync -CRC64   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -sync -SIZE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -sync -SIZE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -sync -DATE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -sync -DATE    c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -sync -QUIET   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -sync -QUIET   c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
ECHO  jbu -sync -RECURSE c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\
      jbu -sync -RECURSE c:\files\code\jas\src\t\   c:\files\code\jas\src\t2\


ECHO      jbu -pull                   [source directory] [destination]
ECHO  jbu -r -pull       c:\files\code\jas\src\t2\  c:\files\code\jas\src\pull\
      jbu -r -pull       c:\files\code\jas\src\t2\  c:\files\code\jas\src\pull\
ECHO  jbu -pull -CRC64   c:\files\code\jas\src\t\   c:\files\code\jas\src\pull\
      jbu -pull -CRC64   c:\files\code\jas\src\t\   c:\files\code\jas\src\pull\
ECHO  jbu -pull -SIZE    c:\files\code\jas\src\t\   c:\files\code\jas\src\pull\
      jbu -pull -SIZE    c:\files\code\jas\src\t\   c:\files\code\jas\src\pull\
ECHO  jbu -pull -DATE    c:\files\code\jas\src\t\   c:\files\code\jas\src\pull\
      jbu -pull -DATE    c:\files\code\jas\src\t\   c:\files\code\jas\src\pull\
ECHO  jbu -pull -QUIET   c:\files\code\jas\src\t\   c:\files\code\jas\src\pull\
      jbu -pull -QUIET   c:\files\code\jas\src\t\   c:\files\code\jas\src\pull\
ECHO  jbu -pull -RECURSE c:\files\code\jas\src\t\   c:\files\code\jas\src\pull\
      jbu -pull -RECURSE c:\files\code\jas\src\t\   c:\files\code\jas\src\pull\



ECHO  jbu -prune c:\files\code\jas\src\t2\jbu_output.txt
      jbu -prune c:\files\code\jas\src\t2\jbu_output.txt





















  REM     >> jbu_output.txt
  REM     >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM
  REM
  REM
  REM
  REM     >> jbu_output.txt
  REM     >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM
  REM
  REM
  REM
  REM     >> jbu_output.txt
  REM     >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM
  REM
  REM
  REM     >> jbu_output.txt
  REM     >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM
  REM
  REM
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
  REM
  REM
  REM
  REM  >> jbu_output.txt
  REM  >> jbu_output.txt
