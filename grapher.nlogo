;;
;; global variables declared with sliders:
;;  coordinate-precision
;;  a b c
;;
;; declared with inputs:
;;  =0
;;  eqaution#
;;  zoom-factor
;;  graph-color axes-color background-color
;;  a,b,c-min,increment,max

;; declared with swiches:
;;  show-axes?

;; TODOs:
  ; Change line color for new graph
;;  Make "detect change" functional
;;  Optimize move-window, and possibly, zooming


;;
;; model
;;

globals
[
  ; track whether model is initialized (useful for stopping forever buttons on "ca")
  init?

  ; for clear-graph
  cur-num-labels
  cur-label-length

  ; keep track of graphed equations
  equations


  slider-max1 slider-min1

  ;; grid system
  wx-max wx-min wy-max wy-min
  ;; default window size
  DEFAULT-X DEFAULT-Y

  ;; moving window
  was-mouse-down?
  init-pt final-pt

  ;; showing coordinate
  coordinate
  showing-coordinate?

  ;; for changing window color
  old-background-color
  old-graph-color
  old-axes-color

  ;; for constant sliders
  f-a-min f-a-increment f-a-max
  f-b-min f-b-increment f-b-max
  f-c-min f-c-increment f-c-max

  ;; for detecting change; "o" stands for "old"
  old-a old-b old-c
]

patches-own
[
  ;; for window size
  wxcor wycor
  ;; for graphing
  wzcor on-graph?

  ;; for labeling
  is-label?

  ;; for moveing window
  f-wxcor f-wycor f-pcolor was-in-window?
]

breed [points point]

; reset all parameters
to reset-all
  set =0 ""
  set show-axes? true
  set coordinate-precision 2
  set zoom-factor 2
  set axes-color 3
  set graph-color pink
  set background-color black
  ; equations reset in setup

  ;; set constant sliders
  set a-min -50 set a-increment 1 set a-max 50 set a 0
  set b-min -50 set b-increment 1 set b-max 50 set b 0
  set c-min -50 set c-increment 1 set c-max 50 set c 0

  ; initialize model again
  setup
end

; modify user input for graphing
to-report modify [str]
  if position "x" str = false
  and position "y" str = false
  [
    error "Include at least 1 variable in equation (x or y)  "
  ]
  let reporter-str (word "[ [x y] -> " str " ]")
  report (runresult reporter-str)
end

;; set the internal grid system
;; does NOT update the view
to set-grid [new-x-max new-x-min new-y-max new-y-min]

  let x-diff abs (new-x-max - new-x-min)
  let y-diff abs (new-y-max - new-y-min)

  let x-factor (x-diff / (max-pxcor * 2))
  let y-factor (y-diff / (max-pycor * 2))

  label-bounds new-x-max new-x-min new-y-max new-y-min

  ask patches
  [
    set wxcor (pxcor + max-pxcor) * x-factor + new-x-min
    set wycor (pycor + max-pycor) * y-factor + new-y-min
  ]

  set wx-max new-x-max
  set wx-min new-x-min
  set wy-max new-y-max
  set wy-min new-y-min
end

;; set the internal grid system, only with selected patches (pixels)
;; does NOT update the view
to set-grid-with [pixels new-x-max new-x-min new-y-max new-y-min]

  let x-diff abs (new-x-max - new-x-min)
  let y-diff abs (new-y-max - new-y-min)

  let x-factor (x-diff / (max-pxcor * 2))
  let y-factor (y-diff / (max-pycor * 2))

  label-bounds new-x-max new-x-min new-y-max new-y-min

  ask pixels
  [
    set wxcor (pxcor + max-pxcor) * x-factor + new-x-min
    set wycor (pycor + max-pycor) * y-factor + new-y-min
  ]

  set wx-max new-x-max
  set wx-min new-x-min
  set wy-max new-y-max
  set wy-min new-y-min
end

to-report equations.exist? [ y ]
  report member? y equations
end

; add equation to "equations"
to equations.add [ equation ]
  set equations lput equation equations
end

