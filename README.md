# PicoBlaze KCPSM6 — Basys 3 / Vivado 2022.2

Proiect adaptat dintr-o implementare funcțională KCPSM6 pentru Nexys 4 DDR. Varianta curentă include numai **16 switch-uri, 5 butoane, 16 LED-uri, afișajul de 4 digiți și UART**, conform restrângerii cerute. FPGA: **xc7a35tcpg236-1**, ceas: **100 MHz**.

## Pornire rapidă

1. Clonează repository-ul sau descarcă arhiva ZIP într-un director local cu drept de scriere.
2. Rulează `scripts\build.cmd`. Calea implicită este `C:\Xilinx\Vivado\2022.2\bin\vivado.bat`; pentru altă instalare setează variabila `VIVADO_BAT` la fișierul corespunzător.
3. Deschide proiectul `vivado\PicoBlaze_Basys3.xpr` în Vivado. Scriptul realizează sinteza și implementarea direct în sesiunea Tcl; starea GUI a run-urilor synth_1/impl_1 poate rămâne „Not started”. Implementarea rutată este în `output\routed.dcp`.
4. În Hardware Manager conectează placa Basys 3 prin USB-JTAG și programează `output\PicoBlaze_Basys3.bit`. Alternativ, din Vivado Tcl Console: `source <director>/scripts/program_board.tcl`. Scriptul acceptă un singur dispozitiv XC7A35T detectat.
5. Switch-urile trebuie să se reflecte identic în LED-uri. Afișajul prezintă valoarea switch-urilor în hexazecimal, SW15..12 la stânga și SW3..0 la dreapta.
6. Deschide portul COM al plăcii la **115200 baud, 8N1, fără flow control**. Fiecare octet primit este retransmis. Portul COM se identifică în Device Manager; nu este fixat la COM8.

Nu este necesară instalarea fișierelor „board files”: constrângerile și componenta FPGA sunt specificate explicit.

## Crearea proiectului fără compilare

Din directorul repository-ului, într-un terminal cu Vivado disponibil:

```bat
vivado -mode batch -source scripts/create_project.tcl
```

Sau în consola Tcl din Vivado:

```tcl
source C:/cale/catre/picoblaze/scripts/create_project.tcl
```

Rezultatul este `vivado/PicoBlaze_Basys3.xpr`, cu top-level `picoblaze_basys3`, sursele Verilog, memoria generată și XDC-ul Basys 3. Nu pornește sinteza sau implementarea. Fișierul `software/demo.v` este inclus; după modificarea programului rulează mai întâi `scripts/assemble.cmd`. Pentru compilare completă rulează `scripts/build.cmd`, care reutilizează acest script.

Scriptul folosește `create_project -force`: directorul generat `vivado` este recreat. Păstrează modificările proiectului în surse și scripturi înainte de rerulare.

## Butoane și reset

Cele cinci butoane sunt sincronizate și filtrate aproximativ 10 ms. În exemplu, C aprinde punctul zecimal al digitului 0 (dreapta), R al digitului 1, L al digitului 2, iar D sau U al digitului 3. Toate cele cinci stări sunt disponibile separat la citirea portului 02.

Ținerea simultană a **U+D** resetează procesorul, LED-urile, afișajul și UART. La eliberare programul repornește. Niciun buton individual nu este rezervat exclusiv resetului. La configurare există un reset automat de circa 655 µs. Butonul fizic de configurare al plăcii nu este un pin CPU_RESETN utilizabil ca pe Nexys.

## Module și memorie

