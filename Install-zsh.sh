pkg install zsh git lsd vim
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "alias ls=lsd" >> ~/.zshrc
git clone https://github.com/adi1090x/termux-style && cd termux-style && ./install
termux-style
read -p "press any key to exit and restart!"
exit
