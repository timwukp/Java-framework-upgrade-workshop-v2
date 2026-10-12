<!-- source: docs/quick-reference.md @ a9b4611446ce6963150e0ff2545b8da0f3095436 -->
# 每日速查表

[English](quick-reference.md) · **中文（台灣）**

工作坊當天用的一頁說明。更多資訊：[遷移重點表](migration-cheat-sheet.md)（每個階段改了什麼）·
[疑難排解](troubleshooting.md)（症狀與修正）· [Kiro 功能參考](kiro-feature-reference.md)（功能、檔案格式、文件連結）·
[腳本](../scripts/README.md)。這些頁面與各模組皆為英文。

## 一天的全貌

每個階段都有 **14 個測試**（9 個 service + 5 個 web）。所有指令都在 `sample-app/` 中執行。

| 模組 | 起點 | JDK | Hooks（verify / guard） | 結束時的 tag |
|---|---|---|---|---|
| 1 環境設定與評估 | 基準 | 8 | 開 / 關 | `stage-0` |
| 2 Spring Boot 2.7 + Java 21 | `stage-0` | 8，在切換 JDK 的步驟改為 **21** | 開 / 關 | `stage-1` |
| 3 Spring Boot 3.5 + Jakarta EE | `stage-1` | 21 | guard 在開始時**開啟**（之後保持開啟）；建置刻意失敗期間 verify **暫停**，結束前**重新開啟** | `stage-2` |
| 4 Spring Boot 4.1 + Java 25 | `stage-2` | 21，在 Java 25 段落改為 **25** | 開 / 開 | `stage-3` |
| 5 品質關卡 | `stage-3` | 25 | 開 / 開（只在 Bugfix 示範或實作時暫停 verify） | `stage-3-final` |
| 6、7（選修） | `stage-3-final` | 25 | 開 / 開 | — |

「verify」指 `verify-after-spec-task`，「guard」指 `jakarta-import-guard`。在 Agent Hooks 面板用眼睛圖示切換 hooks。

