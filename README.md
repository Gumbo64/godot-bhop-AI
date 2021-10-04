# What is it
This is a path-finding AI that takes advantage of [bunnyhopping](https://youtu.be/LxirBXof-3s), a movement technique in Counter Strike and other such games. To move optimally, a bot also has to factor in acceleration, variable turning radius and speed gains/losses from slopes and walls. This unique scenario means that conventional path-finding approaches can only be used as a general guide but won't help it with fine control.

# How it works
* Normal path-finding algorithm provides a path to follow (think google maps)
* Monte Carlo Tree Search algorithm is used for fine adjustments

# Other notable parts
This is stuff you'd probably want to know if you started looking into the code

 - "multistep" is an easy way for the MCTS algorithm to look further into the future by repeating the chosen action n amount of times. Since trees increase exponentially, it is important to have each node to be different to the last but holding down for too long will make it less agile
 - "splitcounter" is used so that "multistep" doesn't just speed up the game. This means that the MCTS iterations are spread across each of those frames. Say "multistep" was set to 10 and you had to do 30 iterations total each time you chose a new move then you would do 3 each frame.


# Credits
The most notable/helpful sources I used. Basis meaning I still had to port it over to GDScript and make some changes.
 - [Dust 2 Model](https://sketchfab.com/3d-models/dust2-75fb3338c87742ce92c2f31b9bb42d6d)
 - [FPS camera controls](https://youtu.be/Nn2mi5sI8bM)
 - [Basis for bunnyhop physics](https://youtu.be/B9mqpaUJ0-g)
 - [Basis for Monte Carlo Tree Search](https://gist.github.com/qpwo/c538c6f73727e254fdc7fab81024f6e1)
 - [MCTS pseudocode / text explanation](https://www.geeksforgeeks.org/ml-monte-carlo-tree-search-mcts/)
 - [MCTS video explanation](https://youtu.be/UXW2yZndl7U)
 - [MCTS more general video explanation](https://youtu.be/Fbs4lnGLS8M) 
 

