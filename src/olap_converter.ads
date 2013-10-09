with Ada.Unchecked_Deallocation;
with Ada.Strings.Unbounded;

package OLAP_Converter is
   --Базовый пакет, в котором содержатся описания основных типов
   use Ada.Strings.Unbounded;

   type Name_Array is array (Positive range <>) of Unbounded_String;

   Empty_Name_Array : Name_Array (1 .. 0);

   type Attribute is
      record
         Name          : Unbounded_String;
         Relation_Name : Unbounded_String;
         Value_Type    : Unbounded_String;
         Current_Value : Unbounded_String;
         Value_Amount  : Natural := 0;
      end record;

   function Extended_Equals
     (X : Attribute;
      Y : Attribute) return Boolean;

   function "="
     (X : Attribute;
      Y : Attribute) return Boolean;

   type Attribute_Array is array (Positive range <>) of Attribute;
   type Access_Attribute_Array is access all Attribute_Array;

   Empty_Attr_Array : Attribute_Array (1..0);

   procedure Sort_Attributes (Attrs : in out Attribute_Array);

   type Index_Array is array (Positive range <>) of Positive;
   type Access_Index_Array is access all Index_Array;

   Empty_Index_Array : Index_Array (1..0);

   type Relation is tagged
      record
         Name        : Unbounded_String;
         Attributes  : Access_Attribute_Array := null;
         Primary_Key : Access_Index_Array := null;
      end record;

   function "="
     (X : Relation;
      Y : Relation) return Boolean;

   type Relation_Array is array (Positive range <>) of Relation;
   type Access_Relation_Array is access all Relation_Array;

   function Create_Attribute (Name : String) return Attribute;

   function Primary (R : Relation'Class) return Attribute_Array;

   -- procedures to Create/Delete relations
   function Create_Relation
     (Name  : String;
      Attrs : Attribute_Array;
      PK    : Index_Array := Empty_Index_Array) return Relation;
   procedure Delete_Relation (R : Relation);

   -- Dot notation "DB.Table" composing functions
   function Full_Name (DB_Name : String; Table_Name : String) return String
   is (DB_Name & "." & Table_Name);

   function DB_Name (Name : String) return String;
   function Table_Name (Name : String) return String;
private
   function Equals
     (X : Attribute;
      Y : Attribute) return Boolean;

   function Equals
     (X : Relation;
      Y : Relation) return Boolean;

   procedure Free_Index_Array is new Ada.Unchecked_Deallocation
     (Object => Index_Array, Name => Access_Index_Array);
   procedure Free_Attribute_Array is new Ada.Unchecked_Deallocation
     (Object => Attribute_Array, Name => Access_Attribute_Array);
   procedure Free_Relation_Array is new Ada.Unchecked_Deallocation
     (Object => Relation_Array, Name => Access_Relation_Array);

end OLAP_Converter;