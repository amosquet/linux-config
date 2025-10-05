Config files that my scripts and linux devices can pull from for easy provisioning.

This is very much in active development and should currently NOT be used if this is your first time using Linux.

The basis is that after doing the basic install of Arch, and within the terminal of the new machine, you call run installer.sh and it will handle everything.
This includes setting up KDE Plasma, graphics drivers, and application install. It will also configure pacman and paru with some basic settings.

Later, I will consider releasing a script that could handle everything including Arch installation, but right now I am focusing on automating the environment setup.

I made this because I don't want to spend time reinstalling everything when I switch to Arch from Windows and Fedora, I had to install everything multiple times on my laptop because Framework support kept telling me that wifi problems was an OS/Driver problem, not hardware. As a result, I went from Windows -> NixOS -> Fedora -> Ubuntu -> Fedora, all within the span of two short weeks, and I got annoyed at having to do everthing over and over again. To avoid the time when migrating my desktop to Arch from Windows, I want a script to do it for me, and when I eventually migrate from Fedora to Arch.
PS. Framework support was very much wrong and ended up sending me a new AMD RZ616 wifi card, that died a few months later, and now I'm using a much better Intel AX210 (non vPro)