# 6502 Monitor

## Unformatted notes

```
; VIA1 (right)
;   Port A
;           A0-A7 --> SN76489
;   Port B
;           B0    --> SN76489 /WE
;           B1    --> SN76489 RDY
;           B0-B1 --> SOUND
;           B2-B7 --> unconnected
;
; VIA2 (left)
;   Port A
;           A0-A3 --> LCD D7..D0
;           A4    --> LCD E
;           A5    --> LCD RW
;           A6    --> LCD RS
;           A7    --> USER LED
;   Port B
;           B0-B7 --> unconnected
```