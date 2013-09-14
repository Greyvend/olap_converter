package OLAP_Converter.RDB.Connection.MySQL is
   type DBMS is new OLAP_Converter.RDB.Connection.DBMS with null record;

   procedure Attributes
     (Self : not null access DBMS;
      R    : in out Relation);
   -- set attributes to the relation with given name

   procedure Primary_Key
     (Self : not null access DBMS;
      R    : in out Relation);
   -- get all Primary Key attributes
   -- (several in the case of complex key)
   -- provide relation, filled with name and
   -- attributes

   procedure Create_Table
     (Self : not null access DBMS;
      R    : Relation;
      Temp : Boolean := True);

   procedure Create_TJ
     (Self      : not null access DBMS;
      Name      : String;
      DB_Name   : String := "";
      Relations : Relation_Array;
      Attrs     : Attribute_Array;
      Formula   : String);
end OLAP_Converter.RDB.Connection.MySQL;