; remove equation from "equations"
to equations.remove [ index ]
  set equations remove-item (index - 1) equations
end

; remove all equations from "equations"
to equations.remove-all
  set equations []
end

; graph all equations in "equations", WITHOUT doing anything else
to equations.graph-all
  if equations = 0 or empty? equations [ stop ]
  let implicit-equations (map modify equations)
  foreach implicit-equations graph-implicit
  tick
end

to equations.carefully.graph-all
  carefully
  [
    if equations = 0 or empty? equations [ stop ]
    let implicit-equations (map modify equations)
    foreach implicit-equations graph-implicit
  ]
  [
    output.setup
    output.print-equations
    ; user-message (word "The graph of y = " =0 " is not added. The following error has occurred: " error-message " Check equation input to make sure all syntax is correct.")
    output.print-message "-----------------------------------------\nGraphing stopped because of error:"
    output.print-message word " - " error-message
    output.print-message "Check the equation input to make sure all \nsyntax are correct."
    beep
  ]
end
;;
;; controllers - what buttons should access ONLY
;;

to separate-comments end

; setup the axes, enable other options, initialize "equations" to empty list
to setup
  ca
  reset-ticks

  set init? 1

  set equations []
  set DEFAULT-X 10
  set DEFAULT-Y 10
  set equation# 0
  set was-mouse-down? false
  set showing-coordinate? false
  set coordinate nobody
  set-default-shape points "dot"
  set old-graph-color graph-color
  set old-axes-color axes-color
  set old-background-color background-color
  update-constant-sliders

  ;; set internal grid-system
  zoom "reset" 0

  clear-view
  update-window-colors


  set old-a a
  set old-b b
  set old-c c
end

; graph equation in "=0"
; calls: equations.exist?, equations.add, graph-implicit, modify, output.print-last
to add-graph
  if =0 = "" [ stop ]
  if equations.exist? =0 [ stop ]

  ; catch user error or other predefined workarounds (division by 0, sqrt of a negative, etc)
  carefully
  [
    let implicit-equation (modify =0)
    graph-implicit implicit-equation
    equations.add =0
    output.setup
    output.print-equations
    set equation# length equations
    tick
  ]
  ; catch error
  [
    output.setup
    output.print-equations
    ; user-message (word "The graph of y = " =0 " is not added. The following error has occurred: " error-message " Check equation input to make sure all syntax is correct.")
    output.print-message "-----------------------------------------\nGraphing stopped because of error:"
    output.print-message word " - " error-message
    output.print-message "Check the equation input to make sure all \nsyntax are correct."
    beep
  ]
end

; clear all graphs and update internal grid
; calls: set-grid [], setup-guides [], equations.graph-all

; clear all graphs: clear all patch colors and redraw the axes
; calls: draw-axes
to clear-window
  ask patches
  [ set pcolor background-color]
  draw-axes
end

; clear window and graph
to clear-window-graph
  clear-view
  add-graph
end

to clear-all-graphs
  clear-view
  set equation# 0
end

to update-window-colors
  if graph-color = background-color
  or background-color = axes-color
  or axes-color = graph-color
  [
    user-message "Please select different colors"
    clear-ticks
    stop
  ]
  ask patches
  [
    if pcolor = old-graph-color
    [
      set pcolor graph-color
    ]
    if pcolor = old-background-color
    [
      set pcolor background-color
    ]
    if pcolor = old-axes-color
    [
      set pcolor axes-color
    ]
  ]
  set old-graph-color graph-color
  set old-axes-color axes-color
  set old-background-color background-color
end

to update-constant-sliders
  set f-a-min a-min set f-a-increment a-increment set f-a-max a-max
  set f-b-min b-min set f-b-increment b-increment set f-b-max b-max
  set f-c-min c-min set f-c-increment c-increment set f-c-max c-max
end

to detect-change
  if init? = 0 [ stop ]
  every 0.5
  [
    if a != old-a or b != old-b or c != old-c
    [
      clear-window
      equations.carefully.graph-all
      tick
      output.setup
      output.print-equations
      set old-a a
      set old-b b
      set old-c c
    ]
  ]
