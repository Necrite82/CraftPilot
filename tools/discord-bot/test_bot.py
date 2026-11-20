"""Offline tests for the pure helpers: python3 -m unittest test_bot.py"""
import tempfile
import unittest
from pathlib import Path

import bot


class Helpers(unittest.TestCase):
    def test_newly_added(self):
        self.assertTrue(bot.newly_added(["DE"], ["DE", "Bestätigt"], "Bestätigt"))
        self.assertFalse(bot.newly_added(["Bestätigt"], ["Bestätigt", "EN"], "Bestätigt"))
        self.assertFalse(bot.newly_added([], ["DE"], "Bestätigt"))

    def test_build_issue(self):
        title, body = bot.build_issue("  Fehler beim Öffnen  ", "Lua error x", ["DE", "Bestätigt"],
                                      ["https://cdn/x.png"], "https://discord.com/channels/1/2", "Bestätigt")
        self.assertEqual(title, "Fehler beim Öffnen")
        self.assertIn("https://discord.com/channels/1/2", body)
        self.assertIn("Lua error x", body)
        self.assertIn("- https://cdn/x.png", body)
        self.assertIn("Discord-Tags: DE", body)
        self.assertNotIn("Bestätigt", body)

    def test_build_issue_limits(self):
        title, body = bot.build_issue("", "x" * 70000, [], [], "u", "Bestätigt")
        self.assertEqual(title, "Bug aus Discord")
        self.assertLess(len(body), 65536)

    def test_swap_tags(self):
        self.assertEqual(bot.swap_tags(["DE", "Bestätigt"], "Bestätigt", "Behoben / Fixed"),
                         ["Behoben / Fixed", "DE"])
        five = ["a", "b", "c", "d", "Bestätigt"]
        self.assertEqual(len(bot.swap_tags(five, "Bestätigt", "Fix")), 5)
        self.assertEqual(bot.swap_tags(["Fix"], "Bestätigt", "Fix"), ["Fix"])

    def test_config(self):
        env = {"DISCORD_TOKEN": "t", "BUG_FORUM_ID": "123", "GITHUB_TOKEN": "g",
               "GITHUB_REPO": "Necrite82/CraftPilot", "POLL_SECONDS": "5"}
        cfg = bot.Config.from_env(env)
        self.assertEqual(cfg.forums, {123: "Necrite82/CraftPilot"})  # older single-forum setup still works
        self.assertEqual(cfg.poll_seconds, 60)  # lower bound
        self.assertEqual(cfg.issue_labels, ("bug",))
        with self.assertRaises(SystemExit):
            bot.Config.from_env({**env, "GITHUB_REPO": "nope"})
        with self.assertRaises(SystemExit):
            bot.Config.from_env({k: v for k, v in env.items() if k != "DISCORD_TOKEN"})

    def test_state_roundtrip(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "sub" / "state.json"
            s = bot.State(path)
            s.remember(42, 7, "https://github.com/x/y/issues/7", "x/y")
            again = bot.State(path)
            self.assertEqual(again.issue_for(42)["issue"], 7)
            self.assertEqual(again.issue_for(42)["repo"], "x/y")
            self.assertEqual([t for t, _ in again.open_entries()], [42])
            again.mark_closed(42)
            self.assertEqual(bot.State(path).open_entries(), [])


class Routing(unittest.TestCase):
    base = {"DISCORD_TOKEN": "t", "GITHUB_TOKEN": "g"}

    def test_one_forum_per_addon(self):
        cfg = bot.Config.from_env({**self.base, "BUG_FORUMS": "111=Necrite82/CraftPilot, 222=Necrite82/GearPilot"})
        self.assertEqual(cfg.repo_for(111, ["DE"]), "Necrite82/CraftPilot")
        self.assertEqual(cfg.repo_for(222, ["EN", "Bestätigt"]), "Necrite82/GearPilot")
        self.assertIsNone(cfg.repo_for(333, []))

    def test_shared_forum_with_addon_tags(self):
        cfg = bot.Config.from_env({**self.base, "BUG_FORUMS": "111=",
                                   "REPO_TAGS": "CraftPilot=Necrite82/CraftPilot,GearPilot=Necrite82/GearPilot"})
        self.assertEqual(cfg.repo_for(111, ["DE", "GearPilot"]), "Necrite82/GearPilot")
        self.assertEqual(cfg.repo_for(111, ["CraftPilot"]), "Necrite82/CraftPilot")
        self.assertIsNone(cfg.repo_for(111, ["DE"]))  # bot asks for the addon tag
        self.assertEqual(cfg.fallback_repo, "Necrite82/CraftPilot")

    def test_tag_beats_forum_default(self):
        cfg = bot.Config.from_env({**self.base, "BUG_FORUM_ID": "111", "GITHUB_REPO": "Necrite82/CraftPilot",
                                   "REPO_TAGS": "GearPilot=Necrite82/GearPilot"})
        self.assertEqual(cfg.repo_for(111, ["GearPilot"]), "Necrite82/GearPilot")
        self.assertEqual(cfg.repo_for(111, []), "Necrite82/CraftPilot")

    def test_bad_settings(self):
        with self.assertRaises(SystemExit):
            bot.Config.from_env({**self.base, "BUG_FORUMS": "abc=Necrite82/CraftPilot"})
        with self.assertRaises(SystemExit):
            bot.Config.from_env({**self.base, "BUG_FORUMS": "111="})  # no repo and no addon tags
        with self.assertRaises(SystemExit):
            bot.Config.from_env(self.base)

    def test_addon_tag_hidden_in_issue(self):
        _, body = bot.build_issue("t", "x", ["DE", "GearPilot"], [], "u", "Bestätigt", hidden_tags=("GearPilot",))
        self.assertIn("Discord-Tags: DE", body)
        self.assertNotIn("GearPilot", body)


if __name__ == "__main__":
    unittest.main()
