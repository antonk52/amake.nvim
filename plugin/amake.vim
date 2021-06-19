if exists('g:amake_loaded') || &cp
  finish
end
let g:amake_loaded = 1

com! -nargs=1 Amake lua require('amake/init').init("<args>")
com! -nargs=0 AmakeJobs lua require('amake/init').list_jobs()
