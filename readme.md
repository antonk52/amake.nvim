# Amake.nvim

Asynchronous make for neovim

Make/build/lint/test etc execution without blocking the your work flow.

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

Each job should have `cmd` and `error_format` fields. Optionally you can add `msg_success` and `msg_error` to specify messages to be printed to status line once the job has finished. `{{count}}` can be used in `msg_error` as a placeholder for the number errors found.

```vim
let g:amake_jobs = {
  \ 'typescript': {
  \     'cmd': ['npx', 'tsc', '--noEmit'],
  \     'error_format': '%E\ %#%f\ %#(%l\\\,%c):\ error\ TS%n:\ %m,%C%m',
  \     'msg_success': 'No errors!',
  \     'msg_error': '{{count}} errors found',
  \   }
  \ }
```
