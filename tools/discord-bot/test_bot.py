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
        self.assertEqual(cfg.forum_id, 123)
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
            s.remember(42, 7, "https://github.com/x/y/issues/7")
            again = bot.State(path)
            self.assertEqual(again.issue_for(42)["issue"], 7)
            self.assertEqual([t for t, _ in again.open_entries()], [42])
            again.mark_closed(42)
            self.assertEqual(bot.State(path).open_entries(), [])


if __name__ == "__main__":
    unittest.main()
