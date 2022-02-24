-- Demux for the read-enable signals of the FIFOs (between the 1st and 2nd processes of Delta-Cam)
-- One demux per axis (= per 2nd-process instance)
-- By S. Morel, Zthorus-Labs

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity f_rd_demux is
  port( rd_req : in std_logic;
        fifo_sel : in std_logic; -- would have to be replaced by std_logic_vector for actual implementation (more than 2 segments per axis)
		  frame_id : in std_logic;
		  f_rd: out std_logic_vector(3 downto 0)
		);
end f_rd_demux;

architecture behavior of f_rd_demux is
begin
  process(rd_req,frame_id,fifo_sel)
    variable frd : std_logic_vector(3 downto 0);
  begin
    if (rd_req = '1') then
	   if ((frame_id = '0') and (fifo_sel = '0')) then frd := "1000"; end if;
	   if ((frame_id = '0') and (fifo_sel = '1')) then frd := "0100"; end if;
	   if ((frame_id = '1') and (fifo_sel = '0')) then frd := "0010"; end if;
		if ((frame_id = '1') and (fifo_sel = '1')) then frd := "0001"; end if;
	 else
	   frd := "0000";
	 end if;
	 f_rd <= frd;
  end process;
end behavior;
