library IEEE;
use IEEE.STD_LOGIC_1164.all;
-----------------------------------------------------------------------------------------------------------------
package idx is

function getidx(x, y, size, offset : natural) return natural;

end idx;
-----------------------------------------------------------------------------------------------------------------
package body idx is

function getidx(x, y, size, offset : natural) return natural is
begin
    return ((x mod size)+(y mod size)*size)*4 + (offset mod 4);
end getidx;
 
end idx;