from typing import Any, Dict

def on_focus_change(boss, window, data: Dict[str, Any]) -> None:
#Onforcus: 0.8, Outforcus: 0.1
    opacity = "0.8" if data.get("focused") else "0.1"

    try:
        boss.set_background_opacity(opacity)
    except Exception
        pass
