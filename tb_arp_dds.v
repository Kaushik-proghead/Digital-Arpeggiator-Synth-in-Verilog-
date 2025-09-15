// tb_arp_dds.v
`timescale 1ns/1ps
module tb_arp_dds;
    reg clk = 0;
    always #10 clk = ~clk; // 50 MHz simulation clock (period irrelevant for audio)

    reg rst = 1;
    initial begin
        #50 rst = 0;
    end

    // params
    parameter integer SAMPLE_RATE = 48000;
    parameter integer NOTE_DURATION_SAMPLES = SAMPLE_RATE / 4; // 0.25s per note by default
    parameter integer TOTAL_SECONDS = 12;
    parameter integer TOTAL_SAMPLES = SAMPLE_RATE * TOTAL_SECONDS;

    reg [31:0] delta;
    reg [1:0] wave_sel;
    wire signed [15:0] sample;

    // instantiate dds
    dds #(.PHASE_WIDTH(32), .OUT_WIDTH(16), .LUT_ADDR_BITS(8)) dut (
        .clk(clk),
        .rst(rst),
        .delta(delta),
        .wave_sel(wave_sel),
        .out_sample(sample)
    );

    integer outfile;
    integer i;

    // Pattern selection: 0=UP, 1=DOWN, 2=UP-DOWN, 3=RANDOM
    integer pattern = 2;

    // REST marker: delta==0
    localparam REST = 32'h0000_0000;

    // Example chord: C minor (C4, Eb4, G4). Use deltas printed from generate_sine_mem.py
    // You should replace these with the decimal deltas your python script printed for exact freq.
    // I put example placeholders — run python to get correct large integers.
    reg [31:0] chord [0:2];
    initial begin
        // Example deltas (these are placeholders — better to compute via python):
        chord[0] = 32'd38222;    // <-- replace with delta_for_freq(C4) from python
        chord[1] = 32'd45450;    // <-- replace with delta_for_freq(Eb4)
        chord[2] = 32'd51020;    // <-- replace with delta_for_freq(G4)
    end

    // Arp pattern with optional rests: we will step through the chord array indices,
    // but we can also interleave REST entries if you want explicit silence between notes.
    integer note_index = 0;
    integer direction = 1; // for up-down

    initial begin
        outfile = $fopen("output.txt", "w");
        // choose waveform (00=sine, 01=square, 10=triangle, 11=saw)
        wave_sel = 2'b00;

        // Allow some time after reset
        #100;

        // initialize delta to first chord note
        delta = chord[0];

        // produce TOTAL_SAMPLES samples
        // we change the active note every NOTE_DURATION_SAMPLES
        for (i = 0; i < TOTAL_SAMPLES; i = i + 1) begin
            // every NOTE_DURATION_SAMPLES samples, move to next note according to pattern
            if ((i % NOTE_DURATION_SAMPLES) == 0) begin
                case (pattern)
                    0: begin // UP
                        note_index = (note_index + 1) % 3;
                        delta = chord[note_index];
                    end
                    1: begin // DOWN
                        note_index = (note_index - 1 + 3) % 3;
                        delta = chord[note_index];
                    end
                    2: begin // UP-DOWN (bounce)
                        if (note_index == 2) direction = -1;
                        else if (note_index == 0) direction = 1;
                        note_index = note_index + direction;
                        delta = chord[note_index];
                    end
                    3: begin // RANDOM
                        note_index = $urandom % 3;
                        delta = chord[note_index];
                    end
                    default: begin
                        note_index = (note_index + 1) % 3;
                        delta = chord[note_index];
                    end
                endcase
            end

            @(posedge clk);
            // write the decimal sample value into the text file
            $fwrite(outfile, "%0d\n", sample);
        end

        $fclose(outfile);
        $display("Done. Wrote output.txt (%0d samples).", TOTAL_SAMPLES);
        $finish;
    end
endmodule