end

to update-window-with-constants
  if a != old-a or b != old-b or c != old-c
  [
    clear-window
    equations.carefully.graph-all
    tick
    output.setup
    output.print-equations
    set old-a a
    set old-b b
    set old-c c
  ]
end

; remove the equation that "equation#" is pointing to
; calls: remove-equation
to button.remove-equation
  remove-equation equation#
  clear-window
  equations.graph-all
end

to zoom-in
  zoom "in" zoom-factor
end

to zoom-out
  zoom "out" zoom-factor
end

to zoom-center
  zoom "center" zoom-factor
end

to zoom-reset
  zoom "reset" zoom-factor
end

;; move window based on user interaction
to move-window
  if init? = 0 ; has not setup yet; this can happen if `ca` is used while the botton is pressed
  [
    stop
  ]
  if mouse-inside?
  [
    let is-mouse-down? mouse-down?
    if is-mouse-down? and not was-mouse-down?
    [
      ;; on mouse-down, initialize
      create-points 1
      [
        setxy mouse-xcor mouse-ycor
        set size 10
        set color green
        set init-pt self
        set label (word "(" precision wxcor coordinate-precision "," precision wycor coordinate-precision ")")
      ]
      create-points 1
      [
        setxy mouse-xcor mouse-ycor
        set size 10
        set color red
        set final-pt self
        create-link-from init-pt
      ]

    ]
    if is-mouse-down? and was-mouse-down?
    [
      ;; on drag, make final-pt follow mouse
      ask final-pt
      [
        setxy mouse-xcor mouse-ycor
        ifelse not showing-coordinate?
        [
          set label (word "(" precision wxcor coordinate-precision "," precision wycor coordinate-precision ")")
        ]
        [
          set label ""
        ]
      ]
    ]
    if not is-mouse-down? and was-mouse-down?
    [
      ;; on release, move window according to the patches
      if init-pt != final-pt
      [
        move (patch [xcor] of init-pt [ycor] of init-pt) (patch [xcor] of final-pt [ycor] of final-pt)
      ]
      ask (turtle-set init-pt final-pt)
      [ die ]
    ]
    set was-mouse-down? is-mouse-down?
    tick
  ]
end

;; (forever button needed) show the coordinates/closest graph of current mouse position
to show-coordinates
  if init? = 0 ; fix error on `ca` when pressed
  [
    stop
  ]
  ifelse mouse-down?
  [
    set showing-coordinate? true
    ifelse coordinate != nobody
    [
      ask coordinate
      [
        setxy mouse-xcor mouse-ycor
        set label (word "(" precision wxcor coordinate-precision "," precision wycor coordinate-precision ")")
      ]
      tick
    ]
    [
      cro 1 [
        set shape "x"
        set coordinate self
      ]
    ]
  ]
  [
    set showing-coordinate? false
    if coordinate != nobody
    [
      ask coordinate
      [
        set label ""
        die
      ]
    ]
  ]

  tick
end

; graph the given equation: equation (as anonymous reporter)
to graph-implicit [ equation ]
  ;; reset patches state
  ask patches
  [
    set on-graph? false
  ]

  ;; compute and store height to the surface
  ask patches
  [
    carefully
  [
      set wzcor (runresult equation wxcor wycor)
    ]
    [
      ;; catch any error by Netlogo's system
      if position "imaginary number" error-message != false
      or error-message = "Division by zero."
      or error-message = "math operation produced a non-number"
      or position "Can't take logarithm of " error-message != false
      [
        set wzcor false
      ]
      ;; the else condition, bubble up the user error
      if wzcor != false
      [
        error error-message
      ]
    ]
  ]

  ;; graph all valid patches
  ask patches with [wzcor != false]
  [
    ifelse wzcor = 0
    [ set on-graph? true]
    [
      if wzcor > 0
      [
        if any? neighbors with [ wzcor != false and wzcor < 0 ]
        [ set on-graph? true ]
      ]
    ]
  ]

  ask patches with [on-graph?]
  [ set pcolor graph-color ]

