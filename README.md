vim-focus-events
==============
Provided focus events for vim in termnals: urxvt, XTerm, Konsole and iTerm2.
Neovim ```>v0.1.1``` provides focus events by itself for XTerm/Konsole.

Features
--------
* Introduces events FocusGained and FocusLost for terminal vim.
* Offers helpful widgets, binded to events FocusGained, FocusLost:
    - clipboard -- copies content between regs @" and @+ ;
    - buffers -- re-reads changed buffers or saves them;
* Different cursor shape for NORMAL/INSERT modes (why here? -- because it's
        terminal dependent staff).
* Different cursor color for primary/secondary language in terminal (you need
        [vim-xkbswitch](https://github.com/lyokha/vim-xkbswitch) installed).
* List of options for customization you can see in ```plugin/focau.vim```.
  You have several ways to change default options:
```VimL
" #1 -- set all options of interest at once
let g:focau = {'key': 'value'}
" #2 -- allows adding comments after options
let g:focau = {}
let g:focau.key = 'value'
```


Alternatives
------------
* [vitality](https://github.com/sjl/vitality.vim) -- works only for iTerm2. Seized.
* [tmux-plugins](https://github.com/tmux-plugins/vim-tmux-focus-events) -- no
urxvt support. Was refined and completely melded with this plugin.

Background
----------
In my general workflow I use clipboard too often -- having many instances of
vim, terminals, browsers, etc at once. No matter how little keystrokes you
need for any simple mappings to copy to and from '+' register, it will always
be too much. I tried really hard to accustom myself with no success. Solution
is pretty simple and cute -- make vim copy registers for you.

There is default vim setting to autosync regs @" and @+:
```vim
set clipboard^=unnamedplus
```
but such workflow has flaws, as you will lost value in @+ as soon as you use
@", which is desired to be preserved for repeated use.


Installation
------------
You know how to use your's plugin manager, so convert it yourself:
```
NeoBundle 'amerlyq/vim-focus-autocmd'
```
In XTerm, Konsole and iTerm2 plugin works as is.
To receive focus events in urxvt, you must install:
[urxvt-ext-evolved](https://github.com/amerlyq/urxvt-ext-evolved).
Don't forget to restart urxvt after update.

To work in tmux, check ```~/.tmux.conf``` had enabled focus events:
```
set -g focus-events on
```

FAQ
---------------
* Q: When switching between two vims in different terminals, FocusGained is
triggered, but sync_clipboard don't work.
* A: It greatly depends on terminal and environment timings, because
FocusGained in current terminal can be triggered *before* FocusLost in
previous.
* Q: I don't receive FocusLost/FocusGained when cursor in cmdline
* A: You simply don't see its consequences -- because screen wasn't redrawed.
Moreover, cmline executes mappings in sandbox (see :h sandbox), so some
stuff inside autocmd linked to ```Focus*``` can't be executed at all.
* Q: When in operator-peding mode and focus lost, mode is dropped to normal.
* A: It's consequences of operator-peding mode itself. Currently I have no
reliable way to execute function being in OP and restore OP command after that.
* Q: In SELECT mode sometimes selected text became deleted when switching.
* A: ```snoremap``` are unreliable. Don't use this mode as much as you can?:)
* Q: Don't work with neovim in urxvt.
* A: Wait for neovim v0.2 where ```t_ti/te``` must be repaired. Currently
neovim is detached from terminal and there no way to send sequences directly.
Those sequences are necessary, as ```urxvt``` has non-standart focus activation.

*If someone knows way to cure one of problems described in this FAQ, feel free
to create issue with mitigation and I'll gladly improve this plugin*
