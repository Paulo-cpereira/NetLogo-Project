extensions [rnd]
globals[
  cont_movs;
  turn_flag;
  aux;
  Toupeiras_mortas;
  N_relva;
  flag;
  contador_patch;
  contador_starved;
  nascimentos;
  inseridas;
]

breed [planta_relvas planta_relva]
breed [toupeiras toupeira]

toupeiras-own [energy]


to setup
  inicializar_campo

  set-default-shape planta_relvas "turtle"
  criar_planta-relva 0 0

  set-default-shape toupeiras "bug"
  insere_toupeira toupeiras_iniciais

  reset-ticks
end

to go
  ask patches[set N_relva count patches with [pcolor = lime]]
  touch-input
  ask planta_relvas
  [
    if Planta_relva_mov
    [
      andar_planta-relva
      matar_toupeiras-here
    ]
  ]

  if modo_automatico [update_board_afk]

  ask toupeiras[
    check-energy

    if Prob_toupeira > (random-float 1)[                                                                ;Se a Prob_toupeira (Probabilidade de mover) for superior a um valor entre 0
      andar_toupeira

      if count toupeiras-here with [energy >= Adult_energy] >= 2 [ask toupeiras-here[hatch_toupeira]]   ;Verifica a colisão e chama a função hatch_toupeira
    ]
  ]
  tick
end

to update_board_afk                                               ;Para acrescentar complexidade e imprivisibilidade ao algoritmo adicionamos probabilidades condicionadas
  if random-float 40 < Prob_praga                                 ;random-float x é para não inserir instantaneamente novas toupeiras
  [
    if N_relva > count patches / (1.5 + (0.5 * Prob_praga))[
      let pares[[1 0.6][2 0.25][3 0.09][4 0.05][5 0.01]]               ;É definida uma lista com o numero de toupeiras a adicionar e a probabilidade de ser a escolhida
      set aux first rnd:weighted-one-of-list pares [[p] -> last p]  ; É escolhido o primeiro argumento(first) de um dos pares da lista "pares"
      insere_toupeira aux
    ]
  ]
  if count toupeiras > 150
  [
    set modo_de_plantar "Manutenção"
  ]
end

to andar_toupeira
  ifelse [pcolor] of patch-ahead 1 = lime [avançar_toupeira]
      [
        ifelse energy < Adult_energy         ; Se a toupeira não for adulta
        [
          set heading heading + 90 ;Virar à direita
          ifelse [pcolor] of patch-ahead 1 = lime [avançar_toupeira]
          [
            set heading heading - 90 ;Vira para a frente
            ifelse [pcolor] of patch-ahead 1 = lime [avançar_toupeira]
            [
              set heading heading - 90 ;Vira à esquerda
              ifelse [pcolor] of patch-ahead 1 = lime [avançar_toupeira]
              [; Se não encontrar relva para comer, vira para a frente e anda
                set heading heading + 90
                avançar_toupeira
              ]
            ]
          ]
        ]
        [avançar_toupeira]
  ]
end

to avançar_toupeira
  forward 0.5
  if GetEnergyOnlyFromFood = true [set energy energy - 0.5]
  ask patch-here[
    if pcolor = lime
    [
      ask toupeiras-here[set energy (Grass_energy + energy)]
      set pcolor brown
      if N_relva > 0[set N_relva N_relva - 1]
    ]
  ]
  if random 40 = 2[set heading random 360]
end

to check-energy
  if GetEnergyOnlyFromFood = false[increment-energy]                    ;As toupeiras perdem energia ao andarem, não ganham energia a cada tick.[true]
                                                                        ;As toupeiras não perdem energia ao andarem, ganham energia a cada tick.[false]
  (ifelse
  energy < 0 [set contador_starved contador_starved + 1 die]         ;Verifica se a toupeira não tem energia, e mata-a se energia < 0
  energy <= 50 [set color red]                                       ;Verifições de energia para determinar o estado da toupeira (Esfomeada->Red, Normal->Blue, Fertil->Black)
  energy > 50 and energy < Adult_energy [set color blue]
  energy >= Adult_energy [set color black]
  )
end

to touch-input; handles user touch input
  if mouse-down?
  [
    ask patch mouse-xcor mouse-ycor
    [
      ifelse modo_manual = "Comer"[set pcolor brown ask neighbors [set pcolor brown]]
      [
        if modo_manual = "Plantar" [set pcolor lime set pcolor lime]
      ]
    ]
  ]
