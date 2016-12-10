;---------------------------------------------------------------
; Game specific asm file to intercept execution flow to obtain addresses, prevent writes etc.
;---------------------------------------------------------------

;---------------------------------------------------------------
; Public definitions so the linker knows which names are present in this file
PUBLIC cameraAddressInterceptor
PUBLIC cameraAddressInterceptor2
PUBLIC cameraWriteInterceptor1
PUBLIC cameraWriteInterceptor2
PUBLIC cameraWriteInterceptor3
PUBLIC gamespeedAddressInterceptor
;---------------------------------------------------------------

;---------------------------------------------------------------
; Externs defined in Core.cpp, which are used and set by the system. Read / write these
; values in asm to communicate with the system
EXTERN _cameraStructAddress: qword
EXTERN _cameraStructAddress2: qword
EXTERN _gamespeedStructAddress: qword
EXTERN _cameraEnabled: byte
EXTERN _timeStopped: byte
;---------------------------------------------------------------

;---------------------------------------------------------------
; Own externs, defined in InterceptorHelper.cpp
EXTERN _cameraStructInterceptionContinue: qword
EXTERN _cameraStructInterceptionContinue2: qword
EXTERN _cameraWriteInterceptionContinue1: qword
EXTERN _cameraWriteInterceptionContinue2: qword
EXTERN _cameraWriteInterceptionContinue3: qword
EXTERN _gamespeedInterceptionContinue: qword

;---------------------------------------------------------------
; For reference for fixing after game patch: Timestop usage code with RIP offset 
; hitman.exe+41C47B4 - 48 89 5C 24 50        - mov [rsp+50],rbx
; hitman.exe+41C47B9 - C6 05 88DC49FE 00     - mov byte ptr [hitman.exe+2662448],00		<<<<<<< offset.
; hitman.exe+41C47C0 - 48 83 B9 B8000000 00  - cmp qword ptr [rcx+000000B8],00
; hitman.exe+41C47C8 - 48 89 7C 24 40        - mov [rsp+40],rdi
;---------------------------------------------------------------


;---------------------------------------------------------------
.code

cameraAddressInterceptor PROC
	; Game jmps to this location due to the hook set in C function SetCameraStructInterceptorHook
	cmp byte ptr [rbx+038h], 0 							; check if this is the camera in rbx. For this game: Check with a 0-check. Could also check +20 or +24 for 0 if the above fails
	jne originalCode
	mov [_cameraStructAddress], rbx						; intercept address of camera struct
	cmp byte ptr [_cameraEnabled], 1					; check if the user enabled the camera. If so, just skip the write statements, otherwise just execute the original code.
	je exit												; our own camera is enabled, just skip the writes
originalCode:
	movss dword ptr [rbx+090h], xmm0					; original statement
exit:
    movss xmm0, dword ptr [rsp+058h]					; original statement
	jmp qword ptr [_cameraStructInterceptionContinue]	; jmp back into the original game code, which is the location after the original statements above.
cameraAddressInterceptor ENDP


cameraAddressInterceptor2 PROC
	; Game jmps to this location due to the hook set in C function SetCameraStructInterceptorHook
	mov [_cameraStructAddress2], rax					; camera used during menu / timestop. 
	cmp byte ptr [_cameraEnabled], 1
	je originalCode
	movss xmm0, dword ptr [rax+20]						; original statement
originalCode:
	movq xmm2, qword ptr [rax+18]						; original statement
	movaps xmm1,xmm5									; original statement
	addps xmm1,xmm5										; original statement
	jmp qword ptr [_cameraStructInterceptionContinue2]
cameraAddressInterceptor2 ENDP


gamespeedAddressInterceptor PROC
	mov [_gamespeedStructAddress], rbx
	mov [rbx+028h],rax
	mov rcx,[rbx+018h]
	mov [rbx+020h],rcx
	add [rbx+018h],rax
	jmp qword ptr [_gamespeedInterceptionContinue]
gamespeedAddressInterceptor ENDP


;-------------------------------------------------------------------
; Camera values write interceptions. For each block of statements in the game's exe which write to the camera values, we intercept them and execute them if our
; own camera is disabled, otherwise we skip them. Each block checks whether the current struct pointer is the camera struct. If it's not the camera struct, it will
; execute the code regardless of whether our camera is enabled.

cameraWriteInterceptor1 PROC
	; Game jmps to this location due to the hook set in C function SetMatrixWriteInterceptorHooks. 
	; first check if this is really a call for the camera. Other logic will use this code too. Check rbx with our known cameraStruct address to be sure
	cmp qword ptr rbx, [_cameraStructAddress]
	jne originalCode
	cmp byte ptr [_cameraEnabled], 1					; check if the user enabled the camera. If so, just skip the write statements, otherwise just execute the original code.
	je exit												; our own camera is enabled, just skip the writes
originalCode:
	movaps xmm0, dword ptr [rax]						; original statement
	movups dword ptr [rbx+080h],xmm0					; original statement
exit:
	movss xmm0, dword ptr [rsp+050h]					; original statement
	jmp qword ptr [_cameraWriteInterceptionContinue1]	; jmp back into the original game code which is the location after the original statements above.
cameraWriteInterceptor1 ENDP

cameraWriteInterceptor2 PROC
	; Game jmps to this location due to the hook set in C function SetMatrixWriteInterceptorHooks. 
	; first check if this is really a call for the camera. Other logic will use this code too. Check rbx with our known cameraStruct address to be sure
	cmp qword ptr rbx, [_cameraStructAddress]
	jne originalCode
	cmp byte ptr [_cameraEnabled], 1					; check if the user enabled the camera. If so, just skip the write statements, otherwise just execute the original code.
	je exit												; our own camera is enabled, just skip the writes
originalCode:
	movups dword ptr [rbx+098h], xmm0					; original statement
	movss dword ptr [rbx+094h], xmm1					; original statement	
exit:
	jmp qword ptr [_cameraWriteInterceptionContinue2]	; jmp back into the original game code which is the location after the original statements above.
cameraWriteInterceptor2 ENDP

cameraWriteInterceptor3 PROC
	; Game jmps to this location due to the hook set in C function SetMatrixWriteInterceptorHooks. 
	; first check if this is really a call for the camera. Other logic will use this code too. Check rbx with our known cameraStruct address to be sure
	cmp qword ptr rbx, [_cameraStructAddress]
	jne originalCode
	cmp byte ptr [_cameraEnabled], 1					; check if the user enabled the camera. If so, just skip the write statements, otherwise just execute the original code.
	je exit												; our own camera is enabled, just skip the writes
originalCode:
	movups dword ptr [rbx+080h],xmm0					; original statement
	movaps xmm1, dword ptr[rdi+030h]					; original statement
	movaps xmm0,xmm1									; original statement
	movss dword ptr [rbx+090h],xmm1						; original statement
	shufps xmm0,xmm1, 055h								; original statement
	shufps xmm1,xmm1,-056h								; original statement
	movss dword ptr [rbx+098h], xmm1					; original statement
	movss dword ptr [rbx+094h], xmm0					; original statement
exit:
	jmp qword ptr [_cameraWriteInterceptionContinue3]	; jmp back into the original game code which is the location after the original statements above.
cameraWriteInterceptor3 ENDP

END