end

;; compute graph on certain patches, not
;; param: equation
;; param: pixels, the patches to graph
to graph-implicit-with [ equation pixels ]
    ;; reset patches state
  ask pixels
  [
    set on-graph? false
    set wzcor false
  ]

  ;; compute and store height to the surface, only for given patches
  ask pixels
  [
    carefully
  [
      set wzcor (runresult equation wxcor wycor)
    ]
    [
      ;; catch any error by Netlogo's system
      if position "imaginary number" error-message != false
      or error-message = "Division by zero."
      or error-message = "math operation produced a non-number"
      or position "Can't take logarithm of " error-message != false
      [
        set wzcor false
      ]
      ;; the else condition, bubble up the user error
      if wzcor != false
      [
        error error-message
      ]
    ]
  ]

  ;; graph all valid patches
  ask pixels with [wzcor != false]
  [
    ifelse wzcor = 0
    [ set on-graph? true]
    [
      if wzcor > 0
      [
        if any? neighbors with [ wzcor != false and wzcor < 0 ]
        [ set on-graph? true ]
      ]
    ]
  ]

  ask pixels with [on-graph?]
  [ set pcolor pink ]
end

; remove an equation: index
to remove-equation [ index ]
  if index > length equations or index = 0
  [ stop ]
  equations.remove index
  output.setup
  output.print-equations
  set equation# length equations
;  update-window
  equations.graph-all
end

;;
;; view
;;

;; clear all graphes, axes
;; calls: output.setup, equations.remove-all
to clear-view
  ; this will reset patch colors
  ; don't use "cp", since it would reset the wxcor wycor values
  ask patches
  [ set pcolor background-color ]
  draw-axes
  tick
  output.setup
  equations.remove-all
end

; label xy max and min: x, y
to label-bounds [x-max x-min y-max y-min]
  ask patches with [is-label? = true]
  [
    set plabel ""
    set is-label? false
  ]

  ;; x-max
  ask patch (max-pxcor - 1) -1
  [
    set plabel word "x max: " x-max
    set is-label? true
  ]

  let x-min-label word "x min: " x-min
  ;; x-min
  ask patch (min-pxcor + (length x-min-label) * 5) -1
  [
    set plabel x-min-label
    set is-label? true
  ]

  ;; y-max
  ask patch -1 (max-pycor - 10)
  [
    set plabel word "y max: " y-max
    set is-label? true
  ]

  ;; y-min
  ask patch -1 (min-pycor + 10)
  [
    set plabel word "y min: " y-min
    set is-label? true
  ]

end

to draw-axes
  if not show-axes?
  [ stop ]
  if wx-max >= 0 and wx-min <= 0
  [
    ask patches with-min [abs wxcor]
    [ set pcolor axes-color ]
  ]
  if wy-max >= 0 and wy-min <= 0
  [
    ask patches with-min [abs wycor]
    [ set pcolor axes-color ]
  ]

end

;; internal: zoom to a particular place or type
to zoom [zoom-type factor]
  ;; if reset, then don't care about factor
  if zoom-type = "reset"
  [
    set-grid DEFAULT-X (- DEFAULT-X) DEFAULT-Y (- DEFAULT-Y)
    clear-window
    equations.graph-all
    stop
  ]
  if factor <= 0
  [
    user-message "Please put in a positive scale factor"
    stop
  ]
  ;; mouse inside, mouse as center
  ifelse mouse-inside?
  [
    let mouse-patch patch mouse-xcor mouse-ycor
    let px ([wxcor] of mouse-patch)
    let py ([wycor] of mouse-patch)
    if zoom-type = "in"
    [
      set-grid (wx-max - px) / factor + px
      (wx-min - px) / factor + px
      (wy-max - py) / factor + py
      (wy-min - py) / factor + py
    ]
    if zoom-type = "out"
    [
      set-grid (wx-max - px) * factor + px
      (wx-min - px) * factor + px
      (wy-max - py) * factor + py
      (wy-min - py) * factor + py
    ]
    if zoom-type = "center"
    [
      move (patch mouse-xcor mouse-ycor) (patch 0 0)
    ]
  ]
  [
    if zoom-type = "in"
    [
      set-grid wx-max / factor
      wx-min / factor
      wy-max / factor
      wy-min / factor
    ]
    if zoom-type = "out"
    [
      set-grid wx-max * factor
      wx-min * factor
      wy-max * factor
      wy-min * factor
    ]
  ]

  ;; update window
  clear-window
  equations.graph-all
