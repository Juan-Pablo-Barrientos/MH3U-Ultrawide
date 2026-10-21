[MH3U_Ultrawide_US_v32]
moduleMatches = 0x9d2f15e5

; Each frame, the viewport update at 0x02ba0474 sets a camera's aspect
; (camera +0x38) from its viewport's integer rect: (x1-x0)/(y1-y0).
; At that point r0 holds the width and r8 the height. Only the full
; 1920x1080 TV viewport gets widened, so smaller views keep their aspect.
; r7 and f13 are rewritten before the game reads them again.

.origin = codecave

_aspectScale:
.float ($width / $height) / (16.0 / 9.0)

_widenAspect:
fdivs f11, f11, f13
cmpwi r0, 1920
bne _widenAspectDone
cmpwi r8, 1080
bne _widenAspectDone
lis r7, _aspectScale@ha
lfs f13, _aspectScale@l(r7)
fmuls f11, f11, f13
_widenAspectDone:
blr

0x02ba0474 = bl _widenAspect
