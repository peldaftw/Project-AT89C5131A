cseg at 0
jmp main


;Externe Interrupt
;---------------------------------------------------------------------------------------------
;P3.2  level hochz�hlen
org 03h 
						mov a,level
						cjne a,#000Fh,erhoehe
zurueckerhoehe:			clr C
						reti


org 13h 
						mov a,level
						cjne a,#0000h,vermindere
zurueckvermindere:		clr C
						reti
;---------------------------------------------------------------------------------------------
erhoehe:		inc level
				ljmp zurueckerhoehe
vermindere: 	dec level
				ljmp zurueckvermindere

;---------------------------------------------------------------------------------------------

;Einsprung (Hauptprogramm)
main:
								;Vorbereitung f�r PGM
;-------------------------------------------------------------------------------------------------------------------------------------------

;Interrupts vorbereiten
;---------------------------------------------------------------------------------------------
setb ea
setb ex0
setb IT0					;�bernehmen bei Aballender Flanke des Interrupts 0
setb ex1
setb IT1
;---------------------------------------------------------------------------------------------


;Equals (Zuweisung der ''Variablen'')
;---------------------------------------------------------------------------------------------
anfangswert equ 30h
endwert equ 31h
level equ 32h
zeahlfaktor equ 33h
uberlaufzahler equ 34h
;---------------------------------------------------------------------------------------------


;Port zuweisung
;---------------------------------------------------------------------------------------------
Ausgabeport equ p2.0
AusgabeDisplayport equ p0
;---------------------------------------------------------------------------------------------


;Config (Startwerte f�r das Programm
;---------------------------------------------------------------------------------------------
mov anfangswert,#1
mov endwert,#255
mov level,#0		
mov uberlaufzahler,#0
;---------------------------------------------------------------------------------------------


;Timer init (Einstellungen des Timers)
;---------------------------------------------------------------------------------------------
anl tmod,#11111011b	
orl tmod,#01h
mov tl0,anfangswert
mov th0,endwert
;---------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------------------------------


;Start des eigentlichen Programms
call anzeigen
jmp aus


;Auszyklus f�r den Motor
;---------------------------------------------------------------------------------------------
aus:
mov tl0,anfangswert
mov th0,endwert
clr C
mov Ausgabeport,C
mov A,#15					;Akku mit Konstante 15 vorladen
clr C						;Carry bit auf 0 setzen
SUBB A,level				;Level wird von 10 Abgezogen um die "Aus" Zeit des Ports zu bestimmen allerdings wird das doppelte ben�tigt (ein durchgang nur 0,06s lang)
mov zeahlfaktor,A			; anzahl an duchg�ngen des z�hlers mal 2

setb tr0 
call zaehlen
clr tr0

jmp an
;---------------------------------------------------------------------------------------------


;Auszyklus f�r den Motor
;---------------------------------------------------------------------------------------------
an:
mov tl0,anfangswert
mov th0,endwert
setb C
mov Ausgabeport,C
mov A,level					;Akku mit level laden		
mov zeahlfaktor,A
			
setb tr0 
call zaehlen
clr tr0

jmp aus
;---------------------------------------------------------------------------------------------


;Zeitliche verz�gerung f�r den aus bzw an zustand des Motors
;�berpr�fung ob Z�hler schon so oft �bergelaufen ist wie gew�nscht
;---------------------------------------------------------------------------------------------
zaehlen:
									;Starten von timer
mov a,zeahlfaktor							;zeahlfaktor wird geladen(Wie oft �berlaufen soll, wird in akku geladen)
cjne a,uberlaufzahler,uberlaufcheck			;Akku mit �berlaufz�hler vergleichen wenn ungleich sprung nach uberlaufcheck sonst weiter
mov uberlaufzahler,#00h

ret										   	;springe zur�ck zur stelle nach dem zaehlen aufgerufen wurde
;---------------------------------------------------------------------------------------------


;�berpr�fung ob der Z�hler �bergelaufen ist
;---------------------------------------------------------------------------------------------
uberlaufcheck:
jnb tf0,zaehlen				;Timer �berlauf? wenn nein, springe zu zaehlen
inc uberlaufzahler
clr tf0
jmp zaehlen
;---------------------------------------------------------------------------------------------


;Ausgabe an der 7-Segment-Anzeige
;---------------------------------------------------------------------------------------------
anzeigen:				  	
		mov a, level					; Zahl an level einlesen	
		anl a, #0Fh						; obere 4 Bits ausblenden
		mov dptr, #seg7code 			; Datenpointer init.
		movc a, @a+dptr					; ROM-Zugriff
		mov AusgabeDisplayport, a		; Zahl anzeigen
		ret
;---------------------------------------------------------------------------------------------


;look-up Tabelle f�r die 7-Segment-Anzeige
;---------------------------------------------------------------------------------------------
seg7code:   DB 01111110b,00010010b,10111100b,10110110b
			DB 11010010b,11100110b,11101110b,00110010b
			DB 11111110b,11110110b,11111010b,11001110b
			DB 01101100b,10011110b,11101100b,11101000b	
;---------------------------------------------------------------------------------------------

	
					
end	