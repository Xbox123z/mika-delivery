# 让决策类模型（decision / startlux）不再拖垮整家服务商

改动主题：**服务商里只有 / 或包含决策类模型时，Mika 仍能保存这家服务商**；决策类模型可以分配给「用途」里的非主模型角色（看图 / 轻量），但**不允许当主模型**。

- 上游仓库：https://github.com/wangzan101/Mika
- 基线提交：`736b53d98b2975335d08eb1755055d1d08d1e894`（2026-11-01 03:27 +0800）
- 完整 diff：[`patches/mika-startlux-support-decision-nonmain.patch`](patches/mika-startlux-support-decision-nonmain.patch)
- 完整交付/验证记录：[`完成报告.md`](完成报告.md)

---

## 1. 现象

在 Bamboo Relay 一类的中转服务商上配置 `startlux-decision-27b-autothink` 后点「保存」，界面上服务商**完全没被保存**；换成 DeepSeek 之类的模型就正常。

## 2. 根因（已在真实源码里逐行复核）

HTTP 错误先过 core 的通用分类器 `core/src/main/kotlin/com/wangzan101/mika/core/model/ModelAccessErrors.kt:60`：

```kotlin
if (status != 400 && status != 403 && status != 404) return null
```

Bamboo Relay 返回的却是 **503**（响应体里才写 `model_not_found: No available channel for model startlux-decision-27b-autothink`）。503 不在上面三个状态码里 → 分类器放弃 → 落到 `ModelError.Server(503)` → `serverSide = true`。

于是 `ModelSetupViewModel.probe()`（有列表时的逐个试调用）在收尾处判定：

> 「试的全都是服务端出错」→ 整家服务商不可用 → `testAndSave()` 什么都不存。

**根子是「某个模型不可用」被当成了「这一家不可用」。** 聚合服务商把很多上游模型塞在同一个列表里，其中一个上游挂掉是常态，不该株连整家。

另外该类模型回答走的是自己的 `/v1/decisions` 接口，被 Mika 按 `/v1/chat/completions` 发工具调用测试时必然失败，因此它天生不适合当主模型。

## 3. 改动清单（7 个文件，+135 / −10）

| 文件 | 改动 |
| --- | --- |
| `app/src/main/java/com/wangzan101/mika/ui/ModelSetupViewModel.kt` | 核心逻辑：新增 `NON_MAIN_MODEL_TOKENS` 常量与 `isNonMainOnly()` / `nonMainReason()` / `setupProbeNote()`；`probe()` 收敛、状态新增 `nonMainRoleNote`；`pick()` 与 `pickManual()` 都拦「决策模型当主模型」并给出可读原因 |
| `app/src/main/java/com/wangzan101/mika/ui/ModelSetupScreen.kt` | 引导页把无需主模型的提示用警示色显示出来 |
| `app/src/main/java/com/wangzan101/mika/ui/ModelsScreen.kt` | 「用途」页顶部显示为什么这类模型只能占非主模型角色 |
| `app/src/main/res/values/strings_setup.xml` | 新增 3 条文案（英文） |
| `app/src/main/res/values-zh/strings_setup.xml` | 同上，简体中文 |
| `app/src/main/res/values-b+zh+Hant/strings_setup.xml` | 同上，繁体中文 |
| `app/src/test/java/com/wangzan101/mika/ui/ModelSetupViewModelTest.kt` | 新增 2 个用例：`providerWithOnlyDecisionModelsIsSavedWithoutAMainModel`、`decisionModelIsRejectedAsMainButUsableForAnotherRole` |

文案全部走项目既有的三语言资源机制，没有硬编码字符串。

### 行为对照

| 场景 | 改前 | 改后 |
| --- | --- | --- |
| 列表里只有决策类模型 | 服务商保存失败 | 服务商照常保存，主模型留空，提示去「用途」里选 |
| 列表里决策类在前、可用模型在后 | 可用模型被跳过 / 判定整家不可用 | 逐个继续试，通过后照常保存并把主模型设为它，提示里说明前面哪些没通过 |
| 把决策类模型设为主模型 | 静默失败（原 patch 只在注释里写了「弹 Toast」） | `pick()` / `pickManual()` 都拦下，给出中文原因「它在另一个（决策）接口上回答，工具的试调用过不了」 |
| Key 错 / 地址错 / 网络错 / 超时 | 判定整家不可用 | **完全没动**，保持原判定 |

## 4. 怎么应用到干净的上游源码

```bash
git clone https://github.com/wangzan101/Mika.git
cd Mika
git checkout 736b53d98b2975335d08eb1755055d1d08d1e894   # 对齐基线，也可直接用新版 HEAD
git apply docs/decision-nonmain/patches/mika-startlux-support-decision-nonmain.patch
```

一键脚本（自动 clone + 打补丁 + 出 APK）：[`scripts/build-apk.sh`](scripts/build-apk.sh)。

注意：本仓库给的 `expected-diff`-式原始补丁（用户提供）**不能直接用**，它有 hunk 行数不符、一处恒不成立的条件、把 `Rejected` 对象地址拼进文案等问题；这里提供的是重写版。详见 [`完成报告.md`](完成报告.md) 第三章。

## 5. 验证记录

| 项目 | 结果 |
| --- | --- |
| Kotlin 2.1.20 语法检查（改动的 3 个主文件） | 与基线对比无新增错误 |
| `gradle :app:testDebugUnitTest` | **151 个测试类 / 1071 个用例全绿，0 失败 0 错误** |
| `gradle :app:assembleDebug` | 构建成功（JDK 17 + Android SDK 36） |

编译环境脚本参见 [`scripts/build-apk.sh`](scripts/build-apk.sh)；CI 见 `.github/workflows/android-ci.yml`（push/PR 自动跑单测与 assembleDebug）。

## 6. 验收清单（真机）

1. 添加只有决策类模型的服务商 → **能保存成功**，不再弹失败。
2. 保存后出现提示：说明这些模型在决策接口上回答，请到「用途」里选。
3. 进入「用途」→ 看图 / 轻量 → **能选中**该模型，返回后角色上显示它。
4. 尝试在「主模型」页选它 → **被拦下**，提示里说清原因。
5. 主模型仍用原来的 DeepSeek 等，日常对话不受影响。

## 7. 已知边界与下一步

本改动只解决**「能配上、能选中」**，**没有实现 `/v1/decisions` 的实际调用**：真用它干活时，Mika 仍然按对话接口发请求。

要真正跑起来，还需要在 core 的推理层补一个走决策接口的模型实现，大致参照 `core/src/main/kotlin/com/wangzan101/mika/core/model/OpenAiCompatModel.kt`：

1. 新增一个走 `/v1/decisions` 的 model 实现，独立处理请求体与响应解析（不走 tool-calling）。
2. 在 `capabilities` 上标记「不可 tool-calling」，让上层在决定是否下发工具时跳过它。
3. 模型 id 判定沿用现有的 `isNonMainOnly()` token 表，不要各写一套。
4. 补 core 层的单元测试与一次真机冒烟。

## 8. 许可

本派生仓库沿用上游 **Apache-2.0** 许可，`LICENSE` / `NOTICE` / `THIRD_PARTY_NOTICES.md` 原样保留，原作者版权保留。正式版本请到上游 [releases](https://github.com/wangzan101/Mika/releases) 下载。
