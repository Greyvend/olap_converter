with OLAP_Converter.RDB.Connection;            use OLAP_Converter.RDB.Connection;
with OLAP_Converter.RDB.Connection.Predicates; use OLAP_Converter.RDB.Connection.Predicates;

package OLAP_Converter.Connection_Table is
   -- low level procedures of creating relational tables (using RDB_Connector),
   -- that contain dimension context realizations and application context realization (TJs)
   function TJ
     (Name    : String;
      Attrs   : Attribute_Array;
      Context : Relation_Array;
      P       : Predicate) return Relation;
   -- Attrs :
   -- 1. attributes that are listed in an input dimension characteristics
end OLAP_Converter.Connection_Table;
