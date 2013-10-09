with Ada.Containers.Generic_Array_Sort;
with Ada.Strings.Fixed;

use Ada.Strings.Fixed;

package body Olap_Converter is

   ------------
   -- Equals --
   ------------

   function Equals
     (X : Attribute;
      Y : Attribute) return Boolean
   is
   begin
      if X.Name = Y.Name then
         return True;
      end if;
      return False;
   end Equals;

   ------------
   -- Equals --
   ------------

   function Equals
     (X : Relation;
      Y : Relation) return Boolean
   is
   begin
      if X.Name = Y.Name then
         return True;
      end if;
      return False;
   end Equals;

   ---------------------
   -- Extended_Equals --
   ---------------------

   function Extended_Equals
     (X : Attribute;
      Y : Attribute) return Boolean
   is
   begin
      if Equals (X, Y) and
        X.Relation_Name = Y.Relation_Name then
         return True;
      end if;
      return False;
   end Extended_Equals;

   ---------
   -- "=" --
   ---------

   function "="
     (X : Attribute;
      Y : Attribute) return Boolean
   is
   begin
      return Equals (X, Y);
   end "=";

   ---------
   -- "=" --
   ---------

   function "="
     (X : Relation;
      Y : Relation) return Boolean
   is
   begin
      return Equals (X, Y);
   end "=";

   ----------------------
   -- Create_Attribute --
   ----------------------

   function Create_Attribute (Name : String) return Attribute
   is
      Result : Attribute;
   begin
      Result := (Name          => To_Unbounded_String (Name),
                 Relation_Name => To_Unbounded_String (""),
                 Value_Type    => To_Unbounded_String ("No_Value_Type"),
                 Current_Value => To_Unbounded_String (""),
                 Value_Amount  => 0);
      return Result;
   end Create_Attribute;

   function Primary (R : Relation'Class) return Attribute_Array
   is
   begin
      if R.Primary_Key = null then
         return Empty_Attr_Array;
      else
         declare
            Attrs : Attribute_Array (R.Primary_Key'Range);
         begin
            for I in Attrs'Range loop
               Attrs (I) := R.Attributes (R.Primary_Key (I));
            end loop;
            return Attrs;
         end;
      end if;
   end Primary;

   ---------------------
   -- Create_Relation --
   ---------------------

   function Create_Relation
     (Name  : String;
      Attrs : Attribute_Array;
      PK    : Index_Array := Empty_Index_Array) return Relation
   is
      R : Relation;
   begin
      R.Name := Ada.Strings.Unbounded.To_Unbounded_String (Name);
      R.Attributes := new Attribute_Array (Attrs'Range);
      R.Attributes.all := Attrs;

      if PK /= Empty_Index_Array then
         R.Primary_Key := new Index_Array (PK'Range);
         R.Primary_Key.all := PK;
      end if;

      return R;
   end Create_Relation;

   ---------------------
   -- Delete_Relation --
   ---------------------

   procedure Delete_Relation (R : Relation)
   is
      Access_Attr  : Access_Attribute_Array := R.Attributes;
      Access_Index : Access_Index_Array := R.Primary_Key;
   begin
      Free_Attribute_Array (Access_Attr);
      Free_Index_Array (Access_Index);
   end Delete_Relation;

   -------------
   -- DB_Name --
   -------------

   function DB_Name (Name : String) return String
   is
      Dot_Position : constant Integer := Index (Name, ".");
   begin
      --if Dot_Position = 0 then
      return Name (Name'First .. Dot_Position - 1);
   end DB_Name;

   ----------------
   -- Table_Name --
   ----------------

   function Table_Name (Name : String) return String
   is
      Dot_Position : constant Integer := Index (Name, ".");
   begin
      return Name (Dot_Position + 1 .. Name'Last);
   end Table_Name;

   ---------------------
   -- Sort_Attributes --
   ---------------------

   procedure Sort_Attributes (Attrs : in out Attribute_Array)
   is
      -- by decreasing the amount of values, that the attribute has
      function Greater (L, R : Attribute) return Boolean
      is
      begin
         if L.Value_Amount > R.Value_Amount then
            return True;
         end if;
         return False;
      end Greater;

      procedure Sort_By_Decrease is new
        Ada.Containers.Generic_Array_Sort (Index_Type => Positive,
                                           Element_Type => Attribute,
                                           Array_Type => Attribute_Array,
                                           "<" => Greater);
   begin
      Sort_By_Decrease (Attrs);
   end Sort_Attributes;
end OLAP_Converter;