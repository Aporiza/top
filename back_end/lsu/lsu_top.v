// Source struct:
//   LsuIn  = {rob_commit, rob_bcast, dec_bcast, csr_status, dis2lsu,
//             exe2lsu, peripheral_resp, dcache2lsu, mmu2lsu}
//   LsuOut = {lsu2dis, lsu2rob, lsu2exe, peripheral_req, lsu2dcache, lsu2mmu}
// LDQ/STQ entries, address/data RAMs, MMIO state and replay bookkeeping remain
// private to LSU.

module lsu_top #(
    parameter integer DECODE_WIDTH           = 8,
    parameter integer COMMIT_WIDTH           = DECODE_WIDTH,
    parameter integer AREG_IDX_WIDTH         = 6,
    parameter integer PRF_IDX_WIDTH          = 11,
    parameter integer ROB_IDX_WIDTH          = 11,
    parameter integer STQ_IDX_WIDTH          = 9,
    parameter integer LDQ_IDX_WIDTH          = 9,
    parameter integer BR_TAG_WIDTH           = 6,
    parameter integer BR_MASK_WIDTH          = 64,
    parameter integer FTQ_IDX_WIDTH          = 8,
    parameter integer FTQ_OFFSET_WIDTH       = 4,
    parameter integer INST_TYPE_WIDTH        = 5,
    parameter integer UOP_TYPE_WIDTH         = 5,
    parameter integer LSU_LDU_COUNT          = 4,
    parameter integer LSU_STA_COUNT          = 4,
    parameter integer LSU_AGU_COUNT          = 8,
    parameter integer LSU_SDU_COUNT          = 4,
    parameter integer LSU_LOAD_WB_WIDTH      = LSU_LDU_COUNT,
    parameter integer LSU_LDU_WIDTH          = 2,
    parameter integer MAX_STQ_DISPATCH_WIDTH = DECODE_WIDTH,
    parameter integer MAX_LDQ_DISPATCH_WIDTH = DECODE_WIDTH,
    parameter integer ROB_NUM                = 2048,
    parameter integer W_STQ_COUNT            = 10,
    parameter integer W_LDQ_COUNT            = 10,
    parameter integer W_DebugMeta            = 32 + 32 + 8 + 1 + 64,
    parameter integer W_TmaMeta              = 4,
    parameter integer W_RobCommitInst        =
        32 + AREG_IDX_WIDTH + (2 * PRF_IDX_WIDTH) + FTQ_IDX_WIDTH +
        FTQ_OFFSET_WIDTH + 1 + 2 + 1 + 7 + ROB_IDX_WIDTH + 1 +
        STQ_IDX_WIDTH + 1 + 4 + INST_TYPE_WIDTH + W_TmaMeta + W_DebugMeta + 1,
    parameter integer W_RobCommitIO    = COMMIT_WIDTH * (1 + W_RobCommitInst),
    parameter integer W_RobBroadcastIO =
        7 + 5 + 32 + 32 + ROB_IDX_WIDTH + 1 + ROB_IDX_WIDTH + 1,
    parameter integer W_DecBroadcastIO =
        1 + BR_MASK_WIDTH + BR_TAG_WIDTH + ROB_IDX_WIDTH + BR_MASK_WIDTH,
    parameter integer W_CsrStatusIO = 32 + 32 + 32 + 2,
    parameter integer W_DisLsuIO    =
        MAX_STQ_DISPATCH_WIDTH *
            (1 + BR_MASK_WIDTH + 3 + ROB_IDX_WIDTH + 1 + 1) +
        MAX_LDQ_DISPATCH_WIDTH *
            (1 + LDQ_IDX_WIDTH + BR_MASK_WIDTH + ROB_IDX_WIDTH + 1),
    parameter integer W_ExeLsuReqUop =
        32 + PRF_IDX_WIDTH + 3 + 7 + 1 + BR_MASK_WIDTH + ROB_IDX_WIDTH +
        STQ_IDX_WIDTH + 1 + LDQ_IDX_WIDTH + 1 + 1 + UOP_TYPE_WIDTH +
        W_DebugMeta,
    parameter integer W_ExeLsuIO =
        (LSU_AGU_COUNT + LSU_SDU_COUNT) * (1 + W_ExeLsuReqUop),
    parameter integer W_PeripheralRespIO = 1 + 1 + 32,
    parameter integer W_LoadResp         = 1 + 32 + 32 + 2,
    parameter integer W_StoreResp        = 1 + 2 + 32,
    parameter integer W_DCacheRespPorts  =
        (LSU_LDU_COUNT * W_LoadResp) + (LSU_STA_COUNT * W_StoreResp),
    parameter integer W_DcacheLsuIO = W_DCacheRespPorts + 1,
    parameter integer W_MMUResp     = 1 + 32 + 2,
    parameter integer W_MMULsuIO    =
        (W_MMUResp * LSU_LDU_COUNT) + (W_MMUResp * LSU_STA_COUNT),
    parameter integer W_LsuDisIO =
        STQ_IDX_WIDTH + 1 + W_STQ_COUNT + W_LDQ_COUNT +
        (LDQ_IDX_WIDTH * MAX_LDQ_DISPATCH_WIDTH) + MAX_LDQ_DISPATCH_WIDTH,
    parameter integer W_LsuRobIO      = ROB_NUM + 1,
    parameter integer W_LsuExeRespUop =
        32 + 32 + PRF_IDX_WIDTH + BR_MASK_WIDTH + ROB_IDX_WIDTH + 1 +
        2 + UOP_TYPE_WIDTH + W_DebugMeta + 1,
    parameter integer W_LsuExeIO =
        (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT) * (1 + W_LsuExeRespUop),
    parameter integer W_PeripheralReqIO = 1 + 1 + 32 + 32 + 3,
    parameter integer W_LoadReq         = 1 + 32 + 32 + 1,
    parameter integer W_StoreReq        = 1 + 32 + 32 + 8 + 32 + 1,
    parameter integer W_DCacheReqPorts  =
        (LSU_LDU_COUNT * W_LoadReq) + (LSU_STA_COUNT * W_StoreReq),
    parameter integer W_LsuDcacheIO = W_DCacheReqPorts + LSU_LDU_WIDTH + 1,
    parameter integer W_MMUReq      = 1 + 32,
    parameter integer W_LsuMMUIO    =
        (W_MMUReq * LSU_LDU_COUNT) + (W_MMUReq * LSU_STA_COUNT) + W_CsrStatusIO,
    parameter integer W_LsuIn =
        W_RobCommitIO + W_RobBroadcastIO + W_DecBroadcastIO + W_CsrStatusIO +
        W_DisLsuIO + W_ExeLsuIO + W_PeripheralRespIO + W_DcacheLsuIO +
        W_MMULsuIO,
    parameter integer W_LsuOut =
        W_LsuDisIO + W_LsuRobIO + W_LsuExeIO + W_PeripheralReqIO +
        W_LsuDcacheIO + W_LsuMMUIO
) (
    input wire [W_RobCommitIO-1:0]      rob_commit,
    input wire [W_RobBroadcastIO-1:0]   rob_bcast,
    input wire [W_DecBroadcastIO-1:0]   dec_bcast,
    input wire [W_CsrStatusIO-1:0]      csr_status,
    input wire [W_DisLsuIO-1:0]         dis2lsu,
    input wire [W_ExeLsuIO-1:0]         exe2lsu,
    input wire [W_PeripheralRespIO-1:0] peripheral_resp,
    input wire [W_DcacheLsuIO-1:0]      dcache2lsu,
    input wire [W_MMULsuIO-1:0]         mmu2lsu_io,

    output wire [W_LsuDisIO-1:0]        lsu2dis,
    output wire [W_LsuRobIO-1:0]        lsu2rob,
    output wire [W_LsuExeIO-1:0]        lsu2exe,
    output wire [W_PeripheralReqIO-1:0] peripheral_req,
    output wire [W_LsuDcacheIO-1:0]     lsu2dcache,
    output wire [W_LsuMMUIO-1:0]        lsu2mmu_io
);

    wire [W_LsuIn-1:0]  pi;
    wire [W_LsuOut-1:0] po;

    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_valid;
    wire [(W_RobCommitInst * COMMIT_WIDTH)-1:0] rob_commit_entry_uop;
    assign {rob_commit_entry_valid, rob_commit_entry_uop} = rob_commit;
    wire [(32 * COMMIT_WIDTH)-1:0] rob_commit_entry_uop_diag_val;
    wire [(AREG_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_dest_areg;
    wire [(PRF_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_dest_preg;
    wire [(PRF_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_old_dest_preg;
    wire [(FTQ_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_ftq_idx;
    wire [(FTQ_OFFSET_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_ftq_offset;
    wire [COMMIT_WIDTH-1:0]       rob_commit_entry_uop_ftq_is_last;
    wire [COMMIT_WIDTH-1:0]       rob_commit_entry_uop_mispred;
    wire [COMMIT_WIDTH-1:0]       rob_commit_entry_uop_br_taken;
    wire [COMMIT_WIDTH-1:0]       rob_commit_entry_uop_dest_en;
    wire [(7 * COMMIT_WIDTH)-1:0] rob_commit_entry_uop_func7;
    wire [(ROB_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_rob_idx;
    wire [COMMIT_WIDTH-1:0] rob_commit_entry_uop_rob_flag;
    wire [(STQ_IDX_WIDTH * COMMIT_WIDTH)-1:0]
        rob_commit_entry_uop_stq_idx;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_stq_flag;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_page_fault_inst;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_page_fault_load;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_page_fault_store;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_illegal_inst;
    wire [(INST_TYPE_WIDTH * COMMIT_WIDTH)-1:0] rob_commit_entry_uop_type;
    wire [(W_TmaMeta * COMMIT_WIDTH)-1:0]       rob_commit_entry_uop_tma;
    wire [(W_DebugMeta * COMMIT_WIDTH)-1:0]     rob_commit_entry_uop_dbg;
    wire [COMMIT_WIDTH-1:0]                     rob_commit_entry_uop_flush_pipe;
    assign {rob_commit_entry_uop_diag_val,
            rob_commit_entry_uop_dest_areg,
            rob_commit_entry_uop_dest_preg,
            rob_commit_entry_uop_old_dest_preg,
            rob_commit_entry_uop_ftq_idx,
            rob_commit_entry_uop_ftq_offset,
            rob_commit_entry_uop_ftq_is_last,
            rob_commit_entry_uop_mispred,
            rob_commit_entry_uop_br_taken,
            rob_commit_entry_uop_dest_en,
            rob_commit_entry_uop_func7,
            rob_commit_entry_uop_rob_idx,
            rob_commit_entry_uop_rob_flag,
            rob_commit_entry_uop_stq_idx,
            rob_commit_entry_uop_stq_flag,
            rob_commit_entry_uop_page_fault_inst,
            rob_commit_entry_uop_page_fault_load,
            rob_commit_entry_uop_page_fault_store,
            rob_commit_entry_uop_illegal_inst,
            rob_commit_entry_uop_type,
            rob_commit_entry_uop_tma,
            rob_commit_entry_uop_dbg,
            rob_commit_entry_uop_flush_pipe} = rob_commit_entry_uop;

    wire                     rob_bcast_flush;
    wire                     rob_bcast_mret;
    wire                     rob_bcast_sret;
    wire                     rob_bcast_ecall;
    wire                     rob_bcast_exception;
    wire                     rob_bcast_fence;
    wire                     rob_bcast_fence_i;
    wire                     rob_bcast_page_fault_inst;
    wire                     rob_bcast_page_fault_load;
    wire                     rob_bcast_page_fault_store;
    wire                     rob_bcast_illegal_inst;
    wire                     rob_bcast_interrupt;
    wire [31:0]              rob_bcast_trap_val;
    wire [31:0]              rob_bcast_pc;
    wire [ROB_IDX_WIDTH-1:0] rob_bcast_head_rob_idx;
    wire                     rob_bcast_head_valid;
    wire [ROB_IDX_WIDTH-1:0] rob_bcast_head_incomplete_rob_idx;
    wire                     rob_bcast_head_incomplete_valid;
    assign {rob_bcast_flush, rob_bcast_mret, rob_bcast_sret,
            rob_bcast_ecall, rob_bcast_exception, rob_bcast_fence,
            rob_bcast_fence_i, rob_bcast_page_fault_inst,
            rob_bcast_page_fault_load, rob_bcast_page_fault_store,
            rob_bcast_illegal_inst, rob_bcast_interrupt,
            rob_bcast_trap_val, rob_bcast_pc, rob_bcast_head_rob_idx,
            rob_bcast_head_valid, rob_bcast_head_incomplete_rob_idx,
            rob_bcast_head_incomplete_valid} = rob_bcast;

    wire                     dec_bcast_mispred;
    wire [BR_MASK_WIDTH-1:0] dec_bcast_br_mask;
    wire [BR_TAG_WIDTH-1:0]  dec_bcast_br_id;
    wire [ROB_IDX_WIDTH-1:0] dec_bcast_redirect_rob_idx;
    wire [BR_MASK_WIDTH-1:0] dec_bcast_clear_mask;
    assign {dec_bcast_mispred, dec_bcast_br_mask, dec_bcast_br_id,
            dec_bcast_redirect_rob_idx, dec_bcast_clear_mask} = dec_bcast;

    wire [31:0] csr_status_sstatus;
    wire [31:0] csr_status_mstatus;
    wire [31:0] csr_status_satp;
    wire [1:0]  csr_status_privilege;
    assign {csr_status_sstatus, csr_status_mstatus, csr_status_satp,
            csr_status_privilege} = csr_status;

    wire [MAX_STQ_DISPATCH_WIDTH-1:0]                   dis2lsu_alloc_req;
    wire [(BR_MASK_WIDTH * MAX_STQ_DISPATCH_WIDTH)-1:0] dis2lsu_br_mask;
    wire [(3 * MAX_STQ_DISPATCH_WIDTH)-1:0]             dis2lsu_func3;
    wire [(ROB_IDX_WIDTH * MAX_STQ_DISPATCH_WIDTH)-1:0] dis2lsu_rob_idx;
    wire [MAX_STQ_DISPATCH_WIDTH-1:0]                   dis2lsu_rob_flag;
    wire [MAX_STQ_DISPATCH_WIDTH-1:0]                   dis2lsu_stq_flag;
    wire [MAX_LDQ_DISPATCH_WIDTH-1:0]                   dis2lsu_ldq_alloc_req;
    wire [(LDQ_IDX_WIDTH * MAX_LDQ_DISPATCH_WIDTH)-1:0] dis2lsu_ldq_idx;
    wire [(BR_MASK_WIDTH * MAX_LDQ_DISPATCH_WIDTH)-1:0] dis2lsu_ldq_br_mask;
    wire [(ROB_IDX_WIDTH * MAX_LDQ_DISPATCH_WIDTH)-1:0] dis2lsu_ldq_rob_idx;
    wire [MAX_LDQ_DISPATCH_WIDTH-1:0]                   dis2lsu_ldq_rob_flag;
    assign {dis2lsu_alloc_req, dis2lsu_br_mask, dis2lsu_func3,
            dis2lsu_rob_idx, dis2lsu_rob_flag, dis2lsu_stq_flag,
            dis2lsu_ldq_alloc_req, dis2lsu_ldq_idx, dis2lsu_ldq_br_mask,
            dis2lsu_ldq_rob_idx, dis2lsu_ldq_rob_flag} = dis2lsu;

    wire [(LSU_AGU_COUNT + LSU_SDU_COUNT)-1:0] exe2lsu_req_valid;
    wire [(W_ExeLsuReqUop * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop;
    assign {exe2lsu_req_valid, exe2lsu_req_uop} = exe2lsu;
    wire [(32 * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_result;
    wire [(PRF_IDX_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_dest_preg;
    wire [(3 * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_func3;
    wire [(7 * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_func7;
    wire [(LSU_AGU_COUNT + LSU_SDU_COUNT)-1:0]
        exe2lsu_req_uop_is_atomic;
    wire [(BR_MASK_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_br_mask;
    wire [(ROB_IDX_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_rob_idx;
    wire [(STQ_IDX_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_stq_idx;
    wire [(LSU_AGU_COUNT + LSU_SDU_COUNT)-1:0]
        exe2lsu_req_uop_stq_flag;
    wire [(LDQ_IDX_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_ldq_idx;
    wire [(LSU_AGU_COUNT + LSU_SDU_COUNT)-1:0]
        exe2lsu_req_uop_rob_flag;
    wire [(LSU_AGU_COUNT + LSU_SDU_COUNT)-1:0]
        exe2lsu_req_uop_dest_en;
    wire [(UOP_TYPE_WIDTH * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_op;
    wire [(W_DebugMeta * (LSU_AGU_COUNT + LSU_SDU_COUNT))-1:0]
        exe2lsu_req_uop_dbg;
    assign {exe2lsu_req_uop_result, exe2lsu_req_uop_dest_preg,
            exe2lsu_req_uop_func3, exe2lsu_req_uop_func7,
            exe2lsu_req_uop_is_atomic, exe2lsu_req_uop_br_mask,
            exe2lsu_req_uop_rob_idx, exe2lsu_req_uop_stq_idx,
            exe2lsu_req_uop_stq_flag, exe2lsu_req_uop_ldq_idx,
            exe2lsu_req_uop_rob_flag, exe2lsu_req_uop_dest_en,
            exe2lsu_req_uop_op, exe2lsu_req_uop_dbg} = exe2lsu_req_uop;

    wire        peripheral_resp_is_mmio;
    wire        peripheral_resp_ready;
    wire [31:0] peripheral_resp_mmio_rdata;
    assign {peripheral_resp_is_mmio, peripheral_resp_ready,
            peripheral_resp_mmio_rdata} = peripheral_resp;

    wire [W_DCacheRespPorts-1:0] dcache2lsu_resp_ports;
    wire                         dcache2lsu_mshr_fill;
    assign {dcache2lsu_resp_ports, dcache2lsu_mshr_fill} = dcache2lsu;

    wire [(W_MMUResp * LSU_LDU_COUNT)-1:0] mmu2lsu_ldq_resp;
    wire [(W_MMUResp * LSU_STA_COUNT)-1:0] mmu2lsu_stq_resp;
    assign {mmu2lsu_ldq_resp, mmu2lsu_stq_resp} = mmu2lsu_io;

    wire [STQ_IDX_WIDTH-1:0] lsu2dis_stq_tail;
    wire                     lsu2dis_stq_tail_flag;
    wire [W_STQ_COUNT-1:0]   lsu2dis_stq_free;
    wire [W_LDQ_COUNT-1:0]   lsu2dis_ldq_free;
    wire [(LDQ_IDX_WIDTH * MAX_LDQ_DISPATCH_WIDTH)-1:0]
        lsu2dis_ldq_alloc_idx;
    wire [MAX_LDQ_DISPATCH_WIDTH-1:0] lsu2dis_ldq_alloc_valid;
    assign {lsu2dis_stq_tail, lsu2dis_stq_tail_flag, lsu2dis_stq_free,
            lsu2dis_ldq_free, lsu2dis_ldq_alloc_idx,
            lsu2dis_ldq_alloc_valid} = lsu2dis;

    wire [ROB_NUM-1:0] lsu2rob_tma_miss_mask;
    wire               lsu2rob_committed_store_pending;
    assign {lsu2rob_tma_miss_mask,
            lsu2rob_committed_store_pending} = lsu2rob;

    wire [(LSU_LOAD_WB_WIDTH + LSU_STA_COUNT)-1:0] lsu2exe_wb_req_valid;
    wire [(W_LsuExeRespUop * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop;
    assign {lsu2exe_wb_req_valid, lsu2exe_wb_req_uop} = lsu2exe;
    wire [(32 * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_diag_val;
    wire [(32 * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_result;
    wire [(PRF_IDX_WIDTH * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_dest_preg;
    wire [(BR_MASK_WIDTH * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_br_mask;
    wire [(ROB_IDX_WIDTH * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_rob_idx;
    wire [(LSU_LOAD_WB_WIDTH + LSU_STA_COUNT)-1:0]
        lsu2exe_wb_req_uop_dest_en;
    wire [(LSU_LOAD_WB_WIDTH + LSU_STA_COUNT)-1:0]
        lsu2exe_wb_req_uop_page_fault_load;
    wire [(LSU_LOAD_WB_WIDTH + LSU_STA_COUNT)-1:0]
        lsu2exe_wb_req_uop_page_fault_store;
    wire [(UOP_TYPE_WIDTH * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_op;
    wire [(W_DebugMeta * (LSU_LOAD_WB_WIDTH + LSU_STA_COUNT))-1:0]
        lsu2exe_wb_req_uop_dbg;
    wire [(LSU_LOAD_WB_WIDTH + LSU_STA_COUNT)-1:0]
        lsu2exe_wb_req_uop_flush_pipe;
    assign {lsu2exe_wb_req_uop_diag_val, lsu2exe_wb_req_uop_result,
            lsu2exe_wb_req_uop_dest_preg, lsu2exe_wb_req_uop_br_mask,
            lsu2exe_wb_req_uop_rob_idx, lsu2exe_wb_req_uop_dest_en,
            lsu2exe_wb_req_uop_page_fault_load,
            lsu2exe_wb_req_uop_page_fault_store,
            lsu2exe_wb_req_uop_op, lsu2exe_wb_req_uop_dbg,
            lsu2exe_wb_req_uop_flush_pipe} = lsu2exe_wb_req_uop;

    wire        peripheral_req_is_mmio;
    wire        peripheral_req_wen;
    wire [31:0] peripheral_req_mmio_addr;
    wire [31:0] peripheral_req_mmio_wdata;
    wire [2:0]  peripheral_req_mmio_fun3;
    assign {peripheral_req_is_mmio, peripheral_req_wen,
            peripheral_req_mmio_addr, peripheral_req_mmio_wdata,
            peripheral_req_mmio_fun3} = peripheral_req;

    wire [W_DCacheReqPorts-1:0] lsu2dcache_req_ports;
    wire [LSU_LDU_WIDTH:0]      lsu2dcache_icache_req;
    assign {lsu2dcache_req_ports, lsu2dcache_icache_req} = lsu2dcache;

    wire [(W_MMUReq * LSU_LDU_COUNT)-1:0] lsu2mmu_ldq_req;
    wire [(W_MMUReq * LSU_STA_COUNT)-1:0] lsu2mmu_stq_req;
    wire [W_CsrStatusIO-1:0]              lsu2mmu_csr_status;
    assign {lsu2mmu_ldq_req, lsu2mmu_stq_req,
            lsu2mmu_csr_status} = lsu2mmu_io;

    assign pi =
        {rob_commit, rob_bcast, dec_bcast, csr_status, dis2lsu, exe2lsu,
         peripheral_resp, dcache2lsu, mmu2lsu_io};
    assign {lsu2dis, lsu2rob, lsu2exe, peripheral_req, lsu2dcache,
            lsu2mmu_io} = po;

    lsu_bsd_top #(
        .W_LsuIn(W_LsuIn),
        .W_LsuOut(W_LsuOut)
    ) u_lsu_bsd_top (
        .pi(pi),
        .po(po)
    );

endmodule
