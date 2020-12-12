; Notes:
;; Lots of code taken from several models in the model library. The flower shapes are also from there.
;; All code is written with full understanding. No blind re-typing. Exception: car motion

globals [acceleration deceleration hit? falling? action? going-to-be-hit?]

breed [cars car]
breed [flowers flower]
breed [people person]
breed [objects object]

flowers-own [age]
people-own [frame]
cars-own [speed speed-min speed-limit]
objects-own [kind]

patches-own [f-color]


to go
  ca

  reset-ticks

  set hit? false
  set falling? false
  set action? false
  set going-to-be-hit? false

  display-message-0

  cp

  setup-background

  while [not hit?]
  [
    operate-world

    if ticks > 800 and not hit? and not going-to-be-hit?
    [
      if (make-large-object 0) = 0
      [
        set going-to-be-hit? true
      ]
    ]
  ]

  operate-fall

  wait 1

  cd
  ct

  display-message-1

end

to setup-background
  set-default-shape people "person-0"
  set-default-shape flowers "flower-1"
  set-default-shape cars "car"

  ; person as people
  create-people 1
  [
    set size 10
    set heading 270
    setxy 11 0
    set color red + 4.5
  ]


  draw-road

  ; boat as turtle
  cro 1
  [
    set shape "boat"
    set color yellow
    setxy -5 -14
    set heading 270
    set size 8
  ]

  ; cars as cars
  create-cars 6
  [
    set color one-of (list blue (red - 1))
    setxy random-xcor (one-of [3 4])
    set heading 90
    set size 2
    set speed 0.1 + random-float 0.3
    set speed-limit 0.5
    set speed-min 0
    separate-cars
  ]
  set acceleration 0.003
  set deceleration 0.002

  ; stars as turtles
  cro 10
  [
    set shape "star"
    set color yellow
    set xcor random-xcor
    set ycor random-ycor mod 4 + 11
  ]
end

to operate-world

  animate
  tick
  ask person 0
  [
    if xcor <= 0
    [
      follow-me
    ]
  ]
end
to animate
  every 0.06
  [
    ask people
    [
      walk
    ]
    ask person 0
    [ clean-up ]
    ask flowers [age-flowers]
    if random 10 < 1
    [ make-flowers ]
    ; river
    flow
  ]
  every 0.03
  [
    move-boat
  ]
  every 0.01
  [
    move-cars
  ]
  every 1
  [
    if [xcor] of person 0 <= 0
    [
      if random 10 < 2
      [ make-small-object ]

      if random 100 < 50
      [ if 0 = make-large-object 100 [ ] ]
    ]
  ]
end
to operate-fall
  set falling? true
  ask person 0
  [ set frame 0 ]
  while [falling?]
  [
    every 0.1
    [
      ask person 0
      [ fall ]
    ]
    tick
  ]
end

to walk
  if frame > 6
  [ set frame 1 ]

  set shape word "person-" frame

  set frame frame + 1
  fd 0.51

  if ;(any? objects-on patch-at -1 -1) or
  (any? objects-on patch-ahead 3)
  [
    set hit? true
  ]
end

to clean-up
  ask flowers-at 16 0
  [ die ]
  ask objects with [xcor > [xcor] of person 0 + 15.3 and xcor < [xcor] of person 0 + 16.7]
  [ die ]
  ask objects with [xcor > [xcor] of person 0 + 14 and xcor < [xcor] of person 0 + 16.7 and kind = 1]
  [
    die
  ]

end

to make-flowers
  ask person 0
  [
    hatch 1
    [
      ;; age and shape are set automatically
;      set ycor ycor - 5
      set breed flowers
      set xcor xcor + 16
      set color one-of [magenta sky yellow]
      set size 3
    ]
  ]
end

to age-flowers
    set age (age + 1)
    if age >= 16
    [ set age 16 ]
    set shape (word "flower-" age)
end

