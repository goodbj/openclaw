@echo off
chcp 65001 >nul
title OpenClaw Docker 开发环境 - 容器终端

echo ================================================
echo   OpenClaw Docker 开发环境 - 容器终端
echo ================================================
echo.

:: 检查 Docker 是否运行
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] Docker 未运行或未启动！
    echo.
    echo 请先启动 Docker Desktop，然后重试。
    echo.
    pause
    exit /b 1
)

echo [检查] Docker 运行正常...
echo.

:: 检查容器是否在运行
docker ps --format "{{.Names}}" | findstr "openclaw-gateway-dev" >nul 2>&1
if %errorlevel% neq 0 (
    echo [警告] 开发容器未运行！
    echo.
    echo 正在尝试启动容器...
    echo.
    
    :: 尝试启动容器
    docker compose -f docker-compose.dev.yml up -d
    
    if %errorlevel% neq 0 (
        echo.
        echo [错误] 启动容器失败！
        echo.
        echo 请检查：
        echo   1. docker-compose.dev.yml 文件是否存在
        echo   2. Docker Desktop 是否有足够资源
        echo   3. 端口 18789, 18790, 18791 是否被占用
        echo.
        pause
        exit /b 1
    )
    
    echo.
    echo [等待] 容器启动中...
    timeout /t 15 /nobreak >nul
    
    :: 再次检查容器状态
    docker ps --format "{{.Names}}" | findstr "openclaw-gateway-dev" >nul 2>&1
    if %errorlevel% neq 0 (
        echo [错误] 容器启动失败或健康检查未通过！
        echo.
        echo 查看日志：
        docker compose logs openclaw-gateway-dev --tail 20
        echo.
        pause
        exit /b 1
    )
    
    echo [成功] 容器已启动并运行正常！
    echo.
)

:: 显示容器信息
echo [信息] 容器状态:
docker ps --filter "name=openclaw-gateway-dev" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.

:: 进入容器执行 bash
echo [提示] 正在进入容器终端...
echo.
echo ================================================
echo   欢迎进入 OpenClaw 开发容器！
echo ================================================
echo.
echo 常用命令:
echo   pnpm dev          - 启动开发服务器
echo   pnpm test         - 运行测试
echo   pnpm build        - 构建项目
echo   pnpm tsgo         - TypeScript 类型检查
echo   openclaw --help   - 查看 CLI 帮助
echo   exit              - 退出容器终端
echo.
echo ================================================
echo.

:: 进入交互式 bash 会话
docker compose exec openclaw-gateway-dev bash

:: 返回到批处理脚本
echo.
echo [提示] 已退出容器终端
echo.
pause
