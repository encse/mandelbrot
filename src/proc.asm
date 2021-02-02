;; Macros for C-style procedure definitions
;;
;; proc foo
;;      %arg   i:word
;;      %arg   j:word
;;      %local k:word
;; begin
;;      mov ax, [i]
;;      mov ax, [k]
;; endproc

; define a procedure definition called with ip on the stack
%macro proc 1
    %push proc
    %1: 
    %stacksize large
    %assign %$localsize 0 
    %assign %$arg 0
    %define %$procname %1
%endmacro

; begin a procedure definition called with cs:ip on the stack
%macro farproc 1
        %push farproc
    %1: 
        %stacksize small
        %assign %$localsize 0 
        %assign %$arg 0
        %define %$procname %1
%endmacro

%macro begin 0
    enter %$localsize, 0
%endmacro

%macro endproc 0
    %ifctx farproc
        leave
        retf
    %elifctx proc
        leave
        ret
    %else
        %error Mismatched `endproc'/`proc'
    %endif
    %pop
%endmacro
