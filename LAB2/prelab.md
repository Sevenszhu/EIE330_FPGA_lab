

1.设计早期调查（这段算提示词，别直接贴report）
这地方适合逼逼几句板子上的有源晶振，有源晶振一般都是lvcmos33的，要是愿意水多逼逼几句有源晶振温飘和阻抗

也可以逼逼几句为什么不用无源晶振，不用无源晶振的原因大概率就是这无源晶振需要特殊物理层，起振参数不好配置

多逼逼几句cyclone4的内部时钟网络也行，虽然不上板子，有人确实喜欢这种没有营养的废话

之后多给逼逼几句位移寄存器是啥，虽然我没用真的位移寄存器，用的是状态机

不消抖，也没必要消抖

step1里面问的一堆狗屁问题，ai最好先把这个prelab读完再回答

2.准备fpga代码
50mhz对一般时序电路不算很慢了，如果多叠几层逻辑或者fpga内部有高扇出模块确实有很大概率把pnr的时序炸掉
但是时序依旧不是应该考虑的事情，因为就几个逻辑门，约束不写也未尝不可（更何况没有实际板子）

框图很简单，时钟输入，同步复位后只有led输出


3:代码

module blink #(
    parameter INIT_LED_HIZ = 1'b0
)(
    input  wire clk,
    input  wire rst_n,
    output wire led,
    output wire [24:0] debug_counter
);

    reg [24:0] counter;//这里和王泽逼逼几句怎么选的，2的25次幂大概是33M
    reg        stage;

    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 25'd0;
            stage   <= INIT_LED_HIZ;
        end else if (counter == 25'd24999999) begin
            counter <= 25'd0;
            stage   <= ~stage;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    assign led           = stage;
    assign debug_counter = counter;

endmodule
宏等于1的时候上电或者复位是hiz（或者推挽高电平），引脚约束建议使用开漏模式（其实不用也不是不行）


module runningLED #(
    parameter INIT_LED_HIZ  = 1'b1,
    parameter INVERSE_OUTPUT = 1'b1
)(
    input  wire       clk,
    input  wire       rst_n,
    output wire [3:0] led,
    output wire [24:0] debug_counter
);

    reg [24:0] counter;
    reg [3:0]  state;

    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 25'd0;
            state   <= 4'b0001;
        end else if (counter == 25'd24_999_999) begin
            counter <= 25'd0;

            if (state == 4'b1000)
                state <= 4'b0001;
            else
                state <= state << 1;
        end else begin
            counter <= counter + 1'b1;
        end
    end

wire [3:0] led_state;

assign led_state = state ^ {4{INVERSE_OUTPUT}};
assign led       = !rst_n ? {4{INIT_LED_HIZ}} : led_state;
assign debug_counter = counter;

endmodule


4:仿真
一块跟着里面的文件发出去了
vcd，csv都在，报告里面有必要给一份文件的sha256做保险
vcd仿真确实操蛋，全部仿真后直接GB起步，我只给sha256，i9的14900单核跑这个玩意也得几分钟
csv是用ai改的，只给了10ms的间隔
sh脚本也是ai写的，我认为课程没有必要也不应该拒绝ai写的固定时间戳的脚本
如果非要杠，那确实很杠精了
我并不认为我需要上传完整vcd，谁需要谁举证，反正sha256我贴出来了，跑得了和尚跑不了庙

0eee47da67e30a9e6005d0513e1a69ab1a9356326558b6337ab009269ad2faf4  blink_tb.vcd
32d165dac0a5387f3808e3e7e12431ad50647c75b20618ce2381c2b74a07a4d5  runningLED_tb.vcd



视频在文件夹，不是500ms很正常，差不多匀速就行，靠linux调度的玩意能闪起来就行，记得解释清楚



（说两句题外话，王泽这垃圾玩意是阻塞的，即使是lab1里面的组合逻辑，直接跑满单核，仿真50mhz遇上pc上linux调度也是相当幽默，所以说必然不是500ms一次
这个逼办法没有）
5:时序分析
当放屁就行，示波器都测不准，几个时序电路不至于彻底把时序炸掉，因为always块里面没有踩着边沿输出更快边沿的玩意，炸不了
电脑仿真更是幽默中的幽默，我不知道怎么骂了
