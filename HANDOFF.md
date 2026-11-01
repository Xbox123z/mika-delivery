# HANDOFF — dsh ↔ Workbuddy 协作看板

> 用法：谁要对方接手，就在下面「当前待办」写 `@<对方> 请接手：...`，
> 并在提交信息里带 `HANDOFF: @<对方>`。另一侧每 30 分钟扫一次本文件 + 提交信息。

---

## 当前待办

**@Workbuddy 请接手：暂无 —— 现由 dsh 接手验证中**

## 状态：dsh 已接手（2026-11-01 15:45）

### ✅ Workbuddy 已完成
- 基于上游 `wangzan101/Mika @ 736b53d` 派生
- 7 文件改动（+135 / −10）：核心 `ModelSetupViewModel.kt` + 3 语言资源 + 2 UI + 1 测试
- Kotlin 语法检查干净，`gradle :app:testDebugUnitTest` **151 类 / 1071 用例全绿**
- `gradle :app:assembleDebug` 成功，两个 APK 已发 Release `v0.1.0-decision-nonmain`
- 文档齐全：`docs/decision-nonmain/README.md` + `完成报告.md`

### 🔄 dsh 接手进展
- [x] 读通 README / 完成报告，复核根因与我的原判断一致并更精确：
      `core/model/ModelAccessErrors.kt:60` 只认 400/403/404 → 503 落到 `ModelError.Server`
      → `probe()` 收尾 `rejected.all { serverSide }` → 整家 Blocked
- [x] 下载 test APK：99,644,837 bytes，`testzip=OK`，894 条目，32 个 dex
- [x] 确认包名 `com.wangzan101.mika.test`，versionName `0.1.27`，minSdk 30，**可与官方版并存**
- [x] APK 已放到手机 `Download/mika-test-0.1.27.apk` 与 `鹿/mika-test-0.1.27.apk`
- [ ] **安装验证 ← 当前阻塞**

### 🚫 阻塞：三个自动化通道全断
手机重启（uptime 20min）之后：
- **Shizuku 服务停止** —— 非 root 设备重启后必须用 USB 或无线调试重新拉起
- **ADB 5555 关闭** —— `adb tcpip 5555` 不跨重启持久化
- **无障碍服务报未开启** —— `android_ui_dump` 走不通

=> 无法执行 `pm install`，也无法用 UI 自动化点安装。
=> 目前需要用户手动点一次安装，或恢复任意一条通道。

### ⏭️ 下一步（按 README 第 6 节 5 条验收）
1. 用户手动安装 `mika-test-0.1.27.apk`
2. dsh 验证：
   - [ ] 只有决策类模型的服务商能保存成功
   - [ ] 保存后有提示「到用途里选」
   - [ ] 「用途」→ 看图 / 轻量 能选中该模型
   - [ ] 「主模型」页选它被拦下且原因可读
   - [ ] 原主模型（DeepSeek）日常对话不受影响
3. 结果回写本文件，`@Workbuddy` 告知

---

## 约定
- 扫描频率：每 30 分钟
- 识别信号：本文件标题下方「当前待办」里的 `@Workbuddy` / `@dsh`，或提交信息里的 `HANDOFF:`
- **不中途插手**：看到信号后先把对方这一轮所有提交读完，确认推完再动手
- 写权限：dsh 侧 token 有 `repo` scope，push/admin 均为 true，可直接推送
