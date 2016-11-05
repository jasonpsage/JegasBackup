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
unit TFTPDaemonThread_jegas;
//=============================================================================

//=============================================================================
// Precompiler Directives
//=============================================================================
{$INCLUDE i_jegas_splash.pp}
{$INCLUDE i_jegas_macros.pp}
{$DEFINE SOURCEFILE:='jegasbackup.pas'}
{$SMARTLINK ON}
{$PACKRECORDS 4}
{$MODE objfpc}


//=============================================================================


//=============================================================================
// NOTES: ---------------------------------------------------------------------
//=============================================================================
//   TFTP supports five types of packets, all of which have been mentioned
//   above:
//      opcode     operation
//
//        1        Read request (RRQ)
//        2        Write request (WRQ)
//        3        Data (DATA)
//        4        Acknowledgment (ACK)
//        5        Error (ERROR)
//
//
//   Error Codes
//     Value       Meaning
//
//       0         Not defined, see error message (if any).
//       1         File not found.
//       2         Access violation.
//       3         Disk full or allocation exceeded.
//       4         Illegal TFTP operation.
//       5         Unknown transfer ID.
//       6         File already exists.
//       7         No such user.
//
//-----------------------------------------------------------------------------
// REFERENCE --- HOW To USE the built in messaging thing.
//-----------------------------------------------------------------------------
// Fill the Log-Memo whith Infos about the request
//case RequestType of
//1:FLogMessage := 'Read-Request from ' + TFTPDaemon.RequestIP + ':' + TFTPDaemon.RequestPort;//case
//2:FLogMessage := 'Write-Request from '+ TFTPDaemon.RequestIP + ':' + TFTPDaemon.RequestPort;//case
//end;//select
//Synchronize(UpdateLog);
//FLogMessage := 'File: ' + Filename;
//Synchronize(UpdateLog);
//=============================================================================





//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
interface
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================

//=============================================================================
uses Classes, SysUtils, ftpTSend_jegas,dos,ug_jegas,ug_jfc_dir,ug_common,ug_jfc_tokenizer;
//=============================================================================

//=============================================================================
const
//=============================================================================
  cnKeyValidationTimeOutInMinutes = 15;
//=============================================================================

//=============================================================================
type TTFTPDaemonThread = class(TThread)
//=============================================================================
  private
    { Private declarations }
    FIPAdress:String;
    FPort:String;
    dtKeyValidated: TDATETIME;
    procedure UpdateLog;
  protected
    procedure Execute; override;
    function bReadRequest(p_saFilename: ansistring; var p_u8ErrID: uint64; var p_saErrMsg: ansistring): boolean;
    function bWriteRequest(p_saFilename: ansistring): boolean;
  public
    TFTPDaemon:TTFTPSend;
    function bGetDir(p_saDir:ansistring; var p_saDirOut: ansistring; p_bRecurse: boolean; p_bCalcCRC: boolean):boolean;
    constructor Create(IPAdress,Port:String;p_saServerKey: ansistring; p_saServerKeyFile: ansistring);
  public
    saServerKeyFile: ansistring;
    FLogMessage:String;
    saServerKey: ansistring;
    saValidatedClientIP: ansistring;
  end;
//=============================================================================





//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
implementation
//=============================================================================
//=============================================================================
//=============================================================================
//=============================================================================
const csTempfile='jbu.tmp';
      csDirFilename='directory.jbures';
//=============================================================================
constructor TTFTPDaemonThread.Create(IPAdress,Port:String;p_saServerKey: ansistring; p_saServerKeyFile: ansistring);
//=============================================================================
begin
  FIPAdress := IPAdress;
  FPort     := Port;
  self.saServerKey:=p_saServerKey;
  saValidatedClientIP:='';
  saServerKeyFile:=p_saServerKeyFile;
  inherited Create(False);
end;
//=============================================================================

//=============================================================================
procedure TTFTPDaemonThread.UpdateLOG;
//=============================================================================
begin
  writeln('FTP-UpdateLog procedure: '+FLogMessage);
end;
//=============================================================================



//=============================================================================
function TTFTPDaemonThread.bGetDir(p_saDir:ansistring; var p_saDirOut: ansistring; p_bRecurse: boolean; p_bCalcCRC: boolean):boolean;
//=============================================================================
var
  bOk: boolean;
  SrcDir: JFC_DIR;
  sa,saTemp: ansistring;
  //saRev:ansistring;
  saFile: ansistring;
  dt: TDateTime;
  //u8Chop: Uint64;
  TK: JFC_TOKENIZER;
  iSlashesInSrcDir: longint;
  saErrMsg:ansistring;u8ErrId:UInt64;
  u8FileSize: UInt64;
