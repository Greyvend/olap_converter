select COLUMN_NAME
from information_schema.COLUMNS 
where TABLE_SCHEMA='faculty_xp' 
	  and TABLE_NAME='INFO'
	  and COLUMN_KEY='PRI'; 