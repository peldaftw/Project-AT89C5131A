cseg at 0
jmp main

;Interrupts
;-----------------------------------------------------------
org 03h												   ;p3.2
		jmp runter

org 13h												   ;p3.3
		jmp hoch

org 0Bh												   ;TF0 = Überlaufinterrupt
		jmp ueberlauf
;----------------------------------------------------------------------------

;Verarbeitung Interrupts
;----------------------------------------------------------------------------
runter:				mov a,level
					cjne a,#0000h,vermindere
zurueckvermindere:	clr C
					call anzeigen
					reti
vermindere: 		dec level
					ljmp zurueckvermindere
;---------------------------------------------------
hoch:				mov a,level
					cjne a,#000Fh,erhoehe
zurueckerhoehe:		clr C
					call anzeigen
					reti
erhoehe:			inc level
					ljmp zurueckerhoehe
;---------------------------------------------------
ueberlauf:
					clr tr0				  ;Timer stoppen
					clr tf0				  ;Überlaufflag rücksetzen
					mov tl0,lowwert		  ;Startwerte für Timer setzen
					mov th0,highwert
					inc uberlaufzahler
					setb tr0	
					reti


;----------------------------------------------------------------------------


main:
;Interrupts vorbereiten
;----------------------------------------------------------------------------
setb ea
setb ex0
setb IT0					
setb ex1
setb IT1
;----------------------------------------------------------------------------

;Equals (Zuweisung der ''Variablen'')
;----------------------------------------------------------------------------
highwert equ 30h
lowwert equ 31h
level equ 32h
zaehlfaktor equ 33h
uberlaufzahler equ 34h
;----------------------------------------------------------------------------

;Port zuweisung
;----------------------------------------------------------------------------
Ausgabeport equ p2.0
AusgabeDisplayport equ p0
;----------------------------------------------------------------------------

;Config (Startwerte für das Programm)
;----------------------------------------------------------------------------
mov highwert,#11111110b
mov lowwert,#11111111b
mov level,#07h		
mov uberlaufzahler,#0
;----------------------------------------------------------------------------

;Timer init (Einstellungen des Timers)
;----------------------------------------------------------------------------
anl tmod,#0f0h	
orl tmod,#01h
mov tl0,lowwert
mov th0,highwert
;----------------------------------------------------------------------------

call anzeigen
jmp aus

;Auszyklus für den Motor
;----------------------------------------------------------------------------
aus:
			mov uberlaufzahler,#0
			mov A,#15					;Akku mit Konstante 15 vorladen
			clr C						;Carry bit auf 0 setzen
			SUBB A,level				;Level wird von 10 Abgezogen um die "Aus" Zeit des Ports zu bestimmen allerdings wird das doppelte benötigt (ein durchgang nur 0,06s lang)
			mov zaehlfaktor,A			; anzahl an duchgängen des zählers mal 2
			clr C
			mov Ausgabeport,C
			setb tr0
ausloop:	
			mov a, zaehlfaktor
			cjne a, uberlaufzahler, ausloop
			jmp an

an:
			mov uberlaufzahler,#0
			mov zaehlfaktor,level			; anzahl an duchgängen des zählers mal 2
			setb C
			mov Ausgabeport,C
			setb tr0
anloop:	
			mov a, zaehlfaktor
			cjne a, uberlaufzahler, anloop
			jmp aus
			
;----------------------------------------------------------------------------

;Ausgabe an der 7-Segment-Anzeige
;----------------------------------------------------------------------------
anzeigen:				  	
		mov a, level					; Zahl an level einlesen	
		anl a, #0Fh						; obere 4 Bits ausblenden
		mov dptr, #seg7code 			; Datenpointer init.
		movc a, @a+dptr					; ROM-Zugriff
		mov AusgabeDisplayport, a		; Zahl anzeigen
		ret
;----------------------------------------------------------------------------

;look-up Tabelle für die 7-Segment-Anzeige
;----------------------------------------------------------------------------
seg7code:   DB 01111110b,00010010b,10111100b,10110110b
			DB 11010010b,11100110b,11101110b,00110010b
			DB 11111110b,11110110b,11111010b,11001110b
			DB 01101100b,10011110b,11101100b,11101000b	
;----------------------------------------------------------------------------
end