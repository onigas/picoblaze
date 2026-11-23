# Validare — 23 noiembrie 2026

## Surse oficiale și pini

Componenta și perifericele au fost verificate în manualul Digilent Basys 3; XDC-ul activ a fost comparat automat cu fișierul master oficial inclus ca referință. Rezultat: **52 porturi, 52 pini diferiți, toate atribuirile identice cu Digilent**. Sunt active numai resursele cerute în ultima precizare.

Nucleul, șablonul ROM și cele două executabile Xilinx au fost comparate prin SHA-256 cu proiectul anterior: identice. Verilog-ul memoriei a fost regenerat din programul Basys 3, nu copiat din aplicația Nexys. HEX: 4096 cuvinte de 18 biți, toate pozițiile peste 3FF sunt zero; memoria instanțiată este de 1K.

## Implementare Vivado 2022.2

- FPGA: xc7a35tcpg236-1.
- Sinteză, plasare și rutare efectuate local.
- DRC: **0 încălcări**.
- Timing: **WNS +0,640 ns**, **WHS +0,115 ns**, TNS/THS zero.
- Zero registre fără ceas și zero endpoint-uri interne neconstrânse.
- Ceasul sistemului: 100 MHz. DRCK și UPDATE sunt modelate separat pentru analiza loaderului.
- Bitstream: `output/PicoBlaze_Basys3.bit`.
- Resurse: aproximativ 294 LUT, 398 registre, un RAMB18E1 pentru program și un BSCANE2 pentru loader; vezi raportul de utilizare.

Intrările externe asincrone au excepții numai până la primul etaj de sincronizare. Ieșirile LED/afișaj/UART nu au ceas extern de captură și sunt exceptate de la analiza I/O sincronă. Aceste excepții sunt explicite în XDC.

**Limita raportului CDC:** cele 22 de intrări externe și resetul JTAG spre ceasul procesorului sunt clasificate „Safe”. În loaderul Xilinx nemodificat există traversări DRCK–UPDATE clasificate de analiza structurală drept „Critical”: 15 endpoint-uri „Unsafe” și 26 „Unknown” cumulat în cele două sensuri. Ele sunt gestionate prin protocolul scan/update al șablonului original și exceptate ca grupuri de ceas asincrone. Nu am ascuns aceste rezultate și nu pretind validarea protocolului JTAG pe hardware. Raportul `output/cdc.rpt` este inclus integral.

Avertizările legacy privind declarații de parametri în nucleul Xilinx, semnale implicit declarate în șablon și eliminarea logicii neutilizate sunt păstrate în jurnal; nu s-a modificat nucleul pentru a le elimina.

## Simulare funcțională

XSim 2022.2, nucleu KCPSM6 și memorie originală generate: **SIM_PASS**.

- Execuția programului din BRAM și oglindirea fiecărui switch în LED-ul corespunzător.
- Ordinea celor patru digiți și codul fizic CA–CG pentru cifra C.
- Toate cele cinci butoane și punctele zecimale aferente.
- Ecou UART pentru 55, 00, FF și A6.
- Reset U+D și repornire.
- Reset prin `rdl` și repornire; testul forțează semnalul, nu execută tranzacții JTAG.

Debounce-ul este scurtat numai în testbench. Testul se termină la aproximativ 1,863 ms simulate. Scriptul întoarce eroare dacă lipsește mesajul SIM_PASS sau simulatorul raportează Fatal.

## Verificări pe hardware

Nu s-a programat o placă fizică și nu s-a testat ecoul pe un port COM real. JTAG Loader a fost pornit numai cu opțiunea `-h`, folosind bibliotecile ISE 14.7: executabilul funcționează și confirmă opțiunile `-d`, `-l`, implicit USER2 și BRAM 0. Compatibilitatea efectivă a cablului/driverului și încărcarea memoriei pe Basys 3 rămân de verificat de utilizator.

Pentru acceptarea pe placă: programează bitstream-ul, verifică switch/LED/afișaj/butoane, rulează test_uart.ps1 cu portul COM corect, apoi schimbă un comportament vizibil în demo.psm, reasamblează și încarcă demo.hex prin scriptul ISE. Confirmă schimbarea fără reprogramarea bitstream-ului.

## Crearea proiectului separat

Scriptul `scripts/create_project.tcl` a fost executat cu succes în Vivado 2022.2: proiectul xc7a35tcpg236-1 a fost creat cu sursele, memoria și constrângerile corecte, fără pornirea sintezei. Scriptul build.tcl reutilizează această configurare.
