with Ada.Text_IO;

procedure OLAP_Converter.RDB.Connection.MySQL.Test
is
   use Ada.Text_IO;
   use OLAP_Converter.RDB.Connection;
   use OLAP_Converter.RDB;

   Test_Name : constant String := "RDB.Connection.MySQL.Test";

   procedure Print (S : String) is
   begin
      Put_Line (Test_Name & " : " & S);
   end Print;

   function Attr
     (Attr_Name  : String;
      Rel_Name   : String := "";
      Attr_Type  : String := "";
      Attr_Value : String := "") return Attribute
   is
   begin
      return (Name => To_Unbounded_String (Attr_Name),
              Relation_Name => To_Unbounded_String (Rel_Name),
              Value_Type => To_Unbounded_String (Attr_Type),
              Current_Value => To_Unbounded_String (Attr_Value),
              Value_Amount => 0);
   end Attr;

   Connection : RDB_Connection
     := Connect
       (Driver_Name   => "QMYSQL",
        Host_Name     => "localhost",
        Database_Name => "test",
        User_Name     => "root",
        Password      => "mysql");
begin
   --     Print ("Attribute Names");
   --     declare
   --        Attrs
   --     begin
   --        Attribute_Names
   --          (Attrs : Attribute_Array;
   --           Modifier : String) return
   --        end;

   --if Connection.Open then
   --Close

   Print ("Create temporary table"); --!remove after initial testing, because it's gonna be used in other tests
   declare
      Table_Name : constant String := "Test_Table"; --!place this name in attributes Relation name field. Add Value type getting
      --!to RDB.Connection.Connect function => easy equality check
      Id             : constant Attribute := Attr (Attr_Name => "id", Attr_Type => "Int(11)");
      Name           : constant Attribute := Attr (Attr_Name => "Name",Attr_Type => "Varchar(255)");
      Some_Date      : constant Attribute := Attr (Attr_Name => "Some_Date",Attr_Type =>  "Date");
      R              : Relation;
      PK             : Index_Array (1..1);
      Checked_Result : Relation;
   begin
      PK (1) := 1;
      R := Create_Relation (Table_Name, (Id, Name, Some_Date), PK);
      PK (1) := 2;

      Connection.Access_System.Create_Table (R);

      Checked_Result := Table (Connection.Access_System, Table_Name);
      Print ("Table successfully created");
      Connection.Access_System.Drop_Table (Checked_Result);
   exception
      when others =>
         Print ("!!! Error in creating temp table");
         raise Program_Error;
   end;

   Print ("Get Primary Key");
   -- get all Primary Key attributes
   -- (several in the case of complex key)
   declare
      Table_Name : constant String := "Test_Table"; --!place this name in attributes Relation name field. Add Value type getting
      --!to RDB.Connection.Connect function => easy equality check
      Id1            : constant Attribute := Attr (Attr_Name => "id1", Attr_Type => "Int(11)");
      Id2            : constant Attribute := Attr (Attr_Name => "id2", Attr_Type => "Int(11)");
      Name           : constant Attribute := Attr (Attr_Name => "Name", Attr_Type => "Varchar(255)");
      Some_Date      : constant Attribute := Attr (Attr_Name => "Some_Date", Attr_Type => "Date");
      PK             : constant Index_Array := (1, 2);
      R              : constant Relation
        := Create_Relation (Table_Name, (Id1, Id2, Name, Some_Date), PK);
      Checked_Result : Relation;
   begin
      Connection.Access_System.Create_Table (R, False);

      Checked_Result.Name := R.Name;
      Checked_Result.Attributes := new Attribute_Array (R.Attributes'Range);
      Checked_Result.Attributes.all := R.Attributes.all;
      Connection.Access_System.Primary_Key (Checked_Result);
      if Checked_Result.Primary_Key.all /= PK then
         Print ("Wrong Primary Key assignment");
         raise Program_Error;
      else
         Print ("Primary Key successfully assigned");
      end if;
      Connection.Access_System.Drop_Table (Checked_Result);
   exception
      when others =>
         Print ("!!! Error occured");
         raise Program_Error;
   end;

   Print ("Get Values");
   declare
      Table_Name     : constant String := "employee";
      Dept           : constant Attribute := Attr (Attr_Name => "Dept", Attr_Value => "Sales");
      Name           : constant Attribute := Attr (Attr_Name => "Name", Attr_Value => "Barney Rubble");
      Job_Title      : constant Attribute := Attr (Attr_Name => "jobTitle");
      Params         : constant Attribute_Array (1..2) := (Dept, Name);
      X              : Attribute_Array (1..1);
      R              : Relation;
   begin
      R.Name := To_Unbounded_String (Table_Name);
      X (1) := Job_Title;
      Connection.Access_System.Values (R, Params, X);
      -- return R[X] where Params specify particular attribute values
      -- if several results are returned, then only the 1st row is evaluated

      if X (1).Current_Value /= "Neighbor"
      then
         Print ("Wrong 'Values' query result");
         raise Program_Error;
      else
         Print ("Values are received correctly");
      end if;
   exception
      when others =>
         Print ("!!! Error occured");
         raise Program_Error;
   end;

   Print ("Check Inclusion Dependency in following relations");
   -- check if R1[X] is a subset of R2[X]
   declare
      Value          : constant Attribute := Attr (Attr_Name => "value");
      X              : Attribute_Array (1..1);
      R1, R2         : Relation;
   begin
      R1.Name := To_Unbounded_String ("table1");
      R2.Name := To_Unbounded_String ("table2");
      X (1) := Value;
      -- return R[X] where Params specify particular attribute values
      -- if several results are returned, then only the 1st row is evaluated

      if not Connection.Access_System.Inclusion_Dependency (R1, R2, X)
      then
         Print ("R1 is not evaluated as a subset of R2");
         raise Program_Error;
      else
         Print ("R1 is a subset of R2");
      end if;
   exception
      when others =>
         Print ("!!! Error occured");
         raise Program_Error;
   end;

   Print ("Count Attributes in given relation");
   -- count distinct values of all attributes in relation");
   declare
      --!fail after another db select, just a stub for Values query check
      Table_Name       : constant String := "employee";
      Name             : constant Attribute := Attr (Attr_Name => "Name");
      Dept             : constant Attribute := Attr (Attr_Name => "Dept");
      Job_Title        : constant Attribute := Attr (Attr_Name => "jobTitle");
      Name_Amount      : constant Positive := 4;
      Job_Title_Amount : constant Positive := 3;
      R                : Relation := Create_Relation (Table_Name, (Name, Dept, Job_Title));
   begin
      Connection.Access_System.Count_Attributes (R);

      if R.Attributes (1).Value_Amount /= Name_Amount or else
        R.Attributes (3).Value_Amount /= Job_Title_Amount
      then
         Print ("Wrong 'Count_Attributes' query result");
         raise Program_Error;
      else
         Print ("Attribute amounts returned are correct");
      end if;
   exception
      when others =>
         Print ("!!! Error occured");
         raise Program_Error;
   end;

   Print ("Create TJ from given relations and attributes");
   declare
      A       : constant Attribute := Create_Attribute ("A");
      B       : constant Attribute := Create_Attribute ("B");
      C       : constant Attribute := Create_Attribute ("C");
      D       : constant Attribute := Create_Attribute ("D");
      E       : constant Attribute := Create_Attribute ("E");
      F       : constant Attribute := Create_Attribute ("F");
      G       : constant Attribute := Create_Attribute ("G");

      A_Amount : constant Natural := 3;
      D_Amount : constant Natural := 4;
      F_Amount : constant Natural := 4;

      R1      : Relation := Create_Relation ("R1", (A, B, C));
      R2      : Relation := Create_Relation ("R2", (C, D, E));
      R3      : Relation := Create_Relation ("R3", (E, F, G));

      Formula : constant String := "";
      TJ_Name : constant String := "TJ_R1_R2_R3";
      Checked_Result : Relation;
   begin
      Connection.Access_System.Create_TJ
        (Name      => TJ_Name,
         Relations => (R1, R2, R3),
         Attrs     => (A, B, C, D, E, F, G),
         Formula   => Formula);

      Checked_Result := Connection.Access_System.Table (TJ_Name);
      Connection.Access_System.Count_Attributes (Checked_Result);

--        procedure Create_TJ
--          (Self      : not null access DBMS;
--           Name      : String;
--           DB_Name   : String := "";
--           Relations : Relation_Array;
--           Attrs     : Attribute_Array;
--           Formula   : String)

      if Checked_Result.Attributes (1).Value_Amount /= A_Amount
        or else Checked_Result.Attributes (2).Value_Amount /= D_Amount
        or else Checked_Result.Attributes (3).Value_Amount /= F_Amount
      then
         Print ("Wrong 'Count_Attributes' query result");
         raise Program_Error;
      else
         Print ("Attribute amounts returned are correct");
      end if;
   exception
      when others =>
         Print ("!!! Error occured");
         raise Program_Error;
   end;
end OLAP_Converter.RDB.Connection.MySQL.Test;

