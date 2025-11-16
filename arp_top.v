// arp_top.v — ONLY the arpeggio (no chords), guitar-like ADSR

module arp_top #(
    parameter PHASE_BITS  = 32,
    parameter SAMPLE_RATE = 44100
)(
    input  wire               sample_clk,
    input  wire               rst,
    output wire signed [15:0] pcm_out
);

    // ----------------------------------------------------------
    // Arpeggio voice
    // ----------------------------------------------------------
    wire [PHASE_BITS-1:0] arp_phase_step;
    wire [4:0] arp_seq_pos;
    wire signed [15:0] arp_raw, arp_env;

    arp_fsm #(
        .PHASE_BITS(PHASE_BITS),
        .SAMPLE_RATE(SAMPLE_RATE)
    ) arp_inst (
        .sample_clk(sample_clk),
        .rst(rst),
        .phase_step_out(arp_phase_step),
        .seq_pos(arp_seq_pos)
    );

    // DDS with improved waveshape (you updated this separately)
    dds #(.PHASE_BITS(PHASE_BITS)) arp_dds (
        .sample_clk(sample_clk),
        .rst(rst),
        .phase_step(arp_phase_step),
        .pcm_out(arp_raw)
    );

    // ----------------------------------------------------------
    // Guitar-like envelope
    // ----------------------------------------------------------
    adsr #(
        .SAMPLE_RATE(SAMPLE_RATE),
        .ATTACK_MS(5),      // quick pick
        .DECAY_MS(150),     // natural decay
        .SUSTAIN_PCT(8),    // tiny sustain
        .RELEASE_MS(200)    // smooth tail
    ) arp_adsr (
        .sample_clk(sample_clk),
        .rst(rst),
        .note_gate(1'b1),
        .in_pcm(arp_raw),
        .out_pcm(arp_env)
    );

    // ----------------------------------------------------------
    // Strong Startup Mute — guaranteed no thump
    // Mutes first 5000 samples (~113 ms at 44.1 kHz)
    // ----------------------------------------------------------
    reg [15:0] startup_counter = 0;
    reg        mute = 1;

    always @(posedge sample_clk or posedge rst) begin
        if (rst) begin
            startup_counter <= 0;
            mute <= 1;
        end else begin
            if (startup_counter < 16'd5000) begin
                startup_counter <= startup_counter + 1;
                mute <= 1;
            end else begin
                mute <= 0;
            end
        end
    end

    // ----------------------------------------------------------
    // Final output
    // ----------------------------------------------------------
    assign pcm_out = mute ? 16'sd0 : arp_env;

endmodule
