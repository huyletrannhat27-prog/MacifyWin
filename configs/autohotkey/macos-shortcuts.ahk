#Requires AutoHotkey v2.0
#SingleInstance Force

; MacifyWin - Phim tat macOS cho Windows (Alt dong vai tro nut Command ben canh Space)
; Giu nguyen Ctrl+C/V/X/Z cua Windows de khong gay xung dot phan mem.

; --- He thong & Spaces (Virtual Desktop) ---
^Left::Send "^#{Left}"      ; Ctrl + Trai: Chuyen sang Desktop ben trai
^Right::Send "^#{Right}"    ; Ctrl + Phai: Chuyen sang Desktop ben phai
^Up::Send "#{Tab}"          ; Ctrl + Len: Mission Control (xem tat ca cua so & desktop)
F3::Send "#{Tab}"           ; F3: Mission Control
!Space::Send "#{s}"         ; Alt + Space: Spotlight / Tim kiem he thong
!q::Send "!{F4}"            ; Alt + Q: Thoat han ung dung (tuong tu Cmd + Q)
!w::Send "^w"               ; Alt + W: Dong tab / cua so (tuong tu Cmd + W)
!m::WinMinimize "A"         ; Alt + M: Thu nho cua so
!^Esc::Send "^+{Esc}"       ; Alt + Ctrl + Esc: Force Quit / Task Manager
!^q::DllCall("LockWorkStation") ; Ctrl + Alt + Q: Khoa may
!^Space::Send "#."          ; Ctrl + Alt + Space: Emoji Picker
!+3::Send "{PrintScreen}"   ; Alt + Shift + 3: Chup toan man hinh
!+4::Send "#+s"             ; Alt + Shift + 4: Chup chon vung

; Alt + ` : Chuyen qua lai cac cua so cua CUNG 1 ung dung (giong Cmd + ` tren Mac)
!`:: {
    try {
        exe := WinGetProcessName("A")
        ids := WinGetList("ahk_exe " . exe)
        if (ids.Length > 1) {
            WinActivate(ids[ids.Length])
        }
    }
}

; --- Finder / Files App & Explorer ---
#HotIf WinActive("ahk_exe Files.exe") || WinActive("ahk_class CabinetWClass")
!i::Send "!{Enter}"         ; Alt + I: Get Info (xem thuoc tinh file)
!BackSpace::Send "{Delete}" ; Alt + Delete/Backspace: Chuyen file vao Trash
!Down::Send "{Enter}"       ; Alt + Xuong: Mo file / thu muc
#HotIf
