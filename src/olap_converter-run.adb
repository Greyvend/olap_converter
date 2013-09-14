with OLAP_Converter.RDB.Connection; use OLAP_Converter.RDB.Connection;

with OLAP_Converter.Contexts;
with OLAP_Converter.Contexts.Test;
with OLAP_Converter.RDB.Connection.MySQL.Test;
with OLAP_Converter.Connection_Table.Test;

procedure OLAP_Converter.Run
is
   Connection : RDB_Connection;
begin
   Connection := Connect
     (Driver_Name   => "QMYSQL",
      Host_Name     => "localhost",
      Database_Name => "test",
      User_Name     => "root",
      Password      => "mysql");
Commit to git first!!!!!!!!!!
   OLAP_Converter.Contexts.Test;
   OLAP_Converter.RDB.Connection.MySQL.Test;

   Disconnect (Connection);
end OLAP_Converter.Run;
