{=============================================================================
|    _________ _______  _______  ______  _______  Get out of the Mainstream, |
|   /___  ___// _____/ / _____/ / __  / / _____/    Mainstream Jetstream!    |
|      / /   / /__    / / ___  / /_/ / / /____         and into the          |
|     / /   / ____/  / / /  / / __  / /____  /            Jetstream! (tm)    |
|____/ /   / /___   / /__/ / / / / / _____/ /                                |
/_____/   /______/ /______/ /_/ /_/ /______/                                 |
|         Virtually Everything IT(tm)                        Jason@Jegas.com |
==============================================================================
                       Copyright(c)2016 Jegas, LLC
=============================================================================}

//=============================================================================
// SEARCH: !@! - Defines      !#! - Functions/Procedures
//=============================================================================


//=============================================================================
// Global Directives
//=============================================================================
{$INCLUDE i_jegas_splash.pp}
{$INCLUDE i_jegas_macros.pp}
{$DEFINE SOURCEFILE:='jbu.pas'}
{$SMARTLINK ON}
{$PACKRECORDS 4}
{$MODE objfpc}
{$DEFINE RELEASE}
{DEFINE DEBUG_MESSAGES}
{DEFINE DRY_RUN_ONLY} //DO NOT MOVE ANYTHING!!!!!!
{DEFINE HASFTP}
{DEFINE DEBUG_ROUTINE_NESTING}
//=============================================================================

//=============================================================================
// compiler output   // !@!
//=============================================================================
{$IFDEF DEBUG_MESSAGES}
  {$INFO  DEBUG_MESSAGES ENABLED - lots of output and readln too}
{$ENDIF}

{$IFDEF DRY_RUN_ONLY}
  {$INFO  DRY_RUN_ONLY MODE - only tests command line}
{$ENDIF}

{$IFDEF DEBUG_ROUTINE_NESTING}
  {$INFO DEBUG_ROUTINE_NESTING - built in tracing of the application}
{$ENDIF}
//=============================================================================
//  TODO: Tell Server TO LOSE the IP Validation essentially signing off.
//  TODO: Add duplicate Finder (CRC64) Based
//=============================================================================




//=============================================================================
// THIS IS THE ONE TO DO NOW  - TWO VERSIONS: DESTRUCTIVE and RETIRE
//=============================================================================
//  TODO: Feature Where two Directories are compared like a sync except
//        if a file is missing in the source but exists in the destination,
//        KILL IT! <---- Destructive (and kill the history too! *.jbu*)
//
//        RETIRE - versions the file (renames filename.jbu### ### = highest
//                 version number for that file). This is good for when
//                 you use the PULL command - you only get the latest stuff
//                 and that means "retired" files aren't "pulled".
//=============================================================================





//-----------------------------------------------------------------------------
// ftp client - key > server (server records ip in mem if key good)
//                           server will only deal with keys or
//                           validated. Validated IP pretty much
//                           owns the server's working dir. Client
//                           go higher than server's working dir.
//                           security thing - as open and home/private
//                           this tool might be mainly intended - this
//                           prevents a "hacker" or user just messing up
//                           from accidently/puposely writing above the
//                           working dir potentially damaging stuff!
//
// ftp client -> ASKS FOR DIR LIST OF SERVER WORKING DIR WITH DUPE ID Strategy Flags
//                 sending the flags will allow the server to be basically told
//                 to spitout a text file response or CRC the wHOLE DAM FOLDER
//                 and send me the same list with CRC's This will allow the
//                 client to do crc64 remote without hardly any traffic :)
//
//  FORMAT IN: JEGASBACKUP FILELIST -date -size -crc
//           Note: No Flags means file name alone
//           is enough to make the system back
//           the file up before overwriting it
//           if it exists. More effient strategies
//           are any individual use or combo of the
//           options -date -size -crc
//
//  ALL FILE PUTS TO SERVER TO FILENAME ONLY VERSIONING BECAUSE THE BRAINS
//  on what to bother sending will all be client
//
//
//
//
//
//
//
//
//=============================================================================


//=============================================================================
program jbu; // !@!
//=============================================================================

//=============================================================================
Uses //!@!
//=============================================================================
//  classes
//  ,dos
{$IFDEF linux}
//  ,baseunix
cthreads,
{$ENDIF}
classes
//,syncobjs
,sysutils
,ug_common
,sockets
,ug_jegas
,ug_jfc_dir
,ug_misc
,ug_jfc_tokenizer
,ug_jfc_xdl
,ug_jcrypt
,dos
,process
{$IFDEF HASFTP}
//,blcksock
//,httpsend
,FTPTSend
,TFTPDaemonThread_jegas
{$ENDIF}
{$IFNDEF WINDOWS}
,types
{$ENDIF}
;
//=============================================================================







//=============================================================================
const // !@!
//=============================================================================
  //---------------------------------------------------------------------------
  // Application info
  //---------------------------------------------------------------------------
  csJBU_AppTitle       = 'Jegas Backup';
  csJBU_Version        = '2016-11-02';
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // JegasBackup Modes dicated on command line by caller.
  //---------------------------------------------------------------------------
  cnJB_Backup           =1;
  cnJB_Client           =2;
  cnJB_Copy             =3;
  cnJB_Help             =4;
  cnJB_MakeKey          =12;
  cnJB_Move             =5;
  cnJB_PermBackup       =6;
  cnJB_PermRestore      =7;
  cnJB_Pull             =8;
  cnJB_Prune            =9;
  cnJB_SplashOnly       =0;//ZERO!!!!!!!!!!!
  cnJB_Sync             =11;
  {$IFDEF HASFTP}
  cnJB_Server           =10;
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // remote server modes. if jbu was invoked as to perform a local file move
  //   to/from a remote instance of jegasbackup there are two states,
  // or none at all. These describe if the source "dir" or destination "dir"
  // are infact remote servers instead a local dir and storage device.
  // e.g. it works over the wire :)
  //---------------------------------------------------------------------------
  cnRS_None = 0;
  cnRS_Src  = 1;
  cnRS_Dest = 2;
  //---------------------------------------------------------------------------
  {$ENDIF}
  csDirFilename = 'directory.jbures';
  csTempFile='jbu.tmp';
  {$IFNDEF WINDOWS}
  csTempScriptName = 'jegasbackup-temp.sh';
  {$ENDIF}
  csJBULogFilename = 'jbu.log';

  cnMaxNestLevel = 20;
//=============================================================================




//=============================================================================
var             // !@!
//=============================================================================
  gsaSrcDir: ansistring;
  gsaDestDir: ansistring;
  gi1Mode: shortint;
  // BEGIN ------------- STATS
  dtStart, dtEnd: TDATETIME;
  gu8Count_File: UInt64;
  gu8Count_Dir: UInt64;
  gu8Count_Versioned: UInt64;// means renamed, a nunmber assigned it, so not overwritten
  gu8Count_BytesMoved: UInt64;//how much actual data copied?
  gu8Count_BytesSkipped: UInt64;// how much data was NOT COPIED purposely?
  gu8Count_Errors: UInt64;
  gu8Count_Pruned: UInt64;
  // END ------------- STATS
  gbOptDate: boolean;
  gbOptSize: boolean;
  gbOptCrc: boolean;
  gbOptRecurse: boolean;
  gbOptLog: boolean;
  gbOptQuiet: boolean;
  gbOptRetire: boolean;
  gbOptDestructive: boolean;
  gsaParam1: ansistring;
  gsaParam2: ansistring;
  gsaParam3: ansistring;
  gi8NestLevel: Int64;
  fLog: text;
  gbFirstError: boolean;
  {$IFDEF DEBUG_ROUTINE_NESTING}
  gi8RoutineNestLvl: Int64;
  {$ENDIF}
  {$IFDEF HASFTP}
  fDir: text;
  gsaIP        :ansistring;
  gsaPort      :ansistring;
  gsaKey: ansistring;
  gbOptWait: boolean;
  giRemoteServerIs: integer;
  TFTP: TTFTPSend;
  gu8ServerTimeOut: UInt64;
  gsaKeyFile: ansistring; // no file ext
  {$ENDIF}

//=============================================================================







{$IFDEF DEBUG_ROUTINE_NESTING}
//=============================================================================
procedure DebugRoutineIn(p_saRoutineName: ansistring);
//=============================================================================
begin
  write('-->  |');
  gi8RoutineNestLvl+=1;
  if gi8RoutineNestLvl>1 then write(saRepeatChar('-',gi8RoutineNestLvl));
  writeln(p_saRoutineName);
end;
//=============================================================================

//=============================================================================
procedure DebugRoutineOut(p_saRoutineName: ansistring);
//=============================================================================
begin
  write('<--  |');
  if gi8RoutineNestLvl>1 then write(saRepeatChar('-',gi8RoutineNestLvl));
  gi8RoutineNestLvl-=1;
  writeln(p_saRoutineName);
end;
//=============================================================================
{$ENDIF}

//=============================================================================
procedure WriteSeparator(p_bStart: boolean; p_saName: ansistring);// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='WriteSeparator';{$ENDIF}
var i: integer;
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  for i:=0 to 1 do write(saRepeatChar('=',79)+csCRLF);
  if p_bStart then write('BEGIN ') else write('END ');
  for i:=0 to 1 do write(saRepeatChar('=',79)+csCRLF);
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================



//=============================================================================
procedure BUError(p_id: uint64; p_saErr:ansistring);// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='BUError';{$ENDIF}
var sa: ansistring;
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  gu8Count_Errors+=1;
  if gbFirstError then
  begin
    if gbOptLog then
    begin
      writeln(flog,saJegasLogoRawText(csCRLF));
      writeln(flog,grJegasCommon.sAppProductName+'  - Version: '+grJegasCommon.sVersion);
      writeln(flog,'By: Jason Peter Sage - Jegas, LLC - Jegas.com');
      writeln(flog,sarepeatchar('=',79));
    end;
    gbFirstError:=false;
  end;

  sa:='ERR - '+ inttostr(p_id)+' - '+p_saErr;
  if not gbOptQuiet then writeln(sa);
  if gbOptLog then
  begin
    //riteln('Writing to Log - begin');
    writeln(flog,sa);
    //riteln('Writing to Log - end');
  end;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================



{$IFDEF HASFTP}
//=============================================================================
function saRemoteServerIs: ansistring;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='saRemoteServerIs';{$ENDIF}
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  case giRemoteServerIs of
  cnRS_None   : result:='None';
  cnRS_Src    : result:='Source';
  cnRS_Dest   : result:='Dest';
  end;//select
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================


//=============================================================================
function saFTPError(p_u1: byte): string;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='saFTPError';{$ENDIF}
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  case p_u1 of
  0: result:='Not defined, see error message (if any).';
  1: result:='File not found.';
  2: result:='Access violation.';
  3: result:='Disk full or allocation exceeded.';
  4: result:='Illegal TFTP operation.';
  5: result:='Unknown transfer ID.';
  6: result:='File already exists.';
  7: result:='No such user.';
  end;//select
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================
{$ENDIF}


//=============================================================================
function saModeName: ansistring;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='saModeName';{$ENDIF}
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  case gi1Mode of
  cnJB_Backup           : result:='Backup';
  cnJB_Copy             : result:='Copy';
  cnJB_Help             : result:='Help';
  cnJB_MakeKey          : result:='Make key file for networking';
  cnJB_Move             : result:='Move';
  cnJB_PermBackup       : result:='Permissions Backup';
  cnJB_PermRestore      : result:='Permissions Restore';
  cnJB_Pull             : result:='Pull';
  cnJB_Prune            : result:='Prune';
  cnJB_SplashOnly       : result:='Splash Screen Only';
  cnJB_Sync             : result:='Synchronization';
  {$IFDEF HASFTP}
  cnJB_Client           : result:='Client';
  cnJB_Server           : result:='Server';
  {$ENDIF}
  else begin
    result:='< !! Unknown Mode !! >';
  end;//case
  end;//select
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================













