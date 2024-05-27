unit unitmain;

{$mode ObjFPC}{$H+}

interface

uses
  gemUtil, gemClock, gemprogram, process, Unix,
  Classes, SysUtils;

  procedure Main();
  procedure CheckOnline();
  procedure CheckParams();
  procedure CheckPrograms();
  procedure DisplayMenu();
  procedure RankMirrors();
  procedure GetUpdateCount();
  procedure MakeSnapshot();
  procedure DoUpdates();
  procedure DoTimeprune();
  procedure DoReboot();
  procedure ErrHalt(const aMessage: String = '');
  procedure ShowHelp();

var
  Pac: String = 'pacman'; // assume yay by default, correct to pacman later if yay doesn't exist
  UpdateCount: Integer = 0;
  EnableReboot: Boolean = False;
  EnableRank: Integer = 0;
  MirrorCount: Integer = 20;
  TimeOut: Integer = 10;
  ShowMenu: Integer = 0;
  Prog: TGEMProgram;

const
  Ver: String = 'Version 0.1';
  Prefix: String = #27'[33m[gembackupdate]'#27'[0m ';
  FrameStr: String = '|------------------------------------------------|';

implementation

procedure Main();
var
I: Integer;
  begin

    // create program instance, require root
    Prog := TGEMProgram.Create(True);

    WriteLn();
    WriteLn('gembackupdate ' + Ver);
    WriteLn('Hello, ' + Prog.UserName);
    WriteLn();

    // check for -h before anything else
    for I := 1 to ParamCount do begin
      if ParamStr(I) = '--help' then begin
        ShowHelp();
      end;
    end;

    CheckOnline();
    CheckParams();
    DisplayMenu();
    CheckPrograms(); // check for timeshift, pacman, yay
    GetUpdateCount(); // halts here on no update
    RankMirrors; // run reflector to update and rank mirrors if present
    MakeSnapshot();
    DoUpdates();
    DoTimeprune();
    DoReboot();

  end;

