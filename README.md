# AnyFold Vim plugin

Generic folding mechanism and motion based on indentation. Fold anything that is structured into indented blocks. Quickly navitate between blocks.


## Introduction

This Vim plugin comes with the following features:
* Folding mechanism based on indented blocks that has a very intuitive and predictable behaviour (see examples below).
* Results comparable to syntax aware folding methods but generic algorithm that does not rely on language specific rules.
* Works out of the box for any filetypes, optimal results for all indented languages (including properly indented curly brace languages).
* Shortcuts to toggle folds and to navigate to beginning / end of a block and to previous / next indented block.
* Can handle corner cases with ease (comments, varying indentation widths, line breaks).

It has the following shortcomings:
* Can **not** correctly fold mismatched indentation and thus should only be used together with disciplined programming style (or in combination with Vim's `equalprg` autoindent feature).
* Indent based text objects not implemented - for that I recommend [vim-indent-object](https://github.com/michaeljsmith/vim-indent-object).


## Examples

### Python
![python](https://cloud.githubusercontent.com/assets/6178172/18611583/c489caa8-7d3d-11e6-8a12-57fe183250ed.gif)

### Fortran
![fortran](https://cloud.githubusercontent.com/assets/6178172/18611581/c4865c92-7d3d-11e6-9a90-98bbb12d04d5.gif)

### C++
![cpp](https://cloud.githubusercontent.com/assets/6178172/18611584/c48a3c86-7d3d-11e6-9d64-df01580709ae.gif)

### Java
Note: this example is outdated since better defaults have been implemented for curly braces.
![java](https://cloud.githubusercontent.com/assets/6178172/18611582/c4896374-7d3d-11e6-834b-9dcecb4ae1ef.gif)

Examples were recorded using

```vim
let anyfold_activate=1
let anyfold_fold_comments=1
set foldlevel=0
colorscheme solarized
hi Folded term=NONE cterm=NONE
```


## Setup and usage

1. Install this plugin with a vim plugin manager.
2. Add the following lines to your vimrc (if not already present).

    ```vim
    filetype plugin indent on
    syntax on
    let anyfold_activate=1
    set foldlevel=0
    ```

    Choose a higher foldlevel if you prefer to have folds open by default.
3. Use the spacebar to toggle folds and key combinations `[[` and `]]` to navigate to the beginning and end of the current open fold. Use `]k` and `[j` to navigate to the end of the previous block and to the beginning of the next block.


## Additional remarks

1. *Filetype specific activation:*
    Activate AnyFold for a selected \<filetype\> only with

    ```vim
    autocmd Filetype <filetype> let anyfold_activate=1
    ```
2. *Useful folding commands:* Using the spacebar to toggle folds is the most convenient way of dealing with folds. Note that this always recursively opens all folds under the cursor. You can easily refold by placing the cursor somewhere inside the open fold and hitting `zx`. Open all folds with `zR`.
3. *Fold display:* AnyFold's minimalistic display of closed fold assumes that folds are highlighted by your color scheme. If that is not the case, consider installing a suitable color scheme or highlight folds yourself by a command similar to

    ```vim
    hi Folded term=underline
    ```

4. *Customization:* For expert configuration, AnyLoad triggers an event `AnyFoldLoaded` after initialisation. This enables user-defined startup steps such as

    ```vim
    autocmd User AnyFoldLoaded normal zv
    ```

   which unfolds the line in which the cursor is located when opening a file.
5. *Documentation:* For more detailed instructions and information, read the included vim doc `:h AnyFold`.


## Options

All options can be either set globally

```vim
let <option>=<value>
```

or filetype specific

```vim
autocmd Filetype <filetype> let <option>=<value>
```

Option | Values | Default value |  Description
------ | -------------- | ------------- | ------------
`anyfold_fold_display` | 0, 1 | 1 | Minimalistic display of closed folds
`anyfold_toggle_key` | string | '\<space\>' | Key to toggle folds
`anyfold_motion` | 0, 1 | 1 | Map motion commands to `[[`, `]]`, `[j`, `]k`
`anyfold_auto_reload` | 0, 1 | 1 | Automatically update folds
`anyfold_identify_comments` | 0, 1 | 1 | Identify (and ignore) comment lines
`anyfold_fold_comments` | 0, 1 | 0 | Fold multiline comments
`anyfold_fold_toplevel` | 0, 1 | 0 | Fold subsequent unindented lines


## Acknowledgements

I thank the following people for their contribution
* Greg Sexton for allowing me to use [his function](http://www.gregsexton.org/2011/03/improving-the-text-displayed-in-a-fold/) for improved fold display.