{$IFNDEF WINDOWS}
//=============================================================================
function bPermRestore(p_saSrcFile: ansistring; p_saWorkDir: ansistring):boolean;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='bPermRestore';{$ENDIF}
var
  bOk: boolean;
  sa: ansistring;
  TK: JFC_TOKENIZER;
  u2IOResult: word;
  bOpen: boolean;
  saTemp: ansistring;//for the parsing lines of text of dir
  p1,p2,p3: byte;
  bDoneWithLine: boolean;
  saCmd: ansistring;
  u2ShellREsult: word;
  saFolder:ansistring;
  saOwner, saGrp: ansistring;
  saDate: ansistring;
  //dt: TDATETIME;
  f: text;
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  TK:=JFC_TOKENIZER.create;
  //TK.saLastOne:='';
  //TK.bCaseSensitive:=False;
  //TK.bKeepDebugInfo:=False;
  TK.sQuotes:='';
  TK.sWhiteSpace:=csCRLF+' "';
  TK.sSeparators:=csCRLF+' ';
  TK.iQuoteMode:=0;
  bOk:=fileexists(p_saSrcFile);
  bOpen:=false;
  if not bOk then
  begin
    BUError(201511251956,'File not Found: '+p_saSrcfile);
  end;

  if bOk then
  begin
    assign(f,p_saSrcFile);u2IOResult:=ioresult;bOk:=u2IOResult=0;
    if not bOk then
    begin
      BUError(201511251954,'IOResult: '+inttostr(u2IOREsult)+' '+
        sIOResult(u2IOREsult)+'. Unable to assign file handle to file: '+
        p_saSrcfile);
    end;
  end;

  if bOk then
  begin
    try
      reset(f);
    except on E:Exception do begin
      bOk:=false;
      BUError(201607070124,'reset(f)'+csDirFilename);
    end;//except
    end;//try
    u2IOResult:=ioresult;bOk:=bOk and (u2IOResult=0);bOpen:=bOk;
    if not bOk then
    begin
      BUError(201511251955,'IOResult: '+inttostr(u2IOREsult)+' '+
        sIOResult(u2IOREsult)+'. Unable to open this file in read only mode: '+
        p_saSrcfile);
    end;
  end;


  //------------------------------------------
  // TOKENIZER ITEM (parent - jfc_xdl)
  //------------------------------------------
  // saToken: AnsiString;
  //   0=Not a Quoted Token
  //   otherwise -
  //   Positive Numbers point to Which Quote Pair in QuotesXDL
  //   The Token is
  //
  //   NEGATIVE Value Means In Single Quote Mode From
  //   saQuotes. Value *-1 in this case tels you WHICH
  //   Quote (char position in saQuotes)
  // iQuoteID: Integer;
  //------------------------------------------



  ////------------------------------------------
  //// Tokenizer
  ////------------------------------------------
  //saLastOne: AnsiString;
  //// Some Settings To Control How Tokenizing is performed
  //bCaseSensitive: Boolean; //< Default FALSE
  //bKeepDebugInfo: Boolean; //< Default FALSE (But you better check!)
  //Property Item_iQuoteID: Integer read read_Item_iQuoteID W rite w rite_Item_iQuoteID;
  //Property Item_saToken: AnsiString read read_Item_saToken W rite w rite_item_saToken;
  //Property Item_i8Pos: Int64 read read_Item_i8Pos W rite w rite_Item_i8Pos;
  //Property Tokens: Integer read iItems; //< same as listcount in JFC_DL for example.
  //Property Token: Integer read iNN; //< same as "N" - The Sequential Position in JFC_DL for example.
  //Function Tokenize(p_sa: AnsiString): Integer; //< Deletes Token List
  //Function TokenizeMore(p_sa: AnsiString): Integer; //< Continues where it left off
  //Function DumpToTextFile(p_saFileName: AnsiString): Integer;
  //Function NthItem_saToken(p_i: Integer): AnsiString; //< SAFE method - Give me This
  //Function FoundItem_iQuoteID(p_i: Integer):Boolean;
  //Procedure SetDefaults;
  //
  //// Name Field Has Start Quote, Desc Field has End Quote
  //// Load Up With Start and End Quotes -
  //// This is designed for Multi Character Start and END Quotes.
  //// CAVEATS: (or Blessings) if There is a blank start quote - in the list
  //// Tokenizing Starts with the End Quote
  //// If there is a Blank End Quote tokenizing starts with the start quote
  //// If there is quote item with both - Tokenization stops
  //public
  //QuotesXDL: JFC_QUOTEXDL;
  //
  //// This is designed for SINGLE QUOTE pairs - Where Start and End Quote
  //// ARE the SAME Character. These can be Escaped by having two in a row.
  //// There are checked AFTER the QuotesXDL list is checked due to its
  //// "Blank" Quote paradigm. (For Ignoring Stuff) Like These Freepascal
  //// Double Slashes for comments! ;)
  //saQuotes: AnsiString;
  //
  //// Separators START New Tokens
  //// Load Up with separators
  //saSeparators: AnsiString;
  //
  //// White Space Characters Don't Make it into TOKENS
  //// unless within quotes. Whitespace shouldn't be in
  //// quotes. Load Up With WhiteSpace Chars (Get Dropped)
  //saWhiteSpace: AnsiString;
  //
  //
  //// 0 = not in quote mode, otherwise - points to
  ////     QUOTE mode last in.
  //// NEGATIVE Value Means In Single Quote Mode From
  //// saQuotes. Value *-1 in this case tels you WHICH
  //// Quote.
  //iQuoteMode: Integer;
  //
  //Function FoundItem_saToken(p_sa:AnsiString;p_bCaseSensitive:Boolean):Boolean;
  //Function FNextItem_saToken(p_sa:AnsiString;p_bCaseSensitive:Boolean):Boolean;
  /////------------------------------------------

  if bOk then
  begin
    saFolder:='';
    repeat
      bDoneWithLine:=false;
      try
        readln(f,sa);
      except on e:exception do
      begin
        bOk:=false;
        BUError(201607070125,'readln(f,sa): '+sa);
      end;//except
      end;//try
      u2IOResult:=ioresult;bOk:= bOk and (u2IOResult=0);
      if not bOk then
      begin
        BUError(201511252017,'IOResult: '+inttostr(u2IOREsult)+' '+
          sIOResult(u2IOREsult)+'. Trouble reading from file: '+
          p_saSrcfile);
      end;

      if bOk then
      begin
        if not gbOptQuiet then write('-');
        TK.Tokenize(sa);
        if tk.movefirst then
        begin
          saDate:='';saOwner:='';saGrp:='';
          repeat
            saTemp:=TK.Item_saToken;
            //riteln('TOP OF LINE TOKEN LOOP - folder: '+saFolder);
            if tk.N = 1 then
            begin
              if rightstr(saTemp,1)=':' then
              begin
                saTemp:=LeftStr(saTemp,length(saTemp)-1);
                if leftStr(saTemp,1)='.' then saTemp:=rightStr(saTemp,length(saTemp)-1);
                saFolder:=saTemp;
                //if not gbOptQuiet then riteln(' Dir: ',saFolder);
                bDoneWithLine:=true;
              end else

              if saTemp='total' then
              begin
                //riteln('Got Total Line. Note Folder: '+saFolder);
                // This guy does not pay so skip him!
                //if not gbOptQuiet then riteln(' Skipping disk space value.');
                bDoneWithLine:=true;
              end else

              if (LeftStr(saTemp,1)='-') or
                 (LeftStr(saTemp,1)='d') then
              begin
                //if not gbOptQuiet then riteln(' [Permissions]');
                //rite(LeftStr(saTemp,1),' ');
                //riteln('Got file entry. Note Folder: '+saFolder);
                // The read bit adds 4 to its total (in binary 100),
                // The w rite bit adds 2 to its total (in binary 010), and
                // The execute bit adds 1 to its total (in binary 001).
                // drwxr-xr-x.
                p1:=0;p2:=0;p3:=0;
                if saTemp[ 2]='r' then p1+=4;
                if saTemp[ 3]='w' then p1+=2;
                if saTemp[ 4]='x' then p1+=1;

                if saTemp[ 5]='r' then p2+=4;
                if saTemp[ 6]='w' then p2+=2;
                if saTemp[ 7]='x' then p2+=1;

                if saTemp[ 8]='r' then p3+=4;
                if saTemp[ 9]='w' then p3+=2;
                if saTemp[10]='x' then p3+=1;

              end;
            end else

            if (TK.N=3) then
            begin
              // CHOWN
              //if not gbOptQuiet then riteln(' [OWNER]');
              saOwner:=saTemp;
            end else

            if (TK.N=4) then
            begin
              // CHGRP
              //if not gbOptQuiet then riteln(' [GROUP]');
              saGrp:=saTemp;
            end else

            if (TK.N=6) then
            begin
              // 2015-11-22
              saDate:=saTemp;
            end else

            if (TK.N=7) then
            begin
              // 11:14:08.924114088
              saDate+=' '+LeftStr(saTemp,8);
            end else

            if (TK.N=8) then
            begin
              // -0500
              saDate+=saTemp;
            end else

            if (TK.N=9) then
            begin
              //riteln('p_saWorkDir+saFolder+saTemp: >',p_saWorkDir,'< >',saFolder,'< >',saTemp);
              if fileexists(p_saWorkDir+saFolder+saTemp) then
              begin
                saCMD:='chown '+saOwner+' '+p_saWorkDir+saFolder+saTemp;
                u2ShellREsult:=u2ExecuteShellCommand('.',saCMD);
                bOk:=(u2ShellREsult=32767) or (u2ShellREsult=0);
                if not bOk then
                begin
                  BUError(201511262121,'CHMOD Failure. Result: '+
                    inttostr(u2ShellREsult)+' CMD: '+saCMD);
                end;

                if bOk then
                begin
                  saCMD:='chgrp '+saGrp+' '+p_saWorkDir+saFolder+saTemp;
                  u2ShellREsult:=u2ExecuteShellCommand('.',saCMD);
                  bOk:=(u2ShellREsult=32767) or (u2ShellREsult=0);
                  if not bOk then
                  begin
                    BUError(201511262122,'Command Shell Result: '+
                      inttostr(u2ShellREsult)+' CMD: '+saCMD);
                  end;
                end;

                if bOk then
                begin
                  // DO NOT ATTEMPT TO PROPAGATE COMMAND LINE STUFF ALLOWING
                  // EVEN AND ACCIDENTAL * (wildcard) ...its a gut thing. :)
                  if (pos('*',saTemp)=0) then
                  begin
                    //riteln('tk.n=9 File: '+p_saWorkDir+'-+-'+saFolder+'-+-'+saTemp);
                    if fileexists(p_saWorkDir+saFolder+saTemp) then
                    begin
                      saCmd:='chmod '+inttostr((p1*100)+(p2*10)+p3)+
                        ' "'+p_saWorkDir+saFolder+saTemp+'"';

                      u2ShellREsult:=u2ExecuteShellCommand('.',saCMD);
                      //if not gbOptQuiet then write('CMD: '+saCMD);
                      //riteln(p_saWorkDir+'-=-'+saFolder+'-=-'+saTemp);
                      bOk:=(u2ShellREsult=32767) or (u2ShellREsult=0);
                      if not bOk then
                      begin
                        BUError(201511252121,'Command Shell Result: '+
                          inttostr(u2ShellREsult)+' CMD: '+saCMD);
                      end;

                      //if bOk then
                      //begin
                        // parsed date format - raw text
                        // 2015-11-22 11:14:07-0500
                        // saDate - contains that
                        //---
                        //  FROM FORMAT for JDATE
                        //---
                        //Const csDateFormat_11='YYYY-MM-DD HH:NN:SS';
                        //const cnDateFormat_11=11; //<11 '2005-01-30 14:15:12'
                        //
                        //Const csDateFormat_00='?';
                        //const cnDateFormat_00=0;//< 0 for when you pass DATE OBJECT, use this as format in, just so routine doesn't kick you out.
                        //JDate(LeftStr(saDate,19),cnDateFormat_00,cnDateFormat_11,dt);
                        //u2IOResult:=FileSetDate(p_saWorkDir+saFolder+saTemp,DateTimeToFileDate(dt));
                        //bOk:= 0 = u2IOResult;
                        //if not bOk then
                        //begin
                        //  BUError(201511262118,'Setting File Date to '+saDate+
                        //    ' Error code: '+inttostr(u2IOResult)+' '+
                        //    sIOResult(u2ShellREsult));
                        //end;
                      //end;
                    end
                    else
                    begin
                      bDoneWithLine:=true;
                    end;
                  end;
                //riteln('CMD:',saCMD);
                end;
              end;
            end;
            //riteln('saFolder Persist:',saFolder);
          until (bDoneWithLine) or (not tk.movenext);
          //riteln;
        end;
        //if not gbOptQuiet then //riteln;
        tk.deleteall;
      end;
    until (not bOK) or eof(f);
    {I$-}
    if bOpen then close(f);
    {$I+}
  end;
  TK.Destroy;
  writeln;
  result:=bOk;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================
{$ENDIF}



































//=============================================================================
function bBackUpRecursiveDive(p_saSrcDir: ansistring; p_saDestDir: ansistring): boolean;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='bBackUpRecursiveDive';{$ENDIF}
var
  bOk: boolean;
  SrcDir:  JFC_DIR;
  DestDir: JFC_DIR;
  DeathSquad: JFC_DIR;
  u2IOResult: word;
  //u2ShellREsult: integer;
  saSrcFilename: ansistring;
  saDestFilename: ansistring;
  saDestPathNFile: ansistring;
  sa: ansistring;
  i: integer;
  bDestinationExists: boolean;
  dtSrcFile:  TDATETIME;
  dtDestFile: TDATETIME;
  bSkip: boolean;
  i4Rev: longint;  

  dir:string;
  name: string;
  ext: string;
  u8Time: UInt64;
  u8SrcfileSize : uint64;
  u8DestfileSize: uint64;
  bDupe: boolean;
  CRC64A, CRC64B: UInt64;
  sSlash: string[1];
  {$IFDEF HASFTP}
  TK: JFC_TOKENIZER;
  saCmd: ansistring;
  dt:tdatetime;
  //ts: TTimeStamp;
  bServerSrcDir: boolean;
  //iPos: longint;
  bDirOpened: Boolean;
  {$ENDIF}


label tryagain;

begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  bOk:=true;
  {$IFDEF DEBUG_MESSAGES}writeln('---');writeln('201601101108 - p_saSrcDir: >'+p_saSrcDir+'<');{$ENDIF}
  {$IFDEF DEBUG_MESSAGES}writeln('201601101107 - p_saDestDir: >'+p_saDestDir+'<');{$ENDIF}

  if leftstr(p_saSrcDir,1)='"' then p_saSrcDir:=rightstr(p_saSrcDir,length(p_saSrcDir)-1);
  if rightstr(p_saSrcDir,1)='"' then p_saSrcDir:=leftstr(p_saSrcDir,length(p_saSrcDir)-1);
  if leftstr(p_saDestDir,1)='"' then p_saDestDir:=rightstr(p_saDestDir,length(p_saDestDir)-1);
  if rightstr(p_saDestDir,1)='"' then p_saDestDir:=leftstr(p_saDestDir,length(p_saDestDir)-1);

  if (p_saSrcDir='.') or (LEftStr(p_saSrcDir,3)='..'+DOSSLASH) then p_saSrcDir:=FExpand(p_saSrcDir);
  if (p_saDestDir='.') or (LEftStr(p_saDestDir,3)='..'+DOSSLASH) then p_saDestDir:=FExpand(p_saDestDir);

  p_saSrcDir:=saAddSlash(p_saSrcDir);
  p_saDestDir:=saAddSlash(p_saDestDir);

  {$IFDEF DEBUG_MESSAGES}writeln('---');writeln('p_saSrcDir after processing >'+p_saSrcDir+'<');{$ENDIF}
  {$IFDEF DEBUG_MESSAGES}writeln('p_saDestDir after processing >'+p_saDestDir+'<');writeln('---');{$ENDIF}


  //---------------------------------------------------------------------------
  // BEGIN - SERVER KEY, DIRECTORY RETRIEVAL HANDSHAKE
  //---------------------------------------------------------------------------
  //riteln('begin dive nest:',gi8NestLevel);
  //riteln('src:',p_saSrcDir,' --> Dest:',p_saDestDir);
  {$IFDEF HASFTP}
  //riteln(' serveris:',gsaRemoteServerIs);
  bDirOpened:=false;
  if (gi8NestLevel=0) then
  begin
    if (giRemoteServerIs<>cnRS_None) then
    begin
      //riteln('level zero');
      TFTP:=TTFTPSend.Create;
      TFTP.TargetHost := gsaIP;
      TFTP.TargetPort := gsaPort;
      if not gbOptQuiet then writeln('Server: ' + TFTP.TargetHost+':'+TFTP.TargetPort);
      saCmd:=gsaKeyFile+'.jbu000';
      try
        try
          if not gbOptQuiet then writeln('Loading: '+saCmd);
          TFTP.Data.LoadFromFile(saCmd);
        finally
        end;//try
      Except On EInOutError do begin
        bOk:=false; BUError(201512201701,'IO Error attempting to load: '+saCmd);
      end;//except
      On EFOpenError do begin
        bOk:=false; BUError(201512300522,'Open Error attempting to load: '+saCmd);
      end;
      end;//try

    
      if bOk and (giRemoteServerIs<>cnRS_None) then
      begin
        try
          try
            //riteln('try to send it');
            if TFTP.SendFile(saCmd) then if not gbOptQuiet then writeln('File Sent.');
            //riteln('we made it past sendfile');
          finally
          end;//try
        Except on EAccessViolation do begin
          bOk:=false; // KABOOM lol
          BUError(201607070126,'TFTP.SendFile(saCMD):'+saCMD);
        end;//except
        end;//try
        bOk:= bOk and (TFTP.ErrorCode=0);
        if bOk then
        begin
          if not gbOptQuiet then Writeln('Server Key Sent.');
        end
        else
        begin
          writeln('Key file invalid or server unreachable.');
          BUError(201512201640,'Indicated server key is invalid or could not be sent to the server.');
        end;
      end;
      
      if bOk then
      begin
        if (giRemoteServerIs<>cnRS_None) then
        begin
          if (gbOptCrc and gbOptRecurse) then saCmd:='rdircrc' else
          if (gbOptCrc and (gbOptRecurse=false)) then saCmd:='dircrc' else
          if ((gbOptCrc=false) and gbOptRecurse) then saCmd:='rdir' else saCmd:='dir';
          bOk:=bSaveFile(csTempFile,p_saSrcDir,1,1000,u2IOResult,false);
          if not bOk then
          begin
            BUError(201512300737,'Unable to save '+csTempFile+' file');
          end;
      
          if bOk then
          begin
            //riteln('b4 using tftp. Nil? ',saYesNo(TFTP=nil));
            TFTP.Data.LoadFromFile(csTempFile);
            //riteln('past first use using tftp');
            if not gbOptQuiet then writeln('Requesting server directory.');
            while not (TFTP.SendFile(saCMD+'.jbucmd') and (TFTP.ErrorCode=0))or
                      ((gbOptWait=false) and (iDiffMSec(dtStart,Now)>gu8ServerTimeOut)) do
            begin
              yield(1000);
              if not gbOptQuiet then write('.');
            end;
      
            bOk:= TFTP.ErrorCode = 0;
            if not bOk then
            begin
              BUError(201512300912,'FTP Error Code: '+saFTPError(TFTP.ErrorCode)+' '+TFTP.ErrorString);
            end;
      
            if not gbOptQuiet then
            begin
              if not bOK then writeln('Error. Unable to connect to server.')
              else writeln('Success. The server is generating your directory.');
            end;
            //riteln('b4 a delete of csDirFilename:'+csDirFilename);
            try
              deletefile(csDirFilename);//mightneedatry- dunno
            except on E:Exception do begin
              BUError(201607070123,'deletefile(csDirFilename): '+csDirFilename);
            end;//except
            end;//try

            //riteln('after a delete');
            if not gbOptQuiet then
            begin
              writeln(saRepeatChar('=',79));
              writeln('Executed: '+saCMD+'.jbucmd');
              writeln(saRepeatChar('=',79));
            end;
          end;
      
          if bOk then
          begin
            TFTP.Destroy;//trying a reset of sorts - big hammer  :)
            TFTP:=TTFTPSend.Create;
            TFTP.TargetHost := gsaIP;
            TFTP.TargetPort := gsaPort;
            TFTP.Data.Clear;
            if not gbOptQuiet then writeln('Waiting for server to generate the directory.');
            while not (TFTP.RecvFile('directory.jbures') and (TFTP.ErrorCode=0) and (TFTP.data.size>0)) or
                      ((gbOptWait=false) and (iDiffMSec(dtStart,Now)>gu8ServerTimeOut)) do
            begin
              yield(1000);//.. just give server a second before we annoy JEGAS He is a grumpy fkr
            end;
            TFTP.Data.SaveToFile(csDirFilename);
            bOk:=(TFTP.Data.Size>0) and
                 (uFileSize(csDirFilename)>0);
            if not bOk then
            begin
              BUError(201512201925,'Unable to get the server''s directory information.');
            end;
          end
          else
          begin
            BUError(2015121754,'Unable to complete request for the server directory.');
          end;
          if bOk then
          begin
            if not gbOptQuiet then
            begin
              writeln('Directory should be getting generated now on the server.');
              writeln('When available, GET '+csDirFilename + ' to get the results.');
            end;
          end;
        end;
      
        if bOk then
        begin
          Assign(fDir,csDirFilename);
          u2IOResult:=ioResult;
          bOk:=u2IOResult=0;bDirOpened:=bOk;
          if not bOk then
          begin
            BUError(201512222237,'Unable to assign filehandle to directory.jbures. IO Result: '+sIOResult(u2IOResult));
          end;
        end;
      
        if bOk then
        begin
          try
            reset(fDir);//read mode
          except on E:Exception do bOk:=false;
            BUError(201607070127,'reset(fDir): '+csDirFilename);
          end;//try
          u2IOResult:=ioResult;
          bOk:=bOk and (u2IOResult=0);
          if not bOk then
          begin
            BUError(201512222238,'Unable to reset directory.jbures. IO Result: '+sIOResult(u2IOResult));
          end;
        end;
      
        if bOk then // here is the top part of the trick - we used to just read the harddrive dir,
        begin       // this is where I am injecting a fraud lol - data from the other system's drive.
          // ------- Read past Header -------------
          for i:=1 to 13 do
          begin
            try
              readln(fDir,sa);
            except on E:Exception do bOk:=false;
              BUError(201607070128,'readln(fdir,sa):'+sa);
            end;//try
            u2IOResult:=ioresult;
            bOk:=bOk and (u2IOResult=0);
            if not bOk then exit;
          end;
          // ------- Read past Header -------------
          if bOk then
          begin
            try
              readln(fDir,sa);
            except on E:Exception do bOk:=false;
              BUError(201607070129,'readln(fDir,sa):'+sa);
            end;//try
            u2IOREsult:=ioresult;
          end;// Grab First DIR
          if not bOk then
          begin
            BUError(201512222239,'Error while reading directory.jbures. IO Result: '+sIOResult(u2IOResult));
          end;
        end;
      end;
    end;
  end;
  //---------------------------------------------------------------------------
  // END - SERVER KEY, DIRECTORY RETRIEVAL HANDSHAKE
  //---------------------------------------------------------------------------
  {$ENDIF}


  //---------------------------------------------------------------------------
  // BEGIN - Verify Src/Dest Directories Exist
  //---------------------------------------------------------------------------
  if bOk then
  begin
    if (gi1Mode=cnJB_Backup) or (gi1Mode=cnJB_Copy) or (gi1Mode=cnJB_Move) or
        (gi1Mode=cnJB_Sync) or (gi1Mode=cnJB_Pull) or (gi1Mode=cnJB_Prune) then
    begin
      {$IFDEF HASFTP}
      if giRemoteServerIs<>cnRS_Src then
      begin
      {$ENDIF}
        bOk:=DirectoryExists(gsaParam1);
        if not bOk then
        begin
          if not gbOptQuiet then BUError(201512201641,'Source directory does NOT exist or is not available: '+gsaParam1);
        end;
      {$IFDEF HASFTP}
      end
      else
      begin
        // remote server is the source
      end;
      {$ENDIF}
    end;

    if bOk then
    begin
      if (gi1Mode=cnJB_Backup) or (gi1Mode=cnJB_Copy) or (gi1Mode=cnJB_Move) or
          (gi1Mode=cnJB_Sync) or (gi1Mode=cnJB_Pull) then // prune's param1 = "DESTINATION" of operation
      begin
        {$IFDEF HASFTP}
        if giRemoteServerIs<>cnRS_Dest then
        begin
        {$ENDIF}
          //--- Try to make dir if its not already there; THEN REQUIRE IT EXIST
          if not DirectoryExists(gsaParam2) then
          begin
            bok:=CreateDir(gsaParam2);//maybe add multiple creates for multi level   requests
            if not bOk then
            begin
              BUError(201601022219,'Create Directory Failed: '+gsaPAram2);
            end;
          end;

          if bOk then
          begin
            bOk:=DirectoryExists(gsaParam2);
            if not bOk then
            begin
              BUError(201512201642,'Destination directory does NOT exist or is unavailable: '+gsaParam2);
            end;
          end;



        {$IFDEF HASFTP}
        end
        else
        begin
          // remote server is dest
        end;
        {$ENDIF}
      end;
    end;
  end;
  //---------------------------------------------------------------------------
  // END - Verify Src/Dest Directories Exist
  //---------------------------------------------------------------------------



