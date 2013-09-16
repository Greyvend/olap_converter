with Ada.Containers.Generic_Array_Sort;

package body OLAP_Converter.Connection_Table is

   function TJ
     (Self       : not null access DBMS'Class;
      DB_Name    : String := "";
      Name       : String;
      Attrs      : Attribute_Array;
      Context    : Relation_Array;
      P          : Predicate) return Relation
   is
      TJ : Relation;
   begin
      Self.Create_TJ
        (DB_Name   => DB_Name,
         Name      => Name,
         Relations => Context,
         Attrs     => Attrs,
         Formula   => "");

      --TJ := Create_Relation (Name, Attrs);
      TJ := Self.Table (Name);

      Hierarchy_Setup:
      declare
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
         Sort_By_Decrease (TJ.Attributes.all);
      end Hierarchy_Setup;

      return TJ;
   end TJ;
end OLAP_Converter.Connection_Table;