begin
  writeln('BEGIN saGetDir: >'+p_saDIR+'< ===============');
  bOk:=true;
  sa:=p_saDir;
  TK:=JFC_TOKENIZER.create;
  TK.saSeparators:='/';
  TK.saQuotes:='';
  TK.saWhiteSpace:='';
  TK.Tokenize(sa);
  //TK.DumpToTextFile
  iSlashesInSrcDir:=TK.Listcount;
  TK.DeleteAll;
  SrcDIR:=JFC_DIR.Create;
  with SrcDir do begin
    saPath:=sa;
    bDirOnly:=false;
    saFileSpec:='*';
    bSort:=true;
    bSortAscending:=false;
    bSortCaseSensitive:=true;//faster
    bOutput:=true;
    //riteln('========== getdir calling loadir start');
    LoadDir;//console output = true
    //riteln('========== getdir calling loadir end');

    // -- strip out keyfiles from being sent - might have to rethink dunno
    //if MoveFirst then
    //begin
    //  repeat
    //    sa:=Item_saName;
    //    if RightStr(sa,7)='.jbu000' then
    //    begin
    //      DeleteItem;
    //      MovePrevious;
    //    end;
    //  until not movenext;
    //end;
    //--
  end;//with
  sa+=csCRLF;
  if SrcDir.MoveFirst then
  begin
    //riteln(' ftpdt - start repeat loop for srcdir just loaded');
    repeat
      bOk:=true;
      {$IFNDEF WINDOWS}
      saFile:=p_saDir+srcDir.Item_saName;//saAddFwdSlash(p_sa: AnsiString)
      {$ELSE}
      saFile:=SrcDir.saConvertPathToWindowsFormat(p_saDir)+csDOSSLASH+srcDir.Item_saName;
      //riteln('lose a slash ? : ',saFile);
      saFile:=saSNRStr(saFile,'\\','\');
      //riteln('lose a slash result : ',saFile);
      {$ENDIF}
      //if fileexists(saFile) then
      //begin
        writeln('ITEM: '+saFile);
        if SrcDir.Item_bDir then       sa+='D' else sa+='-';
        if SrcDir.Item_bReadOnly then  sa+='R' else sa+='-';
        if SrcDir.Item_bHidden then    sa+='H' else sa+='-';
        if SrcDir.Item_bSysFile then   sa+='S' else sa+='-';
        if SrcDir.Item_bVolumeID then  sa+='V' else sa+='-';
        if SrcDir.Item_bArchive then   sa+='A' else sa+='-';
        //writeln('b4 get file modified date: '+ saFile);
        bOk:=bGetFileModifiedDate(saFile,dt);
        if not bOk then
        begin
          u8ErrID:=201601031942;saErrMsg:='Unable to get modified date for file: '+saFile;
          TFTPDaemon.ReplyError(u8ErrID,saErrMsg);
        end;
        writeln('after get file modified date, success:',saYesNo(bOk), 'File: '+safile);
        
        if bOk then
        begin
          sa+=' '+JDATE('',11,0,dt);
          writeln('b4 filesize check');
          u8FileSize:=0;
          bGetFileSize(saFile,u8FileSize);
          sa+=' '+inttostr(u8FileSize);
          writeln('after filesize check sa:',sa);





          if p_bCalcCRC and (not SrcDir.Item_bDir) then sa+=' '+inttostr(u8GetCRC64(saFile)) else sa+=' 0';
          writeln('after crc. file: '+saFile);
        
          TK.Tokenize(saFile);
          if tk.FoundNth(iSlashesInSrcDir) then
          begin
            saFile:='';
            repeat
              saFile+=Tk.Item_saToken;
            until not tk.movenext;
          end;
          if saFile[1]='/' then saFile:=rightstr(saFile,length(saFile)-1);
          sa+=' "'+safile+'"'+csCRLF;
        end
        else
        begin
          u8ErrID:=201601031659;saErrMsg:='Unable to get modified date fromfile: '+saFile;
          TFTPDaemon.ReplyError(u8ErrID,saErrMsg);
        end;
      //end;// file not found
    until (not SrcDir.MoveNext) or (not bOk);
  end;

  if bOk and p_brecurse and SrcDir.MoveFirst then
  begin
    //riteln('*************saGetDir - PREP FOR DIVE*****************');
    repeat
       saTemp:='';
       bOk:=bGetDir(SrcDir.saConvertPathToWindowsFormat(p_saDir) +csDOSSLASH+
              srcDir.Item_saName,saTemp, p_bRecurse, p_bCalcCRC);
       sa+=saTemp;
    until not SrcDir.MoveNext;
  end;
  SrcDir.Destroy;
  writeln('END saGetDir  ====== SUCCESS: '+saYesNo(bOk)+' =======' );
  TK.Destroy;
  p_saDirOut:=sa;
  result:=bOk;
end;
//=============================================================================




//=============================================================================
function TTFTPDaemonThread.bReadRequest(p_saFilename: ansistring; var p_u8ErrID: uint64; var p_saErrMsg: ansistring): boolean;
//=============================================================================
var bOk: boolean;
    name,dir,ext:string;
    saData: ansistring;
    u2IOResult: word;
    //saReqPath: ansistring;
    // sanameout: ansistring;
    //iPos: integer;
    //dtStart: TDateTime;
const csTempFile = 'jbu.tmp';

begin
  //riteln('BEGIN READ REQUEST: '+p_saFilename);
  bOk:=saValidatedClientIP<>'';
  if bOk then
  begin
    FSplit(p_saFilename,dir,name,ext);
    //===========================================================================
    // BEGIN              COMMAND WEDGE
    //===========================================================================
    if (ext='.jbucmd') then
    begin
      writeln('REQUEST: '+name);
      if (name='delete') then
      begin
        try
          TFTPDaemon.Data.savetofile('temp.jbucmd');
        except on E:Exception do bOK:=false;
        end;//try
        if not bOk then
        begin
          p_u8ErrID:=201512272234;p_saErrMsg:='Unable to save temporary data file: temp.jbucmd';
          TFTPDaemon.ReplyError(p_u8ErrID,p_saErrMsg);
        end;

        if bOk then
        begin
          bOk:=bLoadtextfile(csTempFile,saData,u2IOResult);
          if not bOk then
          begin
            p_u8ErrID:=201512272230;p_saErrMsg:='Unable to load saved '+
              'temp.jbucmd data from disk. Err: '+inttostr(u2IOResult)+' - '+
              saIOResult(u2IOResult);
            TFTPDaemon.ReplyError(p_u8ErrID,p_saErrMsg);
          end;
        end;

        if bOk then
        begin
          //riteln('deleting '+csTempFile);
          bOk:=Deletefile(csTempFile);
          if not bOk then
          begin
            p_u8ErrID:=201512272234;p_saErrMsg:='Unable to delete the temp.jbucmd file.';
            TFTPDaemon.ReplyError(1,inttostr(p_u8ErrID)+' - Unable to delete the temp.jbucmd file.');
          end;
        end;

        if bOk then
        begin
          saData:=trim(saData);
          bOk:=fileexists(saData);
          if not bOk then
          begin
            p_u8ErrID:=201512272231;p_saErrMsg:='File not Found: '+saData;
            TFTPDaemon.ReplyError(1,inttostr(p_u8ErrID)+' - Unable to delete the temp.jbucmd file.');
          end;
        end;

        if bOk then
        begin
          bOk:=Deletefile(saData);
          if not bOk then
          begin
            p_u8ErrID:=201512272232;p_saErrMsg:='Unable to delete file: '+saData;
            TFTPDaemon.ReplyError(p_u8ErrID,p_saErrMsg);
          end;
        end;

        if bOk then
        begin
          p_u8ErrID:=201512272233;p_saErrMsg:='AWESOME CODE';
          TFTPDaemon.ReplyError(p_u8ErrID,p_saErrMsg);
        end;
      end;

    end else
    //===========================================================================
    // END                COMMAND WEDGE
    //===========================================================================
    
    
    //===========================================================================
    // Send FILE to CLIENT - TODO: if it exists etc
    begin
    //===========================================================================
      //riteln('Sending FILE to CLIENT');
      bOk:=FileExists(p_saFileName);
      if not bOk then
      begin
        writeln('201512300930 - File not found.');
      end;

      if bOk then
      begin
        TFTPDaemon.Data.LoadFromFile(p_saFileName);
        bOk:=TFTPDaemon.Data.size>0;
        if not bOk then
        begin
          writeln('201512301354 - Loaded file to send client is zero length.');
        end;
      end;

      if bOk then
      begin
        bOk:=TFTPDaemon.ReplySend;
        if not bOk then
        begin
          writeln('201512301436 - Reply send failed. FTP Err:' +
            inttostr(TFTPDaemon.ErrorCode)+' '+TFTPDaemon.ErrorString);
        end;
      end;
      if bOk then
      begin
        //riteln('Success!');
      end;
    end;
  end
  else
  begin
    writeln('!!!!! UNVALIDATED CLIENT KNOCKING AT THE DOOR !!!!!');
  end;
  //riteln('END READ REQUEST bOk: ',saYesNo(bok));
  result:=bok;
end;
//=============================================================================











//=============================================================================
function TTFTPDaemonThread.bWriteRequest(p_saFilename: ansistring): boolean;
//=============================================================================
var
  bOk: boolean;
  name,dir,ext:string;
  bOpen:boolean;
  f:text;
  u2IoResult: word;
  saData,saKey,saIP,saPort,sa,saReqPath,satempDir: ansistring;
  srcdir: JFC_DIR;//hate to do this need it  scope thingy
begin
  Writeln('BEGIN WRITE REQUEST: '+p_saFilename);
  bOk:=TFTPDaemon.ReplyRecv and (TFTPDaemon.Data.size>0);
  SrcDir:=JFC_DIR.create;
  if bOk then
  begin
    FSplit(p_saFilename,dir,name,ext);
    // BEGIN ==================================================================
    // BEGIN ===  KEY VERIFICATION PROCESS ====================================
    // BEGIN ==================================================================
    if (saValidatedClientIP='') or (saValidatedClientIP=TFTPDaemon.FRequestIP) then
    begin
      if ext='.jbu000' then
      begin
        TFTPDaemon.Data.SaveToFile(p_saFileName);
        if fileexists(p_safilename) then
        begin
          bOk:=true;bOpen:=false;
          assign(f,p_safilename);
          if bOk then begin try reset(f); Except On E:Exception do bOk:=false;end; bOk:=bOk;end;
          if bOk then try readln(f,saIP); Except On E:Exception do bOk:=false;end;
          if bOk then try readln(f,saPort); Except On E:Exception do bOk:=false; end;
          saKey:='';
          if bOk then while not eof(f) do begin readln(f,sa); saKey+=trim(sa); end;
          if bOpen then try close(f); Except On E:Exception do ;end;
          if bOk and (saKey=self.saServerKey) then
          begin
            writeln('CLIENT VALIDATED');
            saValidatedClientIP:= TFTPDaemon.FRequestIP;
            dtKeyValidated:=now;
          end
          else
          begin
            writeln('INVALID KEY FILE!'); // correct keyfile name. Something is wrong with it.
          end;
        end
        else
        begin
          writeln('INVALID KEY FILE.'); // requested keyfile does not exist on the server
        end;
      end;
      if saValidatedClientIP='' then
      begin
        DeleteFile(p_safilename);
      end;
    end;
    // END ====================================================================
    // END ===  KEY VERIFICATION PROCESS ======================================
    // END ====================================================================
  end;


  if bOk then
  begin
    if TFTPDaemon.FRequestIP=saValidatedClientIP then
    begin
      writeln('Validated IP:'+saValidatedClientIP);
      //FSplit(p_saFilename,dir,name,ext);
      //riteln('filename in:',Filename);
      if (ext='.jbucmd') then
      begin
        if (name='dir') or (name='dircrc') or
           (name='rdir') or (name='rdircrc') then
        begin
          writeln('Create Directory Export');
          TFTPDaemon.Data.SaveToFile(csTempFile);
          bOk:=bLoadTextFile(csTempFile,saReqPath,u2IOResult);
          if not bOk then
          begin
            writeln('201512300803 Unable to load '+csTempFile+' with ftp requested directory. IO Result: ' +inttostr(u2IOResult)+' - '+saIOResult(u2IOResult) );
          end;

          if bOk then
          begin
            //riteln('saReqPath:'+saReqPath);
            if saReqPath='' then saReqPath:='/';
            saReqPath:=SrcDir.saConvertPathToWindowsFormat(saReqPath);
            saData:=saRepeatChar('=',79)+csCRLF+
                    saJegasLogoRawText(csCRLF)+
                    saRepeatChar('=',79)+csCRLF+
                    'Requested path: '+saReqPath+csCRLF+
                    saRepeatChar('=',79)+csCRLF+
                    'DIRECTORY FLAGS - D=Dir R=ReadOnly H=Hidden S=SysFile V=VolumeID A=Archive'+csCRLF+
                    saRepeatChar('=',79)+csCRLF;
            //riteln('b4 getdir');
            saTempDir:='';
            bOk:=bGetDir(saReqPath,saTempDir,(name='rdir') or (name='rdircrc'),(name='dircrc') or (name='rdircrc'));
            if not bOk then
            begin
              writeln(201201031559,' - Unable to get directory: ' +saReqPath);
            end;
            //riteln('after dir');

            if bOk then
            begin
              // FLASHY SERVER - shows whole dir list
              writeln(saTempDir);
              // FLASHY SERVER - shows whole dir list
              
              
              bOk:=bSaveFile(csDirFilename,saData+saTempDir,1,1000,u2IOResult,false);
              if not bOk then
              begin
                writeln('201512300813 Unable to save '+csTempFile+' with ftp requested directory. IO Result: ' +inttostr(u2IOResult)+' - '+saIOResult(u2IOResult) );
              end;
            end;
          end
          else
          begin
            writeln('Unable to respond to client directory request.');
            bOk:=false;
          end;
        end; // end of the dir,rdir,dircrc,rdircrc command code
      end;
      TFTPDaemon.Data.SaveToFile(p_saFileName);
    end
    else
    begin
      writeln('!!!!! UNVALIDATED CLIENT KNOCKING AT THE DOOR !!!!!');
      writelN('Requestor: '+TFTPDaemon.FRequestIP+' Validated IP: '+saValidatedClientIP);
    end;
  end
  else
  begin
    Writeln('201512152230 - replyrecvfailed - bServerFunction');
  end;
  Writeln('END WRITE REQUEST. bOk: ',saYesNo(bOK));
  SrcDir.Destroy;
  result:=bOk;
end;
//=============================================================================





















//=============================================================================
procedure TTFTPDaemonThread.Execute;
//=============================================================================
var RequestType:Word;
    FileName:ansiString;
    bOk: boolean;
    u8ErrID: UInt64;
    saErrMsg: ansistring;
    //SrcDir: JFC_DIR;
    //saData,saPort: ansistring;
    //u2IOResult: word;
    //bOpen: boolean;
    i4TimeCheck: longint;
    c: char;
    dtLoop: TDATETIME;
    b2Fast: boolean;
//=============================================================================
begin
  //bOk:=true;
  //bOpen:=false;
  TFTPDaemon := TTFTPSend.Create;
  //FLogMessage := 'ServerThread created on Port ' + FPort;
  //Synchronize(UpdateLog);
  TFTPDaemon.TargetHost := FIPAdress;
  TFTPDaemon.TargetPort := FPort;
  i4TimeCheck:=0;
  c:='.';
  try
    bOk:=true;
    writeln('Waiting for requests on '+FIPADRESS+':'+FPort);
    b2Fast:=false;
    while not terminated do
    begin
      if not b2Fast then dtLoop:=now;
      if TFTPDaemon.WaitForRequest(RequestType,FileName)then
      begin
        case RequestType of
        1:begin
          bOk:=bReadRequest(Filename,u8ErrID,saErrMsg);  //case -  Read request (RRQ)
          if not bOk then
          begin
            write(c);c:='R'
          end;
        end;//case
        2:begin
          bOk:=bWriteRequest(FileName);  //case -  Write request (WRQ)
          if not bOk then
          begin
            write(c);c:='W'
          end;
        end//case
        else begin
          u8ErrID:=201512201747;saErrMsg:='Unexpected FTP Request Type: '+inttostr(RequestType)+'!! Think it''s a bad guy?';
          TFTPDaemon.ReplyError(u8ErrID,saErrMsg);
        end;//case
        end;//select
        i4TimeCheck+=1;
        if i4TimeCheck=100 then
        begin
          i4TimeCheck:=0;
          if iDiffMinutes(dtKeyValidated, now) > cnKeyValidationTimeOutInMinutes then
          begin
            saValidatedClientIP:='';
          end;
        end;
      end
      else
      begin
        if iDiffMSec(dtLoop,now) > 500 then
        begin
          write(c);c:='.';b2Fast:=false;
        end
        else
        begin
          c:='?';
          b2Fast:=true;
        end;
      end;
    end;//while
  finally
    TFTPDaemon.Free;
  end;
end;
//=============================================================================



end.
//=============================================================================
// EOF
//=============================================================================

