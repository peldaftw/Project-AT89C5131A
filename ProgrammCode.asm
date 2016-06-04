cseg at 0
jmp main


;Externe Interrupt
;---------------------------------------------------------------------------------------------
;P3.2  level hochzählen
org 03h			  			
			anl level,#15
			jc zuhoch   	;Wenn Level == 15, springe zu zuhoch
			inc level		;Wenn nicht 15, dann ist es möglich zu inkrementieren
zuhoch:		clr C
			ljmp anzeigen
			reti

;P3.3  level runterzählen
org 13h 					
			anl level,#0
			jc zuniedrig ;Wenn Level == 0, springe zu zuniedrig
			dec level		;Wenn nicht 0, dann ist es möglich zu dekrementieren
zuniedrig:	clr C
			ljmp anzeigen
			reti
;---------------------------------------------------------------------------------------------


;Einsprung (Hauptprogramm)
main:
								;Vorbereitung für PGM
;-------------------------------------------------------------------------------------------------------------------------------------------

;Interrupts vorbereiten
;---------------------------------------------------------------------------------------------
setb ea
setb ex0
setb IT0					;Übernehmen bei Aballender Flanke des Interrupts 0
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


;Config (Startwerte für das Programm
;---------------------------------------------------------------------------------------------
mov anfangswert,#1
mov endwert,#255
mov level,#07h		
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


;Auszyklus für den Motor
;---------------------------------------------------------------------------------------------
aus:
mov tl0,anfangswert
mov th0,endwert
clr C
mov Ausgabeport,C
mov A,#15					;Akku mit Konstante 15 vorladen
clr C						;Carry bit auf 0 setzen
SUBB A,level				;Level wird von 10 Abgezogen um die "Aus" Zeit des Ports zu bestimmen allerdings wird das doppelte benötigt (ein durchgang nur 0,06s lang)
mov zeahlfaktor,A			; anzahl an duchgängen des zählers mal 2

call zaehlen
jmp an
;---------------------------------------------------------------------------------------------


;Auszyklus für den Motor
;---------------------------------------------------------------------------------------------
an:
mov tl0,anfangswert
mov th0,endwert
setb C
mov Ausgabeport,C
mov A,level					;Akku mit level laden		
mov zeahlfaktor,A			

call zaehlen
jmp aus
;---------------------------------------------------------------------------------------------


;Zeitliche verzögerung für den aus bzw an zustand des Motors
;Überprüfung ob Zähler schon so oft übergelaufen ist wie gewünscht
;---------------------------------------------------------------------------------------------
zaehlen:
setb tr0 									;Starten von timer
mov a,zeahlfaktor							;zeahlfaktor wird geladen(Wie oft Überlaufen soll, wird in akku geladen)
cjne a,uberlaufzahler,uberlaufcheck			;Akku mit Überlaufzähler vergleichen wenn ungleich sprung nach uberlaufcheck sonst weiter
mov uberlaufzahler,#00h
clr tr0
ret										   	;springe zurück zur stelle nach dem zaehlen aufgerufen wurde
;---------------------------------------------------------------------------------------------


;Überprüfung ob der Zähler übergelaufen ist
;---------------------------------------------------------------------------------------------
uberlaufcheck:
jnb tf0,zaehlen				;Timer Überlauf? wenn nein, springe zu zaehlen
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


;look-up Tabelle für die 7-Segment-Anzeige
;---------------------------------------------------------------------------------------------
seg7code:   DB 01111110b,00010010b,10111100b,10110110b
			DB 11010010b,11100110b,11101110b,00110010b
			DB 11111110b,11110110b,11111010b,11001110b
			DB 01101100b,10011110b,11101100b,11101000b	
;---------------------------------------------------------------------------------------------

					
end	