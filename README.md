# （七）零基础FPGA图像处理——HDMI彩条显示实验
# 0 致读者


此篇为专栏 **《FPGA学习笔记》** 的第七篇，记录我的学习FPGA的一些开发过程和心得感悟，刚接触FPGA的朋友们可以先去此专栏置顶 [《FPGA零基础入门学习路线》](http://t.csdnimg.cn/T0Qw2)来做最基础的扫盲。

本篇内容基于笔者实际开发过程和正点原子资料撰写，将会详细讲解此FPGA实验的全流程，**诚挚**地欢迎各位读者在评论区或者私信我交流！


本文的工程文件**开源地址**如下（基于ZYNQ7020，大家 **clone** 到本地就可以直接跑仿真，如果要上板请根据自己的开发板更改约束即可）：

> [https://github.com/ChinaRyan666/FPGA-HDMI-Colorbor](https://github.com/ChinaRyan666/FPGA-HDMI-Colorbor)
# 1 实验任务

**HDMI 接口**在消费类电子行业，如电脑、液晶电视、 投影仪等产品中得到了广泛的应用。一些专业的视频设备如摄像机、视频切换器等也都集成了 HDMI 接口。本文我们将学习如何在 **ZYNQ** 开发板上的驱动 **HDMI 接口**。

本文的实验任务是驱动 **ZYNQ** 开发板上的 **HDMI 接口**， 在显示器上显示 **720p** 彩条图案（720p 分辨率为 1280*800，像素时钟大约为 75MHz）。




# 2 HDMI 简介

**HDMI** 是新一代的多媒体接口标准， 英文全称是 **High-Definition Multimedia Interface**， 即**高清多媒体接口**。 它能够同时传输视频和音频，简化了设备的接口和连线；同时提供了更高的数据传输带宽， 可以传输无压缩的数字音频及高分辨率视频信号。

>HDMI 1.0 版本于 2002 年发布， 最高数据传输速度为 5Gbps； HDMI 2.0版本于 2013 年推出的， 2.0 理论传输速度能达到 18Gbit/s，实际传输速度能达到14.4Gbit/s； 而 2017 年发布的 HDMI 2.1 标准的理论带宽可达 48Gbps，实际速度也能达到 42.6Gbit/s。

不过在 **HDMI 接口**出现之前，被广泛应用的是 **VGA 接口**。 **VGA** 的全称是 **Video Graphics Array**，即视频图形阵列，是一个使用模拟信号进行视频传输的标准。 VGA 接口采用 15 针插针式结构，里面传输模拟信号颜色分量、同步等信号，是很多老显卡、笔记本和投影仪所使用的接口。**由于 VGA 接口传输的是模拟信号，其信号容易受到干扰**，因此 VGA 在高分辨率下字体容易虚，信号线长的话，图像有拖尾现象。 

**VGA 接口**由下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/0cfff80dc188461b946c60924e023943.png)


**VGA 接口**除信号容易受到干扰外，其体积也较大，因此 **VGA 接口**已逐渐退出舞台，一些显示器也不再带有 **VGA 接口**，在数字设备高度发展的今天，取而代之的是 **HDMI 接口**和 **DP（Display Port）接口**等。

**HDMI** 向下兼容 **DVI**，但是 **DVI（数字视频接口）** 只能用来传输视频，而**不能同时传输音频**， 这是两者最主要的差别。此外， **DVI 接口**的尺寸明显大于 **HDMI 接口**，如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/a8b639e427a04a779aced622d9c0439f.png)


上图右侧是生活中最常见的 **A 型 HDMI 接口**，其引脚定义如下图所示：


