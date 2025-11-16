// arp_fsm.v - Looped two-pattern arpeggiator
// Tempo = 130 BPM. Each note = sixteenth note.
// Small pause (one sixteenth) between Pattern 1 and Pattern 2.
// Patterns loop forever.

module arp_fsm #(
    parameter PHASE_BITS  = 32,
    parameter SAMPLE_RATE = 44100
)(
    input  wire                 sample_clk,
    input  wire                 rst,
    output reg [PHASE_BITS-1:0] phase_step_out,
    output reg [4:0]            seq_pos        // <-- ADDED OUTPUT
);

    // ------------------------------------------------------
    // Phase-step constants (approx for guitar register)
    // ------------------------------------------------------
    localparam [31:0] FSHARP3 = 32'd18017164;
    localparam [31:0] ASHARP3 = 32'd21730900;
    localparam [31:0] CSHARP4 = 32'd26983800;
    localparam [31:0] E4      = 32'd32102942;
    localparam [31:0] G4      = 32'd36590106;
    localparam [31:0] ASHARP4 = 32'd43461800;
    localparam [31:0] A3      = 32'd20511920;
    localparam [31:0] C4      = 32'd25480122;
    localparam [31:0] B3      = 32'd24050034;
    localparam [31:0] D4      = 32'd28600469;
    localparam [31:0] FSHARP4 = 32'd36034328;

    // ------------------------------------------------------
    // Timing for 130 BPM
    // Sixteenth note = 5082 samples
    // ------------------------------------------------------
    localparam integer NOTE_SAMPLES = 5082;   // sixteenth @130 BPM
    localparam integer REST_SAMPLES = 5082;   // tiny pause

    // ------------------------------------------------------
    // Sequence: Pattern 1 (12 notes), rest, Pattern 2 (14 notes)
    // Total = 27 steps (0..26)
    // ------------------------------------------------------
    reg [31:0] count = 0;

    function [31:0] seq_val;
        input [4:0] idx;
    begin
        case (idx)
            // Pattern 1 (12 notes)
            5'd0:  seq_val = FSHARP3;
            5'd1:  seq_val = ASHARP3;
            5'd2:  seq_val = CSHARP4;
            5'd3:  seq_val = E4;
            5'd4:  seq_val = G4;
            5'd5:  seq_val = ASHARP4;
            5'd6:  seq_val = CSHARP4;
            5'd7:  seq_val = ASHARP4;
            5'd8:  seq_val = G4;
            5'd9:  seq_val = E4;
            5'd10: seq_val = CSHARP4;
            5'd11: seq_val = A3;

            // small rest
            5'd12: seq_val = 32'd0;

            // Pattern 2 (14 notes)
            5'd13: seq_val = A3;
            5'd14: seq_val = CSHARP4;
            5'd15: seq_val = E4;
            5'd16: seq_val = A3;
            5'd17: seq_val = CSHARP4;
            5'd18: seq_val = D4;
            5'd19: seq_val = FSHARP4;
            5'd20: seq_val = D4;
            5'd21: seq_val = CSHARP4;
            5'd22: seq_val = A3;
            5'd23: seq_val = G4;
            5'd24: seq_val = A3;
            5'd25: seq_val = CSHARP4;
            5'd26: seq_val = A3;

            default: seq_val = 32'd0;
        endcase
    end
    endfunction

    // ------------------------------------------------------
    // FSM: step through sequence and LOOP forever
    // ------------------------------------------------------
    always @(posedge sample_clk or posedge rst) begin
        if (rst) begin
            seq_pos <= 0;
            count <= 0;
            phase_step_out <= seq_val(0);
        end else begin
            count <= count + 1;

            // REST slot
            if (seq_pos == 5'd12) begin
                if (count >= REST_SAMPLES) begin
                    count <= 0;
                    seq_pos <= (seq_pos == 5'd26) ? 0 : seq_pos + 1;
                    phase_step_out <= seq_val((seq_pos == 5'd26) ? 0 : seq_pos + 1);
                end
            end

            else begin
                // Normal note
                if (count >= NOTE_SAMPLES) begin
                    count <= 0;
                    seq_pos <= (seq_pos == 5'd26) ? 0 : seq_pos + 1;
                    phase_step_out <= seq_val((seq_pos == 5'd26) ? 0 : seq_pos + 1);
                end
            end
        end
    end

endmodule
