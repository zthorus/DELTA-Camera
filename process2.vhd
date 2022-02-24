-- Process #2 of DeltaCam electronics
-- This process (one instance for each axis) takes the pre-centering data from the FIFOs,
-- calculates the photo-event projection coordinates and writes them in RAM.
-- The joining of photo-event projections overlapping two segments is done by this process
-- as well as the rejection of isolated illuminated pixels (considered as noise)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity process2 is
  port( clk : in std_logic;
        d_fifo : in std_logic_vector(9 downto 0);
		  fifo_emp : in std_logic;
		  n_frm : in std_logic;
		  fifo_rdrq : out std_logic;
	     fifo_sel : out std_logic; -- would have to be replaced by std_logic_vector for actual implementation (more than 2 segments per axis)
		  proc_state : out std_logic_vector(2 downto 0);
		  w_ram : out std_logic;
        a_ram : out std_logic_vector(3 downto 0);
		  d_ram : out std_logic_vector(8 downto 0)
		);
end process2;

architecture behavior of process2 is
begin
  process(clk,n_frm)
    variable f_sel : std_logic; -- would have to be replaced by std_logic_vector for actual implementation (more than 2 segments per axis)
	 variable f_rdrq : std_logic;
    variable state : std_logic_vector(2 downto 0);
    variable start : std_logic_vector(8 downto 0);
	 variable x : std_logic_vector(8 downto 0) :="000000000"; 
	 variable addr: std_logic_vector(3 downto 0);
	 variable wren : std_logic;
	 variable nofall : std_logic_vector(5 downto 0);
	 
  begin
     -- Process #2 is a finite-state machine with the following states:
	  --   000 = wait for start of spot 
	  --   001 = wait for end of spot
	  --   010 = write end-of-list
	  --   011 = idle (wait for next frame)
	  --   100 = spot overlapping segments
	  
    if (rising_edge(clk)) then
      if (n_frm = '1') then
		  -- new frame, reset process
		  f_sel := '0';
		  f_rdrq := '1';
		  addr := "1111"; -- RAM address will be set to 0 at next write
		  wren := '0';
		  state := "000";
	   else 
		  -- analyze 4-bit suffix (= edge on even pixel present, edge on odd pixel present, rising edge on even pixel, rising edge on odd pixel)
		  
		  if (state = "000") then 
		    if (d_fifo(3 downto 0) = "1010") then
		      -- rising edge on even pix, start spot
		      start := '0' & f_sel & d_fifo(9 downto 4) & '0'; 
			   state := "001";
			   wren := '0';
		    end if;
		    if (d_fifo(3 downto 0) = "0101") then 
		      -- rising edge on odd pix, start spot
		      start := '0' & f_sel & d_fifo(9 downto 4) & '1'; 
			   nofall := d_fifo(9 downto 4) + 1; -- set forbidden location of falling edge on even pix (to eliminate isolated illuminated pixel) 
			   state := "001";
			   wren := '0';
		    end if;
		  elsif (state = "100") then
			 if (d_fifo(3 downto 0) = "1010") then 
		    -- rising edge on even pix
		      if ((start and "001111111") /= "001111111") then
	         -- spot started on previous segment but not on last pixel (otherwise it's an isolated illuminated pixel)
		        x:= start + ('0' & f_sel & "0000000"); -- complete spot started on previous segment (falling edge on pix 0 cannot be detected by process1)
			     wren := '1';
			   else
	           wren := '0';
			   end if;
			   start := '0' & f_sel & d_fifo(9 downto 4) & '0'; 
			   state := "001";
		    end if;
		    if (d_fifo(3 downto 0) = "0101") then 
		      -- rising edge on odd pix
		      if ((start and "001111111") /= "001111111") then
			   -- spot started on previous segment but not on last pixel (otherwise it's an isolated illuminated pixel)
		        x:= start + ('0' & f_sel & "0000000"); -- complete spot started on previous segment (falling edge on pix 0 cannot be detected by process1)
			     wren := '1';
			   else
			     wren := '0';
			   end if;
			   start := '0' & f_sel & d_fifo(9 downto 4) & '1'; 
			   state := "001";
			 end if;
		  end if;
		  if ((state = "001") or (state = "100")) then
		    if (d_fifo(3 downto 0) = "1000") then
		      -- falling edge on even pix
		      x:= start + ('0' & f_sel & d_fifo(9 downto 4) & '0'); 
			   state := "000";
			   -- check validity of spot (shall not be an isolated illuminated pixel)
			   if (d_fifo(9 downto 4) = nofall) then
			     wren := '0'; -- invalid spot, do not write
			   else
			     wren := '1';
			     addr := addr + 1;
			   end if;
		    end if;
		    if (d_fifo(3 downto 0) = "0100") then
		      -- falling edge on odd pix
		      x:= start + ('0' & f_sel & d_fifo(9 downto 4) & '1'); 
			   state := "000";
			   wren := '1';
			   addr := addr + 1;
		    end if;
		    if (d_fifo(3 downto 0) = "1101") then
            -- falling edge on even pix immediately followed by rising edge on even pix (case of 1 non-illuminated pix between 2 spots)
		      x:= start + ('0' & f_sel & d_fifo(9 downto 4) & '0'); 
			   wren := '1';
			   start := '0' & f_sel & d_fifo(9 downto 4) & '1'; 
			   state := "001";
			 end if;
		  end if;
		  
		  if (((state = "000") or (state = "001")) and (fifo_emp = '1')) then
		    -- the current FIFO has been totally read
		    if (f_sel = '0') then
			   -- switch to next FIFO = next segment
			   f_sel := '1';
				if (state = "001") then
				  -- current spot may overlap segments
				  state := "100";
				end if;
			 else
			   -- all the FIFOs have been totally read
			   if (state = "001") then
				  -- case of spot at end of axis (no falling edge received)
				  x:= start + "011111111";
				  wren := '1';
				  addr := addr + 1;
				  f_rdrq := '0';
				end if;
			   state := "010";	
			 end if;
		  else
		    if (state = "010") then
			   -- write end-of-list word
			   x := "000000000"; -- we assume that 0 cannot be a spot coordinate
			   state := "011";
				wren := '1';
				addr := addr + 1;
			 else
			   if (state = "011") then
				  -- idle state
				  wren := '0';
				end if;
			 end if;
		  end if;
		end if;	
	 end if;		    
	 fifo_sel <= f_sel;
	 fifo_rdrq <= f_rdrq;
	 w_ram <= wren;
	 a_ram <= addr;
	 d_ram <= x;
	 proc_state <= state;
  end process;	 
end behavior;