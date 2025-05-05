ml /c /coff main.asm 有main.obj的話就不用這行，若沒有，記得環境變數指向的path 要有ml.exe

前置作業
要在邊輯系統環境變數裡把以下的path新增到環境變數(我有放照片)
C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.38.33130\bin\Hostx64\x86
以上路徑是我電腦的情況，找到自己的Microsoft Visual Studio，裡面要有link.exe

把 masm32 放到C槽(我會放masm32在整個專案裡，不要放在專案裡，把它移到C槽，這很重要)

link main.obj /SUBSYSTEM:CONSOLE 這行是做出main.exe, 在cmd 裡面做就可以

[以系統管理員身分執行main.exe 這很重要，不然會跑不動]