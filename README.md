# Zero To Bare Metal: A bare metal firmware writing journey

In this github repository, I document my journey of writing a bare-metal firmware
from the ground up. I write down the details so that, if you choose to follow along,
you can see exactly what was done, why each decision was made, and how the system
works at the lowest level.

Where necessary, I refer to core hardware and system concepts, but I focus on 
explaining them in detail where I believe deeper understanding is important. 
Rather than relying on vague references or assumptions, I take the time to lay
out exact sources and references, so that every mechanism, design choice or 
principle can be traced and verified.

This remains, first and foremost, a practical journey - centered on real 
mplementation, debugging and understanding, without hiding behind frameworks or
operating systems.

Here are the steps I have taken so far:

 + [Part 0](00_Introduction/README.md): Introduction to the journey
 + [Part 1](01_Directory_Layout/README.md): Directory Layout
 + [Part 2](02_Build_System/README.md): Build System
 + [Part 3](03_Arm_Makefile_Fragment/README.md): Arm Makefile Fragment
 + [Part 4](04_Linker_Script_and_Memory_Layout/README.md): Linker Script and Memory Layout
