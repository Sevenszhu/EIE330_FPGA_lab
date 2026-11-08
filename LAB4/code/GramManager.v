module GramManager (
    input  wire        sw,
    input  wire        clk,
    input  wire        reboot,
    input  wire [6:0]  blockx,
    input  wire [5:0]  blocky,
    output reg  [15:0] rgb
);

reg [1:0] pages = 0;
reg sw_old = 0;

always @(posedge clk or negedge reboot) begin
    if (!reboot) begin
        pages  <= 0;
    end else begin
        sw_old <= sw;
        if (sw && !sw_old) begin
            if (pages >= 2)
                pages <= 0;
            else
                pages <= pages + 1;
        end
    end
end

//以下字模为ai编写，同理我并不认为人手写这玩意有多么高端



// MUST字模
function must_pixel;
    input [6:0] x;
    input [5:0] y;

    begin
        must_pixel = 0;

        if ((y >= 31) && (y <= 37)) begin
            // M
            if ((x == 45) || (x == 49) ||
                ((y == 32) && ((x == 46) || (x == 48))) ||
                ((y == 33) && (x == 47)))
                must_pixel = 1;

            // U
            if ((((x == 52) || (x == 56)) && (y < 37)) ||
                ((y == 37) && (x >= 53) && (x <= 55)))
                must_pixel = 1;

            // S
            if ((((y == 31) || (y == 34) || (y == 37)) &&
                 (x >= 59) && (x <= 63)) ||
                (((y == 32) || (y == 33)) && (x == 59)) ||
                (((y == 35) || (y == 36)) && (x == 63)))
                must_pixel = 1;

            // T
            if (((y == 31) && (x >= 66) && (x <= 70)) ||
                ((y > 31) && (x == 68)))
                must_pixel = 1;
        end
    end
endfunction

// END字模
function end_pixel;
    input [6:0] x;
    input [5:0] y;

    begin
        end_pixel = 0;

        if ((y >= 31) && (y <= 37)) begin
            // E
            if ((x == 49) ||
                (((y == 31) || (y == 34) || (y == 37)) &&
                 (x >= 49) && (x <= 53)))
                end_pixel = 1;

            // N
            if ((x == 56) || (x == 60) ||
                (((y == 32) || (y == 33)) && (x == 57)) ||
                ((y == 34) && (x == 58)) ||
                (((y == 35) || (y == 36)) && (x == 59)))
                end_pixel = 1;

            // D
            if ((x == 63) ||
                (((y == 31) || (y == 37)) &&
                 (x >= 63) && (x <= 66)) ||
                ((x == 67) && (y > 31) && (y < 37)))
                end_pixel = 1;
        end
    end
endfunction

// 根据当前页面输出RGB565颜色
always @(*) begin
    rgb = 16'h0000;

    case (pages)
        // 页面0：竖直彩条
        0: begin
            if      (blockx < 27) rgb = 16'hf800; // 红
            else if (blockx < 36) rgb = 16'hfc00; // 橙
            else if (blockx < 45) rgb = 16'hffe0; // 黄
            else if (blockx < 54) rgb = 16'h07e0; // 绿
            else if (blockx < 63) rgb = 16'h07ff; // 青
            else if (blockx < 72) rgb = 16'h001f; // 蓝
            else if (blockx < 81) rgb = 16'h8010; // 紫
            else if (blockx < 90) rgb = 16'h0000; // 黑
            else                  rgb = 16'hffff; // 白
        end

        // 页面1：MUST
        1: begin
            if (must_pixel(blockx, blocky))
                rgb = 16'hffff;
            else
                rgb = 16'h0000;
        end

        // 页面2：END
        2: begin
            if (end_pixel(blockx, blocky))
                rgb = 16'hffff;
            else
                rgb = 16'h0000;
        end

        default: begin
            rgb = 16'h0000;
        end
    endcase
end

endmodule
