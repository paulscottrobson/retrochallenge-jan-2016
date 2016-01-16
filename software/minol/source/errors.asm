; ****************************************************************************************************************
; ****************************************************************************************************************
;
;												Error Codes
;
; ****************************************************************************************************************
; ****************************************************************************************************************

ERRC_END = 0xFF													; psuedo error, program stopped. Does "OK" as for no error.
ERRC_LABEL = '1' 												; Label does not exist (e.g. GOTO)
ERRC_UNKNOWN = '2'												; Unknown instruction
ERRC_TERM = '4' 												; Illegal term/expression
ERRC_SYNTAX = '5'												; Syntax Error
ERRC_MEMORY = '6' 												; Out of memory
ERRC_DIVZERO = '7' 												; Division by Zero Error.
ERRC_BREAK = '8' 												; Break.