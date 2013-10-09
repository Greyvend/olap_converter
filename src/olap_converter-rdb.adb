package body OLAP_Converter.RDB is

   ---------------
   -- Create_FD --
   ---------------

   function Create_FD
     (Left_Part : Attribute_Array;
      Right_Part : Attribute_Array) return Functional_Dependency
   is
      D : Functional_Dependency;
   begin
      D.Left := new Attribute_Array(Left_Part'Range);
      D.Right := new Attribute_Array(Right_Part'Range);
      for I in Left_Part'Range loop
         D.Left.all(I) := Left_Part(I);
      end loop;
      for I in Right_Part'Range loop
         D.Right.all(I) := Right_Part(I);
      end loop;
      return D;
   end Create_FD;

   ---------------
   -- Create_FD --
   ---------------

   function Create_FD
     (Left : String;
      Right : String) return Functional_Dependency
   is
      D : Functional_Dependency;
   begin
      D.Left := new Attribute_Array(1..1);
      D.Left.all(1) := (Name => To_Unbounded_String (Left),
                        Relation_Name => To_Unbounded_String (""),
                        Value_Type => To_Unbounded_String ("No_Value_Type"),
                        Current_Value => To_Unbounded_String (""),
                        Value_Amount => 0);
      D.Right := new Attribute_Array(1..1);
      D.Right.all(1) := (Name => To_Unbounded_String (Right),
                         Relation_Name => To_Unbounded_String (""),
                         Value_Type => To_Unbounded_String ("No_Value_Type"),
                         Current_Value => To_Unbounded_String (""),
                         Value_Amount => 0);
      return D;
   end;

   ----------------
   -- Create_MVD --
   ----------------

   function Create_MVD
     (Left_Part  : Attribute_Array;
      Right_Part : Attribute_Array;
      Context    : Attribute_Array) return Multi_Valued_Dependency
   is
      MVD : Multi_Valued_Dependency;
   begin
      MVD.Base.Left := new Attribute_Array (Left_Part'Range);
      MVD.Base.Right := new Attribute_Array (Right_Part'Range);

      for I in Left_Part'Range loop
         MVD.Base.Left.all (I) := Left_Part (I);
      end loop;

      for I in Right_Part'Range loop
         MVD.Base.Right.all(I) := Right_Part(I);
      end loop;

      return MVD;
   end Create_MVD;

   ---------------
   -- Delete_FD --
   ---------------

   procedure Delete_FD (FD : Functional_Dependency)
   is
      Access_Var : Access_Attribute_Array := FD.Left;
   begin
      Free_Attribute_Array (Access_Var);

      Access_Var := FD.Right;
      Free_Attribute_Array (Access_Var);
   end Delete_FD;

   ----------------
   -- Delete_MVD --
   ----------------

   procedure Delete_MVD (MVD : Multi_Valued_Dependency)
   is
      Access_Var : Access_Attribute_Array := MVD.Base.Left;
   begin
      Free_Attribute_Array (Access_Var);

      Access_Var := MVD.Base.Right;
      Free_Attribute_Array (Access_Var);

      Access_Var := MVD.Context;
      Free_Attribute_Array (Access_Var);
   end Delete_MVD;


end OLAP_Converter.RDB;