end

to-report grass-right
  right 90
  ifelse [pcolor] of patch-ahead 1 = lime
  [left 90 report true]
  [left 90 report false]
end

to-report grass-left
  left 90
  ifelse [pcolor] of patch-ahead 1 = lime
  [right 90 report true]
  [right 90 report false]
end

to increment-energy
  set energy (1 + energy)
end

to kill-toupeiras
  ask toupeiras[die]
end

to insere_toupeira [x]
  let pares[[40 0.05][80 0.9][320 0.05]]                              ;É definida uma lista com a energia inicial e a probabilidade de ser a escolhida
  set inseridas inseridas + x                                         ;Incrementa o contador de toupeiras inseridas
  create-toupeiras x[
    set energy first rnd:weighted-one-of-list pares [[p] -> last p]   ; É escolhido o primeiro argumento(first) de um dos pares da lista "pares"
                                                                      ;write energy ;(Debug)
    (  ifelse                                                         ;Inicializamos a energia inicial
    energy = 320 [set color black ]                                   ;Cor inicial
    energy = 80 [set color blue  ]
    energy = 40 [set color red] )
    setxy random sqrt(count patches) random sqrt(count patches)       ;Coordenadas iniciais random entre 0 e o comprimento da view
    set size 2                                                        ;Tamanho inicial 2
    set heading random 360                                            ;Direção inicial random
  ]
end

to hatch_toupeira
  if energy >= Adult_energy
  [
    if Prob_hatch > random-float 1
    [
      ask toupeiras-here [set energy Adult_energy / 2]
      set color blue
      set nascimentos nascimentos + 1
      hatch-toupeiras 1
      [
        set color blue
        set energy (Adult_energy / 2 + random 30)            ; A Energia inicial de uma toupeira procriada é metade da energia para atingir o estado adulto/fertil mais um valor de 0 a 29
        set heading random 360                               ; EX: Adult_energy = 300 -> energy varia entre [150, 179]
      ]
    ]
  ]
end

to avançar
  forward 1
  if random 20 = 2[
    ifelse random 2 = 0
    [    set heading heading + 90]
    [    set heading heading - 90]
  ]
end

to plantar_tudo
  ask patches[set pcolor lime]
end

to comer_tudo
  ask patches[set pcolor brown]
end

to avançar_plantar
  forward 1
  set contador_patch contador_patch + 1
  set cont_movs cont_movs + 1
  ask patch-here[set pcolor lime]
  set N_relva N_relva + 1
end

to right180
  set heading heading + 90
  avançar_plantar
  set heading heading + 90
  set turn_flag 1
end

to left180
  set heading heading - 90
  avançar_plantar
  set heading heading - 90
  set turn_flag 0
end

to inicializar_campo
  clear-all
  set inseridas 0
  set nascimentos 0
  set contador_starved 0
  set contador_patch 0
  set Prob_hatch 0.5
  set Prob_toupeira 0.5
  set Adult_energy 300
  set Grass_energy 20
  set modo_de_plantar "Serpentina"
  set flag 0;
  set N_relva 0
  set Toupeiras_mortas 0
  set cont_movs 0
  set turn_flag 0
  ask patches[
    set pcolor brown
  ]

end

to criar_planta-relva [x y]
  create-planta_relvas 1[
    set heading one-of[0 90 180 270]
    setxy x y
    ask patch-here[set pcolor lime]
    if modo_de_plantar = "Serpentina"[set heading 0]
    set size 2.5
  ]
end

to Remover_planta-relva
  ask one-of planta_relvas[die]
end


to andar_planta-relva
  (ifelse
  modo_de_plantar = "Frente" [plantar_frente]
  modo_de_plantar = "Serpentina"[plantar_serpentina]
  modo_de_plantar = "Manutenção"[plantar_manutencao]
  )
end

to plantar_frente
  ifelse [pcolor] of patch-ahead 1 = brown       ;Verificar se a patch da frente pode ser plantada
  [
    avançar_plantar                              ;Avança e planta relva
  ]
  [
    if grass-left != true [left 90]              ;Verifica se pode plantar do lado esquerdo
    if grass-right != true [right 90]            ;Verifica se pode plantar do lado direito


    if[pcolor] of patch-ahead 1 = lime  ;        ;Verifica se está rodeado de relva
    [
      set modo_de_plantar "Manutenção"           ;Atualiza o modo de plantação para "Manutenção"
      set contador_patch 0                       ;Inicializar variável para o modo "Manutenção"
    ]
  ]
