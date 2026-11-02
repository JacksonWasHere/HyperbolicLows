# Hyperbolic Lows
This project can be used to show the low elements (and their inverses) in a hyperbolic coxeter group of rank 3. It also will show the small roots and fundamental domain.

## How to Use
The jupyter project has one code block at the top that needs to be run. The line
`system = R3System(a,b,c)`
sets the relations between the generators. Change `a,b,c` to any integers such that `1/a + 1/b + 1/c < 1`.

After running the code block the file `sketch/roots.json` will be updated to contain the group information.
You can now run the following in the `sketch` folder.

`python3 -m http.server`

This should run a server that shows the hyperbolic tiling.

## Demo
You can see an example on [this page](https://editor.p5js.org/jackson.weidmann/sketches/4xdFahsnT) with the group (2,4,5). If there is no image visible hit the play button.
