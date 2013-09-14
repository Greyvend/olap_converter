with Ada.Containers.Generic_Array_Sort;

package body OLAP_Converter.Connection_Table is

   function TJ
     (Name    : String;
      Attrs   : Attribute_Array;
      Context : Relation_Array;
      P       : Predicate) return Relation
   is
      TJ : Relation;
   begin
      --        -- block 1
      --        Find_Intersection_Attributes:
      --        declare
      --        begin
      --           for I in Context.Attributes'Range loop
      --
      --           end loop;
      --
      --        end Find_Intersection_Attributes;

      --         ^^^^ don't do the DBMS work

      -- block 2
      --Create_TJ (...);

      TJ := Create_Relation (Name, Attrs);

      -- block 3
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
