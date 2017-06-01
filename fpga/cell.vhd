----------------------------------------------------------------------------------
-- Engineer: Juraj Kubis (xkubis15)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.math.ALL; -- vysledek z prvniho ukolu


entity cell is
   GENERIC (
      MASK              : mask_t := (others => '1') -- mask_t definovano v baliku math_pack
   );
   Port ( 
      INVERT_REQ_IN     : in   STD_LOGIC_VECTOR (3 downto 0);
      INVERT_REQ_OUT    : out  STD_LOGIC_VECTOR (3 downto 0);
      
      KEYS              : in   STD_LOGIC_VECTOR (4 downto 0);
      
      SELECT_REQ_IN     : in   STD_LOGIC_VECTOR (3 downto 0);
      SELECT_REQ_OUT    : out  STD_LOGIC_VECTOR (3 downto 0);
      
      INIT_ACTIVE       : in   STD_LOGIC;
      ACTIVE            : out  STD_LOGIC;
      
      INIT_SELECTED     : in   STD_LOGIC;
      SELECTED          : out  STD_LOGIC;

      CLK               : in   STD_LOGIC;
      RESET             : in   STD_LOGIC
   );
end cell;

architecture Behavioral of cell is
  constant IDX_TOP    : NATURAL := 0; -- index sousedni bunky nachazejici se nahore v signalech *_REQ_IN a *_REQ_OUT, index klavesy posun nahoru v KEYS
  constant IDX_LEFT   : NATURAL := 1; -- ... totez        ...                vlevo
  constant IDX_RIGHT  : NATURAL := 2; -- ... totez        ...                vpravo
  constant IDX_BOTTOM : NATURAL := 3; -- ... totez        ...                dole
  
  constant IDX_ENTER  : NATURAL := 4; -- index klavesy v KEYS, zpusobujici inverzi bunky (enter, klavesa 5)

  signal S_ACTIVE     : STD_LOGIC;
  signal S_SELECTED   : STD_LOGIC;
begin

-- Pozadavky na funkci (sekvencni chovani vazane na vzestupnou hranu CLK)
--   pozadavky do okolnich bunek se posilaji a z okolnich bunek prijimaji, jen pokud je maska na prislusne pozici v '1'
  process (CLK, RESET)
  begin    
--   pri resetu se nastavi ACTIVE a SELECTED na vychozi hodnotu danou signaly INIT_ACTIVE a INIT_SELECTED    
    if (RESET = '1') then
      S_ACTIVE <= INIT_ACTIVE;
      S_SELECTED <= INIT_SELECTED;
    
    elsif (CLK'event and CLK = '1') then
      INVERT_REQ_OUT(3 downto 0) <= (others => '0');
      SELECT_REQ_OUT(3 downto 0) <= (others => '0');

--   pokud je bunka aktivni a prijde signal z klavesnice, tak se bud presune aktivita pomoci SELECT_REQ na dalsi bunky nebo se invertuje stav bunky a jejiho okoli pomoci INVERT_REQ (klavesa ENTER)
      if (S_SELECTED = '1') then
        if (KEYS(IDX_ENTER) = '1') then
          S_ACTIVE <= not S_ACTIVE;

          if (MASK.top = '1') then
            INVERT_REQ_OUT(IDX_TOP) <= '1';
          end if;
          
          if (MASK.left = '1') then
            INVERT_REQ_OUT(IDX_LEFT) <= '1';
          end if;
          
          if (MASK.right = '1') then
            INVERT_REQ_OUT(IDX_RIGHT) <= '1';
          end if;
          
          if (MASK.bottom = '1') then
            INVERT_REQ_OUT(IDX_BOTTOM) <= '1';
          end if;

        elsif (KEYS(IDX_TOP) = '1' and MASK.top = '1') then
          SELECT_REQ_OUT(IDX_TOP) <= '1';
          S_SELECTED <= '0';
        elsif (KEYS(IDX_LEFT) = '1' and MASK.left = '1') then
          SELECT_REQ_OUT(IDX_LEFT) <= '1';
          S_SELECTED <= '0';

        elsif (KEYS(IDX_RIGHT) = '1' and MASK.right = '1') then
          SELECT_REQ_OUT(IDX_RIGHT) <= '1';
          S_SELECTED <= '0';

        elsif (KEYS(IDX_BOTTOM) = '1' and MASK.bottom = '1') then
          SELECT_REQ_OUT(IDX_BOTTOM) <= '1';
          S_SELECTED <= '0';
        end if;

--   pokud bunka neni aktivni a prijde signal INVERT_REQ, invertuje svuj stav
      elsif (S_SELECTED = '0') then
          if (MASK.top = '1' and INVERT_REQ_IN(IDX_TOP) = '1') then
            S_ACTIVE <= not S_ACTIVE;
          elsif (MASK.left = '1' and INVERT_REQ_IN(IDX_LEFT) = '1') then
            S_ACTIVE <= not S_ACTIVE;
          elsif (MASK.right = '1' and INVERT_REQ_IN(IDX_RIGHT) = '1') then
            S_ACTIVE <= not S_ACTIVE;
          elsif (MASK.bottom = '1' and INVERT_REQ_IN(IDX_BOTTOM) = '1') then
            S_ACTIVE <= not S_ACTIVE;
          end if;   

          if (MASK.top = '1' and SELECT_REQ_IN(IDX_TOP) = '1') then
            S_SELECTED <= '1';
          elsif (MASK.left = '1' and SELECT_REQ_IN(IDX_LEFT) = '1') then
            S_SELECTED <= '1';
          elsif (MASK.right = '1' and SELECT_REQ_IN(IDX_RIGHT) = '1') then
            S_SELECTED <= '1';
          elsif (MASK.bottom = '1' and SELECT_REQ_IN(IDX_BOTTOM) = '1') then
            S_SELECTED <= '1';
          end if;      
      end if;     
    end if;
  end process;

ACTIVE <= S_ACTIVE;
SELECTED <= S_SELECTED;
  
end Behavioral;