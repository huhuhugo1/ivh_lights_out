library IEEE;
use IEEE.STD_LOGIC_1164.all;
-----------------------------------------------------------------------------------------------------------------
package math is

type mask_t is
record
    top		: std_logic;
    left    : std_logic;
    right   : std_logic;
    bottom  : std_logic;
end record;

function getmask(x,y : natural; COLUMNS, ROWS : natural) return mask_t;

end math;
-----------------------------------------------------------------------------------------------------------------
package body math is

function getmask(x,y : natural; COLUMNS, ROWS : natural) return mask_t is
variable 
    maska:mask_t:=(top=>'1', left=>'1', right=>'1', bottom=>'1');
begin
    if (x=0) then maska.left := '0'; end if;
    if (x=COLUMNS-1) then maska.right := '0'; end if;
    if (y=0) then maska.top := '0'; end if;
    if (y=ROWS-1) then maska.bottom := '0'; end if;
    
    return maska;
end getmask;
 
end math;