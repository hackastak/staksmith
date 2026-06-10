/**
 * staksmith Plugin for OpenCode
 *
 * This package provides the published staksmith OpenCode plugin module:
 * - Plugin hooks (auto-format, TypeScript check, console.log warning, env injection, etc.)
 * - Custom tools (run-tests, check-coverage, security-audit, format-code, lint-check, git-summary)
 * - Bundled reference config/assets for the wider staksmith OpenCode setup
 *
 * Usage:
 *
 * Option 1: Install via npm
 * ```bash
 * npm install staksmith
 * ```
 *
 * Then add to your opencode.json:
 * ```json
 * {
 *   "plugin": ["staksmith"]
 * }
 * ```
 *
 * That enables the published plugin module only. For staksmith commands, agents,
 * prompts, and instructions, use this repository's `.opencode/opencode.json`
 * as a base or copy the bundled `.opencode/` assets into your project.
 *
 * Option 2: Clone and use directly
 * ```bash
 * git clone https://github.com/hackastak/staksmith
 * cd staksmith
 * opencode
 * ```
 *
 * @packageDocumentation
 */

// Export the main plugin
export { StaksmithHooksPlugin, default } from "./plugins/index.js"

// Export individual components for selective use
export * from "./plugins/index.js"

// Version export
export const VERSION = "1.6.0"

// Plugin metadata
export const metadata = {
  name: "staksmith",
  version: VERSION,
  description: "staksmith plugin for OpenCode",
  author: "hackastak",
  features: {
    agents: 13,
    commands: 31,
    skills: 37,
    configAssets: true,
    hookEvents: [
      "file.edited",
      "tool.execute.before",
      "tool.execute.after",
      "session.created",
      "session.idle",
      "session.deleted",
      "file.watcher.updated",
      "permission.ask",
      "todo.updated",
      "shell.env",
      "experimental.session.compacting",
    ],
    customTools: [
      "run-tests",
      "check-coverage",
      "security-audit",
      "format-code",
      "lint-check",
      "git-summary",
    ],
  },
}
