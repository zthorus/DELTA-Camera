-- DELTA-camera control electronics (feasibility demonstration)
-- This device takes the binarized output of the three TH7809A linear CCDs
-- (on which the photo-events are projected on axes A, B and C) and calculates
-- the coordinates of the photo-events

-- This implementation simulates the hypothetic case in which the linear CCDs
-- have 2 segments (instead of 8), still consisting of 128 pixels with even and
-- odd pixels read in parallel. 

-- The CCD frames are simulated by a ROM containing the data

-- This control electronics works in continuous read of the CCD (pipe-line) and uses
-- two banks of memory elements (FIFOs, RAMs) between the processes. These two banks
-- are switched (reading and writing are swapped) at each new frame.

-- The current version (2022-02-24) does not include the "4th process" which would just
-- consist of a look-up table in ROM to scale down the resolved y-coordinates by a
-- 1/sqrt(3) factor. The limits of the free edition of Intel Quartus Prime and ModelSim
-- (on which this project has been developped) seem to have been reached.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity DeltaCam is 
  port(
        clock    : in std_logic;    
		  test_out : out std_logic_vector(26 downto 0)
		);
end DeltaCam;

architecture behavior of DeltaCam is
  signal clk_j : std_logic;                           -- clock for memory components (FIFOs, RAMs, ROMs except Mealy machines), rising edge
  signal clk_k : std_logic;                           -- clock for the processes, rising edge, in phase opposition with clk_j
  signal pix_counter : std_logic_vector(6 downto 0);  -- counter of pixel-pairs of segments
  signal frame_0 : std_logic;                         -- selector for memory bank 0
  signal	frame_1 : std_logic;                         -- selector for memory bank 1, in phase opposition with frame_0
  signal state_a0 : std_logic_vector(2 downto 0);     -- states of Mealy machines
  signal state_a1 : std_logic_vector(2 downto 0);
  signal state_b0 : std_logic_vector(2 downto 0);
  signal state_b1 : std_logic_vector(2 downto 0);
  signal state_c0 : std_logic_vector(2 downto 0);
  signal state_c1 : std_logic_vector(2 downto 0);
  signal d_a0 : std_logic_vector(7 downto 0);         -- output of Mealy machines (state, photo-event edge data, validity flag)
  signal d_a1 : std_logic_vector(7 downto 0);
  signal d_b0 : std_logic_vector(7 downto 0);
  signal d_b1 : std_logic_vector(7 downto 0);
  signal d_c0 : std_logic_vector(7 downto 0);
  signal d_c1 : std_logic_vector(7 downto 0);
  signal new_frame : std_logic;                        -- pulse marking beginning of a new frame
  signal frame_data : std_logic_vector(11 downto 0);
  signal addr_mrom_a0 : std_logic_vector(4 downto 0);  -- input of Mealy machine (state and even/odd pair of pixel values)
  signal addr_mrom_a1 : std_logic_vector(4 downto 0);
  signal addr_mrom_b0 : std_logic_vector(4 downto 0);
  signal addr_mrom_b1 : std_logic_vector(4 downto 0);
  signal addr_mrom_c0 : std_logic_vector(4 downto 0);
  signal addr_mrom_c1 : std_logic_vector(4 downto 0);
  signal f_a0_in : std_logic_vector(9 downto 0);        -- input of FIFOs between 1st and 2nd processes (alias FIFO_12s)
  signal f_a1_in : std_logic_vector(9 downto 0);
  signal f_b0_in : std_logic_vector(9 downto 0);
  signal f_b1_in : std_logic_vector(9 downto 0);
  signal f_c0_in : std_logic_vector(9 downto 0);
  signal f_c1_in : std_logic_vector(9 downto 0);
  signal f_a0_0_out : std_logic_vector(9 downto 0);     -- output of FIFO_12s
  signal f_a0_1_out : std_logic_vector(9 downto 0);
  signal f_a1_0_out : std_logic_vector(9 downto 0);
  signal f_a1_1_out : std_logic_vector(9 downto 0);
  signal f_b0_0_out : std_logic_vector(9 downto 0);
  signal f_b0_1_out : std_logic_vector(9 downto 0);
  signal f_b1_0_out : std_logic_vector(9 downto 0);
  signal f_b1_1_out : std_logic_vector(9 downto 0);
  signal f_c0_0_out : std_logic_vector(9 downto 0);
  signal f_c0_1_out : std_logic_vector(9 downto 0);
  signal f_c1_0_out : std_logic_vector(9 downto 0);
  signal f_c1_1_out : std_logic_vector(9 downto 0);
  signal f_rd_a0_0 : std_logic;                          -- read-enable input flag of FIFO_12s
  signal f_rd_a0_1 : std_logic;
  signal f_rd_a1_0 : std_logic;
  signal f_rd_a1_1 : std_logic;
  signal f_rd_b0_0 : std_logic;
  signal f_rd_b0_1 : std_logic;
  signal f_rd_b1_0 : std_logic;
  signal f_rd_b1_1 : std_logic;
  signal f_rd_c0_0 : std_logic;
  signal f_rd_c0_1 : std_logic;
  signal f_rd_c1_0 : std_logic;
  signal f_rd_c1_1 : std_logic;
  signal f_wr_a0_0 : std_logic;                          -- write-enable input flag of FIFO_12s
  signal f_wr_a0_1 : std_logic;
  signal f_wr_a1_0 : std_logic;
  signal f_wr_a1_1 : std_logic;
  signal f_wr_b0_0 : std_logic;
  signal f_wr_b0_1 : std_logic;
  signal f_wr_b1_0 : std_logic;
  signal f_wr_b1_1 : std_logic;
  signal f_wr_c0_0 : std_logic;
  signal f_wr_c0_1 : std_logic;
  signal f_wr_c1_0 : std_logic;
  signal f_wr_c1_1 : std_logic;
  signal f_em_a0_0 : std_logic;                           -- empty-state flag of FIFO_12s
  signal f_em_a0_1 : std_logic;
  signal f_em_a1_0 : std_logic;
  signal f_em_a1_1 : std_logic;
  signal f_em_b0_0 : std_logic;
  signal f_em_b0_1 : std_logic;
  signal f_em_b1_0 : std_logic;
  signal f_em_b1_1 : std_logic;
  signal f_em_c0_0 : std_logic;
  signal f_em_c0_1 : std_logic;
  signal f_em_c1_0 : std_logic;
  signal f_em_c1_1 : std_logic;
  signal f_all_out_a : std_logic_vector(39 downto 0);     -- grouping of all output bits of FIFO_12s (input of mux)
  signal f_all_out_b : std_logic_vector(39 downto 0);
  signal f_all_out_c : std_logic_vector(39 downto 0);
  signal f_all_em_a : std_logic_vector(3 downto 0);       -- grouping of all empty-state flags of FIFO_12s (input of mux)
  signal f_all_em_b : std_logic_vector(3 downto 0);
  signal f_all_em_c : std_logic_vector(3 downto 0);
  signal f_a_out : std_logic_vector (9 downto 0);         -- selected FIFO_12 output (feeding input of process2) 
  signal f_b_out : std_logic_vector (9 downto 0); 
  signal f_c_out : std_logic_vector (9 downto 0); 
  signal f_rd_a : std_logic_vector(3 downto 0);            -- fan-out of read-enable flag to all FIFO_12s
  signal f_rd_b : std_logic_vector(3 downto 0);
  signal f_rd_c : std_logic_vector(3 downto 0);
  signal f_sel_a : std_logic;                              -- FIFO_12 (any of the 2 banks) selected by process2 for readout
  signal f_sel_b : std_logic; -- (would have to be replaced by std_logic_vector for actual implementation (more than 2 segments per axis))
  signal f_sel_c : std_logic; 
  signal f_em_a : std_logic;                               -- FIFO_12 empty-state flag at input of process2
  signal f_em_b : std_logic;
  signal f_em_c : std_logic;
  signal f_rd_req_a : std_logic;                           -- FIFO_12 read-enable flag at output of process2
  signal f_rd_req_b : std_logic;
  signal f_rd_req_c : std_logic;
  signal ram_wr_a : std_logic;                             -- write-enable flags (issued by proc2) of RAM containing resolved A,B,C photo-event coordinates 
  signal ram_wr_b : std_logic;
  signal ram_wr_c : std_logic;
  signal ram_wr_a_0 : std_logic;                           -- write enable input flags of RAMs, bank 0
  signal ram_wr_b_0 : std_logic;
  signal ram_wr_c_0 : std_logic;
  signal ram_wr_a_1 : std_logic;                           -- write enable input flags of RAMs, bank 1
  signal ram_wr_b_1 : std_logic;
  signal ram_wr_c_1 : std_logic;
  signal ram_rd: std_logic;                                -- read-enable flag of RAMs (all together) issued by process3
  signal ram_rd_0 : std_logic;                             -- read-enable flag of RAMS bank 0
  signal ram_rd_1 : std_logic;                             -- read-enable flag of RAMs bank 1
  signal ram_adw_a : std_logic_vector(3 downto 0);         -- address of RAMs (writing)
  signal ram_adw_b : std_logic_vector(3 downto 0);
  signal ram_adw_c : std_logic_vector(3 downto 0);
  signal ram_d_a : std_logic_vector(8 downto 0);           -- RAM input data
  signal ram_d_b : std_logic_vector(8 downto 0); 
  signal ram_d_c : std_logic_vector(8 downto 0);
  signal ram_adr_a : std_logic_vector(3 downto 0);         -- address of RAMs (reading)
  signal ram_adr_b : std_logic_vector(3 downto 0);
  signal ram_adr_c : std_logic_vector(3 downto 0);
  signal ram_q_a_0 : std_logic_vector(8 downto 0);         -- RAM output data
  signal ram_q_b_0 : std_logic_vector(8 downto 0);
  signal ram_q_c_0 : std_logic_vector(8 downto 0);
  signal ram_q_a_1 : std_logic_vector(8 downto 0);       
  signal ram_q_b_1 : std_logic_vector(8 downto 0);
  signal ram_q_c_1 : std_logic_vector(8 downto 0);
  signal d_ram_a   : std_logic_vector(8 downto 0) ;        -- data from RAMs at input of process3
  signal d_ram_b   : std_logic_vector(8 downto 0) ;        -- data from RAMs at input of process3
  signal d_ram_c   : std_logic_vector(8 downto 0) ;        -- data from RAMs at input of process3
  signal clk_ram : std_logic;                              -- clock signal of RAMs
  signal a_ph : std_logic_vector(8 downto 0);              -- resolved a (=x) coordinate of photo-event
  signal bmc_ph : std_logic_vector(9 downto 0);            -- resolved b-c (~ y) coordinate of photo-event
  signal val_ph : std_logic;                               -- validity of photo-event coordinates 
  signal ovload : std_logic;                               -- data overload flag (too much (A,B,C) triplets for frame duration)

  signal proc2_state_a : std_logic_vector(2 downto 0);     -- states of process2 (only for debug purpose)
  signal proc2_state_b : std_logic_vector(2 downto 0);
  signal proc2_state_c : std_logic_vector(2 downto 0);
  signal sum : std_logic_vector(10 downto 0);         -- sum A+B+C in process3 (only for debug purpose)

  