end

;; internal: move window based on initial patch and end patch
;; use the optimized graph procedure
to move [m-from m-to]
  ;; store the distance of patches to look at
  let move-px ([pxcor] of m-from - [pxcor] of m-to)
  let move-py ([pycor] of m-from - [pycor] of m-to)

  let move-wx ([wxcor] of m-from - [wxcor] of m-to)
  let move-wy ([wycor] of m-from - [wycor] of m-to)

;; attempt optimization
;; look at the future patch
;  ask patches
;  [
;    let f-patch (patch-at move-px move-py)
;    ifelse f-patch != nobody
;    [
;      set f-pcolor [pcolor] of f-patch
;      set f-wxcor [wxcor] of f-patch
;      set f-wycor [wycor] of f-patch
;      set was-in-window? true
;    ]
;    [
;      set was-in-window? false
;    ]
;  ]
;
;  ask patches
;  [
;    ifelse was-in-window?
;    [
;      set pcolor f-pcolor
;      set wxcor f-wxcor
;      set wycor f-wycor
;    ]
;    [
;      set pcolor black
;    ]
;  ]
;  set-grid-with (patches with [not was-in-window?])
;    wx-max + move-px
;    wx-min + move-px
;    wy-max + move-py
;    wy-min + move-py
;
;  foreach equations
;  [
;    equation ->
;    graph-implicit-with equation (patches with [not was-in-window?])
;    print "graphing"
;  ]

  set-grid
  wx-max + move-wx
  wx-min + move-wx
  wy-max + move-wy
  wy-min + move-wy

  clear-window
  equations.graph-all

  tick
end

; setup output area
to output.setup
  clear-output
  output-print "Graphed Equations:"
end

; format and print all equations in "equations" to output area
to output.print-equations
  if empty? equations [ stop ]
  let output-list (map [equation -> (word ((position equation equations) + 1) ": 0 = " equation "\n") ] equations)
  let output-str (reduce [ [ prev next ] -> word prev next ] output-list)
  output-type output-str
end

; print the last graphed equation to output area
to output.print-last
  let equation last equations
  output-type (word (length equations) ": 0 = " equation "\n")
end

; a wrapper for "output-print"
to output.print-message [msg]
  output-print msg
end
@#$#@#$#@
GRAPHICS-WINDOW
17
10
566
560
-1
-1
1.0
1
11
1
1
1
0
0
0
1
-270
270
-270
270
1
1
1
ticks
30.0

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
1

INPUTBOX
574
113
1082
173
=0
sin(100 * x) - cos(100 * y)
1
0
String (reporter)

BUTTON
574
182
704
215
add graph
add-graph
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
0

BUTTON
1088
360
1181
393
clear all graphs
clear-all-graphs
NIL
1
T
OBSERVER
NIL
E
NIL
NIL
0

BUTTON
705
182
835
215
clear window and graph
clear-window-graph
NIL
1
T
OBSERVER
NIL
G
NIL
NIL
0

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
577
227
727
245
Window
12
0.0
1

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

OUTPUT
1085
10
1406
319
11

BUTTON
1087
323
1239
356
remove equation of #
button.remove-equation
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
1257
322
1331
382
equation#
1.0
1
0
Number

TEXTBOX
779
10
929
38
Show coordinates of cursor\n(When mouse presses down)
11
0.0
1

BUTTON
775
75
938
108
show mouse coordinate
show-coordinates
T
1
T
OBSERVER
NIL
S
NIL
NIL
0

SLIDER
776
39
973
72
coordinate-precision
coordinate-precision
0
10
2.0
1
1
dec. places
HORIZONTAL

