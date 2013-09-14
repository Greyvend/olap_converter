package body Olap_Converter is

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

   function "="
     (X : Attribute;
      Y : Attribute) return Boolean
   is
   begin
      return Equals (X, Y);
   end "=";

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
      Result := (Name => To_Unbounded_String(Name),
                 Relation_Name => To_Unbounded_String(""),
                 Value_Type => To_Unbounded_String("No_Value_Type"),
                 Current_Value => To_Unbounded_String(""),
                 Value_Amount => 0);
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

end OLAP_Converter;