p23_ram_inst : p23_ram PORT MAP (
		clock	 => clock_sig,
		data	 => data_sig,
		rdaddress	 => rdaddress_sig,
		rden	 => rden_sig,
		wraddress	 => wraddress_sig,
		wren	 => wren_sig,
		q	 => q_sig
	);
