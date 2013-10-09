with Ada.Text_IO;

procedure OLAP_Converter.Connection_Table.Test
is
   use Ada.Text_IO;
   use OLAP_Converter.RDB.Connection;
   use OLAP_Converter.RDB;

   Test_Name : constant String := "Connection_Table.Test";

   procedure Print (S : String) is
   begin
      Put_Line (Test_Name & " : " & S);
   end Print;

--     function Attr
--       (Attr_Name  : String;
--        Rel_Name   : String := "";
--        Attr_Type  : String := "";
--        Attr_Value : String := "") return Attribute
--     is
--     begin
--        return (Name => To_Unbounded_String (Attr_Name),
--                Relation_Name => To_Unbounded_String (Rel_Name),
--                Value_Type => To_Unbounded_String (Attr_Type),
--                Current_Value => To_Unbounded_String (Attr_Value),
--                Value_Amount => 0);
--     end Attr;

   Connection : RDB_Connection
     := Connect
       (Driver_Name   => "QMYSQL",
        Host_Name     => "localhost",
        Database_Name => "TJ_Test_2",
        User_Name     => "root",
        Password      => "mysql");
begin
   Print ("Create TJ from given relations and attributes");
   declare
      A       : constant Attribute := Create_Attribute ("A");
      B       : constant Attribute := Create_Attribute ("B");
      C       : constant Attribute := Create_Attribute ("C");
      D       : constant Attribute := Create_Attribute ("D");
      E       : constant Attribute := Create_Attribute ("E");
      F       : constant Attribute := Create_Attribute ("F");
      G       : constant Attribute := Create_Attribute ("G");

      Attrs   : constant Attribute_Array := (A, B, C, D, E, F, G);

      R1 : constant Relation := Create_Relation ("R1", (A, B, C));
      R2 : constant Relation := Create_Relation ("R2", (C, D, E));
      R3 : constant Relation := Create_Relation ("R3", (E, F, G));

      P       : Predicate;

      DB_Name    : constant String := "test";
      Table_Name : constant String := "TJ_R1_R2_R3";
      TJ_Name    : constant String := Full_Name (DB_Name, Table_Name);

      Checked_Result : Relation;

      Raised : Boolean := False;
   begin
      if Connection.Access_System.Table (TJ_Name).Attributes.all
        /= Empty_Attr_Array
      then
         Connection.Access_System.Drop_Table (TJ_Name);
      end if;

      Checked_Result := TJ
        (Self       => Connection.Access_System,
         Name       => TJ_Name,
         Attrs      => Attrs,
         Context    => (R1, R2, R3),
         P          => P);

      declare
      begin
         if Checked_Result.Name /= TJ_Name then
            Print ("Created TJ has wrong name");
            raise Program_Error;
         elsif Checked_Result.Attributes'Length /= Attrs'Length then
            Print ("Created TJ has wrong amount of attributes");
            raise Program_Error;
         elsif Checked_Result.Attributes.all /=
           (B, E, F, C, A, G, D) then
            Print ("Created TJ has wrong attribute order");
            raise Program_Error;
         end if;
      exception
         when others =>
            Raised := True;
      end;

      Delete_Relation (R1);
      Delete_Relation (R2);
      Delete_Relation (R3);
      Connection.Access_System.Drop_Table (TJ_Name);
      Disconnect (Connection);

      if Raised then
         raise Program_Error;
      end if;
   exception
      when others =>
         Print ("!!! Error occured");
         raise Program_Error;
   end;
end OLAP_Converter.Connection_Table.Test;

