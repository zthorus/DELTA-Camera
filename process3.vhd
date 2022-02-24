-- Process #3 of DeltaCam electronics
-- This process takes the A,B,C coordinates from the RAMs
-- and finds out the triplets corresponding to a photo-event
-- (by calculating the sum A+B+C). The valid (A,B-C) coordinates are
-- sent to the output

-- Test on 2022-02-24: OK, but sum is 770 (would expect 767 from the simulated data)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity process3 is
  port( clk : in std_logic;
		  n_frm : in std_logic;
		  d_ram_a : in std_logic_vector(8 downto 0);
		  d_ram_b : in std_logic_vector(8 downto 0);
		  d_ram_c : in std_logic_vector(8 downto 0);
		  rdrq_ram : out std_logic;
        a_ram_a : out std_logic_vector(3 downto 0);
        a_ram_b : out std_logic_vector(3 downto 0);
        a_ram_c : out std_logic_vector(3 downto 0);
		  a_photon : out std_logic_vector(8 downto 0);
		  bmc_photon : out std_logic_vector(9 downto 0);
		  valid : out std_logic;
		  overload : out std_logic;
		  sum_test : out std_logic_vector(10 downto 0) -- test for debug
		);
end process3;

architecture behavior of process3 is
begin
  process(clk)
    variable a_idx : std_logic_vector(3 downto 0) := "0000";
	 variable b_idx : std_logic_vector(3 downto 0) := "0000";
	 variable c_idx : std_logic_vector(3 downto 0) := "0000";
	 variable a_test : std_logic_vector(8 downto 0);
	 variable b_test : std_logic_vector(8 downto 0);
	 variable c_test : std_logic_vector(8 downto 0);
	 variable sum : std_logic_vector(10 downto 0);
	 variable a_ph : std_logic_vector(8 downto 0) := "000000000";
	 variable bmc_ph : std_logic_vector(9 downto 0) := "0000000000";
	 variable vld : std_logic := '0';
	 variable idle : std_logic := '1';
	 variable rd_rq : std_logic := '0';
	 variable ovload : std_logic := '0';
		
  begin
    if (rising_edge(clk)) then
	   if (n_frm = '1') then
		  -- new frame, reset process
		  a_idx := "0000";
		  b_idx := "0000";
		  c_idx := "0000";
		  if (idle = '0') then
		    -- process was still busy and could not test all the triplets => raise overload flag
		    ovload := '1';
		  else
		    idle := '0';
			 ovload := '0';
			 rd_rq := '1';
		  end if;
	   else 
		  if (idle = '0') then
	   	 a_test := d_ram_a;
		    b_test := d_ram_b;
		    c_test := d_ram_c;
		    if (a_test = "000000000") then
		      a_idx := "0000";
			   b_idx := b_idx + 1;
			   a_ph := "000000000";
	         bmc_ph:= "0000000000";
	         vld := '0';
		    elsif (b_test = "000000000") then
		      b_idx := "0000";
		      c_idx := c_idx + 1;
		      a_ph := "000000000";
	         bmc_ph:= "0000000000";
	         vld := '0';
		    elsif (c_test = "000000000") then
		      -- end of all possible triplets reached => stop process
			   idle := '1';
			   a_ph := "000000000";
	         bmc_ph := "0000000000";
	         vld := '0';
				rd_rq := '0';
          else		  
			   sum := ("00" & a_test) + ("00" & b_test) + ("00" & c_test);
		      if ((sum = "01100000000") or (sum = "01100000001") or (sum = "01100000010") or (sum = "01011111111") or (sum = "01011111110")) then
			     a_ph := a_test;
	           bmc_ph := ('0' & b_test) + ('1' & not c_test) + "1000000001"; -- b-c = b + not c + 1 ; to do : verify offset value (512 ?)
	           vld := '1';
	         else
	           a_ph := "000000000";
	           bmc_ph:= "0000000000";
	           vld := '0';
	         end if;
	         a_idx := a_idx + 1;		 
		    end if;
		  end if;
		end if;
		a_ram_a <= a_idx;
	   a_ram_b <= b_idx;
	   a_ram_c <= c_idx;
	   rdrq_ram <= rd_rq;
	   a_photon <= a_ph;
	   bmc_photon <= bmc_ph;
	   valid <= vld;
	   overload <= ovload;
		sum_test <= sum;
	 end if;
  end process;
 end behavior; 
	