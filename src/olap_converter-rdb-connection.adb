with Qt4;
with Qt4.Variants;
with Qt4.Strings;
with Qt4.Sql_Queries;
--with Qt4.Sql_Databases;
with Qt4.Sql_Records;
use Qt4.Sql_Records;

--  --/stub: use Generic_Constructor later
with OLAP_Converter.RDB.Connection.MySQL;
with Ada.Text_IO;
--  --\stub

package body OLAP_Converter.RDB.Connection is
   use Qt4.Sql_Databases;

   -------------
   -- Connect --
   -------------

   function Connect
     (Driver_Name   : String;
      Host_Name     : String;
      Database_Name : Wide_String;
      User_Name     : String;
      Password      : String) return RDB_Connection
   is
      use Qt4.Strings;
      use Standard;
      use Qt4;

      function Pull_Schema (Access_System : Access_DBMS) return RDB_Schema;

      function Pull_Schema (Access_System : Access_DBMS) return RDB_Schema
      is
         Table_Name : Q_String := From_Utf_16("");
         Q_List     : Q_String_List;
         Schema     : RDB_Schema;

      begin
         null;
         Q_List := Qt4.Sql_Databases.Tables (Access_System.DB);

         Fill_Relations_Of_Schema:
         declare
            Relations : Relation_Array (1..Standard.Integer (Size (Q_List)));

         begin
            for I in 0 .. (Size (Q_List) - 1) loop
               Table_Name := Qt4.Strings.Value (Q_List, I);
               --Relations (Standard.Integer (I + 1)) := Table (Access_System, To_Utf_8 (Table_Name));
               Append (Relations (Standard.Integer (I + 1)).Name, To_Utf_8 (Table_Name));
               Access_System.Attributes (Relations (Standard.Integer (I + 1)));

               Access_System.Primary_Key (Relations (Standard.Integer (I + 1)));
               declare
                  test_array : Attribute_Array := Relations (Standard.Integer (I + 1)).Primary;
               begin
                  null;
               end;
            end loop;

            Set_Schema (Relations, Schema);
         end Fill_Relations_Of_Schema;

         return Schema;
      end Pull_Schema;

      Access_System : Access_DBMS;
      Result        : RDB_Connection;
   begin
      --/stub: use Generic_Constructor later
      Access_System := new OLAP_Converter.RDB.Connection.MySQL.DBMS;
      --\stub
      Append (Access_System.Name, Driver_Name);
      --Append (Access_System.DB_Name, Database_Name);

      --Qt4.Sql_Databases.Remove_Database (Default_Connection);
      Access_System.DB := Qt4.Sql_Databases.Add_Database
        (From_Utf_8 (Driver_Name));
      --From_Utf_16 (Database_Name));

      Access_System.DB.Set_Host_Name (From_Utf_8 (Host_Name));
      Access_System.DB.Set_Database_Name (From_Utf_16 (Database_Name));
      Access_System.DB.Set_User_Name (From_Utf_8 (User_Name));
      Access_System.DB.Set_Password (From_Utf_8 (Password));

      if not Access_System.DB.Open then
         raise Program_Error;
      end if;

      Result.Schema := Pull_Schema (Access_System);
      Result.Access_System := Access_System;
      return Result;
   end Connect;

   ----------------
   -- Disconnect --
   ----------------

   procedure Disconnect (RDB_C : in out RDB_Connection)
   is
   begin
      Free_DBMS (RDB_C.Access_System);
      Remove_Database (Default_Connection);
      Clear_Schema (RDB_C.Schema);
   end Disconnect;

   ----------------
   -- Set_Schema --
   ----------------

   procedure Set_Schema
     (Relations : in     Relation_Array;
      Schema    :    out RDB_Schema)
   is
      function Other_Attributes (R : Relation) return Attribute_Array
      is
         Primary : constant Attribute_Array := R.Primary;
         Result : Attribute_Array (1..R.Attributes'Length - Primary'Length);
         Found : Boolean := False;
         K : Positive := 1;
      begin
         for I in R.Attributes'Range loop
            Found := False;
            Inner_Loop:
            for J in Primary'Range loop
               if Primary (J) = R.Attributes (I) then
                  Found := True;
                  exit Inner_Loop;
               end if;
            end loop Inner_Loop;

            if not Found then
               Result (K) := R.Attributes (I);
               K := K + 1;
            end if;
         end loop;

         return Result;
      end Other_Attributes;

   begin
      Schema.Relations := new Relation_Array (Relations'Range);
      Schema.Functional_Dependencies := new FD_Array (Relations'Range);
      for I in Relations'Range loop
         Schema.Relations (I) := Relations (I);
         Schema.Functional_Dependencies (I) :=
           Create_FD (Relations (I).Primary, Other_Attributes (Relations (I)));
      end loop;

   end Set_Schema;

   ------------------
   -- Clear_Schema --
   ------------------

   procedure Clear_Schema (Schema : in out RDB_Schema) is
   begin
      for I in Schema.Relations.all'Range loop
         Delete_Relation (Schema.Relations.all (I));
      end loop;
      Free_Relation_Array (Schema.Relations);

      if Schema.Functional_Dependencies /= null then
         for I in Schema.Functional_Dependencies.all'Range loop
            Delete_FD (Schema.Functional_Dependencies.all (I));
         end loop;
         Free_FD_Array (Schema.Functional_Dependencies);
      end if;

      if Schema.Functional_Dependencies /= null then
         for I in Schema.Multi_Valued_Dependencies.all'Range loop
            Delete_MVD (Schema.Multi_Valued_Dependencies.all (I));
         end loop;
         Free_MVD_Array (Schema.Multi_Valued_Dependencies);
      end if;
   end Clear_Schema;

   -----------
   -- Table --
   -----------

   function Table
     (Self : not null access DBMS'Class;
      Name : String) return Relation
   is
      use Qt4.Sql_Records;
      use Qt4.Strings;
      use type Qt4.Q_Integer;

      Cur_Record : constant Q_Sql_Record :=
        Self.DB.Table_Record (From_Utf_8 (Name));
      Attributes : Attribute_Array (1..Standard.Integer (Qt4.Sql_Records.Count (Cur_Record)));
   begin
      for J in 0 .. Count (Cur_Record) - 1 loop
         Attributes (Standard.Integer (J + 1)) :=
           (Name => To_Unbounded_String (To_Utf_8 (Field_Name (Cur_Record, J))),
            Relation_Name => To_Unbounded_String (Name),
            Current_Value => To_Unbounded_String(""),
            Value_Type => To_Unbounded_String("No_Value_Type"),
            Value_Amount => 0);
      end loop;

      return Create_Relation (Name, Attributes);
   end Table;

   ----------------------
   -- Count_Attributes --
   ----------------------

   procedure Count_Attributes
     (Self : not null access DBMS'Class;
      R    : in out Relation)
   is
      use Qt4;
      use Qt4.Variants;
      use Qt4.Strings;
      Query        : aliased Qt4.Sql_Queries.Q_Sql_Query := Self.DB.Create;
      Query_String : Unbounded_String := To_Unbounded_String ("select ");
   begin
      Append (Query_String, To_Unbounded_String ("count(distinct "));
      Append (Query_String, Attribute_Names (R.Attributes.all, "), count(distinct "));
      Append (Query_String, To_Unbounded_String (") "));
      Append (Query_String, To_Unbounded_String ("from "));
      Append (Query_String, R.Name);
      Append (Query_String, To_Unbounded_String (";"));

      if Query.Exec (From_Utf_8 (To_String (Query_String))) and Query.Next then
         for I in R.Attributes'Range loop
            R.Attributes (I).Value_Amount := Integer (Query.Value (Q_Integer (I - 1)).To_Integer);
         end loop;
      end if;
   end Count_Attributes;

   ----------------
   -- Drop_Table --
   ----------------

   procedure Drop_Table
     (Self : not null access DBMS;
      R    : Relation)
   is
      use Qt4;
      use Qt4.Variants;
      use Qt4.Strings;
      Query        : aliased Qt4.Sql_Queries.Q_Sql_Query := Self.DB.Create;
      Query_String : Unbounded_String := To_Unbounded_String ("drop table ");
   begin
      Append (Query_String, R.Name);
      Append (Query_String, To_Unbounded_String (";"));

      if not Query.Exec (From_Utf_8 (To_String (Query_String))) then
         raise Program_Error;
      end if;
   end Drop_Table;


   --------------------------
   -- Inclusion_Dependency --
   --------------------------

   function Inclusion_Dependency
     (Self : not null access DBMS'Class;
      R1   : in Relation;
      R2   : in Relation;
      X    : in Attribute_Array) return Boolean
   is
      use Qt4;
      use Qt4.Variants;
      use Qt4.Strings;
      Query        : aliased Qt4.Sql_Queries.Q_Sql_Query := Self.DB.Create;
      Query_String : Unbounded_String := To_Unbounded_String ("select count(distinct ");
      Attrs_String : constant Unbounded_String := Attribute_Names (X, ", ");
   begin
      Append (Query_String, Attrs_String);
      Append (Query_String, To_Unbounded_String (") as amount"));
      Append (Query_String, To_Unbounded_String (" from "));
      Append (Query_String, R1.Name);
      Append (Query_String, To_Unbounded_String (" join "));
      Append (Query_String, R2.Name);
      Append (Query_String, To_Unbounded_String (" using ("));
      Append (Query_String, Attrs_String);
      Append (Query_String, To_Unbounded_String (") having amount = (select count(distinct "));
      Append (Query_String, Attrs_String);
      Append (Query_String, To_Unbounded_String (") "));
      Append (Query_String, To_Unbounded_String ("from "));
      Append (Query_String, R1.Name);
      Append (Query_String, To_Unbounded_String (");"));

      if not Query.Exec (From_Utf_8 (To_String (Query_String))) then
         raise Program_Error;
      else
         if Query.Next then
            return True;
         else
            return False;
         end if;
      end if;

      --        "select count(distinct value) as amount"
      --         "    from table1 "
      --         "      join table2"
      --          "       using (value)"
      --           "      having amount = (select count(distinct value) from table1);"
      -- R1 x R2, count = count (R1)
   end Inclusion_Dependency;

   ------------
   -- Values --
   ------------

   procedure Values
     (Self   : not null access DBMS'Class;
      R      : Relation;
      Params : Attribute_Array;
      X      : in out Attribute_Array)
   is
      use Qt4;
      use Qt4.Variants;
      use Qt4.Strings;
      Query        : aliased Qt4.Sql_Queries.Q_Sql_Query := Self.DB.Create;
      Query_String : Unbounded_String := To_Unbounded_String ("select ");
   begin
      Append (Query_String, Attribute_Names (X, ", "));
      Append (Query_String, To_Unbounded_String (" from "));
      Append (Query_String, R.Name);
      Append (Query_String, To_Unbounded_String (" where "));

      for I in Params'Range loop
         Append (Query_String, Params (I).Name);
         Append (Query_String, "='");
         Append (Query_String, Params (I).Current_Value);
         Append (Query_String, ("'"));
         if I /= Params'Last then
            Append (Query_String, To_Unbounded_String (" and "));
         end if;
      end loop;

      Append (Query_String, To_Unbounded_String (";"));

      if Query.Exec (From_Utf_8 (To_String (Query_String))) and Query.Next then
         for I in X'Range loop
            X (I).Current_Value := To_Unbounded_String (To_Utf_8 ( Query.Value (Q_Integer (I - 1)).To_String));
         end loop;
      end if;
   end Values;

   ---------------------
   -- Attribute_Names --
   ---------------------

   function Attribute_Names
     (Attrs    : Attribute_Array;
      Modifier : String) return Unbounded_String
   is
      Result_String : Unbounded_String;
   begin
      for I in Attrs'Range loop
         Append (Result_String, Attrs (I).Name);
         if I /= Attrs'Last then
            Append (Result_String, To_Unbounded_String (Modifier));
         end if;
      end loop;
      return Result_String;
   end Attribute_Names;

end OLAP_Converter.RDB.Connection;