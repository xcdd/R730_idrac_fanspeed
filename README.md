# R730_idrac_fanspeed
|通过IPMI可以在linux系统上运行的Dell R730xd风扇自动调速脚本。IPMI-enabled automatic fan speed control script for Dell R730xd running on Linux systems.|
| :- |

<a name="heading_0"></a>**为什么有这个项目**

众所周知，R730xd是一个兼具性价比、可玩性、保有量大的二手服务器型号，非常适合用来搭建NAS。然而这种服务器默认起飞式的风扇控制策略，根本就没办法在办公室、家庭里边使用。因此买了这个服务器，若不是把它丢在一个隔音房，那调整风扇转速是显然一定要做的事。

之前我一直在使用[https://github.com/cw1997/dell\_fans\_controller](https://github.com/cw1997/dell_fans_controller)，但这是一个windows平台的软件，且只能手工调整转速。而有些硬件搭配比较奇怪的R730xd，他们在重新开机甚至是过了一段时间以后，就会重新开始转速起飞。因此自动化的调整是一个需求。

而我希望这个调整脚本可以在一个不吃资源的平台上实现，所以我选择了linux脚本，然后配合crontab计划程序来达成这个设想。我还希望，风扇转速不是固定在对应的某个温度对应的赋值上。所以我还添加了，在温度阈值范围内能自动无极调整转速的功能。

我不是程序员，所以我请教了metaso搜索引擎来如何实现这个目的，再配合反复提示ChatGPT来调试排错，我成功得到了目前这个实践方案。

<a name="heading_1"></a>**脚本说明**

1. **获取当前温度**：使用`ipmitool`命令获取服务器的当前温度。脚本获取的温度是第1个CPU的温度，你也可以请教GPT这类工具，让它帮你把取值改成其它温度（如`Inlet Temp`，进气温度；`Exhaust Temp`，排气温度）；
2. **设置温度阈值**：定义了两个温度阈值（`TEMP\_THRESHOLD\_LOW`和`TEMP\_THRESHOLD\_HIGH`），用于决定`FAN\_SPEED\_LOW`（最低）和`FAN\_SPEED\_HIGH`（最高）的风扇转速。
3. **根据温度设置风扇转速**：根据当前温度与设定的温度阈值，计算出相应的风扇转速。如果温度低于低阈值，使用最低转速；如果温度高于高阈值，使用最高转速；否则，根据温度在高低阈值之间的位置，根据实际的温度情况与高低阈值的设置，计算出一个中间值的转速。
4. **关闭自动风扇控制**：使用`ipmitool`命令关闭自动风扇控制，以确保手动设置的转速生效。
5. **设置风扇转速**：使用`ipmitool`命令设置风扇转速，转速值以百分比表示，并转换为十六进制格式。

<a name="heading_2"></a>**兼容性**

本脚本在Dell R730xd+Ubuntu 24上测试通过，理论上可能也适合其它Dell的机型、其它支持`ipmitool`的linux系统，欢迎测试。

<a name="heading_3"></a>**使用说明**

1. 你需要先打开你机器的`IPMI over LAN`服务。并且知道IP地址、账号、密码（这点有很多教程，例如<https://zhuanlan.zhihu.com/p/157796567>）；
2. 你先要在linux里边安装`ipmitool`。以`Ubuntu 24`为例，在终端中输入：<br>
`sudo apt-get install ipmitool`
3. 安装完成后，先测试一下ipmitool是否是可以用的，在终端中输入：<br>
`ipmitool -I lanplus -H 服务器ip -U 用户名 -P 密码 sdr type Temperature`<br>
例如<br>
`ipmitool -I lanplus -H 192.168.2.10 -U root -P password sdr type Temperature`<br>
查看打印出来的信息里，是否包括了以下温度信息。如不包括，说明你的账号信息有问题，或者该脚本无法在你机器上使用。<br>只装了一个CPU的服务器会少一个Temp，不影响使用。<br>
   Inlet Temp       | 04h | ok  |  7.1 | 30 degrees C<br>
   Exhaust Temp     | 01h | ok  |  7.1 | 46 degrees C<br>
   Temp             | 0Eh | ok  |  3.1 | 59 degrees C<br>
   Temp             | 0Fh | ok  |  3.2 | 63 degrees C<br>
4. 把存储库的fan_control.sh传到你服务器上，给755权限
5. 修改fan_control.sh里边的IP地址、用户名和密码。你也可以看到有关风扇转速的设置在这的下面，改成你喜欢的，如果没有想法，可以用我调整好的值。
6. 执行fan_control.sh，观察是否打印出来如下类似信息，并感受下风扇转速是否有变化。如有就是成功了<br>
OUTPUT: Temp             | 0Eh | ok  |  3.1 | 58 degrees C<br>CURRENT\_TEMP: 58<br>当前温度: 58°C, 风扇转速设置为: 17%
7. 使用cron作业定期执行脚本，例如每5分钟执行一次，这样就是每5分钟让脚本检查一下风扇转速是否需要调整：
  `crontab -e`<br>
   添加以下行：<br>
  `\*/5 \* \* \* \* /path/to/fan_control.sh`