to draw-road
  ; soil
  ask patches with [pycor <= 0 and pycor >= -2]
  [set pcolor brown - random-float 0.8]

  ; sidewalk
  ask patches with [pycor <= -3 and pycor > -12]
  [set pcolor grey - 0.8 + random-float 0.25]
  ask patches with [pycor = -12]
  [set pcolor grey - 3.7 + random-float 0.25]

  ;  river
  ask patches with [pycor <= -13]
  [set pcolor sky - random-float 0.5]

  ; roads for cars
  ask patches with [pycor <= 5 and pycor >= 1]
  [set pcolor grey - 2.5 + random-float 0.25]

  ask patches with [pxcor = 0 and (pycor = 1 or pycor = 5)]
  [
    sprout 1
    [
      set color yellow
      set heading 90
      pd fd 33
      die
    ]
  ]

  ; sidewalk
  ask patches with [pycor <= 10 and pycor >= 6]
  [set pcolor grey - 0.8 + random-float 0.25]

  ; sky
  ; all black!
end

to flow
  ask patches with [pycor <= -13]
  [ set f-color [pcolor] of patch-at 1 0 ]
  ask patches with [pycor <= -13]
  [ set pcolor f-color ]
end

to move-boat
  ask turtles with [shape = "boat"]
  [
    fd 0.5
    if shade-of? grey [pcolor] of patch-at 0 1
    [ lt 1 ]
    if pycor < -14
    [ rt 1 ]
    ifelse abs (heading - 270) > 5
    [ lt heading - 270 ]
    [ rt (random 3 - 1) / 5 ]
  ]
end


to separate-cars ;; cars (turtle) procedure
  if any? other cars-on neighbors [
    fd 3
    separate-cars
  ]
end

to move-cars
  ;; if there is a car right ahead of you, match its speed then slow down
  ask cars [
    let car-ahead one-of turtles-on patch-ahead 1
    ifelse car-ahead != nobody
      [ slow-down-car car-ahead ]
      [ speed-up-car ] ;; otherwise, speed up
    ;; don't slow down below speed minimum or speed up beyond speed limit
    if speed < speed-min [ set speed speed-min ]
    if speed > speed-limit [ set speed speed-limit ]
    fd speed
  ]
end

to slow-down-car [ car-ahead ] ;; turtle procedure
  ;; slow down so you are driving more slowly than the car ahead of you
  set speed [ speed ] of car-ahead - deceleration
end

to speed-up-car ;; turtle procedure
  set speed speed + acceleration
end

to make-small-object
  ask person 0
  [
    hatch 1
    [
      set breed objects
      fd 14
      set ycor (random-ycor mod 4 + 6)
      set color one-of [magenta sky yellow]
      set shape one-of ["house" "sheep" "tree" "truck" "building institution" "building store" "campsite" "factory" "house bungalow" "house colonial" "house efficiency" "house ranch" "house two story" "logs"]
      set size 2
      set kind 0
    ]
  ]
end

to-report make-large-object [location]
  ask person 0
  [
    hatch 1
    [
      if any? objects-here or any? objects-on neighbors or any? objects with [pxcor = [pxcor] of myself]
      [
        die
        stop
      ]
      set breed objects
      set xcor int (xcor - 14)
      set heading 180
      fd random 5
      if not (location = 100)
      [
        set ycor location
      ]
      set size 10
      set shape one-of ["tree" "tree pine"]
      set color green - random 0.5
      set kind 1
    ]
  ]
  report 0
end

to fall
  if frame > 4
  [
    set falling? false
    stop
  ]

  set frame frame + 1
  set shape word "person-fall-" frame
;
;    set frame 1
;    let str "person-fall-"
;    set shape word str frame
;
;    wait 0.05
;    set frame frame + 1
;    set shape word str 2
;
;    wait 0.05
;    set shape word str 3
;
;    wait 0.05
;    set shape word str 4
;
;    wait 0.05
;    set shape word str 5
;
end

to display-message-0
ask patch 9 6
[
  set plabel "HEADS UP, PHONE ADDICTS!"
]

tick

let sec 5
repeat 5
[
  ask patch 9 -6
  [
    set plabel word "Animation starts in " sec
  ]
  tick
  wait 1
  set sec sec - 1
]

;  set plabel "Starts in 5"
;  wait 1
;  set plabel "Starts in 4"
;  wait 1
;  set plabel "Starts in 3"
;  wait 1
;  set plabel "Starts in 2"
;  wait 1
;  set plabel "Starts in 1"
;  wait 1
end