//riteln('5');



  //---------------------------------------------------------------------------
  // TODO - This is the openheart surgery to mix remote server and client
  //        so they are seamless. Same syntax for local and remote.
  //---------------------------------------------------------------------------

  // !#! ACTUAL START OF Process after Server Wedge Stuff completed (if server called upon)
  if (gi8NestLevel>0) or ((gi8NestLevel=0) and bOk) then
  begin
    //-------------------------------------------------------------------------
//riteln('5.4');
    //if not gbOptQuiet then riteln('p_saSrcDir: >'+p_saSrcDir+'< p_saDestDir: >'+p_saDestDir+'<');
    SrcDir :=JFC_DIR.create;
    DestDir:=JFC_DIR.Create;
    DeathSquad:=JFC_DIR.Create;
    i:=0;
    bOk:=true;bOk:=bOk;//shutup compiler for now
    //remove quotes if there

    //if rightstr(p_saSrcDir,1)<>csDosslash then p_saSrcDir+=csDosslash;
    //if rightstr(p_saDestDir,1)<>csDosslash then p_saDestDir+=csDosslash;



//riteln('5.5');
    //if not gbOptQuiet then riteln('p_saSrcDir: >'+p_saSrcDir+'< p_saDestDir: >'+p_saDestDir+'<');
    with SrcDir do begin
      saPath:=p_saSrcDir;
      bDirOnly:=false;
      saFileSpec:='*';
      bSort:=true;
      bSortAscending:=true;
      //bSortCaseSensitive:=true;//faster
      //Procedure oadDir;
      //Procedure PreviousDir;
    end;//with
    with DestDir do begin
      saPath:=p_saDestDir;
      //riteln('Dest Path:' + saPath);
      bDirOnly:=false;
      saFileSpec:='*.jbu*';
      bSort:=true;
      bSortAscending:=false;
      bSortCaseSensitive:=true;//faster
      //Procedure oadDir;
      //Procedure PreviousDir;
    end;
    with DeathSquad do begin
      saPath:=p_saDestDir;
      bDirOnly:=false;
      saFileSpec:='*';
      bSort:=false;
      //bSortAscending:=true;
      //bSortCaseSensitive:=true;//faster
      //Procedure oadDir;
      //Procedure PreviousDir;
    end;//with


    //-------------------------------------------------------------------------

//riteln('6');

    //-------------------------------------------------------------------------
    // SERVER IS THE SOURCE, IN THIS SITUATION (vs Server being destination)
    // WE Load the DIR and load it into the same exact class used to read the
    // directories of harddrives. Hopefully we can make it so we get code that
    // works on both server and client a little :) Save some work, ease mgt.
    //-------------------------------------------------------------------------
    if bOk then
    begin
      //riteln('Loading Source Directory');
      {$IFDEF HASFTP}
      if (giRemoteServerIs = cnRS_Src) then
      begin
        Readln(fDir,sa);SrcDir.saPAth:=sa;
        {$IFDEF DEBUG_MESSAGES}writeln('Remote Server Is the Source. SrcDir.saPath now:'+SrcDir.saPath);{$ENDIF}
        TK:=JFC_TOKENIZER.create;
        TK.saSeparators:=' '+#13+#10;
        TK.saQuotes:='"';
        TK.saWhiteSpace:=' ';
        repeat
          bServerSrcDir:=false;
          Readln(fDir,sa);
          if (length(sa)>0) and ((sa[1]='D')or(sa[1]='-')) then
          begin
            sa:=saSNRStr(sa,'\"','[@TEMPQUOTE@]');
            if not gbOptQuiet then writeln(sa);
            TK.Tokenize(sa);
            bOk:=TK.MoveFirst;
            if bOk then // GRAB File Attributes We Include using the key
            Begin       // in saGetDir function this jbu source file
              SrcDir.AppendItem;
              sa:=TK.Item_saToken;
              //riteln('Tk 1:',TK.Item_saToken);
              bOk:=length(sa)=6;
              if not bok then
              begin
                BUError(201512222254,'Attribute token is the wrong length:>'+sa+'<');
              end;
            end;
      
      
      
            if bOk then
            begin
              JFC_DIRENTRY(SrcDir.Item_lpPtr).u1Attr:=0; // D=Dir R=ReadOnly H=Hidden S=SysFile V=VolumeID A=Archive
              if sa[1]='D' then JFC_DIRENTRY(SrcDir.Item_lpPtr).u1Attr+=directory;
              if sa[2]='R' then JFC_DIRENTRY(SrcDir.Item_lpPtr).u1Attr+=Readonly;
              if sa[3]='H' then JFC_DIRENTRY(SrcDir.Item_lpPtr).u1Attr+=hidden;
              if sa[4]='S' then JFC_DIRENTRY(SrcDir.Item_lpPtr).u1Attr+=sysfile;
              if sa[5]='V' then JFC_DIRENTRY(SrcDir.Item_lpPtr).u1Attr+=volumeid;
              if sa[6]='A' then JFC_DIRENTRY(SrcDir.Item_lpPtr).u1Attr+=archive;
              bOk:=TK.MoveNext;
              if not bOk then
              begin
                BUError(201512211129,'Directory Failed to parse date. Entry: '+SrcDir.saPath);
              end;
            end;
      
            if bOk then // GRAB YYYY-MM-DD DATE Token
            begin
              sa:=TK.Item_saToken+' ';
              //riteln('Tk 2:',TK.Item_saToken);
              bOk := TK.MoveNext;
              if not bOk then
              begin
                BUError(201512211130,'Directory Failed to parse time. Entry: '+SrcDir.saPath);
              end;
            end;
            
            if bOk then // GRAB HH:MM:SS Military Time Part Token
            begin
              sa+=TK.Item_saToken;
              //riteln('Tk 3:',TK.Item_saToken);
                                  // YYYY-MM-DD HH:MM:SS -> DATETIME VARIABLE (Our date routine geared for TDATETIME so.. yup - our tool!
              JDATE(sa,0,11,dt);  // 0=Means DATETIME variable type is giving or receiving a date
                                  // HEre,position seemsbackwards, is textin,date type out,date type in, datetime type incasewe need )
                                  // two ways to call, dont need use a dt variable if converting date text to another date text format
              JFC_DIRENTRY(SrcDir.Item_lpPtr).dtModified:=dt;
              bOk:=TK.MoveNext;
              if not bOk then
              begin
                BUError(201512211131,'Directory Failed to parse filesize. Entry: '+SrcDir.saPath);
              end;
            end;
            
            if bOk then
            begin
              JFC_DIRENTRY(SrcDir.Item_lpPtr).u8Size:=u8Val(TK.Item_saToken);
              //riteln('Tk 4:',TK.Item_saToken);
              bOk:=TK.MoveNext;
              if not bOk then
              begin
                BUError(201512211132,'Directory Failed to parse CRC column. Entry: '+SrcDir.saPath);
              end;
            end;
            
            if bOk then
            begin
              JFC_DIRENTRY(SrcDir.Item_lpPtr).u8CRC:=u8Val(TK.Item_saToken);
              //riteln('Tk 5:',TK.Item_saToken);
              bOk:=TK.MoveNext;
              if not bOk then
              begin
                BUError(201512211133,'Directory Failed to parse filename. Entry: '+SrcDir.saPath);
              end;
              JFC_DIRENTRY(SrcDir.Item_lpPtr).saName:=saSNRStr(TK.Item_saToken,'\"','[@TEMPQUOTE@]');
            end;
          end
          else
          begin
            bServerSrcDir:=true;
          end;
        until (not bOk) or EOF(fDir) or bServerSrcDir;
        //riteln('Leaving server dir load loop - bok:',saYesNo(bOk),' EOF(fDir):',saYesNo(eof(fdir)),'bServerSrcDir:',saYesNo(bServerSrcDir),'count:',srcdir.listcount);
        TK.Destroy;TK:=nil;
      end
      else
      begin
      {$ENDIF}
        {$IFDEF DEBUG_MESSAGES}writeln('BEGIN - 201607061909 - SrcDir.saPath right before loaddir call:'+srcDir.saPath);{$ENDIF}
        {$IFDEF DEBUG_MESSAGES}SrcDir.bOutput:=true;{$ENDIF}
        SrcDir.LoadDir;
        {$IFDEF DEBUG_MESSAGES}writeln('END - 201607061909 - SrcDir.saPath right before loaddir call:'+srcDir.saPath);{$ENDIF}
      {$IFDEF HASFTP}
      end;
      {$ENDIF}
      {$IFDEF DEBUG_MESSAGES}writeln('Loading Source Directory - FINISHED bOk:',bOk, ' Listcount: ',SrcDir.ListCount);{$ENDIF}
    end;

    //riteln('after srcdir loaded - bOk:',bOk, ' SrcDir.ListCount:',SrcDir.ListCount);
    if bOk then
    begin
      //riteln('Loading Destination Directory');
      {$IFDEF HASFTP}
      if giRemoteServerIs = cnRS_Dest then
      begin
        // TODO: Gather Server DIR Info and use to populate DestDir
      end
      else
      begin
      {$ENDIF}
        {$IFDEF DEBUG_MESSAGES}writeln('BEGIN - 201607061910 - DestDir.saPath right before loaddir call:'+srcDir.saPath);{$ENDIF}
        {$IFDEF DEBUG_MESSAGES}DestDir.bOutput:=true;{$ENDIF}
        DestDir.LoadDir;
        {$IFDEF DEBUG_MESSAGES}writeln('END - 201607061910 - DestDir.saPath right before loaddir call:'+srcDir.saPath);{$ENDIF}
        {$IFDEF DEBUG_MESSAGES}DestDir.bOutput:=true;{$ENDIF}
        if gbOptRetire or gbOptDestructive then DeathSquad.LoadDir;

