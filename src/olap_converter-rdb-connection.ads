--  with Qt4.Message_Boxes;
--  with Qt4.Strings;
--  with Qt4.Sql_Queries;
with Qt4.Sql_Databases;

package OLAP_Converter.RDB.Connection is
   type RDB_Schema is
      record
         Relations                 : Access_Relation_Array;
         Functional_Dependencies   : Access_FD_Array;
         Multi_Valued_Dependencies : Access_MVD_Array;
      end record;

   type DBMS is abstract tagged limited private;
   type Access_DBMS is access all DBMS'Class;

   type RDB_Connection is
      record
         Schema        : RDB_Schema;
         Access_System : Access_DBMS;
      end record;

   procedure Set_Schema
     (Relations : in     Relation_Array;
      Schema    :    out RDB_Schema);

   procedure Clear_Schema (Schema : in out RDB_Schema);

   function Connect
     (Driver_Name   : String;
      Host_Name     : String;
      Database_Name : Wide_String;
      User_Name     : String;
      Password      : String) return RDB_Connection;

   procedure Disconnect (RDB_C : in out RDB_Connection);

--     procedure Open (RDB_C : in out RDB_Connection);
--     procedure Close (RDB_C : in out RDB_Connection);

   function Table
     (Self : not null access DBMS'Class;
      Name : String) return Relation;

   procedure Attributes
     (Self : not null access DBMS;
      R    : in out Relation) is abstract;
   -- set attributes to the relation with given name

   procedure Count_Attributes
     (Self : not null access DBMS'Class;
      R    : in out Relation);
   -- count distinct values of all attributes in relation

   function Inclusion_Dependency
     (Self : not null access DBMS'Class;
      R1   : in Relation;
      R2   : in Relation;
      X    : in Attribute_Array) return Boolean;
   -- check if R1[X] is a subset of R2[X]

   procedure Values
     (Self : not null access DBMS'Class;
      R      : Relation;
      Params : Attribute_Array;
      X      : in out Attribute_Array);
   -- return R[X] where Params specify particular attribute values
   -- if several results are returned, then only the 1st row is evaluated

   procedure Primary_Key
     (Self : not null access DBMS;
      R    : in out Relation) is abstract;
   -- get all Primary Key attributes
   -- (several in the case of complex key)

   procedure Create_Table
     (Self : not null access DBMS;
      R    : Relation;
      Temp : Boolean := True) is abstract;

   procedure Create_TJ
     (Self      : not null access DBMS;
      Name      : String;
      DB_Name   : String := "";
      Relations : Relation_Array;
      Attrs     : Attribute_Array;
      Formula   : String) is abstract;

   procedure Drop_Table
     (Self : not null access DBMS;
      R    : Relation);

private
   type DBMS is abstract tagged limited
      record
         Name : Unbounded_String;                        --!TODO: add list of Connection Names
         DB : aliased Qt4.Sql_Databases.Q_Sql_Database; --!TODO: DB - active Q_Sql_Database
      end record;

   function Attribute_Names
     (Attrs : Attribute_Array;
      Modifier : String) return Unbounded_String;
end OLAP_Converter.RDB.Connection;