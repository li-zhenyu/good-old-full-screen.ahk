; ============================================
; AHK v2 无边框全屏切换
; 快捷键: Win + F
; ============================================

#Requires AutoHotkey v2.0
#SingleInstance Ignore

Global FullscreenMap := Map()
Global TaskbarHidden := false

#f:: ToggleFullScreen()

ToggleFullScreen() {
    activeHwnd := WinExist("A")
    if !activeHwnd
        return
    if FullscreenMap.Has(activeHwnd)
        ExitFullScreen(activeHwnd)
    else
        EnterFullScreen(activeHwnd)
}

EnterFullScreen(hwnd) {
    Global FullscreenMap, TaskbarHidden

    ; 获取当前是否最大化
    isMax := IsWindowMaximized(hwnd)

    ; ★ 关键修复：如果窗口最大化，先还原，再获取原始正常尺寸
    if isMax {
        WinRestore(hwnd)
        ;Sleep(50)               ; 等待窗口稳定（测得并无影响，已关闭）
    }

    ; 获取窗口当前实际位置和大小（对于原最大化窗口，此时已是正常尺寸）
    WinGetPos(&x, &y, &w, &h, hwnd)

    ; 保存原始状态（包括正常尺寸和最大化标志）
    oldStyle := GetWindowStyle(hwnd)
    FullscreenMap[hwnd] := {x:x, y:y, w:w, h:h, max:isMax, style:oldStyle}

    ; 移除边框
    newStyle := oldStyle & ~0xC40000
    SetWindowStyle(hwnd, newStyle)
    ;Sleep(50)

    ; 铺满全屏（覆盖任务栏区域）
    WinMove(0, 0, A_ScreenWidth, A_ScreenHeight, hwnd)

    ; 隐藏任务栏
    if !TaskbarHidden {
        WinHide("ahk_class Shell_TrayWnd")
        if WinExist("ahk_class Shell_SecondaryTrayWnd")
            WinHide("ahk_class Shell_SecondaryTrayWnd")
        TaskbarHidden := true
    }
}

ExitFullScreen(hwnd) {
    Global FullscreenMap, TaskbarHidden
    if !FullscreenMap.Has(hwnd)
        return
    saved := FullscreenMap[hwnd]

    ; 恢复样式（去除最大化标志）
    cleanStyle := saved.style & ~0x03000000
    SetWindowStyle(hwnd, cleanStyle)
    ;Sleep(50)

    ; 恢复到原始正常大小和位置
    WinMove(saved.x, saved.y, saved.w, saved.h, hwnd)

    ; 如果原始状态是最大化，重新最大化
    if saved.max
        WinMaximize(hwnd)

    ; 显示任务栏
    if TaskbarHidden {
        WinShow("ahk_class Shell_TrayWnd")
        if WinExist("ahk_class Shell_SecondaryTrayWnd")
            WinShow("ahk_class Shell_SecondaryTrayWnd")
        TaskbarHidden := false
    }

    FullscreenMap.Delete(hwnd)
}

; ----- 辅助函数 -----
GetWindowStyle(hwnd) {
    return DllCall("GetWindowLongPtr", "Ptr", hwnd, "Int", -16, "Ptr")
}

SetWindowStyle(hwnd, style) {
    DllCall("SetWindowLongPtr", "Ptr", hwnd, "Int", -16, "Ptr", style, "Ptr")
    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x27)
}

IsWindowMaximized(hwnd) {
    style := GetWindowStyle(hwnd)
    return (style & 0x03000000) ? true : false
}

; ----- 托盘菜单 -----
A_TrayMenu.Delete()
A_TrayMenu.Add("切换全屏 (Win+F)", (*) => ToggleFullScreen())
A_TrayMenu.Add()
A_TrayMenu.Add("退出脚本", (*) => ExitApp())
A_TrayMenu.Default := "切换全屏 (Win+F)"