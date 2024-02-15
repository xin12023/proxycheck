#!/bin/bash

# 日志目录
LOG_DIR="/home/auser/logs"

# 日志目录不存在则创建
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

# 定义今天和昨天的日志文件名称
TODAY_LOG_FILE="${LOG_DIR}/script_$(date '+%Y-%m-%d').log"
YESTERDAY_LOG_FILE="${LOG_DIR}/script_$(date '+%Y-%m-%d' -d "yesterday").log"

# 清理除了今天和昨天的日志文件
find "$LOG_DIR" -type f -name 'script_*.log' ! -name "$(basename $TODAY_LOG_FILE)" ! -name "$(basename $YESTERDAY_LOG_FILE)" -delete

# 检查tinyproxy服务状态
if ! systemctl is-active --quiet tinyproxy; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - tinyproxy服务未运行，跳过此次检查。" >> $TODAY_LOG_FILE
    exit 0
fi

# 获取外网IP
EXTERNAL_IP=$(curl -s http://ifconfig.me)
# 验证IP地址格式（IPv4）
if ! [[ $EXTERNAL_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 获取的外网IP地址格式不正确: $EXTERNAL_IP" >> $TODAY_LOG_FILE
    exit 0
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 获取到外网IP: $EXTERNAL_IP" >> $TODAY_LOG_FILE

# 代理端口和认证信息
PROXY_PORT="18395"
USERNAME="uakfjkl"
PASSWORD="asuWErsdf8w"
PROXY="http://$USERNAME:$PASSWORD@$EXTERNAL_IP:$PROXY_PORT"

# 错误计数文件
ERROR_COUNT_FILE="/home/auser/error_count.txt"

# 初始化错误计数
if [ ! -f "$ERROR_COUNT_FILE" ]; then
    echo 0 > "$ERROR_COUNT_FILE"
fi

# 使用curl发起请求，并获取HTTP状态码
HTTP_CODE=$(curl -s -o /home/auser/response.txt -w "%{http_code}" --proxy $PROXY http://google.com)
echo "$(date '+%Y-%m-%d %H:%M:%S') - HTTP请求状态码: $HTTP_CODE" >> $TODAY_LOG_FILE

# 读取并打印完整响应体到日志
echo "$(date '+%Y-%m-%d %H:%M:%S') - 代理请求返回:" >> $TODAY_LOG_FILE
cat /home/auser/response.txt >> $TODAY_LOG_FILE

# 检查返回状态码和内容
if [[ "$HTTP_CODE" != "301" && "$HTTP_CODE" != "302" ]] || ! grep -q "http://www.google.com" /home/auser/response.txt; then
    # 记录错误
    ERROR_COUNT=$(cat "$ERROR_COUNT_FILE")
    ERROR_COUNT=$((ERROR_COUNT+1))
    echo $ERROR_COUNT > "$ERROR_COUNT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Incremented error count to $ERROR_COUNT." >> $TODAY_LOG_FILE
else
    # 清除错误计数并退出
    echo 0 > "$ERROR_COUNT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 清除错误计数." >> $TODAY_LOG_FILE
    exit 0
fi

# 检查错误次数
if [[ $(cat "$ERROR_COUNT_FILE") -ge 3 ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 错误次数大地3次,重启系统." >> $TODAY_LOG_FILE
    # 警告：这将重启你的系统
    echo "错误次数达到3次，即将重启系统..."
    sudo shutdown -r now
fi