**切換 JDK（模組 2 與 4，以及重設之後）：** 把新的 JDK 設為新終端機的預設值，完全結束 Kiro，在 `sample-app/`
開一個新的終端機，用 `kiro .` 啟動 Kiro，再請 agent 執行 `mvn -v`。做法：
[Switch the JDK per terminal](participant-setup.md#switch-the-jdk-per-terminal)。

## 腳本

| 指令（在 `sample-app/` 中） | 作用 |
|---|---|
| `../scripts/check-env.sh --stage N` | 檢查工具、終端機與 Maven 使用的 JDK、Maven 快取、steering 與 hook 檔案。不會建置。 |
| `../scripts/verify-stage.sh N` | 一次乾淨建置；只有 JDK 與 parent 正確且結果為 `Tests run: 14, Failures: 0, Errors: 0, Skipped: 0` 時才通過 |
| `../scripts/compare-stage.sh N` | 把你的 `pom.xml` 與 `src/` 和階段 1、2 或 3 的參考解答比較 |
| `../scripts/reset-to-stage.sh N` | 趕進度：換成階段 0、1、2、3 或 `3-final` 的參考 `pom.xml` 與 `src/`，並列出接下來要你親手輸入的步驟 |
| `../scripts/smoke.sh` | 對執行中的應用程式做下表的檢查；需要先 export `APP_ADMIN_PASSWORD` |

Git commit 與 tag、切換 JDK、重新啟動 Kiro、切換 hooks 都維持手動：它們是學習內容的一部分。

## 每次都要做

- **Supervised** 模式（`kiroAgent.agentAutonomy`）：每個 hunk 套用前先審查。
- **每次讓 agent 執行前先 commit。** Kiro checkpoints（檢查點）不會記錄 shell 指令（Maven、OpenRewrite）或你手動的修改。
- **一次只跑一個建置。** spec 任務完成後，到 Kiro output 讀 hook 的結果，或等 hook 結束後才自己執行 Maven
  （建置共用 `target/`）。
- **一律加 `clean`**（`mvn -B clean verify`）：否則切換 JDK 或版本後，Maven 可能略過重新編譯而藏住陷阱。
- **讀你自己的 `Tests run`。** 測試變少的綠色建置就是失敗的步驟。
- **切換 JDK 之後**，結束 Kiro，再從那個終端機用 `kiro .` 啟動。
- **信任（Trust）**工作區，否則儲存庫的 steering、agents 與 skills 不會載入。為這個工作區用 **Always allow**
  核准一次 `mvn *`；永遠不要預先核准部署或 push。
- `migration-reviewer` 審查之後執行 `git status`：它沒有 `write` 工具，但有 `shell`。

## 選對工作階段

| 你想要… | 使用 |
|---|---|
| 理解程式碼、不做任何修改 | **Plan** 工作流程（唯讀） |
| 經過審查、多步驟的變更 | **Spec**（requirements → design → tasks） |
| 範圍已經確定的變更（模組 3 與 4：playbook 裡的一整個階段），一次產生、沒有核准關卡 | **Quick Spec**，在任何任務執行前先審查檔案 |
| 修正回歸問題，並防止弄壞更多東西 | **Bug Fix**（`bugfix.md`） |
| 自由提問、反覆嘗試 | Default agent |
| 專門角色 | Agent selector → `migration-reviewer` |

聊天中的 context（上下文）：`#codebase` · `#file`（輸入 `#` 再加檔名）· `#folder` · `#git diff` ·
`#terminal` · `#problems` · `#spec` · `#steering` · `#docs` · `#url` · `#code` · `#current` ·
`#repository` · `#mcp`。選取程式碼後按 **Cmd/Ctrl+L** 加入聊天。

## 執行中的應用程式會回應什麼

`../scripts/smoke.sh` 會檢查這些項目，也可以用 `curl -u admin:"$APP_ADMIN_PASSWORD" …` 自己呼叫：

| 請求 | 階段 0–1 | 階段 2–3 |
|---|---|---|
| 不帶帳密的 `GET /api/users` | 401 | 401 |
| 以 admin 身分 `GET /api/users` | 200，並帶 `X-Request-Id` 標頭 | 200，並帶 `X-Request-Id` 標頭 |
| e-mail 不合法的 `POST /api/users` | 400 | 400 |
| 只有 name 與 e-mail 的 `POST /api/users` | 201，`"active":true`，ISO-8601 的 `createdDate` | 201，`"active":true`，ISO-8601 的 `createdDate` |
| 再送一次相同的 e-mail | 400 | 400 |
| `GET /api/users/999999` | 404 | 404 |
| `GET /api/users/`（結尾斜線） | 200 | **404**（Spring Framework 6 以上） |

Class 檔的 major version（`javap -v … | grep "major version"`）：**52** Java 8 · **65** Java 21 · **69** Java 25。

## 最常見的問題

| 症狀 | 前往 |
|---|---|
| `BUILD SUCCESS` 但 `Tests run: 0` | [T-B01](troubleshooting.md#t-b01-build-success-but-tests-run-0-or-no-tests-run-line) |
| Tests run 少於 14 | [T-B02](troubleshooting.md#t-b02-tests-run-is-lower-than-14) |
| `expected:<400> but was:<201>` | [T-B03](troubleshooting.md#t-b03-invaliduserisrejectedbybeanvalidation-expected400-but-was201) |
| 隨機出現的編譯或 Surefire 錯誤 | [T-B04](troubleshooting.md#t-b04-random-compile-or-surefire-errors-that-go-away-on-a-rerun-or-a-corrupt-jar) |
| agent 的 Java 和你的終端機不同 | [T-A02](troubleshooting.md#t-a02-the-agents-or-the-hooks-java-is-not-your-terminals) |
| verify hook 從未執行 | [T-K15](troubleshooting.md#t-k15-the-verify-hook-never-runs) |
| JDK 25 上 getter 出現 `cannot find symbol` | [T-B11](troubleshooting.md#t-b11-cannot-find-symbol-for-getters-setters-or-constructors-on-jdk-25) |
| Spring Boot 4 上每次建立都回 400 | [T-B12](troubleshooting.md#t-b12-validuseriscreated-status-expected201-but-was400-every-create-returns-400) |
| web 測試得到 403 | [T-B13](troubleshooting.md#t-b13-a-web-test-gets-403-instead-of-400-or-201) |
| 落後或卡住 | [T-X04](troubleshooting.md#t-x04-you-are-behind-or-your-workspace-is-broken) |

## 原始指令

```bash
mvn -B clean verify
```
```bash
mvn -B dependency:tree -Dincludes=org.projectlombok,net.bytebuddy
```
```bash
mvn -B clean test-compile -Dmaven.compiler.showDeprecation=true -Dmaven.compiler.showWarnings=true | grep -iE "deprecat|removal"
```
```bash
grep -rnE '^import (static )?javax\.((persistence|validation|servlet|inject|jms|mail|websocket|ejb|faces|el|xml\.bind|xml\.ws|ws\.rs)\.|annotation\.(PostConstruct|PreDestroy|Resource|security\.)|transaction\.[A-Z*])' src
```

附註的階段 tag 會記錄測試數量（`stage-0`、`stage-1`、`stage-2`、`stage-3`，模組 5 再加上 `stage-3-final`）：

```bash
git tag -a stage-1 -m "Stage 1: Java 21, Spring Boot 2.7.18, Tests run: 14" && git tag -n1 -l "stage-*"
```

落後了？在 `sample-app/` 中使用 [solutions/README.md](../solutions/README.md) 裡唯一的重設程序。
