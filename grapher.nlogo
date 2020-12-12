; global variables declared with sliders:
; number-of-labels label-length
; x-max y-max
; graphing-speed

; declared with inputs:
; y=
; eqaution#

; declared with swiches:
; show-coordinates?
; show-closest-equation?

;TODOs:
  ; code cleanup, organize more into MVC, perhaps?
  ; implement mouse-down pt report
  ; Change line color for new graph

;DONE:
  ; Align open brackets and close brackets
  ; Display error message in Output and BEEP


; model

globals
[
  ; for clear-graph
  cur-num-labels
  cur-label-length
  cur-x-max
  cur-y-max

  ; for internal grid system
  x-factor
  y-factor

  ; keep track of graphed equations
  equations

]

; reset all parameters
to reset-all
  set number-of-labels 15
  set label-length 0.3
  set x-max max-pxcor
  set y-max max-pycor
  set graphing-speed 100
  set y= ""
  set coordinate-precision 2
  ; equations reset in setup

  ; initialize model again
  setup
end

; modify user input for graphing
to-report modify [str]
  let reporter-str (word "[ x -> " str " ]")
  print reporter-str
  report (runresult reporter-str)
end

; set the internal grid system and update the view
to set-grid [new-x-max new-y-max]

  ; set internal grid system
  set x-factor (new-x-max / max-pxcor)
  set y-factor (new-y-max / max-pycor)

  label-bounds new-x-max new-y-max

  set cur-x-max new-x-max
  set cur-y-max new-y-max
end

to-report equations.exist? [ y ]
  report member? y equations
end

; add equation to "equations"
to equations.add [ y ]
  set equations lput y equations
end

; remove equation from "equations"
to equations.remove [ y ]
  ifelse is-number? y
  [
    set equations remove-item (y - 1) equations
  ]
  [
    set equations remove y equations
  ]
end

; remove all equations from "equations"
to equations.remove-all
  set equations []
end

; graph all equations in "equations", WITHOUT doing anything else
to equations.graph-all
  if equations = 0 or empty? equations [ stop ]
  let functions (map modify equations)
  foreach functions graph-function
end

;
to-report get-closest-graph [x y]
  let functions map modify equations
  let results map [func -> (runresult func x)] functions
  let distances map [val -> (abs val) - y] results
  report position (min distances) distances
end


; controllers - what buttons should access ONLY

to separate-comments end

; setup the axes, enable other options, initialize "equations" to empty list
to setup
  ca
  set equations []
  update-axes
  set-grid x-max y-max
  output.setup
  set equation# 0

  set show-coordinates? true
  set show-closest-graph? false
  reset-ticks
end

; graph equation in "y="
; calls: equations.exist?, equations.add, graph-function, modify, output.print-last
to add-graph
  if y= = "" [ stop ]
  if equations.exist? y= [ stop ]

  ; catch user error or division by 0
  carefully
  [
    let function (modify y=)
    graph-function function
    equations.add y=
    output.setup
    output.print-equations
    set equation# length equations
  ]
  ; catch error
  [
    output.setup
    output.print-equations
    ; user-message (word "The graph of y = " y= " is not added. The following error has occurred: " error-message " Check equation input to make sure all syntax is correct.")
    output.print-message "Graphing stopped because of error:"
    output.print-message word " - " error-message
    output.print-message "Check the equation input to make sure all \nsyntax are correct."
    beep
  ]
end

; clear all graphs and update internal grid
; calls: set-grid [], setup-guides [], equations.graph-all
to update-window
  cd
  set-grid x-max y-max
  setup-guides cur-num-labels cur-label-length
  equations.graph-all
end

; clear the window, setup the view of axes
; calls: clear-window, setup-guides []
to update-axes
  cd
  setup-guides number-of-labels label-length
  equations.graph-all
end

; clear all graphs: clear all drawings and redraw the axes and labels
; calls: clear-view, setup-guides []
to clear-window
  clear-view
  setup-guides cur-num-labels cur-label-length
end

; reset-axes-labels
; calls: clear-view, setup-guides []
to reset-axes
  set number-of-labels 15
  set label-length 0.3
  clear-view
  setup-guides number-of-labels label-length
end

; remove the equation that "equation#" is pointing to
; calls: remove-function
to remove-equation
  remove-function equation#
