// adsr.v - Simple ADSR envelope generator (Verilog-2005 compatible)
// Scales 16-bit PCM based on ADSR state machine
module adsr #(
    parameter SAMPLE_RATE = 44100,
    parameter ATTACK_MS   = 50,
    parameter DECAY_MS    = 100,
    parameter RELEASE_MS  = 150,
    parameter SUSTAIN_PCT = 50   // 0–100 (% of peak)
)(
    input  wire              sample_clk,
    input  wire              rst,
    input  wire              note_gate,       // 1 = note on, 0 = note off
    input  wire signed [15:0] in_pcm,
    output reg  signed [15:0] out_pcm
);

    // ======================================================
    // Convert envelope times to sample counts
    // ======================================================
    localparam integer ATTACK_SAMPLES  = (SAMPLE_RATE * ATTACK_MS)  / 1000;
    localparam integer DECAY_SAMPLES   = (SAMPLE_RATE * DECAY_MS)   / 1000;
    localparam integer RELEASE_SAMPLES = (SAMPLE_RATE * RELEASE_MS) / 1000;

    // 0–65535 amplitude scale
    reg [15:0] amp = 0;

    // Envelope phases
    localparam [1:0] ST_ATTACK  = 2'd0;
    localparam [1:0] ST_DECAY   = 2'd1;
    localparam [1:0] ST_SUSTAIN = 2'd2;
    localparam [1:0] ST_RELEASE = 2'd3;

    reg [1:0] state = ST_RELEASE;
    reg [31:0] env_count = 0;

    // Sustain target (16-bit scale)
    localparam [15:0] SUSTAIN_LEVEL = (SUSTAIN_PCT * 65535) / 100;

    // ======================================================
    // Envelope FSM
    // ======================================================
    always @(posedge sample_clk or posedge rst) begin
        if (rst) begin
            state <= ST_RELEASE;
            env_count <= 0;
            amp <= 0;
        end else begin

            case (state)

            // ---------------------------------- Attack
            ST_ATTACK: begin
                if (env_count < ATTACK_SAMPLES) begin
                    env_count <= env_count + 1;
                    amp <= (env_count * 65535) / ATTACK_SAMPLES;
                end else begin
                    state <= ST_DECAY;
                    env_count <= 0;
                end
            end

            // ---------------------------------- Decay
            ST_DECAY: begin
                if (env_count < DECAY_SAMPLES) begin
                    env_count <= env_count + 1;
                    amp <= 65535 - (env_count * (65535 - SUSTAIN_LEVEL)) / DECAY_SAMPLES;
                end else begin
                    state <= ST_SUSTAIN;
                    amp <= SUSTAIN_LEVEL;
                end
            end

            // ---------------------------------- Sustain
            ST_SUSTAIN: begin
                amp <= SUSTAIN_LEVEL;
            end

            // ---------------------------------- Release
            ST_RELEASE: begin
                if (env_count < RELEASE_SAMPLES) begin
                    env_count <= env_count + 1;
                    amp <= (SUSTAIN_LEVEL * (RELEASE_SAMPLES - env_count)) / RELEASE_SAMPLES;
                end else begin
                    amp <= 0;
                end
            end

            endcase

            // ----------------------------------
            // Note ON → Attack
            if (note_gate && state == ST_RELEASE) begin
                state <= ST_ATTACK;
                env_count <= 0;
            end

            // Note OFF → Release
            if (!note_gate && state != ST_RELEASE) begin
                state <= ST_RELEASE;
                env_count <= 0;
            end
        end
    end

    // ======================================================
    // Apply amplitude to PCM
    // ======================================================
    wire signed [31:0] scaled = (in_pcm * amp) >>> 16;

    always @(posedge sample_clk) begin
        out_pcm <= scaled[15:0];
    end

endmodule
