/**
 * staksmith Plugins for OpenCode
 *
 * This module exports all staksmith plugins for OpenCode integration.
 * Plugins provide hook-based automation that mirrors Claude Code's hook system
 * while taking advantage of OpenCode's more sophisticated 20+ event types.
 */

export { StaksmithHooksPlugin, default } from "./staksmith-hooks.js"

// Re-export for named imports
export * from "./staksmith-hooks.js"
