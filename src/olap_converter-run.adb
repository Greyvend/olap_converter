with OLAP_Converter.RDB.Connection; use OLAP_Converter.RDB.Connection;

with OLAP_Converter.Contexts;
with OLAP_Converter.Contexts.Test;
with OLAP_Converter.RDB.Connection.MySQL.Test;
with OLAP_Converter.Connection_Table.Test;

procedure OLAP_Converter.Run
is
begin
   OLAP_Converter.Contexts.Test;
   OLAP_Converter.RDB.Connection.MySQL.Test;
end OLAP_Converter.Run;
