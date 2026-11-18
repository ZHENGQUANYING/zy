# Todo List

Vue 3 + Electron 桌面待办应用，FastAPI 后端，SQLite 本地存储。

## 技术栈

- **前端**：Vue 3 + Vite（`src/`）
- **桌面壳**：Electron（`electron/`）
- **后端**：FastAPI + 标准库 sqlite3（`server/`）
- **数据库**：SQLite（`server/db/schema.sql`，启动时自动建库）

## 开发

```bash
# 首次：安装依赖
npm install
python -m venv .venv
.venv/Scripts/pip install -r requirements.txt

# 方式一：浏览器开发（前后端分离）
npm run server        # 终端1：后端 http://localhost:3100（接口文档 /docs）
npm run dev           # 终端2：前端 http://localhost:5173

# 方式二：Electron 桌面窗口（自动拉起后端 + Vite）
npm run electron:dev
```

## 测试

```bash
npm run server &                                # 先启动后端
.venv/Scripts/python.exe server/smoke_test.py   # 17 项 API 冒烟测试
```

## 打包（Windows 安装包）

```bash
npm run dist        # 完整流程：前端构建 → 后端打 exe → NSIS 安装包
npm run dist:dir    # 免安装目录模式（调试用）
npm run build:server  # 只重打后端 exe（PyInstaller → dist-server/）
```

产物：`release/Todo List Setup 0.1.0.exe`（NSIS 安装包，可选安装目录）。

打包原理：

1. PyInstaller 把 FastAPI 后端打成单文件 `todo-server.exe`（schema.sql 内嵌）
2. electron-builder 把前端 `dist/` + `electron/` 打成 app.asar
3. NSIS `customInstall` 宏把 `todo-server.exe` 释放到安装目录 `resources/`
4. 运行时：Electron 主进程拉起 `resources/todo-server.exe`，
   数据库写入 `%APPDATA%/<产品名>/todo.db`（程序目录只读，不可存数据）

## 部署网页版

网页版使用 Vite 静态构建，不需要后端或数据库；任务通过浏览器 `localStorage`
保存在当前设备上，并与桌面版共用同一套 Vue 界面和存储键。

仓库已提供 GitHub Pages 工作流：`.github/workflows/deploy-pages.yml`。
在 GitHub 仓库的 Settings → Pages 中将 Source 设为 GitHub Actions，向 `main`
分支推送后会自动执行：

```bash
npm ci
npm run build
```

部署完成后，GitHub Pages 会生成项目站点地址；无需预先配置域名或密钥。

## 本机环境注意事项（重要）

这台机器的开发环境有三个特殊情况，脚本已全部适配，换机器可忽略：

1. **`node` 是 Kimi 客户端的 Electron 伪装版**（`ELECTRON_RUN_AS_NODE=1` 全局注入）。
   - 跑打包脚本必须用独立 Node：`.tools/node/node.exe`（npm scripts 已写死）
   - 手动启动 Electron GUI 前必须 `unset ELECTRON_RUN_AS_NODE`
2. **工作区文件被桌面客户端实时锁定**：打包输出一律走系统临时目录
   （`%TEMP%/todo-list-release`），再用流式复制回 `release/`。
3. **Device Guard 策略**可能拦截新构建的未签名 exe（报错
   「已被你的组织 Device Guard 策略阻止」）。NSIS 安装包及其安装后的
   程序不受影响；若遇到拦截，换目录运行或对 exe 做代码签名即可。

## 目录

```
├── electron/       # Electron 主进程与预加载脚本
├── scripts/        # dev-electron / build-server / build-app 脚本
├── server/         # FastAPI 后端 + schema.sql + 冒烟测试
├── src/            # Vue 前端（App / Sidebar / TodoItem / TodoEditor）
└── release/        # 打包产物（安装包 + 免安装目录）
```
