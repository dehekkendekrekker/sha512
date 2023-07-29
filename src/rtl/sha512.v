//======================================================================
//
// sha512_core.v
// -------------
// Verilog 2001 implementation of the SHA-512 hash function.
//
//
// Author: Daniel Attevelt
// Copyright (c) 2023 Rawatech
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

module sha512(
  input wire            clk,
  input wire            reset_n,   // Resets W block, active low

  input wire            init,      // Initializes first round, active high. Pull high before a new series of PBKDF rounds. Mutually exclusive with 'next'.
  input wire [31:0]     rounds,

  input wire [1023 : 0] block,

  output wire           ready,
  output wire [511 : 0] digest,
  output wire           digest_valid,
  output wire			debug
);


//----------------------------------------------------------------
// Internal constant and parameter definitions.
//----------------------------------------------------------------
  localparam CTRL_IDLE   = 2'h0;
  localparam CTRL_ROUNDS = 2'h1;
  localparam CTRL_DONE   = 2'h2;


//----------------------------------------------------------------
// Registers including update variables and write enable.
//----------------------------------------------------------------
    reg init_reg;
    reg init_new;
    reg init_we;

    reg [1023:0] block_reg;
    reg [1023:0] block_new;
    reg block_we;

//----------------------------------------------------------------
// Module instantiantions.
//----------------------------------------------------------------
    sha512_core sha512_core_inst(
        .clk(clk),
        .reset_n(reset_n),
        .init(init_reg),
        .block(block_reg),
        .ready(ready),
        .digest(digest)
    );
  

endmodule