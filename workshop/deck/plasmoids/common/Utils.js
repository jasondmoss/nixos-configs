/*
    Shared helpers for the Deck cards.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
.pragma library

var palette = {
    ok: "#3fcf8e",
    running: "#5aa9ff",
    warn: "#f5b942",
    error: "#ff5f6d",
    hold: "#c084fc",
    muted: "#8a8a94"
};

/* Any status word from git/gulp/CircleCI/Pantheon → palette key. */
function statusKey(status)
{
    switch (String(status || "").toLowerCase()) {
    case "success": case "succeeded": case "watching": case "ok": case "finished": case "clean":
        return "ok";
    case "running": case "compiling": case "starting": case "pending": case "created": case "queued": case "failing":
        return "running";
    case "on_hold": case "external": case "blocked":
        return "hold";
    case "failed": case "error": case "errored": case "unauthorized": case "infrastructure_fail": case "timedout": case "exited":
        return "error";
    case "warning": case "warn": case "dirty": case "canceled": case "cancelled": case "retried":
        return "warn";
    default:
        return "muted";
    }
}

function statusColor(status)
{
    return palette[statusKey(status)];
}

function statusIcon(status)
{
    switch (statusKey(status)) {
    case "ok": return "emblem-checked";
    case "running": return "media-playback-start";
    case "hold": return "media-playback-pause";
    case "error": return "emblem-error";
    case "warn": return "emblem-warning";
    default: return "emblem-question";
    }
}

/* Seconds since the epoch from an ISO string, epoch seconds, or Date. */
function epoch(value)
{
    if (value === undefined || value === null || value === "") {
        return NaN;
    }
    if (typeof value === "number") {
        return value;
    }
    if (value instanceof Date) {
        return value.getTime() / 1000;
    }
    var t = Date.parse(value);
    if (isNaN(t)) {
        // "2026-10-09T15:50:10-0400" — Date.parse wants a colon in the offset.
        t = Date.parse(String(value).replace(/([+-]\d\d)(\d\d)$/, "$1:$2"));
    }
    return t / 1000;
}

function relTime(value, now)
{
    var t = epoch(value);
    if (isNaN(t)) {
        return "";
    }
    var delta = Math.max(0, ((now || Date.now()) / 1000) - t);
    if (delta < 45) return "just now";
    if (delta < 3600) return Math.round(delta / 60) + " min ago";
    if (delta < 86400) return Math.round(delta / 3600) + " h ago";
    if (delta < 86400 * 14) return Math.round(delta / 86400) + " d ago";
    // No `Locale` enum in a .pragma library file: plain ISO date.
    var d = new Date(t * 1000);
    return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
}

function duration(seconds)
{
    if (seconds === undefined || seconds === null || isNaN(seconds)) {
        return "";
    }
    seconds = Math.round(seconds);
    if (seconds < 60) return seconds + "s";
    if (seconds < 3600) return Math.floor(seconds / 60) + "m " + (seconds % 60) + "s";
    return Math.floor(seconds / 3600) + "h " + Math.floor((seconds % 3600) / 60) + "m";
}

function plural(n, word)
{
    return n + " " + word + (n === 1 ? "" : "s");
}

function basename(path)
{
    var s = String(path || "");
    var i = s.lastIndexOf("/");
    return i >= 0 ? s.substring(i + 1) : s;
}

function dirname(path)
{
    var s = String(path || "");
    var i = s.lastIndexOf("/");
    return i > 0 ? s.substring(0, i) : "";
}

/* Human title for a CircleCI/Pantheon state word. */
function titleCase(word)
{
    var s = String(word || "").replace(/_/g, " ");
    return s.charAt(0).toUpperCase() + s.slice(1);
}
