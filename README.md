# [Youtube Video](https://www.youtube.com/watch?v=x8CDa-khAYY)

# What is it
This is a path-finding AI that takes advantage of [bunnyhopping](https://youtu.be/LxirBXof-3s), a movement technique in Counter Strike and other such games. To move optimally, a bot also has to factor in acceleration, variable turning radius and speed gains/losses from slopes and walls. This unique scenario means that conventional path-finding approaches can only be used as a general guide but won't help it with fine control.

# How it works
* Normal path-finding algorithm provides a path to follow (think google maps)
* Monte Carlo Tree Search algorithm is used for planning out how to follow this path considering the physics and using the available controls

# Other notable parts
This is stuff you'd probably want to know if you started looking into the code

 - "multistep" is an easy way for the MCTS algorithm to look further into the future by repeating the chosen action n amount of times. Since trees increase exponentially, it is important to have each node to be different to the last but holding down for too long will make it less agile. 
 - "splitcounter": when multistep is used, each action will be held for n times longer than normal and those steps still need to be shown onscreen anyway, so instead of allowing all the MCTS iterations to be done on a single laggy frame they can be split across each of those n frames for a better framerate

edit: I also used a bad version of "Search Tree Reuse" in https://ieeexplore.ieee.org/document/6731713 (my approach would be with no decay ie γ=1 ) so definitely read that explanation



# Credits
The most notable/helpful sources I used. Basis meaning I still had to port it over to GDScript and make some changes.
 - [Dust 2 Model](https://sketchfab.com/3d-models/dust2-75fb3338c87742ce92c2f31b9bb42d6d)
 - [FPS camera controls](https://youtu.be/Nn2mi5sI8bM)
 - [Basis for bunnyhop physics](https://youtu.be/B9mqpaUJ0-g)
 - [Basis for Monte Carlo Tree Search](https://gist.github.com/qpwo/c538c6f73727e254fdc7fab81024f6e1)
 - [MCTS pseudocode / text explanation](https://www.geeksforgeeks.org/ml-monte-carlo-tree-search-mcts/)
 - [MCTS video explanation](https://youtu.be/UXW2yZndl7U)
 - [MCTS more general video explanation](https://youtu.be/Fbs4lnGLS8M) 
 

