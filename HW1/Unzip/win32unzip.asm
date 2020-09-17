;===============================================================================
;Program        : win32unzip
;Version        : 0.0.1
;Author         : Yeoh HS
;Date           : 9 January 2018
;Purpose        : a Win32 console program to unzip a .zip file
;flat assembler : 1.73.02
;Notes          : This program needs unzip32.dll. You can find it in unz552dn.zip
;               ; from ftp://ftp.info-zip.org/pub/infozip/win32/
;               ; Website: http://infozip.sourceforge.net/   (Thanks to Info-Zip.)
;===============================================================================
format PE CONSOLE 4.0
entry start

include 'win32axp.inc'
include 'macro\if.inc'

;-------------------------------------------------------------------------------
; This is the structure that needs to be filled
struct UNZIP32DCL
       ExtractOnlyNewer dd ?  ; 1 = Extract Only Newer/New, Else 0
       SpaceToUnderscore dd ? ; 1 = Convert Space To Underscore, Else 0
       PromptToOverwrite dd ? ; 1 = Prompt To Overwrite Required, Else 0
       fQuiet dd ?            ; 2 = No Messages, 1 = Less, 0 = All
       ncflag dd ?            ; 1 = Write To Stdout, Else 0
       ntflag dd ?            ; 1 = Test Zip File, Else 0
       nvflag dd ?            ; 0 = Extract, 1 = List Zip Contents
       nfflag dd ?            ; 1 = Extract Only Newer Over Existing, Else 0
       nzflag dd ?            ; 1 = Display Zip File Comment, Else 0
       ndflag dd ?            ; 1 = Honor Directories, Else 0
       noflag dd ?            ; 1 = Overwrite Files, Else 0
       naflag dd ?            ; 1 = Convert CR To CRLF, Else 0
       nZIflag dd ?           ; 1 = Zip Info Verbose, Else 0
       C_flag dd ?            ; 1 = Case Insensitivity, 0 = Case Sensitivity
       fPrivilege dd ?        ; 1 = ACL, 2 = Privileges
       Zip dd ?               ; The Zip Filename To Extract Files
       ExtractDir dd ?      ; The Extraction Directory, NULL If Extracting To Current Dir
ends

struct Unzip32UserFunctions
 dd UzPrintRoutine
 dd UzSoundRoutine
 dd UzReplaceRoutine
 dd UzPasswordRoutine
 dd UzSendMessage
 UzTotalSizeComp dd ?
 UzTotalSize dd ?
 UzNumMembers dd ?
 UzcchComment dd ?
ends

;-------------------------------------------------------------------------------
macro println arg*
{
   cinvoke printf, '%s', arg
}

;-------------------------------------------------------------------------------
section '.data' data readable writeable
    dcl         UNZIP32DCL
    uuf         Unzip32UserFunctions
    zipfile    db 'testzip.zip',0     ; For example, unzip this file
    unzipto    db 'TestZip',0      ; e.g. unzip to this folder

    CRLF         db '',13,10,0
    strfmt       db '%s',0
    StartUnZipping db 'Start unzipping...',0
    UnZippingDone  db 'Unzipping done!',0

;-------------------------------------------------------------------------------
section '.code' code readable executable
start:
     println StartUnZipping

     stdcall Unzip32DLL,zipfile,NULL ; unzip to current folder

     println UnZippingDone

.finished:
    invoke  ExitProcess,0

;-------------------------------------------------------------------------------
;
; ZipFile is the zip file's name
; UnzipToDir is the directory to unzip to. If it does not exist, it will be created.
; If NULL is passed instead, it will unzip to the executable's folder.
;
proc Unzip32DLL,ZipFile,UnzipToDir
    mov [dcl.fQuiet], 2
    mov [dcl.ndflag],1
    mov [dcl.noflag], 1
    mov eax, [ZipFile]
    mov [dcl.Zip], eax
    mov eax, [UnzipToDir]
    mov [dcl.ExtractDir], eax
    cinvoke Wiz_SingleEntryUnzip, 0,NULL, 0,NULL,dcl,uuf
    ret
endp

UzPrintRoutine:
    mov eax, 0
    ret

UzSoundRoutine:
    mov eax, 0
    ret

UzReplaceRoutine:
    mov eax, 0
    ret

UzPasswordRoutine:
    mov eax, 0
    ret

UzSendMessage:
    mov eax, 0
    ret

;-------------------------------------------------------------------------------
section '.idata' import data readable writeable
library kernel32, 'KERNEL32.DLL',\
        user32,   'USER32.DLL',\
        comctl32, 'COMCTL32.DLL',\
        shell32,  'SHELL32.DLL',\
        advapi32, 'ADVAPI32.DLL',\
        comdlg32, 'COMDLG32.DLL',\ 
        gdi32,    'GDI32.DLL',\
        wsock32,  'WSOCK32.DLL',\
        unzip32,  'UNZIP32.DLL',\
        msvcrt,   'MSVCRT.DLL'

include 'api\kernel32.inc'
include 'api\user32.inc'
include 'api\comctl32.inc'
include 'api\shell32.inc'
include 'api\advapi32.inc'
include 'api\comdlg32.inc'
include 'api\gdi32.inc'
include 'api\wsock32.inc'
 
import  unzip32,\
        Wiz_SingleEntryUnzip, 'Wiz_SingleEntryUnzip'

import  msvcrt,\
        printf,   'printf'

; end of file ==================================================================
