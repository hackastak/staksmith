/**
 * Pi footer for the stoplight status line.
 *
 * Pi has no Claude Code `statusLine` command and no subscription `rate_limits`
 * payload, so this draws the same bar through `ctx.ui.setFooter`. The 7-day
 * gauge is self-tracked tokens against `PI_WEEKLY_TOKEN_BUDGET` and stays hidden
 * when that budget is unset.
 *
 * Install: copy or re-export this file from `~/.pi/agent/extensions/`.
 */

import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { type TUI, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import {
	contextSegment,
	gitPlace,
	joinSegments,
	readBranch,
	statusLine,
	turnsSegment,
	weekSegment,
	workHalf,
} from "./layout.js";

const USAGE_FILE = join(homedir(), ".pi", "agent", "statusline-usage.json");
const WEEKLY_WINDOW_DAYS = 7;
const RETENTION_DAYS = 40;

type Tone = "success" | "warning" | "error" | "text";

interface UsageStore {
	lifetime: number;
	daily: Record<string, number>;
}

interface PaintedSegment {
	text: string;
	tone: Tone;
}

function budget(name: string): number | null {
	const raw = process.env[name];
	if (!raw) return null;
	const value = Number(raw);
	return Number.isFinite(value) && value > 0 ? value : null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function parseUsage(raw: unknown): UsageStore {
	if (!isRecord(raw)) return { lifetime: 0, daily: {} };
	const daily: Record<string, number> = {};
	if (isRecord(raw.daily)) {
		for (const [key, value] of Object.entries(raw.daily)) {
			if (typeof value === "number" && Number.isFinite(value)) daily[key] = value;
		}
	}
	return {
		lifetime: typeof raw.lifetime === "number" && Number.isFinite(raw.lifetime) ? raw.lifetime : 0,
		daily,
	};
}

function loadUsage(): UsageStore {
	try {
		return parseUsage(JSON.parse(readFileSync(USAGE_FILE, "utf8")));
	} catch {
		return { lifetime: 0, daily: {} };
	}
}

function saveUsage(usage: UsageStore): void {
	try {
		mkdirSync(dirname(USAGE_FILE), { recursive: true });
		writeFileSync(USAGE_FILE, JSON.stringify(usage));
	} catch {
		// A status line must never break the session over a failed write.
	}
}

function dateKey(date = new Date()): string {
	const month = String(date.getMonth() + 1).padStart(2, "0");
	const day = String(date.getDate()).padStart(2, "0");
	return `${date.getFullYear()}-${month}-${day}`;
}

function prune(usage: UsageStore): UsageStore {
	const cutoff = dateKey(new Date(Date.now() - RETENTION_DAYS * 86_400_000));
	const daily: Record<string, number> = {};
	for (const [key, value] of Object.entries(usage.daily)) {
		if (key >= cutoff) daily[key] = value;
	}
	return { lifetime: usage.lifetime, daily };
}

function weeklyTokens(usage: UsageStore): number {
	let total = 0;
	for (let offset = 0; offset < WEEKLY_WINDOW_DAYS; offset++) {
		total += usage.daily[dateKey(new Date(Date.now() - offset * 86_400_000))] || 0;
	}
	return total;
}

function tokenCount(message: Record<string, unknown>): number {
	const usage = message.usage;
	if (!isRecord(usage)) return 0;
	if (typeof usage.totalTokens === "number") return usage.totalTokens;
	const input = typeof usage.input === "number" ? usage.input : 0;
	const output = typeof usage.output === "number" ? usage.output : 0;
	return input + output;
}

function sessionTokens(entries: readonly unknown[]): number {
	let total = 0;
	for (const entry of entries) {
		if (!isRecord(entry) || entry.type !== "message" || !isRecord(entry.message)) continue;
		if (entry.message.role !== "assistant") continue;
		total += tokenCount(entry.message);
	}
	return total;
}

function userTurnCount(entries: readonly unknown[]): number {
	let count = 0;
	for (const entry of entries) {
		if (!isRecord(entry) || entry.type !== "message" || !isRecord(entry.message)) continue;
		if (entry.message.role === "user") count += 1;
	}
	return count;
}

interface ThemePainter {
	fg(color: Tone, text: string): string;
}

function paint(theme: ThemePainter, segment: PaintedSegment): string {
	return theme.fg(segment.tone, segment.text);
}

function modelName(model: { name?: string; id?: string } | undefined): string {
	return model?.name || model?.id || "";
}

export default function staksmithStatusline(pi: ExtensionAPI) {
	const weeklyBudget = budget("PI_WEEKLY_TOKEN_BUDGET");
	let usage = loadUsage();
	let baseline = 0;
	let prompting = false;
	let tui: TUI | undefined;

	function accrue(entries: readonly unknown[]): void {
		const current = sessionTokens(entries);
		const delta = current - baseline;
		if (delta <= 0) return;
		baseline = current;
		const today = dateKey();
		const next: UsageStore = {
			lifetime: usage.lifetime + delta,
			daily: { ...usage.daily, [today]: (usage.daily[today] || 0) + delta },
		};
		usage = prune(next);
		saveUsage(usage);
		tui?.requestRender();
	}

	function tabTitle(cwd: string, icon: "" | "🔴 " | "🟢 "): string {
		const place = gitPlace(cwd);
		const branch = readBranch(cwd);
		const repo = place?.name ?? "";
		const label = branch && repo ? `${branch} · ${repo}` : branch || repo;
		return `${icon}${label}`;
	}

	pi.on("session_start", async (_event, ctx) => {
		usage = loadUsage();
		baseline = sessionTokens(ctx.sessionManager.getBranch());
		if (ctx.mode !== "tui") return;

		ctx.ui.setFooter((tuiInstance, theme, footerData) => {
			tui = tuiInstance;
			const unsub = footerData.onBranchChange(() => tuiInstance.requestRender());

			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					const branch = footerData.getGitBranch();
					const entries = ctx.sessionManager.getBranch();
					const claude: PaintedSegment[] = [
						{
							text: ctx.isIdle() ? "✏️ ready" : "⏳ working",
							tone: "text",
						},
					];

					const context = ctx.getContextUsage();
					if (context?.percent !== null && context?.percent !== undefined) {
						claude.push(contextSegment(context.percent));
					}

					const turns = userTurnCount(entries);
					if (turns > 0) claude.push(turnsSegment(turns));

					const name = modelName(ctx.model);
					if (name) claude.push({ text: `🧠 ${name}`, tone: "text" });

					if (weeklyBudget) {
						claude.push(weekSegment((weeklyTokens(usage) / weeklyBudget) * 100));
					}

					const line = statusLine({
						work: workHalf(ctx.cwd, branch ?? undefined),
						claude: joinSegments(claude.map(segment => paint(theme, segment))),
					});
					return [visibleWidth(line) > width ? truncateToWidth(line, width) : line];
				},
			};
		});
		ctx.ui.setTitle(tabTitle(ctx.cwd, "🟢 "));
	});

	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.mode === "tui") {
			ctx.ui.setTitle(tabTitle(ctx.cwd, ""));
			tui?.requestRender();
		}
	});

	pi.on("agent_end", async (_event, ctx) => {
		if (ctx.mode === "tui") {
			ctx.ui.setTitle(tabTitle(ctx.cwd, prompting ? "🔴 " : "🟢 "));
			tui?.requestRender();
		}
	});

	pi.on("ui_prompt_start", async (_event, ctx) => {
		prompting = true;
		if (ctx.mode === "tui") {
			ctx.ui.setTitle(tabTitle(ctx.cwd, "🔴 "));
			tui?.requestRender();
		}
	});

	pi.on("ui_prompt_end", async (_event, ctx) => {
		prompting = false;
		if (ctx.mode === "tui") {
			ctx.ui.setTitle(tabTitle(ctx.cwd, ctx.isIdle() ? "🟢 " : ""));
			tui?.requestRender();
		}
	});

	pi.on("turn_end", async (_event, ctx) => {
		accrue(ctx.sessionManager.getBranch());
	});
}
