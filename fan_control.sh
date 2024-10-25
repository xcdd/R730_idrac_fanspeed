#!/bin/bash

# 填写你服务器iDRAC的IP地址、用户名和密码
IDRAC_IP="0.0.0.0"
IDRAC_USER="user"
IDRAC_PASSWORD="password"
# 设置你期望的风扇转速百分比和高低温度的阈值，最低转速不要太低
TEMP_THRESHOLD_LOW=55
TEMP_THRESHOLD_HIGH=72
FAN_SPEED_LOW=15
FAN_SPEED_HIGH=27

# 获取当前温度
OUTPUT=$(ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD sdr type Temperature | awk '$1 == "Temp" && $2 !~ /Inlet/ && $2 !~ /Exhaust/ {print $0; exit}' | head -n 1)

# 检查是否成功获取温度信息
if [ -z "$OUTPUT" ]; then
    echo "无法获取温度信息，请检查iDRAC连接和权限。"
    exit 1
fi

# 使用正则表达式提取最后一个数字字段作为温度值
CURRENT_TEMP=$(echo "$OUTPUT" | grep -oP '\d+\.?\d*' | tail -n 1)

# 打印此时处理前和处理后的温度值（如果你觉得脚本工作不正常的话）
echo "OUTPUT: $OUTPUT"
echo "CURRENT_TEMP: $CURRENT_TEMP"

# 检查是否成功提取温度值
if [ -z "$CURRENT_TEMP" ] || ! [[ "$CURRENT_TEMP" =~ ^[0-9]+(.[0-9]+)?$ ]]; then
    echo "获取的温度参数不是有效的数字: $CURRENT_TEMP"
    exit 1
fi

# 根据温度设置风扇转速
if [[ "$CURRENT_TEMP" -lt "$TEMP_THRESHOLD_LOW" ]]; then
    FAN_SPEED=$FAN_SPEED_LOW
elif [[ "$CURRENT_TEMP" -ge "$TEMP_THRESHOLD_HIGH" ]]; then
    FAN_SPEED=$FAN_SPEED_HIGH
else
    # 计算无级调速的风扇转速
    FAN_SPEED=$(( (CURRENT_TEMP - TEMP_THRESHOLD_LOW) * (FAN_SPEED_HIGH - FAN_SPEED_LOW) / (TEMP_THRESHOLD_HIGH - TEMP_THRESHOLD_LOW) + FAN_SPEED_LOW ))
fi

# 确保风扇转速是整数（似乎也可不确保）
FAN_SPEED=${FAN_SPEED%.*}

# 关闭自动风扇控制
ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD raw 0x30 0x30 0x01 0x00

# 设置风扇转速
ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PASSWORD raw 0x30 0x30 0x02 0xff $FAN_SPEED

echo "当前温度: $CURRENT_TEMP°C, 风扇转速设置为: $FAN_SPEED%"