| Fișier | Rol |
|---|---|
| `rtl/picoblaze_basys3.v` | Top-level, reset, sincronizare switch-uri, decodare porturi |
| `rtl/kcpsm6.v` | Nucleul Xilinx original, copiat nemodificat din proiectul funcțional |
| `rtl/button_filter.v` | Sincronizare și debounce pentru 5 butoane |
| `rtl/seven_segment_scan.v` | Multiplexare 4 digiți, decodare hex, puncte zecimale |
| `rtl/uart_115200.v` | UART TX/RX, buffer RX de un octet |
| `software/demo.psm` | Programul demonstrativ editabil |
| `software/demo.v` | Memorie generată de asamblor, utilizată la sinteză |
| `software/demo.hex` | Imagine pentru JTAG Loader |
| `software/ROM_form.v` | Șablon Xilinx pentru asamblor; **nu se adaugă la sursele Vivado** |
| `constraints/Basys3.xdc` | Numai pinii perifericelor prezente în top-level |
| `sim/tb_basys3.v` | Test de integrare cu nucleul și memoria reale |

Memoria are **1024 instrucțiuni × 18 biți**, cu `.C_FAMILY("7S")`, `.C_RAM_SIZE_KWORDS(1)` și **`.C_JTAG_LOADER_ENABLE(1)`**. Adresele utilizabile sunt 000–3FF; magistrala nucleului are 12 biți. Scratchpad: 64 octeți. Întreruperile sunt dezactivate; la 3FF există `RETURNI DISABLE`. `OUTPUTK` nu este decodat de periferice; se utilizează `OUTPUT`.

Semnalul `rdl` al memoriei produce resetul sistemului în timpul încărcării; eliberarea resetului este sincronizată la ceasul de 100 MHz. Programul repornește de la adresa zero. Memoria utilizează mecanismul BSCAN din șablonul original, fără pini JTAG declarați în top-level sau XDC.

Asamblorul emite un HEX cu 4096 poziții; în această configurație numai primele 1024 sunt utilizate, iar pozițiile superioare sunt zero. Aceasta nu înseamnă că memoria hardware are 4K. Nu introduce instrucțiuni după adresa 3FF.

Constrângerile modelează separat ceasurile BSCAN DRCK și UPDATE, cu un buget de analiză de 10 ns. Aceasta nu modifică frecvența cablului. Traversările dintre aceste evenimente și ceasul procesorului sunt asincrone și se bazează pe protocolul șablonului Xilinx, inclusiv menținerea procesorului în reset în timpul scrierii BRAM. Raportul CDC poate semnala aceste traversări ale loaderului; ele nu reprezintă o verificare hardware a protocolului JTAG.

## Harta porturilor — numere hexazecimale

| Port | Operație | Semnificație |
|---|---|---|
| 00 | INPUT | SW7..0 |
| 01 | INPUT | SW15..8 |
| 02 | INPUT | biții 4..0 = U,D,L,R,C; biții 7..5 = 0 |
| 10 | OUTPUT | LED7..0 |
| 11 | OUTPUT | LED15..8 |
| 20–23 | OUTPUT | digit 0–3; biții 3..0 = hex, bit 7 = punct aprins; 6..4 ignorați |
| 30 | INPUT | date UART; citirea consumă octetul și șterge RX-valid |
| 30 | OUTPUT | transmitere UART, acceptată numai dacă TX-ready=1 |
| 31 | INPUT | bit 0 = RX-valid, bit 1 = TX-ready; restul 0 |

Citirile nemapate întorc zero; scrierile nemapate sunt ignorate. UART are buffer de un octet, fără FIFO sau flow control. Dacă software-ul nu citește la timp, octetul următor îl poate suprascrie. Nu este garantat un flux continuu fără pierderi la saturație; testul furnizat trimite un octet și așteaptă ecoul. Cadrele cu stop invalid sunt ignorate.

Afișajul este activ pe zero: `seg[0]`=CA până la `seg[6]`=CG. `an[0]` selectează digitul din dreapta. Scanarea are 125 µs/digit, aproximativ 2 kHz/cadru; o pauză de 160 ns la schimbarea digitului reduce suprapunerea segmentelor.

## Actualizarea programului cu JTAG Loader și ISE

Hardware-ul se compilează în **Vivado 2022.2**. Pentru schimbarea programului fără refacerea bitstream-ului se utilizează executabilul original **Xilinx JTAG Loader**, cu bibliotecile și driverele **ISE 14.7**.

