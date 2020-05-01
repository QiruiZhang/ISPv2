module testbench;

    localparam FRAMEBASE = 32'hA0411290;
    localparam MEMSUPERS = 4;
    localparam MEMSETS   = 5;
    localparam MEMBANKS  = 4;

	AHB_BUS #(.BUS(32)) slave_bus  (.*);
	AHB_BUS #(.BUS(32)) master_bus (.*);

	/////////////////////////////////////////
	// Set up signals
	logic           HCLK     ; 
	logic           HRESETn  ;
	logic           valid_m2s;
	logic [31   :0] haddr    ;
	logic [2    :0] hsize    ;
	logic [31   :0] hwdata   ;
	logic           ready_m2s;
	logic [31   :0] hrdata   ;
	logic [1    :0] hresp    ;

    /////////////////////////////////////////

	/////////////////////////////////////////
	// ASSERTION
	property write_test;
 	   @(posedge HCLK) disable iff(!HRESETn)
 	   slave_bus.HSEL&slave_bus.HREADY&slave_bus.HWRITE |-> ##[1:$] slave_bus.HREADY&valid_m2s&ready_m2s&&(slave_bus.HWDATA==hwdata);
 	endproperty	
 	   
	property read_test;
 	   @(posedge HCLK) disable iff(!HRESETn) 
 	   slave_bus.HSEL&slave_bus.HREADY&!slave_bus.HWRITE |-> ##[1:30] slave_bus.HREADY&valid_m2s&ready_m2s&&(slave_bus.HRDATA==hrdata);
 	endproperty	

	property addr_test;
	bit [31:0] temp;
 	   @(posedge HCLK) disable iff(!HRESETn) 
 	   (slave_bus.HSEL&slave_bus.HREADY,temp=slave_bus.HADDR) |-> ##[1:30] slave_bus.HREADY&valid_m2s&ready_m2s&(temp==haddr);
 	endproperty	


    /////////////////////////////////////////
    
    logic          o_interrupt;

  `ifndef SYN
    NEURALENGINE_TOP dut(.HCLK(HCLK),
                         .HRESETn(HRESETn),
                         .bus_master(master_bus.MASTER_BLOCK),
                         .bus_slave(slave_bus.SLAVE_BLOCK),
                         .o_interrupt(o_interrupt),
                         .SWRW(1'b0),
                         .ISOL_MBC(1'b0),
                         .Resetn_MBC(1'b1),
                         .SD0_32X32(5'b0),
                         .SD1_32X32(5'b0),
                         .SD2_32X32(6'b0),
                         .SD3_32X32(5'b0),
                         .SD0_128X512(5'b0),
                         .SD1_128X512(5'b0),
                         .SD2_128X512(6'b0),
                         .SD3_128X512(5'b0),
                         .CLK_8M(1'b0)
                       );

  `else
    NEURALENGINE_TOP_svsim dut(.HCLK(HCLK),
                               .HRESETn(HRESETn),
                               .bus_master(master_bus.MASTER_BLOCK),
                               .bus_slave(slave_bus.SLAVE_BLOCK),
                               .o_interrupt(o_interrupt),
                               .SWRW(1'b0),
                               .ISOL_MBC(1'b0),
                               .Resetn_MBC(1'b1),
                               .SD0_32X32(5'b0),
                               .SD1_32X32(5'b0),
                               .SD2_32X32(6'b0),
                               .SD3_32X32(5'b0),
                               .SD0_128X512(5'b0),
                               .SD1_128X512(5'b0),
                               .SD2_128X512(6'b0),
                               .SD3_128X512(5'b0),
                               .CLK_8M(1'b0)
                              );
  `endif

    /////////////////////////////////////////


	task write_ahbslave;
		input [31   :0] addr;
		input [31   :0] data;
		begin
			@(posedge HCLK);#1;
			slave_bus.HSEL    = 1'b1;
			slave_bus.HWRITE  ='b1;
			slave_bus.HADDR   = addr;
			slave_bus.HTRANS  = 2'b10;
			@(posedge HCLK);#1;
			slave_bus.HSEL    = 'b0;
			slave_bus.HWRITE  = 'b0;
			slave_bus.HADDR   = 'b0;
			slave_bus.HWDATA  = 'b0;
			slave_bus.HTRANS  = 'b0;
			slave_bus.HWDATA  = data;
		 end
	endtask

	task read_ahbslave;
		input [31   :0] addr;
		begin
			@(posedge HCLK);#1;
			slave_bus.HSEL    = 1'b1;
			slave_bus.HWRITE  ='b0;
			slave_bus.HADDR   = addr;
			slave_bus.HTRANS  = 2'b10;
            //$display("AHB READ: %b",slave_bus.HRDATA);
			@(posedge HCLK);#1;
			slave_bus.HSEL    = 'b0;
			slave_bus.HWRITE  = 'b0;
			slave_bus.HADDR   = 'b0;
			slave_bus.HWDATA  = 'b0;
			slave_bus.HTRANS  = 'b0;
            //$display("AHB READ: %b",slave_bus.HRDATA);
		 end
	endtask

    task master_response;
        input [31:0] data;
        begin
            @(posedge HCLK);#1;
            master_bus.HREADY = 1'b1;
            master_bus.HRDATA = data;
            master_bus.HRESP  = 'b0;
            @(posedge HCLK);#1;
            master_bus.HREADY = 'b0;
            master_bus.HRDATA = 'b0;
            master_bus.HRESP  = 'b0;
        end
    endtask


    /////////////////////////////////////////


    // fake frame memory
    logic [127:0] image_mem [255:0];

    // fake ncx regfile
    logic [15:0] regfile [23:0];

    // fake instruction mem
    logic [255:0] imem_instr [511:0];

        
    logic [127:0] fakeunified [MEMSUPERS-1:0][MEMSETS-1:0][MEMBANKS-1:0][511:0];
    logic [MEMSUPERS-1:0][MEMSETS-1:0][MEMBANKS-1:0] is_unified_bank_empty;
    logic [MEMSUPERS-1:0][MEMSETS-1:0][MEMBANKS-1:0][511:0] addr_already_written_to;


    event   call_preload_nesram;
    event   call_dump_nesram;
    event   call_check_sram_access;

    integer count;
    integer fd;

    integer ufds [MEMSUPERS-1:0][MEMSETS-1:0][MEMBANKS-1:0];

    integer sram_fd;

    integer found;

    integer realticks;                                    

    initial realticks = 0;
    initial HCLK = 0;
    initial addr_already_written_to = '0;
    always begin
        #1000; // 500 KHz
     	//#2500; // 200 KHz
        //#200;
        HCLK = ~HCLK;
        realticks = realticks+1;
    end


    logic [15:0] uaddr;

    integer fasd;

    task preload_sharedmem;
        begin
            // put into fake variables
            ->call_preload_nesram;

            fasd = $fopen("/z/libra2_nn/full_ne/ahb_sharedmem_inaddr_dump.txt", "w");
            @(posedge HCLK);

            // manually load every single unifiedmem word
            uaddr = 0;
            for(int su=0; su < MEMSUPERS; su++) begin
                for(int se=0; se < MEMSETS; se++) begin
                    for(int ba=0; ba < MEMBANKS; ba++) begin

                        uaddr[12:11] = su;
                        uaddr[15:13] = se;
                        uaddr[10:9]  = ba;

                        $display("writing all 512 for su: %1d, se: %1d, ba: %1d", su,se,ba);

                        for(int wo=0; wo < 512; wo++) begin
                            uaddr[8:0] = wo;

                            if(addr_already_written_to[su][se][ba][wo]) begin
                                $display("\n!!DANGER!! double-writing sharedmem address !!DANGER!!\n");
                            end
                            addr_already_written_to[su][se][ba][wo] = 1'b1;

                            for(count=0; count < 4; count++) begin
                                $fdisplay(fasd, "%X", (32'h00004100 + (uaddr*16) + (count*4)));
                                write_ahbslave(32'h00004100 + (uaddr*16) + (count*4),
                                               fakeunified[su][se][ba][wo][(count*32)+:32]
                                              );
                            end
                        end
                    end
                end
            end

            $fclose(fasd);
        end
    endtask

    integer ff, gg;
    initial begin
      `ifndef SYN
        ff = $fopen("/z/libra2_nn/full_ne/n2w_sharedmem_ADDR_dump.txt", "w");
        gg = $fopen("/z/libra2_nn/full_ne/n2w_sharedmem_i_addr.txt", "w");
      `endif
    end
    always @(posedge HCLK) begin

      `ifndef SYN
        if(dut.u_N2W_SHAREDMEM.MEM_EN && !dut.u_N2W_SHAREDMEM.READ1_WRITE0) begin

            $fdisplay(ff, "%X", dut.u_N2W_SHAREDMEM.ADDR);
            $fdisplay(gg, "%X", dut.u_N2W_SHAREDMEM.i_addr);

        end
      `endif

    end

    task dump_sharedmem;
        begin
            ->call_dump_nesram;
        end
    endtask


    logic [127:0] temppp [511:0];

    string stringg;

    string linel;
   
    logic [7:0] cchar; 

    genvar supi, seti, banki;
    generate
    for(supi=0; supi<MEMSUPERS; supi++) begin : nesram_suploopi
        for(seti=0; seti<MEMSETS; seti++) begin : nesram_setloopi
            for(banki=0; banki<MEMBANKS; banki++) begin : nesram_bankloopi
                always @call_preload_nesram begin
                    for(int iii=0; iii<512; iii++) begin
                        temppp[iii] = 128'h0;
                    end

                    $readmemh($psprintf("/z/libra2_nn/full_ne/unified_sram/in_%1d_%1d_%1d.mem",supi,seti,banki), temppp);
                    $display("loading /z/libra2_nn/full_ne/unified_sram/in_%1d_%1d_%1d.mem",supi,seti,banki);

                    fakeunified[supi][seti][banki] = temppp;
                end
            end
        end
    end
    endgenerate


    genvar supo, seto, banko;
    generate
    for(supo=0; supo<MEMSUPERS; supo++) begin : nesram_suploopo
        for(seto=0; seto<MEMSETS; seto++) begin : nesram_setloopo
            for(banko=0; banko<MEMBANKS; banko++) begin : nesram_bankloopo
                always @call_dump_nesram begin
                  `ifndef SYN
                    dut.u_NE.unified_mem.datastore.supersets[supo].sets[seto].banks[banko].sram.writeMemoryBytes($psprintf("/z/libra2_nn/full_ne/unified_sram/out_%1d_%1d_%1d.mem",supo,seto,banko));
                  `endif
                end
            end
        end
    end
    endgenerate

    genvar supa, seta, banka;
    generate
    for(supa=0; supa<MEMSUPERS; supa++) begin : nesram_suploopa
        for(seta=0; seta<MEMSETS; seta++) begin : nesram_setloopa
            for(banka=0; banka<MEMBANKS; banka++) begin : nesram_bankloopa
                always @call_check_sram_access begin
                  `ifndef SYN
                    if(dut.u_NE.unified_mem.datastore.supersets[supa].sets[seta].banks[banka].sram.CS) begin
                        if(found==0) begin
                            $fdisplay(sram_fd, "\nEdge: %d ==============================================", realticks);
                            found = 1;
                        end
                        if(dut.u_NE.unified_mem.datastore.supersets[supa].sets[seta].banks[banka].sram.R_Wb) begin
                            $fdisplay(sram_fd, "SHARED READ Superset: %1d Set: %1d Bank: %1d Word: %3d",supa,seta,banka,dut.u_NE.unified_mem.datastore.supersets[supa].sets[seta].banks[banka].sram.Addr);
                        end else begin
                            $fdisplay(sram_fd, "SHARED WRITE Superset: %1d Set: %1d Bank: %1d Word: %3d",supa,seta,banka,dut.u_NE.unified_mem.datastore.supersets[supa].sets[seta].banks[banka].sram.Addr);
                        end
                    end
                  `endif
                end
            end
        end
    end
    endgenerate



    task preload_imem;
        begin

            $readmemh("/z/libra2_nn/full_ne/ne_instructions.txt",imem_instr);

            count = 0;
            for(int instn=0; instn < 512; instn++) begin
                for(int subwb=0; subwb < 8; subwb++) begin
                    write_ahbslave(32'h00000100 + count, imem_instr[instn][(subwb*32)+:32]);
                    count += 4;
                end
            end


          `ifndef SYN
            // dump for sanity check
            dut.u_NE.imem.parallel_bank_0.writeMemory("/z/libra2_nn/full_ne/sim_inst_bottom.txt");
            dut.u_NE.imem.parallel_bank_1.writeMemory("/z/libra2_nn/full_ne/sim_inst_top.txt");
          `endif
        end
    endtask

    task preload_ncx_rf;
        begin

            $readmemh("/z/libra2_nn/full_ne/ncx_rf.txt",regfile);


            count = 0;
            for(int r=0; r < 24; r++) begin
                write_ahbslave(32'h0000000C + count, {16'h0000,regfile[r]});
                count += 4;
            end

          `ifndef SYN
            // dump for sanity check
            dut.u_NE.ncx_core.rf.dumpRegs("/z/libra2_nn/full_ne/sim_ncx_rf.txt");
          `endif

        end
    endtask


    task preload_image;
        begin

            $readmemh("/z/libra2_nn/full_ne/macroblocks.mem",image_mem);

        end
    endtask


    task print_decompressed_w;
        input integer w_file;
        begin
      `ifndef SYN
        #1;
        if(|dut.u_NE.pe.w_buffer_write_en) begin
            if(dut.u_NE.pe.w_buffer_write_en[0]) begin
                for(int ochan =0; ochan < 8; ochan++) begin
                    for(int ichan=0; ichan<8; ichan++) begin
                        $fwrite(w_file, "%4d", $signed(dut.u_NE.pe.w_buffer_write_data[0][ochan][ichan]));
                    end
                end
                $fwrite(w_file, "\n");
            end else begin
                for(int ochan=0; ochan<8; ochan++) begin
                    for(int ichan=0; ichan<8; ichan++) begin
                        $fwrite(w_file, "%4d", $signed(dut.u_NE.pe.w_buffer_write_data[1][ochan][ichan]));
                    end
                end
                $fwrite(w_file, "\n");
            end
        end
      `endif
        end
    endtask



    task dump_ncx_rf;
        begin

            fd = $fopen("/z/libra2_nn/full_ne/ncx_rf.dump","w");

            count = 0;
            for(int t=0; t < 24; t++) begin
                read_ahbslave(32'h0000000C + count);
                $fdisplay(fd, "r[%2d]: %d", t, slave_bus.HRDATA);
                count += 4;
            end

            $fclose(fd);

        end
    endtask
        

    integer mcb_line_index;
    integer mcb_chunk;
    initial begin
        mcb_line_index = 0;
        mcb_chunk = 3;
    end

    
    integer do_access_patterns;

    logic [31:0]  temp_hrdata;

    always @(negedge HCLK) begin
      `ifndef SYN
        if(master_bus.HREADY && master_bus.HGRANT && dut.ahbm_valid_s2m) begin
      `else
        if(master_bus.HREADY && master_bus.HGRANT && dut.NEURALENGINE_TOP.ahbm_valid_s2m) begin
      `endif
            if(mcb_line_index < 256) begin 
                temp_hrdata = image_mem[mcb_line_index][(mcb_chunk*32)+:32];
                master_bus.HRDATA[31:24] = temp_hrdata[7:0];
                master_bus.HRDATA[23:16] = temp_hrdata[15:8];
                master_bus.HRDATA[15:8]  = temp_hrdata[23:16];
                master_bus.HRDATA[7:0]   = temp_hrdata[31:24];
            end else begin
                master_bus.HRDATA = 32'hDEADBEEF;
            end
            if(mcb_chunk === 0) begin
                mcb_line_index = mcb_line_index + 1;
                mcb_chunk = 3;
            end else begin
                mcb_chunk = mcb_chunk - 1;
            end
        end


        if(do_access_patterns===1) begin
            found = 0;
            ->call_check_sram_access;
        end
    end



  `ifndef SYN
    always_ff @(negedge HCLK) begin

      if(dut.u_NE.pe.PE_engine.accum_banks_write_en[2] === 1'b1 && dut.u_NE.pe.PE_engine.accum_banks_write_addr[2] === 5'b0) begin
          $fwrite(accum0_fd, "%d + %d = %d\n", $signed(dut.u_NE.pe.PE_engine.SIMD_A[0][2]), $signed(dut.u_NE.pe.PE_engine.SIMD_B[0][2]), $signed(dut.u_NE.pe.PE_engine.accum_banks_write_data[2]));
      end

    end
  `endif





    integer num_cycles;
    integer sim_weight_file;

    integer lm0;
    integer lm1;

    integer conv_cnt, pool_cnt, dfc_cnt, sfc_cnt, mov_cnt, ncx_cnt, relu_cnt, add_cnt, resize_cnt;

    integer accum0_fd;

    initial begin

        do_access_patterns = 0;
        sram_fd = $fopen("/z/libra2_nn/full_ne/shared_sram_access_pattern.txt","w");

        accum0_fd = $fopen("/z/libra2_nn/full_ne/accum0_fd.txt","w");

        $srandom(8675309);
        $display("\nStarting.....\n");

      `ifdef SYN
        //$sdf_annotate("/afs/eecs.umich.edu/vlsida/projects/VC/users/tawesley/CMPv1/synth/NE/latest_output/NEURALENGINE_TOP.sdf", dut.NEURALENGINE_TOP);
        //$dumpfile("/z/libra2_nn/full_ne/fulldump.vcd");
        //$dumpvars(0, dut.NEURALENGINE_TOP);
        $set_gate_level_monitoring("on");
        $set_toggle_region(dut.NEURALENGINE_TOP);
      `endif


	 	HRESETn = 'b0;
	 	HCLK    = 'b0;
	 	slave_bus.HSEL           ='b0;
	 	slave_bus.HADDR          ='b0;
	 	slave_bus.HWRITE         ='b0;
	 	slave_bus.HSIZE          ='b0;
	 	slave_bus.HTRANS         ='b0;
	 	slave_bus.HBURST         ='b0;
	 	slave_bus.HPROT          ='b0;
	 	slave_bus.HWDATA         ='b0;
	 	slave_bus.HMASTER        ='b0;
		master_bus.HREADY        ='b1;
		master_bus.HRDATA        = 32'hDEADBEEF;
		master_bus.HRESP         ='b0;
		master_bus.HGRANT        ='b1;
		master_bus.HMASTLOCK     ='b0;

	 	#15;
	 	@(negedge HCLK);
      `ifdef SYN
        $toggle_start();
      `endif
	 	HRESETn        ='b1;
	 	@(posedge HCLK);
	 	for(int test=0; test<10; test=test+1) begin
	 		count   = ($random%16)+30;
	 	end

        // configure framemem base addr
        write_ahbslave(32'h8, FRAMEBASE);

        // don't disable clk gate yet, but do
        // disable reset
        write_ahbslave(32'h0, 32'h00000010);

        // preload stuff
        preload_imem;
        preload_image;
      `ifdef SYN
        //$dumpoff;
        $toggle_stop();
      `endif
        preload_sharedmem;
      `ifdef SYN
        //$dumpon;
        $toggle_start();
      `endif

        // turn off autogating PE

        // turn off resetn and clock gate
        write_ahbslave(32'h0, 32'h00000011);

        // RF needs clock gate released! 
        preload_ncx_rf;


        // start execution at instruction 0
        write_ahbslave(32'h4, 32'h0);


      `ifndef SYN
        sim_weight_file = $fopen("/z/libra2_nn/full_ne/decompressed_weight_sim.txt", "w");
      `endif

        //// packed so this can be directly sent as 32bit data
        //// ITEMS: instruction, iafifo, w row/col
        //typedef struct packed {
        //    logic [3:0]     instruction_opcode;
        //    logic           instruction_ia_mem_dir_0;
        //    logic           instruction_ia_mem_buffer_0;
        //    logic           instruction_oa_mem_dir;
        //    logic           instruction_oa_mem_buffer;
        //    logic           ia_fifo_index;
        //    logic [1:0]     ia_fifo_status;
        //    logic           ia_fifo_initialized;
        //    logic [3:0]     ia_fifo_ptr;
        //    logic [3:0]     ia_col_pointer;
        //    logic [3:0]     ia_row_pointer;
        //    logic [3:0]     w_col_cnt;
        //    logic [3:0]     w_row_cnt;
        //} pe_status_group1; // total: 32b
        //typedef struct packed {
        //    logic [3:0]     PE_array_w_row;
        //    logic [3:0]     PE_array_w_col;
        //    logic [3:0]     PE_array_ia_row;
        //    logic [3:0]     PE_array_ia_col;
        //    logic [1:0]     shared_read_status;
        //    logic [1:0]     shared_read_status_d;
        //    logic [1:0]     pe_shared_mem_status;
        //    logic [3:0]     local_mem_status;
        //    logic [3:0]     add_valid_inputs;
        //} pe_status_group2; // total: 30b
        //typedef struct packed {
        //    logic [7:0]     write_row;
        //    logic [7:0]     write_col;
        //    logic [11:0]    write_oc;
        //    logic [3:0]     write_padding;
        //} pe_status_group3; // total: 32b 
        //typedef struct packed {
        //    logic [11:0]    instruction_current_ic;
        //    logic [11:0]    instruction_current_oc;
        //} pe_status_group4; // total: 24b
        //typedef struct packed {
        //    logic [7:0]     instruction_ia_row_current;
        //    logic [7:0]     instruction_ia_col_current;
        //    logic [9:0]     instruction_conv_clear_addr;
        //    logic           instruction_conv_clear_finished;
        //    logic           instruction_sparse_fc_clean;
        //    logic           instruction_sparse_fc_process;
        //    logic           instruction_sparse_fc_mov;
        //} pe_status_group5; // total: 30b
        //typedef struct packed {
        //    logic [6:0]     packet_ptr;
        //    logic           packet_end;
        //    logic [4:0]     subtree_num;
        //    logic           w_0_or_idx_1;
        //    logic           packet_0_valid;
        //    logic           packet_1_valid;
        //    logic [7:0]     loc;
        //} decomp_status_group1; // total: 24b
        //typedef struct packed {
        //    logic [7:0]     packet_row;
        //    logic [7:0]     packet_col;
        //    logic [3:0][3:0] processing_bits;
        //} decomp_status_group2; // total: 32b
        //typedef struct {
        //    pe_status_group1       peg1;
        //    pe_status_group2       peg2;
        //    pe_status_group3       peg3;
        //    pe_status_group4       peg4;
        //    pe_status_group5       peg5;
        //    decomp_status_group1   deg1;
        //    decomp_status_group2   deg2;
        //} pe_all_status_structs;
            
        $display("entering loop at sim time: %d\n", $time);
        do_access_patterns = 0;
        conv_cnt=0;
        pool_cnt=0;
        dfc_cnt =0;
        sfc_cnt =0;
        relu_cnt=0;
        mov_cnt =0;
        add_cnt =0;
        resize_cnt=0;
        for(num_cycles = 0; num_cycles < 200000; num_cycles++) begin

            @(negedge HCLK);
            if(num_cycles % 100 == 0) begin
                $display("Cycles: %5d", num_cycles);
            end

            //if(num_cycles == 350) begin
            //    write_ahbslave(32'h00000070, 32'h00000001); // suspend
            //    read_ahbslave(32'h00000088); // NE_PE_STATE_VARS_GROUP5
            //    write_ahbslave(32'h00000074, 32'h00000040); // ++64cycles
            //    read_ahbslave(32'h00000088); // NE_PE_STATE_VARS_GROUP5
            //    write_ahbslave(32'h00000070, 32'h0); // resume
            //end

          `ifndef SYN
            if(dut.u_NE.pe_instruction_finish) begin
                $display("\n> instruction_finish at cycle %8d", num_cycles);

                // +1 cycle to finish writes
                @(negedge HCLK);
                num_cycles++;
                @(negedge HCLK);
                num_cycles++;
   
              `ifdef ENABLE_PERFORMANCE_METRICS
                $write("> it was a");
                case(dut.u_NE.o_metrics.pe_metrics_data.opcode)
                    `PE_CONV_OPCODE: begin
                        $display(" %c[92mCONV%c[0m:",27,27);
                        $display("  w_buffer stall cycles: %5d", dut.u_NE.o_metrics.pe_metrics_data.w_stall_cycles);
                        $display("  instr running cycles:  %5d", dut.u_NE.o_metrics.pe_metrics_data.instr_runtime_cycles);
                        if(conv_cnt < 10) begin
                            lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/conv%1d.cycle_%05d.buf_0", conv_cnt, num_cycles), "w");
                            lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/conv%1d.cycle_%05d.buf_1", conv_cnt, num_cycles), "w");
                        end else begin
                            lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/conv%2d.cycle_%05d.buf_0", conv_cnt, num_cycles), "w");
                            lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/conv%2d.cycle_%05d.buf_1", conv_cnt, num_cycles), "w");
                        end
                        for(int z=0; z < 512; z++) begin
                            $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_1.mem[z]);
                            $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_0.mem[z]);
                            $fwrite(lm0, "\n");
                            $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_1.mem[z]);
                            $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_0.mem[z]);
                            $fwrite(lm1, "\n");
                        end
                        $fclose(lm0);
                        $fclose(lm1);
                        conv_cnt++;
                    end
                    `PE_POOL_OPCODE: begin
                        $display(" %c[94mPOOL%c[0m:",27,27);
                        $display("  w_buffer stall cycles: %5d", dut.u_NE.o_metrics.pe_metrics_data.w_stall_cycles);
                        $display("  instr running cycles:  %5d", dut.u_NE.o_metrics.pe_metrics_data.instr_runtime_cycles);
                        if(pool_cnt < 10) begin
                            lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/pool%1d.cycle_%05d.buf_0", pool_cnt, num_cycles), "w");
                            lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/pool%1d.cycle_%05d.buf_1", pool_cnt, num_cycles), "w");
                        end else begin
                            lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/pool%2d.cycle_%05d.buf_0", pool_cnt, num_cycles), "w");
                            lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/pool%2d.cycle_%05d.buf_1", pool_cnt, num_cycles), "w");
                        end
                        for(int z=0; z < 512; z++) begin
                            $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_1.mem[z]);
                            $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_0.mem[z]);
                            $fwrite(lm0, "\n");
                            $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_1.mem[z]);
                            $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_0.mem[z]);
                            $fwrite(lm1, "\n");
                        end
                        $fclose(lm0);
                        $fclose(lm1);
                        pool_cnt++;
                    end
                    `PE_MOV_OPCODE: begin
                        $display(" %c[93mMOV%c[0m:",27,27);
                        //$display("  w_buffer stall cycles: %5d", dut.u_NE.o_metrics.pe_metrics_data.w_stall_cycles);
                        $display("  instr running cycles:  %5d", dut.u_NE.o_metrics.pe_metrics_data.instr_runtime_cycles);
                        //$display("  dumping localmem to %s", $psprintf("localdumps/buf_[0,1].mov%02d.cycle_%05d", mov_cnt, num_cycles));
                        //lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/buf_0.mov%02d.cycle_%05d", mov_cnt, num_cycles), "w");
                        //lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/buf_1.mov%02d.cycle_%05d", mov_cnt, num_cycles), "w");
                        //for(int z=0; z < 512; z++) begin
                        //    $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_1.mem[z]);
                        //    $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_0.mem[z]);
                        //    $fwrite(lm0, "\n");
                        //    $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_1.mem[z]);
                        //    $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_0.mem[z]);
                        //    $fwrite(lm1, "\n");
                        //end
                        //$fclose(lm0);
                        //$fclose(lm1);
                        mov_cnt++;
                    end
                    `PE_ADD_OPCODE:    $display(" %c[91mADD%c[0m:",27,27);
                    `PE_FC_OPCODE: begin
                        $display(" %c[95mFC%c[0m:",27,27);
                        if(sfc_cnt < 10) begin
                            lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/sfc%1d.cycle_%05d.buf_0", sfc_cnt, num_cycles), "w");
                            lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/sfc%1d.cycle_%05d.buf_1", sfc_cnt, num_cycles), "w");
                        end else begin
                            lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/sfc%2d.cycle_%05d.buf_0", sfc_cnt, num_cycles), "w");
                            lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/sfc%2d.cycle_%05d.buf_1", sfc_cnt, num_cycles), "w");
                        end
                        for(int z=0; z < 512; z++) begin
                            $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_1.mem[z]);
                            $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_0.mem[z]);
                            $fwrite(lm0, "\n");
                            $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_1.mem[z]);
                            $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_0.mem[z]);
                            $fwrite(lm1, "\n");
                        end
                        $fclose(lm0);
                        $fclose(lm1);
                        sfc_cnt++;
                    end
                    `PE_RELU_OPCODE: begin
                        $display(" %c[96mRELU%c[0m:",27,27);
                        $display("  w_buffer stall cycles: %5d", dut.u_NE.o_metrics.pe_metrics_data.w_stall_cycles);
                        $display("  instr running cycles:  %5d", dut.u_NE.o_metrics.pe_metrics_data.instr_runtime_cycles);
                        if(relu_cnt < 10) begin
                            lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/relu%1d.cycle_%05d.buf_0", relu_cnt, num_cycles), "w");
                            lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/relu%1d.cycle_%05d.buf_1", relu_cnt, num_cycles), "w");
                        end else begin
                            lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/relu%2d.cycle_%05d.buf_0", relu_cnt, num_cycles), "w");
                            lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/relu%2d.cycle_%05d.buf_1", relu_cnt, num_cycles), "w");
                        end
                        for(int z=0; z < 512; z++) begin
                            $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_1.mem[z]);
                            $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_0.mem[z]);
                            $fwrite(lm0, "\n");
                            $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_1.mem[z]);
                            $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_0.mem[z]);
                            $fwrite(lm1, "\n");
                        end
                        $fclose(lm0);
                        $fclose(lm1);
                        relu_cnt++;
                    end
                    `PE_RESIZE_OPCODE: $display(" %c[97mRESIZE%c[0m:",27,27);
                    `PE_DFC_OPCODE: begin
                        $display(" %c[91mDFC%c[0m:",27,27);
                        $display("  w_buffer stall cycles: %5d", dut.u_NE.o_metrics.pe_metrics_data.w_stall_cycles);
                        $display("  instr running cycles:  %5d", dut.u_NE.o_metrics.pe_metrics_data.instr_runtime_cycles);
                        if(dfc_cnt < 10) begin
                            lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/dfc%1d.cycle_%05d.buf_0", dfc_cnt, num_cycles), "w");
                            lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/dfc%1d.cycle_%05d.buf_1", dfc_cnt, num_cycles), "w");
                        end else begin
                            lm0 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/dfc%2d.cycle_%05d.buf_0", dfc_cnt, num_cycles), "w");
                            lm1 = $fopen($psprintf("/z/libra2_nn/full_ne/localdumps/dfc%2d.cycle_%05d.buf_1", dfc_cnt, num_cycles), "w");
                        end
                        for(int z=0; z < 512; z++) begin
                            $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_1.mem[z]);
                            $fwrite(lm0,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[0].parallel_bank_0.mem[z]);
                            $fwrite(lm0, "\n");
                            $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_1.mem[z]);
                            $fwrite(lm1,"%0128H", dut.u_NE.pe.PE_engine.local_buffer.local_buffer[1].parallel_bank_0.mem[z]);
                            $fwrite(lm1, "\n");
                        end
                        $fclose(lm0);
                        $fclose(lm1);
                        dfc_cnt++;
                    end
                    default: $display(" %c[91m!!! INVALID !!!%c[0m",27,27);
                endcase



              `endif
            end else if(dut.u_NE.ctrl_instruction_finish) begin
                $display("\n> [HUFF/BIAS] finished at cycle %8d", num_cycles);
            end else if(dut.u_NE.ncx_inst_vector_finished) begin
                $display("\n> %c[96mN%c[91mC%c[92mX%c[0m vector finished at cycle %8d",27,27,27,27,num_cycles);
            end

            print_decompressed_w(sim_weight_file);

          `endif


            if(o_interrupt) begin
              `ifdef SYN
                $toggle_stop();
              `endif
                dump_sharedmem;
                dump_ncx_rf;

                // see that interrupt holds
                @(posedge HCLK);

              `ifndef SYN
                dump_sharedmem;
              `endif
                @(posedge HCLK);
                @(posedge HCLK);
                // clear interrupt
                write_ahbslave(32'h000000FC, 32'h0);
                @(posedge HCLK);
                @(posedge HCLK);

              `ifdef SYN
                $toggle_report("/z/libra2_nn/full_ne/activity.saif", 1.0e-12, dut.NEURALENGINE_TOP);
              `endif
                @(posedge HCLK);
                $display("@@@TOTAL CYCLES: %8d", num_cycles);
                $display("@@@finish -- NE HALT INTERRUPT!\n");
                $fclose(accum0_fd);
                $finish;
            end

        end


        $toggle_stop();
        @(negedge HCLK)
        dump_ncx_rf;
      `ifdef SYN
        $toggle_report("/z/libra2_nn/full_ne/activity.saif", 1.0e-12, dut.NEURALENGINE_TOP);
      `endif
        @(posedge HCLK);
        $display("@@@finish -- %c[31mTIMEOUT REACHED%c[0m\n",27,27);
        $fclose(accum0_fd);
        $finish;

    end

endmodule

