//======================================================================
//
// sha512_core.v
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
    input wire reset_n,
    input wire init,

    input wire [1023 : 0 ] block,
    input wire [31   : 0 ] rounds,

    output wire ready,
    output wire [511 : 0] digest
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
    .digest(digest)
);


wire core_ready; // Driven by core
wire core_init;  // Driven by pbkdf module

reg [1023 : 0 ] core_input; // Driven by pbkdf module


endmodule