end

to plantar_serpentina
  ifelse [pcolor] of patch-ahead 1 = brown       ;Verificar se a patch da frente pode ser plantada
  [
    avançar_plantar                              ;Avança e planta relva
  ]
  [

    if grass-right and grass-left                ;Verifica se tem relva do lado direito e do lado esquerdo
    [
      set modo_de_plantar "Manutenção"           ;Atualiza o modo de plantação para "Manutenção"
      set contador_patch 0                       ;Inicializar variável para o modo "Manutenção"
    ]
    ifelse turn_flag = 0                         ;Para a flag "turn_flag" :
    [
      right180                                   ;turn_flag = 0 (False) -> Inverte o sentido pelo lado da direita
    ]
    ;Else
    [
      left180                                    ;turn_flag = 1 (True) -> Inverte o sentido pelo lado da esquerda
    ]
  ]
end

to plantar_manutencao
  set heading heading + 90                                                             ;Virar à direita
  ifelse [pcolor] of patch-ahead 1 = brown [avançar_plantar]                           ;Se puder plantar, planta
  [
    set heading heading - 90                                                           ;Vira em frente

    ifelse [pcolor] of patch-ahead 1 = brown [set contador_patch 0 avançar_plantar]    ;Se puder plantar, planta
    [
      set heading heading - 90                                                         ;Vira à esquerda
      ifelse [pcolor] of patch-ahead 1 = brown [set contador_patch 0 avançar_plantar]  ;Se puder plantar, planta
      [
        set heading heading + 90                                                       ;Virar em frente
        ifelse contador_patch = sqrt(count patches) + 2                               ; Verifica se já percorreu o comprimento do campo + 1, se já vira à esquerda ou à direita
        [
          set contador_patch 0                                                        ; e reseta o contador_patch
          ifelse turn_flag = 0 [set turn_flag 1 right 90][set turn_flag 0 left 90]    ;Alterna entre mudar a direção para a esquerda ou direita, atraves de flag
                                                                                      ;Explicar no relatório o porque do uso de flag e não de random
        ]
        [
          forward 1                                                                    ;Avança sem plantar
          set contador_patch contador_patch + 1                                        ;Incrementa a variável contador_patch
        ]
      ]
    ]
  ]
end

