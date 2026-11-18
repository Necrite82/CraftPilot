"""CraftPilot Discord bug bridge.

Watches the #bug-reports forum on Discord:

* When a moderator adds the "confirmed" tag to a forum post, the bot opens a
  GitHub issue (label "bug") with the post text and a link back to Discord,
  then replies in the thread with the issue link.
* Every few minutes it asks GitHub whether those issues were closed. A closed
  issue (completed) switches the Discord post to the "fixed" tag and the bot
  posts a short note in the thread.

GitHub is polled, so the bot needs no open port and runs fine behind NAT.
Configuration comes from environment variables (see .env.example).
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import sys
from dataclasses import dataclass
from pathlib import Path

import aiohttp
import discord

log = logging.getLogger("craftpilot-bot")

GITHUB_API = "https://api.github.com"
MAX_BODY = 60000  # GitHub allows 65536 characters per issue body


# --------------------------------------------------------------------------- config

@dataclass(frozen=True)
class Config:
    discord_token: str
    forum_id: int
    github_token: str
    github_repo: str  # "owner/name"
    confirmed_tag: str = "Bestätigt"
    fixed_tag: str = "Behoben / Fixed"
    issue_labels: tuple[str, ...] = ("bug",)
    poll_seconds: int = 300
    state_file: Path = Path("/var/lib/craftpilot-bot/state.json")

    @classmethod
    def from_env(cls, env: dict[str, str] | None = None) -> "Config":
        env = dict(os.environ if env is None else env)
        missing = [k for k in ("DISCORD_TOKEN", "BUG_FORUM_ID", "GITHUB_TOKEN", "GITHUB_REPO") if not env.get(k)]
        if missing:
            raise SystemExit("Fehlende Einstellungen / missing settings: " + ", ".join(missing))
        repo = env["GITHUB_REPO"].strip()
        if repo.count("/") != 1:
            raise SystemExit("GITHUB_REPO muss die Form owner/name haben, z. B. Necrite82/CraftPilot")
        labels = tuple(l.strip() for l in env.get("ISSUE_LABELS", "bug").split(",") if l.strip())
        return cls(
            discord_token=env["DISCORD_TOKEN"].strip(),
            forum_id=int(env["BUG_FORUM_ID"]),
            github_token=env["GITHUB_TOKEN"].strip(),
            github_repo=repo,
            confirmed_tag=env.get("CONFIRMED_TAG", cls.confirmed_tag),
            fixed_tag=env.get("FIXED_TAG", cls.fixed_tag),
            issue_labels=labels,
            poll_seconds=max(60, int(env.get("POLL_SECONDS", "300"))),
            state_file=Path(env.get("STATE_FILE", str(cls.state_file))),
        )


# --------------------------------------------------------------------------- state

class State:
    """Remembers which Discord thread belongs to which GitHub issue."""

    def __init__(self, path: Path):
        self.path = path
        self.threads: dict[str, dict] = {}
        if path.exists():
            self.threads = json.loads(path.read_text(encoding="utf-8")).get("threads", {})

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".tmp")
        tmp.write_text(json.dumps({"threads": self.threads}, indent=2), encoding="utf-8")
        tmp.replace(self.path)

    def issue_for(self, thread_id: int) -> dict | None:
        return self.threads.get(str(thread_id))

    def remember(self, thread_id: int, issue_number: int, issue_url: str) -> None:
        self.threads[str(thread_id)] = {"issue": issue_number, "url": issue_url, "closed": False}
        self.save()

    def open_entries(self) -> list[tuple[int, dict]]:
        return [(int(t), e) for t, e in self.threads.items() if not e.get("closed")]

    def mark_closed(self, thread_id: int) -> None:
        self.threads[str(thread_id)]["closed"] = True
        self.save()


# --------------------------------------------------------------------------- pure helpers

def tag_names(tags) -> list[str]:
    return [t.name for t in tags]


def newly_added(before: list[str], after: list[str], name: str) -> bool:
    return name in after and name not in before


def build_issue(title: str, content: str, tags: list[str], attachments: list[str], url: str,
                confirmed_tag: str) -> tuple[str, str]:
    """Issue title and Markdown body for a confirmed forum post."""
    shown_tags = [t for t in tags if t != confirmed_tag]
    lines = [
        f"> Aus Discord übernommen / imported from Discord: {url}",
        "",
        content.strip() or "_(kein Text / no text)_",
    ]
    if attachments:
        lines += ["", "**Anhänge / attachments:**"] + [f"- {a}" for a in attachments]
    if shown_tags:
        lines += ["", "Discord-Tags: " + ", ".join(shown_tags)]
    body = "\n".join(lines)
    if len(body) > MAX_BODY:
        body = body[:MAX_BODY] + "\n\n… (gekürzt / truncated – siehe Discord)"
    return title.strip()[:250] or "Bug aus Discord", body


def swap_tags(current: list[str], remove: str, add: str, limit: int = 5) -> list[str]:
    """New tag list: `remove` taken out, `add` put in, Discord's 5-tag limit kept."""
    result = [t for t in current if t != remove and t != add]
    result.insert(0, add)
    return result[:limit]