end

; (forever button needed) show the coordinates/closest graph of current mouse position
to show-coordinates
  ifelse mouse-down? and mouse-inside?
  [
    ifelse count turtles with [ shape = "x" ] = 1
    [
      ask turtles with [ shape = "x" ]
      [
        setxy mouse-xcor mouse-ycor
        ifelse show-coordinates? and show-closest-graph?
        [
          view-coordinates 2
        ]
        [
          ifelse show-coordinates?
          [
            view-coordinates 0
          ]
          [
            ifelse show-closest-graph?
            [
              view-coordinates 1
            ]
            [
              view-coordinates 3
            ]
          ]
        ]
      ]
    ]
    [
      ask turtles with [shape = "x"]
      [
        die
      ]
      cro 1
      [
        set shape "x"
        set size 0.5
        set color red
      ]
    ]
  ]
  [
    ask turtles with [ shape = "x" ]
    [
      die
    ]
  ]
end


; graph the given equation: function (as anonymous reporter)
to graph-function [ func ]

  ; create the graphing agent
  cro 1
  [
    set hidden? true
    set color pink
    set shape "dot"
    set size 0.3
  ]

  ; initialize x y
  let x (-1 * cur-x-max)
  let y (runresult func x)

  ask turtles with [shape = "dot"]
  [

    ; var to keep track of whether just graphed (because of boundary issues)
    ; make sure turtle produce the correct graph when the last point is out of bound
    let graphed false

    ; graph from left to right
    while [x < cur-x-max]
    [

      ; plot if y is not outside of boundary
      ifelse (abs y) <= cur-y-max
      [
        ifelse graphed
        [
          pd
          setxy x / x-factor y / y-factor
          stamp
          pu
        ]
        [
          ; makes sure to not connect the last point if it was outside of boundary
          setxy x / x-factor y / y-factor
          stamp
          set graphed true
        ]
      ]
      [
        set graphed false
      ]

      ; update x y
      set x (x + 0.01)
      set y (runresult func x)

      ; graphing speed
      if graphing-speed != 100
      [
        wait 0.01 / (graphing-speed)
      ]
    ]

    die
  ]
  tick
end

; remove a function: index
to remove-function [ index ]
  if index > length equations [ stop ]
  if index = 0 [ stop ]
  equations.remove index
  output.setup
  output.print-equations
  set equation# length equations
  update-window
  equations.graph-all
end


; view

; clear all drawings and agents
; calls: output.seup, equations.remove-all
to clear-view
  cd
  ask turtles [die]
  output.setup
  equations.remove-all
end

; draw labels (marks on axes): number of labels, length of each label
; calls: draw-axes, label-axes[num-label len]
to setup-guides [num-label len]
  cro 1
  [
    set hidden? true
    set color 4
  ]

  draw-axes
  label-axes num-label len

  ; retain latest setting - to be used by clear-window
  set cur-num-labels num-label
  set cur-label-length len

  ask turtles
  [
    die
  ]
end

  ; draw four plane axes with arrows on each end
  to draw-axes ; turtles needed
    ask turtles
  [
      set pen-size 2
      setxy 0 0 pd
      set ycor max-pycor pu
      stamp

      setxy 0 0 pd
      set xcor max-pxcor pu
      rt 90
      stamp

      setxy 0 0 pd
      set ycor min-pycor pu
      rt 90
      stamp

      setxy 0 0 pd
      set xcor min-pxcor pu
      rt 90
      stamp
  ]
  end

  ; draw marks on the axes and label "x" "y": number of labels on each axis, length of each label
  to label-axes [num len] ; turtles needed
  ask patch (max-pxcor - 1) 1
  [
    set plabel "x"
  ]
  ask patch 1 (max-pycor)
  [
    set plabel "y"
  ]

  ask turtles
  [
    set pen-size 1
    setxy 0 0
    let interval (max-pxcor / (num + 1))
    let one-side [ -> repeat num [fd interval lt 90 fd len pd bk (len * 2) pu fd len rt 90]]
    repeat 4
    [
      setxy 0 0
      rt 90
      run one-side
    ]
  ]
end

