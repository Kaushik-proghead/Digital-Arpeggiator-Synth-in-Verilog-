// sine_rom.v - Verilog-2005 ROM with diagnostic prints
module sine_rom (
    input  wire [7:0] addr,
    output reg  [7:0] dout
);
    reg [7:0] mem [0:255];

    integer i;

    initial begin
        $display("---- sine_rom diagnostic ----");

        // Attempt to load file
        $readmemh("sine256.hex", mem);

        // Print the first 16 ROM entries
        $display("First 16 ROM values (hex):");
        for (i = 0; i < 16; i = i + 1) begin
            $write("%h ", mem[i]);
        end
        $display("\n---- end diagnostic ----");
    end

    always @(*) begin
        dout = mem[addr];
    end
endmodule