![在这里插入图片描述](https://img-blog.csdnimg.cn/6503a826e48d470fa6f4a28e1aa1fdc3.png)


**DVI** 和 **HDMI 接口**协议在物理层使用 **TMDS** 标准传输音视频数据。 **TMDS**（ Transition Minimized Differential Signaling，最小化传输差分信号）是美国 Silicon Image 公司开发的一项高速数据传输技术，在 **DVI** 和 **HDMI** 视频接口中使用差分信号传输高速串行数据。 **TMDS** 差分传输技术使用两个引脚（如上图中的“数据 2+”和“数据 2-”） 来传输一路信号，利用这两个引脚间的电压差的正负极性和大小来决定传输数据的数值（0 或 1）。

**Xilinx** 在 **Spartan-3A** 系列之后的器件中，加入了对 **TMDS** 接口标准的支持， 用于在 FPGA 内部实现 **DVI** 和 **HDMI 接口**。

>由于本次实验只是使用 **HDMI 接口**来显示图像， 不需要传输音频，因此我们只需要实现 **DVI 接口**的驱动逻辑即可。不过在此之前我们还需要简单地了解一下 **TMDS 视频传输协议**。

下图是 **TMDS** 发送端和接收端的连接示意图， **DVI** 或 **HDMI** 视频传输所使用的 **TMDS** 连接通过四个串行通道实现。 对于 **DVI** 来说， 其中三个通道分别用于传输视频中每个像素点的红、绿、蓝三个颜色分量（**RGB 4:4:4 格式**）。 **HDMI** 默认也是使用三个 **RGB** 通道，但是它同样可以选择传输像素点的亮度和色度信息（**YCrCb 4:4:4 或 YCrCb 4:2:2 格式**）。第四个通道是时钟通道， 用于传输像素时钟。 独立的 **TMDS** 时钟通道为接收端提供接收的参考频率，保证数据在接收端能够正确恢复。


![在这里插入图片描述](https://img-blog.csdnimg.cn/704cbcbc43ce4a728e07bff798fe1217.png)


如果每个像素点的**颜色深度为 24 位**，即 **RGB** 每个颜色分量**各占 8 位**，那么每个通道上的颜色数据将通过编码器来转换成一个 **10 位**的像素字符。然后这个 10 位的字符通过**并串转换器**转换成**串行**数据，最后由 **TMDS** 数据通道发送出去。这个 **10:1** 的并转串过程所生成的串行数据速率是**实际像素时钟速率的 10 倍**。

>在传输视频图像的过程中， **数据通道**上传输的是编码后的有效像素字符。而在每一帧图像的行与行之间， 以及视频中不同帧之间的时间间隔（消隐期） 内， **数据通道**上传输的则是控制字符。每个通道上有两位控制信号的输入接口，共对应四种不同的控制字符。这些控制字符提供了视频的**行同步（HSYNC）** 以及**帧同步（VSYNC）** 信息， 也可以用来指定所传输数据的边界（用于同步） 。

对于 DVI 传输，整个视频的消隐期都用来传输控制字符。 而 HDMI 传输的消隐期除了控制字符之外，还可以用于传输音频或者其他附加数据，比如字幕信息等。 这就是 **DVI** 和 **HDMI** 协议之间最主要的差别。从上图中也可以看出这一差别， 即 **“Auxiliary Data”** 接口标有 **“HDMI Only”** ，即它是 HDMI 所独有的接口。

从前面的介绍中我们可以看出， **TMDS** 连接从逻辑功能上可以划分成两个阶段：**编码**和**并串转换**。在编码阶段， 编码器将视频源中的像素数据、 HDMI 的音频/附加数据， 以及行同步和场同步信号**分别编码成 10 位的字符流**。 然后在并串转换阶段将上述的字符**流转换成串行数据流**， 并将其**从三个差分输出通道发送出去**。

**DVI 编码器**在视频有效数据段输出像素数据，在消隐期输出控制数据， 如下图所示。 其中 **VDE（Video Data Enable）**为高电平时表示视频数据有效， 为低电平代表当前处于视频消隐期。

![在这里插入图片描述](https://img-blog.csdnimg.cn/8329a63cf34a44df83cea88b2750cf2a.png)

下图给出了三个通道的 **DVI 编码器**示意图。对于像素数据的 **RGB** 三个颜色通道，编码器的逻辑是完全相同的。 **VDE** 用于各个通道选择输出**视频像素数据**还是**控制数据**， **HSYNC** 和 **VSYNC** 信号在蓝色通道进行编码得到 **10** 位字符， 然后在视频消隐期传输。 绿色和红色通道的控制信号 **C0** 和 **C1** 同样需要进行编码， 并在消隐期输出。但是 **DVI** 规范中这两个通道的控制信号是预留的（未用到） ，因此将其置为 2’b00。

![在这里插入图片描述](https://img-blog.csdnimg.cn/8466c1228cd84117a68f376e1e199bd2.png)


每个通道输入的视频像素数据都要使用 **DVI** 规范中的 **TMDS** 编码算法进行编码。每个 **8-bit** 的数据都将被转换成 460 个特定 **10-bit** 字符中的一个。这个编码机制大致上实现了传输过程中的直流平衡，即一段时间内传输的高电平（数字 “1”）的个数大致等于低电平（数字 “0”） 的个数。 同时，每个编码后的 **10-bit** 字符中状态跳转（“由 1 到 0”或者“由 0 到 1” ） 的次数将被限制在五次以内。

除了视频数据之外， 每个通道 **2-bit** 控制信号的状态也要进行编码，编码后分别对应四个不同的 **10-bit** 控制字符，分别是 10'b1101010100， 10'b0010101011， 10'b0101010100， 和 10'b1010101011。 可以看出，每个控制字符都有七次以上的状态跳转。 **视频字符**和**控制字符**状态跳转次数的不同将会被用于发送和接收设备的同步。

>**HDMI** 协议与 **DVI** 协议在很多方面都是相同的， 包括物理连接（**TMDS**）、有效视频编码算法以及控制字符的定义等。 但是，相比于 **DVI**， **HDMI** 在视频的消隐期会传输更多的数据， 包括音频数据和附加数据。**4-bit** 音频和附加数据将通过 **TERC4** 编码机制转换成 **10-bit TERC4** 字符， 然后在绿色和红色通道上传输。

**HDMI** 在输入附加数据的同时，还需要输入 **ADE**（Aux/Audio Data Enable）信号，其作用和 **VDE** 是类似的： 当 **ADE** 为高电平时，表明输入端的附加数据或者音频数据有效。 为了简单起见，我们在这里把 **HDMI** 接口当作 **DVI** 接口进行驱动。

在编码之后 3 个通道的 **10-bit** 字符将进行并串转换，这一过程是使用 7 系列 **FPGA** 中专用的硬件资源来实现的。 **ZYNQ PL** 部分与 7 系列的 **FPGA** 是等价的， 它提供了专用的并串转换器——**OSERDESE2**。单一的 **OSERDESE2** 模块可以实现 **8:1** 的并串转换， 通过位宽扩展可以实现 10:1 和 14:1 的转换率。







# 3 程序设计

## 3.1 总体模块设计

本次实验在 [LCD 彩条显示实验](http://t.csdnimg.cn/kefzC) 的基础上添加一个 **RGB2DVI** 模块， 将 **RGB888** 格式的视频图像转换成 **TMDS** 数据输出。 本文的重点是介绍 **RGB2DVI** 模块，其余模块的介绍请参考 [LCD 彩条显示实验](http://t.csdnimg.cn/kefzC) 。

由此得出本次实验的系统框图如下所示：


![在这里插入图片描述](https://img-blog.csdnimg.cn/c99a87ec38514a1ebed62ec07f1cfb32.png)


## 3.2 RGB2DVI 模块设计

在设计 **RGB2DVI** 模块框图之前，我们先了解一下 **RGB2DVI** 顶层模块的设计框图：


![在这里插入图片描述](https://img-blog.csdnimg.cn/74ede1137dca43269e1bff41d80c41ef.png)

上图中， **Encoder** 模块负责对数据进行编码， **Serializer** 模块对编码后的数据进行并串转换，最后通过 **OBUFDS** 转化成 **TMDS** 差分信号传输。

>整个系统需要两个输入时钟，一个是视频的像素时钟 **Pixel Clk**， 另外一个时钟 **Pixel Clk x5** 的频率是像素时钟的五倍。由前面的简介部分我们知道， 并串转换过程的实现的是 **10:1** 的转换率，理论上转换器需要一个 **10** 倍像素时钟频率的串行时钟。这里我们只用了一个 **5** 倍的时钟频率，这是因为 **OSERDESE2** 模块可以实现 **DDR** 的功能，即它在五倍时钟频率的基础上又实现了双倍数据速率。

**TMDS** 连接的时钟通道我们采用与数据通道相同的并转串逻辑来实现。 通过对 **10** 位二进制序列 **10’b11111_00000** 在 **10** 倍像素时钟频率下进行并串转换，就可以得到像素时钟频率下的 **TMDS** 参考时钟。

**OSERDESE2** 模块要求复位信号高电平有效，并且需要将异步复位信号同步到并行时钟域。因此， 我们生成一个同步复位模块，将低电平有效的异步复位信号转换成高有效， 同时对其进行异步复位，同步释放处理。

另外需要注意的是，图中左下脚 HDMI 的音频/附加数据输入在本次实验中并未用到， 因此以虚线表示。

根据上述分析我们可以绘制 **RGB2DVI** 模块框图如下：

![在这里插入图片描述](https://img-blog.csdnimg.cn/dff9edcce3f84ce7bee4430887c96d41.png)

根据模块的设计分析以及我们绘制的 **RGB2DVI** 模块框图，我们可以编写 **RGB2DVI** 顶层的整体代码。 **RGB2DVI** 顶层模块就是 **RGB2DVI 驱动控制部分**的顶层模块，内部实例化**编码模块**和**并行转串行模块**，连接各自对应信号，代码编写较为简单，无需波形图绘制。

```
module dvi_transmitter_top(
    input        pclk,           // pixel clock
    input        pclk_x5,        // pixel clock x5
    input        reset_n,        // reset
    
    input [23:0] video_din,      // RGB888 video in
    input        video_hsync,    // hsync data
    input        video_vsync,    // vsync data
    input        video_de,       // data enable
    
    output       tmds_clk_p,    // TMDS 时钟通道
    output       tmds_clk_n,
    output [2:0] tmds_data_p,   // TMDS 数据通道
    output [2:0] tmds_data_n,
    output       tmds_oen       // TMDS 输出使能
    );
    
//wire define    
wire        reset;
    
//并行数据
wire [9:0]  red_10bit;
wire [9:0]  green_10bit;
wire [9:0]  blue_10bit;
wire [9:0]  clk_10bit;  
  
//串行数据
wire [2:0]  tmds_data_serial;
wire        tmds_clk_serial;

//*****************************************************
//**                    main code
//***************************************************** 
assign tmds_oen = 1'b1;  
assign clk_10bit = 10'b1111100000;

//异步复位，同步释放
asyn_rst_syn reset_syn(
    .reset_n    (reset_n),
    .clk        (pclk),
    
    .syn_reset  (reset)    //高有效
    );
  
//对三个颜色通道进行编码
dvi_encoder encoder_b (
    .clkin      (pclk),
    .rstin	    (reset),
    
    .din        (video_din[7:0]),
    .c0			(video_hsync),
    .c1			(video_vsync),
    .de			(video_de),
    .dout		(blue_10bit)
    ) ;

dvi_encoder encoder_g (
    .clkin      (pclk),
    .rstin	    (reset),
    
    .din		(video_din[15:8]),
    .c0			(1'b0),
    .c1			(1'b0),
    .de			(video_de),
    .dout		(green_10bit)
    ) ;
    
dvi_encoder encoder_r (
    .clkin      (pclk),
    .rstin	    (reset),
    
    .din		(video_din[23:16]),
    .c0			(1'b0),
    .c1			(1'b0),
    .de			(video_de),
    .dout		(red_10bit)
    ) ;
    
//对编码后的数据进行并串转换
serializer_10_to_1 serializer_b(
    .reset              (reset),                // 复位,高有效
    .paralell_clk       (pclk),                 // 输入并行数据时钟
    .serial_clk_5x      (pclk_x5),              // 输入串行数据时钟
    .paralell_data      (blue_10bit),           // 输入并行数据

    .serial_data_out    (tmds_data_serial[0])   // 输出串行数据
    );    
    
serializer_10_to_1 serializer_g(
    .reset              (reset),
    .paralell_clk       (pclk),
    .serial_clk_5x      (pclk_x5),
    .paralell_data      (green_10bit),

    .serial_data_out    (tmds_data_serial[1])
    );
    
serializer_10_to_1 serializer_r(
    .reset              (reset),
    .paralell_clk       (pclk),
    .serial_clk_5x      (pclk_x5),
    .paralell_data      (red_10bit),

    .serial_data_out    (tmds_data_serial[2])
    );
            
serializer_10_to_1 serializer_clk(
    .reset              (reset),
    .paralell_clk       (pclk),
    .serial_clk_5x      (pclk_x5),
    .paralell_data      (clk_10bit),

    .serial_data_out    (tmds_clk_serial)
    );
    
//转换差分信号  
OBUFDS #(
    .IOSTANDARD         ("TMDS_33")    // I/O电平标准为TMDS
) TMDS0 (
    .I                  (tmds_data_serial[0]),
    .O                  (tmds_data_p[0]),
    .OB                 (tmds_data_n[0]) 
);

OBUFDS #(
    .IOSTANDARD         ("TMDS_33")    // I/O电平标准为TMDS
) TMDS1 (
    .I                  (tmds_data_serial[1]),
    .O                  (tmds_data_p[1]),
    .OB                 (tmds_data_n[1]) 
);

OBUFDS #(
    .IOSTANDARD         ("TMDS_33")    // I/O电平标准为TMDS
) TMDS2 (
    .I                  (tmds_data_serial[2]), 
    .O                  (tmds_data_p[2]), 
    .OB                 (tmds_data_n[2])  
);

OBUFDS #(
    .IOSTANDARD         ("TMDS_33")    // I/O电平标准为TMDS
) TMDS3 (
    .I                  (tmds_clk_serial), 
    .O                  (tmds_clk_p),
    .OB                 (tmds_clk_n) 
);
  
endmodule
```


在 **dvi_transmitter_top** 模块中， 不仅例化了**编码模块**和**并转串模块**，同时还例化了四个 **OBUFDS** 原语， 用于将三路数据和一路时钟信号转换成差分信号输出， 如程序第 116 至 147 行所示。

**OBUFDS** 是差分输出缓冲器，用于将来自 **FPGA** 内部逻辑的信号转换成差分信号输出， 支持 **TMDS** 电平标准。 **OBUFDS 原语**示意图如下所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/784b8e0adb44494e8c771ca8800447c3.png)

## 3.3 编码模块设计


**dvi_encoder** 编码模块就是为了完成 **RGB** 图像数据 8b 转 10b 的编码，关于 8b 转 10b 编码的理论知识我们在前面的 **HDMI** 简介部分已经做了详细介绍。

根据上述分析，我们可以绘制 **dvi_encoder** 编码模块的框图：

![在这里插入图片描述](https://img-blog.csdnimg.cn/8a621fcfe6fe491497a0e75835a2241c.png)

### 3.3.1 代码编写

对于编码模块的代码编写，我不再进行波形图的绘制，以官方手册的流程图为参照，编码模块代码为 **xilinx** 官方所提供的。

编码模块参考流程图，具体见下图。

![在这里插入图片描述](https://img-blog.csdnimg.cn/6e058408d0ee4e74bacf3d66a0cefbf4.png)

![在这里插入图片描述](https://img-blog.csdnimg.cn/432c68df4820483e935723b6b5a7d8ae.png)

**TMDS** 通过逻辑算法将 8 位字符数据通过编码转换为 10 位字符数据，前 8 位数据由原始信号经运算后获得，**第 9 位**表示运算的方式， 1 表示异或 0 表示异或非。经过 **DC** 平衡后（第 10 位），采用差分信号传输数据。**第 10 位**实际是一个反转标志位， 1 表示进行了反转而 0 表示没有反转，从而达到 **DC** 平衡。

>接收端在收到信号后，再进行相反的运算。 **TMDS** 和 **LVDS**、 **TTL** 相比有较好的电磁兼容性能。这种算法可以减小传输信号过程的上冲和下冲，而 **DC** 平衡使信号对传输线的电磁干扰减少，可以用低成本的专用电缆实现长距离、高质量的数字信号传输。


下面我们一起来看一下 **xilinx** 官方提供的编码模块代码：




```
module dvi_encoder (
  input            clkin,    // pixel clock input
  input            rstin,    // async. reset input (active high)
  input      [7:0] din,      // data inputs: expect registered
  input            c0,       // c0 input
  input            c1,       // c1 input
  input            de,       // de input
  output reg [9:0] dout      // data outputs
);

////////////////////////////////////////////////////////////
// Counting number of 1s and 0s for each incoming pixel
// component. Pipe line the result.
// Register Data Input so it matches the pipe lined adder
// output
////////////////////////////////////////////////////////////
reg [3:0] n1d; //number of 1s in din
reg [7:0] din_q;

//计算像素数据中“1”的个数
always @ (posedge clkin) begin
  n1d <=#1 din[0] + din[1] + din[2] + din[3] + din[4] + din[5] + din[6] + din[7];

  din_q <=#1 din;
end

///////////////////////////////////////////////////////
// Stage 1: 8 bit -> 9 bit
// Refer to DVI 1.0 Specification, page 29, Figure 3-5
///////////////////////////////////////////////////////
wire decision1;

assign decision1 = (n1d > 4'h4) | ((n1d == 4'h4) & (din_q[0] == 1'b0));

wire [8:0] q_m;
assign q_m[0] = din_q[0];
assign q_m[1] = (decision1) ? (q_m[0] ^~ din_q[1]) : (q_m[0] ^ din_q[1]);
assign q_m[2] = (decision1) ? (q_m[1] ^~ din_q[2]) : (q_m[1] ^ din_q[2]);
assign q_m[3] = (decision1) ? (q_m[2] ^~ din_q[3]) : (q_m[2] ^ din_q[3]);
assign q_m[4] = (decision1) ? (q_m[3] ^~ din_q[4]) : (q_m[3] ^ din_q[4]);
assign q_m[5] = (decision1) ? (q_m[4] ^~ din_q[5]) : (q_m[4] ^ din_q[5]);
assign q_m[6] = (decision1) ? (q_m[5] ^~ din_q[6]) : (q_m[5] ^ din_q[6]);
assign q_m[7] = (decision1) ? (q_m[6] ^~ din_q[7]) : (q_m[6] ^ din_q[7]);
assign q_m[8] = (decision1) ? 1'b0 : 1'b1;

/////////////////////////////////////////////////////////
// Stage 2: 9 bit -> 10 bit
// Refer to DVI 1.0 Specification, page 29, Figure 3-5
/////////////////////////////////////////////////////////
reg [3:0] n1q_m, n0q_m; // number of 1s and 0s for q_m
always @ (posedge clkin) begin
  n1q_m  <=#1 q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
  n0q_m  <=#1 4'h8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]);
end

parameter CTRLTOKEN0 = 10'b1101010100;
parameter CTRLTOKEN1 = 10'b0010101011;
parameter CTRLTOKEN2 = 10'b0101010100;
parameter CTRLTOKEN3 = 10'b1010101011;

reg [4:0] cnt; //disparity counter, MSB is the sign bit
wire decision2, decision3;

assign decision2 = (cnt == 5'h0) | (n1q_m == n0q_m);
/////////////////////////////////////////////////////////////////////////
// [(cnt > 0) and (N1q_m > N0q_m)] or [(cnt < 0) and (N0q_m > N1q_m)]
/////////////////////////////////////////////////////////////////////////
assign decision3 = (~cnt[4] & (n1q_m > n0q_m)) | (cnt[4] & (n0q_m > n1q_m));

////////////////////////////////////
// pipe line alignment
////////////////////////////////////
reg       de_q, de_reg;
reg       c0_q, c1_q;
reg       c0_reg, c1_reg;
reg [8:0] q_m_reg;

always @ (posedge clkin) begin
  de_q    <=#1 de;
  de_reg  <=#1 de_q;
  
  c0_q    <=#1 c0;
  c0_reg  <=#1 c0_q;
  c1_q    <=#1 c1;
  c1_reg  <=#1 c1_q;

  q_m_reg <=#1 q_m;
end

///////////////////////////////
// 10-bit out
// disparity counter
///////////////////////////////
always @ (posedge clkin or posedge rstin) begin
  if(rstin) begin
    dout <= 10'h0;
    cnt <= 5'h0;
  end else begin
    if (de_reg) begin
      if(decision2) begin
        dout[9]   <=#1 ~q_m_reg[8]; 
        dout[8]   <=#1 q_m_reg[8]; 
        dout[7:0] <=#1 (q_m_reg[8]) ? q_m_reg[7:0] : ~q_m_reg[7:0];

        cnt <=#1 (~q_m_reg[8]) ? (cnt + n0q_m - n1q_m) : (cnt + n1q_m - n0q_m);
      end else begin
        if(decision3) begin
          dout[9]   <=#1 1'b1;
          dout[8]   <=#1 q_m_reg[8];
          dout[7:0] <=#1 ~q_m_reg[7:0];

          cnt <=#1 cnt + {q_m_reg[8], 1'b0} + (n0q_m - n1q_m);
        end else begin
          dout[9]   <=#1 1'b0;
          dout[8]   <=#1 q_m_reg[8];
          dout[7:0] <=#1 q_m_reg[7:0];

          cnt <=#1 cnt - {~q_m_reg[8], 1'b0} + (n1q_m - n0q_m);
        end
      end
    end else begin
      case ({c1_reg, c0_reg})
        2'b00:   dout <=#1 CTRLTOKEN0;
        2'b01:   dout <=#1 CTRLTOKEN1;
        2'b10:   dout <=#1 CTRLTOKEN2;
        default: dout <=#1 CTRLTOKEN3;
      endcase

      cnt <=#1 5'h0;
    end
  end
end
  
endmodule
```

结合仿真波形我们看一下 **xilinx** 官方提供的编码模块：

![在这里插入图片描述](https://img-blog.csdnimg.cn/2509d7328ea14591900537a15f288e97.png)

如上图所示，当 **“decision2= 1”** 时，对应代码中的第 101 到 105 行， **dout** 等于 10’b10_0000_0000， **cnt** 等于 5’b11000；当“decision2 = 0 且条件 decision3 = 0” 时，对应代码的第 114 到 118 行， **dout** 等于10’b00_1111_1111，**cnt** 等于 5’b11110，下一个时钟周期 **cnt** 等于 5’b00100，因为 **q_m_reg** 值保持不变，所以 **dout** 也保持不变；当 “decision2= 0 且 decision3 = 1 时” ，对应代码的第 108 到 112 行， **dout** 等于 10’b10_0000_0000， **cnt** 等于 5’b11100。

>因为 **cnt** 和 **dout** 为时序逻辑，所以在输出的结果会延迟一个时钟周期。这里 **dout** 以及 **cnt** 的计算过程，大家如果有兴趣可以参考对应行号的公式进行计算一下，我这里就不做一个详细的展开了。


## 3.4 Serializer 模块设计

下面我们来看一下 **Serializer（并串转换）** 模块的设计，本次我们设计的并串转换模块是通过 **xilinx** 官方提供的 **OSERDESE2** 原语，对编码模块输出的 **10bit** 数据进行**并串转换然后输出**，模块框图如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/e37f3c5b383e441ea0b68f65e3ab0595.png)

### 3.4.1 OSERDESE2 原语调用


在调用 **Xlinx OSERDESE2** 的原语之前，我首先带大家一起了解一下它的相关概念。

>**OSERDESE2** 是一种专用的**并 - 串转换器**，每个 **OSERDESE2** 模块都包括一个专用串行化程序用于数据和 3 状态控制。数据和 3 状态序列化程序都可以工作在 **SDR** 和 **DDR** 模式。数据串行化的位宽可以达到 **8:1**（如果使用原语模块级联，则可以到 10:1 和 14:1）。 3 状态序列化最高可达 14:1，有一个专用的 **DDR3** 模式可用于支持高速内存应用程序。

**OSERESE2** 框图如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/b5ca4b2db3a44dffa95d2381e8e2fdcb.png)

**OSERDESE2** 的端口说明如下：

![在这里插入图片描述](https://img-blog.csdnimg.cn/541c444d20124218834e281802637a22.png)

![在这里插入图片描述](https://img-blog.csdnimg.cn/184382948fce4e3fb9ca8dca8ecf5407.png)

需要注意的是， 一个 **OSERDESE2** 只能实现最多 **8:1** 的转换率， 在这里我们通过**位宽扩展**实现了 **10:1** 的并串转换， 如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/2e0b0ecdd2bd4a6fb390cb84cfa4aa90.png)

**SERDESE2** 位宽扩展通过两个 **OSERDESE2** 模块来实现， 其中一个作为 **Master**， 另一个作为 **Slave**， 通过这种方式最多可实现 **14:1** 的并串转换。需要注意的是， 在位宽扩展时， **Slave** 模块的数据输入端只能使用 **D3** 至 **D8**。

接下里例化一个原语来实现 10 位数据的并串转换，采用 **DDR** 输出。例化 2 个原语 **OSERDESE2** 级联（打开 **vivado--Tools--Language Templates**，搜索 **“OSERDESE2”** ，选择 **A7** 系列，可以找到 **Xilinx** 提供的原语模板），具体步骤如下图所示：


![在这里插入图片描述](https://img-blog.csdnimg.cn/d126810b89cd4933a724718b836fb7c3.png)

![在这里插入图片描述](https://img-blog.csdnimg.cn/fd11958b1bbc4bf0ac1c01af8f017cca.png)

在例化原语之前，我们先来看一下 **OSERDESE2** 需要例化的一些可用属性：

![在这里插入图片描述](https://img-blog.csdnimg.cn/de00dda1dce8429a91ad94b3fbb2df8a.png)

![在这里插入图片描述](https://img-blog.csdnimg.cn/4ac325f586cc4b748be84f9c8ad9e86d.png)

### 3.4.2 代码编写

接下来我们将原语例化到我们的 **serializer** 模块中，**并串转换**代码如下所示：

```
module serializer_10_to_1(
    input           reset,              // 复位,高有效
    input           paralell_clk,       // 输入并行数据时钟
    input           serial_clk_5x,      // 输入串行数据时钟
    input   [9:0]   paralell_data,      // 输入并行数据

    output 			serial_data_out     // 输出串行数据
    );
    
//wire define
wire		cascade1;     //用于两个OSERDESE2级联的信号
wire		cascade2;
  
//*****************************************************
//**                    main code
//***************************************************** 
    
//例化OSERDESE2原语，实现并串转换,Master模式
OSERDESE2 #(
    .DATA_RATE_OQ   ("DDR"),       // 设置双倍数据速率
    .DATA_RATE_TQ   ("SDR"),       // DDR, BUF, SDR
    .DATA_WIDTH     (10),           // 输入的并行数据宽度为10bit
    .SERDES_MODE    ("MASTER"),    // 设置为Master，用于10bit宽度扩展
    .TBYTE_CTL      ("FALSE"),     // Enable tristate byte operation (FALSE, TRUE)
    .TBYTE_SRC      ("FALSE"),     // Tristate byte source (FALSE, TRUE)
    .TRISTATE_WIDTH (1)             // 3-state converter width (1,4)
)
OSERDESE2_Master (
    .CLK        (serial_clk_5x),    // 串行数据时钟,5倍时钟频率
    .CLKDIV     (paralell_clk),     // 并行数据时钟
    .RST        (reset),            // 1-bit input: Reset
    .OCE        (1'b1),             // 1-bit input: Output data clock enable
    
    .OQ         (serial_data_out),  // 串行输出数据
    
    .D1         (paralell_data[0]), // D1 - D8: 并行数据输入
    .D2         (paralell_data[1]),
    .D3         (paralell_data[2]),
    .D4         (paralell_data[3]),
    .D5         (paralell_data[4]),
    .D6         (paralell_data[5]),
    .D7         (paralell_data[6]),
    .D8         (paralell_data[7]),
   
    .SHIFTIN1   (cascade1),         // SHIFTIN1 用于位宽扩展
    .SHIFTIN2   (cascade2),         // SHIFTIN2
    .SHIFTOUT1  (),                 // SHIFTOUT1: 用于位宽扩展
    .SHIFTOUT2  (),                 // SHIFTOUT2
        
    .OFB        (),                 // 以下是未使用信号
    .T1         (1'b0),             
    .T2         (1'b0),
    .T3         (1'b0),
    .T4         (1'b0),
    .TBYTEIN    (1'b0),             
    .TCE        (1'b0),             
    .TBYTEOUT   (),                 
    .TFB        (),                 
    .TQ         ()                  
);
   
//例化OSERDESE2原语，实现并串转换,Slave模式
OSERDESE2 #(
    .DATA_RATE_OQ   ("DDR"),       // 设置双倍数据速率
    .DATA_RATE_TQ   ("SDR"),       // DDR, BUF, SDR
    .DATA_WIDTH     (10),           // 输入的并行数据宽度为10bit
    .SERDES_MODE    ("SLAVE"),     // 设置为Slave，用于10bit宽度扩展
    .TBYTE_CTL      ("FALSE"),     // Enable tristate byte operation (FALSE, TRUE)
    .TBYTE_SRC      ("FALSE"),     // Tristate byte source (FALSE, TRUE)
    .TRISTATE_WIDTH (1)             // 3-state converter width (1,4)
)
OSERDESE2_Slave (
    .CLK        (serial_clk_5x),    // 串行数据时钟,5倍时钟频率
    .CLKDIV     (paralell_clk),     // 并行数据时钟
    .RST        (reset),            // 1-bit input: Reset
    .OCE        (1'b1),             // 1-bit input: Output data clock enable
    
    .OQ         (),                 // 串行输出数据
    
    .D1         (1'b0),             // D1 - D8: 并行数据输入
    .D2         (1'b0),
    .D3         (paralell_data[8]),
    .D4         (paralell_data[9]),
    .D5         (1'b0),
    .D6         (1'b0),
    .D7         (1'b0),
    .D8         (1'b0),
   
    .SHIFTIN1   (),                 // SHIFTIN1 用于位宽扩展
    .SHIFTIN2   (),                 // SHIFTIN2
    .SHIFTOUT1  (cascade1),         // SHIFTOUT1: 用于位宽扩展
    .SHIFTOUT2  (cascade2),         // SHIFTOUT2
        
    .OFB        (),                 // 以下是未使用信号
    .T1         (1'b0),             
    .T2         (1'b0),
    .T3         (1'b0),
    .T4         (1'b0),
    .TBYTEIN    (1'b0),             
    .TCE        (1'b0),             
    .TBYTEOUT   (),                 
    .TFB        (),                 
    .TQ         ()                  
);  
        
endmodule
```

本次例化 **OSERDESE2** 原语需要注意的是，根据 **UG471** 数据手册的说明，配置 10 转 1 的并串转换需要将 **DATA_RATE_OQ** 配置为 **“DDR”** 和 **“DATA_RATE_TQ“SDR”**，具体详见下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/6bf191e0270640ff87d8f9e9b74d647b.png)

![在这里插入图片描述](https://img-blog.csdnimg.cn/ef66d624743f427c8c419c245ed360ab.png)

从仿真图中可以看出，在①处的上升沿采集到的数据为 **10’b1101010100**， 在②处也就是 4 个串行时钟的延迟后，串行输出开始有数据，分别为 **0-0-1-0-1-0-1-0-1-1**，可以看出是第 1 个上升沿采集到的数据输出（**11010_10100** 从低位往高位输出）。

## 3.5 顶层模块编写

实验工程的各子功能模块均已讲解完毕，在本小节对顶层模块做一下介绍。 **hdmi_colorbar** 顶层模块主要是对各个子功能模块的实例化，以及对应信号的连接。代码编写较为容易，无需波形图的绘制。

顶层模块 **hdmi_colorbar_top** 的代码如下：

```
module  hdmi_colorbar_top(
    input        sys_clk,
    input        sys_rst_n,
    
    output       tmds_clk_p,    // TMDS 时钟通道
    output       tmds_clk_n,
    output [2:0] tmds_data_p,   // TMDS 数据通道
    output [2:0] tmds_data_n
);

//wire define
wire          pixel_clk;
wire          pixel_clk_5x;
wire          clk_locked;

wire  [10:0]  pixel_xpos_w;
wire  [10:0]  pixel_ypos_w;
wire  [23:0]  pixel_data_w;

wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;

//*****************************************************
//**                    main code
//*****************************************************

//例化MMCM/PLL IP核
clk_wiz_0  clk_wiz_0(
    .clk_in1        (sys_clk),
    .clk_out1       (pixel_clk),        //像素时钟
    .clk_out2       (pixel_clk_5x),     //5倍像素时钟
    
    .reset          (~sys_rst_n), 
    .locked         (clk_locked)
);

//例化视频显示驱动模块
video_driver  u_video_driver(
    .pixel_clk      ( pixel_clk ),
    .sys_rst_n      ( sys_rst_n ),

    .video_hs       ( video_hs ),
    .video_vs       ( video_vs ),
    .video_de       ( video_de ),
    .video_rgb      ( video_rgb ),
	.data_req		(),

    .pixel_xpos     ( pixel_xpos_w ),
    .pixel_ypos     ( pixel_ypos_w ),
	.pixel_data     ( pixel_data_w )
);

//例化视频显示模块
video_display  u_video_display(
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (sys_rst_n),

    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w)
    );

//例化HDMI驱动模块
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk),
    .pclk_x5        (pixel_clk_5x),
    .reset_n        (sys_rst_n & clk_locked),
                
    .video_din      (video_rgb),
    .video_hsync    (video_hs), 
    .video_vsync    (video_vs),
    .video_de       (video_de),
                
    .tmds_clk_p     (tmds_clk_p),
    .tmds_clk_n     (tmds_clk_n),
    .tmds_data_p    (tmds_data_p),
    .tmds_data_n    (tmds_data_n), 
    .tmds_oen       ()                        //预留的端口，本次实验未用到
    );

endmodule
```

>在代码的 30 至 37 行，我们通过调用时钟 **IP** 核来产生两个时钟，其中 **pixel_clk** 为像素时钟，而 **pixel_clk_5x** 为并串转换模块所需要的串行数据时钟，其频率为 **pixel_clk** 的 5 倍。

# 4 仿真验证

## 4.1 编写TestBench

顶层模块参考代码介绍完毕，开始对顶层模块进行仿真，对顶层模块的仿真就是对实验工程的整体仿真。

**HDMI** 彩条 **TB** 模块（**tb_hdmi_colorbar.v**）代码编写如下：

```
`timescale 1ns/1ns

module tb_hdmi_colorbar_top();

reg        sys_clk		;
reg        sys_rst_n	;
    
wire       tmds_clk_p	;    // TMDS 时钟通道
wire       tmds_clk_n	;
wire [2:0] tmds_data_p	;    // TMDS 数据通道
wire [2:0] tmds_data_n  ;

initial begin
	sys_clk = 1'b1;
	sys_rst_n <= 1'b0;
	#201
	sys_rst_n <= 1'b1;
end

always #10 sys_clk <= ~sys_clk;

hdmi_colorbar_top	hdmi_colorbar_top_inst(
    .sys_clk		(sys_clk	),
    .sys_rst_n		(sys_rst_n	),

    .tmds_clk_p		(tmds_clk_p	),    // TMDS 时钟通道
    .tmds_clk_n		(tmds_clk_n	),
    .tmds_data_p	(tmds_data_p),   // TMDS 数据通道
    .tmds_data_n    (tmds_data_n)
);

endmodule
```


## 4.2 仿真波形分析

接下来打开 **Modelsim** 软件对代码进行仿真，仿真的波形如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/c7f206e653ac43e4a637ef5a996f0dc9.png)

![在这里插入图片描述](https://img-blog.csdnimg.cn/4db6cac16eb349ffa0b6d2a8dff14aea.png)


从波形图中可以看出， **HDMI** 顶层差分时钟以及差分数据信号结果是没有问题的。而 **lcd_rgb** 在 **lcd_hs** 拉高的范围内，将 **RGB888** 颜色分为五种颜色，分别是**白（24’hffffff）**、**黑（24’h000000）**、**红（24’hff0000）**、**绿（24’h00ff00）** 和 **蓝（24’h0000ff）**，与我们设计的代码是一致的。

编码模块的波形以及并转串的仿真，在前面的子功能模块已经进行了验证分析。而驱动以及显示模块的波形，可以参考  [LCD 彩条显示实验](http://t.csdnimg.cn/kefzC) 部分的模块介绍。至此本章节 **HDMI** 彩条实验的设计已经完成，接下来就可以进行下载验证了。


# 5 下载验证

将本次实验生成的 **BIT** 文件下载下开发板中，下载完成之后 **HDMI** 显示器上显示彩条图案，说明本次实验下载验证成功！


![在这里插入图片描述](https://img-blog.csdnimg.cn/e25b9d40e7e847198d1ecdd4aa7b25c2.png)





# 6 总结

到这里，本文 **HDMI** 彩条实验的讲解就完毕。 通过本章的实验，我记录了 **HDMI** 显示的基本知识和概念、 **TMDS** 传输原理以及 **OSERDESE2** 原语的使用，希望能和大家一起进步！







微博：沂舟Ryan ([@沂舟Ryan 的个人主页 - 微博 ](https://weibo.com/u/7619968945))

GitHub：[ChinaRyan666](https://github.com/ChinaRyan666)

微信公众号：沂舟无限进步

如果对您有帮助的话请点赞支持下吧！



**集中一点，登峰造极。**