1. Programează FPGA cu bitstream-ul acestui proiect.
2. Închide conexiunea la cablu din Vivado Hardware Manager (`close_hw_target`, apoi `disconnect_hw_server`) și eliberează cablul din iMPACT sau alte aplicații.
3. Editează `software\demo.psm` și rulează `scripts\assemble.cmd`. Verifică succesul în `software\demo.log` și regenerarea `demo.hex`.
4. Rulează `scripts\load_program_jtag.cmd`. Acesta apelează `C:\Xilinx\14.7\ISE_DS\settings64.bat`, configurează bibliotecile ISE și execută `JTAG_Loader_Win7_64.exe -d -l demo.hex`. Opțiunea `-d` selectează cablul Digilent Adept; `-l` este litera L mică.
5. Pentru o altă instalare setează `ISE_DS_ROOT` la directorul `ISE_DS` înainte de rulare. Driverele de cablu Digilent compatibile cu ISE trebuie instalate; simpla existență a Vivado nu le înlocuiește.

Executabilul este cel din proiectul precedent, denumit pentru Windows 7 pe 64 biți. Funcționarea sa cu sistemul de operare, driverul și placa efectiv conectată trebuie confirmată pe hardware. Nu am executat o încărcare pe placa fizică în această pregătire. În caz de probleme de detectare a cablului, verifică disponibilitatea plăcii în iMPACT, apoi închide conexiunea iMPACT înainte de Loader. `JTAG_Loader_Win7_64.exe -h` afișează opțiunile versiunii instalate.

Actualizarea modifică **BRAM volatilă**, nu flash-ul plăcii. La reconfigurare sau oprire se pierde programul încărcat astfel și revine imaginea inclusă în bitstream. Pentru a schimba acea imagine, rulează din nou build și programează bitstream-ul rezultat. Dacă schimbi perifericele, harta porturilor sau dimensiunea memoriei, este necesară și recompilarea hardware.

Nu este inclus scriptul experimental de încărcare a programului prin Tcl/Vivado din proiectul anterior. Scripturile Tcl prezente sunt pentru compilare, simulare și programarea standard a **bitstream-ului**.

## Verificare

Rezultatele efective sunt consemnate în `docs/VALIDARE.md`, iar rapoartele Vivado în `output`.

Simulare reproductibilă din directorul proiectului:

```bat
C:\Xilinx\Vivado\2022.2\bin\vivado.bat -mode batch -source scripts/simulate.tcl
```

Testul folosește nucleul Xilinx și memoria generată, scurtează numai debounce-ul mecanic, verifică fiecare switch, maparea afișajului, cele cinci butoane, octeții UART 55/00/FF/A6 și reseturile. Nu simulează protocolul extern JTAG Loader. Rezultatul de succes este mesajul `SIM_PASS`.

După programarea plăcii, închide terminalul serial și rulează în PowerShell, înlocuind COMx:

```powershell
.\scripts\test_uart.ps1 -Port COMx
```

## Surse și proveniență

- [Digilent Basys 3 Reference Manual, rev. C](https://digilent.com/reference/_media/basys3:basys3_rm.pdf): componenta FPGA, ceasul, resursele și polaritățile interfețelor.
- [Digilent Basys-3-Master.xdc](https://github.com/Digilent/digilent-xdc/blob/master/Basys-3-Master.xdc): atribuirea pinilor; copie de referință păstrată în `docs`. Pinii neutilizați nu sunt activați în constrângerile proiectului.
- [AMD PicoBlaze](https://www.amd.com/en/products/adaptive-socs-and-fpgas/intellectual-property/picoblaze.html): pagina oficială a nucleului.
- Sursele Xilinx `kcpsm6.v`, `ROM_form.v` și executabilele au fost preluate din proiectul local funcțional; antetele originale de copyright și licență sunt păstrate. Nucleul este destinat dispozitivelor Xilinx. Nu sunt înlocuite cu o implementare terță.

Pachetul actual nu include Pmod, VGA, PS/2, XADC sau flash în top-level, conform cererii finale. Copia master XDC este doar referință și nu trebuie adăugată la constrângerile active.