to display-message-1
  ask patch 9 3
  [
    set plabel "THAT'S WHAT HAPPENS!!!"
  ]

  tick

  wait 2

  ask patch 5 -4
  [
    set plabel "The End"
  ]
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
20
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
41
63
104
96
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

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

boat
true
0
Polygon -1 true false 138 237 93 210 93 77 138 10
Rectangle -6459832 true false 138 143 268 150
Polygon -13345367 true false 266 150 251 169 253 155 252 153 251 151
Polygon -7500403 true true 246 143 221 125 204 126 198 115 188 122 176 106 169 104 161 110 154 108 149 89 146 84 146 143
Polygon -7500403 true true 226 150 209 154 201 161 186 157 177 159 174 163 171 169 161 168 164 158 158 174 153 181 153 152

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
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

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

campsite
false
0
Polygon -7500403 true true 150 11 30 221 270 221
Polygon -16777216 true false 151 90 92 221 212 221
Line -7500403 true 150 30 150 225

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

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
Polygon -10899396 true false 150 300 165 300 165 285 165 270

flower-1
false
0
Polygon -10899396 true false 150 300 165 300 165 285 165 270

flower-10
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Polygon -10899396 true false 165 150 150 150 135 135 135 105 150 105 165 135
Polygon -7500403 true true 135 120 150 135 135 105

flower-11
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Polygon -10899396 true false 150 135 120 120 120 105 135 90 150 90 165 120
Polygon -7500403 true true 150 90 150 120 135 90
Polygon -7500403 true true 120 105 120 120 150 120
Line -7500403 true 150 90 150 120

flower-12
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -10899396 true false 133 105 32
Circle -10899396 true false 152 90 28
Circle -10899396 true false 118 88 32
Circle -10899396 true false 133 73 32
Circle -7500403 true true 125 80 50
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Circle -16777216 true false 147 102 6

flower-13
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -10899396 true false 133 120 32
Circle -10899396 true false 167 90 28
Circle -10899396 true false 103 88 32
Circle -10899396 true false 133 58 32
Circle -7500403 true true 120 75 60
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Circle -16777216 true false 144 99 12

flower-14
false
0
Circle -10899396 true false 103 58 32
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -10899396 true false 103 120 32
Circle -7500403 true true 133 135 32
Circle -7500403 true true 182 90 28
Circle -10899396 true false 167 60 28
Circle -10899396 true false 167 122 28
Circle -7500403 true true 88 88 32
Circle -7500403 true true 133 43 32
Circle -7500403 true true 105 60 90
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Circle -16777216 true false 135 90 30

flower-15
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 90 137 28
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 90 45 28
Circle -7500403 true true 182 45 28
Circle -7500403 true true 182 137 28
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 120 75 60
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

flower-16
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

flower-2
false
0
Polygon -10899396 true false 150 300 180 255 180 270 165 300

flower-3
false
0
Polygon -10899396 true false 150 300 180 240 195 225 195 240 165 300

flower-4
false
0
Polygon -10899396 true false 150 300 180 240 180 210 195 225 195 240 165 300
Polygon -10899396 true false 180 255 165 240 150 240

flower-5
false
0
Polygon -10899396 true false 150 300 180 240 180 210 180 165 195 195 195 240 165 300
Polygon -10899396 true false 180 255 135 225 105 240 135 240

flower-6
false
0
Polygon -10899396 true false 150 300 180 240 180 210 165 165 165 150 195 195 195 240 165 300
Polygon -10899396 true false 180 255 135 210 120 210 90 225 105 240 135 240
Polygon -10899396 true false 185 235 210 210 222 208 210 225

flower-7
false
0
Polygon -10899396 true false 180 255 150 210 105 210 83 241 135 240
Polygon -10899396 true false 150 300 180 240 180 210 165 150 150 135 165 135 195 195 195 240 165 300
Polygon -10899396 true false 189 230 217 200 235 195 255 195 232 210

flower-8
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Polygon -10899396 true false 189 233 219 188 240 180 255 195 228 214
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Polygon -10899396 true false 150 135 135 135 135 120 150 120

flower-9
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Polygon -10899396 true false 189 233 219 188 240 180 270 195 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Polygon -10899396 true false 150 135 135 120 135 105 150 105
Line -7500403 true 135 105 150 120

