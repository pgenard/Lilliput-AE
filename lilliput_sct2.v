`timescale 1ns/1ps

module lilliput_sct2 (
    input wire clk,
    input wire rst_n,
    input wire start,

    input wire[127:0] key,
    input wire[119:0] nonce,
    input wire[127:0] associated_data,
    input wire[127:0] plaintext,

    // Input lengths in bytes.
    // Currently supported: 0 and 16.
    input wire[4:0] associated_data_len,
    input wire[4:0] plaintext_len,

    output reg[127:0] ciphertext,
    output reg[127:0] tag,

    output reg busy,
    output reg done
);

// --------------------------------------------------
// State machine
// --------------------------------------------------

localparam IDLE      = 4'd0;
localparam AD_START  = 4'd1;
localparam AD_WAIT   = 4'd2;
localparam MSG_START = 4'd3;
localparam MSG_WAIT  = 4'd4;
localparam TAG_START = 4'd5;
localparam TAG_WAIT  = 4'd6;
localparam ENC_START = 4'd7;
localparam ENC_WAIT  = 4'd8;

reg[3:0] state;

// --------------------------------------------------
// Input registers
// --------------------------------------------------

reg[127:0] key_reg;
reg[119:0] nonce_reg;

reg[127:0] ad_reg;
reg[127:0] plaintext_reg;

reg[4:0] ad_len_reg;
reg[4:0] plaintext_len_reg;

// --------------------------------------------------
// Intermediate values
// --------------------------------------------------

reg[127:0] auth_reg;
reg[127:0] tag_tmp_reg;
reg[127:0] padded_nonce;

// --------------------------------------------------
// TBC interface
// --------------------------------------------------

reg[127:0] tbc_tweak;
reg[127:0] tbc_data;

wire[127:0] tbc_result;

wire tbc_busy;
wire tbc_done;

reg tbc_start;

reg[127:0] tbc_tweak_reg;
reg[127:0] tbc_data_reg;

// --------------------------------------------------
// TBC core
// --------------------------------------------------

lilliput_tbc_128 u_tbc (
    .clk(clk),
    .rst_n(rst_n),
    .start(tbc_start),
    .key(key_reg),
    .tweak(tbc_tweak_reg),
    .data_in(tbc_data_reg),
    .data_out(tbc_result),
    .busy(tbc_busy),
    .done(tbc_done)
);


// --------------------------------------------------
// TBC input selection
//
// Byte zero occupies the least significant byte.
// --------------------------------------------------

wire[127:0] tag_reg_for_tweak;

assign tag_reg_for_tweak = tag | 128'h00000000000000000000000000000080;

always @(*) begin
    tbc_tweak = 128'b0;
    tbc_data  = 128'b0;

    case (state)

        AD_START: begin
            tbc_tweak = 128'h00000000000000000000000000000020;
            tbc_data  = ad_reg;
        end

        MSG_START: begin
            tbc_tweak = 128'b0;
            tbc_data  = plaintext_reg;
        end

        TAG_START: begin
            tbc_tweak = {nonce_reg, 8'h10};
            tbc_data  = tag_tmp_reg;
        end

        ENC_START: begin
            tbc_tweak = tag_reg_for_tweak;
            tbc_data  = padded_nonce;
        end

        default: begin
            tbc_tweak = 128'b0;
            tbc_data  = 128'b0;
        end
    endcase
end // always @ (*)

// --------------------------------------------------
// SCT-2 controller
// --------------------------------------------------

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        key_reg <= 128'b0;
        nonce_reg <= 120'b0;
        ad_reg <= 128'b0;
        plaintext_reg <= 128'b0;
        ad_len_reg <= 5'b0;
        plaintext_len_reg <= 5'b0;
        auth_reg <= 128'b0;
        tag_tmp_reg <= 128'b0;
        padded_nonce <= 128'b0;
        ciphertext <= 128'b0;
        tag <= 128'b0;
        busy <= 1'b0;
        done <= 1'b0;
        tbc_start <= 1'b0;
    end

    else begin
        done <= 1'b0;
        tbc_start <= 1'b0;
       
        case (state)
            // --------------------------------------
            // IDLE
            // --------------------------------------

            IDLE: begin
                busy <= 1'b0;

                if (start) begin
                    key_reg <= key;
                    nonce_reg <= nonce;
                    ad_reg <= associated_data;
                    plaintext_reg <= plaintext;
                    ad_len_reg <= associated_data_len;
                    plaintext_len_reg <= plaintext_len;
                    padded_nonce <= {nonce, 8'h00};
                    auth_reg <= 128'b0;
                    tag_tmp_reg <= 128'b0;
                    ciphertext <= 128'b0;
                    tag <= 128'b0;
                    busy <= 1'b1;
                    state <= AD_START;
                end
            end

            // --------------------------------------
            // Associated-data authentication
            // --------------------------------------

	  AD_START: begin
    if (ad_len_reg == 0) begin
        auth_reg <= 128'b0;
        state <= MSG_START;
    end
    else begin
        tbc_tweak_reg <= tbc_tweak;
        tbc_data_reg  <= tbc_data;
        tbc_start <= 1'b1;
        state <= AD_WAIT;
    end
end


            AD_WAIT: begin
                if (tbc_done) begin
                    auth_reg <= tbc_result;
                    state <= MSG_START;
                end
            end

            // --------------------------------------
            // Message authentication
            // --------------------------------------

MSG_START: begin
    if (plaintext_len_reg == 0) begin
        tag_tmp_reg <= auth_reg;
        state <= TAG_START;
    end
    else begin
        tbc_tweak_reg <= tbc_tweak;
        tbc_data_reg  <= tbc_data;
        tbc_start <= 1'b1;
        state <= MSG_WAIT;
    end
end

            MSG_WAIT: begin
                if (tbc_done) begin
                    tag_tmp_reg <= auth_reg ^ tbc_result;
                    state <= TAG_START;
                end
            end

            // --------------------------------------
            // Final authentication tag
            // --------------------------------------

TAG_START: begin
    tbc_tweak_reg <= tbc_tweak;
    tbc_data_reg  <= tbc_data;
    tbc_start <= 1'b1;
    state <= TAG_WAIT;
end

            TAG_WAIT: begin
                if (tbc_done) begin
                    tag <= tbc_result;
                    state <= ENC_START;
                end
            end

            // --------------------------------------
            // Message encryption
            // --------------------------------------

ENC_START: begin
    if (plaintext_len_reg == 0) begin
        ciphertext <= 128'b0;
        busy <= 1'b0;
        done <= 1'b1;
        state <= IDLE;
    end
    else begin
        tbc_tweak_reg <= tbc_tweak;
        tbc_data_reg  <= tbc_data;
        tbc_start <= 1'b1;
        state <= ENC_WAIT;
    end
end

            ENC_WAIT: begin
                if (tbc_done) begin
                    ciphertext <= plaintext_reg ^ tbc_result;
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end
            end

            // --------------------------------------
            // Default recovery
            // --------------------------------------

            default: begin
                state <= IDLE;
                busy <= 1'b0;
            end
        endcase
    end
end

endmodule // lilliput_sct2
