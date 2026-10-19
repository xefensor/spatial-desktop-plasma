import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

script = Path(__file__).resolve().parents[1] / "scripts/panel.py"
spec = importlib.util.spec_from_file_location("panel", script)
panel = importlib.util.module_from_spec(spec)
spec.loader.exec_module(panel)


class PanelTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.state = Path(self.temp.name)
        self.record = self.state / "panel.json"

    def test_failed_preflight_does_not_install_or_create_state(self):
        with patch.object(panel, "preflight", side_effect=RuntimeError("No desktop bus")), \
             patch.object(panel, "install") as install, patch.object(panel, "save") as save:
            with self.assertRaises(RuntimeError):
                panel.start(280)
        install.assert_not_called()
        save.assert_not_called()

    def test_cleanup_removes_only_the_recorded_panel(self):
        self.record.write_text(json.dumps({"token":"ours"}))
        with patch.object(panel, "RECORD", self.record), patch.object(panel, "plasma") as call:
            panel.stop()
        self.assertFalse(self.record.exists())
        # Execute the exact generated desktop script against three panels.
        javascript = """
const vm=require('node:vm'),assert=require('node:assert/strict'),removed=[];
const panels=()=>['ours','other-test',''].map(token=>({readConfig(){return token},remove(){removed.push(token)}}));
vm.runInNewContext(SCRIPT,{panels});assert.deepEqual(removed,['ours']);
""".replace("SCRIPT", json.dumps(call.call_args.args[0]))
        subprocess.run(["node", "-e", javascript], check=True)

    def test_failed_cleanup_retains_recovery_record(self):
        self.record.write_text(json.dumps({"token":"ours"}))
        with patch.object(panel, "RECORD", self.record), patch.object(panel, "plasma", side_effect=RuntimeError("Offline")):
            with self.assertRaises(RuntimeError):
                panel.stop()
        self.assertTrue(self.record.exists())

    def test_partial_start_is_cleaned_up_using_pre_saved_token(self):
        events = []
        def fail_create(script):
            self.assertTrue(self.record.exists())
            events.append(script)
            if "new Panel" in script:
                raise RuntimeError("Widget could not load")
            return ""
        with patch.object(panel, "STATE", self.state), patch.object(panel, "RECORD", self.record), \
             patch.object(panel, "preflight"), patch.object(panel, "install"), \
             patch.object(panel, "plasma", side_effect=fail_create):
            with self.assertRaises(RuntimeError):
                panel.start(300)
        self.assertEqual(len(events), 2)
        self.assertFalse(self.record.exists())


if __name__ == "__main__":
    unittest.main()
