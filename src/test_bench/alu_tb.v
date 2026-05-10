`timescale 1ns/1ps
`include "verify_1.v"
`include "ref_model.v"

// ALU_TESTBENCH

module alu_tb;

parameter WIDTH = 8, CMD_WIDTH = 4;
reg f;

////SIGNALS

	reg [WIDTH-1:0] OPA, OPB;
	reg CLK, RST, CE, CIN, MODE;
	reg [CMD_WIDTH-1:0] CMD;
	reg [1:0] INP_VALID;

	wire [(2*WIDTH)-1:0] RES_D, RES_R;
	wire E_D, E_R;
	wire G_D, G_R;
	wire L_D, L_R;
	wire COUT_D, COUT_R;
	wire OFLOW_D, OFLOW_R;
	wire ERR_D, ERR_R;

	integer pass_count = 0;
	integer fail_count = 0;
	integer test_count = 0;
	integer i;

/////////////////////


// INSTANTIATION ////

	ALU_DESIGN  #(WIDTH)dut(
		.OPA(OPA),.OPB(OPB),.CLK(CLK),.RST(RST),.CE(CE),.CIN(CIN),
		.MODE(MODE),.INP_VALID(INP_VALID),.CMD(CMD),
		.RES(RES_D),.E(E_D),.G(G_D),.L(L_D),.COUT(COUT_D),.OFLOW(OFLOW_D),.ERR(ERR_D)
	);

	ref_model  #(WIDTH,CMD_WIDTH) reff(
		.CLK(CLK),.RST(RST),.CE(CE),.MODE(MODE),.CIN(CIN),.OPA(OPA),.OPB(OPB),.CMD(CMD),.INP_VALID(INP_VALID),
		.RES(RES_R),.COUT(COUT_R),.E(E_R),.G(G_R),.L(L_R),.ERR(ERR_R),.OFLOW(OFLOW_R)
	);

/////////////////////

/// CLOCK GENERATION

	initial begin
		CLK = 0;
		forever #5 CLK = ~CLK;
	end

//////////////////////

/////// APPLY TASK

	task apply_test(
		input [WIDTH-1:0] a,b,
		input [1:0] inp,
		input mode,cin,ce,
		input [CMD_WIDTH-1:0] cmd,
		input [80*8:1] test_name
	);
		begin
			@(posedge CLK);
			OPA = a;
			OPB = b;
			INP_VALID = inp;
			MODE = mode;
			CIN = cin;
			CE = ce;
			CMD = cmd;

			@(posedge CLK);	
			@(posedge CLK);	
			test_count = test_count + 1;

			if(compare_outputs(COUT_D, COUT_R)) begin
				$display("[PASS] %s: OPA=0x%h OPB=0x%h INP_VALID=0x%h MODE=0x%h CIN=0x%h CE=0x%h CMD=0x%h",test_name,a,b,inp,mode,cin,ce,cmd);
				pass_count = pass_count + 1;
				display_mismatch();
			end
			else begin
				$display("[FAIL] %s: OPA=0x%h OPB=0x%h INP_VALID=0x%h MODE=0x%h CIN=0x%h CE=0x%h CMD=0x%h",test_name,a,b,inp,mode,cin,ce,cmd);
				fail_count = fail_count + 1;
				display_mismatch();

			end
		end
	endtask
///////////////////////////

// MULTIPLICATION APPLY TASK
	   task apply_test_mul(
        input [WIDTH-1:0] a, b,
	input [1:0] inp,
	input mode,cin,ce,
        input [CMD_WIDTH-1:0] cmd,
        input [80*8:1] test_name
    );
        begin
            @(posedge CLK);
	    OPA = a;
	    OPB = b;
	    INP_VALID = inp;
   	    MODE = mode;
	    CIN = cin;
	    CE = ce;
	    CMD = cmd;

	    f = 0;
            @(posedge CLK);
            @(posedge CLK);
            if(RES_D!=={(2*WIDTH){1'bx}}) begin
                 f=1;
                 test_count = test_count + 1;
		 $display("[FAIL] %s: OPA=0x%h OPB=0x%h INP_VALID=0x%h MODE=0x%h CIN=0x%h CE=0x%h CMD=0x%h",test_name,a,b,inp,mode,cin,ce,cmd);
                 fail_count = fail_count + 1;
                 display_mismatch();
            end else begin
            @(posedge CLK);
            @(posedge CLK);
            test_count = test_count + 1;
                if (f==0) begin
                    if (compare_outputs(COUT_D, COUT_R)) begin
		 	$display("[PASS] %s: OPA=0x%h OPB=0x%h INP_VALID=0x%h MODE=0x%h CIN=0x%h CE=0x%h CMD=0x%h",test_name,a,b,inp,mode,cin,ce,cmd);
                        pass_count = pass_count + 1;
                        display_mismatch();
                    end else begin
		 	$display("[FAIL] %s: OPA=0x%h OPB=0x%h INP_VALID=0x%h MODE=0x%h CIN=0x%h CE=0x%h CMD=0x%h",test_name,a,b,inp,mode,cin,ce,cmd);
                        display_mismatch();
                        fail_count = fail_count + 1;
                    end
                end
            end
        end
    endtask

//////////////////////////////////
/////ARITHMETIC TEST

	task test_arithmetic();
		begin 
			//DIRECT CASES
			
			apply_test(8'd23,8'd12,3,1,0,1,0,"ADD");
			apply_test(8'd23,8'd12,3,1,0,1,1,"SUB");
			apply_test(8'd23,8'd12,3,1,0,1,2,"ADD CIN 0");
			apply_test(8'd23,8'd12,3,1,1,1,2,"ADD CIN 1");
			apply_test(8'd23,8'd12,3,1,0,1,3,"SUB CIN 0");
			apply_test(8'd23,8'd12,3,1,1,1,3,"SUB CIN 1");
			apply_test(8'd23,8'd12,3,1,0,1,4,"INC A");
			apply_test(8'd23,8'd12,3,1,0,1,5,"DEC A");
			apply_test(8'd23,8'd12,3,1,0,1,6,"INC B");
			apply_test(8'd23,8'd12,3,1,0,1,7,"DEC B");
			apply_test(8'd23,8'd12,3,1,0,1,8,"CMP G");
			apply_test(8'd23,8'd23,3,1,0,1,8,"CMP E");
			apply_test(8'd23,8'd24,3,1,0,1,8,"CMP L");
			apply_test_mul(8'd23,8'd12,3,1,0,1,9,"MUL ADD");
			//apply_test_mul(8'd50,8'd225,3,1,0,1,9,"MUL ADD");
			//apply_test_mul(8'd254,8'd0,3,1,0,1,9,"MUL ADD");
			apply_test_mul(8'd23,8'd12,3,1,0,1,10,"MUL SHIFT");
			//apply_test_mul(8'd127,8'd255,3,1,0,1,10,"MUL SUB");
			//apply_test_mul(8'd31,8'd31,3,1,0,1,10,"MUL SUB");
			//apply_test_mul(8'd128,8'd1,3,1,0,1,10,"MUL SHIFT");
			//apply_test_mul(8'd31,8'd2,3,1,0,1,10,"MUL SHIFT");
			apply_test(8'd23,8'd1,3,1,0,1,11,"SIGNED ADD");
			apply_test(8'd23,8'd1,3,1,0,1,12,"SIGNED SUB");
			apply_test(8'd23,8'd12,3,1,0,0,12,"SIGNED SUB CE(It should latch)");

			/*for(i=0;i<13;i = i + 1) begin
				apply_test(8'd23,8'd12,0,1,0,1,i,"INP INVALID");
				apply_test(8'd23,8'd12,1,1,0,1,i,"INP INVALID");
				apply_test(8'd23,8'd12,2,1,0,1,i,"INP INVALID");
			end
			*/

			/*apply_test(4'd9,4'd3,3,1,0,1,0,"ADD");
			apply_test(4'd9,4'd3,3,1,0,1,1,"SUB");
			apply_test(4'd9,4'd3,3,1,0,1,2,"ADD CIN 0");
			apply_test(4'd9,4'd3,3,1,1,1,2,"ADD CIN 1");
			apply_test(4'd9,4'd3,3,1,0,1,3,"SUB CIN 0");
			apply_test(4'd9,4'd3,3,1,1,1,3,"SUB CIN 1");
			apply_test(4'd9,4'd3,3,1,0,1,4,"INC A");
			apply_test(4'd9,4'd3,3,1,0,1,5,"DEC A");
			apply_test(4'd9,4'd3,3,1,0,1,6,"INC B");
			apply_test(4'd9,4'd3,3,1,0,1,7,"DEC B");
			apply_test(4'd9,4'd3,3,1,0,1,8,"CMP G");
			apply_test(4'd9,4'd9,3,1,0,1,8,"CMP E");
			apply_test(4'd9,4'd10,3,1,0,1,8,"CMP L");
			apply_test(4'd9,4'd3,3,1,0,1,11,"SIGNED ADD");
			apply_test(4'd9,4'd3,3,1,0,1,12,"SIGNED SUB");
			apply_test(4'd9,4'd3,3,1,0,0,7,"DEC B CE(It should latch)");
			*/
			
			//CORNER CASES
			
			apply_test(8'd255,8'd1,3,1,0,1,0,"ADD CORNER");
			apply_test(8'd0,8'd1,3,1,0,1,1,"SUB CORNER");
			apply_test(8'd255,8'd255,3,1,0,1,2,"ADD CIN 0 CORNER");
			apply_test(8'd255,8'd255,3,1,0,1,2,"ADD CIN 1 CORNER");
			apply_test(8'd1,8'd1,3,1,0,1,3,"SUB CIN 0 CORNER");
			apply_test(8'd1,8'd1,3,1,0,1,3,"SUB CIN 1 CORNER");
			apply_test(8'd255,8'd12,3,1,0,1,4,"INC A CORNER");
			apply_test(8'd0,8'd12,3,1,0,1,5,"DEC A CORNER");
			apply_test(8'd23,8'd255,3,1,0,1,6,"INC B CORNER");
			apply_test(8'd23,8'd0,3,1,0,1,7,"DEC B CORNER");
			apply_test(8'd127,8'd1,3,1,0,1,11,"SIGNED ADD CORNER");
			apply_test(8'd0,8'd1,3,1,0,1,12,"SIGNED SUB CORNER");
			apply_test(8'd128,8'd1,3,1,0,1,12,"SIGNED SUB CORNER");
			apply_test(8'd23,8'd255,3,1,0,1,11,"SIGNED ADD CORNER POS NEG");
			apply_test(8'd130,8'd0,3,1,0,1,11,"SIGNED ADD CORNER NEG POS");

			//ERROR CASES
			
			apply_test(8'd23,8'd12,3,1,0,1,14,"INVALID CMD ARITHMETIC");
			apply_test(8'd23,8'd12,0,1,0,1,0,"INVALID INP_VALID (0)");
			apply_test(8'd23,8'd12,1,1,0,1,0,"INVALID INP_VALID (1)");
			apply_test(8'd23,8'd12,2,1,0,1,0,"INVALID INP_VALID (2)");
			apply_test(8'd23,8'd12,1,1,0,1,4,"INVALID INP_VALID (SHOULD BE VALID)");
		end
	endtask

/////////////////////

//LOGICAL FUNCTION

	task test_logical();
		begin 
			//DIRECT CASES
			
			apply_test(8'hF0,8'h0f,3,0,0,1,0,"AND");
			apply_test(8'hF0,8'h0f,3,0,0,1,1,"NAND");
			apply_test(8'hF0,8'h0f,3,0,0,1,2,"OR");
			apply_test(8'hF0,8'h0f,3,0,1,1,3,"NOR");
			apply_test(8'hF0,8'h0f,3,0,0,1,4,"XOR");
			apply_test(8'hF0,8'h0f,3,0,1,1,5,"XNOR");
			apply_test(8'hF0,8'h0f,3,0,0,1,6,"NOT A");
			apply_test(8'hf0,8'h0f,3,0,0,1,7,"NOT B");
			apply_test(8'hf0,8'h0f,3,0,0,1,8,"SHIFT RIGHT A");
			apply_test(8'hf0,8'h0f,3,0,0,1,9,"SHIFT LEFT A");
			apply_test(8'hf0,8'h0f,3,0,0,1,10,"SHIFT RIGHT B");
			apply_test(8'hf0,8'h0f,3,0,0,1,11,"SHIFT LEFT B");
			apply_test(8'hf0,8'h07,3,0,0,1,12,"ROTATE RIGHT");
			apply_test(8'hf0,8'h07,3,0,0,1,13,"ROTATE LEFT");
			apply_test(8'hf0,8'h0f,3,0,0,1,12,"ROTATE RIGHT");
			apply_test(8'hf0,8'h0f,3,0,0,1,13,"ROTATE LEFT");

			/*for(i=0;i<14;i = i + 1) begin
				apply_test(8'd23,8'd12,0,0,0,1,i,"INP INVALID");
				apply_test(8'd23,8'd12,1,0,0,1,i,"INP INVALID");
				apply_test(8'd23,8'd12,2,0,0,1,i,"INP INVALID");
			end
			*/
			/*apply_test(8'h0,8'hf,3,0,0,1,0,"AND");
			apply_test(8'h0,8'hf,3,0,0,1,1,"NAND");
			apply_test(8'h0,8'hf,3,0,0,1,2,"OR");
			apply_test(8'h0,8'hf,3,0,1,1,3,"NOR");
			apply_test(8'h0,8'hf,3,0,0,1,4,"XOR");
			apply_test(8'h0,8'hf,3,0,1,1,5,"XNOR");
			apply_test(8'h0,8'hf,3,0,0,1,6,"NOT A");
			apply_test(8'h0,8'hf,3,0,0,1,7,"NOT B");
			apply_test(8'h0,8'hf,3,0,0,1,8,"SHIFT RIGHT A");
			apply_test(8'h0,8'hf,3,0,0,1,9,"SHIFT LEFT A");
			apply_test(8'h0,8'hf,3,0,0,1,10,"SHIFT RIGHT B");
			apply_test(8'h0,8'hf,3,0,0,1,11,"SHIFT LEFT B");
			apply_test(8'h6,8'h6,3,0,0,1,12,"ROTATE RIGHT");
			apply_test(8'h6,8'h6,3,0,0,1,13,"ROTATE LEFT");
			apply_test(8'h6,8'he,3,0,0,1,13,"ERROR: UPPER BIT 1 ROTATE LEFT");
			*/

			//ERROR CASES
			
			apply_test(8'hf0,8'h0f,3,0,0,1,14,"INVALID CMD LOGICAL");
			apply_test(8'hf0,8'h1f,3,0,0,1,13,"UPPER BITS 1");
		end
	endtask


//////////////////////////



////// COMPARISION FUNCTION

	function compare_outputs(input COUT_D, COUT_R);
		begin
			compare_outputs = 1;
			if(RES_D !== RES_R) compare_outputs = 0;
			if(COUT_D != COUT_R) compare_outputs = 0;
			if(OFLOW_D != OFLOW_R) compare_outputs = 0;
			if(ERR_D != ERR_R) compare_outputs = 0;
			if(E_D != E_R) compare_outputs = 0;
			if(G_D != G_R) compare_outputs = 0;
			if(L_D != L_R) compare_outputs = 0;
		end
	endfunction
////////////////////////

/// DISPLAY MISMATCH

	task display_mismatch();
		begin
			$display("DUT: RES=0x%h COUT=0x%h OFLOW=0x%h ERR=0x%h E=0x%h G=0x%h L=0x%h", RES_D,COUT_D,OFLOW_D,ERR_D,E_D,G_D,L_D);
			$display("REF: RES=0x%h COUT=0x%h OFLOW=0x%h ERR=0x%h E=0x%h G=0x%h L=0x%h", RES_R,COUT_R,OFLOW_R,ERR_R,E_R,G_R,L_R);
		end
	endtask
///////////////////////////




////// TEST STIMULUS

	initial begin
		RST = 1; CE = 1; CIN = 0; MODE = 1; OPA = 0; OPB = 0; INP_VALID = 3;
		CMD = 0;

		@(posedge CLK);
		RST = 0;
		@(posedge CLK);

		$display("\n TESTING ARITHMETIC OPERATIONS");
		test_arithmetic();

		@(posedge CLK);
		RST = 1;
		@(posedge CLK);
		@(posedge CLK);
		display_mismatch();
		@(posedge CLK);
		RST = 0;
		@(posedge CLK);

		$display("\n TESTING LOGICAL OPERATIONS");
		test_logical();

		$display("TEST SUMMARY");
		$display("Total Tests: %0d", test_count);
		$display("PASS: %0d", pass_count);
		$display("FAIL: %0d", fail_count);
		#2000$finish;
	end



/////////////////
endmodule