def thread_url(guild_id: int, thread_id: int) -> str:
    return f"https://discord.com/channels/{guild_id}/{thread_id}"


# --------------------------------------------------------------------------- GitHub

class GitHub:
    def __init__(self, token: str, repo: str):
        self.repo = repo
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "craftpilot-discord-bot",
        }
        self.session: aiohttp.ClientSession | None = None

    async def _session(self) -> aiohttp.ClientSession:
        if self.session is None or self.session.closed:
            self.session = aiohttp.ClientSession(headers=self.headers, timeout=aiohttp.ClientTimeout(total=30))
        return self.session

    async def create_issue(self, title: str, body: str, labels: tuple[str, ...]) -> dict:
        s = await self._session()
        payload = {"title": title, "body": body, "labels": list(labels)}
        async with s.post(f"{GITHUB_API}/repos/{self.repo}/issues", json=payload) as r:
            if r.status != 201:
                raise RuntimeError(f"GitHub {r.status}: {await r.text()}")
            return await r.json()

    async def get_issue(self, number: int) -> dict:
        s = await self._session()
        async with s.get(f"{GITHUB_API}/repos/{self.repo}/issues/{number}") as r:
            if r.status != 200:
                raise RuntimeError(f"GitHub {r.status}: {await r.text()}")
            return await r.json()

    async def close(self) -> None:
        if self.session and not self.session.closed:
            await self.session.close()


# --------------------------------------------------------------------------- Discord

