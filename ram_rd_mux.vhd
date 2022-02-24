-- Muxltiplexer for the read data of the RAMs (between the 2nd and 3rd processes of Delta-Cam) 
-- One mux per axis
-- By S. Morel, Zthorus-Labs

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ram_rd_mux is
  port( d_0 : in std_logic_vector(8 downto 0);
        d_1 : in std_logic_vector(8 downto 0);
		  frame_id : in std_logic;
		  q: out std_logic_vector(8 downto 0)
		);
end ram_rd_mux;

architecture behavior of ram_rd_mux is
begin
  process(d_0,d_1,frame_id) 
  begin
    if (frame_id = '0') then
      q <= d_0;
	 else
	   q <= d_1;
    end if;
  end process;
end behavior;