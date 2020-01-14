/*
//
// limits.ahk
//
//      Copyright (c) Microsoft Corporation. All rights reserved.
//
// The C Standard Library <limits.h> header.
//
*/

CHAR_BIT        := 8                                                    ;  number of bits in a char
SCHAR_MIN       := -128                                                 ;  minimum signed char value
SCHAR_MAX       := 127                                                  ;  maximum signed char value
UCHAR_MAX       := 255                                                  ;  maximum unsigned char value           0xff

if (_CHAR_UNSIGNED) {
    CHAR_MIN    := SCHAR_MIN                                            ; mimimum char value
    CHAR_MAX    := SCHAR_MAX                                            ; maximum char value
} else {
    CHAR_MIN    := 0
    CHAR_MAX    := UCHAR_MAX
}

MB_LEN_MAX      := 5								                    ; max. # bytes in multibyte char
SHRT_MIN        := -32768                                               ; minimum (signed) short value
SHRT_MAX        := 32767i16                                             ; maximum (signed) short value
USHRT_MAX       := 65535                                                ; maximum unsigned short value          0xffff
INT_MIN         := -2147483648                                          ; minimum (signed) int value
INT_MAX         := 2147483647i32                                        ; maximum (signed) int value
UINT_MAX        := 4294967295                                           ; maximum unsigned int value            0xffffffff
LONG_MIN        := -9223372036854775808                                 ; minimum (signed) long value
LONG_MAX        := 9223372036854775807                                  ; maximum (signed) long value
ULONG_MAX       := 18446744073709551615                                 ; maximum unsigned long value           0xffffffff
LLONG_MIN       := -9223372036854775808                                 ; maximum signed long long int value
LLONG_MAX       := 9223372036854775807                                  ; minimum signed long long int value
ULLONG_MAX      := 18446744073709551615                                 ; maximum unsigned long long int value  0xffffffffffffffff

_I8_MIN		    := -127i8 - 1                                           ; minimum signed 8 bit value
_I8_MAX 	    := 127i8                                                ; maximum signed 8 bit value
_UI8_MAX 	    := 0xffui8                                              ; maximum unsigned 8 bit value

_I16_MIN 	    := -32767i16 - 1                                        ; minimum signed 16 bit value
_I16_MAX	    := 32767i16                                             ; maximum signed 16 bit value
_UI16_MAX 	    := 0xffffui16                                           ; maximum unsigned 16 bit value

_I32_MIN 	    := -2147483647i32 - 1                                   ; minimum signed 32 bit value
_I32_MAX 	    := 2147483647i32                                        ; maximum signed 32 bit value
_UI32_MAX 	    := 0xffffffffui32                                       ; aximum unsigned 32 bit value

_I64_MIN 	    := -9223372036854775807i64 - 1                          ; minimum signed 64 bit value
_I64_MAX 	    := 9223372036854775807i64                               ; maximum signed 64 bit value

_UI64_MAX	    := 0xffffffffffffffffui64                               ; maximum unsigned 64 bit value

if (_INTEGRAL_MAX_BITS >= 128) {
    _I128_MIN   := -170141183460469231731687303715884105727i128 - 1     ; minimum signed 128 bit value
    _I128_MAX   := 170141183460469231731687303715884105727i128          ; maximum signed 128 bit value
    _UI128_MAX  := 0xffffffffffffffffffffffffffffffffui128              ; maximum unsigned 128 bit value
}

if (SIZE_MAX)
    if(A_PtrSize = 8)
        SIZE_MAX := _UI64_MAX
    else
        SIZE_MAX := UINT_MAX

if (__STDC_WANT_SECURE_LIB__)
    if(RSIZE_MAX)
        RSIZE_MAX := SIZE_MAX >> 1

/*

..

#define SHRT_MIN    (-32768)        /* minimum (signed) short value */
#define SHRT_MAX      32767         /* maximum (signed) short value */
#define USHRT_MAX     0xffff        /* maximum unsigned short value */
#define INT_MIN     (-2147483647 - 1) /* minimum (signed) int value */
#define INT_MAX       2147483647    /* maximum (signed) int value */
#define UINT_MAX      0xffffffff    /* maximum unsigned int value */
#define LONG_MIN    (-2147483647L - 1) /* minimum (signed) long value */
#define LONG_MAX      2147483647L   /* maximum (signed) long value */
#define ULONG_MAX     0xffffffffUL  /* maximum unsigned long value */

#if     _INTEGRAL_MAX_BITS >= 8
#define _I8_MIN     (-127i8 - 1)    /* minimum signed 8 bit value */
#define _I8_MAX       127i8         /* maximum signed 8 bit value */
#define _UI8_MAX      0xffui8       /* maximum unsigned 8 bit value */
#endif

#if     _INTEGRAL_MAX_BITS >= 16
#define _I16_MIN    (-32767i16 - 1) /* minimum signed 16 bit value */
#define _I16_MAX      32767i16      /* maximum signed 16 bit value */
#define _UI16_MAX     0xffffui16    /* maximum unsigned 16 bit value */
#endif

#if     _INTEGRAL_MAX_BITS >= 32
#define _I32_MIN    (-2147483647i32 - 1) /* minimum signed 32 bit value */
#define _I32_MAX      2147483647i32 /* maximum signed 32 bit value */
#define _UI32_MAX     0xffffffffui32 /* maximum unsigned 32 bit value */
#endif

#if     _INTEGRAL_MAX_BITS >= 64
/* minimum signed 64 bit value */
#define _I64_MIN    (-9223372036854775807i64 - 1)
/* maximum signed 64 bit value */
#define _I64_MAX      9223372036854775807i64
/* maximum unsigned 64 bit value */
#define _UI64_MAX     0xffffffffffffffffui64
#endif

#if     _INTEGRAL_MAX_BITS >= 128
/* minimum signed 128 bit value */
#define _I128_MIN   (-170141183460469231731687303715884105727i128 - 1)
/* maximum signed 128 bit value */
#define _I128_MAX     170141183460469231731687303715884105727i128
/* maximum unsigned 128 bit value */
#define _UI128_MAX    0xffffffffffffffffffffffffffffffffui128
#endif
