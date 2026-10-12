<!-- source: README.md @ e3f1653026a83d056afa6eec690584bcf0819863 -->
# 用 Kiro 進行 Java 現代化工作坊

[English](README.md) · **中文（台灣）**

這是為期一天的實作工作坊：把一個老舊的 **Java 8 + Spring Boot 2.2** 服務，分階段、安全且可驗證地升級到
**Java 25 + Spring Boot 4.1（Spring Framework 7）**。過程中使用 [Kiro](https://kiro.dev) 的
spec（規格）、steering（引導規則）、hooks（掛鉤）、skills（技能）、custom agents（自訂代理）與
powers（擴充包）。

> 內容已於 **2026-10-09** 對照 Kiro 官方文件與 Spring / Java 的支援資料。Kiro 更新頻繁；若介面與本文說明不同，
> 以 [Kiro 文件](https://kiro.dev/docs/) 為準。

本頁與[每日速查表](docs/cheat-sheet.zh-TW.md)提供中文版；各模組、提示詞（prompt）、指令與預期輸出維持英文，
與 Kiro 介面一致。

## 你會學到什麼

- 用 **Plan** 工作階段與 **Feature spec**（requirements → design → tasks）規劃框架遷移。
- 把團隊標準寫成 **steering**（`always`、`fileMatch`、`manual`），讓 agent（代理）遵守。
- 讓 **hooks** 在每個 spec 任務完成後執行一次 `mvn -B clean verify`（並回報測試數量），並抓出 agent 遺留的
  `javax.*` import。
- 把可重複使用的經驗包成 **skills** 與一個 **power**，並用一個 **custom agent** 當審查者。它沒有 `write`
  工具，且被指示不得修改檔案；審查後你仍要檢查 `git status`。
- 找出不會讓建置失敗、之後才出現的遷移陷阱：悄悄失效的驗證、悄悄停止執行的測試、意義改變的安全規則，以及
  Jackson 3 拒絕合法建立請求的變更。

## 分階段路徑

| 階段 | 模組 | Java | Spring Boot | Spring Framework | 為何停在這裡 |
|---|---|---|---|---|---|
| 0 | 1 | 8 | 2.2.4 | 5.2.3 | 基準。Boot 2.2.4 官方文件標示相容到 Java 13（2.2 最後的修補版 2.2.13 到 Java 15）；從不支援 Java 21：在 JDK 21 上，Lombok 1.18.10 會以 `IllegalAccessError` 讓建置失敗。 |
| 1 | 2 | 21 | 2.7.18 | 5.3.x | 2.x 的最後一條版本線；仍是 `javax.*`；可在 Java 21 上執行。 |
| 2 | 3 | 21 | 3.5.x | 6.2.x | Jakarta EE 命名空間、Spring Security 6。中繼站：開源支援已於 2026-06-30 結束。 |
| 3 | 4 | 25 | 4.1.x | 7.0.x | 目標。Jakarta EE 11、Jackson 3、Spring Security 7、Java 25 LTS。 |

支援日期：[endoflife.date：Spring Boot](https://endoflife.date/spring-boot)、
[Spring Framework](https://endoflife.date/spring-framework)、[Java](https://endoflife.date/oracle-jdk)。

## Kiro 在這裡做什麼、不做什麼

Kiro **沒有一鍵「升級 Java」的轉換功能**。在這個工作坊中，由 agent 在你的指揮下完成遷移：

1. 一份 spec 把「升級到 Boot 3.5」變成經過審查的需求、設計與任務清單。
2. agent 執行這些任務。steering 與 skills 告訴它怎麼做；Supervised（監督）模式讓你審查每一個 hunk（變更區塊）。
3. 每個任務完成後，一個 hook 執行一次乾淨的 Maven 建置，並把測試數量或失敗訊息回報給 agent。
4. 你在每個階段 commit，因此隨時都能回到已知良好的狀態。

OpenRewrite recipes 或 AWS Transform power 等確定性工具，可以處理大量機械式變更。模組 4 的選修附錄（不在核心時間內）
介紹它們，包含前置條件與授權注意事項。

## 從這裡開始

| 你是… | 依序閱讀 |
|---|---|
| 學員 | [學員事前準備](docs/participant-setup.md)（工作坊前完成，60 到 120 分鐘，大多是下載時間）→ [模組 1](modules/01-setup-and-assessment.md)。當天開著[速查表](docs/cheat-sheet.zh-TW.md)與[疑難排解](docs/troubleshooting.md)。 |
| 自學 | 同上。每個模組最後都有你自己能執行的檢查；落後時，[重設到某個階段](solutions/README.md#reset-your-workspace-to-a-stage-the-one-procedure-all-modules-use)。 |
| 講師 | [講師手冊](docs/instructor-guide.md)與[議程](docs/agenda.md)，再把上面的學員路徑當作你的預演。 |

**工作坊前一週：** 取得 Kiro 付費方案或組織席位（免費方案的 credits（點數）撐不到一天結束）、向 IT 詢問安裝 JDK 21
與 25 及代理伺服器設定，macOS 使用者請先安裝 Xcode Command Line Tools。細節：
[學員事前準備第 0 節](docs/participant-setup.md#0-one-week-before)。

## 快速開始

完成[學員事前準備](docs/participant-setup.md)（JDK、Maven、Kiro 與登入、預先下載）之後，在 macOS 或 Linux
上、使用 JDK 8 的終端機中執行：

```bash
git clone https://github.com/timwukp/Java-framework-upgrade-workshop-v2.git
cd Java-framework-upgrade-workshop-v2/sample-app
mvn -B clean verify       # expect Tests run: 14 and BUILD SUCCESS
../scripts/check-env.sh   # am I ready? every line should say PASS
kiro .                    # opens sample-app/ as the Kiro workspace, with this terminal's JDK
```

工作區是 **`sample-app/` 資料夾**，不是儲存庫根目錄。信任（Trust）這個工作區，然後開始
[模組 1](modules/01-setup-and-assessment.md)。每次變更使用中的 JDK 後，都要結束 Kiro，再從那個終端機用
`kiro .` 重新啟動。

## 儲存庫結構

| 路徑 | 內容 |
|---|---|
| [`modules/`](modules/) | 七個模組：[1](modules/01-setup-and-assessment.md) · [2](modules/02-runway-boot27-java21.md) · [3](modules/03-spring-boot-3.md) · [4](modules/04-spring-boot-4-java25.md) · [5](modules/05-quality-gates.md) · [6（選修）](modules/06-platform-deployment.md) · [7（選修）](modules/07-scale-out-cli-web.md) |
| [`sample-app/`](sample-app/) | **在 Kiro 中開啟這個資料夾。** 老舊的起點（階段 0），內含工作坊的 `.kiro/` steering、hooks、自訂代理與 skills |
| [`docs/participant-setup.md`](docs/participant-setup.md) | 安裝 JDK 8/21/25、Maven 與 Kiro；基準建置；預先下載 |
| [`docs/cheat-sheet.zh-TW.md`](docs/cheat-sheet.zh-TW.md) | 中文速查表：各階段、JDK、hooks、腳本、預期結果（英文版：[`docs/quick-reference.md`](docs/quick-reference.md)） |
| [`docs/troubleshooting.md`](docs/troubleshooting.md) | 所有已知症狀、原因與修正，附固定編號 |
| [`docs/migration-cheat-sheet.md`](docs/migration-cheat-sheet.md) | 每個階段改了什麼、為什麼 |
| [`docs/kiro-feature-reference.md`](docs/kiro-feature-reference.md) | 用到的每個 Kiro 功能、檔案格式與文件連結 |
| [`docs/agenda.md`](docs/agenda.md) | 時間表，以及落後時可以略過什麼 |
| [`docs/instructor-guide.md`](docs/instructor-guide.md) | 預演、流程、現場控管 |
| [`docs/verification-log.md`](docs/verification-log.md) | 預演驗證了什麼、還有什麼尚未驗證 |
| [`scripts/`](scripts/README.md) | 從 `sample-app/` 執行的輔助腳本：`check-env`、`verify-stage`、`compare-stage`、`reset-to-stage`、`smoke` |
| [`solutions/`](solutions/README.md) | 階段 1、2、3 結束時的參考狀態，以及唯一的重設程序（刻意放在工作區之外） |
| [`powers/java-modernization/`](powers/java-modernization/README.md) | 模組 4 匯入的 Kiro power（Agent Plugins 格式） |
| [`tools/`](tools/README.md) | 維護者用的文件與腳本檢查，以及如何撰寫模組 |

## 前置條件

- **macOS 或 Linux。** hooks 與各模組的指令都是 POSIX shell。Windows 使用者請用 Linux 虛擬機或雲端桌面
  （WSL2 未經測試）。
- JDK 8、21 與 25（例如 [Amazon Corretto](https://aws.amazon.com/corretto/)）、Maven 3.9+、Git 2.23+、
  `python3` 與 `curl`
- [Kiro IDE](https://kiro.dev/docs/getting-started/installation/) 1.x，以及付費方案或組織席位：一整天用掉的
  credits 超過免費方案的每月額度（見 [participant-setup.md](docs/participant-setup.md)）。
- 能閱讀 Java 與 Spring 程式碼。不需要事先用過 Kiro。

## 安全注意事項

- 這個儲存庫中沒有儲存任何密碼。除非你設定 `APP_ADMIN_PASSWORD` / `APP_USER_PASSWORD`，範例應用程式會在啟動時
  產生記憶體中的使用者密碼。
- Kiro 的權限規則以使用者為單位。被詢問時，為這個工作區預先核准 `mvn *`；永遠不要預先核准部署或 push 指令。

## 授權

[MIT](LICENSE)
