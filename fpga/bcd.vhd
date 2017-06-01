library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity bcd is
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           NUM1 : out  STD_LOGIC_VECTOR (3 downto 0);
           NUM2 : out  STD_LOGIC_VECTOR (3 downto 0);
           NUM3 : out  STD_LOGIC_VECTOR (3 downto 0));
end bcd;

architecture Behavioral of bcd is
	signal cnt_num1: std_logic_vector(3 downto 0) := (others => '0');
	signal cnt_num2: std_logic_vector(3 downto 0) := (others => '0');
	signal cnt_num3: std_logic_vector(3 downto 0) := (others => '0');
begin
  process (CLK, RST)
  begin
	if (RST = '1') then
	   cnt_num1(3 downto 0) <= (others => '0');
	   cnt_num2(3 downto 0) <= (others => '0');
	   cnt_num3(3 downto 0) <= (others => '0');
    elsif (CLK'event and  CLK = '1') then
      cnt_num1 <= cnt_num1 + 1;
      if (cnt_num1(3)='1' and cnt_num1(2)='0' and cnt_num1(1)='0' and cnt_num1(0)='1') then
        cnt_num1(3 downto 0) <= (others => '0');
        cnt_num2 <= cnt_num2 + 1;
        if (cnt_num2(3)='1' and cnt_num2(2)='0' and cnt_num2(1)='0' and cnt_num2(0)='1') then
          cnt_num2(3 downto 0) <= (others => '0');
          cnt_num3 <= cnt_num3 + 1;
          if (cnt_num3(3)='1' and cnt_num3(2)='0' and cnt_num3(1)='0' and cnt_num3(0)='1') then
            cnt_num3(3 downto 0) <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;
    
  NUM1 <= cnt_num1;
  NUM2 <= cnt_num2;
  NUM3 <= cnt_num3;
end Behavioral;