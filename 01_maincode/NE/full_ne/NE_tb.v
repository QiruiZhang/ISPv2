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
    logic           SWRW     ;
    logic           ISOL_MBC ;
    logic           Resetn_MBC;
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

	//assert property (write_test);
	//assert property (read_test );
	//assert property (addr_test );


    /////////////////////////////////////////
    
    logic          o_interrupt;


    logic [4:0]    SD0_32X32;
    logic [4:0]    SD1_32X32;
    logic [5:0]    SD2_32X32;
    logic [4:0]    SD3_32X32;

    logic [4:0]    SD0_128X512;
    logic [4:0]    SD1_128X512;
    logic [5:0]    SD2_128X512;
    logic [4:0]    SD3_128X512;

    logic          CLK_8M;

  `ifndef SYN
    NEURALENGINE_TOP dut(.HCLK(HCLK),
                         .HRESETn(HRESETn),
                         .bus_master(master_bus.MASTER_BLOCK),
                         .bus_slave(slave_bus.SLAVE_BLOCK),
                         .o_interrupt(o_interrupt),
                         .SWRW(SWRW),
                         .ISOL_MBC(ISOL_MBC),
                         .Resetn_MBC(Resetn_MBC),
                         .SD0_32X32(5'b0),
                         .SD1_32X32(5'b0),
                         .SD2_32X32(6'b0),
                         .SD3_32X32(5'b0),
                         .SD0_128X512(5'b0),
                         .SD1_128X512(5'b0),
                         .SD2_128X512(6'b0),
                         .SD3_128X512(5'b0),
                         .CLK_8M(CLK_8M)
                       );

  `else
    NEURALENGINE_TOP_svsim dut(.HCLK(HCLK),
                               .HRESETn(HRESETn),
                               .bus_master(master_bus.MASTER_BLOCK),
                               .bus_slave(slave_bus.SLAVE_BLOCK),
                               .o_interrupt(o_interrupt),
                               .SWRW(SWRW),
                               .ISOL_MBC(ISOL_MBC),
                               .Resetn_MBC(Resetn_MBC),
                               .SD0_32X32(5'b0),
                               .SD1_32X32(5'b0),
                               .SD2_32X32(6'b0),
                               .SD3_32X32(5'b0),
                               .SD0_128X512(5'b0),
                               .SD1_128X512(5'b0),
                               .SD2_128X512(6'b0),
                               .SD3_128X512(5'b0),
                               .CLK_8M(CLK_8M)
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
        //#1000; // 500 KHz
     	//#2500; // 200 KHz
        //#200;
        #992
        HCLK = ~HCLK;
        realticks = realticks+1;
    end

    initial CLK_8M = 0;
    always begin
        #62
        CLK_8M = ~CLK_8M;
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
                  `ifndef NEW_SRAMS
                    dut.u_NE.unified_mem.datastore.supersets[supo].sets[seto].banks[banko].sram.writeMemoryBytes($psprintf("/z/libra2_nn/full_ne/unified_sram/out_%1d_%1d_%1d.mem",supo,seto,banko));
                  `endif
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


  `ifndef SYN
    // local mem and weight buffer mem accesses
    always @call_check_sram_access begin

        #5; // so the shared mems have time to print 'Tick' first

        // LOCAL MEM
        if(dut.u_NE.pe.PE_engine.local_buffer.EN[0]) begin
            if(found==0) begin
                $fdisplay(sram_fd, "\nEdge: %d ==============================================", realticks);
                found = 1;
            end
            if(dut.u_NE.pe.PE_engine.local_buffer.R0W1[0]) begin
                $fdisplay(sram_fd, "LOCAL WRITE Set: 0 Bank: 0 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[0]);
                $fdisplay(sram_fd, "LOCAL WRITE Set: 0 Bank: 1 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[0]);
            end else begin
                $fdisplay(sram_fd, "LOCAL READ Set: 0 Bank: 0 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[0]);
                $fdisplay(sram_fd, "LOCAL READ Set: 0 Bank: 1 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[0]);
            end
        end
        if(dut.u_NE.pe.PE_engine.local_buffer.EN[1]) begin
            if(found==0) begin
                $fdisplay(sram_fd, "\nEdge: %d ==============================================", realticks);
                found = 1;
            end
            if(dut.u_NE.pe.PE_engine.local_buffer.R0W1[1]) begin
                $fdisplay(sram_fd, "LOCAL WRITE Set: 1 Bank: 0 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[1]);
                $fdisplay(sram_fd, "LOCAL WRITE Set: 1 Bank: 1 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[1]);
            end else begin
                $fdisplay(sram_fd, "LOCAL READ Set: 1 Bank: 0 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[1]);
                $fdisplay(sram_fd, "LOCAL READ Set: 1 Bank: 1 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[1]);
            end
        end

        // WEIGHT MEM
        if(dut.u_NE.pe.PE_engine.weight_buffer.EN[0]) begin
            if(found==0) begin
                $fdisplay(sram_fd, "\nEdge: %d ==============================================", realticks);
                found = 1;
            end
            if(dut.u_NE.pe.PE_engine.weight_buffer.R0W1[0]) begin
                $fdisplay(sram_fd, "WEIGHT WRITE Set: 0 Bank: 0 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[0]);
                $fdisplay(sram_fd, "WEIGHT WRITE Set: 0 Bank: 1 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[0]);
            end else begin
                $fdisplay(sram_fd, "WEIGHT READ Set: 0 Bank: 0 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[0]);
                $fdisplay(sram_fd, "WEIGHT READ Set: 0 Bank: 1 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[0]);
            end
        end
        if(dut.u_NE.pe.PE_engine.weight_buffer.EN[1]) begin
            if(found==0) begin
                $fdisplay(sram_fd, "\nEdge: %d ==============================================", realticks);
                found = 1;
            end
            if(dut.u_NE.pe.PE_engine.weight_buffer.R0W1[1]) begin
                $fdisplay(sram_fd, "WEIGHT WRITE Set: 1 Bank: 0 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[1]);
                $fdisplay(sram_fd, "WEIGHT WRITE Set: 1 Bank: 1 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[1]);
            end else begin
                $fdisplay(sram_fd, "WEIGHT READ Set: 1 Bank: 0 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[1]);
                $fdisplay(sram_fd, "WEIGHT READ Set: 1 Bank: 1 Word: %3d", dut.u_NE.pe.PE_engine.local_buffer.ADDR[1]);
            end
        end

        // INSTRUCTION MEM
        if(dut.u_NE.imem.CS) begin
            if(found==0) begin
                $fdisplay(sram_fd, "\nEdge: %d ==============================================", realticks);
                found = 1;
            end
            if(!dut.u_NE.imem.R_Wb) begin
                $fdisplay(sram_fd, "IMEM WRITE Bank: 0 Word: %3d", dut.u_NE.imem.ADDR);
                $fdisplay(sram_fd, "IMEM WRITE Bank: 1 Word: %3d", dut.u_NE.imem.ADDR);
            end else begin
                $fdisplay(sram_fd, "IMEM READ Bank: 0 Word: %3d", dut.u_NE.imem.ADDR);
                $fdisplay(sram_fd, "IMEM READ Bank: 1 Word: %3d", dut.u_NE.imem.ADDR);
            end
        end

        // ACCUMs
        if(|dut.u_NE.pe.PE_engine.accumulators.CS) begin

            if(found==0) begin
                $fdisplay(sram_fd, "\nEdge: %d ==============================================", realticks);
                found = 1;
            end

            for(int yyy=0; yyy < 8; yyy++) begin
                for(int zzz=0; zzz < 8; zzz++) begin
                    if(dut.u_NE.pe.PE_engine.accumulators.CS[yyy][zzz]) begin
                        $fdisplay(sram_fd, "ACCUM xxx Bank: %2d Word: %3d", ((yyy*8)+zzz), dut.u_NE.pe.PE_engine.accumulators.ADDR[yyy][zzz]);
                    end
                end
            end

        end

        


    end
  `endif




    task initialize_custom_srams;
        begin
            // IMEM  
            SWRW = 1;
            write_ahbslave(32'h00000100, 32'hCC33CC33);
            write_ahbslave(32'h00000104, 32'h00000000);
            write_ahbslave(32'h00000108, 32'h00000000);
            write_ahbslave(32'h0000010C, 32'h00000000);
            write_ahbslave(32'h00000110, 32'hCC33CC33);
            write_ahbslave(32'h00000114, 32'h00000000);
            write_ahbslave(32'h00000118, 32'h00000000);
            write_ahbslave(32'h0000011C, 32'h00000000);
            read_ahbslave(32'h00000120);

            @(posedge HCLK);

            // SHAREDMEM
            for(int uu=0; uu < 80; uu=uu+1) begin
                write_ahbslave(32'h00004100 + (uu*8192), 32'hCC33CC33);
                write_ahbslave(32'h00004100 + (uu*8192) + 4, 32'h00000000);
                write_ahbslave(32'h00004100 + (uu*8192) + 8, 32'h00000000);
                write_ahbslave(32'h00004100 + (uu*8192) + 12, 32'h00000000);
                read_ahbslave(32'h00004100 + (uu*8192) + 64); // flush
                @(posedge HCLK);
            end


            // LOCALMEM
            write_ahbslave(32'h000C4100, 32'hCC33CC33); // localmem buf 0
            write_ahbslave(32'h000C4104, 32'h00000000);
            write_ahbslave(32'h000C4108, 32'h00000000);
            write_ahbslave(32'h000C410C, 32'h00000000);
            write_ahbslave(32'h000C4110, 32'h00000000);
            write_ahbslave(32'h000C4114, 32'h00000000);
            write_ahbslave(32'h000C4118, 32'h00000000);
            write_ahbslave(32'h000C411C, 32'h00000000);
            write_ahbslave(32'h000C4120, 32'hCC33CC33);
            write_ahbslave(32'h000C4124, 32'h00000000);
            write_ahbslave(32'h000C4128, 32'h00000000);
            write_ahbslave(32'h000C412C, 32'h00000000);
            write_ahbslave(32'h000C4130, 32'h00000000);
            write_ahbslave(32'h000C4134, 32'h00000000);
            write_ahbslave(32'h000C4138, 32'h00000000);
            write_ahbslave(32'h000C413C, 32'h00000000);
            write_ahbslave(32'h000C8100, 32'hCC33CC33); // localmem buf 1
            write_ahbslave(32'h000C8104, 32'h00000000);
            write_ahbslave(32'h000C8108, 32'h00000000);
            write_ahbslave(32'h000C810C, 32'h00000000);
            write_ahbslave(32'h000C8110, 32'h00000000);
            write_ahbslave(32'h000C8114, 32'h00000000);
            write_ahbslave(32'h000C8118, 32'h00000000);
            write_ahbslave(32'h000C811C, 32'h00000000);
            write_ahbslave(32'h000C8120, 32'hCC33CC33);
            write_ahbslave(32'h000C8124, 32'h00000000);
            write_ahbslave(32'h000C8128, 32'h00000000);
            write_ahbslave(32'h000C812C, 32'h00000000);
            write_ahbslave(32'h000C8130, 32'h00000000);
            write_ahbslave(32'h000C8134, 32'h00000000);
            write_ahbslave(32'h000C8138, 32'h00000000);
            write_ahbslave(32'h000C813C, 32'h00000000);
            read_ahbslave(32'h000C8180);

            @(posedge HCLK);

            // WEIGHTBUF
            write_ahbslave(32'h000CC100, 32'hCC33CC33); // weightbuf buf 0
            write_ahbslave(32'h000CC104, 32'h00000000);
            write_ahbslave(32'h000CC108, 32'h00000000);
            write_ahbslave(32'h000CC10C, 32'h00000000);
            write_ahbslave(32'h000CC110, 32'hCC33CC33);
            write_ahbslave(32'h000CC114, 32'h00000000);
            write_ahbslave(32'h000CC118, 32'h00000000);
            write_ahbslave(32'h000CC11C, 32'h00000000);
            write_ahbslave(32'h000CC120, 32'hCC33CC33);
            write_ahbslave(32'h000CC124, 32'h00000000);
            write_ahbslave(32'h000CC128, 32'h00000000);
            write_ahbslave(32'h000CC12C, 32'h00000000);
            write_ahbslave(32'h000CC130, 32'hCC33CC33);
            write_ahbslave(32'h000CC134, 32'h00000000);
            write_ahbslave(32'h000CC138, 32'h00000000);
            write_ahbslave(32'h000CC13C, 32'h00000000);
            write_ahbslave(32'h000D0100, 32'hCC33CC33); // weightbuf buf 1
            write_ahbslave(32'h000D0104, 32'h00000000);
            write_ahbslave(32'h000D0108, 32'h00000000);
            write_ahbslave(32'h000D010C, 32'h00000000);
            write_ahbslave(32'h000D0110, 32'hCC33CC33);
            write_ahbslave(32'h000D0114, 32'h00000000);
            write_ahbslave(32'h000D0118, 32'h00000000);
            write_ahbslave(32'h000D011C, 32'h00000000);
            write_ahbslave(32'h000D0120, 32'hCC33CC33);
            write_ahbslave(32'h000D0124, 32'h00000000);
            write_ahbslave(32'h000D0128, 32'h00000000);
            write_ahbslave(32'h000D012C, 32'h00000000);
            write_ahbslave(32'h000D0130, 32'hCC33CC33);
            write_ahbslave(32'h000D0134, 32'h00000000);
            write_ahbslave(32'h000D0138, 32'h00000000);
            write_ahbslave(32'h000D013C, 32'h00000000);
            read_ahbslave(32'h000D0180);

            @(posedge HCLK);

            // BIASBUF
            write_ahbslave(32'h000D6100, 32'hCC33CC33);
            write_ahbslave(32'h000D6104, 32'h00000000);
            write_ahbslave(32'h000D6108, 32'h00000000);
            write_ahbslave(32'h000D610C, 32'h00000000);
            read_ahbslave(32'h000D6180);

            @(posedge HCLK);

            // ACCUMs
            for(int uu=0; uu < 2048; uu=uu+32) begin
                write_ahbslave(32'h000D4100 + (uu*4), 32'h00000000); // correct pattern for 32x32 ?
            end

            // extra edge for safety
            @(posedge HCLK);

            SWRW = 0;

            @(posedge HCLK);
            @(posedge HCLK);

            @(negedge HCLK);


        end
    endtask




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
          `ifndef NEW_SRAMS
            // dump for sanity check
            dut.u_NE.imem.parallel_bank_0.writeMemory("/z/libra2_nn/full_ne/sim_inst_bottom.txt");
            dut.u_NE.imem.parallel_bank_1.writeMemory("/z/libra2_nn/full_ne/sim_inst_top.txt");
          `endif
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
    integer times_mults_active;
    initial begin
        mcb_line_index = 0;
        mcb_chunk = 3;
    end

    
    integer do_access_patterns;

    logic [31:0]  temp_hrdata;

    always @(negedge HCLK) begin

        #700;

      `ifndef SYN

        if(dut.u_NE.pe.PE_engine.instruction.opcode == 0 && dut.u_NE.pe.PE_engine.instruction.valid == 1 && dut.u_NE.pe.PE_engine.start_process == 1) begin
            if(|dut.u_NE.pe.PE_engine.actual_pe_array_mult_en) begin
                times_mults_active++;
            end
        end

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
    always @(negedge HCLK) begin

      #700;

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

        times_mults_active = 0;
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
        ISOL_MBC = 1;
        SWRW = 0;
        Resetn_MBC = 0;
        SD0_32X32 = 0;
        SD1_32X32 = 0;
        SD2_32X32 = 0;
        SD3_32X32 = 0;

        SD0_128X512 = 0;
        SD1_128X512 = 0;
        SD2_128X512 = 0;
        SD3_128X512 = 0;

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
      `ifdef SYN
        $toggle_stop();
      `endif
	 	for(int test=0; test<4; test=test+1) begin
            @(posedge HCLK);
	 	end


        // configure framemem base addr
        write_ahbslave(32'h8, FRAMEBASE);

        // turn off resetn and clock gate
        write_ahbslave(32'h0, 32'h00000011);

        @(negedge HCLK);


        // boot up srams
        Resetn_MBC = 1;
        @(negedge HCLK);
        ISOL_MBC = 0;
        initialize_custom_srams;

        // preload stuff
        preload_imem;
        preload_image;

        preload_sharedmem;


        // turn off autogating PE
        //write_ahbslave(32'h6C, 32'h0);

        // RF needs clock gate released! 
        preload_ncx_rf;


        // start execution at instruction 0
        write_ahbslave(32'h4, 32'h0);


      `ifndef SYN
        sim_weight_file = $fopen("/z/libra2_nn/full_ne/decompressed_weight_sim.txt", "w");
      `endif

            
        $display("entering loop at sim time: %d\n", $time);
      `ifdef SYN
        $toggle_start();
      `endif
        do_access_patterns = 0;
        times_mults_active = 0;
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

            #700;

            if(num_cycles % 100 == 0) begin
                $display("Cycles: %5d", num_cycles);
            end

            // test stop, read, resume at cycle 300
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
                #700;

              `ifdef ENABLE_PERFORMANCE_METRICS
                $write("> it was a");
                case(dut.u_NE.o_metrics.pe_metrics_data.opcode)
                    `PE_CONV_OPCODE: begin
                        $display(" %c[92mCONV%c[0m:",27,27);
                        $display("  w_buffer stall cycles:   %5d", dut.u_NE.o_metrics.pe_metrics_data.w_stall_cycles);
                        $display("  instr running cycles:    %5d", dut.u_NE.o_metrics.pe_metrics_data.instr_runtime_cycles);
                        $display("  MAC array active cycles: %5d", times_mults_active);
                      `ifndef NEW_SRAMS
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
                      `endif
                        times_mults_active = 0;
                        conv_cnt++;
                        do_access_patterns = 0;
                    end
                    `PE_POOL_OPCODE: begin
                        $display(" %c[94mPOOL%c[0m:",27,27);
                        $display("  w_buffer stall cycles: %5d", dut.u_NE.o_metrics.pe_metrics_data.w_stall_cycles);
                        $display("  instr running cycles:  %5d", dut.u_NE.o_metrics.pe_metrics_data.instr_runtime_cycles);
                      `ifndef NEW_SRAMS
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
                      `endif
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
                        //dump_sharedmem;
                        //@(posedge HCLK);
                        //$finish;
                        mov_cnt++;
                        do_access_patterns = 1;
                    end
                    `PE_ADD_OPCODE:    $display(" %c[91mADD%c[0m:",27,27);
                    `PE_FC_OPCODE: begin
                        $display(" %c[95mFC%c[0m:",27,27);
                      `ifndef NEW_SRAMS
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
                      `endif
                        sfc_cnt++;
                    end
                    `PE_RELU_OPCODE: begin
                        $display(" %c[96mRELU%c[0m:",27,27);
                        $display("  w_buffer stall cycles: %5d", dut.u_NE.o_metrics.pe_metrics_data.w_stall_cycles);
                        $display("  instr running cycles:  %5d", dut.u_NE.o_metrics.pe_metrics_data.instr_runtime_cycles);
                      `ifndef NEW_SRAMS
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
                      `endif
                        relu_cnt++;
                    end
                    `PE_RESIZE_OPCODE: $display(" %c[97mRESIZE%c[0m:",27,27);
                    `PE_DFC_OPCODE: begin
                        $display(" %c[91mDFC%c[0m:",27,27);
                        $display("  w_buffer stall cycles: %5d", dut.u_NE.o_metrics.pe_metrics_data.w_stall_cycles);
                        $display("  instr running cycles:  %5d", dut.u_NE.o_metrics.pe_metrics_data.instr_runtime_cycles);
                      `ifndef NEW_SRAMS
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
                      `endif
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
                $display("\nTimes mults active: %d\n", times_mults_active);
                $display("@@@TOTAL CYCLES: %8d", num_cycles);
                $display("@@@finish -- NE HALT INTERRUPT!\n");
                $fclose(accum0_fd);
                $finish;
            end

        end


        $toggle_stop();
        @(negedge HCLK)
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

