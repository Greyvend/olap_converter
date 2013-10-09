with Ada.Containers.Generic_Constrained_Array_Sort;
with Combinations;

with Ada.Text_IO;

package body OLAP_Converter.Contexts is

   ----------------------
   -- Is_Lossless_Join --
   ----------------------

   function Is_Lossless_Join
     (Relations    : Relation_Array;
      Dependencies : FD_Array) return Boolean
   is
      type Table_Element is
         record
            A : boolean;
            I : Natural;
            J : Positive;
         end record;
      type Table is array (Positive range <>, Positive range <>) of Table_Element;
      type Index_Array is array (Positive range <>) of Positive;

      function Is_String_With_A (Working_Table : Table) return Boolean;
      function Get_Index
        (Attributes : Attribute_Array;
         Attr : Attribute) return Natural;
      procedure Assign_Matched_Relations
        (Left_Dependency_Indexes : in Index_Array;
         Right_Dependency_Index  : in Positive;
         Working_Table           : in out Table;
         Is_Changed              : out Boolean);

      function Is_String_With_A (Working_Table : Table) return Boolean is
      begin
         for I in Working_Table'Range (1) loop
            for J in Working_Table'Range (2) loop
               if not Working_Table (I,J).A then
                  exit;
               end if;
               if J = Working_Table'Last (2) then
                  return True;
               end if;
            end loop;
         end loop;

         return False;
      end Is_String_With_A;

      function Get_Index
        (Attributes : Attribute_Array;
         Attr : Attribute) return Natural
      is
      begin
         for I in Attributes'Range loop
            if Attr.Name = Attributes (I).Name then
               return I;
            end if;
         end loop;
         return 0;
      end Get_Index;

      procedure Assign_Matched_Relations
        (Left_Dependency_Indexes : in     Index_Array;
         Right_Dependency_Index  : in     Positive;
         Working_Table           : in out Table;
         Is_Changed              :    out Boolean)
      is
         Seed_Relation_Index : Positive := 1;
         Relation_Amount     : Positive := 1;
         Matching_Relations  : Index_Array (Relations'Range);
      begin
         Is_Changed := False;

         Main_Loop:
         for I in Working_Table'Range (1) loop
            Matching_Relations (1) := I;
            Seed_Relation_Index := I;

            Search_For_Relations:
            for J in Working_Table'Range (1) loop
               if I /= J then
                  for K in Left_Dependency_Indexes'Range loop
                     if Working_Table (I,Left_Dependency_Indexes (K))
                       /= Working_Table (J,Left_Dependency_Indexes (K))
                     then
                        exit;
                     end if;

                     if K = Left_Dependency_Indexes'Last then
                        if Working_Table (J, Right_Dependency_Index).A then
                           Seed_Relation_Index := J;
                        end if;

                        Relation_Amount := Relation_Amount + 1;
                        Matching_Relations (Relation_Amount) := J;
                     end if;
                  end loop;
               end if;
            end loop Search_For_Relations;

            if Relation_Amount /= 1 then
               Assign_Values:
               for K in 1..Relation_Amount loop
                  if Matching_Relations (K) /= Seed_Relation_Index and
                    Working_Table (Matching_Relations (K), Right_Dependency_Index) /=
                    Working_Table (Seed_Relation_Index, Right_Dependency_Index)
                  then
                     Working_Table (Matching_Relations (K), Right_Dependency_Index) :=
                       Working_Table (Seed_Relation_Index, Right_Dependency_Index);

                     Is_Changed := True;
                  end if;
               end loop Assign_Values;
            end if;

            Relation_Amount := 1;
         end loop Main_Loop;
      end Assign_Matched_Relations;

      Attrs         : constant Attribute_Array := All_Attributes (Relations);
      Working_Table : Table(Relations'Range, Attrs'Range);
   begin  -- Is_Lossless_Join
      Initial_Table_Filling:
      for I in Relations'Range loop
         for J in Attrs'Range loop
            if Get_Index (Relations (I).Attributes.all, Attrs (J)) /= 0 then
               Working_Table (I,J) := (True, 0, J);
            else
               Working_Table (I,J) := (False, I, J);
            end if;
         end loop;
      end loop Initial_Table_Filling;

      Main_Algorithm_Job:
      declare
         Changed                 : Boolean := True;
         Current_Dependency      : Functional_Dependency;
      begin
         while Changed loop
            Changed := False;
            for I in Dependencies'Range loop
               Current_Dependency := Dependencies (I);

               declare
                  Left_Dependency_Indexes : Index_Array (Current_Dependency.Left.all'Range);
                  Right_Dependency_Index  : Positive := 1;
                  Lock                    : Boolean := False;
               begin
                  for J in Current_Dependency.Left.all'Range loop
                     Left_Dependency_Indexes (J) := Get_Index (Attrs, Current_Dependency.Left.all (J));
                  end loop;
                  Right_Dependency_Index := Get_Index (Attrs, Current_Dependency.Right.all (1));

                  Assign_Matched_Relations
                    (Left_Dependency_Indexes,
                     Right_Dependency_Index,
                     Working_Table,
                     Changed);

                  -- prevent Changed to go True -> False,
                  -- not to stop algorithm earlier
                  if Changed then
                     if not Lock
                     then
                        Lock := True;
                     end if;
                  else
                     Changed := Changed or Lock;
                  end if;
               end;
            end loop;

            if Is_String_With_A (Working_Table) then
               return True;
            end if;
         end loop;

         return False;
      end Main_Algorithm_Job;
   end Is_Lossless_Join;

   -------------
   -- Closure --
   -------------

   function Closure
     (Attrs : Attribute_Array;
      Deps : FD_Array) return Attribute_Array
   is
      package List_Of_Attributes is new Ada.Containers.Doubly_Linked_Lists (Attribute);
      use List_Of_Attributes;

      function Is_Subset
        (Subset_Attrs   : Attribute_Array;
         Superset_Attrs : List_Of_Attributes.List) return Boolean;

      procedure Insert
        (Attrs_To_Insert : in     Attribute_Array;
         Insert_Place    : in out List_Of_Attributes.List) ;

      function Is_Subset
        (Subset_Attrs   : Attribute_Array;
         Superset_Attrs : List_Of_Attributes.List) return Boolean
      is
         Elem : Cursor;
         Copy_List : List_Of_Attributes.List := Superset_Attrs;
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

      procedure Insert
        (Attrs_To_Insert : in     Attribute_Array;
         Insert_Place    : in out List_Of_Attributes.List) is
      begin
         for I in Attrs_To_Insert'Range loop
            if not Contains (Insert_Place, Attrs_To_Insert(I)) then
               Append (Insert_Place, Attrs_To_Insert(I));
            end if;
         end loop;
      end Insert;

      Closured_Attributes : List_Of_Attributes.List; -- Builded set of attributes
   begin --Closure
      Initial_Filling: -- X0
      for I in Attrs'Range loop
         Append (Closured_Attributes, Attrs(I));
      end loop Initial_Filling;

      Main_Job:
      declare
         Is_Added : Boolean := False;
      begin
         loop
            Is_Added := False;

            for I in Deps'Range loop
               if Is_Subset (Deps (I).Left.all, Closured_Attributes) and
                 not Is_Subset (Deps (I).Right.all, Closured_Attributes)
               then
                  Insert (Deps (I).Right.all, Closured_Attributes);
                  Is_Added := True;
               end if;
            end loop;

            exit when not Is_Added;
         end loop;
      end Main_Job;

      Copy_To_Array:
      declare
         Result : Attribute_Array (1 .. Integer (Closured_Attributes.Length));
         Position : Cursor := First (Closured_Attributes);
      begin
         for I in Result'Range loop
            Result (I) := Element (Position);
            Next (Position);
         end loop;

         return Result;
      end Copy_To_Array;
   end Closure;

   --------------
   -- Contexts --
   --------------

   function Contexts
     (Connection      : RDB_Connection;
      Basic_Relations : Relation_Array;
      Deps            : FD_Array) return List_Of_Contexts.List
   is
      System : Access_DBMS renames Connection.Access_System;

      function Contains (Who : Attribute_Array; Whom : Attribute_Array) return Boolean;
      function Subsets_Basic_PK (R : Relation) return Boolean;
      function Intersects_Basic (R : Relation) return Boolean;
      function Cut_FDs (Relations : Relation_Array) return FD_Array;

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

      function Subsets_Basic_PK (R : Relation) return Boolean
      is
      begin
         for J in Basic_Relations'Range loop
            --  Other_Relations (I)
            if Contains (R.Attributes.all, Basic_Relations (J).Primary) then
               if System.Inclusion_Dependency (R, Basic_Relations (J), Basic_Relations (J).Primary) then
                  return True;
               end if;
            end if;
         end loop;
         return False;
      end Subsets_Basic_PK;

      function Intersects_Basic (R : Relation) return Boolean is
         All_Attrs : constant Attribute_Array := All_Attributes (Basic_Relations);
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

      function Cut_FDs (Relations : Relation_Array) return FD_Array
      is
         package List_Of_FDs is new Ada.Containers.Doubly_Linked_Lists (Functional_Dependency);
         use List_Of_FDs;
         Deps_List : List_Of_FDs.List;
         Attrs     : constant Attribute_Array := All_Attributes (Relations);
         Single_Array : Attribute_Array (1..1);
      begin
         Fill_Loop:
         for I in Deps'Range loop --Deps from input parameter
            if Contains (Attrs, Deps (I).Left.all) and
              Contains (Attrs, Deps (I).Right.all)
            then
               if Deps (I).Right'Length > 1
               then
                  for J in Deps (I).Right'Range loop
                     Single_Array (1) := Deps (I).Right (J);
                     Append (Deps_List, Create_FD (Deps (I).Left.all, Single_Array));
                  end loop;
               else
                  Append (Deps_List, Deps (I));
               end if;
            end if;
         end loop Fill_Loop;

         Copy_To_Array:
         declare
            Result   : FD_Array (1 .. Integer (Deps_List.Length));
            Position : Cursor := First (Deps_List);
         begin
            for I in Result'Range loop
               Result (I) := Element (Position);
               Next (Position);
            end loop;
            return Result;
         end Copy_To_Array;
      end Cut_FDs;

      Other_Relations : Relation_Array
        (1 .. (Connection.Schema.Relations'Length - Basic_Relations'Length));

      subtype Priority_Index is Positive range Other_Relations'Range;
      type Priority_Pair is
         record
            Priority : Natural;
            Index : Priority_Index;
         end record;
      type Priority_Array is array (Priority_Index) of Priority_Pair;

      Priorities : Priority_Array;
      Size       : Natural := 0;

   begin -- Contexts

      Ada.Text_IO.Put_Line ("Other_Relations: ");

      Fill_Other_Relations:
      declare
         Found : Boolean := False;
         K     : Positive := 1;
      begin
         for I in Connection.Schema.Relations'Range loop
            Found := False;
            for J in Basic_Relations'Range loop
               if Connection.Schema.Relations (I) = Basic_Relations (J) then
                  Found := True;
                  exit;
               end if;
            end loop;

            if not Found
            then
               Other_Relations (K) := Connection.Schema.Relations (I);
               Ada.Text_IO.Put_Line (To_String (Other_Relations (K).Name));
               K := K + 1;
            end if;
         end loop;
      end Fill_Other_Relations;

      Set_Priorities:
      begin
         for I in Other_Relations'Range loop
            if Contains (Closure (Other_Relations (I).Primary, Deps),
                         All_Attributes (Basic_Relations)) then
               Ada.Text_io.put_line (To_String (Other_Relations (I).Name) & " got 3");
               Priorities (I).Priority := 3;
            elsif Subsets_Basic_PK (Other_Relations (I)) then
               Ada.Text_io.put_line (To_String (Other_Relations (I).Name) & " got 2");
               Priorities (I).Priority := 2;
            elsif Intersects_Basic (Other_Relations (I)) then
               Ada.Text_io.put_line (To_String (Other_Relations (I).Name) & " got 1");
               Priorities (I).Priority := 1;
            else Priorities (I).Priority := 0;
               Ada.Text_io.put_line (To_String (Other_Relations (I).Name) & " got 0");
            end if;
            Priorities (I).Index := I;
         end loop;
      end Set_Priorities;

      Ada.Text_io.put_line (" Finished with priorities.");
      Ada.Text_io.put_line ("Priorities are following: ");
      for I in Priorities'Range loop
         Ada.Text_io.put ("(" & Natural'Image (Priorities (I).Priority)
                          & ", " & Priority_Index'Image (Priorities (I).Index) & "), ");
      end loop;
      Ada.Text_IO.Put_Line ("");


      Sort_Indexes_Array: -- by decreasing Relation priority of current index
      declare
         function Greater (L, R : Priority_Pair) return Boolean
         is
         begin
            if L.Priority > R.Priority then
               return True;
            end if;
            return False;
         end Greater;

         procedure Sort_By_Decrease is new
           Ada.Containers.Generic_Constrained_Array_Sort (Index_Type => Priority_Index,
                                                          Element_Type => Priority_Pair,
                                                          Array_Type => Priority_Array,
                                                          "<" => Greater);
      begin
         Sort_By_Decrease (Priorities);

         --you need not to limit the size to positive priorities,
         --when there are MVDs, there can be other contexts within them
         Count_Size_Loop:
         for I in Priorities'Range loop
            if Priorities (I).Priority = 0 then
               exit;
            else
               Size := Size + 1;
            end if;
         end loop Count_Size_Loop;
      end Sort_Indexes_Array;

      Ada.Text_io.put_line ("Sorted priorities are following: ");
      for I in Priorities'Range loop
         Ada.Text_io.put ("(" & Natural'Image (Priorities (I).Priority)
                          & ", " & Priority_Index'Image (Priorities (I).Index) & "), ");
      end loop;
      Ada.Text_IO.Put_Line ("");

      Is_Lossless_For_Relation_Combinations:
      declare
         C           : Combinations.Combination_Array (1..Size + 1) := (others => 0);
         K           : Positive := 1;
         Is_Finished : Boolean := False;
         Cont_List   : List_Of_Contexts.List;
      begin
         loop
            Combinations.Get_Next_Combination (C, K, Is_Finished);
            exit when Is_Finished;
            -- do bad things
            Check_Lossy:
            declare
               Base_Size   : constant Positive := Basic_Relations'Length;
               A_Context   : constant Access_Context := new Context_Type (1..Base_Size + K);
            begin
               for I in Basic_Relations'Range loop
                  A_Context (I) := Basic_Relations (I);
               end loop;
               for J in 1..K loop
                  --Ada.Text_IO.Put (Integer'Image (C(J)) & ", ");
                  A_Context (Base_Size + J) := Other_Relations (Priorities (C (J)).Index);
               end loop;

--                 Ada.Text_IO.Put_Line ("");
--                 ----------------------------------
--                 for I in A_Context'Range loop
--                    Ada.Text_IO.Put (To_String (A_Context.all (I).Name) & ", ");
--                 end loop;
--                 Ada.Text_IO.Put_Line ("");
               ----------------------------------

--                 for I in Cut_FDs (Relation_Array (A_Context.all))'Range loop
--                    declare
--                       FDs : FD_Array := Cut_FDs (Relation_Array (A_Context.all));
--                    begin
--                       for J in FDs (I).Left'Range loop
--                          Ada.Text_IO.Put (To_String (FDs (I).Left (J).Name) & ", ");
--                       end loop;
--
--                       Ada.Text_IO.Put (" -> ");
--
--                       for J in FDs (I).Right'Range loop
--                          Ada.Text_IO.Put (To_String (FDs (I).Right (J).Name) & ", ");
--                       end loop;
--                       Ada.Text_IO.Put_Line ("");
--                    end;
--                 end loop;

               if Is_Lossless_Join
                 (Relation_Array (A_Context.all),
                  Cut_FDs (Relation_Array (A_Context.all)))
               then
                  --Ada.Text_IO.Put_Line ("LOSSY! ");
                  Cont_List.Append (A_Context);
               end if;
            end Check_Lossy;
         end loop;
         return Cont_List;
      end Is_Lossless_For_Relation_Combinations;
   end Contexts;

   --------------------
   -- All_Attributes --
   --------------------

   function All_Attributes (Relations : Relation_Array) return Attribute_Array
   is
      package List_Of_Attributes is new Ada.Containers.Doubly_Linked_Lists (Attribute);
      use List_Of_Attributes;
      Attrs : List_Of_Attributes.List;
   begin
      Fill_Loop:
      for Rel_Index in Relations'Range loop
         for I in Relations (Rel_Index).Attributes'Range loop
            if not Contains (Attrs, Relations (Rel_Index).Attributes (I)) then
               Append (Attrs, Relations (Rel_Index).Attributes (I));
            end if;
         end loop;
      end loop Fill_Loop;

      Copy_To_Array:
      declare
         Result : Attribute_Array (1 .. Integer (Attrs.Length));
         Position : Cursor := First (Attrs);
      begin
         for I in Result'Range loop
            Result (I) := Element (Position);
            Next (Position);
         end loop;
         return Result;
      end Copy_To_Array;
   end All_Attributes;


end OLAP_Converter.Contexts;