flower12
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

house bungalow
false
0
Rectangle -7500403 true true 210 75 225 255
Rectangle -7500403 true true 90 135 210 255
Rectangle -16777216 true false 165 195 195 255
Line -16777216 false 210 135 210 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 150 75 150 150 75
Line -16777216 false 75 150 225 150
Line -16777216 false 195 120 225 150
Polygon -16777216 false false 165 195 150 195 180 165 210 195
Rectangle -16777216 true false 135 105 165 135

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

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

logs
false
0
Polygon -7500403 true true 15 241 75 271 89 245 135 271 150 246 195 271 285 121 235 96 255 61 195 31 181 55 135 31 45 181 49 183
Circle -1 true false 132 222 66
Circle -16777216 false false 132 222 66
Circle -1 true false 72 222 66
Circle -1 true false 102 162 66
Circle -7500403 true true 222 72 66
Circle -7500403 true true 192 12 66
Circle -7500403 true true 132 12 66
Circle -16777216 false false 102 162 66
Circle -16777216 false false 72 222 66
Circle -1 true false 12 222 66
Circle -16777216 false false 30 240 30
Circle -1 true false 42 162 66
Circle -16777216 false false 42 162 66
Line -16777216 false 195 30 105 180
Line -16777216 false 255 60 165 210
Circle -16777216 false false 12 222 66
Circle -16777216 false false 90 240 30
Circle -16777216 false false 150 240 30
Circle -16777216 false false 120 180 30
Circle -16777216 false false 60 180 30
Line -16777216 false 195 270 285 120
Line -16777216 false 15 240 45 180
Line -16777216 false 45 180 135 30

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

person student
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

person-0
false
0
Circle -7500403 true true 90 30 120
Circle -16777216 true false 105 45 90
Rectangle -7500403 true true 150 135 165 225
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 150 225 150 240
Line -7500403 true 150 240 150 285
Line -7500403 true 165 165 90 195
Line -7500403 true 165 225 165 285
Line -7500403 true 90 195 75 180
Rectangle -7500403 true true 75 150 90 180
Line -7500403 true 165 165 105 195
Line -7500403 true 105 195 90 180

person-1
false
0
Circle -7500403 true true 90 30 120
Circle -16777216 true false 105 45 90
Rectangle -7500403 true true 150 135 165 225
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 165 225 165 240
Line -7500403 true 165 240 180 285
Line -7500403 true 165 165 90 195
Line -7500403 true 150 225 135 240
Line -7500403 true 90 195 75 180
Rectangle -7500403 true true 75 150 90 180
Line -7500403 true 135 240 120 270
Line -7500403 true 165 165 105 195
Line -7500403 true 105 195 90 180

person-2
false
0
Circle -7500403 true true 90 30 120
Circle -16777216 true false 105 45 90
Rectangle -7500403 true true 150 135 165 225
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 150 225 120 240
Line -7500403 true 120 240 105 285
Line -7500403 true 165 165 90 195
Line -7500403 true 165 225 195 285
Line -7500403 true 90 195 75 180
Rectangle -7500403 true true 75 150 90 180
Line -7500403 true 165 165 105 195
Line -7500403 true 105 195 90 180

person-3
false
0
Circle -7500403 true true 90 30 120
Circle -16777216 true false 105 45 90
Rectangle -7500403 true true 150 135 165 225
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 150 225 135 240
Line -7500403 true 135 240 120 285
Line -7500403 true 165 165 90 195
Line -7500403 true 165 225 180 255
Line -7500403 true 90 195 75 180
Rectangle -7500403 true true 75 150 90 180
Line -7500403 true 180 255 195 270
Line -7500403 true 165 165 105 195
Line -7500403 true 105 195 90 180

person-4
false
0
Circle -7500403 true true 90 30 120
Circle -16777216 true false 105 45 90
Rectangle -7500403 true true 150 135 165 225
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 150 225 150 240
Line -7500403 true 150 240 135 285
Line -7500403 true 165 165 90 195
Line -7500403 true 165 225 165 255
Line -7500403 true 90 195 75 180
Rectangle -7500403 true true 75 150 90 180
Line -7500403 true 165 255 180 270
Line -7500403 true 165 165 105 195
Line -7500403 true 105 195 90 180