class BugBridge(discord.Client):
    def __init__(self, cfg: Config):
        intents = discord.Intents.default()
        intents.message_content = True  # needed to read the text of the forum post
        super().__init__(intents=intents)
        self.cfg = cfg
        self.state = State(cfg.state_file)
        self.github = GitHub(cfg.github_token, cfg.github_repo)
        self._busy: set[int] = set()

    async def setup_hook(self) -> None:
        self.loop.create_task(self._poll_github())

    async def close(self) -> None:
        await self.github.close()
        await super().close()

    async def on_ready(self) -> None:
        forum = self.get_channel(self.cfg.forum_id)
        if not isinstance(forum, discord.ForumChannel):
            log.error("BUG_FORUM_ID %s ist kein Forum, das der Bot sehen kann", self.cfg.forum_id)
            return
        names = [t.name for t in forum.available_tags]
        for wanted in (self.cfg.confirmed_tag, self.cfg.fixed_tag):
            if wanted not in names:
                log.error("Tag %r fehlt im Forum. Vorhanden: %s", wanted, ", ".join(names))
        log.info("Bereit als %s – beobachte #%s (%s)", self.user, forum.name, self.cfg.github_repo)
        # Catch up on posts confirmed while the bot was offline (active threads only).
        for thread in forum.threads:
            if self.cfg.confirmed_tag in tag_names(thread.applied_tags):
                await self._export(thread)

    async def on_thread_create(self, thread: discord.Thread) -> None:
        # A moderator may pick the confirmed tag right when creating the post.
        if thread.parent_id == self.cfg.forum_id and self.cfg.confirmed_tag in tag_names(thread.applied_tags):
            await asyncio.sleep(2)  # give Discord a moment to store the starter message
            await self._export(thread)

    async def on_thread_update(self, before: discord.Thread, after: discord.Thread) -> None:
        if after.parent_id != self.cfg.forum_id:
            return
        if newly_added(tag_names(before.applied_tags), tag_names(after.applied_tags), self.cfg.confirmed_tag):
            await self._export(after)

    async def _export(self, thread: discord.Thread) -> None:
        if self.state.issue_for(thread.id) or thread.id in self._busy:
            return
        self._busy.add(thread.id)
        try:
            try:
                starter = thread.starter_message or await thread.fetch_message(thread.id)
                content = starter.content
                attachments = [a.url for a in starter.attachments]
            except discord.NotFound:
                content, attachments = "", []
            title, body = build_issue(thread.name, content, tag_names(thread.applied_tags), attachments,
                                      thread_url(thread.guild.id, thread.id), self.cfg.confirmed_tag)
            issue = await self.github.create_issue(title, body, self.cfg.issue_labels)
            self.state.remember(thread.id, issue["number"], issue["html_url"])
            log.info("Thread %s -> Issue #%s", thread.id, issue["number"])
            await thread.send(
                f"✅ Bestätigt und auf GitHub übernommen / confirmed and tracked on GitHub: "
                f"<{issue['html_url']}>\nWir melden uns hier, sobald es behoben ist. / We'll post here once it's fixed."
            )
        except Exception:
            log.exception("Export von Thread %s fehlgeschlagen", thread.id)
        finally:
            self._busy.discard(thread.id)

    async def _poll_github(self) -> None:
        await self.wait_until_ready()
        while not self.is_closed():
            for thread_id, entry in self.state.open_entries():
                try:
                    issue = await self.github.get_issue(entry["issue"])
                    if issue.get("state") == "closed":
                        await self._report_closed(thread_id, issue)
                except Exception:
                    log.exception("Abfrage von Issue #%s fehlgeschlagen", entry.get("issue"))
            await asyncio.sleep(self.cfg.poll_seconds)

    async def _report_closed(self, thread_id: int, issue: dict) -> None:
        thread = self.get_channel(thread_id)
        if thread is None:
            try:
                thread = await self.fetch_channel(thread_id)
            except discord.NotFound:
                log.warning("Thread %s gibt es nicht mehr – Issue #%s wird ignoriert", thread_id, issue["number"])
                self.state.mark_closed(thread_id)
                return
        if not isinstance(thread, discord.Thread):
            self.state.mark_closed(thread_id)
            return
        if thread.archived:
            await thread.edit(archived=False)
        if issue.get("state_reason") == "not_planned":
            await thread.send(f"ℹ️ Das Issue wurde ohne Fix geschlossen / closed without a fix: <{issue['html_url']}>")
        else:
            forum = thread.parent
            by_name = {t.name: t for t in forum.available_tags} if isinstance(forum, discord.ForumChannel) else {}
            if self.cfg.fixed_tag in by_name:
                names = swap_tags(tag_names(thread.applied_tags), self.cfg.confirmed_tag, self.cfg.fixed_tag)
                await thread.edit(applied_tags=[by_name[n] for n in names if n in by_name])
            await thread.send(
                f"🎉 Behoben! Der Fix kommt mit dem nächsten Update. / Fixed! It ships with the next update. "
                f"<{issue['html_url']}>"
            )
        self.state.mark_closed(thread_id)
        log.info("Issue #%s geschlossen -> Thread %s aktualisiert", issue["number"], thread_id)


def main() -> None:
    logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"),
                        format="%(asctime)s %(levelname)s %(name)s: %(message)s", stream=sys.stdout)
    cfg = Config.from_env()
    BugBridge(cfg).run(cfg.discord_token, log_handler=None)


if __name__ == "__main__":
    main()
