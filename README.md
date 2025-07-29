# Tank controls for gameboy
A repository for one of my gameboy experiments

# What is this?
A while back I saw a few videos showcasing the feasibility of 3d-like game engines for the original gameboy. In particular, I really liked [this Mode 7 gameboy demo](https://www.youtube.com/watch?v=6OOEMhUXaCU) and [this fan-made port of (parts of) Wolfenstein for gameboy](https://www.youtube.com/watch?v=3uTkUN4nYM4). The gameboy is not known for 3d games, but it clearly can do them (or pseudo-3d anyway), which makes me want to see more done in that vein. I asked both developers of the above demos if they would consider letting me use their engines, but neither seemed interested, so I decided to learn how to do it and write my own.

# So this is a 3d engine for the gameboy?
No, not yet. But it's a start: pseudo-3d games like Mario Kart and Wolfenstein commonly feature "tank controls" where left and right don't move your *character* left and right, they just rotate your perspective, and vertical movements don't move you up or down, but forward or backward on the Z axis. So I worked on tank controls for the gameboy and got part of it working: left and right rotate the direction your character faces, but the hard part is the Z-axis movement, and that part is not done yet. Up moves you "forward" in whatever direction you're facing, but it moves you on a 2D plane, like in the game Asteroids. The character is also currently represented as a black dot that moves around a blank grey screen, except I did implement an invisible wall on the left of the screen.

# What are your next steps?
Raycasting. The gameboy's field of play is a grid of 32x32 cells, which are meant to be populated by small graphics called sprites, and one scrolling background image. I want to place blocks down in some of those cells to form a maze-like pattern as in Wolfenstein, and then implement raycasting so that the screen shows the maze as if you are inside it rather than looking down at it. But I decided on this route after doing some work implementing something called edge detection, and it was quite a bit of work that I don't think I'll need anymore, so I decided to store it here on my github, hence the existence of this repo.

# Why are you doing this on gameboy? Why not build for modern systems?
I've always been fascinated with "doing more with less," and the gameboy is probably the least-capable piece of game hardware that is technically capable of doing this (barely) and still has an active development community that I can go to for help. Gameboy emulators are also very commonly available for most operating systems without being taxing on the hardware, so games made for the gameboy can actually still be played by many people today. E.g. you can just put it up on a website and let people play it one of the many gameboy emulators written in javascript.

# Tech details
I decided to program the engine in Assembly using the [RGBDS developer kit](https://gbdev.io/). There are other, easier devkits out there, but doing it in Assembly maximizes the system's performance, and I think I will really need to make it sweat for this engine to work. Also note that my assembly file copies a bunch of stuff
from [this gameboy development tutorial](https://gbdev.io/gb-asm-tutorial/index.html) and [these gameboy development examples](), including the need for a hardware.inc file that is linked [here](https://raw.githubusercontent.com/gbdev/hardware.inc/v4.0/hardware.inc).