procedure CheckOnline();
var
proc: TProcess;
OList: TStringList;
  begin
    // check for wget
    if gemFileExists('/usr/bin/wget') = False then begin
      ErrHalt('wget not found in /usr/bin! This program uses wget to determine ' +
        'that there is an internet connection!');
    end;


    // check for internet connection
    Write(Prefix + 'Checking for internet connection...');

    OList := TStringList.Create();

    proc := TProcess.Create(nil);
    proc.Executable := '/bin/sh';
    proc.Parameters.Add('-c');
    proc.Parameters.add('wget -q -O - http://myexternalip.com/raw');
    proc.Options := proc.Options + [poWaitOnExit, poUsePipes];
    proc.Execute;

    OList.LoadFromStream(proc.Output);

    proc.Free;

    if OList.Count <> 0 then begin
      WriteLn(#27'[32m' + 'Found' + #27'[0m');
      Exit();
    end else begin
      WriteLn(#27'[31m' + '!NOT FOUND!' + #27'[0m');
      ErrHalt('Could not determine internet connection! An internet connection is required ' +
        'in order to run updates!');
    end;
  end;

procedure CheckParams();
var
I: Integer;
Skip: Boolean;
  begin

    if ParamCount = 0 then Exit();

    Skip := False;

    for I := 1 to ParamCount do begin

      if Skip then begin
        Skip := False;
        Continue;
      end;

      if ParamStr(I) = '--rank' then begin
        EnableRank := 1;
        ShowMenu := 0;

      end else if ParamStr(I) = '--norank' then begin
        EnableRank := 0;
        ShowMenu := 0;

      end else if ParamStr(I) = '--reboot' then begin
        EnableReboot := True;

      end else if ParamStr(I) = '-m' then begin
        Skip := True;
        if gemStrIsInt(ParamStr(I + 1)) then begin
          MirrorCount := Abs( ParamStr(I + 1).ToInteger() );
          if MirrorCount = 0 then MirrorCount := 20;
        end else begin
          ErrHalt('Found invalid value "' + ParamStr(I + 1) + '"!');
        end;

      end else if ParamStr(I) = '-t' then begin
        Skip := True;
        if gemStrIsInt(ParamStr(I + 1)) then begin
          Timeout := Abs( ParamStr(I + 1).ToInteger() );
          if Timeout = 0 then Timeout := 10;
        end else begin
          ErrHalt('Found invalid value "' + ParamStr(I + 1) + '"!');
        end;

      end else begin
        ErrHalt('Unrecognized option "' + ParamStr(I) + '"!');
      end;

    end;

  end;

procedure DisplayMenu();
  begin

    if ShowMenu = 1 then begin
      // initial menu


    end;

  end;

procedure CheckPrograms();
  begin
    // check for timeshift
    if gemFileExists('/usr/bin/timeshift') = False then begin
      ErrHalt('timeshift not found!');
    end;

    // check for yay
    if gemFileExists('/usr/bin/yay') then begin
      //Pac := 'yay';
      WriteLn(Prefix + 'Found yay... will update Arch repo packages and AUR packages...');
    end else begin
      // if yay not found, try to use pacman
      if gemFileExists('/usr/bin/pacman') then begin
        WriteLn(Prefix + 'Found pacman.. only Arch repo packages will be updated...');
      end else begin
          ErrHalt('Could not locate pacman or yay! Updates cannot be performed!');
      end;
    end;
  end;

procedure RankMirrors();
var
proc: TProcess;
  begin
    if EnableRank = 0 then begin
      WriteLn(Prefix + 'Mirror ranking not enabled... mirrors will not be updated...');
      Exit();
    end;

    WriteLn(Prefix + 'Checking for reflector...');

    if gemFileExists('/usr/bin/reflector') then begin
      WriteLn(Prefix + 'Found!');
      WriteLn(Prefix + 'Running reflector to update and rank mirror list...');
      WriteLn(Prefix + 'Ranking top ' + MirrorCount.ToString() + ' mirrors...');
      WriteLn(Prefix + 'Waiting ' + Timeout.ToString() + ' seconds for ranking timeout...');

      proc := TProcess.Create(nil);
      proc.Options := Proc.Options + [poWaitOnExit];

      proc.CommandLine := 'reflector --latest ' + MirrorCount.ToString() + ' --download-timeout ' + Timeout.ToString() +
        ' --protocol https --sort rate --save /etc/pacman.d/mirrorlist';

      proc.Execute();
      proc.Free();

      WriteLn(Prefix + 'Mirrors ranked!');

    end else begin
      WriteLn(Prefix + 'reflector not found... mirrors will not be updated or ranked...');
    end;

  end;

procedure GetUpdateCount();
var
proc: TProcess;
op: TStringList;
  begin
    op := TStringList.Create();

    WriteLn(Prefix + 'Syncing databases...');

    proc := TProcess.Create(nil);
    proc.Options := proc.Options + [poUsePipes, poWaitOnExit];
    proc.CommandLine := Pac + ' -Sy';
    proc.Execute();

    WriteLn(Prefix + 'Retrieving update count...');

    proc.Options := proc.Options + [poUsePipes, poWaitOnExit];
    proc.CommandLine := Pac + ' -Qu';
    proc.Execute();

    op.LoadFromStream(proc.Output);

    proc.Free();

    if op.Count <> 0 then begin
      WriteLn(Prefix + op.Count.ToString() + ' updates available!');
      UpdateCount := op.Count;
    end else begin
      WriteLn(Prefix + 'No updates available...');
      WriteLn(Prefix + 'Exiting...');
      Halt();
    end;
  end;

procedure MakeSnapshot();
var
proc: TProcess;
  begin
    WriteLn(Prefix + 'Creating new timeshift snapshot...');

    proc := TProcess.Create(nil);
    proc.Options := proc.Options + [poWaitOnExit];
    proc.CommandLine := 'timeshift --create --comments "gembackupdate"';
    proc.Execute();
    proc.Free();

    WriteLn(Prefix + 'Snapshot created!');
  end;

procedure DoUpdates();
var
proc: TProcess;
SString: TStringList;
CheckString: String;
I: Integer;
  begin
    WriteLn(Prefix + 'Performing updates with ' + Pac + '...');

    proc := TProcess.Create(nil);
    proc.Options := proc.Options + [poUsePipes, poStderrToOutPut];
    proc.CommandLine := Pac + ' -Syu';
    proc.Execute();

    SString := TStringList.Create();

    while proc.Active do begin

      while proc.Output.NumBytesAvailable <> 0 do begin
        SString.LoadFromStream(proc.Output);

        for I := 0 to SString.Count - 1 do begin
          WriteLn(SString[I]);

          CheckString := SString[I];
          CheckString := LowerCase(CheckString);

          if Pos('y/n', CheckString) <> 0 then begin
            CheckString := 'y' + #10;
            proc.Input.Write(CheckString[1], Length(CheckString));
          end;
        end;
      end;

    end;

    proc.Free();

    WriteLn(Prefix + 'Updates finished!');
  end;

procedure DoTimeprune();
var
proc: TProcess;
  begin
    WriteLn(Prefix + 'Executing timeprune...');

    proc := TProcess.Create(nil);
    proc.Options := proc.Options + [poWaitOnExit];
    proc.CommandLine := 'timeprune';
    proc.Execute();
    proc.Free();

    WriteLn('timeprune finished!');

  end;

procedure DoReboot();
var
retstr: String;
Clock: TGEMClock;
  begin
    if EnableReboot = False then Exit();

    WriteLn('Rebooting in 5 seconds...');

    Clock := TGEMClock.Create(1);
    Clock.SetIntervalInSeconds(5);
    Clock.Start();
    Clock.Wait();

    Clock.Free();

    RunCommand('reboot', retstr);
  end;

procedure ErrHalt(const aMessage: String = '');
  begin
    WriteLn('ERROR: ' + aMessage);
    WriteLn('Use option --help to view help.');
    WriteLn('Exiting...');
    Halt();
  end;

procedure ShowHelp();
  begin
    WriteLn('Displaying help...');
    WriteLn(FrameStr);
    WriteLn('  --rank     Enable pacman mirror ranking');
    WriteLn('  --norank   Disable pacman mirror ranking');
    WriteLn('  --reboot   Enable reboot after updates');
    WriteLn('  -m #       Rank # mirrors (default=20). Use with --rank');
    WriteLn('  -t #       Timeout ranking after # seconds per mirror (default=10). Use with --rank');
    WriteLn('  --help  Display help');
    Halt();
  end;

end.