begin

  -- frame simulator 
  simulator_controller : entity work.simu_ctrl port map(clock,pix_counter,clk_j,clk_k,new_frame,frame_0,frame_1);
  data_rom : entity work.simu_rom port map(pix_counter,clk_j,frame_data);

  -- 1st process (photo-event projection pre-centering by Mealy machines stored in ROMs)
  mealy_rom_a0 : entity work.mealy_rom port map(addr_mrom_a0,clk_k,d_a0);
  mealy_init_a0 : entity work.mealy_init port map(new_frame,d_a0(7 downto 5),state_a0);
  mealy_rom_a1 : entity work.mealy_rom port map(addr_mrom_a1,clk_k,d_a1);
  mealy_init_a1 : entity work.mealy_init port map(new_frame,d_a1(7 downto 5),state_a1);
  mealy_rom_b0 : entity work.mealy_rom port map(addr_mrom_b0,clk_k,d_b0);
  mealy_init_b0 : entity work.mealy_init port map(new_frame,d_b0(7 downto 5),state_b0);
  mealy_rom_b1 : entity work.mealy_rom port map(addr_mrom_b1,clk_k,d_b1);
  mealy_init_b1 : entity work.mealy_init port map(new_frame,d_b1(7 downto 5),state_b1);
  mealy_rom_c0 : entity work.mealy_rom port map(addr_mrom_c0,clk_k,d_c0);
  mealy_init_c0 : entity work.mealy_init port map(new_frame,d_c0(7 downto 5),state_c0);
  mealy_rom_c1 : entity work.mealy_rom port map(addr_mrom_c1,clk_k,d_c1);
  mealy_init_c1 : entity work.mealy_init port map(new_frame,d_c1(7 downto 5),state_c1);
  
  -- FIFOs between 1st and 2nd processes
  fifo_a0_0 : entity work.p12_fifo port map(clk_j,f_a0_in,f_rd_a0_0,f_wr_a0_0,f_em_a0_0,f_a0_0_out);
  fifo_a0_1 : entity work.p12_fifo port map(clk_j,f_a0_in,f_rd_a0_1,f_wr_a0_1,f_em_a0_1,f_a0_1_out);
  fifo_a1_0 : entity work.p12_fifo port map(clk_j,f_a1_in,f_rd_a1_0,f_wr_a1_0,f_em_a1_0,f_a1_0_out);
  fifo_a1_1 : entity work.p12_fifo port map(clk_j,f_a1_in,f_rd_a1_1,f_wr_a1_1,f_em_a1_1,f_a1_1_out);
  fifo_b0_0 : entity work.p12_fifo port map(clk_j,f_b0_in,f_rd_b0_0,f_wr_b0_0,f_em_b0_0,f_b0_0_out);
  fifo_b0_1 : entity work.p12_fifo port map(clk_j,f_b0_in,f_rd_b0_1,f_wr_b0_1,f_em_b0_1,f_b0_1_out);
  fifo_b1_0 : entity work.p12_fifo port map(clk_j,f_b1_in,f_rd_b1_0,f_wr_b1_0,f_em_b1_0,f_b1_0_out);
  fifo_b1_1 : entity work.p12_fifo port map(clk_j,f_b1_in,f_rd_b1_1,f_wr_b1_1,f_em_b1_1,f_b1_1_out);
  fifo_c0_0 : entity work.p12_fifo port map(clk_j,f_c0_in,f_rd_c0_0,f_wr_c0_0,f_em_c0_0,f_c0_0_out);
  fifo_c0_1 : entity work.p12_fifo port map(clk_j,f_c0_in,f_rd_c0_1,f_wr_c0_1,f_em_c0_1,f_c0_1_out);
  fifo_c1_0 : entity work.p12_fifo port map(clk_j,f_c1_in,f_rd_c1_0,f_wr_c1_0,f_em_c1_0,f_c1_0_out);
  fifo_c1_1 : entity work.p12_fifo port map(clk_j,f_c1_in,f_rd_c1_1,f_wr_c1_1,f_em_c1_1,f_c1_1_out);

  -- 2nd process (photo-event projection centering)
  process2_a : entity work.process2 port map(clk_k,f_a_out,f_em_a,new_frame,f_rd_req_a,f_sel_a,proc2_state_a,ram_wr_a,ram_adw_a,ram_d_a);
  process2_b : entity work.process2 port map(clk_k,f_b_out,f_em_b,new_frame,f_rd_req_b,f_sel_b,proc2_state_b,ram_wr_b,ram_adw_b,ram_d_b);
  process2_c : entity work.process2 port map(clk_k,f_c_out,f_em_c,new_frame,f_rd_req_c,f_sel_c,proc2_state_c,ram_wr_c,ram_adw_c,ram_d_c);

  -- RAMs between 2nd and 3rd processes
  ram_a_0 : entity work.p23_ram port map(clk_ram,ram_d_a,ram_adr_a,ram_rd_0,ram_adw_a,ram_wr_a_0,ram_q_a_0);
  ram_b_0 : entity work.p23_ram port map(clk_ram,ram_d_b,ram_adr_b,ram_rd_0,ram_adw_b,ram_wr_b_0,ram_q_b_0);
  ram_c_0 : entity work.p23_ram port map(clk_ram,ram_d_c,ram_adr_c,ram_rd_0,ram_adw_c,ram_wr_c_0,ram_q_c_0);
  ram_a_1 : entity work.p23_ram port map(clk_ram,ram_d_a,ram_adr_a,ram_rd_1,ram_adw_a,ram_wr_a_1,ram_q_a_1);
  ram_b_1 : entity work.p23_ram port map(clk_ram,ram_d_b,ram_adr_b,ram_rd_1,ram_adw_b,ram_wr_b_1,ram_q_b_1);
  ram_c_1 : entity work.p23_ram port map(clk_ram,ram_d_c,ram_adr_c,ram_rd_1,ram_adw_c,ram_wr_c_1,ram_q_c_1);

  -- 3rd process (triplet finding), use input clock (instead of clk_j or clk_k) to speed up (x2)  
  process3_abc : entity work.process3 port map(clock,new_frame,d_ram_a,d_ram_b,d_ram_c,ram_rd,ram_adr_a,ram_adr_b,ram_adr_c,a_ph,bmc_ph,val_ph,ovload,sum);
  
  -- interface between FIFOs and 2nd process
  f_rd_demux_a : entity work.f_rd_demux port map(f_rd_req_a,f_sel_a,frame_0,f_rd_a);
  f_rd_demux_b : entity work.f_rd_demux port map(f_rd_req_b,f_sel_b,frame_0,f_rd_b);
  f_rd_demux_c : entity work.f_rd_demux port map(f_rd_req_c,f_sel_c,frame_0,f_rd_c);
  f_rd_mux_a : entity work.f_rd_mux port map(f_all_out_a,f_all_em_a,f_sel_a,frame_0,f_a_out,f_em_a);
  f_rd_mux_b : entity work.f_rd_mux port map(f_all_out_b,f_all_em_b,f_sel_b,frame_0,f_b_out,f_em_b);
  f_rd_mux_c : entity work.f_rd_mux port map(f_all_out_c,f_all_em_c,f_sel_c,frame_0,f_c_out,f_em_c);
  
  -- interface between RAMs and 3rd process
  ram_rd_mux_a : entity work.ram_rd_mux port map(ram_q_a_0,ram_q_a_1,frame_0,d_ram_a);
  ram_rd_mux_b : entity work.ram_rd_mux port map(ram_q_b_0,ram_q_b_1,frame_0,d_ram_b);
  ram_rd_mux_c : entity work.ram_rd_mux port map(ram_q_c_0,ram_q_c_1,frame_0,d_ram_c);

  -- input of Mealy machines (current state grouped with pixel values of even/odd pairs)
  addr_mrom_a0 <= state_a0 & frame_data(11 downto 10);
  addr_mrom_a1 <= state_a1 & frame_data(9 downto 8);
  addr_mrom_b0 <= state_b0 & frame_data(7 downto 6);
  addr_mrom_b1 <= state_b1 & frame_data(5 downto 4);
  addr_mrom_c0 <= state_c0 & frame_data(3 downto 2);
  addr_mrom_c1 <= state_c1 & frame_data(1 downto 0);
  
  -- input of FIFO_12s (= pixel counter grouped with partial output of Mealy machines giving spot edges)
  f_a0_in <= pix_counter(5 downto 0) & d_a0(4 downto 1);
  f_a1_in <= pix_counter(5 downto 0) & d_a1(4 downto 1);
  f_b0_in <= pix_counter(5 downto 0) & d_b0(4 downto 1);
  f_b1_in <= pix_counter(5 downto 0) & d_b1(4 downto 1);
  f_c0_in <= pix_counter(5 downto 0) & d_c0(4 downto 1);
  f_c1_in <= pix_counter(5 downto 0) & d_c1(4 downto 1);
  
  -- write-enable flags of FIFO_12s
  f_wr_a0_0 <= d_a0(0) and frame_0;
  f_wr_a0_1 <= d_a0(0) and frame_1;
  f_wr_a1_0 <= d_a1(0) and frame_0;
  f_wr_a1_1 <= d_a1(0) and frame_1;
  f_wr_b0_0 <= d_b0(0) and frame_0;
  f_wr_b0_1 <= d_b0(0) and frame_1;
  f_wr_b1_0 <= d_b1(0) and frame_0;
  f_wr_b1_1 <= d_b1(0) and frame_1;
  f_wr_c0_0 <= d_c0(0) and frame_0;
  f_wr_c0_1 <= d_c0(0) and frame_1;
  f_wr_c1_0 <= d_c1(0) and frame_0;
  f_wr_c1_1 <= d_c1(0) and frame_1;
  
  -- read-enable flags of FIFO_12s
  f_rd_a0_0 <= f_rd_a(3);
  f_rd_a0_1 <= f_rd_a(1);
  f_rd_a1_0 <= f_rd_a(2);
  f_rd_a1_1 <= f_rd_a(0);
  f_rd_b0_0 <= f_rd_b(3);
  f_rd_b0_1 <= f_rd_b(1);
  f_rd_b1_0 <= f_rd_b(2);
  f_rd_b1_1 <= f_rd_b(0);
  f_rd_c0_0 <= f_rd_c(3);
  f_rd_c0_1 <= f_rd_c(1);
  f_rd_c1_0 <= f_rd_c(2);
  f_rd_c1_1 <= f_rd_c(0);
  
  -- write-enable flags of RAMs
  ram_wr_a_0 <= ram_wr_a and frame_0;
  ram_wr_a_1 <= ram_wr_a and frame_1;
  ram_wr_b_0 <= ram_wr_b and frame_0;
  ram_wr_b_1 <= ram_wr_b and frame_1;
  ram_wr_c_0 <= ram_wr_c and frame_0;
  ram_wr_c_1 <= ram_wr_c and frame_1;
  
  -- read-enable flags of RAMs
  ram_rd_0 <= ram_rd and frame_1;
  ram_rd_1 <= ram_rd and frame_0;
  
  -- clock for RAMs 
  clk_ram <= not clock;
  
  -- grouping of FIFO output before multiplexing at 2nd-process input
  f_all_out_a <= f_a0_0_out & f_a1_0_out & f_a0_1_out & f_a1_1_out;
  f_all_out_b <= f_b0_0_out & f_b1_0_out & f_b0_1_out & f_b1_1_out;
  f_all_out_c <= f_c0_0_out & f_c1_0_out & f_c0_1_out & f_c1_1_out;
  f_all_em_a <= f_em_a0_0 & f_em_a1_0 & f_em_a0_1 & f_em_a1_1;
  f_all_em_b <= f_em_b0_0 & f_em_b1_0 & f_em_b0_1 & f_em_b1_1;
  f_all_em_c <= f_em_c0_0 & f_em_c1_0 & f_em_c0_1 & f_em_c1_1;


  test_out <= ram_d_a & ram_d_b & ram_d_c;
end behavior;