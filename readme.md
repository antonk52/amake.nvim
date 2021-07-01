# Amake.nvim

Asynchronous `:make` for neovim

Make/build/lint/test execution without blocking your work flow. Executes defined commands and populated quickfix window with errors found.

## Install

Using [vim-plug](https://github.com/junegunn/vim-plug) or your favorite plugin manager

```vim
Plug 'antonk52/amake.nvim'
```

## Commands

- `:Amake <job>` - executes `job`
- `:AmakeJobs` - lists known jobs

## Configuration

amake.nvim has a default dictionary of jobs which can be extended by settings `g:amake_jobs`.

A job is a table/dictionary that can have following properties:

- `cmd` command to execute a job(table or dictionary) **required**
- `error_format` used to match error from command output(string) for syntax see `:help errorformat` **required**
- `msg_success` printed when command had no errors(string)
- `msg_fail` printed when command had errors(string)

For message fields you can use placeholders for:

- `{{count}}` error count
- `{{job}}` job name

Jobs can be setup using vimscript or lua. See examples.

```vim
" vim
let g:amake_jobs = {
  \ 'typescript': {
  \     'cmd': ['npx', 'tsc', '--noEmit'],
  \     'error_format': '%E\ %#%f\ %#(%l\\\,%c):\ error\ TS%n:\ %m,%C%m',
  \     'msg_success': 'No errors!',
  \     'msg_error': '{{job}}: {{count}} errors found',
  \   }
  \ }
```

or

```lua
-- lua
require('amake').setup({
    jobs = {
        typescript = {
            cmd = {'npx', 'tsc', '--noEmit'},
            -- note that each `\` has to be escaped
            error_format = '%E\\ %#%f\\ %#(%l\\\\\\,%c):\\ error\\ TS%n:\\ %m,%C%m',
            msg_success = 'No errors!',
            msg_error = '{{job}}: {{count}} errors found',
        }
    }
})
```