INPUTBOX
576
315
657
375
zoom-factor
2.0
1
0
Number

BUTTON
577
251
658
284
zoom in
zoom-in
NIL
1
T
OBSERVER
NIL
I
NIL
NIL
0

BUTTON
577
283
658
316
zoom out
zoom-out
NIL
1
T
OBSERVER
NIL
O
NIL
NIL
0

BUTTON
657
314
750
347
reset window
zoom-reset
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
0

BUTTON
658
251
751
284
center at mouse
zoom-center
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
0

SWITCH
578
379
687
412
show-axes?
show-axes?
1
1
-1000

BUTTON
658
283
750
316
move window
move-window
T
1
T
OBSERVER
NIL
M
NIL
NIL
0

INPUTBOX
19
615
131
675
axes-color
3.0
1
0
Color

INPUTBOX
131
615
249
675
graph-color
135.0
1
0
Color

INPUTBOX
249
615
368
675
background-color
0.0
1
0
Color

BUTTON
367
615
483
648
update window
update-window-colors
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
774
251
946
284
a
a
f-a-min
f-a-max
0.0
f-a-increment
1
NIL
HORIZONTAL

INPUTBOX
855
614
943
674
a-increment
1.0
1
0
Number

INPUTBOX
942
614
1031
674
a-max
50.0
1
0
Number

INPUTBOX
769
614
856
674
a-min
-50.0
1
0
Number

SLIDER
774
283
946
316
b
b
f-b-min
f-b-max
0.0
f-b-increment
1
NIL
HORIZONTAL

INPUTBOX
769
673
856
733
b-min
-50.0
1
0
Number

INPUTBOX
856
673
944
733
b-increment
1.0
1
0
Number

INPUTBOX
943
673
1031
733
b-max
50.0
1
0
Number

INPUTBOX
769
731
855
791
c-min
-50.0
1
0
Number

INPUTBOX
855
731
943
791
c-increment
1.0
1
0
Number

INPUTBOX
943
731
1031
791
c-max
50.0
1
0
Number

BUTTON
769
582
1029
615
update constant sliders
update-constant-sliders
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
774
314
946
347
c
c
f-c-min
f-c-max
0.0
f-c-increment
1
NIL
HORIZONTAL

BUTTON
774
383
947
416
detect change (BETA)
detect-change
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
777
225
927
243
Constant Sliders
12
0.0
1

BUTTON
774
351
947
384
update window with constants
update-window-with-constants
NIL
1
T
OBSERVER
NIL
U
NIL
NIL
0

@#$#@#$#@
## WHAT IS IT?

This is a general-purpose graphing calculator. It is intended to visualize how algebraic graphs would look like. This calculator is able to graph implicit equations, which is any equation that can be written as 0 = *. (With some exeptions, which are documented in the KNOWN BUGS AND MISFEATURES section)

## HOW TO USE IT

Before doing anything, **setup** the model. This will initialize all the necessary features and the visual area.

Use **reset all** to reset all the inputs, sliders, and internal states of the graphing calculator to their default values.

### GRAPHING
To graph an equation, put the equation in the input bar named **=0** and hit **add graph**.

The equation box will keep track of all graphed equations. When there is a error in the syntax of the equation, it will also show up in there, giving some important details about the error.

Use **clear window and graph** instead of **add graph** if you want to remove all previously graphed equations and only graph the one in the **=0** input bar.

**remove equation of #** will remove one equation based on its index. The index is the number in the **equation#** input bar. The corresponding equation can be looked up in the equation box above.

**clear all graphs** will clear all graphed equations, but will not reset any window settings.

### Syntax of Equation
Put the equation in the form of "0 = *" and leave out the "0 =" part. Currently this is the only way to obtain a correct graph.

For example, to graph the equation "y ^ 2 + x ^ 2 = 100", type "y ^ 2 + x ^ 2 - 100".

To graph a function, simply put in the function and add "- y" in the end.
For example, to graph the function "y = x + 4", type "x + 4 - y".

The calculator requires equations to be put in the format of a Netlogo expression. For the usage of this model, this means that many expressions might look different from a typical math print.

