-- Component to initialize Mealy machine (set state=0 on request, current state otherwise) 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity mealy_init is
  port( rst : in std_logic;
        cur_state: in std_logic_vector(2 downto 0);
		  q : out std_logic_vector(2 downto 0)
		);
end mealy_init;

architecture behavior of mealy_init is
begin
  process(rst,cur_state)
  begin
    if (rst = '1') then
	   q <= "000";
    else
	   q <= cur_state;
    end if;
  end process;	 
end behavior;