-- 6-bit counter for process 1 (Mealy machine) of DeltaCam 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity mealy_count is
  port( clk : in std_logic;
        rst : in std_logic;
		  q : out std_logic_vector(5 downto 0)
		);
end mealy_count;

architecture behavior of mealy_count is
begin
  process(clk)
    variable c : std_logic_vector(5 downto 0) := "000000";
  begin
    if (rst = '1') then
	   c := "000000";
	 else
      if (rising_edge(clk)) then
		  c := c + 1;
		end if;  
	 end if;
	 q <= c;
  end process;
end behavior;