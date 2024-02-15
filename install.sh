#!/bin/bash

# 定义下载URL，替换为你的GitHub脚本文件URL
SCRIPT_URL="https://raw.githubusercontent.com/xin12023/proxycheck/main/ipcheck.sh"

# 目标目录和脚本路径
TARGET_DIR="/home/auser"
TARGET_SCRIPT="${TARGET_DIR}/ipcheck.sh"

# 创建目标目录（如果不存在）
mkdir -p "$TARGET_DIR"

# 下载脚本
curl -o "$TARGET_SCRIPT" "$SCRIPT_URL" || wget -O "$TARGET_SCRIPT" "$SCRIPT_URL"

# 赋予执行权限
chmod +x "$TARGET_SCRIPT"

# 添加定时任务到crontab
CRON_JOB="*/5 * * * * $TARGET_SCRIPT"
(crontab -l | grep -v -F "$TARGET_SCRIPT"; echo "$CRON_JOB") | crontab -

echo "安装完成，定时任务已设置。"
