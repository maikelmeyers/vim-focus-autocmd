vim-focus-events
==============
Let this plugin cease your irritation from copy-pasting and etc!


Features
--------
* Offers helpful widgets, binded to events FocusGained, FocusLost:
    - sync_clipboard -- copies content between reg" and reg+ ;
    - sync_filestate -- re-reads changed buffers or saves them;
* Introduces events FocusGained and FocusLost for terminal vim.
* Different cursor shape for NORMAL/INSERT modes in terminal.
    (Why integrated? Because it's terminal dependent staff.)
* Different cursor color for primary/secondary language in terminal.
* Highly customizable. Choose your own set of necessary features.


Alternatives
------------
* [vitality](https://github.com/sjl/vitality.vim) -- only iTerm2.


Background
----------
In my general workflow I use clipboard too often -- having many instances of
vim, terminals, browsers, etc at once. No matter how little keystrokes you
need for any simple mappings to copy to and from '+' register, it will always
be too much. I tried really hard to accustom myself with no success.


Installation
------------
You know how to use your's plugin manager, so convert it yourself:
```
NeoBundle 'amerlyq/vim-focus-autocmd', {
    \ 'disabled' : !has('unix'),
    \ 'build': { 'linux': 'bash ./res/setup' }
    \ }
```


FAQ
---------------
Q: When switching between two vims in different terminals, FocusGained is
triggered, but sync_clipboard don't work.
A: It greatly depends on terminal and environment.