Some important things to note about operators and syntax:

  * Use basic arithmetic operators as usual, such as **+, -, \*, /**
  * Use **^** for exponentiation, where "10 ^ 2" means 10 squared
  * Use the *log* keyword followed by the number, and then the base, with one space in between. For example, "log 64 2" means log of 64 to the base 2, which is 6.
  * Put a space around each operator and numberical value
  * _π_ and _e_ are predifined. To use them, type in "pi" or "e"
  * Netlogo provides trigonometric functions, but they are in degrees
  * "x" and "y" follow the conventional meaning of algebra
  * DO NOT type in any equation lacking both "x" and "y", and the calculator will not graph anything if you do this. 
    * Theoretically, 0 is not equal to anything except for 0, so "0 = a" where a is anthing not 0, will not produce a graph, since it's a true statement. "0 = 0" will produce a graph that's true for every x and y. These are not meaningful graphs, so the calculator avoids them

If an error occurs when the program tries to graph the equation, the error will show up in the **Graphed Equations** box, and the program will make a beep sound.

For more imformation, including some limitation in numbers, refer to the [Math section in Netlogo's Programming Guide](https://ccl.northwestern.edu/netlogo/docs/programming.html#math)

### WINDOW
Window refers to the visual area of the calculator.

There are several operations available on the window, **zoom in**, **zoom out**, **center at mouse**, **move window**, and **reset window**.

When the mouse(cursor) is in the window, **zoom in** and **zoom out** will use the mouse as the center. If the mosue is not in the window, they will zoom using the center of the window.

When mouse is in window, **center at mouse** will set the mouse coordinate as the new center for the window. If the mouse is not in the window, **center at mouse** does nothing.

**reset window** will reset the window settings to the default values, including the zoom and center of the window.

All the zooming features zoom by the **zoom-factor**.

Turn **show-axes?** off if you don't want to see the x- and y-axes in the window.

The window shows its boundaries with _x min_, _x max_, _y min_ and _y max_. These values will change when you zoom or move the window.

The colors of window background, graph, and axes can be customized. To do this, scroll down and change the color in the input bar, and then press **update window**.

### CONSTANT SLIDERS

**Constant Sliders** provide a way to include letter constants into the equation. When you include one of the letters, you can control the graph with the slider.

**update window with constants** will reflect the change of the slider value in all graphs.

To change the minimum, maximum, or the increment step of the sliders, scroll to the bottom of the calculator, and change the corresponding value. When finished, press **update constant sliders**.

**detect change** (BETA) will automatically detect any change in the slider value and update the equation based on the new value. At this point, this feature is not stable.

<!---
## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

--->

## THINGS TO TRY
<!---
(suggested things for the user to try to do (move sliders, switches, etc.) with the model)
--->
Try some interesting equations.

 - `5 * e ^ (-1 * ((x / 5) ^ 2)) - y` (bell curve)

 - `x - y ^ 2` (sideways parabola)

 - `x - 2 ^ y` (logarithm)

 - `sin(100 * x) - cos(100 * y)` (grid)

 - `sin(100 * x) - 2 * cos(100 * y)` (waves?)


## EXTENDING THE MODEL
<!---
(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)
--->

  * Use different colors for consecutive graphs, automatically.
  * Optimize **move window** and the zoomimg features

<!---
## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)
--->

## KNOWN BUGS AND MISFEATURES

  * Functions like _floor_, _round_, _mod_, produces a continuous graph, which is unexpected.
  * Square root functions and logarithmic functions can be very slow, and may show an incomplete graph
    * A workaround for logarithmic function is to do exponentiation on y (e.g. instead of 2 ^ x - y = 0, type x - 2 ^ y = 0)
  * Odd root functions only produce half of the graph that they are supposed to produce, in addition to being very slow
  * Equations that contain exponentiation with a negative power will not work


## CREDITS AND REFERENCES

Inspiration from Peter Brooks, at Stuyvesant High School. He solved most of the problems in this model.
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
NetLogo 6.1.1
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
