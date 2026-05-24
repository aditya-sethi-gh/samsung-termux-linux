# samsung-termux-linux
Running Linux on a Samsung device.


After installing Termux from F-Droid and Termux-X11 from the official GitHub repo, run the following script:

For a desktop environment over Termux (XFCE or LxQt):

apt update && apt upgrade -y && apt install curl -y && curl -fsSL https://raw.githubusercontent.com/aditya-sethi-gh/samsung-termux-linux/main/setup.sh | bash


OR for Ubuntu (no GUI):


apt update && apt upgrade -y && apt install curl -y && curl -fsSL https://raw.githubusercontent.com/aditya-sethi-gh/samsung-termux-linux/main/setup-ubuntu.sh | bash


OR for Ubuntu with GNOME:


apt update && apt upgrade -y && apt install curl -y && curl -fsSL https://raw.githubusercontent.com/aditya-sethi-gh/samsung-termux-linux/main/setup-ubuntu-gnome.sh | bash
