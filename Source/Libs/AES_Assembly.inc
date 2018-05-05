{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Rijndael/AES cipher

  ©František Milt 2018-05-03

  Version 1.1.2

  This file contains code fragments used in assembly implementation of
  hardware-accelerated AES cipher.

===============================================================================}

{$IFDEF KeyExpand_128_RoundCommon}
    SHUFPS    XMM1, XMM1, $FF
    PXOR      XMM1, XMM0
    PSLLDQ    XMM0, 4
    PXOR      XMM1, XMM0
    PSLLDQ    XMM0, 4
    PXOR      XMM1, XMM0
    PSLLDQ    XMM0, 4
    PXOR      XMM1, XMM0

    MOVAPS    XMM0, XMM1
    ADD       KeySchedule,  16
    MOVAPS    dqword ptr [KeySchedule],  XMM0
{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF KeyExpand_192_RoundCommon_1}
    SHUFPS    XMM3, XMM3, $FF
    PXOR      XMM3, XMM2
    PSLLDQ    XMM2, 4
    PXOR      XMM3, XMM2
    PSLLDQ    XMM2, 4
    PXOR      XMM3, XMM2
    PSLLDQ    XMM2, 4
    PXOR      XMM3, XMM2

    MOVAPS    dqword ptr [KeySchedule], XMM3
    ADD       KeySchedule,  16

    MOVAPS    XMM0, XMM3

    SHUFPS    XMM3, XMM3, $FF
    PSRLDQ    XMM1, 8
    PXOR      XMM3, XMM1
    PSLLDQ    XMM1, 4
    PXOR      XMM3, XMM1
    MOVAPS    XMM2, XMM3
    MOVAPS    XMM1, XMM0
{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF KeyExpand_192_RoundCommon_2}
    SHUFPS    XMM3, XMM3, $55
    PXOR      XMM3, XMM1
    PSLLDQ    XMM1, 4
    PXOR      XMM3, XMM1
    PSLLDQ    XMM3, 8
    MOVSD     XMM3, XMM2

    MOVAPS    dqword ptr [KeySchedule], XMM3
    ADD       KeySchedule,  16

    MOVAPS    XMM1, XMM3
    MOVHLPS   XMM2, XMM0
    MOVLHPS   XMM2, XMM1

    SHUFPS    XMM3, XMM3, $FF
    PXOR      XMM3, XMM2
    PSLLDQ    XMM2, 4
    PXOR      XMM3, XMM2
    PSLLDQ    XMM2, 4
    PXOR      XMM3, XMM2
    PSLLDQ    XMM2, 4
    PXOR      XMM3, XMM2

    MOVAPS    dqword ptr [KeySchedule], XMM3
    ADD       KeySchedule,  16

    MOVAPS    XMM0, XMM1
    MOVAPS    XMM1, XMM3
    MOVHLPS   XMM2, XMM0
    MOVLHPS   XMM2, XMM1
{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF KeyExpand_256_RoundCommon_1}
    SHUFPS    XMM2, XMM2, $FF
    PXOR      XMM2, XMM0
    PSLLDQ    XMM0, 4
    PXOR      XMM2, XMM0
    PSLLDQ    XMM0, 4
    PXOR      XMM2, XMM0
    PSLLDQ    XMM0, 4
    PXOR      XMM2, XMM0

    MOVAPS    XMM0, XMM2
    MOVAPS    dqword ptr [KeySchedule], XMM2
    ADD       KeySchedule,  16
{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF KeyExpand_256_RoundCommon_2}
    SHUFPS    XMM2, XMM2, $AA
    PXOR      XMM2, XMM1
    PSLLDQ    XMM1, 4
    PXOR      XMM2, XMM1
    PSLLDQ    XMM1, 4
    PXOR      XMM2, XMM1
    PSLLDQ    XMM1, 4
    PXOR      XMM2, XMM1

    MOVAPS    XMM1, XMM2
    MOVAPS    dqword ptr [KeySchedule], XMM2
    ADD       KeySchedule,  16
{$ENDIF}
