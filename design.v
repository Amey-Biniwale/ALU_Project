module top#(parameter WIDTH = 8, CMD_WIDTH = 4)(
        input CLK, RST, CIN, CE, MODE,
        input [WIDTH-1:0] OPA, OPB,
        input [CMD_WIDTH-1:0] CMD,
        input [1:0] INP_VALID,
        output reg [(2*WIDTH)-1:0] RES,
        output reg OFLOW, COUT, E, G, L, ERR
);
        reg COUNT_9,COUNT_10;
        reg OFLOW_M,COUT_M,E_M,G_M,L_M,ERR_M;
        reg [(2*WIDTH)-1:0] RES_M;
        reg [CMD_WIDTH-1:0] PREV_CMD;
        reg [(2*WIDTH)-1:0] WAIT_RES_9,WAIT_RES_10;
        reg [(2*WIDTH)-1:0] TEMP_ADD,TEMP_SUB;

        always @(OPA or OPB) begin
                TEMP_ADD = $signed(OPA) + $signed(OPB);
                TEMP_SUB = $signed(OPA) - $signed(OPB);
        end

        always @(posedge CLK or posedge RST) begin
                if(RST) begin
                        PREV_CMD <= 0;
                end
                else begin
                        PREV_CMD <= CMD;
                end
        end

        always @(posedge CLK or posedge RST) begin
                if(RST) begin
                        COUNT_9 <= 0;
                end
                else if(MODE ==  1 && (CMD==9) ) begin
                        COUNT_9 <= COUNT_9 + 1;
                end
                else if(MODE == 1 && (CMD == 9 && PREV_CMD != 9))begin
                        COUNT_9 <= 0;
                end
        end
        
        always @(posedge CLK or posedge RST) begin
                if(RST) begin
                        COUNT_10 <= 0;
                end
                else if(MODE ==  1 && (CMD==10) ) begin
                        COUNT_10 <= COUNT_10 + 1;
                end
                else if(MODE == 1 && (CMD == 10 && PREV_CMD != 10))begin
                        COUNT_10 <= 0;
                end
        end

        always @(posedge CLK or posedge RST) begin
                RES_M <= 0; OFLOW_M <= 0; COUT_M <= 0; E_M <= 0; G_M <= 0; L_M <= 0; ERR_M <= 0;
                RES <= 0; OFLOW <= 0; COUT <= 0; E <= 0; G <= 0; L <= 0; ERR <= 0;
                if(RST) begin //RESETS ALL OUTPUTS TO 0
                        RES   <= 0; RES_M <= 0;
                        OFLOW <= 0; OFLOW_M <= 0;
                        COUT  <= 0; COUT_M <= 0;
                        E     <= 0; E_M <= 0;
                        G     <= 0; G_M <= 0;
                        L     <= 0; L_M <= 0;
                        ERR   <= 0; ERR_M <= 0;
                end
                else if(CE) begin
                        if(MODE) begin
                                case(CMD)
                                        0: begin //ADD
                                                if(INP_VALID == 3) begin
                                                        {COUT_M,RES_M[WIDTH-1:0]} <= OPA + OPB;
                                                        RES_M <= OPA + OPB;
                                                end
                                                else ERR_M <= 1;
                                        end
                                        1: begin //SUB
                                                if(INP_VALID == 3) begin
                                                        OFLOW_M <= OPA < OPB;
                                                        RES_M <= OPA - OPB;
                                                end
                                                else ERR_M <= 1;
                                        end
                                        2: begin //ADD_CIN
                                                if(INP_VALID == 3) begin
                                                        {COUT_M, RES_M[WIDTH-1:0]} <= OPA + OPB + CIN;
                                                        RES_M <= OPA + OPB + CIN;
                                                end
                                        end
                                        3: begin //SUB_CIN
                                                if(INP_VALID == 3) begin
                                                        OFLOW_M <= OPA <= OPB;
                                                        RES_M <= OPA - OPB - 1;
                                                end
                                                else ERR_M <= 1;
                                        end
                                        4: begin //INC_A
                                                if(INP_VALID[0]) RES_M[WIDTH-1:0] <= OPA + 1;
                                                else ERR_M <= 0;
                                        end
                                        5: begin //DEC_A
                                                if(INP_VALID[0]) RES_M[WIDTH-1:0] <= OPA - 1;
                                                else ERR_M <= 1;
                                        end
                                        6: begin //INC_B
                                                if(INP_VALID[1]) RES_M[WIDTH-1:0] <= OPB + 1;
                                                else ERR_M <= 1;
                                        end
                                        7: begin //DEC_B
                                                if(INP_VALID[1]) RES_M[WIDTH-1:0] <= OPB - 1;
                                                else ERR_M <= 1;
                                        end
                                        8: begin //CMP
                                                if(INP_VALID == 3) begin
                                                        E_M <= OPA == OPB;
                                                        G_M <= OPA > OPB;
                                                        L_M <= OPA < OPB;
                                                end
                                                else ERR_M <= 1;
                                        end
                                        9: begin //MUL_INC
                                                if(INP_VALID == 3) begin
                                                        if(COUNT_9 == 0) begin
                                                                WAIT_RES_9 <= (OPA + 1) * (OPB + 1);
                                                                RES_M <= {2*WIDTH{1'bx}};
                                                        end
                                                        else if(COUNT_9 == 1) begin
                                                                RES_M <= WAIT_RES_9;
                                                        end
                                                end
                                        end
                                        10: begin //MUL_SHI 
                                                if(INP_VALID == 3) begin
                                                        if(COUNT_10 == 0) begin
                                                                WAIT_RES_10 <= (OPA << 1) * (OPB);
                                                                RES_M <= {2*WIDTH{1'bx}};
                                                        end
                                                        else if(COUNT_10 == 1) begin
                                                                RES_M <= WAIT_RES_10;
                                                        end
                                                end
                                        end
                                        11: begin //SIGNED_ADD 
                                                if(INP_VALID == 3) begin
                                                        RES_M <= $signed(OPA) + $signed(OPB);
                                                        OFLOW_M <= (OPA[WIDTH-1] == OPB[WIDTH-1]) && (TEMP_ADD[WIDTH-1] != OPA[WIDTH-1]);
                                                end
                                                else ERR_M <= 1;
                                        end
                                        12: begin //SIGNED_SUB 
                                                if(INP_VALID == 3) begin
                                                        RES_M <= $signed(OPA) - $signed(OPB);
                                                        OFLOW_M <= (OPA[WIDTH-1] != OPB[WIDTH-1]) && (TEMP_SUB[WIDTH-1] != OPA[WIDTH-1]);
                                                end
                                                else ERR_M <= 1;
                                        end
                                        default : ERR_M <= 1;
                                endcase
                        end

                        else begin
                                case(CMD)
                                        0: begin //AND
                                                if(INP_VALID == 3) RES_M[WIDTH-1:0] <= OPA & OPB;
                                                else ERR_M <= 1;
                                        end
                                        1: begin //NAND
                                                if(INP_VALID == 3) RES_M[WIDTH-1:0] <= ~(OPA & OPB);
                                                else ERR_M <= 1;
                                        end
                                        2: begin //OR
                                                if(INP_VALID == 3) RES_M[WIDTH-1:0] <= OPA | OPB;
                                                else ERR_M <= 1;
                                        end
                                        3: begin //NOR
                                                if(INP_VALID == 3) RES_M[WIDTH-1:0] <= ~(OPA | OPB);
                                                else ERR_M <= 1;
                                        end
                                        4: begin //XOR
                                                if(INP_VALID == 3) RES_M[WIDTH-1:0] <= OPA ^ OPB;
                                                else ERR_M <= 1;
                                        end
                                        5: begin //XNOR
                                                if(INP_VALID == 3) RES_M[WIDTH-1:0] <= ~(OPA ^ OPB);
                                                else ERR_M <= 1;
                                        end
                                        6: begin //NOT_A
                                                if(INP_VALID[0]) RES_M[WIDTH-1:0] <=  ~OPA;
                                                else ERR_M <= 1;
                                        end
                                        7: begin//NOT_B
                                                if(INP_VALID[1]) RES_M[WIDTH-1:0] <= ~OPB;
                                                else ERR_M <= 1;
                                        end
                                        8: begin //A_SHIFT_RIGHT
                                                if(INP_VALID[0]) RES_M[WIDTH-1:0] <= OPA >> 1;
                                                else ERR_M <= 1;
                                        end
                                        9: begin //A_SHIFT_LEFT
                                                if(INP_VALID[0]) RES_M[WIDTH-1:0] <= OPA << 1;
                                                else ERR_M <= 1;
                                        end
                                        10: begin //B_SHIFT_RIGHT
                                                if(INP_VALID[1]) RES_M[WIDTH-1:0] <= OPB >> 1;
                                                else ERR_M <= 1;
                                        end
                                        11: begin //B_SHIFT_LEFT
                                                if(INP_VALID[1]) RES_M[WIDTH-1:0] <= OPB << 1;
                                                else ERR_M <= 1;
                                        end
                                        12: begin //A_ROTATE_RIGHT
                                                if(OPB[WIDTH-1:$clog2(WIDTH)] != 0) ERR_M <= 1;
                                                RES_M[WIDTH-1:0] <= (OPA << OPB[$clog2(WIDTH)-1:0]) | (OPA >> (WIDTH - OPB[$clog2(WIDTH)-1:0]));
                                        end
                                        13: begin //A_ROTATE_LEFT
                                                if(OPB[WIDTH-1:$clog2(WIDTH)] != 0) ERR_M <= 1;
                                                RES_M[WIDTH-1:0] <= (OPA >> OPB[$clog2(WIDTH)-1:0]) | (OPA << (WIDTH - OPB[$clog2(WIDTH)-1:0]));
                                        end
                                        default: ERR_M <= 1;
                                endcase
                        end
                end
                else begin
                        RES_M <= RES_M; OFLOW_M <= OFLOW_M; COUT_M <= COUT_M; E_M <= E_M; G_M <= G_M; L_M <= L_M; ERR_M <= ERR_M;
                end
                RES <= RES_M; OFLOW <= OFLOW_M; COUT <= COUT_M; E <= E_M; G <= G_M; L <= L_M; ERR <= ERR_M;
        end
endmodule