to matar_toupeiras-here
  ask toupeiras-here                                                                     ;Verifica se no mesmo patch do planta_relva existem toupeiras
  [
     set Toupeiras_mortas Toupeiras_mortas + 1                                           ;Incrementa a variável global "Toupeiras_mortas"
     die                                                                                  ;Mata o agente "Toupeira"
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
604
14
1027
438
-1
-1
12.6
1
10
1
1
1
0
1
1
1
0
32
0
32
0
0
1
ticks
30.0

BUTTON
515
18
579
51
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
517
51
580
84
Go
go
T
1
T
OBSERVER
NIL
E
NIL
NIL
1

CHOOSER
284
97
422
142
modo_de_plantar
modo_de_plantar
"Frente" "Serpentina" "Manutenção"
1

MONITOR
406
235
536
280
Movimentos Planta relva
cont_movs
17
1
11

BUTTON
343
51
440
84
Inserir Toupeira
insere_toupeira 1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
353
157
525
190
Prob_toupeira
Prob_toupeira
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
181
190
353
223
Prob_hatch
Prob_hatch
0
1
0.5
0.01
1
NIL
HORIZONTAL

MONITOR
222
235
308
280
Toupeiras vivas
count Toupeiras
17
1
11

PLOT
34
279
606
483
População de toupeiras
Ticks
Toupeiras
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Toupeiras com fome" 1.0 0 -2674135 true "" "plot count Toupeiras with [energy < 50]"
"Toupeiras ferteis" 1.0 0 -16777216 true "" "plot count toupeiras with [energy > Adult_energy]"
"Toupeiras normais" 1.0 0 -13345367 true "" "plot count toupeiras with [color = blue]"

SLIDER
353
190
525
223
Adult_energy
Adult_energy
100
500
300.0
10
1
NIL
HORIZONTAL

BUTTON
440
51
517
84
Go once
go
NIL
1
T
OBSERVER
NIL
Q
NIL
NIL
1

SLIDER
449
101
587
134
toupeiras_iniciais
toupeiras_iniciais
0
20
5.0
1
1
NIL
HORIZONTAL

MONITOR
34
235
86
280
Comidas
Toupeiras_mortas
17
1
11

PLOT
315
483
606
677
Qualidade da relva
Ticks
Relva verde
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Relva" 1.0 0 -10899396 true "" "plot N_relva"
"Maximo de relva" 1.0 0 -7500403 true "" "plot count patches"

MONITOR
536
235
606
280
Relva verde
N_relva
17
1
11

BUTTON
229
51
343
84
Inserir 10 Toupeiras
insere_toupeira 10
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
606
438
1027
677
Aparecimento/Desaparecimento Toupeiras
Ticks
Toupeiras mortas
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Procriadas" 1.0 0 -13345367 true "" "plot nascimentos"
"Comidas" 1.0 0 -7171555 true "" "plot Toupeiras_mortas"
"Estrangeiras" 1.0 0 -6995700 true "" "plot inseridas"

SWITCH
101
102
256
135
Planta_relva_mov
Planta_relva_mov
0
1
-1000

BUTTON
203
19
300
52
Matar toupeiras
kill-toupeiras
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1061
151
1215
184
Modo_automatico
Modo_automatico
1
1
-1000

SLIDER
181
157
353
190
Grass_energy
Grass_energy
10
60
20.0
10
1
NIL
HORIZONTAL

SWITCH
1061
262
1256
295
GetEnergyOnlyFromFood
GetEnergyOnlyFromFood
0
1
-1000

MONITOR
308
235
406
280
Toupeiras Adultas
count toupeiras with [energy > Adult_energy]
17
1
11

BUTTON
110
51
229
84
Inserir Planta_relva
criar_planta-relva 0 0
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
1065
42
1203
87
modo_manual
modo_manual
"Comer" "Plantar"
0

TEXTBOX
1062
94
1212
136
Clique no ecrã para \"comer\" ou \"plantar\" relva.
11
0.0
1

TEXTBOX
1061
191
1211
233
Ative o modo automático para serem adicionadas toupeiras automáticamente
11
0.0
1

TEXTBOX
1063
296
1351
355
As toupeiras perdem energia ao andarem, não ganham energia a cada tick.[ON]\nAs toupeiras não perdem energia ao andarem, ganham energia a cada tick.[OFF]
11
0.0
1

BUTTON
379
19
459
52
Plantar tudo
plantar_tudo
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
300
19
379
52
Comer tudo
comer_tudo
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1039
377
1178
433
Legenda de toupeiras:\nVermelha - Com fome!\nAzul - Bem alimentada.\nPreta - Fertil.
11
0.0
1

MONITOR
171
677
288
722
Toupeiras com fome
count toupeiras with [energy < 50]
17
1
11

PLOT
34
483
316
677
Toupeiras com fome
Ticks
População
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Mortas" 1.0 0 -8630108 true "" "plot contador_starved"
"Vivas" 1.0 0 -2674135 true "" "plot count toupeiras with [energy < 50]"

MONITOR
67
677
171
722
Mortas por fome
contador_starved
17
1
11

TEXTBOX
1109
10
1259
30
EXTRA:
16
0.0
1

SLIDER
1223
151
1395
184
Prob_praga
Prob_praga
0
1
0.15
0.01
1
NIL
HORIZONTAL

BUTTON
84
19
203
52
NIL
Remover_planta-relva
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
160
235
222
280
Procriadas
nascimentos
17
1
11

MONITOR
86
235
160
280
Estrangeiras
inseridas
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
14
Circle -16777216 true true 81 182 108
Circle -16777216 true true 110 127 80
Circle -16777216 true true 110 75 80
Line -1 false 150 100 80 30
Line -1 false 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -1184463 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -1184463 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -1184463 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -1184463 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -1184463 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -2674135 true false 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99
Line -1 false 135 135 105 135
Line -1 false 105 135 105 150
Line -1 false 105 150 120 150
Line -1 false 120 150 120 165
Line -1 false 120 165 105 165
Line -2674135 false 120 135 150 135
Line -1 false 135 135 135 165
Line -1 false 135 165 150 165
Line -1 false 165 135 165 165
Line -1 false 165 135 180 135
Line -1 false 180 135 180 150
Line -1 false 180 150 165 150
Line -1 false 180 150 180 165
Line -1 false 180 165 165 165

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
