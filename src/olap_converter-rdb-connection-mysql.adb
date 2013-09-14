with Qt4;               use Qt4;
with Qt4.Sql_Queries;   use Qt4.Sql_Queries;
with Qt4.Variants;      use Qt4.Variants;
with Qt4.Strings;       use Qt4.Strings;

package body OLAP_Converter.RDB.Connection.MySQL is
   procedure Attributes
     (Self : not null access DBMS;
      R    : in out Relation)
   is      Query        : aliased Qt4.Sql_Queries.Q_Sql_Query := Self.DB.Create;
      Query_String : Unbounded_String :=
        To_Unbounded_String ("select COLUMN_NAME " &
                               "from information_schema.COLUMNS " &
                               "where ");
   begin
      Append (Query_String, To_Unbounded_String ("TABLE_SCHEMA='"));
      Append (Query_String, To_Unbounded_String (To_Utf_8 (Self.DB.Database_Name)));
      Append (Query_String, To_Unbounded_String ("' and TABLE_NAME='"));
      Append (Query_String, R.Name);
      Append (Query_String, To_Unbounded_String ("';"));

      if Query.Exec (From_Utf_8 (To_String (Query_String))) then
         if Query.Size /= -1 then
            declare
               I : Positive := 1;
            begin
               R.Attributes := new Attribute_Array (1 .. Integer (Query.Size));
               while Query.Next loop
                  R.Attributes (I) :=
                    (Name => To_Unbounded_String (To_Utf_8 (Query.Value (Q_Integer (0)).To_String)),
                     Relation_Name => R.Name,
                     Current_Value => To_Unbounded_String(""),
                     Value_Type => To_Unbounded_String("No_Value_Type"),
                     Value_Amount => 0);
                  I := I + 1;
               end loop;
            end;
         end if;
      end if;
   end Attributes;

   procedure Primary_Key
     (Self : not null access DBMS;
      R    : in out Relation)
   is
      function Attr_Search (Name : Unbounded_String) return Positive;

      function Attr_Search (Name : Unbounded_String) return Positive
      is
      begin
         for I in R.Attributes'Range loop
            if R.Attributes (I).Name = Name then
               return I;
            end if;
         end loop;

         --no attr found in attribute list of relation
         raise Program_Error;
      end Attr_Search;

      Query        : aliased Qt4.Sql_Queries.Q_Sql_Query := Self.DB.Create;
      Query_String : Unbounded_String :=
        To_Unbounded_String ("select COLUMN_NAME " &
                               "from information_schema.COLUMNS " &
                               "where ");
   begin
      Append (Query_String, To_Unbounded_String ("TABLE_SCHEMA='"));
      Append (Query_String, To_Unbounded_String (To_Utf_8 (Self.DB.Database_Name)));
      Append (Query_String, To_Unbounded_String ("' and TABLE_NAME='"));
      Append (Query_String, R.Name);
      Append (Query_String, To_Unbounded_String ("' and COLUMN_KEY='PRI';"));

      if Query.Exec (From_Utf_8 (To_String (Query_String))) then
         if Query.Size /= -1 then
            declare
               I : Positive := 1;
            begin
               R.Primary_Key := new Index_Array (1 .. Integer (Query.Size));
               while Query.Next loop
                  R.Primary_Key (I) := Attr_Search
                    (To_Unbounded_String (To_Utf_8 (Query.Value (Q_Integer (0)).To_String)));
                  I := I + 1;
               end loop;
            end;
         end if;
      end if;
      --        select COLUMN_NAME
      --             from information_schema.COLUMNS
      --               where TABLE_SCHEMA='faculty_xp'
      --               and TABLE_NAME='INFO'
      --               and COLUMN_KEY='PRI';
   end Primary_Key;

   procedure Create_Table
     (Self : not null access DBMS;
      R    : Relation;
      Temp : Boolean := True)
   is
      Query        : aliased Qt4.Sql_Queries.Q_Sql_Query := Self.DB.Create;
      Query_String : Unbounded_String := To_Unbounded_String ("create ");
   begin
      if Temp then
         Append (Query_String, "temporary ");
      end if;
      Append (Query_String, "table ");
      Append (Query_String, R.Name);
      Append (Query_String, "(");
      for I in R.Attributes'Range loop
         Append (Query_String, R.Attributes (I).Name);
         Append (Query_String, To_Unbounded_String (" "));
         Append (Query_String, R.Attributes (I).Value_Type);

         if I /= R.Attributes'Last then
            Append (Query_String, To_Unbounded_String (", "));
         else
            if R.Primary_Key /= null then
               Append (Query_String, To_Unbounded_String (", primary key ("));
               Append (Query_String, Attribute_Names (R.Primary, ", "));
               Append (Query_String, To_Unbounded_String (")"));
            end if;
            Append (Query_String, To_Unbounded_String (") "));
         end if;
      end loop;

      Append (Query_String, To_Unbounded_String ("ENGINE=myisam DEFAULT CHARSET=utf8;"));

      if not Query.Exec (From_Utf_8 (To_String (Query_String))) then
         raise Program_Error;
      end if;
   end Create_Table;

   procedure Create_TJ
     (Self      : not null access DBMS;
      Name      : String;
      DB_Name   : String := "";
      Relations : Relation_Array;
      Attrs     : Attribute_Array;
      Formula   : String)
   is
      Query        : aliased Qt4.Sql_Queries.Q_Sql_Query := Self.DB.Create;
      Query_String : Unbounded_String := To_Unbounded_String ("create table ");
      Full_Name    : Unbounded_String;
   begin
      if DB_Name /= "" then
         Full_Name := To_Unbounded_String (DB_Name & "." & Name);
      else
         Full_Name := To_Unbounded_String (Name);
      end if;

      Append (Query_String, Full_Name);
      Append (Query_String, To_Unbounded_String (" select distinct "));
      Append (Query_String, Attribute_Names (Attrs, ","));
      Append (Query_String, To_Unbounded_String ("from ("));

      for I in Relations'Range loop
         Append (Query_String, Relations (I).Name);

         if I /= Relations'Last then
            Append (Query_String, To_Unbounded_String (" natural join "));
         else
            Append (Query_String, To_Unbounded_String (");"));--!remove ; after Formula insert
         end if;
      end loop;

      --!Add this when predicates are ready: Append (Query_String, To_Unbounded_String ("where " & Formula & ";"));

      if not Query.Exec (From_Utf_8 (To_String (Query_String))) then
         raise Program_Error;
      end if;
   end Create_TJ;

--     create table metadb_name.TJ_R1_R2_R3
--     select
--        distinct A, D, F
--          from
--            (R1 natural join
--                 R2 natural join
--                   R3);

   --  OPTIMIZED:
   --              select * into 'newtable'
   --                   from
   --                   ((select distinct A, C from R1) as R1
   --                      join
   --                        (select distinct C, E from R2) as R2 using (C)
   --                      join
   --                        (select distinct E, G from R3) as R3 using (E));


end OLAP_Converter.RDB.Connection.MySQL;