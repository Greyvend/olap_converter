with Ada.Containers.Doubly_Linked_Lists;
with OLAP_Converter.RDB;            use OLAP_Converter.RDB;
with OLAP_Converter.RDB.Connection; use OLAP_Converter.RDB.Connection;

package OLAP_Converter.Contexts is
   type Context_Type is new Relation_Array;
   type Access_Context is access all Context_Type;
   type Context_Array is array (Positive range <>) of Access_Context;
   type Access_Context_Array is access all Context_Array;

   package List_Of_Contexts is new Ada.Containers.Doubly_Linked_Lists (Access_Context);

   function Contexts
     (Connection      : RDB_Connection;
      Basic_Relations : Relation_Array;
      Deps            : FD_Array) return List_Of_Contexts.List;
private
   function Closure
     (Attrs : Attribute_Array;
      Deps : FD_Array) return Attribute_Array;

   function Is_Lossless_Join
     (Relations    : Relation_Array;
      Dependencies : FD_Array) return Boolean;

   function All_Attributes (Relations : Relation_Array) return Attribute_Array;
end OLAP_Converter.Contexts;