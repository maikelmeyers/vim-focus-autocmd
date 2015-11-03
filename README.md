vim-focus-events
==============
Let this plugin cease your irritation from copy-pasting and etc!


Features
--------
* Offers helpful widgets, binded to events FocusGained, FocusLost:
    - sync_clipboard -- copies content between reg" and reg+ ;
    - sync_filestate -- re-reads changed buffers or saves them;
* Introduces events FocusGained and FocusLost for terminal vim.
* Different cursor shape for NORMAL/INSERT modes (why here? -- because it's
        terminal dependent staff).
* Different cursor color for primary/secondary language in terminal (you need
        [vim-xkbswitch](https://github.com/lyokha/vim-xkbswitch) installed).
* Highly customizable. Choose your own set of necessary features.


Alternatives
------------
* [vitality](https://github.com/sjl/vitality.vim) -- works only for iTerm2.


Background
----------
In my general workflow I use clipboard too often -- having many instances of
vim, terminals, browsers, etc at once. No matter how little keystrokes you
need for any simple mappings to copy to and from '+' register, it will always
be too much. I tried really hard to accustom myself with no success. Solution
is pretty cimple and cute -- make vim copy registers for you.

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
NeoBundle 'amerlyq/vim-focus-autocmd', {
    \ 'disabled' : !has('unix'),
    \ 'build': { 'linux': 'bash ./res/setup' }
    \ }
```
That snippet will automatically update symlinks on ```:NeoBundleCheckUpdate```.

If after update something don't work, you must restart urxvt. Because it
sources plugins only at loading time.

Used in connection with
[vim-focus-autocmd](https://github.com/amerlyq/vim-focus-autocmd).
Install it for plugin to work in urxvt. In XTerm will work as is.


FAQ
---------------
* Q: When switching between two vims in different terminals, FocusGained is
triggered, but sync_clipboard don't work.
* A: It greatly depends on terminal and environment.
