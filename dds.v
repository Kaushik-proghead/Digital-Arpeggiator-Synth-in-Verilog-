module dds #(
    parameter PHASE_BITS = 32
)(
    input  wire                 sample_clk,
    input  wire                 rst,
    input  wire [PHASE_BITS-1:0] phase_step,
    output reg  signed [15:0]   pcm_out
);

    reg [PHASE_BITS-1:0] phase = 0;

    // --------------------------------------------------------
    // Phase accumulator with ZERO-CROSS RESET
    // Forces phase to exactly 0 on reset so the waveform 
    // starts at a perfect zero crossing → NO startup click.
    // --------------------------------------------------------
    always @(posedge sample_clk or posedge rst) begin
        if (rst) begin
            phase <= {PHASE_BITS{1'b0}};   // start DDS at 0.0 exactly
        end else begin
            phase <= phase + phase_step;
        end
    end

    // ROM address (top 8 bits)
    wire [7:0] addr = phase[PHASE_BITS-1 -: 8];
    wire [7:0] lut_data;

    sine_rom rom_inst (
        .addr(addr),
        .dout(lut_data)
    );

    // ------------------------------------------------------------------
    // Improved guitar-style waveshape:
    // ------------------------------------------------------------------

    // sine 16-bit (centered)
    wire signed [15:0] sin =
        ( $signed({1'b0, lut_data}) - 8'sd128 ) <<< 8;

    // sawtooth (high 16 bits)
    wire signed [15:0] saw = phase[PHASE_BITS-1 -: 16];

    // square wave from MSB
    wire signed [15:0] sqr = phase[PHASE_BITS-1]
                              ? 16'sh7FFF
                              : -16'sh7FFF;

    // harmonic blend
    wire signed [17:0] blend =
        sin +
        (saw >>> 2) +
        (sqr >>> 4);

    // final output
    always @(posedge sample_clk) begin
        pcm_out <= blend[15:0];
    end

endmodule
