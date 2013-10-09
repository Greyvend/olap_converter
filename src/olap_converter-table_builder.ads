with OLAP_Converter.Contexts; use OLAP_Converter.Contexts;

package OLAP_Converter.Table_Builder is
   --  Write given Connection Tables in ods file.
   --  This data representation is in fact a Hyper Cube.


   --!TODO: If this procedure is left alone, then we'll delete package and
   --! leave it as single file procedure (it is needed because there is outer
   --! project dependency planned).
   procedure Create_Table (TJ_Names : in Name_Array; File_Name :  out String);
   -- TJ_Names format:
   -- 1st is X Dimension TJ
   -- 2nd to N - 1 is Y_i Dimension TJ
   -- Nth is application TJ















--     type Dimension is
--        record
--           Attributes          : Access_Attribute_Array;
--           Attribute_Relations : Access_Relation_Array;
--           Measures            : Access_Attribute_Array := null;
--           Measure_Relations   : Access_Relation_Array  := null;
--           -- Filter_Formula      : Stub;
--           Context             : Access_Context;
--           Context_Realization : Relation;
--        end record;
--     type Access_Dimension is access all Dimension;
--     type Dimension_Array is array (Positive range <>) of Access_Dimension;
--     type Access_Dimension_Array is access all Dimension_Array;
--
--     type Cube_Schema is
--        record
--           Dimensions           : Access_Dimension_Array;
--           Dimension_Contexts   : Access_Context_Array;
--           Application_Dimension: Access_Dimension;
--           -- ^ sum of all dimensions, represented in overall attributes,
--           -- relations, measures and main logical formula
--           Application_Context  : Access_Context;
--        end record;
--
--     ----    type Cube_File is abstract tagged limited private;
--     ----     type Cube_File_Access is access all Cube_File;
--
--     type Cube is
--        record
--           Schema  : Cube_Schema;
--           --Storage : Cube_File;
--        end record;
--
--     procedure Stub;
--
--     --private
--     --     type Cube_File is abstract tagged limited
--     --        record
--     --           File_Name : String (1 .. Len);
end OLAP_Converter.Table_Builder;
