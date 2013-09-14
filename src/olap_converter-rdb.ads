package OLAP_Converter.RDB is

   type Attribute_Array_Pair is
      record
         Left    : Access_Attribute_Array;
         Right   : Access_Attribute_Array;
      end record;

   type Functional_Dependency is new Attribute_Array_Pair;
   type FD_Array is array (Positive range <>) of Functional_Dependency;
   type Access_FD_Array is access all FD_Array;

   type Multi_Valued_Dependency is
      record
         Base    : Attribute_Array_Pair;
         Context : Access_Attribute_Array;
      end record;
   type MVD_Array is array (Positive range <>) of Multi_Valued_Dependency;
   type Access_MVD_Array is access all MVD_Array;

   function Create_FD
     (Left_Part : Attribute_Array;
      Right_Part : Attribute_Array) return Functional_Dependency;

   function Create_FD
     (Left : String;
      Right : String) return Functional_Dependency;

   function Create_MVD
     (Left_Part  : Attribute_Array;
      Right_Part : Attribute_Array;
      Context    : Attribute_Array) return Multi_Valued_Dependency;

   procedure Delete_FD (FD : Functional_Dependency);
   procedure Delete_MVD (MVD : Multi_Valued_Dependency);

   -- feature: type Constraint
   --! important feature: make good pointer management
private
   procedure Free_FD_Array is new Ada.Unchecked_Deallocation
     (Object => FD_Array, Name => Access_FD_Array);
   procedure Free_MVD_Array is new Ada.Unchecked_Deallocation
     (Object => MVD_Array, Name => Access_MVD_Array);
end OLAP_Converter.RDB;