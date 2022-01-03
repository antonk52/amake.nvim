local jobs = {}

jobs.luacheck = {
    cmd = {'luacheck', '**/*.lua'},
    error_format = '%E\\ \\ \\ \\ %f:%l:%c:\\ %m,%-G%.%#',
    dev_comment = 'Make sure to pass filepaths to luacheck',
}

jobs.eslint = {
    cmd = {'npx', 'eslint', '--ext=.ts,.js,.jsx,.tsx', '--', '--format=unix'},
    error_format = '%E\\ %#%f:%l:%c:\\ %m,%-G%.%#',
    dev_comment = 'Make sure to call eslint with "--format=unix" or provide your own "error_format"',
}

jobs.tsc = {
    cmd = {'npx', 'tsc', '--noEmit'},
    error_format='%E\\ %#%f\\ %#(%l\\\\\\,%c):\\ error\\ TS%n:\\ %m,%C%m',
}

jobs.flow = {
    name = 'flow',
    cmd = {'npx', 'flow', '--timeout', '5', '--retry-if-init', 'false', '--from', 'vim'},
    error_format = '%EFile "%f"\\, line %l\\, characters %c-%.%#,%Z%m,%-G%.%#'
}

jobs.typescript = jobs.tsc

local function add_job_names(jobs_table)
    for name,_ in pairs(jobs_table) do
        jobs_table[name].name = name
    end

    return jobs_table
end

local named_jobs = add_job_names(jobs)

return {
    jobs = named_jobs,
    default_fields = {
        msg_success = '{{job}}: No errors!',
        msg_error = '{{job}}: {{count}} errors found',
    }
}
