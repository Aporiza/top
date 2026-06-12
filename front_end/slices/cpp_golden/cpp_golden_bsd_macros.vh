// Simulation-only helper for C++ golden BSD mode.
`ifndef CPP_GOLDEN_BSD_MACROS_VH
`define CPP_GOLDEN_BSD_MACROS_VH

`define CPP_GOLDEN_BSD(MOD_NAME, IN_WIDTH, OUT_WIDTH) \
    import "DPI-C" context function void cpp_golden_``MOD_NAME( \
        input  bit [IN_WIDTH-1:0]  dpi_pi, \
        output bit [OUT_WIDTH-1:0] dpi_po \
    ); \
    reg [OUT_WIDTH-1:0] po_cpp_golden; \
    always @* begin \
        cpp_golden_``MOD_NAME(pi, po_cpp_golden); \
    end \
    assign po = po_cpp_golden;

`endif
