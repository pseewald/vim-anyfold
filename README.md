# AnyFold Vim plugin

Generic folding mechanism based on indentation. Fold anything that is structured into indented blocks.


## Introduction

This Vim plugin comes with the following features:
* Folding mechanism based on visually indented blocks that has a very intuitive and predictable behaviour.
* Results comparable to syntax aware folding methods but generic algorithm that does not rely on language specific rules.
* Shortcuts to toggle folds and to navigate to beginning / end of a block and to previous / next indented block.
* Can be configured for new filetypes in less than 5 minutes.
* Can handle corner cases with ease (comments, varying indentation widths, line breaks).

It has the following shortcomings:
* Can **not** correctly fold mismatched indentation and thus should only be used together with disciplined programming style (or in combination with Vim's `equalprg` autoindent feature).
* It uses Vim's fold-expr and thus may have slow startup times for large files.
* Indent based text objects not implemented - for that I recommend [vim-indent-object](https://github.com/michaeljsmith/vim-indent-object).


## Quick default setup for the impatient

1. Install this plugin with a vim plugin manager.
2. Add the following lines to your vimrc (if not already present).

    ```vim
    filetype plugin indent on
    let anyfold_activate=1
    set foldlevel=0
    ```

    Choose a higher foldlevel if you prefer to have folds open by default.
3. Use the spacebar to toggle folds and key combinations `[[` and `]]` to navigate to the beginning and end of the current open fold.


## Full setup and usage

1. Make sure that `filetype plugin indent on` is in your vimrc. Install this plugin with a vim plugin manager of your choice (e.g. [Pathogen](https://github.com/tpope/vim-pathogen)).
2. Take a look at the contents of ftplugin directory. If there is a file `<your-filetype>.vim` for the filetype you want to use, AnyFold already supports this filetype. If not, copy the file `filetype.vim.template` to `<your-filetype>.vim` and replace `<nindent>` and `<comment>` with the defaults you think are most appropriate for your filetype.
3. You need to activate AnyFold in your vimrc, otherwise it will not do anything. You can activate it for all supported filetypes by adding

    ```vim
    let anyfold_activate=1
    ```

    or, alternatively, activate it only for a selected filetype (e.g. python) with

    ```vim
    autocmd Filetype python let anyfold_activate=1
    ```

4. The behaviour of folds is defined by the vim option `foldlevel`. To close all folds when opening a file, add

    ```vim
    set foldlevel=0
    ```

    or choose a higher value to open some or all folds.
5. You have successfully set up AnyFold and you are ready to try it out. For most cases, using the spacebar to toggle folds is the most convenient way of dealing with folds. If you'd like to open only one fold at a time, use `zo` instead of spacebar. Read further to learn more functionality.
6. Use the key combinations `[[` and `]]` to navigate to the beginning and end of the current block. Use `]k` and `[j` to navigate to the end of the previous block and to the beginning of the next block.
7. In order to quickly fix indentation when needed, you can either use Vim's integrated `equalprg`, or set up an external autoindenter with AnyFold by

    ```vim
    autocmd Filetype <my-filetype> let anyfold_equalprg=<my-indent-command>
    ```

    The external program `<my-indent-command>` needs to be in your PATH and must accept its input via `stdin` and return the indented text to `stdout`.
    If you need to pass arguments to `<my-indent-command>`, add them via

    ```vim
    autocmd Filetype <my-filetype> let anyfold_equalprg_args='<arg1> <arg2> <...>'
    ```

    Auto-indenting is invoked with `=` (`gg=G` to indent the entire file). Of course Vim's option `equalprg` can be set directly but this is not recommended. If `anyfold_equalprg` is set, AnyFold will take care that `=` is undone if it fails (in contrast to Vim's default behaviour which replaces the text by an error message).
8. AnyFold's minimalistic display of closed fold assumes that folds are highlighted by your color scheme. If that is not the case, consider installing a suitable color scheme or highlight folds yourself by a command similar to

    ```vim
    hi Folded term=underline
    ```


## Options

All options can be either set globally

```vim
let <option>=<value>
```

or filetype specific

```vim
autocmd Filetype <filetype> let <option>=<value>
```

`0, 1` values have the meaning `off, on`.

Option | Values | Default value |  Description
------ | -------------- | ------------- | ------------
`anyfold_nindent` | integer | filetype specific | Indentation width
`anyfold_fold_display` | 0, 1 | 1 | Improved display of closed folds
`anyfold_equalprg` | string | filetype specific | External executable for equalprg
`anyfold_equalprg_args` | string | filetype specific | Arguments for external equalprg
`anyfold_toggle_key` | string | '\<space\>' | Key to toggle folds recursively
`anyfold_motion` | 0, 1 | 1 | Map motion commands to `[[`, `]]`, `[j`, `]k`
`anyfold_auto_reload` | 0, 1 | 1 | Automatically reload folds on write
`anyfold_ftsettings` | 0, 1 |  1  | Use AnyFold's recommended filetype defaults
`anyfold_docu_fold` | 0, 1 | 0 | Fold documentation boxes (experimental)


## Contributing

Don't hesitate to get in touch with me if you have any suggestions or comments. You are encouraged to contribute to this project:
* If you add new filetypes to the plugin, please contribute it to the project by *pull request*.
* If you find bugs or if you don't like this plugin, create an *issue* before giving up on this plugin.
* If you find that this plugin does not behave as you'd like for a given filetype, create an *issue*.


## License

Copyright 2016 Patrick Seewald
