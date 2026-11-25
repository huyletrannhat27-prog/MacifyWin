#Requires AutoHotkey v2.0
#SingleInstance Force

; MacifyWin - Phim tat bo tro kieu macOS
; Chuyen Virtual Desktop muot bang Ctrl + Mui ten Trai/Phai
^Left::Send "^#{Left}"
^Right::Send "^#{Right}"

; Alt + Q: Dong cua so hien tai (tuong tu Cmd + Q)
!q::Send "!{F4}"

; Alt + M: Thu nho cua so hien tai (tuong tu Cmd + M)
!m::WinMinimize "A"

; Alt + Space: Mo trinh tim kiem nhanh (Spotlight / Seelen Launcher)
!Space::Send "#{s}"

