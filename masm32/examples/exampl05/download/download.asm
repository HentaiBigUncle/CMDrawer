; �������������������������������������������������������������������������
    include \masm32\include\masm32rt.inc
; �������������������������������������������������������������������������

comment * -----------------------------------------------------
                        Build this  template with
                       "CONSOLE ASSEMBLE AND LINK"
        ----------------------------------------------------- *

    include \masm32\include\urlmon.inc
    includelib \masm32\lib\urlmon.lib

    .code

start:
   
; �������������������������������������������������������������������������

    call main

    exit

; �������������������������������������������������������������������������

main proc

    fn URLDownloadToFile,0, \
                    "http://www.website.masmforum.com/files/random.zip", \
                    "random.zip",0,0

    ret

main endp

; �������������������������������������������������������������������������

end start