//        if not FileExists(p_sadestdir) then
        //riteln('------===== Dir Exists =====----------');
        //riteln('DirectoryExists(p_sadestdir) DirectoryExists('+p_sadestdir+'):'+sYesNo(DirectoryExists(p_sadestdir)));
        //riteln('------===== Dir Exists =====----------');
        if not DirectoryExists(p_sadestdir) then
        begin
          if not gbOptDestructive then
          begin
            bOk:=createdir(p_sadestdir);
            if not bOk then
            begin
              BUError(201612021739,'Create Directory Failed: '+p_saDestDir);
            end;
          end;
        end;

        if bOk and not (gbOptDestructive or gbOptRetire) then
        begin
          try
            u8Time:=FileAge(p_saSrcDir);
          except on E:EConvertError do begin
            BUError(201607070130,'FileAge(p_saSrcDir): '+p_saSrcDir);
          end;//except
          end;//try

          try
            FileSetDate(p_sadestdir,u8Time);
          except on E:EConvertError do begin
            BUError(201607070131,'FileSetDate(p_sadestdir,u8Time): '+p_saDestDir);
          end;//except
          end;//try
        end;
        {$IFDEF HASFTP}
      end;
      {$ENDIF}
      //riteln('Loading Destination Directory - FINISHED');

      //riteln('---------------------------------------');
      //riteln('top srcdir loop - bOk:',bOk);
      if SrcDir.movefirst then
      begin
        repeat
          {$IFDEF DEBUG_MESSAGES}writeln('loop begin >',srcdir.Item_saName,'<');{$ENDIF}
          bOk:=true;
          bDupe:=false;
          bSkip:=false;
          if ((srcdir.Item_saName='.') or (srcdir.Item_saName='..') or (srcdir.Item_saName='')) then
          begin
            // skip it
            //riteln('Skipping > '+srcdir.Item_saName+'<');
            // bOK could chnage here some time?
          end else
          //riteln('DIR?: ',saYesNo(SrcDir.Item_bDir));
          //riteln('ITEM: ',SrcDir.Item_saName);
          //or here

          if bOk then
          begin
            sSlash:=RightStr(SrcDir.Item_saName,1);
            if (SrcDir.Item_bDir) or (sSlash='/') or (sSlash='\') then
            begin
              //-------------------------
              // begin - SUB DIR RELATED
              //-------------------------
              if gbOptRecurse then
              begin
                bOk:=gi8NestLevel<cnMaxNestLevel;
                sa:=trim(SrcDir.Item_saName);
                if bOk and (not bSkip) then
                begin
                  gi8NestLevel+=1;
                  gu8Count_Dir+=1;
                  {$IFDEF HASFTP}
                  if giRemoteServerIs<>cnRS_Src then
                  begin
                  {$ENDIF}
                
                    {$IFDEF DEBUG_MESSAGES}
                    writeln;
                    writeln(saRepeatChar('=',80));
                    writeln('================ 201601101110');
                    writeln('--> Dive (    p_saSrcDir    +    SrcDir.Item_saName    ,    p_saDestDir    +    SrcDir.Item_saName    );');
                    writeln('--> Dive(''',p_saSrcDir ,'''+''',SrcDir.Item_saName,''','''+p_saDestDir+'''+''',SrcDir.Item_saName,''');');
                    writeln('NestLevel          : ' , gi8NestLevel);
                    writeln('================');
                    //readln;
                    {$ENDIF}
                    bOk:=bBackUpRecursiveDive(p_saSrcDir+SrcDir.Item_saName,p_saDestDir+SrcDir.Item_saName);
                    {$IFDEF DEBUG_MESSAGES}
                    writeln('================');
                    writeln('<-- bBackUpRecursiveDive dive');
                    writeln('================');
                    writeln(saRepeatChar('=',80));
                    writeln;
                    {$ENDIF}

                  {$IFDEF HASFTP}
                  end;
                  {$ENDIF}
                end;


                if bOk then
                begin
                  if gi1Mode=cnJB_Move then
                  begin
                    {$IFDEF HASFTP}
                    if giRemoteServerIs = cnRS_Src then
                    begin
                      //TODO: remove remote dir
                    end
                    else
                    begin
                    {$ENDIF}
                      //riteln('B DESTROYDIR('+p_sasrcDir+SrcDir.Item_saName+')');
                      DESTROYDIRECTORY(p_sasrcDir+SrcDir.Item_saName);
                    {$IFDEF HASFTP}
                    end;
                    {$ENDIF}
                  end;
                end;

                gi8NestLevel-=1;

                {$IFDEF HASFTP}
                if giRemoteServerIs = cnRS_Src then
                begin
                  u8Time:=UInt64(JFC_DIRENTRY(SrcDir.Item_lpPtr).dtModified);
                end
                else
                begin
                {$ENDIF}
                  try
                    //riteln('Checking Age of (B): ',p_saSrcDir);
                    u8Time:=FileAge(p_sasrcDir+SrcDir.Item_saName);
                    //riteln('Age check (b) successful');
                  except on E:EConvertError do begin
                    //riteln('Unable to read date from: ',p_saSrcDir);
                    BUError(201607070132,'FileAge(p_sasrcDir+SrcDir.Item_saName): >'+p_saSrcDir+'< + >'+SrcDir.Item_saName);
                  end;//except
                  end;//try
                {$IFDEF HASFTP}
                end;
                {$ENDIF}
                if not (gbOptDestructive or gbOptRetire) then
                begin
                  FileSetDate(p_sadestdir+srcdir.item_saname,u8Time);
                end;
              end;
              // ----------------------------------
              // end SUB DIR RELATED
              //-----------------------------------
            end
            else
            begin
              {$IFDEF DEBUG_MESSAGES}
              writeln(saRepeatChar('=',80));
              writeln('201601101111');
              writeln('SOURCE FILENAME p_sasrcDir: ',p_sasrcDir);
              writeln('SOURCE FILENAME SrcDir.Item_saName: ',SrcDir.Item_saName);
              {$ENDIF}
              //saSrcFilename:=p_sasrcDir+SrcDir.Item_saName;
              saSrcFilename:=SrcDir.Item_saName;
              {$IFDEF DEBUG_MESSAGES}
              writeln('SOURCE FILENAME saSrcFilename: ',saSrcFilename);
              writeln('SOURCE FILENAME p_saDestDir: ',p_saDestDir);
              {$ENDIF}
              saDestFilename:=p_saDestDir+srcdir.Item_saName;
              {$IFDEF DEBUG_MESSAGES}
              writeln('SOURCE FILENAME saDestFilename p_saDestDir+srcdir.Item_saName: ',saDestFilename);
              writeln(saRepeatChar('=',80));write('[enter]:');
              //readln;
              {$ENDIF}

              u8SrcfileSize:=JFC_DIRENTRY(SrcDir.Item_lpPtr).u8Size;
              dtSrcFile:=JFC_DIRENTRY(SrcDir.Item_lpPtr).dtModified;

              //----
              // !!! Begin - NOTE: THIS CODE PRESUMES bSkip = FALSE on ENTRY!!!!!!
              //----
              //riteln('------------======== FileExists ======-------------------');
              //riteln('fileexists(saDestFilename) fileexists('+saDestFilename+'):'+sYesNo(fileexists(saDestFilename)));
              //riteln('------------======== FileExists ======-------------------');
              bDestinationExists:=fileexists(saDestFilename) and (gi1Mode<>cnJB_Copy);
              if bDestinationExists then
              begin
                dtDestFile:=TDATETIME(0);
                u8DestFileSize:=0;
                bSkip:=not bGetFileModifiedDate(saDestfilename,dtDestFile);
                if bSkip then
                begin
                  u2IOResult:=0;
                  BUError(201601141643,'Unable to access destination file''s date. IOResult: '+sIOResult(u2ioresult,cnLANG_ENGLISH)+' Destination: '+sa);
                end
                else
                begin
                  try
                    u8DestFileSize:=u8FileSize(saDestfilename);
                  except on E:Exception do
                  begin
                    bSkip:=true;u2IOResult:=0;
                    BUError(201601141459,'Unable to access destination file''s size. IOResult: '+sIOResult(u2ioresult,cnLANG_ENGLISH)+' Destination: '+sa);
                  end;//except
                  end;//try
                end;
              end;
              //----
              // !!! End   - NOTE: THIS CODE PRESUMES bSkip = FALSE on ENTRY!!!!!!
              //----

              {$IFDEF DEBUG_MESSAGES}
                writeln('Skip:',sYesNo(bSkip),' Dest File Exists: '+sYesNo(bDestinationExists)+' Src Date:',formatdatetime(csDATETIMEFORMAT,dtSrcFile),' Dest Date: ', formatdatetime(csDATETIMEFORMAT,dtDestFile),' src:'+saSrcFilename+'  Dest: '+saDestFilename);
              {$ENDIF}

              if gi1Mode=cnJB_Pull then
              begin
                FSplit(saSrcFilename,dir,name,ext);
                //riteln;
                //riteln('==');
                //riteln('ext:',ext);
                //riteln('==');
                //riteln;
                bSkip:=bSkip or ((length(ext)=7) and (saLeftstr(ext,4)='.jbu') and
                  ((ext[5]>='0') and (ext[5]<='9')) and
                  ((ext[6]>='0') and (ext[6]<='9')) and
                  ((ext[7]>='0') and (ext[7]<='9')));
              end;

tryagain:
              u2ioresult:=0;
              // =============================== DECIDE To VERSION OR COPY ===========================================
              // =============================== DECIDE To VERSION OR COPY ===========================================
              // =============================== DECIDE To VERSION OR COPY ===========================================
              // =============================== DECIDE To VERSION OR COPY ===========================================
              // Original before adding date etc to pull:  if bDestinationExists and ((gi1Mode=cnJB_Backup)or(gi1Mode=cnJB_Sync))  then
              if bDestinationExists and ((gi1Mode=cnJB_Pull)or(gi1Mode=cnJB_Backup)or(gi1Mode=cnJB_Sync))  then
              begin
                bDupe:=true; //UNDERSTAND: Dupe means PRESERVE before we write on it (collision would work too I guess?)
                if gbOptDate then
                begin
                  bSkip:=  bSkip or (dtSrcFile <= dtDestFile);
                  bDupe:=  bDupe or (dtSrcFile >  dtDestFile);
                  //riteln('DATE COMPARE SRC: '+FormatDateTime(csDATETIMEFORMAT,dtSrcFile)+' DEST: '+FormatDateTime(csDateTimeFormat,dtDestfile)+' Dupe (copy over it): '+sYesNo(bDupe)+' Skip: '+sYesno(bSkip));
                  //riteln('above writeln did not bomb - yay');
                end;

                if (not bSkip) and gbOptSize then
                begin
                  bSkip:=bSkip or (u8SrcfileSize =  u8DestFilesize) ;
                  bDupe:=bDupe or (u8SrcfileSize <> u8DestFilesize);
                end;

                if (not bSkip) and gbOptCRC then
                begin
                  {$IFDEF HASFTP}
                  if giRemoteServerIs=cnRS_Src then
                  begin
                    CRC64A:=JFC_DIRENTRY(SrcDir.Item_lpPtr).u8CRC;
                  end
                  else
                  begin
                  {$ENDIF}
                    //ritelN('About to Do CRC check on: ' + saAddSlash(p_saSrcDir)+saSrcFilename);
                    CRC64A:=u8GetCRC64(saAddSlash(p_saSrcDir)+saSrcFilename);
                    //riteln('CRC Check seems ok. Result: ',CRC64A);
                  {$IFDEF HASFTP}
                  end;
                  {$ENDIF}

                  {$IFDEF HASFTP}
                  if giRemoteServerIs=cnRS_Dest then
                  begin
                    CRC64B:=JFC_DIRENTRY(SrcDir.Item_lpPtr).u8CRC;
                  end
                  else
                  begin
                  {$ENDIF}
                    CRC64B:=u8GetCRC64(saDestFilename);
                  {$IFDEF HASFTP}
                  end;
                  {$ENDIF}
                  bSkip:=CRC64A=CRC64B;
                  bDupe:=CRC64A<>CRC64B;

                  {$IFDEF DEBUG_MESSAGES}
                  writeln('BEGIN ===CRC TEST=== 201601101112');
                  writeln('  CRC64A: ',CRC64A);
                  writeln('  CRC64B: ',CRC64B);
                  writeln('  bSkip : ',sYesNo(bSkip));
                  writeln('  bDupe : ',sYesNo(bDupe));
                  writeln('END ===CRC TEST===');
                  {$ENDIF}
                end;

                if bOk and (not bSkip) and bDupe then
                begin
                  FSplit(saDestFilename,dir,name,ext);
                  DestDir.saFilespec:=name+ext+'.jbu*';

                  {$IFDEF HASFTP}
                  if giRemoteServerIs=cnRS_Dest then
                  begin
                    //todo: load srdir like server source mode- try reuse
                    // directory handshake etc already working.
                  end
                  else
                  begin
                  {$ENDIF}
                    //riteln('Loading destination dir of jbu files');
                    DestDir.loaddir;
                    //riteln('Got that DirXDL loaded');
                  {$IFDEF HASFTP}
                  end;
                  {$ENDIF}

                  i:=1;
                  if DestDir.MoveFirst then
                  begin
                    repeat
                      i4Rev:= iVal(rightstr(destdir.item_saName,3));
                      if i4Rev>=i then i:=i4rev+1;
                    until not DestDir.MoveNext;
                  end;
                  sa:=saDestFilename+'.jbu'+sZeroPadInt(i,3);

                  {$IFDEF HASFTP}
                  if giRemoteServerIs=cnRS_Dest then
                  begin
                    //TODO: this is the backup file versioning bit on the remote server - dest
                    //bOk:=bSaveFile('directory.jbures',saData,1,1000,u2IOResult,false);
                    //bOk:=TFTP.RecvFile('delete.jbucmd') and (TFTP.ErrorCode=0);
                  end
                  else
                  begin
                  {$ENDIF}
                    try
                      //riteln('Checking Age of (C): ',saDestFilename);
                      u8Time:=FileAge(saDestFilename);
                    except on E:EconvertError do begin
                      //riteln('Failed reading Fileage of: '+saDestfilename);
                      BUError(201607070140,'FileAge(saDestFilename): '+saDestfilename);
                    end;//except
                    end;//try

                    // Try to continue - just because someone or something
                    // nulled out a directory date entry - bah - copy that thing!
                    // :) Then it will have a nice pretty date again! :)
                    bOk:=bmovefile(saDestFilename,sa);
                    try
                      //riteln('Trying to set the date of ' +sa);
                      FileSetDate(sa,u8Time);
                      //riteln('Trying to set the date of ' +sa+' WORKED! yay');
                    except on E:Exception do begin
                      //riteln('Trouble setting file date: '+sa);
                      BUError(201607070106,'FileSetDate Failed: '+sa);
                    end;//except
                    end;//try

                  {$IFDEF HASFTP}
                  end;
                  {$ENDIF}

                  if bok then
                  begin
                    gu8Count_Versioned+=1;
                  end
                  else
                  begin
                    if not gbOptQuiet then
                    begin
                      writeln;
                      BUError(201512150221,'Rename File Failed '+sIOResult(u2ioresult,cnLANG_ENGLISH)+
                        ' Source: '+saSrcFilename+' Destination: '+sa);
                      bOk:=true;bSkip:=true; gu8Count_BytesSkipped+=u8SrcfileSize;
                    end;
                  end;
                end
                else
                begin
                  gu8Count_BytesSkipped+=u8SrcfileSize;
                end;
              end;

              // =============================== DECIDE To VERSION OR COPY ===========================================
              // =============================== DECIDE To VERSION OR COPY ===========================================
              // =============================== DECIDE To VERSION OR COPY ===========================================
              // =============================== DECIDE To VERSION OR COPY ===========================================
              // riteln('end - Decide Ok:',saYesNo(bOK),' bSkip:'+saYesNo(bSkip)+' file: '+saSrcFilename);
              // riteln('p_saSrcDir:',p_saSrcDir,' SrcDir.Item_saName: ',SrcDir.Item_saName);

              if bok then
              begin
                if gi1Mode=cnJB_Sync then
                begin
                  FSplit(saSrcFilename,dir,name,ext);
                  if (length(ext)=7) and (saLeftStr(ext,4)='.jbu') then
                  begin
                    //riteln('extension len 7 - ',ext);
                    bSkip:=bSkip or ((ext[5] in ['0'..'9']) and
                           (ext[6] in ['0'..'9']) and
                           (ext[7] in ['0'..'9']));
                  end;
                end;

                //riteln('goober Skip:',sYesNo(bSkip),' Dest:',saDestFilename);
                if not bSkip then
                begin
                  //sa:=p_saSrcDir+SrcDir.Item_saName;
                  sa:=saAddSlash(p_saSrcDir)+saSrcFilename;
                  {$IFDEF DEBUG_MESSAGES}
                  writeln('=== saDestfilename parts - 201601101113');
                  writeln('=== COPY gsaParam2: >'+gsaParam2+'<');
                  writeln('=== COPY saDestFilename: >'+saDestFilename+'<');
                  writeln('=== sa: '+sa);
                  {$ENDIF}
                  saDestPathNFile:=saSNRStr(saDestFilename,'//','/');

                  if not gbOptQuiet then writeln(' COPY: '+sa + ' --> ' + saDestPathNFile);
                  //riteln('BEFORE COPY--------');
                  {$IFDEF HASFTP}
                  if giRemoteServerIs<>cnRS_Src then
                  begin
                  {$ENDIF}
                    //riteln('calling bCopyFile. sa>'+sa+'< saDestPathNFile>'+saDestPathNFile);
                    bOk:=bCopyFile(sa,saDestPathNFile,u2IOresult);
                    //riteln('Checking Age of (D): ',saDestPathNFile);
                    FileSetDate(saDestPathNFile,FileAge(sa));
                    //riteln('AFTER COPY-------- Ok? '+sYesNo(bOk));
                    if not bok then
                    begin
                      if not gbOptQuiet then writeln;
                      BUError(201512201643,'File Copy Error: '+sIOResult(u2ioresult,cnLANG_ENGLISH)+
                        ' Source: '+sa+' Destination: '+saDestPathNFile);
                      bSkip:=true;
                    end;
                  {$IFDEF HASFTP}
                  end
                  else
                  begin
                    //iPos:=pos('/',sa);
                    //if iPos<=0 then iPos:=pos('\',sa);
                    //if iPos>0 then sa:=Rightstr(sa,length(sa)-length(gsaKeyFile));
                    //sa:=p_saSrcDir+sa;

                    // FTP GET
                    if not gbOptQuiet then
                    begin
                      writeln('From ', gsaParam1,': ',sa,' --> ',saDestPathNFile);
                    end;
                    bOk:=(TFTP.RecvFile(sa) and (TFTP.ErrorCode=0)) or (TFTP.ErrorCode=0);
                    if not bOk then
                    begin
                      BUError(201512272206,'Trouble receiving from server: '+sa);
                      bSkip:=true;
                    end;

                    if bOk then
                    begin
                      try
                        TFTP.Data.SaveToFile(saDestPathNFile);
                      except on E:Exception do begin
                        bOk:=false;
                        BUError(201607070141,'TFTP.Data.SaveToFile(saDestPathNFile): '+saDestfilename);
                      end;
                      if not bOk then
                      begin
                        BUError(201601011142,'File Creation Error: '+sIOResult(u2ioresult,cnLANG_ENGLISH)+
                          ' Source: '+sa+' Destination: '+saDestPathNFile);
                      end;
                    end;

                    if bOk then
                    begin
                      if uFileSize(saDestPathNFile)=0 then if not gbOptQuiet then writeln('ZERO LENGTH FILE');
                      //if not bOk then
                      //begin
                      //  BUError(201512272207,'Trouble saving file from server: '+saDestFilename+' Source file:'+sa);
                      //  bSkip:=true;
                      //end;
                    end;
                  end;
                  {$ENDIF}

                  if bOk then
                  begin
                    if gi1Mode=cnJB_MOVE then
                    begin
                      {$IFDEF HASFTP}
                      if giRemoteServerIs<>cnRS_Src then
                      begin
                      {$ENDIF}
                        writeln('DELETE FILE sa: '+sa);
                        Deletefile(sa);
                        writeln('DELETE FILE sa: '+sa+' WORKED - yay');
                      {$IFDEF HASFTP}
                      end
                      else
                      begin
                        bOk:=TFTP.RecvFile('delete.jbucmd') and (TFTP.ErrorCode=0);
                      end;
                      {$ENDIF}
                    end;
                    gu8Count_File+=1;
                    gu8Count_BytesMoved+=u8SrcfileSize;
                    try
                      //riteln('Checking Age of (E): ',sa);
                      u8Time:=FileAge(sa);
                      //riteln('Checking Age of (E): ',sa,' WORKED..YAY Again!');
                    except on E:EConvertError do begin
                      //riteln('Checking Age of (E): ',sa,' FAILED....BOO');
                        BUError(201607070143,'Fileage(sa):'+sa);
                    end;//except
                    end;//try

                    //riteln('4321 DEBUG:  bytesmoved: ',gu8Count_BytesMoved,'  u8srcfilesize:',u8SrcFilesize);
                    //riteln('4321 BEGIN --- FileSetDate');
                    //rileSetDate(saDestFilename,u8Time);
                    //riteln('4321 END --- FileSetDate');
                  end;
                end
                else
                begin
                  gu8Count_BytesSkipped+=u8SrcFileSize;
                  if not gbOptQuiet then write('.');
                end;
              end;
            end;
            bOk:=true; /// forces backup to continue on error IMPORTANT :)
          end;
        until (not SrcDir.MoveNext);
      end;
      //riteln('---------------------------------------');
    end;
    if bOk and gbOptDestructive then
    begin
      if DeathSquad.MoveFirst then
      begin
        repeat
          if not
            SrcDir.FoundItem_saName(
              DeathSquad.Item_saName,{$IFNDEF WINDOWS}true{$ELSE}false{$ENDIF})
          then
          begin
            writeln('A deletefile(saAddSlash(p_saDestDir)+DeathSquad.Item_saName);');
            writeln('Adeletefile('+saAddSlash(p_saDestDir)+DeathSquad.Item_saName+')');
            deletefile(saAddSlash(p_saDestDir)+DeathSquad.Item_saName);
          end;
        until not DeathSquad.MoveNext;
      end;
    end;

    if gbOptDestructive then
    begin
      if DeathSquad.MoveFirst then
      begin
        repeat
          if (not SrcDir.FoundItem_saName(DeathSquad.Item_saName,{$IFNDEF WINDOWS}true{$ELSE}false{$ENDIF})) or
             (SrcDir.Item_bDir <> DeathSquad.Item_bDir) then
          begin
            writeln('B deleteFile(saAddSlash(p_saDestDir)+srcdir.Item_saName);');
            writeln('B deleteFile('+saAddSlash(p_saDestDir)+srcdir.Item_saName+');');
            deleteFile(saAddSlash(p_saDestDir)+srcdir.Item_saName);
            writeln('b delete worked');
            if gbOptDestructive then
            begin
              DestDir.saPath:=srcdir.Item_saName+'.jbu*';
              DestDir.bDirOnly:=false;
              DestDir.LoadDir;
              if DestDir.MoveFirst then
              begin
                repeat
                  if (Destdir.Item_saName<>'.') and (Destdir.Item_saName<>'..') And
                    (Destdir.Item_saName='') then
                  begin
                    writeln('C deleteFile(saAddSlash(p_saDestDir)+DestDir.Item_saName);');
                    writeln('C deleteFile('+saAddSlash(p_saDestDir)+DestDir.Item_saName+');');
                    deletefile(saAddSlash(p_saDestDir)+Destdir.Item_saName);
                  end;
                until not destdir.movenext;
              end;
            end;
          end;
        until not DeathSquad.MoveNext;
      end;
    end;

    //rite('<<< DIR: '+p_saSrcDir);
    SrcDir.destroy;//riteln('kill srcdir');
    DestDir.destroy;//riteln('kill destdir');
    //riteln('Leaving bBackUpRecursiveDive: ' ,bOk);
    //if not gbOptQuiet then riteln;
  end;
  //---------------------------------------------------------------------------
  {$IFDEF HASFTP}
  if (gi8NestLevel=0)  and (giRemoteServerIs<>cnRS_None) then
  begin
    if bDirOpened then close(fDir);
    TFTP.Destroy;TFTP:=nil;
  end;
  {$ENDIF}
  //riteln('end backupdive===== bok:',sayesno(bok));
  result:=bOk;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================













//=============================================================================
function bPruneItRecursiveDive(p_saDestDir: ansistring): boolean;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='bPruneItRecursiveDive';{$ENDIF}
var
  bOk: boolean;
  DestDir: JFC_DIR;
  saDestFilename: ansistring;
  bDestinationExists: boolean;
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  DestDir:=JFC_DIR.Create;
  bOk:=true;
  if not gbOptQuiet then writeln(p_saDestDir);
  
  //remove quotes if there
  if leftstr(p_saDestDir,1)='"' then p_saDestDir:=rightstr(p_saDestDir,length(p_saDestDir)-1);
  if rightstr(p_saDestDir,1)='"' then p_saDestDir:=leftstr(p_saDestDir,length(p_saDestDir)-1);
  if rightstr(p_saDestDir,1)<>Dosslash then p_saDestDir+=Dosslash;

  with DestDir do
  begin
    saPath:=p_saDestDir;
    bDirOnly:=false;
    saFileSpec:='*';
    bSort:=false;
    bSortAscending:=false;
    bSortCaseSensitive:=true;//faster
    //Procedure LoadDir;
    //Procedure PreviousDir;
    LoadDir;
  end;
  
  if destDir.movefirst {and srcdir.movenext} then  // pass the period for current directory.
  begin
    repeat
      //Property Item_saName: AnsiString read read_item_saName;
      //Property Item_bReadOnly: Boolean read read_item_bReadOnly;
      //Property Item_bHidden: Boolean   read read_item_bHidden;
      //Property Item_bSysFile: Boolean  read read_item_bSysFile;
      //Property Item_bVolumeID: Boolean read read_item_bVolumeID;
      //Property Item_bDir: Boolean      read read_item_bDir;
      //Property Item_bArchive: Boolean  read read_item_bArchive;
      if ((destdir.Item_saName='.') or (destdir.Item_saName='..') or (destdir.Item_saName='')) then
      begin
        // skip it
        {$IFDEF DEBUG_MESSAGES}
      	writeln('pruneit: skipping dir entry: '+destdir.item_saname);
	      {$ENDIF}
      end else

      if destDir.Item_bDir then
      begin
        if gbOptRecurse then
        begin
          {$IFDEF DEBUG_MESSAGES}
	        writeln('pruneit: Dest: '+p_sadestdir+destdir.item_saname);
         	{$ENDIF}
          bOk:=bPruneItRecursiveDive(p_sadestdir+destdir.item_saname);//recurse
        end;
      end else
      
      begin
        if leftstr(rightstr(destdir.Item_saName,7),4)='.jbu' then
	      begin
       	  saDestFilename:=p_saDestDir+destdir.Item_saName;
          //riteln('-2----------======== FileExists ======-------------------');
          //riteln('fileexists(saDestFilename) fileexists('+saDestFilename+'):'+sYesNo(fileexists(saDestFilename)));
          //riteln('-2----------======== FileExists ======-------------------');
	        bDestinationExists:=fileexists(saDestFilename);
          {$IFDEF DEBUG_MESSAGES}
	          writeln('pruneit: Dest File Exists: '+sYesNo(bDestinationExists)+' Dest: '+saDestFilename);
	        {$ENDIF}
	
          if bDestinationExists then
          begin
            if not gbOptQuiet then writeln('pruning: '+saDestFilename);
            gu8Count_Pruned+=1;
            //riteln('-3----------======== FileExists ======-------------------');
            //riteln('fileexists(saDestFilename) fileexists('+saDestFilename+'):'+sYesNo(fileexists(saDestFilename)));
            //riteln('-3----------======== FileExists ======-------------------');
            deletefile(saDestFilename);
          end;
        end;
      end;
    until (not DestDir.MoveNext);
  end
  else
  begin
    {$IFDEF DEBUG_MESSAGES}
    writeln('pruneit: Directory completely empty.');
    {$ENDIF}
  end;
  DestDir.destroy;  
  result:=bok; 
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================






















{$IFDEF HASFTP}
//=============================================================================
function bMakeKeyFile: boolean;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='bMakeKeyFile';{$ENDIF}
var
  bOk: boolean;
  saKeyFile:ansistring;
  saIP        :ansistring;
  saPort      :ansistring;
  saKey: ansistring;
  f: text;
  i,n: integer;
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  // -makekey [filename (not extension)] password ip_address ip_port
  saKeyFile:=gsaParam1;
  saIP        :=gsaParam2;
  saPort      :=gsaParam3;

  bOk:=true;
  try
    assign(f,saKeyFile+'.jbu000');
  Except On E:Exception do bOk:=false;
    BUError(201607070150,'assign(f,saKeyFile+''.jbu000''): '+saKeyFile);
  end;

  if bOk then
  begin
    try
      try
        rewrite(f);
      finally
      end;
    Except On EInOutError do bOk:=false;
      BUError(201607070152,'rewrite(f). keyfile: '+saKeyFile);
    end;
  end;

  if bOk then
  begin
    try
      writeln(f,saIP);
      writeln(f,saPort);
      saKey:=saKeyGen;n:=1;
      for i:=1 to length(saKey) do
      begin
        write(f,saKey[i]);n+=1;
        if n>79 then
        begin
          write(f,csEOL);
          n:=1;
        end;
      end;
    except on E:Exception do bOk:=false;
      BUError(201607070153,'write(f) '+saKeyFile);
    end;//try
  end;

  try close(f); except on E:Exception do;end;//try  //dont care - just do yur best :)

  result:=bOk;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================




//=============================================================================
function bLoadKeyFile(p_saKeyFile:ansistring): boolean;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='bLoadKeyFile';{$ENDIF}
var
  bOk: boolean;
  f: text;
  sa: ansistring;
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  if not gbOptQuiet then Writeln('Loading Keyfile: ',p_saKeyFile);
  bOk:=true;
  try
    assign(f,p_saKeyFile);
  Except On E:Exception do
  begin
    bOk:=false;
    BUError(201512201731,'IO Error preparing to open: '+p_saKeyFile+' DOS IO RESULT:'+sIOResult(ioresult));
  end;//except
  end;//try

  if bOk then
  begin
    try
      reset(f);
    Except On E:Exception do
    begin
      bOk:=false;
      BUError(201512201732,'IO Error opening: '+p_saKeyFile+' DOS IO RESULT:'+sIOResult(ioresult));
    end;//except
    end;//try
  end;

  if bOk then
  begin
    try
      readln(f,gsaIP);
      readln(f,gsaPort);
      gsaKey:='';
      while not eof(f) do
      begin
        readln(f,sa);
        gsaKey+=trim(sa);
      end;
    except on E:Exception do bOk:=false;
      BUError(201607070155,'readln(f)');
    end;//try
  end;
  try close(f); except on E:Exception do begin
    BUError(201607070156,'close(f)');
  end;//excet
  end;//try
  if not gbOptQuiet then Writeln('Keyfile Loaded Successfuly: ',saYesNo(bOk));
  result:=bOk;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================



















//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//BEGIN                   CLIENT SERVER // !#!
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================







//=============================================================================
function bServerFunction: Boolean;
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='bServerFunction';{$ENDIF}
var
  bOk: boolean;
  TFTPD:TTFTPDaemonThread;
  saCmd: ansistring;
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  bOk:=bLoadKeyFile(gsaParam1+'.jbu000');
  if bOk then
  begin
    if not gbOptQuiet then writeln('Waiting for Connection. (Press Q and Enter To Quit)');
    //TFTPD := TTFTPDaemonThread.Create('0.0.0.0',gsaPort,gsaKey);

    TFTPD := TTFTPDaemonThread.Create(gsaIP,gsaPort,gsaKey,gsaParam1);
    TFTPD := TFTPD; //wasted clock cycles but shuts up compiler
                  // I was told this is bad TO DO. So far, no bad consequences!
    repeat
      //TODO: Commands to get downloads, bytes each direction, failed validation
      //      attempts, timestarted, up time. $ of dif Validated IPS etc.
      //      For Now - Typing Quit is about it.
      readln(saCmd);
      if (UPCASE(saCMD)='HELP')or (saCMD='?') then
      begin
        writeln;
        writeln('Type QUIT and Press ENTER to shut down this server.');
      end;
    until (Upcase(saCMD)='QUIT') or (Upcase(saCMD)='Q');
    writeln('deletefile(directory.jbures);');
    deletefile('directory.jbures');
  end;
  result:=bOk;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================

//=============================================================================
function bClientFunction: Boolean;
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='bClientFunction';{$ENDIF}
var
  bOk: boolean;
  TFTPClient: TTFTPSend;
  saKeyFile: ansistring;
  //saData: ansistring;
  TK: JFC_TOKENIZER;
  saCLI: ansistring;
  bDone: boolean;
  i: LongInt;
  saFilename: ansistring;
  saExpanded: ansistring;
  u2ioresult: word;
  dir,name,ext:string;
  saDestFileName: ansistring;
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  bOk:=true;
  saKeyfile:=gsaParam1;
  if not gbOptQuiet then Writeln('CLI Mode - Keyfile: '+saKeyFile+'.jbu000');
  bOk:=bLoadKeyFile(saKeyFile+'.jbu000');
  if not bOk then
  begin
    BUError(201512182238,'Unable to load key file in client/CLI mode.');
  end;
  TFTPClient := TTFTPSend.Create;
  if bOk then
  begin
    TFTPClient.TargetHost := gsaIP;
    if not gbOptQuiet then writeln('TargetSystem is ' + TFTPClient.TargetHost);
    TFTPClient.TargetPort := gsaPort;
    if not gbOptQuiet then writeln('TargetPort is ' + TFTPClient.TargetPort);


    TFTPClient.Data.LoadFromFile(saKeyFile+'.jbu000');
    if (TFTPClient.SendFile(saKeyFile+'.jbu000') and (TFTPClient.ErrorCode=0)) or
       (TFTPClient.ErrorCode=0)
    then
    begin
      if not gbOptQuiet then writeln('The server was sent your key file.');
    end
    else
    begin
      BUError(201512201644,'Trouble uploading keyfile file. FTP Client Error Code: '+inttostr(TFTPClient.ErrorCode)+' '+TFTPCLient.ErrorString);
    end;


    TK:=JFC_TOKENIZER.Create;
    TK.saQuotes:='"';
    TK.saWhiteSpace:=' '+#10+#13;
    TK.saSeparators:=' ';
    bDone:=false;
    repeat
      saCLI:='';
      readln(saCLI);
      TK.Tokenize(saCLI);
      if TK.MoveFirst then
      begin
        // BEGIN PUT ==========================================================
        if (UPCASE(tk.Item_saToken)='PUT') or (UPCASE(tk.Item_saToken)='P' )then
        begin
          if TK.MoveNExt then
          begin
            //riteln('-3----------======== FileExists ======-------------------');
            //riteln('fileexists(Tk.Item_saToken) fileexists('+Tk.Item_saToken+'):'+sYesNo(fileexists(Tk.Item_saToken)));
            //riteln('-3----------======== FileExists ======-------------------');
            if FileExists(Tk.Item_saToken) then
            begin
              if not gbOptQuiet then writeln('Uploading file...');
              TFTPClient.Data.LoadFromFile(Tk.Item_saToken);
              if (TFTPClient.SendFile(Tk.Item_saToken) and (TFTPClient.ErrorCode=0)) or
                 (TFTPClient.ErrorCode=0) then
              begin
                if not gbOptQuiet then writeln('Success!');
              end
              else
              begin
                BUError(201512201645,'Trouble uploading file. FTP Client Error Code: '+inttostr(TFTPClient.ErrorCode));
              end;
            end
            else
            begin
              BUError(201512201646,'File not found.');
            end;
          end
          else
          begin
            BUError(201512201647,'You forgot to enter the filename.');
          end;
        end else
        // END PUT   ==========================================================





        // BEGIN GET ==========================================================
        if (UPCASE(tk.Item_saToken)='GET') or (UPCASE(tk.Item_saToken)='G') then
        begin
          if TK.MoveNExt then
          begin
            if not gbOptQuiet then writeln('Requesting file: '+tk.Item_saToken);

            dtStart:=now;
            while not (TFTPClient.RecvFile(tk.Item_saToken) and (TFTPClient.ErrorCode=0) and (TFTPClient.data.size>0)) or
                ((gbOptWait=false) and (iDiffMSec(dtStart,Now)>gu8ServerTimeOut)) do
            begin
              sleep(0);
            end;

            if (TFTPClient.ErrorCode=0) and (TFTPClient.data.size>0) then
            begin
              //TODO: Here we need to see what dir are in the path and recreate them perhaps...thinking.... this isnt ftp client - atomation comign
              saExpanded:=FExpand(tk.Item_saToken);
              FSplit(saExpanded,dir,name,ext);
              saDestFileName:=name+ext;
              if not gbOptQuiet then writeln('Saving to: ',saDestFilename);
              try
                try
                  TFTPClient.Data.SaveToFile(saDestFilename);
                finally
                end;//try
              except on E:Exception do begin
                BUError(201512301512,'File Creation Error: '+saDestFilename+' '+E.Message);
                bOK:=false;
              end;
              end;//try


              if bOk then
              begin
                if uFileSize(saDestFilename)>0 then
                begin
                  if not gbOptQuiet then writeln('File Downloaded Successfully.');
                end
                else
                begin
                  if not gbOptQuiet then writeln('Downloaded file is zero length.');
                end;
              end;
            end
            else
            begin
              BUError(201512201648,'Trouble downloading file. FTP Client Error Code: '+inttostr(TFTPClient.ErrorCode)+' '+TFTPCLient.ErrorString);
            end;
          end
          else
          begin
            BUError(201512201649,'You forgot to enter the filename.');
          end;
        end else
        // END GET   ==========================================================




        // BEGIN QUIT =========================================================
        if (UPCASE(tk.Item_saToken)='QUIT') or (UPCASE(tk.Item_saToken)='Q') then
        begin
          bDone:=true;
          //TODO: Sent Command to tell server to unvalidate the IP
        end else
        // END QUIT ===========================================================





        // BEGIN HELP =========================================================
        if (UPCASE(tk.Item_saToken)='HELP') or (tk.Item_saToken='?') then
        begin
          writeln(saRepeatChar('=',80));
          writeln(' Jegas Backup CommandLine Interface Help');
          writeln(saRepeatChar('=',80));
          writeln('CLEAR                Clear screen (with linefeeds)');
          writeln('DIR     serverpath   Grab Dir from the Server)');
          writeln('DIRCRC  serverpath   Grab Dir with CRC64 Calcs)');
          writeln('GET     filename     download file');
          writeln('PUT     filename     upload file');
          writeln('QUIT                 Quit Program');
          writeln('RDIR    serverpath   Recursive Dir from the Server)');
          writeln('RDIRCRC serverpath   Recursive Dir with CRC64 Calcs)');
          writeln(saRepeatChar('=',80));
        end else
        // END HELP  ==========================================================




        // BEGIN CLEAR ========================================================
        if UPCASE(tk.Item_saToken)='CLEAR' then
        begin
          for i:=1 to 43 do writeln;
          //TODO: Sent Command to tell server to unvalidate the IP
        end else
        // END CLEAR ==========================================================



        // BEGIN DIRECTORY COMMANDS ===========================================
        if ((UPCASE(tk.Item_saToken)='DIR') or
           (UPCASE(tk.Item_saToken)='DIRCRC') or
           (UPCASE(tk.Item_saToken)='RDIR') or
           (UPCASE(tk.Item_saToken)='RDIRCRC')) then
        begin
          bOk:=TK.ListCount > 1 ;
          if not bOk then
          begin
            Writeln('All directory commands need the path on the server as the parameter.');
          end;

          if bOk then
          begin
            if UPCASE(tk.Item_saToken)='DIR' then saFilename:='dir.jbucmd' else
            if UPCASE(tk.Item_saToken)='DIRCRC' then saFilename:='dircrc.jbucmd' else
            if UPCASE(tk.Item_saToken)='RDIR' then saFilename:='rdir.jbucmd' else
            if UPCASE(tk.Item_saToken)='RDIRCRC' then saFilename:='rdircrc.jbucmd';
            if bOk then
            begin
              TK.MoveNext;
              bOk:=bSaveFile(saFilename,TK.Item_saToken,1,1000,u2IOResult,false);
              if not bOk then
              begin
                if u2IOResult<>0 then writeln(sIOResult(u2IOResult));
                writeln('Unable to make a temporary file used during server operations: '+saFilename);
              end;
            end;

            if bOk then
            begin
              TFTPClient.Data.LoadFromFile(saFilename);
              bOk:=(TFTPClient.SendFile(saFilename) and (TFTPClient.ErrorCode=0)) or
                 (TFTPClient.ErrorCode=0);
              if not bOk then
              begin
                Writeln('Unable to upload file to server: '+saFilename);
              end;
            end;
            writeln('5-deletefile('+saFilename+')');
            deletefile(saFilename);
          end;
        end else
        // END DIRECTORY COMMANDS =============================================



        // BEGIN ERROR - UNKNOWN COMMAND=======================================
        begin
          BUError(201512201650,'Unknown Command: '+Tk.Item_saToken);
        end;
        // END   ERROR - UNKNOWN COMMAND=======================================
      end;//if tk.movefirst
    until bDone;
  end;

  // Try sending file KEY FILE ========================
  //writeln('file:'+saFilename);
  //TFTPClient.Data.LoadFromFile(saFileName);
  //if TFTPClient.SendFile(saFileName) or (TFTPClient.ErrorCode=0) then
  //begin
  //  // Filetransfer successful
  //  writeln('file sent: ' + saFilename);
  //end
  //else
  //begin
  //  // Filetransfer not successful
  //  writeln('Error while sending File to TFTPServer');
  //  writeln('Error #' + IntToStr(TFTPClient.ErrorCode) + ' - ' + TFTPClient.ErrorString);
  //end;
  // Try sending file KEY FILE ========================


  // TEST SENDING FILE ========================
  //TFTPClient.Data.LoadFromFile(saFileName);
  //if TFTPClient.SendFile('c:\files\code\jas\src\synapse\winsock2.txt') or (TFTPClient.ErrorCode=0)then
  //begin
  //  // Filetransfer successful
  //  writeln('file sent: ' + 'c:\files\code\jas\src\synapse\winsock2.txt');
  //end
  //else
  //begin
  //  // Filetransfer not successful
  //  writeln('Error while sending File to TFTPServer');
  //  writeln('Error #' + IntToStr(TFTPClient.ErrorCode) + ' - ' + TFTPClient.ErrorString);
  //end;
  //// TEST SENDING FILE ========================
  //function RecvFile(const Filename: string): Boolean;
  //TFTPClient.Data.Clear;
  //if TFTPClient.RecvFile('dir.jbucmd') or (TFTPClient.ErrorCode=0)then
  //begin
  //  // Filetransfer successful
  //  TFTPClient.Data.SaveToFile('dir.jbucmd');
  //  writeln('REcieved Something from Server');
  //  bLoadTextFile('dir.jbucmd',saData);
  //  writeln('======-=-=======');
  //  writeln(saData);
  //   writeln('======-=-=======');
  //end
  //else
  //begin
  //  // Filetransfer not successful
  //  writeln('Error while sending File to TFTPServer');
  //  writeln('Error #' + IntToStr(TFTPClient.ErrorCode) + ' - ' + TFTPClient.ErrorString);
  //end;



  // Free TFTPClient
  if not gbOptQuiet then writeln('Shutting down Jegas Backup FTP client');
  TFTPClient.Free;
  result:=bOk;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================






//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//END                     CLIENT SERVER
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
{$ENDIF}















//=============================================================================
function bProcessCommandline: boolean;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='bProcessCommandline';{$ENDIF}
var
  //bok: boolean;
  //saRequestedMode: ansistring;
  i: integer;
  sa,sa2: ansistring;
  //saData: ansistring;
  //u2IoResult: word;
  //saDirRequest: ansistring;
  bOk: boolean;
  //saDirResult: ansistring;
  {$IFDEF HASFTP}
    iPos: longint;
  {$ENDIF}
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  bOk:=true;
  gi1Mode:=cnJB_SplashOnly;
  {$IFDEF DEBUG_MESSAGES}
  writeln('CMD Parameters: ' ,paramcount);
  {$ENDIF}
  for i:=1 to Paramcount do
  begin
    {$IFDEF DEBUG_MESSAGES}
    writeln('Param[',i,']:',Paramstr(i), '  Current Mode: ',saModename);
    {$ENDIF}
    sa:=upcase(Paramstr(i));
    sa2:=saLeftStr(sa,2);
    if sa='-DATE' then
    begin
      if not gbOptDate then
      begin
        gbOptDate:=sa='-DATE';
        {$IFDEF DEBUG_MESSAGES}
        if gbOptDate then writeln('Opt Date Found');
        {$ENDIF}
      end;
    end else

    if sa='-SIZE' then
    begin
      if not gbOptSize then
      begin
        gbOptSize:=sa='-SIZE';
        {$IFDEF DEBUG_MESSAGES}
        if gbOptSize then writeln('Opt Size Found');
        {$ENDIF}
      end;
    end else

    if sa='-CRC' then
    begin
      if not gbOptCRC then
      begin
        gbOptCRC :=sa='-CRC';
        {$IFDEF DEBUG_MESSAGES}
        if gbOptCRC then writeln('CRC Size Found');
        {$ENDIF}
      end;
    end else
    if (sa='-LOG') then gbOptLog:=true else
    if (sa='-PULL') and (gi1Mode=0) then gi1Mode:= cnJB_Pull else
    if (sa='-PRUNE') and (gi1Mode=0)  then gi1Mode:= cnJB_Prune else
    {$IFNDEF WINDoWS}
    if (sa='-PERM-BACKUP') and (gi1Mode=0)  then gi1Mode:=cnJB_PermBackup else
    if (sa='-PERM-RESTORE') and (gi1Mode=0)  then gi1Mode:=cnJB_PermRestore else
    {$ENDIF}
    if sa2='-Q' then gbOptQuiet:=true else
    if (sa2='-H') and (gi1Mode=0)  then gi1Mode:= cnJB_Help else
    if (sa2='-B') and (gi1Mode=0)  then gi1Mode:= cnJB_Backup else
    if (sa='-COPY') and (gi1Mode=0)  then gi1Mode:= cnJB_Copy else
    if (sa='-SYNC') and (gi1Mode=0)  then gi1Mode:= cnJB_Sync else
    {$IFDEF HASFTP}if (sa='-SERVER') and (gi1Mode=0)  then gi1Mode:= cnJB_Server else {$ENDIF}
    {$IFDEF HASFTP}if (sa='-CLIENT') and (gi1Mode=0)  then gi1Mode:= cnJB_Client else {$ENDIF}
    if (sa2='-R') then gbOptRecurse:=true else
    if (sa='-MOVE') and (gi1Mode=0)  then gi1Mode:= cnJB_Move else
    if (sa='-KEY') and (gi1Mode=0) then gi1Mode:= cnJB_MakeKey else
    if (sa='-DESTRUCTIVE') and (gi1Mode=0) then gbOptDestructive:=true else
    if (sa='-RETIRE') and (gi1Mode=0) then gbOptRetire:=true else
    {$IFDEF HASFTP}if (sa='-WAIT') then gbOptWait:=true else{$ENDIF}
    begin
      {$IFDEF DEBUG_MESSAGES}
      writeln('Not an option. Len P1:',length(gsaParam1),' P2:',length(gsaParam2), ' P3:',length(gsaParam2));
      {$ENDIF}
      if gsaParam1='' then begin gsaParam1:=paramstr(i); {$IFDEF DEBUG_MESSAGES}writeln('gsaParam1 = Parameter(',i,') = ',gsaParam1);{$ENDIF}end else
      if gsaParam2='' then begin gsaParam2:=paramstr(i); {$IFDEF DEBUG_MESSAGES}writeln('gsaParam2 = Parameter(',i,') = ',gsaParam2);{$ENDIF}end else
      if gsaParam3='' then begin gsaParam3:=paramstr(i); {$IFDEF DEBUG_MESSAGES}writeln('gsaParam3 = Parameter(',i,') = ',gsaParam3);{$ENDIF}end else
      begin
        {$IFDEF DEBUG_MESSAGES}
        writeln('  paramstr(i):>',paramstr(i),'<');
        writeln('           p1:>',gsaParam1,'<');
        writeln('           p2:>',gsaParam2,'<');
        writeln('           p3:>',gsaParam3,'<');
        {$ENDIF}
      end;
      // ok we have a non-option or command so - trying to only capture two atm so..here goes
      {$IFDEF DEBUG_MESSAGES}
      writeln('PARAMSTR(',i,'):',paramstr(i));
      {$ENDIF}
    end;
  end;

  {$IFDEF HASFTP}
  //saDebug:='BEGIN -------------------------------------- KEY FILE STUFF ';
  giRemoteServerIs:=cnRS_None;
  iPos:=pos('/',gsaParam1);
  if iPos=0 then pos('\',gsaParam1);
  if iPos>0 then
  begin
    sa:=leftstr(gsaParam1,ipos-1);
  end
  else
  begin
    sa:=gsaParam1;
  end;
  gsaKeyFile:=sa;
  sa+='.jbu000';

  //riteln('-4----------======== FileExists ======-------------------');
  //riteln('fileexists(sa) fileexists('+sa+'):'+sYesNo(fileexists(sa)));
  //riteln('-4----------======== FileExists ======-------------------');

  if FileExists(sa) then
  begin
    //saDebug+='src exists:'+gsaParam1+'.jbu000';
    writeln('server load keyfile:',sa);
    if bLoadKeyfile(sa) then
    begin
      //saDebug+='loaded src keyfile:'+gsaParam1;
      giRemoteServerIs:=cnRS_Src;
    end
    else
    begin
      BUError(201512291611,'Source Keyfile did not load: '+sa);
    end;
  end;

  if giRemoteServerIs=cnRS_None then
  begin
    {$IFDEF DEBUG_MESSAGES}
    write('Server Destination? :'+gsaParam2+'.jbu000  ');
    {$ENDIF}
    sa:=gsaParam2+'.jbu000';

    //riteln('-5----------======== FileExists ======-------------------');
    //riteln('fileexists(sa) fileexists('+sa+'):'+sYesNo(fileexists(sa)));
    //riteln('-5----------======== FileExists ======-------------------');


    if FileExists(sa) then
    begin
      writeln('AFFIRMATIVE');
      //saDebug+='dest exists:'+gsaParam1+'.jbu000';
      if bLoadKeyfile(sa) then
      begin
        //saDebug+='loaded dest keyfile:'+gsaParam1;
        giRemoteServerIs:=cnRS_Dest;
      end
      else
      begin
        writeln('keyfile didn''t load');
        BUError(201512291612,'Destination Keyfile did not load: '+sa);
      end;
    end
    else
    begin
     {$IFDEF DEBUG_MESSAGES}
      writeln('NEGATIVE');
     {$ENDIF}
    end;
  end;
  //saDebug+='END -------------------------------------- KEY FILE STUFF ';
  {$ENDIF}

                                 
  //bSaveFile('debug.txt',saDebug,1,1,u2IoResult,false);
                                 
  {$IFDEF DEBUG_MESSAGES}
  writeln('==EXIT PROCESSCMDLINE==');
  {$IFDEF HASFTP}
  writeln('ServerMode:',saRemoteServerIs);
  {$ENDIF}
  writeln('Mode:',saModeName);
  writeln('  p1:',gsaParam1);    
  writeln('  p2:',gsaParam2);    
  writeln('  p3:',gsaParam3);    
  writeln('==EXIT PROCESSCMDLINE==');
  {$ENDIF}
  result:=bOk;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================








//=============================================================================
procedure WriteDupeFileStrategy;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='WriteDupeFileStrategy';{$ENDIF}
begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}
  if not gbOptQuiet{$IFDEF HASFTP} and (gi1Mode<>cnJB_Server){$ENDIF} then
  begin
    writeln('      -=-=- Duplicate File Identification Strategy -=-=-');
    writeln('Filename: '+ sTrueFalse(not (gbOptDate or gbOptSize or gbOptCRC))
      +' Date: '+sTrueFalse(gbOptDate)+' FileSize: '+sTrueFalse(gbOptSize)+' CRC64: '+sTrueFalse(gbOptCRC));
    writeln('      -=-=- Duplicate File Identification Strategy -=-=-');
    writeln;
  end;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
end;
//=============================================================================






//=============================================================================
function bJegasBackup:boolean;// !#!
//=============================================================================
{$IFDEF DEBUG_ROUTINE_NESTING}const csRoutineName='bJegasBackup';{$ENDIF}
var
  sStarted: string[8];
  saUsage: ansistring;
  bOk: boolean;
  sa: ansistring;
  iMilliSecDiff,day,hour,min,sec: INT;
  u2IOResult: word;
  {$IFNDEF WINDOWS}
  u8ErrID: UInt64;
  saErrMsg: ansistring;
  {$ENDIF}
  saP1, saP2: ansistring;//scrubbed params (param1,param2)
  {$IFDEF HASFTP}
  iPos: Longint;
  {$ENDIF}

Begin
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn(csRoutineName);{$ENDIF}


  // BEGIN ------------- STATS
  // END ------------- STATS
  gsaParam1:='';
  gsaParam2:='';
  gsaParam3:='';

  gbFirstError          := true;
  dtStart               := now;
  dtEnd                 := now;
  bOk                   := true;
  gsaSrcDir             := '';
  gsaDestDir            := '';
  gi1Mode               := cnJB_SplashOnly;
  gi8NestLevel          := 0;
  sStarted              := ' STARTED';
  gu8Count_File         := 0;
  gu8Count_Dir          := 0;
  gu8Count_Versioned    := 0;
  gu8Count_BytesMoved   := 0;
  gu8Count_BytesSkipped := 0;
  gu8Count_Errors       := 0;
  gu8Count_Pruned       := 0;
  gbOptDate             :=false;
  gbOptSize             :=false;
  gbOptCrc              :=false;
  gbOptRecurse          :=false;
  gbOptLog              :=false;
  gbOptQuiet            :=false;
  gbOptRetire           :=false;
  gbOptDestructive      :=false;
  gbFirstError          :=true;// turned false once error happens
  {$IFDEF DEBUGMESSAGES}
  gi8RoutineNestLvl     :=0;
  gi8NestLevel          :=0;

  {$ENDIF}
  {$IFDEF HASFTP}
  gsaIP           :='127.0.0.1';
  gsaPort         :='21';
  gsaKey          :='0';
  giRemoteServerIs:=0;
  gbOptWait       :=false;
  TFTP                  :=nil;
  gu8ServerTimeOut      :=60000 * 5; // DEFAULT: 5 Minutes (in milliseconds)
  gsaKeyFile            :='';
  {$ENDIF}
  saUsage:=
    'Usage: jbu [OPTIONS and ONE MODE in any order] [parameters according to MODE]'+ENDLINE+ENDLINE+

    saRepeatChar('-',79)+ENDLINE+
    'MODES OF OPERATION'+ENDLINE+
    saRepeatChar('-',79)+ENDLINE+
    'WARNING: THIS PROGRAM NEVER ASKS FOR CONFIRMATION, LOG FILE YES, ASK YOU ANNOY-'+ENDLINE+
    '         QUESTIONS AFTER YOU GIVE THE ORDER, NO - NEVER - DANGEROUS!'+ENDLINE+
    '         Quite powerful too though! =|:^)>'+ENDLINE+ENDLINE+
   
    ' -backup  | -b [OPTIONS] [source directory] [destination directory]'+ENDLINE+
    '       Safely backups the source directory into the destination folder. Exist-'+ENDLINE+
    '       ing files in the destination folder will only be written to if the'+ENDLINE+
    '       source file has changed. These files are first renamed so that all ver-'+ENDLINE+
    '       sions are preserved. Options: q,r,date,crc,size,log,destructive,retire'+ENDLINE+ENDLINE+

    ' -copy  [OPTIONS] [source directory] [destination directory]'+ENDLINE+
    '        The file in the destination directory will be OVERWRITTEN if the file'+ENDLINE+
    '        being copied already exists. Options: q,r,log'+ENDLINE+ENDLINE+

    ' -move  [OPTIONS] [source directory] [destination directory]'+ENDLINE+
    '        The file in the destination directory will be OVERWRITTEN if the file'+ENDLINE+
    '        being copied already exists. Additionally, after every successful'+ENDLINE+
    '        copy the original is deleted effectively moving the file(s).'+ENDLINE+
    '        Options: q,r,log'+ENDLINE+ENDLINE+

    ' -sync  [OPTIONS] [source directory] [destination directory]'+ENDLINE+
    '        This mode synchronizes two directories using the same logic as '+ENDLINE+
    '        -backup except files can move in both directions and the JBU version'+ENDLINE+
    '        history files are not copied. If a file is about to be overwritten, '+ENDLINE+
    '        te same steps are taken as with backup: The file about to be overwrit-'+ENDLINE+
    '        ten is preserved as the latest historic version. (*.jbu* files).'+ENDLINE+
    '        Options: q,r,date,crc,size,log,destruct-'+ENDLINE+ENDLINE+

    ' -pull [OPTIONS] [source directory] [destination] - pull works like -copy ex-'+ENDLINE+
    '        cept only the LATEST version of each file is copied. This allows you to'+ENDLINE+
    '        restore your files from your backups without copying all the historic'+ENDLINE+
    '        versions of the file too. Options: q,r,log'+ENDLINE+ENDLINE+

    ' -prune [OPTIONS] [destination directory]'+ENDLINE+
    '        Removes all jbu versioned files in the destination directory.'+ENDLINE+
    '        Note all files matching this wild card will be deleted: *.jbu*' +  ENDLINE +
    '        Options: q,r,log' + ENDLINE+ ENDLINE;

  {$IFNDEF WINDOWS}
  saUsage+=
    ' -perm-backup [OPTIONS] [new permission file] [directory to process]'+ENDLINE+
    '        Stores POSIX directory listing output in a specific format for '+ENDLINE+
    '        use later as a means of restoring file permission, ownership and group'+ENDLINE+
    '        attributes.'+ENDLINE+ENDLINE+

    ' -perm-restore [permission file] [parent directory of target directory.]'+ENDLINE+
    '        Restores UNIX permissions saved in your previously created permission '+ENDLINE+
    '        backup file. This file is a "ls -l --full-time " commmand with the re-'+ENDLINE+
    '        cursive flag used based on whether -r or -recurse is passed to jbu or'+ENDLINE+
    '        not.'+ENDLINE+ENDLINE;
  {$ENDIF}


  {$IFDEF HASFTP}
  saUsage+=
    ' -server [key file no extension]'+ENDLINE+
    '        This puts JegasBackup into a mode where it listens for '+ENDLINE+
    '        files transfer command bi-directionally from another instance'+ENDLINE+
    '        of JegasBackup running on another networked machine in any OS '+ENDLINE+
    '        practically. Windows, FreeBSD, Linux, Mac, Raberri, ARM for '+ENDLINE+
    '        example. '+ENDLINE+ENDLINE;

  saUsage+=
    ' -client [key file no extension]'+ENDLINE+
    '        This is a functional, albeit very simple ftp client. This is used '+ENDLINE+
    '        for testing, however it does allow for SOME basic FTP operations.'+ENDLINE+ENDLINE;

  saUsage+=
    ' -key [key file no extension] ip_address ip_port'+ENDLINE+
    '      A file containing your password encrypted along with the IP and '+ ENDLINE+
    '      port. This works for both the server and the client. For the server, '+ENDLINE+
    '      the password is used to validate the client, and the port is used. '+ENDLINE+
    '      The IP Address is not used, the server''s IP will be that assigned '+ENDLINE+
    '      to the machine (default NIC). (This may change in a future version.)'+ENDLINE+ENDLINE;
  {$ENDIF}

  saUsage+=
    saRepeatChar('-',79)+ENDLINE+
    ' OPTIONS - See each mode to see what options apply.'+ENDLINE+
    saRepeatChar('-',79)+ENDLINE+

    ' -destructive     causes file or directory to be deleted if they exist in the'+ENDLINE+
    '                  destination but not in the source. The history files'+ENDLINE+
    '                  (*.jbu*) will deleted also. This option gives you the'+ENDLINE+
    '                  ability to totally remove files you do NOT want to in'+ENDLINE+
    '                  your source directory OR your destination one.'+ENDLINE+ENDLINE+

    'WARNING: DESTRUCTIVE DOES NOT HAVE A ONE LETTER SHORTCUT QUITE PURPOSEFULLY! '+ENDLINE+
    '         It Deletes EVERYTHING in the DESTINATION DIRECTORY NOT IN THE SOURCE'+ENDLINE+
    '         FOLDER! Please test and understand how this mode works before letting'+ENDLINE+
    '         it loose on important directories.'+ENDLINE+ENDLINE+

    ' -retire          this mode works like -destructive but it does not delete,'+ENDLINE+
    '                  instead it preserves them the way backup preserves files '+ENDLINE+
    '                  versus just overwriting them. This is useful for sub-'+ENDLINE+
    '                  sequent pulls (-pull mode), as the "retired" files are not'+ENDLINE+
    '                  "pulled"; however the directories remain. Renaming the '+ENDLINE+
    '                  highest version of the "retired" file to its original name'+ENDLINE+
    '                  effectively restores it, and it will show up in the next '+ENDLINE+
    '                  -pull from that directory.'+ENDLINE+ENDLINE+

    'WARNING: RETIRE IS DESTRUCTIVE, LESS THAN THE -destructive COMMAND HOWEVER THE '+ENDLINE+
    '         SERIOUS WARNING IS WARRANTED. Please test and understand how this mode'+ENDLINE+
    '         works before letting it loose on important directories.'+ENDLINE+ENDLINE+

    ' Combining Duplicate identification strategies like -size, -crc and/or'+ENDLINE+
    ' -date is additive: all conditions must be satisfied before the file is '+ENDLINE+
    ' recognized as being "changed" and therefore worth processing.'+ENDLINE+ENDLINE+



    ' -quiet   | -q    to prevent console output.'+ENDLINE+ENDLINE+

    ' -recurse | -r    recurse and work on specified directory and all the sub-'+ENDLINE+
    '                  directories within it.'+ENDLINE+ENDLINE+

    ' -log              generates an error log file named "jbu.log" in working dir.'+ENDLINE+ENDLINE+

    ' -date             indicates that file modification dates are used to indicate'+ENDLINE+
    '                   a file has changed. This option is fast, and foolproof if'+ENDLINE+
    '                   your file timestamps and your machine''s clock can be'+ENDLINE+
    '                   trusted.'+ENDLINE+ENDLINE+

    ' -size             indicates that file sizes are used to indicate a file has'+ENDLINE+
    '                   changed. This option is Very fast but will mistake a file'+ENDLINE+
    '                   for a duplicate when its not if the file was edited but the'+ENDLINE+
    '                   file size remained the same.'+ENDLINE+ENDLINE+

    ' -crc              calculates a 64bit crc on both the source and destination'+ENDLINE+
    '                   file; if the values do not match, the file has changed. This'+ENDLINE+
    '                   option is slow however it is the safest way to prevent data-'+ENDLINE+
    '                   loss when making backups.'+ENDLINE+ENDLINE;

  {$IFDEF HASFTP}
  saUsage+=
    ' -wait            This command will cause the client to WAIT on the server '+ENDLINE+
    '                  FOREVER. This is useful for huge directories and the like'+ENDLINE+
    '                  that might take awhile. Additionally, any code that fails'+ENDLINE+
    '                  due to networking errors, is designed to try again... like'+ENDLINE+
    '                  waiting fo a task to finish on the server, will also in-'+ENDLINE+
    '                  cessantly try to connect to the server until it responds'+ENDLINE+
    '                  or you press CTRL+C to just end the program.'+ENDLINE+ENDLINE;
  {$ENDIF}

saUsage+=
    saRepeatChar('-',79)+ENDLINE+
    ' How -date, -size, crc work when combined.'+ENDLINE+
    saRepeatChar('-',79)+ENDLINE+
    '-backup and -sync [OPTIONS] control how a duplicate '+ENDLINE+
    'file is decided. The default is by the filename alone. The options '+ENDLINE+
    'are -date, -size and -crc. Using any option makes the existence of'+ENDLINE+
    'the file is NOT ENOUGH to be considered worth copying, moving,'+ENDLINE+
    'backing up or syncing. Using options together means that ALL criteria '+ENDLINE+
    'must be met for the file to be considered a duplicate needing to be ' +ENDLINE+
    'versioned (renamed) for data preservation.'+ENDLINE+ENDLINE;


  saUsage+=
    saRepeatChar('-',79)+ENDLINE+
    ' Examples:'+ENDLINE+
    saRepeatChar('-',79)+ENDLINE+
    '  jbu -backup -quiet -log -crc /some/folder/ /my/backup/'+ENDLINE+
    '  jbu -backup -recurse -date /files/ /backup/files/'+ENDLINE+
    '  jbu -backup -recurse -crc -date /files/ /backup/files/'+ENDLINE+
    '  jbu -backup -r -q -retire /source/directory/ /destination/directory/'+ENDLINE+
    {$IFDEF HASFTP}
    '  jbu -b -date -recurse key_file_name_no_ext_of_server/src/ /dest/'+ENDLINE+
    '  jbu -backup -date -r /dest/ key_file_name_no_ext_of_server/src/'+ENDLINE+
    '  jbu -b -r c:\files\     password_file'+ENDLINE+
    '  jbu -b -r config_file c:\files\'+ENDLINE;
    {$ENDIF}
    ENDLINE+

    '  jbu -copy -q -log /some/folder/ /my/backup/'+ENDLINE+
    '  jbu -copy -recurse /files/ /backup/files/'+ENDLINE+
    {$IFDEF HASFTP}
    '  jbu -copy -date -recurse /your/pc/ key_file_name_no_ext_of_server/dest/'+ENDLINE+
    '  jbu -copy -date -recurse key_file_name_no_ext_of_server/dest/ /your/pc/'+ENDLINE+
    {$ENDIF}
    ENDLINE+

    '  jbu -move -quiet -log /some/folder/ /my/backup/'+ENDLINE+
    '  jbu -move -r /files/ /backup/files/'+ENDLINE+
    {$IFDEF HASFTP}
    '  jbu -move -date -recurse /your/pc/ key_file_name_no_ext_of_server/dest/'+ENDLINE+
    '  jbu -move -date -r key_file_name_no_ext_of_server/dest/ /your/pc/'+ENDLINE+
    {$ENDIF}
    ENDLINE+

    '  jbu -sync -quiet -log -crc /some/folder/ /my/main/stuff/'+ENDLINE+
    '  jbu -sync -recurse -date /files/ /sync/files/'+ENDLINE+
    '  jbu -sync -recurse -crc -date /files/ /sync/files/'+ENDLINE+
    '  jbu -sync -r -q -retire /source/directory/ /destination/directory/'+ENDLINE+
    {$IFDEF HASFTP}
    '  jbu -sync -date -recurse key_file_name_no_ext_of_server/src/ /dest/'+ENDLINE+
    '  jbu -sync -date -r /dest/ key_file_name_no_ext_of_server/src/'+ENDLINE+
    {$ENDIF}
    ENDLINE+

    '  jbu -pull -recurse /files/repository/ /put/them/here/'+ENDLINE+
    '  jbu -pull -q /files/repository/ /put/them/here/'+ENDLINE+
    '  jbu -pull -r /files/repository/ /put/them/here/'+ENDLINE+
    '  jbu -pull -r -log /files/repository/ /put/them/here/'+ENDLINE+
    {$IFDEF HASFTP}
    '  jbu -pull -recurse key_file_name_no_ext_of_server/src/ /dest/'+ENDLINE+
    '  jbu -pull -r /dest/ key_file_name_no_ext_of_server/src/'+ENDLINE+
    {$ENDIF}
    ENDLINE+


    '  jbu -prune -r -q -log /directory/to/prune/'+ENDLINE+
    '  jbu -prune -quiet -log /some/folder/ /my/backup/'+ENDLINE+
    '  jbu -prune -r /files/ /backup/files/'+ENDLINE+
    {$IFDEF HASFTP}
    '  jbu -prune -recurse /your/pc/ key_file_name_no_ext_of_server/dest/'+ENDLINE+
    '  jbu -prune -log -r key_file_name_no_ext_of_server/dest/ /your/pc/'+ENDLINE+
    {$ENDIF}
    ENDLINE+

  {$IFNDEF WINDOWS}
    '  jbu -perm-backup /backup/perm.txt   /'+ENDLINE+ENDLINE+
    '  jbu -perm-restore /backup/perm.txt  /'+ENDLINE+ENDLINE+
  {$ENDIF}


  {$IFDEF HASFTP}
    '  jbu -key config_file 10.0.0.5 21'+ENDLINE+
    '  jbu -key keyfile 1.2.3.4 21'+ENDLINE+ENDLINE+
    '  jbu -server key_file'+ENDLINE+ENDLINE+
    '  jbu -server config_file'+ENDLINE+
    '  jbu -client key_file'+ENDLINE+ENDLINE+
  {$ENDIF}

    saRepeatChar('=',79)+ENDLINE+
    'Executable Info: '+
   {$IFDEF WINDOWS}
     'Windows '+{$IFDEF CPU32}'32'{$ELSE}'64'{$ENDIF}+
   {$ELSE}
     {$IFDEF LINUX}
       'Linux '+{$IFDEF CPU32}'32'{$ELSE}'64'{$ENDIF}+
     {$ELSE}
       'Unknown OS '+{$IFDEF CPU32}'32'{$ELSE}'64'{$ENDIF}+
     {$ENDIF}
   {$ENDIF}
   {$IFDEF HASFTP}' - Networking'+{$ENDIF}
   ' - Max Directory Depth: '+inttostr(cnMaxNestLevel)+ENDLINE+ENDLINE+
   {$IFDEF DEBUG_MESSAGES}'DEBUG MESSAGES ENABLED'+ENDLINE+{$ENDIF}
   {$IFDEF DRY_RUN_ONLY}'DEBUG COMMAND LINE - CRIPPLED BINARY'+ENDLINE+{$ENDIF}
   {$IFDEF DEBUG_ROUTINE_NESTING}'DEBUG TRACE ENABLED'+ENDLINE+{$ENDIF}
  saRepeatChar('=',79)+ENDLINE+

  'If you do not know how to see the information that may have just shot up and'+ENDLINE+
  'off your screen, try:    jbu -help | more'+ENDLINE+
  'How to use "more": Use the ENTER key to scroll down, CNTL-C to exit.'+ENDLINE+
  saRepeatChar('=',79)+ENDLINE;


  grJegasCommon.sAppTitle:=csJBU_Apptitle;
  grJegasCommon.sVersion:=csJBU_Version;

  bOk:=bProcessCommandLine;
  if gbOptLog then // expect revisits - no error handling yet
  begin
    if not gbOptQuiet then writeln('opening log file');
    assign(fLog,csJBULogFilename);
    try
      rewrite(fLog);
    Except On E:Exception do begin
      u2IOresult:=ioresult;
      bOk:=false; BUError(201601010546,'Unable to open jbu.log. IOResult: '+inttostr(u2IOResult)+' '+sIOResult(u2IOResult));
    end;//except
    end;//try
  end;
  if bOk then
  begin
    if not gbOptQuiet then
    begin
      writeln;
      writeln(saJegasLogoRawText(csCRLF));
      writeln(grJegasCommon.sAppProductName+'  - Version: '+grJegasCommon.sVersion);
      writeln('By: Jason Peter Sage - Jegas, LLC - Jegas.com');
      if gi1Mode<>0 then writeln(csCRLF+saFixedLength('BEGIN ===== Mode: '+saModeName+' '+saRepeatChar('=',56),1,80));
      if (gi1Mode=cnJB_Backup)or(gi1Mode=cnJB_Sync) then WriteDupeFileStrategy;
    end;

    {$IFDEF DEBUG_MESSAGES}
    writeln('Mode: ',saModeName);
    writeln('P1:',gsaParam1);
    writeln('P2:',gsaParam2);
    writeln('P3:',gsaParam3);
    {$ENDIF}

    {$IFNDEF DRY_RUN_ONLY}
    if bOk then
    begin
      saP1:=gsaParam1;
      saP2:=gsaParam2;

      {$IFDEF HASFTP}
      case giRemoteServerIs of
      //cnRS_None: begin
      //  saP1:=gsaParam1;
      //  saP2:=gsaParam2;
      //end;
      cnRS_Src: begin
        {$IFDEF WINDOWS}//saWin2LinPath(gsaParam2);
        {$ENDIF}
        iPos:=pos('/',gsaParam1);
        if iPos<=0 then iPos:=pos('\',gsaParam1);
        if iPos>0 then saP1:=rightstr(gsaParam1,length(gsaParam1)-iPos+1) else saP1:=gsaParam1;
      end;//case
      cnRS_Dest: begin
        {$IFDEF WINDOWS}//saWin2LinPath(gsaParam1);
        {$ENDIF}
        iPos:=pos('/',gsaParam2);
        if iPos<=0 then iPos:=pos('\',gsaParam2);
        if iPos>0 then saP2:=rightstr(gsaParam2,length(gsaParam2)-iPos+1) else saP2:=gsaParam2;
      end;//case
      end;//select
      {$ELSE}
       saP1:=gsaParam1;
       saP2:=gsaParam2;
      {$ENDIF}
      {$IFDEF DEBUG_MESSAGES}writeln('first dive saP1 >'+saP1+'< saP2 >'+saP2+'<');{$ENDIF}
      //saSNR(saP1,'\','/');
      //saSNR(saP2,'\','/');
      case gi1Mode of
      cnJB_Help             : write(saUsage);//case
      cnJB_Copy             : begin
         if not gbOptQuiet then writeln('COPY'   ,sStarted,': '+gsaParam1);
         gu8Count_Dir+=1;

         bOk:=bBackupRecursiveDive(saP1,saP2);
      end;//case
      cnJB_Move             : begin
         if not gbOptQuiet then writeln('MOVE'   ,sStarted,': '+saP1);
         gu8Count_Dir+=1;
         bOk:=bBackupRecursiveDive(saP1,saP2);
      end;//case
      cnJB_Pull             : begin if not gbOptQuiet then writeln('PULL'   ,sStarted,': '+saP1); gu8Count_Dir+=1;bOk:= bBackupRecursiveDive(saP1,saP2); end;//case
      cnJB_Backup           : begin if not gbOptQuiet then writeln('BACKUP' ,sStarted,': '+saP1);
                                         //riteln('first dive saP1 >'+saP1+'< saP2 >'+saP2+'<');
                                         gu8Count_Dir+=1;bOk:= bBackupRecursiveDive(saP1,saP2); end;//case
      cnJB_Prune            : begin if not gbOptQuiet then writeln('PRUNE'  ,sStarted,': '+saP1); gu8Count_Dir+=1;bOk:=bPruneItRecursiveDive(saP1); end;//case
      {$IFNDEF WINDOWS}
      cnJB_PermBackup       : begin
        bOK:=bPermBackUp(
          gsaParam1,
          gsaParam2,
          gbOPTRecurse,
          csTempScriptName,
          gu8Count_Errors,
          u8ErrID,
          saErrMsg);
        if not bOk then BUError(u8ErrID, saErrMsg);
      end;//case
      cnJB_PermRestore      : bOk:=bPermRestore(gsaParam1,gsaParam2);
      {$ENDIF}
      cnJB_Sync             : begin
         if not gbOptQuiet then writeln('SYNC'   ,sStarted,': '+gsaParam1);
         gu8Count_Dir+=1;
         bOk:= bBackupRecursiveDive(gsaParam1,gsaParam2);
         if bOk then
         begin
           bOk:= bBackupRecursiveDive(gsaParam2,gsaParam1);
         end;
      end;//case
      {$IFDEF HASFTP}
      cnJB_Server           : bOk:=bServerFunction;
      cnJB_Client           : bOK:=bClientFunction;
      cnJB_MakeKey          : bOk:=bMakeKeyFile;
      {$ENDIF}
      end;//SELECT
    end;
    {$ENDIF}
  end;

  if bOk then
  begin
    if (gi1Mode<>0) then
    begin
      if not gbOptQuiet then // if quiet mode  time does matter
      begin
        dtEnd:=now;
        if (gi1Mode=cnJB_Backup) or (gi1Mode=cnJB_Copy) or (gi1Mode=cnJB_Move) or
           (gi1Mode=cnJB_Sync) or (gi1Mode=cnJB_Pull) or (gi1Mode=cnJB_Prune) then
        begin
          if (gi1Mode=cnJB_Backup)or(gi1Mode=cnJB_Sync) then WriteDupeFileStrategy;
          writeln('      -=-=- Statistics -=-=-');
          iMilliSecDiff:=iDiffMSec(dtStart,dtEnd);
          day:=iMilliSecDiff div ( 1000 * 60 * 60 * 24);iMilliSecDiff-=day * (1000 * 60 * 60 * 24);
          hour:=iMilliSecDiff div ( 1000 * 60 * 60);iMilliSecDiff-= hour * (1000 * 60 * 60);
          min:=iMilliSecDiff div ( 1000 * 60);iMilliSecDiff-= min * (1000 * 60);
          sec:=iMilliSecDiff div  1000;iMilliSecDiff-= sec * 1000;
          writeln('Started: ',FormatDateTime(csDateTimeformat,dtStart),'  Finished: ',FormatDateTime(csDateTimeformat,dtEnd));
          write('Elapsed: ',sZeroPadInt(day,2),':',sZeroPadInt(hour,2),':',sZeroPadInt(min,2),':',sZeroPadInt(sec,2),':',sZeroPadInt(iMilliSecDiff,4),' ');
          if gi1Mode<>cnJB_Prune then
          begin
            writeln('Files: ',gu8Count_File,' Dir: ', gu8Count_Dir,' Versioned Files: ',gu8Count_Versioned);
            writeln('Transferred: ',saBytesToHuman(gu8Count_BytesMoved),' Skipped: ', saBytesToHuman(gu8Count_BytesSkipped),' Errors: ',gu8Count_Errors);
            //writeln('Transferred: ',gu8Count_BytesMoved,' Skipped: ', gu8Count_BytesSkipped,' Errors: ',gu8Count_Errors);
          end
          else
          begin
            writeln('Pruned Versioned Files Removed: ',gu8Count_Pruned);
          end;
          writeln('      -=-=- Statistics -=-=-');writeln;
        end else
        if gi1Mode=cnJB_MakeKey then
        begin
          write('Success - Key File Created: '+gsaParam1+'.jbu000');
        end;
        sa:='END   ===== Mode: '+saModeName+' === ';
        if bOk then sa+='SUCCESS' else sa+='=======';
        if gu8Count_Errors = 0 then sa+='  =|:^)>  ' else sa+='==========';
        writeln(saFixedLength(sa+saRepeatChar('=',56),1,79));
      end;
    end
    else
    begin
      if not gbOptQuiet then writeln('Try: jbu -help');
    end;
  end;
  if not gbOptQuiet then writeln;

  if gbOptLog then
  begin
    if not gbOptQuiet then writeln('closing log file');
    writeln(fLog,saRepeatChar('=',79));
    writeln(flog,'EOF');
    writeln(fLog,saRepeatChar('=',79));
    close(fLog);
  end;
  result:=bOk;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut(csRoutineName);{$ENDIF}
End;
//=============================================================================



//=============================================================================
var bMAIN_Ok: boolean;
begin // !#!
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineIn('COMMAND LINE');{$ENDIF}
  //****SINGLE ENTRY, SINGLE EXIT PREFFERED****
  // but, by no law in any country yet, is
  // REQUIRED SO... (perhaps consequences, perhaps OS has do do clean up? It
  // might do it a zillion times faster than you so if you wont hurt anything
  //  KILL / HALT / DIE Whenever you want! :) FREEDOM MAN!
  bMAIN_Ok:=bJegasBackup;
{$IFDEF DEBUG_ROUTINE_NESTING}DebugRoutineOut('COMMAND LINE');{$ENDIF}
  if bMAIN_Ok then halt(0) else halt(1);
end.
//=============================================================================


//*****************************************************************************
// EOF
//*****************************************************************************