person-5
false
0
Circle -7500403 true true 90 30 120
Circle -16777216 true false 105 45 90
Rectangle -7500403 true true 150 135 165 225
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 165 225 150 240
Line -7500403 true 150 240 165 270
Line -7500403 true 165 165 90 195
Line -7500403 true 150 225 150 255
Line -7500403 true 90 195 75 180
Rectangle -7500403 true true 75 150 90 180
Line -7500403 true 150 255 150 285
Line -7500403 true 165 165 105 195
Line -7500403 true 105 195 90 180

person-6
false
0
Circle -7500403 true true 90 30 120
Circle -16777216 true false 105 45 90
Rectangle -7500403 true true 150 135 165 225
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 165 225 135 255
Line -7500403 true 135 255 150 270
Line -7500403 true 165 165 90 195
Line -7500403 true 150 225 150 255
Line -7500403 true 90 195 75 180
Rectangle -7500403 true true 75 150 90 180
Line -7500403 true 150 255 165 285
Line -7500403 true 165 165 105 195
Line -7500403 true 105 195 90 180

person-fall-1
false
0
Circle -7500403 true true 120 30 120
Circle -16777216 true false 135 45 90
Rectangle -7500403 true true 150 135 165 225
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 150 225 150 240
Line -7500403 true 150 240 150 285
Line -7500403 true 165 165 90 195
Line -7500403 true 165 225 165 285
Line -7500403 true 90 195 75 180
Rectangle -7500403 true true 60 150 75 180
Line -7500403 true 165 165 105 195
Line -7500403 true 105 195 90 180

person-fall-2
false
0
Circle -7500403 true true 165 75 120
Circle -16777216 true false 180 90 90
Rectangle -7500403 true true 135 150 150 240
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 135 240 120 255
Line -7500403 true 120 255 150 285
Line -7500403 true 135 180 60 210
Line -7500403 true 150 225 165 285
Line -7500403 true 60 210 45 195
Rectangle -7500403 true true 45 165 60 195
Line -7500403 true 150 180 90 210
Line -7500403 true 90 210 75 195

person-fall-3
false
0
Circle -7500403 true true 165 120 120
Circle -16777216 true false 180 135 90
Rectangle -7500403 true true 120 180 135 270
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 105 255 90 270
Line -7500403 true 90 270 150 285
Line -7500403 true 135 210 60 240
Line -7500403 true 135 240 165 285
Line -7500403 true 60 240 45 225
Rectangle -7500403 true true 45 195 60 225
Line -7500403 true 135 210 75 240
Line -7500403 true 75 240 60 225

person-fall-4
false
0
Circle -7500403 true true 165 165 120
Circle -16777216 true false 180 180 90
Rectangle -7500403 true true 135 195 150 285
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 105 270 90 285
Line -7500403 true 90 285 150 285
Line -7500403 true 135 255 60 285
Line -7500403 true 135 240 165 285
Line -7500403 true 60 285 45 270
Rectangle -7500403 true true 45 240 60 270
Line -7500403 true 135 255 75 285
Line -7500403 true 75 285 60 270

person-fall-5
false
0
Circle -7500403 true true 165 165 120
Circle -16777216 true false 180 180 90
Rectangle -7500403 true true 165 225 165 225
Line -7500403 true 105 285 90 285
Line -7500403 true 90 285 150 285
Line -7500403 true 135 285 60 285
Line -7500403 true 120 285 165 285
Line -7500403 true 60 285 30 285
Line -7500403 true 165 285 90 270
Line -7500403 true 75 285 90 270
Polygon -7500403 true true 30 285 15 270 30 270 45 285 60 270 60 285
Polygon -7500403 true true 135 285 150 210 165 210 150 285 135 285

person-head
true
0
Circle -7500403 true true 90 30 120
Circle -16777216 true false 105 45 90

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

tree pine
false
0
Rectangle -6459832 true false 120 225 180 300
Polygon -7500403 true true 150 240 240 270 150 135 60 270
Polygon -7500403 true true 150 75 75 210 150 195 225 210
Polygon -7500403 true true 150 7 90 157 150 142 210 157 150 7

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
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

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
NetLogo 6.0.4
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