; label xy max and min: x, y
to label-bounds [x y]

  ask patch (max-pxcor - 1) -1
  [
    set plabel word "max: " x
  ]
  ask patch (min-pxcor + 4) -1
  [
    set plabel word "min: -" x
  ]
  ask patch -1 (max-pycor)
  [
    set plabel word "max: " y
  ]
  ask patch -1 (min-pycor + 1)
  [
    set plabel word "min: -" y
  ]

end

; setup output area
to output.setup
  clear-output
  output-print "Graphed Equations:"
end

; format and print all equations in "equations" to output area
to output.print-equations
  if empty? equations [ stop ]
  let output-list (map [equation -> (word ((position equation equations) + 1) ": y = " equation "\n") ] equations)
  let output-str (reduce [ [ prev next ] -> word prev next ] output-list)
  output-type output-str
end

; print the last graphed equation to output area
to output.print-last
  let equation last equations
  output-type (word (length equations) ": y = " equation "\n")
end

; a wrapper for "output-print"
to output.print-message [msg]
  output-print msg
end

to view-coordinates [ opt ] ; turtle with shape "x" needed
  ; clear
  if opt = 0
  [
    set label (word "(" precision (mouse-xcor * x-factor) coordinate-precision ", " precision (mouse-ycor * y-factor) coordinate-precision ")")
  ]

  ; graph only
  if opt = 1
  [
    set label (
    (word "closest graph: " get-closest-graph mouse-xcor mouse-ycor)
    )
  ]

  ; coordinate and graph
  if opt = 2
  [

  ]

  ; clear
  if opt = 3
  [
    set label ""
  ]
end

@#$#@#$#@
GRAPHICS-WINDOW
31
10
522
502
-1
-1
11.8
1
11
1
1
1
0
0
0
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
571
534
653
567
update axes
update-axes
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
574
294
948
327
x-max
x-max
0.1
100
3.7
0.1
1
NIL
HORIZONTAL

SLIDER
574
332
950
365
y-max
y-max
0.1
100
5.3
0.1
1
NIL
HORIZONTAL

SLIDER
572
450
744
483
number-of-labels
number-of-labels
1
40
15.0
1
1
NIL
HORIZONTAL

SLIDER
572
491
744
524
label-length
label-length
0
max-pxcor
0.3
0.1
1
NIL
HORIZONTAL

BUTTON
655
41
740
74
reset all
reset-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
574
113
953
173
y=
tan (360 * 1 / x)
1
0
String (reporter)

BUTTON
574
219
704
252
add graph
add-graph
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
1027
424
1120
457
clear all graphs
clear-window
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
719
221
882
254
clear window and graph
clear-window\nadd-graph
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
574
371
676
404
update window
update-window
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
577
425
727
443
Axes settings:
12
0.0
1

TEXTBOX
578
91
728
109
Graphing
12
0.0
1

TEXTBOX
575
267
725
285
Window
12
0.0
1

SLIDER
574
180
746
213
graphing-speed
graphing-speed
1
100
100.0
1
1
NIL
HORIZONTAL

TEXTBOX
575
14
725
32
Model Control
12
0.0
1

BUTTON
574
40
647
73
NIL
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
655
534
745
567
reset axes
reset-axes
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

OUTPUT
995
37
1316
346
11

BUTTON
1027
378
1179
411
remove equation of #
remove-equation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
1196
352
1270
412
equation#
1.0
1
0
Number

TEXTBOX
774
377
924
405
Show coordinates of cursor\n(On mousedown)
11
0.0
1

SWITCH
772
447
946
480
show-closest-graph?
show-closest-graph?
1
1
-1000

SWITCH
772
410
946
443
show-coordinates?
show-coordinates?
0
1
-1000

BUTTON
776
535
939
568
show
show-coordinates
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
772
496
969
529
coordinate-precision
coordinate-precision
0
10
2.0
1
1
dec. places
HORIZONTAL

@#$#@#$#@
## THIS IS A PART OF THE LARGER PROJECT. IT IS ***INCOMPLETE***

## THIS FIELD IS FOR HOMEWORK PURPOSES ONLY
1. reporter that accepts parameters
	1.1 used for reporter `label-axes`
2. `run` command combined with *anonymous command*
	2.1 used for drawing the intervals on the axes
	2.2 does it suggest the possibility of a custom function input by user to graph?


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
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

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
