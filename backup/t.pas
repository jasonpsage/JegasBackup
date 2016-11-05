program t;
uses sysutils;
var f: text;
begin
  deletefile('./t2/a.txt');
  assign(f,'./t2/a.txt');
  rewrite(f);
  writeln(f,'hello');
  close(f);
  writeln(fileexists('./t2/a.txt'));
end.
