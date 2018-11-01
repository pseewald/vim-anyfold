# vim-anyfold

Generic folding mechanism and motion based on indentation. Fold anything that is structured into indented blocks. Quickly navigate between blocks.


## Short Instructions

Using this plugin is easy: Activate vim-anyfold by the command `:AnyFoldActivate` and deal with folds using Vim's built-in fold commands. Use key combinations `[[` and `]]` to navigate to the beginning and end of the current open fold. Use `]k` and `[j` to navigate to the end of the previous block and to the beginning of the next block. For more detailed documentation, read the included vim doc `:h anyfold` or continue reading.


## Introduction

This Vim plugin comes with the following features:
* Folding mechanism based on indented blocks that has a very intuitive and predictable behaviour (see examples below).
* Results comparable to syntax aware folding methods but fast and generic algorithm that does not rely on language specific rules.
* Works out of the box for any filetypes, optimal results for all indented languages (including properly indented curly brace languages).
* Shortcuts to navigate to beginning / end of a block and to previous / next indented block.
* Can handle corner cases with ease (comments, varying indentation widths, line breaks).
* Fast update mechanism that keeps folds in sync with buffer.

It has the following shortcomings:
* Can **not** correctly fold mismatched indentation and thus should only be used together with disciplined programming style (or in combination with Vim's `equalprg` autoindent feature).


## Advantages over foldmethod=indent

* `foldmethod=indent` only works for indents that are a multiple of `shiftwidth` and thus fails for aligned code lines and inconsistent indentation. Vim-anyfold correctly defines folds for arbitrary indents.
* vim-anyfold recognizes braces as part of indented blocks and correctly folds them. Vim-anyfold thus produces good folds not only for indented languages but also for e.g. C++ or Java.
* vim-anyfold optionally folds multiline comments.

Be aware that `vim-anyfold` is much slower than `foldmethod=indent` and can reduce Vim's responsiveness. This is noticeable only when editing large files.


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
autocmd Filetype * AnyFoldActivate
let g:anyfold_fold_comments=1
set foldlevel=0
colorscheme solarized
hi Folded term=NONE cterm=NONE
```


## Setup and usage

1. Install this plugin with a vim plugin manager.
2. Add the following lines to your vimrc (if not already present).

    ```vim
    filetype plugin indent on " required
    syntax on                 " required

    autocmd Filetype * AnyFoldActivate               " activate for all filetypes
    " or
    autocmd Filetype <your-filetype> AnyFoldActivate " activate for a specific filetype

    set foldlevel=0  " close all folds
    " or
    set foldlevel=99 " Open all folds
    ```

If you prefer to not activate vim-anyfold automatically, you can always invoke this plugin manually inside vim by typing `:AnyFoldActivate`.

3. Use Vim's fold commands `zo`, `zO`, `zc`, `za`, ... to fold / unfold folds (read `:h fold-commands` for more information). Use key combinations `[[` and `]]` to navigate to the beginning and end of the current open fold. Use `]k` and `[j` to navigate to the end of the previous block and to the beginning of the next block.


## Additional remarks

1. *Supported folding commands:* anyfold uses `foldmethod=expr` to define folds. Thus all commands that work with expression folding are supported.
2. *Fold display:* anyfold's minimalistic display of closed fold assumes that folds are highlighted by your color scheme. If that is not the case, consider installing a suitable color scheme or highlight folds yourself by a command similar to

    ```vim
    hi Folded term=underline
    ```

3. *Lines to ignore:* By default, anyfold uses the `foldignore` option to identify lines to ignore (such as comment lines and preprocessor statements). Vim's default is `foldignore = #`. Lines starting with characters in `foldignore` will get their fold level from surrounding lines. If `anyfold_fold_comments = 1` these lines get their own folds. For instance, in order to ignore C++ style comments starting with `//` and preprocessor statements starting with `#`, set

    ```vim
    autocmd Filetype cpp set foldignore=#/
    ```
    This approach is fast but does not work for e.g. C style multiline comments and Python doc strings. If you'd like anyfold to correctly ignore these lines, add

    ```vim
    let g:anyfold_identify_comments=2
    ```
    to your vimrc. Please note that this may considerably slow down your Vim performance (mostly when opening large files).
4. *Large Files:* anyfold causes long load times on large files, significantly longer than plain indent folding. By adding the following to your vimrc (and replacing `<filetype>`), anyfold is not initialized for large files:

    ```vim
    " activate anyfold by default
    augroup anyfold
        autocmd!
        autocmd Filetype <filetype> AnyFoldActivate
    augroup END

    " disable anyfold for large files
    let g:LargeFile = 1000000 " file is large if size greater than 1MB
    autocmd BufReadPre,BufRead * let f=getfsize(expand("<afile>")) | if f > g:LargeFile || f == -2 | call LargeFile() | endif
    function LargeFile()
        augroup anyfold
            autocmd! " remove AnyFoldActivate
            autocmd Filetype <filetype> setlocal foldmethod=indent " fall back to indent folding
        augroup END
    endfunction

    ```

5. *Customization:* For expert configuration, anyfold triggers an event `anyfoldLoaded` after initialisation. This enables user-defined startup steps such as

    ```vim
    autocmd User anyfoldLoaded normal zv
    ```

   which unfolds the line in which the cursor is located when opening a file.
6. *Documentation:* For more detailed instructions and information, read the included vim doc `:h anyfold`.


## Options

All options can be either set globally

```vim
let g:<option>=<value>
```

or filetype specific

```vim
autocmd Filetype <filetype> let g:<option>=<value>
```

Option | Values | Default value |  Description
------ | -------------- | ------------- | ------------
`anyfold_fold_display` | 0, 1 | 1 | Minimalistic display of closed folds
`anyfold_motion` | 0, 1 | 1 | Map motion commands to `[[`, `]]`, `[j`, `]k`
`anyfold_identify_comments` | 0, 1, 2 | 1 | Identify lines to ignore for better fold behavior. 1: use `foldignore`, 2: use `foldignore` and syntax (slow)
`anyfold_fold_comments` | 0, 1 | 0 | Fold multiline comments
`anyfold_comments` | list of strings | ['comment', 'string'] | Names of syntax items that should be ignored. Only used if `anyfold_identify_comments = 2`.
`anyfold_fold_toplevel` | 0, 1 | 0 | Fold subsequent unindented lines
`anyfold_fold_size_str` | string | '%s lines' | Format of fold size string in minimalistic display
`anyfold_fold_level_str` | string | ' + ' | Format of fold level string in minimalistic display

## Complementary plugins

Here is a small list of plugins that I find very useful in combination with vim-anyfold:
* Cycle folds with one key, much more efficient than Vim's built-in folding commands: [vim-fold-cycle](https://github.com/arecarn/vim-fold-cycle)
* Indent based text objects are not (yet) implemented in vim-anyfold, but this plugin works fine (even though blocks are defined in a slightly different way): [vim-indent-object](https://github.com/michaeljsmith/vim-indent-object)


## Acknowledgements

I thank the following people for their contribution
* Greg Sexton for allowing me to use [his function](http://gregsexton.org/2011/03/27/improving-the-text-displayed-in-a-vim-fold.html) for improved fold display.
