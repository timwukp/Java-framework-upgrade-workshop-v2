# Power: java-modernization

A Kiro power in the [Agent Plugins format](https://kiro.dev/docs/powers/create/): a `plugin.json`
manifest plus `skills/`. It packages the stage 3 know-how (Spring Boot 3.5 → 4.x, Java 21 → 25) so other
teams can install it and use it on their own services.

```text
java-modernization/
├── plugin.json                      # name, version, description, author, keywords (activation)
└── skills/
    ├── spring-boot-4-upgrade/SKILL.md
    └── java-25-adoption/SKILL.md
```

## Install locally (Module 4)

1. In Kiro, open the **Powers** panel.
2. Choose **Add Custom Power** → **Import power from a folder**.
3. Select this `powers/java-modernization/` folder (it contains `plugin.json`).
4. Click **Install**.
5. Test activation with a keyword from `plugin.json`, for example
   "Plan the Spring Boot 4 upgrade for this project".

## Share it

Push the folder to a public GitHub repository (it can sit at the repository root or in a subfolder).
Others install it with **Add Custom Power** → **Import power from GitHub**. See
[Install powers](https://kiro.dev/docs/powers/installation/).

## Extend it

- Add more skills under `skills/<name>/SKILL.md`. The `name` must match the folder name.
- Add an `mcp.json` if the power should bring tools. For example, the
  [Kiro Java guide](https://kiro.dev/docs/guides/languages-and-frameworks/java-guide/) shows a Maven MCP
  server started with `uvx`. Kiro namespaces MCP server names when the power is installed.
