# Manually install ZSH on Termux!

### run
```bash
bash Install-zsh.sh
```

### Install [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh)
> [!Important]
> Restart Termux

### Install [powerlevel10k](https://github.com/romkatv/powerlevel10k)
```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```
### Install [ZSH-Autoupdate](https://github.com/TamCore/autoupdate-oh-my-zsh-plugins)
```bash
git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $ZSH_CUSTOM/plugins/autoupdate
```

### Install [ZSH-Autocomplete](https://github.com/marlonrichert/zsh-autocomplete)
```bash
git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
```

### Install [ZSH-Autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

### Install [ZSH-Syntax-Highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### Open and edit ZSH config file
```bash
nano $HOME/.zshrc
```

### Set theme in ZSH config file

> [!Note]
> Go to line 11 and comment out the existing theme. Then append the code below:

```
ZSH_THEME="powerlevel10k/powerlevel10k" 
```

### Set plugins in ZSH config file

> [!Note]
> Go to line 74 and comment out the existing plugins. Then append the code below:

```
plugins=(git autoupdate zsh-autocomplete zsh-autosuggestions zsh-syntax-highlighting)
```


### Customize Update Frequency to daily
```
export UPDATE_ZSH_DAYS=1
```

### Reload the shell:
```bash
source ~/.zshrc 
```

Now setup PowerLevel10K to your liking.
