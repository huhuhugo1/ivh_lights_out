library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.vga_controller_cfg.all;
use work.math.all;
use work.idx.all;

architecture main of tlv_pc_ifc is

   signal color_active : std_logic_vector(8 downto 0) := "111101000";
   signal color_non_active : std_logic_vector(8 downto 0) := "000010010"; 
   signal color_bg : std_logic_vector(8 downto 0) := "000000000";
   signal color_cursor: std_logic_vector(8 downto 0) := "111000000";   

   signal vga_mode  : std_logic_vector(60 downto 0); -- default 640x480x60

   signal irgb : std_logic_vector(8 downto 0);

   signal row, edited_row : std_logic_vector(11 downto 0);
   signal col, edited_col : std_logic_vector(11 downto 0);

   signal NUM1, NUM2, NUM3 : std_logic_vector(3 downto 0);
   signal RST:std_logic := '0';

   signal active_array : std_logic_vector(24 downto 0);
   signal init_active : std_logic_vector(24 downto 0);
   signal selected_array : std_logic_vector(24 downto 0);
   signal init_selected : std_logic_vector(24 downto 0);

   signal invert_req_array : std_logic_vector(99 downto 0);
   signal select_req_array : std_logic_vector(99 downto 0);

   signal kbrd_data_out : std_logic_vector(15 downto 0);
   signal kbrd_data_vld : std_logic;  

   signal key : std_logic_vector(4 downto 0); 

   signal char_symbol : std_logic_vector(3 downto 0) := "1010";
   signal char_data : std_logic;

   constant IDX_TOP    : NATURAL := 0; -- index sousedni bunky nachazejici se nahore v signalech *_REQ_IN a *_REQ_OUT, index klavesy posun nahoru v KEYS
   constant IDX_LEFT   : NATURAL := 1; -- ... totez        ...                vlevo
   constant IDX_RIGHT  : NATURAL := 2; -- ... totez        ...                vpravo
   constant IDX_BOTTOM : NATURAL := 3; -- ... totez        ...                dole
   constant IDX_ENTER  : NATURAL := 4; -- index klavesy v KEYS, zpusobujici inverzi bunky (enter, klavesa 5)
