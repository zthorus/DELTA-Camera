p12_fifo_inst : p12_fifo PORT MAP (
		clock	 => clock_sig,
		data	 => data_sig,
		rdreq	 => rdreq_sig,
		wrreq	 => wrreq_sig,
		empty	 => empty_sig,
		q	 => q_sig
	);
