;===============================================================================
;Program        : win32zipfolder
;Version        : 0.0.1
;Author         : Yeoh HS
;Date           : 6 January 2018
;Purpose        : a Win32 console program to zip a folder (non-recursive only)
;flat assembler : 1.73.02
;Notes          : This program needs zip32.dll. You can find it in zip232dn.zip
;               ; from ftp://ftp.info-zip.org/pub/infozip/win32/
;               ; Website: http://infozip.sourceforge.net/   (Thanks to Info-Zip.)
;===============================================================================
format PE CONSOLE 4.0
entry start

include 'win32axp.inc'
include 'macro\if.inc'

;-------------------------------------------------------------------------------
struct FilesToZip
       file1 rb 255
ends

struct ZPOPT
  Date rb 8           ; String ' US Date (8 Bytes Long) "12/31/98"?
  szRootDir rb 256    ; String ' Root Directory Pathname (Up To 256 Bytes Long)
  szTempDir: rb 256   ; String ' Temp Directory Pathname (Up To 256 Bytes Long)
  fTemp dd 0          ; Long   ' 1 If Temp dir Wanted, Else 0
  fSuffix dd 0        ; Long   ' Include Suffixes (Not Yet Implemented!)
  fEncrypt dd 0       ; Long   ' 1 If Encryption Wanted, Else 0
  fSystem dd 0        ; Long   ' 1 To Include System/Hidden Files, Else 0
  fVolume dd 0        ; Long   ' 1 If Storing Volume Label, Else 0
  fExtra dd 0         ; Long   ' 1 If Excluding Extra Attributes, Else 0
  fNoDirEntries dd 0  ; Long   ' 1 If Ignoring Directory Entries, Else 0
  fExcludeDate dd 0   ; Long   ' 1 If Excluding Files Earlier Than Specified Date, Else 0
  fIncludeDate dd 0   ; Long   ' 1 If Including Files Earlier Than Specified Date, Else 0
  fVerbose dd 0       ; Long   ' 1 If Full Messages Wanted, Else 0
  fQuiet dd  0        ; Long   ' 1 If Minimum Messages Wanted, Else 0
  fCRLF_LF dd 0       ; Long   ' 1 If Translate CR/LF To LF, Else 0
  fLF_CRLF dd 0       ; Long   ' 1 If Translate LF To CR/LF, Else 0
  fJunkDir dd 0       ; Long   ' 1 If Junking Directory Names, Else 0
  fGrow dd 0          ; Long   ' 1 If Allow Appending To Zip File, Else 0
  fForce dd 0         ; Long   ' 1 If Making Entries Using DOS File Names, Else 0
  fMove dd 0          ; Long   ' 1 If Deleting Files Added Or Updated, Else 0
  fDeleteEntries dd 0 ; Long   ' 1 If Files Passed Have To Be Deleted, Else 0
  fUpdate dd 0        ; Long   ' 1 If Updating Zip File-Overwrite Only If Newer, Else 0
  fFreshen dd 0       ; Long   ' 1 If Freshing Zip File-Overwrite Only, Else 0
  fJunkSFX dd 0       ; Long   ' 1 If Junking SFX Prefix, Else 0
  fLatestTime dd 0    ; Long   ' 1 If Setting Zip File Time To Time Of Latest File In Archive, Else 0
  fComment dd 0       ; Long   ' 1 If Putting Comment In Zip File, Else 0
  fOffsets dd 0       ; Long   ' 1 If Updating Archive Offsets For SFX Files, Else 0
  fPrivilege dd 0     ; Long   ' 1 If Not Saving Privileges, Else 0
  fEncryption dd 0    ; Long   ' Read Only Property!!!
  fRecurse dd 0       ; Long   ' 1 (-r), 2 (-R) If Recursing Into Sub-Directories, Else 0
  fRepair dd 0        ; Long   ' 1 = Fix Archive, 2 = Try Harder To Fix, Else 0
  flevel rb 1         ; Byte   ' Compression Level - 0 = Stored 6 = Default 9 = Max
ends

struct UserFunctions
 dd PrintRoutine
 dd CommentRoutine
 dd PasswordRoutine
 dd Service

 TOtalSizeComp dd 0
 TotalSize dd 0
 NumMembers dd 0
 cchComment dd 0
ends

;-------------------------------------------------------------------------------
macro println arg*
{
   cinvoke printf, '%s', arg
}

;-------------------------------------------------------------------------------
section '.data' data readable writeable
    zArgc       dd 0                ; for Number Of Files To Zip Up
    ftz         FilesToZip
    zp          ZPOPT
    uf          UserFunctions

    aFile1      db "C:\Zip\*.*",0  ; for example, zip all files (top level) in this folder
    Root        db "C:\",0
    MyZipFile   db "testzip.zip",0     ; output file in executable's folder.

    CRLF         db '',13,10,0
    strfmt       db '%s',0
    StartZipping db 'Start zipping...',0
    ZippingDone  db 'Zipping done!',0

;-------------------------------------------------------------------------------
section '.code' code readable executable
start:
     println StartZipping

     mov [zp.Date],NULL           ; insert null string
     mov [zp.fJunkDir], 0         ;
     mov [zp.fRecurse], 0         ; 1 (-r), 2 (-R) If Recursing Into Sub-Directories, Else 0
     mov [zp.fUpdate ],0          ;
     mov [zp.fFreshen], 0         ;
     mov [zp.flevel], 9           ; Compression Level - 0 = Stored 6 = Default 9 = Max
     mov [zp.fEncrypt], 0         ; do not encrypt
     mov [zp.fComment], 0         ; no comments in zip
     mov [zp.fQuiet], 1           ; 1 If Minimum Messages Wanted, Else 0

     mov [zArgc], 1            ;
     mov dword[ftz.file1], aFile1
     mov dword[zp.szRootDir], Root     ; "C:\"   This Affects The Stored Path Name

     cinvoke ZpInit,uf
     cinvoke ZpSetOptions,zp
     cinvoke ZpArchive, [zArgc], MyZipFile, ftz

     println ZippingDone

.finished:
    invoke  ExitProcess,0

;-------------------------------------------------------------------------------
proc PrintRoutine,Arg1,Arg2
     mov eax,0
     ret
endp

proc CommentRoutine,Arg1
     mov eax,0
     ret
endp

proc PasswordRoutine,Arg1,Arg2,Arg3,Arg
     mov eax, 0
     ret
endp

proc Service,Arg1,Arg2
     mov eax,0
     ret
endp

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
        zip32,    'ZIP32.DLL',\
        msvcrt,   'MSVCRT.DLL'

include 'api\kernel32.inc'
include 'api\user32.inc'
include 'api\comctl32.inc'
include 'api\shell32.inc'
include 'api\advapi32.inc'
include 'api\comdlg32.inc'
include 'api\gdi32.inc'
include 'api\wsock32.inc'
 
import  zip32,\
        ZpInit,       'ZpInit',\
        ZpSetOptions, 'ZpSetOptions',\
        ZpArchive,    'ZpArchive'

import  msvcrt,\
        printf,    'printf',\
        fprintf,   'fprintf',\
        fgets,     'fgets'

; end of file ==================================================================
