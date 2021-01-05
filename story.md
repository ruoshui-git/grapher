# Grapher

This is a graphing calculator, written in NetLogo.

# What is NetLogo?

NetLogo is a multi-agent programmable modeling environment, in which commands are entered to control four agents (observer, turtles, patches, links) to run a simulation and draw graphics on screen.

# Motivation

When I took Intro CS, I asked my teacher Mr. Brooks if there's something interesting that I could do.

## Initial Idea

In a NetLogo program:

1. Draw the grid and axis for a Cartesian (xy) plane.
2. Have a 2 sliders, each controlling 1 coefficient of a parabola.
3. Have a turtle draw the graph and change the sliders while drawing to see interesting images in the end.

## What I did

I offered to write a basic model that can graph arbitrary functions. I wanted to see what's possible with the limited string parsing abilities of NetLogo.

# Process

## Function Grapher

This version could only graph basic functions. It asks a turtle to move from the left to right (giving x value), and plot the corresponding y-value.

[image]

It was relatively easy compared to what came later. Initially, `sin` and `cos` weren't behaving correctly, but it was fixed after changing a NetLogo setting.

# Implicit Equation Grapher

Then I started to wonder if it's possible to graph arbitrary implicit equations.

Wolfram|Alpha can do this. Desmos can do it _really fast_.
At first Mr. Brooks thought that desmos run in the server. I showed him that it's not the case.

## Initial Idea

At first, with other math teachers, Mr. Brooks said it looked like gradient fields (or something like that, I can't remember). I didn't know what it was, so according to him, all I had to do was to "learn some calculus". The idea was to find a point on the graph, and then calculate in which direction the graph would "move", and have the turtle continue on that path.

The problem with this approach is that many graphs are not continuous. Some can have multiple parts.

## My implementation

Not understanding the algorithm anyway, my first desperate attempt (over winter break) was to assign a `(x, y)` to each each patch (pixel). For each patch, calculate if their `(x, y)` fit in the equation (`= 0`).

But an exact equal comparison produces almost nothing. So an approximation is needed. The `epsilon`, so to say, is defined via a user-controlled slider.

[image]

And we thought that nothing could be done to improve that.

## My Thought Journey

After winter break, Mr. Brooks told me that what I was doing was taking a cross section of the 3D graph with the plane `z = 0`. My equations were in the form of `0 = [equation]`. If I were to use another number on the left hand side, it would give me the cross section at a different height.

[image]

I thought he meant that there was something wrong about it. I thought about that for a long time.

And my question was, does it make sense? So here's what I thought about over the next few days:

If I were to graph `z = x^2 + y^2`, it would look like a cone that opens upward, except for the the body is round. From the side, it should look like a parabola (since as `z` increases, `y` increases on the order of squares).

[image]

If I slice the graph with `z = 0`, I get a dot, because that's the tip of the 3D shape. As `z` increases, the plane will intersect thicker parts of the 3D shape, producing a circles of increasing length.

And this makes sense when I interpret the equation just as graphing a 2D circle, since it's just increasing `r`, the radius, in `r^2 = x^2 + y^2`. (This is in no way rigorous, because the 3D visualization in my head depends on this fact. I almost fell into circular reasoning. But still, since I know the latter already, I can say that I just used it to understand the former.)

[image]

However, the 3D shape here is only above or on `z = 0`, so if I move the plane down (`z < 0`), I would see nothing because nothing is there. It works with the circle definition because a circle with radius less than 0 will not produce any graph.

[image]

So I thought that they are coherent. I then talked to Mr. Brooks about this. He said there was nothing wrong. The way I was implementing graphing just reminded him of that slicing process.

Then the problem here becomes, how do we know if a point is at the intersection of the plane and the 3D shape?

Just as I was going to leave the office on that day, he realized that if a point on 3D shape intersects with the plane `z = 0`, then the values around it should have opposite signs (+-), meaning that some are above the plane, some are below.

[image]

And in NetLogo, if we run this for every `patch` and test its `z` value produced from its `(x, y)`, we can know if the point is on the graph.

## New Implementation

The actual implementation checks that if the `z` value of the current `patch` is above the plane. If it is, and any neighboring `patch` is below the plane, then we can say that the current `patch` is "on the graph".

With that, here's my viable product:

[image]

The algorithm was really difficult to come up with. But the implementation is _really_ easy.

```netlogo
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
        ;; error catching code
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
```

And I added other features, such as resizing and panning the window, changing colors, etc, which are relatively easy to reason about, but involves much more coding.

# Known Bugs

NetLogo limitations exist. But those aren't interesting.

Here's an interesting one: in junior year Calculus class, we talked about a weird equation:

`x^3 + y^3 + 1 - 3xy = 0`

This graph has a single point at `(1, 1)` and a line running somewhere else. Only at that point the graph is on the cross section. All points around it are above the plane, no points are below.

Turns out that even Desmos and Wolfram|Alpha cannot graph that dot accurately. Turns out that my calculator on default settings just happens to check `(1, 1)`, so it actually graphed that point. But a transformed version (e.g. via translation) will not show correctly.

But since Desmos and Wolfram|Alpha can't do this, I'm good with what I have now.

# Ideas for Improvement

- Currently resizing and panning the window requires _all_ equations to be computed and graphed fresh. It would be nice if I can somehow cache the results and reuse them in future computation.
- Graph different graphs with different colors, like Desmos.
- There's something called NetLogo Web that loads a NetLogo model in the browser. However, it's still a work in progress, and very _slow_ compared to the desktop version. I want to contribute to it by porting the CoffeeScript engine to WebAssembly compiled from Rust. It would make the app a lot more accessible.
