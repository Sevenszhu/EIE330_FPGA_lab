这次没有新的物理层我真的逼逼不了多少了，再给王处bb几句vga得了

直接劫持我们的rgb显存访存通道即可，或者换个说法，vga模块只标准化串行像素流，他就是个节拍器

按钮每次下降沿进入冷却，冷却期间pluse是高电平，冷却后需要btn处于高电平才能释放

字模依旧给ai写，懒得手搓

高内聚低耦合依旧做的很强了，也就几个常量是硬编码

因为不管一页搞没搞完都会直接切画面所以说必然会有撕裂，人眼不一定看出来
消隐区依旧未定义行为，随便吧，能跑就行

王泽死爹妈，依旧忍不住骂他 begin

傻逼模拟器直接吃满一个核跑线程，但凡电脑差点的直接给cpu干飞，里面sleep几个ns真心不如while轮询
依旧60帧狗屁没有，用cpu当fpga哪怕我的i9 14900都扛不住
撕裂是正常的，没有实际板子傻逼软件又有调度问题，谁也说不好观感到底是因为谁变烂的
有时候按键都按不下去，这种死妈软件写出来真是献祭双亲啊
傻逼仿真器会主动丢按键输入操作，写出来真是献祭双亲啊
这也就是为什么按了35秒

end


我只给代码，让ai自己分析状态机去，王处肯定会对这个意淫到高潮
yosys在这，依旧初见端倪了，速度慢一点的fpga没准真的会炸
lut4的，花了164个，周围但凡扇出的狠一点时序就有危险
=== top ===

   Number of wires:                162
   Number of wire bits:            388
   Number of public wires:          35
   Number of public wire bits:     160
   Number of ports:                  6
   Number of port bits:             21
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:                214
     $_DFFE_PN0P_                   23
     $_DFF_P_                        2
     $_SDFFCE_PP0P_                  2
     $_SDFFE_PN0N_                  10
     $_SDFF_PP0_                    10
     $lut                          164
     $scopeinfo                      3






记得让gpt大爹多画几张svg，王泽看到svg得颅内高潮
