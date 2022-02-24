-- Multiplexer for the read data of the FIFOs (between the 1st and 2nd processes of Delta-Cam) and their "FIFO empty" signals
-- One mux per axis (= per 2nd-process instance)
-- By S. Morel, Zthorus-Labs

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity f_rd_mux is
  port( d : in std_logic_vector(39 downto 0);
        fifo_em: in std_logic_vector(3 downto 0);
        fifo_sel : in std_logic; -- would have to be replaced by std_logic_vector for actual implementation (more than 2 segments per axis)
		  frame_id : in std_logic;
		  q: out std_logic_vector(9 downto 0);
		  f_empty: out std_logic
		);
end f_rd_mux;

architecture behavior of f_rd_mux is
begin
  process(d,fifo_em,fifo_sel,frame_id) 
  begin
    if ((fifo_sel = '0') and (frame_id = '0')) then
      q <= d(39 downto 30);
	   f_empty <= fifo_em(3);
    end if;
    if ((fifo_sel = '1') and (frame_id = '0')) then
      q <= d(29 downto 20);
	   f_empty <= fifo_em(2);
    end if;
    if ((fifo_sel = '0') and (frame_id = '1')) then
      q <= d(19 downto 10);
	   f_empty <= fifo_em(1);
    end if;
    if ((fifo_sel = '1') and (frame_id = '1')) then
      q <= d(9 downto 0);
	   f_empty <= fifo_em(0);
    end if;
  end process;
end behavior;