begin

   -- Nastaveni grafickeho rezimu (640x480, 60 Hz refresh)
   setmode(r640x480x60, vga_mode);

   vga: entity work.vga_controller(arch_vga_controller) 
      generic map (REQ_DELAY => 1)
      port map (
        CLK    => CLK, 
        RST    => RESET,
        ENABLE => '1',
        MODE   => vga_mode,

        DATA_RED    => irgb(8 downto 6),
        DATA_GREEN  => irgb(5 downto 3),
        DATA_BLUE   => irgb(2 downto 0),
        ADDR_COLUMN => col,
        ADDR_ROW    => row,

        VGA_RED   => RED_V,
        VGA_BLUE  => BLUE_V,
        VGA_GREEN => GREEN_V,
        VGA_HSYNC => HSYNC_V,
        VGA_VSYNC => VSYNC_V
      );
  
  bcd: entity work.bcd
      port map (CLK => key(IDX_ENTER), RST => RST, NUM1 => NUM1, NUM2 => NUM2, NUM3 => NUM3);

    -- char 2 vga decoder
  chardec : entity work.char_rom
    port map (
      ADDRESS => char_symbol,
      ROW => row(3 downto 0),
      COLUMN => col(2 downto 0),
      DATA => char_data
     );

  kbrd_ctrl: entity work.keyboard_controller(arch_keyboard)
    port map (
      CLK => SMCLK,
      RST => RST,

      DATA_OUT => kbrd_data_out(15 downto 0),
      DATA_VLD => kbrd_data_vld,
       
      KB_KIN   => KIN,
      KB_KOUT  => KOUT
    );

  cursor: process(CLK)
    variable in_access : std_logic := '0';
  begin
    if CLK'event and CLK='1' then
      key <= "00000";
      RST <= '0';

      if in_access='0' then
          if kbrd_data_vld='1' then 
            
            in_access:='1';
            
            if kbrd_data_out(4)='1' then      -- key 2
              key(IDX_TOP) <= '1';
            elsif kbrd_data_out(1)='1' then   -- key 4
              key(IDX_LEFT) <= '1';
            elsif kbrd_data_out(9)='1' then   -- key 6
              key(IDX_RIGHT) <= '1';
            elsif kbrd_data_out(6)='1' then   -- key 8
              key(IDX_BOTTOM) <= '1';
            elsif kbrd_data_out(5)='1' then   -- key 5
              key(IDX_ENTER) <= '1';

            elsif kbrd_data_out(12)='1' then    -- key A
              init_active <= "1101101101010101100011100";
              init_selected <= "0000000000001000000000000";
              RST <= '1';
            elsif kbrd_data_out(13)='1' then    -- key B
              init_active <= "0101101101010101111101000";
              init_selected <= "0000000000001000000000000";
              RST <= '1';
            elsif kbrd_data_out(14)='1' then    -- key C
              init_active <= "1101110101011101010111011";
              init_selected <= "0000000000001000000000000";
              RST <= '1'; 
            elsif kbrd_data_out(15)='1' then    -- key D
              init_active <= "0010011101001110011101111";
              init_selected <= "0000000000001000000000000";
              RST <= '1';             
            end if;
          end if;
       else
          if kbrd_data_vld='0' then 
            in_access:='0';
          end if;
       end if;
    end if;
      
  end process;
   
  stlpec: for x in 0 to 4 generate
    riadok: for y in 0 to 4 generate
      matrix: entity work.cell
        generic map(MASK => getmask(x,y,5,5))
        port map (
          CLK => CLK,
          RESET => RST,

          INIT_ACTIVE => init_active(x+y*5),
          INIT_SELECTED => init_selected(x+y*5),  

          ACTIVE => active_array(y*5+x),
          SELECTED => selected_array(y*5+x),

          INVERT_REQ_IN(IDX_TOP) => invert_req_array(getidx(x,y-1,5,IDX_BOTTOM)),
          INVERT_REQ_IN(IDX_LEFT) => invert_req_array(getidx(x-1,y,5,IDX_RIGHT)),
          INVERT_REQ_IN(IDX_RIGHT) => invert_req_array(getidx(x+1,y,5,IDX_LEFT)),
          INVERT_REQ_IN(IDX_BOTTOM) => invert_req_array(getidx(x,y+1,5,IDX_TOP)),

          SELECT_REQ_IN(IDX_TOP) => select_req_array(getidx(x,y-1,5,IDX_BOTTOM)),
          SELECT_REQ_IN(IDX_LEFT) => select_req_array(getidx(x-1,y,5,IDX_RIGHT)),
          SELECT_REQ_IN(IDX_RIGHT) => select_req_array(getidx(x+1,y,5,IDX_LEFT)),
          SELECT_REQ_IN(IDX_BOTTOM) => select_req_array(getidx(x,y+1,5,IDX_TOP)),

          INVERT_REQ_OUT(IDX_TOP) => invert_req_array(getidx(x,y,5,IDX_TOP)),
          INVERT_REQ_OUT(IDX_LEFT) => invert_req_array(getidx(x,y,5,IDX_LEFT)),
          INVERT_REQ_OUT(IDX_RIGHT) => invert_req_array(getidx(x,y,5,IDX_RIGHT)),
          INVERT_REQ_OUT(IDX_BOTTOM) => invert_req_array(getidx(x,y,5,IDX_BOTTOM)),

          SELECT_REQ_OUT(IDX_TOP) => select_req_array(getidx(x,y,5,IDX_TOP)),
          SELECT_REQ_OUT(IDX_LEFT) => select_req_array(getidx(x,y,5,IDX_LEFT)),
          SELECT_REQ_OUT(IDX_RIGHT) => select_req_array(getidx(x,y,5,IDX_RIGHT)),
          SELECT_REQ_OUT(IDX_BOTTOM) => select_req_array(getidx(x,y,5,IDX_BOTTOM)),       

          KEYS(IDX_TOP) => key(IDX_TOP),
          KEYS(IDX_LEFT) => key(IDX_LEFT),
          KEYS(IDX_RIGHT) => key(IDX_RIGHT),
          KEYS(IDX_BOTTOM) => key(IDX_BOTTOM),
          KEYS(IDX_ENTER) => key(IDX_ENTER)
        );
    end generate riadok;
  end generate stlpec;

  edited_row <= row - 80;  
  edited_col <= col - 160;

  draw: process(CLK)
  begin 
    irgb <= color_bg;

    if edited_row(8 downto 6) = "000" then
      if edited_col(8 downto 6) = "000" then
        if active_array(0) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(0) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(0)); end if;
      end if;

      if edited_col(8 downto 6) = "001" then
        if active_array(1) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(1) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(1)); end if;
      end if;

      if edited_col(8 downto 6) = "010" then
        if active_array(2) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(2) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(2)); end if;
      end if;

      if edited_col(8 downto 6) = "011" then
        if active_array(3) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(3) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(3)); end if;
      end if;

      if edited_col(8 downto 6) = "100" then
        if active_array(4) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(4) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(4)); end if;
      end if;
    end if;
    
    --------------------------------------------------------------------------------------------------
    
    if edited_row(8 downto 6) = "001" then
      if edited_col(8 downto 6) = "000" then
        if active_array(5) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(5) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(5)); end if;
      end if;

      if edited_col(8 downto 6) = "001" then
        if active_array(6) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(6) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(6)); end if;
      end if;

      if edited_col(8 downto 6) = "010" then
        if active_array(7) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(7) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(7)); end if;
      end if;

      if edited_col(8 downto 6) = "011" then
        if active_array(8) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(8) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(8)); end if;
      end if;

      if edited_col(8 downto 6) = "100" then
        if active_array(9) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(9) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(9)); end if;
      end if;
    end if;

    --------------------------------------------------------------------------------------------------
    
    if edited_row(8 downto 6) = "010" then
      if edited_col(8 downto 6) = "000" then
        if active_array(10) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(10) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(10)); end if;
      end if;

      if edited_col(8 downto 6) = "001" then
        if active_array(11) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(11) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(11)); end if;
      end if;

      if edited_col(8 downto 6) = "010" then
        if active_array(12) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(12) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(12)); end if;
      end if;

      if edited_col(8 downto 6) = "011" then
        if active_array(13) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(13) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(13)); end if;
      end if;

      if edited_col(8 downto 6) = "100" then
        if active_array(14) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(14) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(14)); end if;
      end if;
    end if;

    --------------------------------------------------------------------------------------------------
    
    if edited_row(8 downto 6) = "011" then
      if edited_col(8 downto 6) = "000" then
        if active_array(15) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(15) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(15)); end if;
      end if;

      if edited_col(8 downto 6) = "001" then
        if active_array(16) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(16) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(16)); end if;
      end if;

      if edited_col(8 downto 6) = "010" then
        if active_array(17) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(17) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(17)); end if;
      end if;

      if edited_col(8 downto 6) = "011" then
        if active_array(18) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(18) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(18)); end if;
      end if;

      if edited_col(8 downto 6) = "100" then
        if active_array(19) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(19) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(19)); end if;
      end if;
    end if;

    --------------------------------------------------------------------------------------------------
    
    if edited_row(8 downto 6) = "100" then
      if edited_col(8 downto 6) = "000" then
        if active_array(20) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(20) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(20)); end if;
      end if;

      if edited_col(8 downto 6) = "001" then
        if active_array(21) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(21) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(21)); end if;
      end if;

      if edited_col(8 downto 6) = "010" then
        if active_array(22) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(22) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(22)); end if;
      end if;

      if edited_col(8 downto 6) = "011" then
        if active_array(23) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(23) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(23)); end if;
      end if;

      if edited_col(8 downto 6) = "100" then
        if active_array(24) = '1' then irgb <= color_active; else irgb <= color_non_active; end if;
        if selected_array(24) = '1' and edited_col(5) /= edited_col(4) and edited_row(5) /= edited_row(4) then irgb <= (others => not active_array(24)); end if;
      end if;
    end if; 

    if edited_row (5 downto 0) = "000000" or edited_col(5 downto 0) = "000000" then
      	irgb <= color_bg;
      end if;

    if row(11 downto 4) = "00011001" then
      if col(11 downto 3) = "000111011" then
        char_symbol <= NUM1;
        irgb <= (others => char_data);
      end if;
      if col(11 downto 3) = "000111010" then
        char_symbol <= NUM2;
        irgb <= (others => char_data);
      end if;
      if col(11 downto 3) = "000111001" then
        char_symbol <= NUM3;
        irgb <= (others => char_data);
      end if;

    end if;

  end process;
end main;