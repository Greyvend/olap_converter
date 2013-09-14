with Ada.Text_IO;
with OLAP_Converter.RDB.Connection;

procedure OLAP_Converter.Contexts.Test
is
   use Ada.Text_IO;
   use OLAP_Converter.RDB.Connection;
   use OLAP_Converter.RDB;

   Test_Name : constant String := "Contexts.Test";

   procedure Print (S : String) is
   begin
      Put_Line (Test_Name & " : " & S);
   end Print;

begin

   Print ("Simple test on Lossless join");
   declare
      S       : constant Attribute := Create_Attribute ("S");
      A       : constant Attribute := Create_Attribute ("A");
      I       : constant Attribute := Create_Attribute ("I");
      P       : constant Attribute := Create_Attribute ("P");

      R1      : constant Relation  := Create_Relation ("SA", (S, A));
      R2      : constant Relation  := Create_Relation ("SIP", (S, I, P));

      D1, D2      : Functional_Dependency;
      Is_Lossless : Boolean := False;
   begin
      -- D2 := SI -> P
      D1.Left          := new Attribute_Array (1..2);
      D1.Right         := new Attribute_Array (1..1);
      D1.Left.all (1)  := S;
      D1.Left.all (2)  := I;
      D1.Right.all (1) := P;

      -- D2 := S -> A
      D2.Left          := new Attribute_Array (1..1);
      D2.Right         := new Attribute_Array (1..1);
      D2.Left.all (1)  := S;
      D2.Right.all (1) := A;

      Is_Lossless := Is_Lossless_Join ((R1, R2), (D1, D2));

      if Is_Lossless then
         Print ("Losses join is held");
      else
         Print ("Losses join is abandoned");
         Delete_FD (D1);
         Delete_FD (D2);
         Delete_Relation (R1);
         Delete_Relation (R2);
         raise Program_Error;
      end if;

      Delete_FD (D1);
      Delete_FD (D2);
      Delete_Relation (R1);
      Delete_Relation (R2);
   end;

   Print ("Advanced test on Lossless join");
   declare
      A       : constant Attribute := Create_Attribute ("A");
      B       : constant Attribute := Create_Attribute ("B");
      C       : constant Attribute := Create_Attribute ("C");
      D       : constant Attribute := Create_Attribute ("D");
      E       : constant Attribute := Create_Attribute ("E");

      R1      : constant Relation  := Create_Relation ("AB", (A, B));
      R2      : constant Relation  := Create_Relation ("AD", (A, D));
      R3      : constant Relation  := Create_Relation ("AE", (A, E));
      R4      : constant Relation  := Create_Relation ("BE", (B, E));
      R5      : constant Relation  := Create_Relation ("CDE", (C, D, E));

      D1, D2, D3, D4, D5  : Functional_Dependency;
      Is_Lossless         : Boolean := False;
   begin
      -- D1 := A -> C
      D1.Left          := new Attribute_Array (1..1);
      D1.Right         := new Attribute_Array (1..1);
      D1.Left.all (1)  := A;
      D1.Right.all (1) := C;

      -- D2 := S -> A
      D2.Left          := new Attribute_Array (1..1);
      D2.Right         := new Attribute_Array (1..1);
      D2.Left.all (1)  := B;
      D2.Right.all (1) := C;

      -- D3 := C -> D
      D3.Left          := new Attribute_Array (1..1);
      D3.Right         := new Attribute_Array (1..1);
      D3.Left.all (1)  := C;
      D3.Right.all (1) := D;

      -- D4 := DE -> C
      D4.Left          := new Attribute_Array (1..2);
      D4.Right         := new Attribute_Array (1..1);
      D4.Left.all (1)  := D;
      D4.Left.all (2)  := E;
      D4.Right.all (1) := C;

      -- D5 := CE -> A
      D5.Left          := new Attribute_Array (1..2);
      D5.Right         := new Attribute_Array (1..1);
      D5.Left.all (1)  := C;
      D5.Left.all (2)  := E;
      D5.Right.all (1) := A;

      Is_Lossless := Is_Lossless_Join ((R1, R2, R3, R4, R5), (D1, D2, D3, D4, D5));

      if Is_Lossless then
         Print ("Losses join is held");
      else
         Print ("Losses join is abandoned");
         Delete_FD (D1);
         Delete_FD (D2);
         Delete_Relation (R1);
         raise Program_Error;
      end if;

      Delete_FD (D1);
      Delete_FD (D2);
      Delete_FD (D3);
      Delete_FD (D4);
      Delete_FD (D5);
      Delete_Relation (R1);
      Delete_Relation (R2);
      Delete_Relation (R3);
      Delete_Relation (R4);
      Delete_Relation (R5);
   end;

   --!TODO: Test Lossless join with several iterations of main loop

   Print ("Test on Closure subprograms");
   declare
      package List_Of_Attributes is new Ada.Containers.Doubly_Linked_Lists (Attribute);
      use List_Of_Attributes;

      function Is_Subset
        (Subset_Attrs : Attribute_Array;
         Closured_Attrs : List_Of_Attributes.List) return Boolean;
      -- copy of the same named subprogram of the Closure function

      function Is_Subset
        (Subset_Attrs : Attribute_Array;
         Closured_Attrs : List_Of_Attributes.List) return Boolean
      is
         Elem : Cursor;
         Copy_List : List_Of_Attributes.List := Closured_Attrs; --!!!! Check if deep copy
      begin
         for I in Subset_Attrs'Range loop
            if Is_Empty (Copy_List) then
               return False;
            end if;
            Elem := Find (Copy_List, Subset_Attrs (I));
            if Elem /= No_Element then
               Delete (Copy_List, Elem);
            else
               return False;
            end if;
         end loop;

         return True;
      end Is_Subset;

      A       : constant Attribute := Create_Attribute ("A");
      B       : constant Attribute := Create_Attribute ("B");
      C       : constant Attribute := Create_Attribute ("C");
      D       : constant Attribute := Create_Attribute ("D");
      E       : constant Attribute := Create_Attribute ("E");
      Empty_List : List_Of_Attributes.List;
      CDE_List   : List_Of_Attributes.List;
      ACDE_List  : List_Of_Attributes.List;
      CADB_List  : List_Of_Attributes.List;
   begin
      Append (CDE_List, C);
      Append (CDE_List, D);
      Append (CDE_List, E);

      ACDE_List := CDE_List;
      Prepend (CDE_List, A);

      Append (CADB_List, C);
      Append (CADB_List, A);
      Append (CADB_List, D);
      Append (CADB_List, B);

      if Is_Subset ((A, B), Empty_List)
      then
         Print ("Is_Subset: Error on the empty superset");
         raise Program_Error;
      elsif Is_Subset ((A, B), CDE_List)
      then
         Print ("Is_Subset: Error on different sets");
         raise Program_Error;
      elsif Is_Subset ((A, B), ACDE_List)
      then
         Print ("Is_Subset: Error on intersecting sets");
         raise Program_Error;
      elsif not Is_Subset ((A, B), CADB_List)
      then
         Print ("Is_Subset: Error on satisfying sets");
         raise Program_Error;
      else
         Print ("Is_Subset: successfully tested");
      end if;
   end;

   Print ("Simple test on Closure algorithm");
   declare
      Name       : constant Attribute := Create_Attribute ("name");
      Color      : constant Attribute := Create_Attribute ("color");
      Category   : constant Attribute := Create_Attribute ("category");
      Department : constant Attribute := Create_Attribute ("department");
      Price      : constant Attribute := Create_Attribute ("price");
      All_Attributes : constant Attribute_Array
        := (Name, Category, Color, Department, Price);
      R          : constant Relation  :=
        Create_Relation ("goods", (name, color, category, department, price));

      D1, D2, D3  : Functional_Dependency;
      --Closure_Attributes : Attribute_Array
   begin
      -- D1 := name -> color
      D1.Left          := new Attribute_Array (1..1);
      D1.Right         := new Attribute_Array (1..1);
      D1.Left.all (1)  := Name;
      D1.Right.all (1) := Color;

      -- D2 := category -> department
      D2.Left          := new Attribute_Array (1..1);
      D2.Right         := new Attribute_Array (1..1);
      D2.Left.all (1)  := Category;
      D2.Right.all (1) := Department;

      -- D3 := color, category -> price
      D3.Left          := new Attribute_Array (1..2);
      D3.Right         := new Attribute_Array (1..1);
      D3.Left.all (1)  := Color;
      D3.Left.all (2)  := Category;
      D3.Right.all (1) := Price;

      declare
         Closured_Attributes : constant Attribute_Array
           := Closure
             ((name, category),
              (D1, D2, D3));
      begin
         if Closured_Attributes = All_Attributes then
            Print ("Closure is calculated correctly");
         else
            Print ("Error in Closure calculation");
            for I in Closured_Attributes'Range loop
               Ada.Text_IO.Put_Line (To_String (Closured_Attributes (I).Name));
            end loop;

            Delete_FD (D1);
            Delete_FD (D2);
            Delete_FD (D3);
            Delete_Relation (R);
            raise Program_Error;
         end if;
      end;

      Delete_FD (D1);
      Delete_FD (D2);
      Delete_FD (D3);
      Delete_Relation (R);
   end;

   Print ("Advanced test on Closure algorithm");
   declare
      A       : constant Attribute := Create_Attribute ("A");
      B       : constant Attribute := Create_Attribute ("B");
      C       : constant Attribute := Create_Attribute ("C");
      D       : constant Attribute := Create_Attribute ("D");
      E       : constant Attribute := Create_Attribute ("E");
      F       : constant Attribute := Create_Attribute ("F");

      B_Array : Attribute_Array (1..1);
      C_Array : Attribute_Array (1..1);

      R          : constant Relation  :=
        Create_Relation ("ABCDEF", (A, B, C, D, E, F));

      D1, D2, D3, D4  : Functional_Dependency;
   begin
      B_Array (1) := B;
      C_Array (1) := C;

      -- D1 := A,B -> C
      D1.Left          := new Attribute_Array (1..2);
      D1.Right         := new Attribute_Array (1..1);
      D1.Left.all (1)  := A;
      D1.Left.all (2)  := B;
      D1.Right.all (1) := C;

      -- D2 := A,D -> E
      D2.Left          := new Attribute_Array (1..2);
      D2.Right         := new Attribute_Array (1..1);
      D2.Left.all (1)  := A;
      D2.Left.all (2)  := D;
      D2.Right.all (1) := E;

      -- D3 := B -> D
      D3.Left          := new Attribute_Array (1..1);
      D3.Right         := new Attribute_Array (1..1);
      D3.Left.all (1)  := B;
      D3.Right.all (1) := D;

      -- D4 := A,F -> B
      D4.Left          := new Attribute_Array (1..2);
      D4.Right         := new Attribute_Array (1..1);
      D4.Left.all (1)  := A;
      D4.Left.all (2)  := F;
      D4.Right.all (1) := B;

      if Closure ((A, B), (D1, D2, D3, D4)) /= (A, B, C, D, E) then
         Print ("Error in 1st Closure calculation");
         raise Program_Error;
      elsif Closure ((A, F), (D1, D2, D3, D4)) /= (A, F, B, C, D, E) then
         Print ("Error in 2nd Closure calculation");
         raise Program_Error;
      elsif Closure (B_Array, (D1, D2, D3, D4)) /= (B, D) then
         Print ("Error in 3rd Closure calculation");
         raise Program_Error;
      elsif Closure (C_Array, (D1, D2, D3, D4)) /= C_Array then
         Print ("Error in 4th Closure calculation");
         raise Program_Error;
      else
         Print ("All closures were calculated correctly");
      end if;

      Delete_FD (D1);
      Delete_FD (D2);
      Delete_FD (D3);
      Delete_Relation (R);
   exception
      when Program_Error =>
         Delete_FD (D1);
         Delete_FD (D2);
         Delete_FD (D3);
         Delete_Relation (R);
         raise;
   end;

   Print ("Test on Context subprograms");
   declare
      --pseudo Contexts function interface:
      Connection      : RDB_Connection;
      Basic_Relations : Access_Relation_Array;

      function Contains (Who : Attribute_Array; Whom : Attribute_Array) return Boolean;
      function Basic_Attributes return Attribute_Array;
      --        function Subsets_Basic_PK (R : Relation) return Boolean;
      --        function Intersects_Basic (R : Relation) return Boolean;

      function Contains (Who : Attribute_Array; Whom : Attribute_Array) return Boolean is
         Found : Boolean := False;
      begin
         for I in Whom'Range loop
            Found := False;
            Search_Loop:
            for J in Who'Range loop
               if Who (J) = Whom (I) then
                  Found := True;
                  exit Search_Loop;
               end if;
            end loop Search_Loop;

            if not Found
            then
               return False;
            end if;
         end loop;
         return True;
      end Contains;

      function Basic_Attributes return Attribute_Array is
         package List_Of_Attributes is new Ada.Containers.Doubly_Linked_Lists (Attribute);
         use List_Of_Attributes;
         Basic_Attrs : List_Of_Attributes.List;
      begin
         Fill_Loop:
         for Rel_Index in Basic_Relations'Range loop
            for I in Basic_Relations (Rel_Index).Attributes'Range loop
               if not Contains (Basic_Attrs, Basic_Relations (Rel_Index).Attributes (I)) then
                  Append (Basic_Attrs, Basic_Relations (Rel_Index).Attributes (I));
               end if;
            end loop;
         end loop Fill_Loop;

         Copy_To_Array:
         declare
            Result : Attribute_Array (1 .. Integer (Basic_Attrs.Length));
            Position : Cursor := First (Basic_Attrs);
         begin
            for I in Result'Range loop
               Result (I) := Element (Position);
               Next (Position);
            end loop;
            return Result;
         end Copy_To_Array;
      end Basic_Attributes;

      function Subsets_Basic_PK (R : Relation) return Boolean
      is
      begin
         for J in Basic_Relations'Range loop
            --  Other_Relations (I)
            if Contains (R.Attributes.all, Basic_Relations (J).Primary) then
               if Connection.Access_System.Inclusion_Dependency (R, Basic_Relations (J), Basic_Relations (J).Primary) then
                  return True;
               end if;
            end if;
         end loop;
         return False;
      end Subsets_Basic_PK;

      function Intersects_Basic (R : Relation) return Boolean is
         All_Attrs : constant Attribute_Array := Basic_Attributes;
      begin
         for I in R.Attributes'Range loop
            for J in All_Attrs'Range loop
               if R.Attributes (I) = All_Attrs (J) then
                  return True;
               end if;
            end loop;
         end loop;
         return False;
      end Intersects_Basic;

      S       : constant Attribute := Create_Attribute ("S");
      P       : constant Attribute := Create_Attribute ("P");
      A       : constant Attribute := Create_Attribute ("A");
      C       : constant Attribute := Create_Attribute ("C");
      E       : constant Attribute := Create_Attribute ("E");

      D       : constant Attribute := Create_Attribute ("D");
      F       : constant Attribute := Create_Attribute ("F");

      R3, R6, R8 : Relation;

      --R1 : constant Relation := Create_Relation ("Начало_занятий",
   begin
      Connection
        := Connect
          (Driver_Name   => "QMYSQL",
           Host_Name     => "localhost",
           Database_Name => "CWL_1",
           User_Name     => "root",
           Password      => "mysql");
      Basic_Relations := Connection.Schema.Relations;

      if not Contains ((S, A, C, P), (S, C))
      then
         Print ("Contains proc: Subset is said to be not included");
         raise Program_Error;
      elsif Contains ((S, A, C), (S, C, P))
      then
         Print ("Contains proc: False subset is accepted by proc");
         raise Program_Error;
      end if;

      if Basic_Attributes /= (S, A, E, P, C)
      then
         Print ("Basic_Attributes: Error in calculating basic attribute set");
         raise Program_Error;
      end if;

      R3 := Create_Relation ("Intersects", (P, C));
      R6 := Create_Relation ("Not_Intersects", (D, F));
      if not Intersects_Basic (R3)
      then
         Print ("Intersects_Basic: Error: Intersection should be held");
         raise Program_Error;
      elsif Intersects_Basic (R6)
      then
         Print ("Intersects_Basic: Error: Intersection should not be held");
         raise Program_Error;
      end if;
      Delete_Relation (R3);
      Delete_Relation (R6);

      Connection
        := Connect
          (Driver_Name   => "QMYSQL",
           Host_Name     => "localhost",
           Database_Name => "faculty",
           User_Name     => "root",
           Password      => "mysql");
      for I in Connection.Schema.Functional_Dependencies'Range loop
         for J in Connection.Schema.Functional_Dependencies (I).Left'Range loop
            Ada.Text_IO.Put ( To_String (Connection.Schema.Functional_Dependencies (I).Left (J).Name));
         end loop;
         Ada.Text_IO.Put (" -> ");
         for J in Connection.Schema.Functional_Dependencies (I).Right'Range loop
            Ada.Text_IO.Put_Line ( To_String (Connection.Schema.Functional_Dependencies (I).Right (J).Name));
         end loop;
      end loop;

      Basic_Relations := new Relation_Array (1..4);
      Basic_Relations.all := (Connection.Schema.Relations (1),
                              Connection.Schema.Relations (2),
                              Connection.Schema.Relations (4),
                              Connection.Schema.Relations (5));

      --Basic_Relations (1) := Connection.Schema.Relations (1);
--                                ,
--                                Connection.Schema.Relations (2),
--                                Connection.Schema.Relations (4),
--                                Connection.Schema.Relations (5));

      R3 := Connection.Schema.Relations (3); --Оценки
      R6 := Connection.Schema.Relations (6); --Расписание
      R8 := Connection.Schema.Relations (8); --Студенты

      if R3.Name /= "Оценки" or R6.Name /= "Расписание" or R8.Name /= "Студенты" then
         Print ("Error: wrong model overview");
         raise Program_Error;
      end if;

      if Subsets_Basic_PK (R8) then
         Print ("Subsets_Basic_PK: Error: this relation is not a subset");
         raise Program_Error;
      elsif not Subsets_Basic_PK (R6) then
            Print ("Subsets_Basic_PK: Error: right relation " &
                     "is said to be not contained in basic");
            raise Program_Error;
      elsif not Subsets_Basic_PK (R3) then
         Print ("Subsets_Basic_PK: Error: another right relation " &
                  "is said to be not contained in basic");
         raise Program_Error;
      end if;
   end;

   Print ("Simple test on Context itself");
   declare
      use List_Of_Contexts;
      use type Ada.Containers.Count_Type;
      --pseudo Contexts function interface:

      Connection : constant RDB_Connection
          := Connect
            (Driver_Name   => "QMYSQL",
             Host_Name     => "localhost",
             Database_Name => "faculty",
             User_Name     => "root",
             Password      => "mysql");
      Basic_Relations : Access_Relation_Array;
      R4, R7 : Relation;
      Context_List : List;
      C            : Cursor;
      --        N_prepoda : Attribute := Create_Attribute ("№_преподавателя");
      --        FIO       : Attribute := Create_Attribute ("ФИО_преподавателя");
      --        Params : Attribute_Array (1..1);
      --        X : Attribute_Array (1..2) := (N_prepoda, FIO);
      procedure Print_Elem (C : List_Of_Contexts.Cursor)
      is
      begin
         for I in List_Of_Contexts.Element (C)'Range loop
            Ada.Text_IO.Put (To_String (List_Of_Contexts.Element (C).all (I).Name) & ", ");
         end loop;
         Ada.Text_IO.Put_Line ("");
      end Print_Elem;

      --type String_Array is array (Positive range <>) of String
      --function Equals (C : Context; )

   begin
      Basic_Relations := new Relation_Array (1..2);
      Basic_Relations (1) := Connection.Schema.Relations (4);--Предметы
      Basic_Relations (2) := Connection.Schema.Relations (7); --Оценки

      Context_List := Contexts
        (Connection,
         Basic_Relations.all,
         Connection.Schema.Functional_Dependencies.all);
      if Length (Context_List) /= 3
      then
         Print ("Error: wrong contexts amount");
         raise Program_Error;
      end if;
      C := First (Context_List);
      if Element (C)'Length /= 3
      then
         Print ("Error: first context is wrong");
         raise Program_Error;
      elsif Element (Next (C))'Length /= 3
      then
         Print ("Error: second context is wrong");
         raise Program_Error;
      elsif Element (Next (Next (C)))'Length /= 4
      then
         Print ("Error: third context is wrong");
         raise Program_Error;
      end if;
      Print ("Context received are correct");
      Iterate (Context_List, Print_Elem'Access);
   end;

   --     ---------
   --     Attrs (1) := Create_Attribute("C");
   --     D4       := Create_FD (Attrs2, Attrs);
   --     Attrs (1) := Create_Attribute("A");
   --     D5       := Create_FD ( (Create_Attribute ("C"), Create_Attribute ("E")), Attrs);
   --
   --     Ada.Text_IO.Put_Line(Ada.Strings.Unbounded.To_String(D4.Left.all(1).Name) & " "
   --                          & Ada.Strings.Unbounded.To_String(D4.Left.all(2).Name));
   --     Ada.Text_IO.Put_Line(Ada.Strings.Unbounded.To_String(D5.Left.all(1).Name) & " "
   --                          & Ada.Strings.Unbounded.To_String(D5.Left.all(2).Name));
   --     Deps := (D1,D2, D3, D4, D5);
   --     Is_Lossless  := Is_Lossless_Join (Connection.Schema.Relations.all, Deps);
   --     if Is_Lossless then
   --        Ada.Text_IO.Put_Line ("Connection without losses is held.");
   --     end if;

end OLAP_Converter.Contexts.Test;
