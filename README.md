# R730_idrac_fanspeed
|通过IPMI可以在linux系统上运行的Dell R730xd风扇自动调速脚本。IPMI-enabled automatic fan speed control script for Dell R730xd running on Linux systems.|
| :- |

**[English](#english) | [中文](#中文)**

<a name="中文"></a>
# 适用于Dell PowerEdge R730xd服务器的基于IPMI的自动风扇速度控制脚本

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) 
[![Platform](https://img.shields.io/badge/Platform-Linux-important)](https://ubuntu.com/) 
[![Compatibility](https://img.shields.io/badge/Tested%20on-Dell%20R730xd%20%2B%20Ubuntu%2024.04-success)]()

## 项目动机

Dell PowerEdge R730xd凭借其性能和成本的平衡，仍是NAS解决方案中受欢迎的经济高效服务器选择。然而，其默认的激进风扇控制策略使其在没有隔音措施的办公室或家庭环境中难以使用。虽然现有解决方案如[cw1997/dell_fans_controller](https://github.com/cw1997/dell_fans_controller)适用于Windows系统，但它们需要手动干预，且在重启或长时间运行后无法解决风扇速度自动重置的问题。

本项目实现了一个基于Linux的自动化解决方案，具有以下特点：
- 通过cron计划任务的bash脚本实现**资源高效运行**
- 在温度阈值之间使用线性插值实现**动态速度调整**
- 系统重启后仍然保持有效的**持久配置**
- 与各种热传感器配置兼容的**硬件无关设计**

通过AI辅助调试（ChatGPT）进行迭代测试开发，该解决方案无需编程专业知识即可实现有效的风扇控制。

## 实现概述

脚本实现了一个与温度成比例的控制算法：

1. **温度获取**  
   使用`ipmitool`轮询热传感器（默认：CPU1温度）。可配置为其他传感器（如进/排气温度）。

2. **阈值配置**  
   ```bash
   TEMP_THRESHOLD_LOW=45    # °C (FAN_SPEED_LOW)
   TEMP_THRESHOLD_HIGH=65   # °C (FAN_SPEED_HIGH)
   FAN_SPEED_LOW=15         # 15% 
   FAN_SPEED_HIGH=35        # 35%
   ```

3. **动态速度计算**  
   实现阈值之间的线性插值：
   ```plaintext
   Speed = FAN_SPEED_LOW + (TEMP - TEMP_THRESHOLD_LOW) * 
          (FAN_SPEED_HIGH - FAN_SPEED_LOW) / (TEMP_THRESHOLD_HIGH - TEMP_THRESHOLD_LOW)
   ```

4. **IPMI控制**  
   - 禁用自动风扇控制：  
     `ipmitool raw 0x30 0x30 0x01 0x00`
   - 设置计算的速度：  
     `ipmitool raw 0x30 0x30 0x02 0xff <HEX_SPEED>`

## 兼容性

**已验证配置：**  
- 硬件：Dell PowerEdge R730xd
- 操作系统：Ubuntu 24.04 LTS
- IPMI：iDRAC8+

**理论兼容性：**  
- 所有带有iDRAC7+的Dell服务器
- 支持`ipmitool`的Linux发行版

## 安装与配置

### 前提条件
1. 在iDRAC设置中启用IPMI over LAN（[配置指南](https://zhuanlan.zhihu.com/p/157796567)）
2. 安装IPMITool：
   ```bash
   sudo apt update && sudo apt install ipmitool
   ```
3. 验证传感器访问：
   ```bash
   ipmitool -I lanplus -H <服务器IP> -U <用户名> -P <密码> sdr type Temperature
   ```
   预期输出：
   ```plaintext
   Inlet Temp       | 04h | ok  |  7.1 | 30 degrees C
   Exhaust Temp     | 01h | ok  |  7.1 | 46 degrees C
   Temp             | 0Eh | ok  |  3.1 | 59 degrees C  # CPU1
   Temp             | 0Fh | ok  |  3.2 | 63 degrees C  # CPU2
   ```

### 部署
1. 下载脚本：
   ```bash
   wget https://raw.githubusercontent.com/your-repo/R730_idrac_fanspeed/main/fan_control.sh
   chmod 755 fan_control.sh
   ```
2. 配置参数：
   ```bash
   nano fan_control.sh  # 更新IPMI凭据和控制阈值
   ```
3. 手动执行：
   ```bash
   ./fan_control.sh
   ```
   成功输出：
   ```plaintext
   OUTPUT: Temp | 0Eh | ok | 3.1 | 58°C
   CURRENT_TEMP: 58
   Current temperature: 58°C, Fan speed set to: 17%
   ```

### 自动化
添加cron任务以定期执行（例如，每5分钟）：
```bash
crontab -e
*/5 * * * * /path/to/fan_control.sh >/dev/null 2>&1
```

## 贡献
欢迎提交问题和PR。请包括：
- 服务器型号和iDRAC版本
- 操作系统版本和内核信息（`uname -a`）
- 相关的`ipmitool sensor`输出

## 许可证
MIT许可证 - 详情见[LICENSE](LICENSE)

---

<a name="english"></a>
# IPMI-based Automatic Fan Speed Control Script for Dell PowerEdge R730xd Servers

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) 
[![Platform](https://img.shields.io/badge/Platform-Linux-important)](https://ubuntu.com/) 
[![Compatibility](https://img.shields.io/badge/Tested%20on-Dell%20R730xd%20%2B%20Ubuntu%2024.04-success)]()

## Motivation

The Dell PowerEdge R730xd remains a popular cost-effective server choice for NAS solutions due to its balance of performance and affordability. However, its default aggressive fan control strategy makes it impractical for office or home environments without acoustic isolation. While existing solutions like [cw1997/dell_fans_controller](https://github.com/cw1997/dell_fans_controller) work for Windows systems, they require manual intervention and don't address spontaneous fan speed resets after reboots or prolonged operation.

This project implements a Linux-based automated solution featuring:
- **Resource-efficient operation** through cron-scheduled bash scripting
- **Dynamic speed adjustment** with linear interpolation between temperature thresholds
- **Persistent configuration** resistant to system reboots
- **Hardware-agnostic design** compatible with various thermal sensor configurations

Developed through iterative testing with AI-assisted debugging (ChatGPT), this solution demonstrates effective fan control without requiring programming expertise.

## Implementation Overview

The script implements a temperature-proportional control algorithm:

1. **Temperature Acquisition**  
   Uses `ipmitool` to poll thermal sensors (default: CPU1 temperature). Configurable to other sensors (e.g., Inlet/Exhaust Temp).

2. **Threshold Configuration**  
   ```bash
   TEMP_THRESHOLD_LOW=45    # °C (FAN_SPEED_LOW)
   TEMP_THRESHOLD_HIGH=65   # °C (FAN_SPEED_HIGH)
   FAN_SPEED_LOW=15         # 15% 
   FAN_SPEED_HIGH=35        # 35%
   ```

3. **Dynamic Speed Calculation**  
   Implements linear interpolation between thresholds:
   ```plaintext
   Speed = FAN_SPEED_LOW + (TEMP - TEMP_THRESHOLD_LOW) * 
          (FAN_SPEED_HIGH - FAN_SPEED_LOW) / (TEMP_THRESHOLD_HIGH - TEMP_THRESHOLD_LOW)
   ```

4. **IPMI Control**  
   - Disables automatic fan control:  
     `ipmitool raw 0x30 0x30 0x01 0x00`
   - Sets calculated speed:  
     `ipmitool raw 0x30 0x30 0x02 0xff <HEX_SPEED>`

## Compatibility

**Verified Configuration:**  
- Hardware: Dell PowerEdge R730xd
- OS: Ubuntu 24.04 LTS
- IPMI: iDRAC8+

**Theoretical Compatibility:**  
- All Dell servers with iDRAC7+ 
- Linux distributions with `ipmitool` support

## Installation & Configuration

### Prerequisites
1. Enable IPMI over LAN in iDRAC settings ([Configuration Guide](https://zhuanlan.zhihu.com/p/157796567))
2. Install IPMITool:
   ```bash
   sudo apt update && sudo apt install ipmitool
   ```
3. Validate sensor access:
   ```bash
   ipmitool -I lanplus -H <SERVER_IP> -U <USERNAME> -P <PASSWORD> sdr type Temperature
   ```
   Expected output:
   ```plaintext
   Inlet Temp       | 04h | ok  |  7.1 | 30 degrees C
   Exhaust Temp     | 01h | ok  |  7.1 | 46 degrees C
   Temp             | 0Eh | ok  |  3.1 | 59 degrees C  # CPU1
   Temp             | 0Fh | ok  |  3.2 | 63 degrees C  # CPU2
   ```

### Deployment
1. Download script:
   ```bash
   wget https://raw.githubusercontent.com/your-repo/R730_idrac_fanspeed/main/fan_control.sh
   chmod 755 fan_control.sh
   ```
2. Configure parameters:
   ```bash
   nano fan_control.sh  # Update IPMI credentials and control thresholds
   ```
3. Manual execution:
   ```bash
   ./fan_control.sh
   ```
   Successful output:
   ```plaintext
   OUTPUT: Temp | 0Eh | ok | 3.1 | 58°C
   CURRENT_TEMP: 58
   Current temperature: 58°C, Fan speed set to: 17%
   ```

### Automation
Add cron job for periodic execution (e.g., every 5 minutes):
```bash
crontab -e
*/5 * * * * /path/to/fan_control.sh >/dev/null 2>&1
```

## Contribution
Issues and PRs welcome. Please include:
- Server model and iDRAC version
- OS version and kernel info (`uname -a`)
- Relevant `ipmitool sensor` output

## License
MIT License - See [LICENSE](LICENSE) for details
