`timescale 1ns/1ps

module tb_arp;

    parameter integer SAMPLE_RATE   = 44100;
    parameter integer TOTAL_SECONDS = 6;
    parameter integer MAX_SAMPLES   = SAMPLE_RATE * TOTAL_SECONDS;
    parameter integer CLK_PERIOD_NS = 22675; // ~44.1kHz

    reg sample_clk = 0;
    reg rst = 1;
    wire signed [15:0] pcm;

    reg signed [15:0] sample_mem [0:MAX_SAMPLES-1];
    integer sample_count;

    // DUT
    arp_top uut (
        .sample_clk(sample_clk),
        .rst(rst),
        .pcm_out(pcm)
    );

    // clock
    initial forever #(CLK_PERIOD_NS/2) sample_clk = ~sample_clk;

    // reset
    initial begin
        rst = 1;
        repeat(8) @(posedge sample_clk);
        rst = 0;
    end

    // capture samples
    initial begin
        sample_count = 0;
        @(negedge rst);

        while (sample_count < MAX_SAMPLES) begin
            @(posedge sample_clk);
            sample_mem[sample_count] = pcm;
            sample_count = sample_count + 1;
        end

        $display("Collected %0d samples, writing WAV...", sample_count);
        write_wav("arp_pattern.wav");
        $display("Done!");
        $finish;
    end

    // ----------------------------------------------------
    // WAV writer
    // ----------------------------------------------------
    task write_wav;
        input [256*8:0] filename;
        integer fd;
        integer i;
        integer data_size;
        integer byte_rate;
        integer block_align;
        reg [7:0] b0, b1;
    begin
        fd = $fopen(filename, "wb");
        if (fd == 0) begin
            $display("ERROR: cannot open output WAV.");
            disable write_wav;
        end

        data_size = MAX_SAMPLES * 2;
        byte_rate = SAMPLE_RATE * 2;
        block_align = 2;

        $fwrite(fd, "RIFF");
        write_le32(fd, 36 + data_size);
        $fwrite(fd, "WAVE");

        $fwrite(fd, "fmt ");
        write_le32(fd, 16);
        write_le16(fd, 1);
        write_le16(fd, 1);
        write_le32(fd, SAMPLE_RATE);
        write_le32(fd, byte_rate);
        write_le16(fd, block_align);
        write_le16(fd, 16);

        $fwrite(fd, "data");
        write_le32(fd, data_size);

        for (i = 0; i < MAX_SAMPLES; i = i + 1) begin
            b0 = sample_mem[i][7:0];
            b1 = sample_mem[i][15:8];
            $fwrite(fd, "%c%c", b0, b1);
        end

        $fclose(fd);
    end
    endtask

    task write_le16;
        input integer fd, val;
        reg [7:0] lo, hi;
    begin
        lo = val & 8'hFF;
        hi = (val >> 8) & 8'hFF;
        $fwrite(fd, "%c%c", lo, hi);
    end
    endtask

    task write_le32;
        input integer fd, val;
        reg [7:0] b0, b1, b2, b3;
    begin
        b0 = val & 8'hFF;
        b1 = (val >> 8) & 8'hFF;
        b2 = (val >> 16) & 8'hFF;
        b3 = (val >> 24) & 8'hFF;
        $fwrite(fd, "%c%c%c%c", b0, b1, b2, b3);
    end
    endtask

endmodule
