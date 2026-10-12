from typing import Any, Dict

def on_focus_change(boss, window, data: Dict[str, Any]) -> None:
    # フォーカスが当たっている時(True)は 1.0（不透明）
    # フォーカスが外れた時(False)は 0.6（半透明）
    opacity = "0.7" if data.get("focused") else "0.2"
    
    try:
        # Kitty全体の背景透明度を上書きする
        boss.set_background_opacity(opacity)
    except Exception:
        pass
