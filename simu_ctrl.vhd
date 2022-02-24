-- Controller of DeltaCam CCD frame simulator
-- It consists of a counter to address the simulator ROM,
-- and a generator of:
--  * Two clocks in phase opposition.
--  * Two frame id signals in phase opposition.
--  * The "new-frame" pulse.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity simu_ctrl is
  port( clk : in std_logic;
		  ad : out std_logic_vector(6 downto 0);
		  clk_0 : out std_logic;
		  clk_1 : out std_logic;
		  newf : out std_logic;
		  fid0 : out std_logic;
		  fid1 : out std_logic 
		);
end simu_ctrl;

architecture behavior of simu_ctrl is
begin
  process(clk)
    variable a : std_logic := '1';
    variable ck0 : std_logic := '1';
	 variable ck1 : std_logic := '0';
    variable c : std_logic_vector(6 downto 0) := "0000000";
	 variable nf : std_logic := '0';
	 variable f0 : std_logic := '0';
	 variable f1 : std_logic := '0';
  begin
    if (rising_edge(clk)) then
	   if (a = '0') then
		  ck0 := '1';
		  ck1 := '0';
		  c := c + 1;
		  a := '1';
		else
		  ck0 := '0';
		  ck1 := '1';
		  a:= '0';
		end if;
	 end if;
	 if (falling_edge(clk)) then
	   if (((c="0000000") or (c="1000000")) and (nf = '0')) then
		  nf := '1';
		  if (f0 = '0') then
		    f0 := '1';
			 f1 := '0';
		  else
		    f0 := '0';
			 f1 := '1';
		  end if;
     	else
	     nf := '0';
		end if;  
	 end if;
	 ad <= c;
	 clk_0 <= ck0;
	 clk_1 <= ck1;
	 newf <= nf;
	 fid0 <= f0;
	 fid1 <= f1;
  end process;
end behavior;