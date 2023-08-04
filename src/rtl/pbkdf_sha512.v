//======================================================================
//
// pbkdf_sha512.v
// -------------
// Verilog 2001 implementation of a PBKF using SHA512
//
//
// Author: DHK
// Copyright (c) 2023 Rawatech R&D
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================
`default_nettype none

module pbkdf_sha512(
    input wire clk,
    input wire ce, // Chip enable. This pin must be H when cycling init to start the process
    input wire reset_n,
    input wire init,

    input wire [1023 : 0 ] data,
    input wire [31   : 0 ] rounds,

    output wire ready,
    output wire [511 : 0] digest,
    output wire digest_valid
);


//----------------------------------------------------------------
// Module instantiantions.
//----------------------------------------------------------------
sha512_core sha512_core_inst (
    .clk(clk),
    .reset_n(reset_n),
    .init(core_init),
    .block(core_input),
    .ready(core_ready),
    .digest(digest),
    .digest_valid(core_digest_valid)
);

//----------------------------------------------------------------
// Wires.
//----------------------------------------------------------------
wire core_ready; // Driven by core
wire core_init;  // Driven by pbkdf module
wire core_digest_valid;
wire [1023 : 0 ] core_input; // Driven by pbkdf module

//----------------------------------------------------------------
// Registers including update variables and write enable.
//-------------------------------------------------------
reg [31 : 0] round_ctr_reg;
reg [31 : 0] round_ctr_new;
reg          round_ctr_we;
reg          round_ctr_inc;
reg          round_ctr_rst;

reg [1 : 0]  state_reg;
reg [1 : 0]  state_new;
reg          state_we;

reg          ready_reg;
reg          ready_new;
reg          ready_we;

reg          digest_valid_reg;
reg          digest_valid_new;
reg          digest_valid_we;

reg          core_init_reg;
reg          core_init_new;
reg          core_init_we;

reg [1023 : 0]  core_input_reg;
reg [1023 : 0]  core_input_new;
reg             core_input_we;

//----------------------------------------------------------------
// Internal constant and parameter definitions.
//----------------------------------------------------------------
localparam STATE_IDLE    = 2'h0;
localparam STATE_INIT    = 2'h1;
localparam STATE_HASHING = 2'h2;
localparam STATE_DONE    = 2'h3;


//----------------------------------------------------------------
// Concurrent connectivity for ports etc.
//----------------------------------------------------------------
assign ready = ready_reg;
assign digest_valid = digest_valid_reg;
assign core_init = core_init_reg;
assign core_input = core_input_reg;

//----------------------------------------------------------------
// reg_update
// Update functionality for all registers in the core.
// All registers are positive edge triggered with asynchronous
// active low reset. All registers have write enable.
//----------------------------------------------------------------
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state_reg       <= STATE_IDLE;
        ready_reg       <= 1'b1;
        round_ctr_reg   <= 32'b1;
        core_init_reg   <= 1'b0;
        core_input_reg  <= 1024'b0;
    end else begin
        // TODO +clk logic

        if (state_we) 
            state_reg <= state_new;

        if (round_ctr_we)
            round_ctr_reg <= round_ctr_new;

        if (ready_we) 
            ready_reg <= ready_new;

        if (digest_valid_we)
            digest_valid_reg <= digest_valid_new;

        if (core_init_we)
            core_init_reg <= core_init_new;

        if (core_input_we)
            core_input_reg <= core_input_new;
    end
end

//----------------------------------------------------------------
// round_ctr
//
// Update logic for the round counter, a monotonically
// increasing counter with reset.
//----------------------------------------------------------------
always @*
begin : round_ctr
    round_ctr_new = 7'h01;
    round_ctr_we  = 0;

    if (round_ctr_rst)
    begin
        round_ctr_new = 7'h01;
        round_ctr_we  = 1;
    end

    if (round_ctr_inc)
    begin
        round_ctr_new = round_ctr_reg + 1'b1;
        round_ctr_we  = 1;
    end
end // round_ctr


//----------------------------------------------------------------
// pbkdf_fsm
//
// Logic for the state machine controlling the core behaviour.
//----------------------------------------------------------------
always @* begin : pbkdf_fsm
    round_ctr_inc       = 1'b0;
    round_ctr_rst       = 1'b0;
    ready_new           = 1'b0;
    ready_we            = 1'b0;
    digest_valid_we     = 1'b0;
    digest_valid_new    = 1'b0;
    core_init_new       = 1'b0;
    core_init_we        = 1'b0;
	core_input_we       = 1'b0;
	core_input_new      = 1024'b0;
    round_ctr_inc       = 0;

    state_new = STATE_IDLE;
    state_we = 1'b0;

    case (state_reg)
    STATE_IDLE: begin
        if (init && ce) begin
            ready_new           = 1'b0;
            ready_we            = 1'b1;
            round_ctr_rst       = 1;
            digest_valid_new    = 0;
            digest_valid_we     = 1;
            core_init_new       = 1;
            core_init_we        = 1;
            core_input_new      = data;
            core_input_we       = 1;

            state_new           = STATE_INIT;
            state_we            = 1;
        end
    end

    STATE_INIT: begin
        core_init_new = 1'b0;
        core_init_we  = 1;
        state_new = STATE_HASHING;
        state_we = 1;
    end

    STATE_HASHING: begin
        if (core_digest_valid) begin
            round_ctr_inc = 1;
            if (round_ctr_reg == rounds) begin
                state_new = STATE_DONE;
                state_we = 1;
            end else begin
                core_input_new      = {digest, 1'b1, 499'b0, 12'd512};
                core_input_we       = 1;
                state_new = STATE_INIT;
                state_we = 1;
                core_init_new = 1;
                core_init_we = 1;
            end
        end
    end

    STATE_DONE: begin
        ready_new        = 1'b1;
        ready_we         = 1'b1;
        digest_valid_new = 1'b1;
        digest_valid_we  = 1'b1;
        state_new  = STATE_IDLE;
        state_we   = 1'b1;
    end



    endcase

end

endmodule