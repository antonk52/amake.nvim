local M = {}

-- TODO sort jobs by the list,
-- there cannot be two jobs fighting to place the output in the same list
--
-- { [job_name]: job_id | nil }
local current_jobs = {}

local default_job_description = {
    cmd = {'npx', 'tsc', '--noEmit'},
    error_format='%E\\ %#%f\\ %#(%l\\\\\\,%c):\\ error\\ TS%n:\\ %m,%C%m',
    msg_success = 'No errors!',
    msg_error = '{{count}} errors found',
}

local function logger(severity, msg)
    if severity < 1 then
        return nil
    end
    if vim.fn.exists('g:amake_debug_severity') ~= 1 then
        return nil
    end
    local g_severity = vim.api.nvim_get_var('amake_debug_severity')
    if severity < g_severity then
        return nil
    end
    local to_print = 'Amake('..severity..'): '

    print(to_print .. msg)
end

local function get_known_jobs()
    -- Default jobs
    local result = {
        tsc = default_job_description,
        typescript = default_job_description,
    }

    -- Assign user jobs
    if vim.fn.exists('g:amake_jobs') == 1 then
        local amake_jobs = vim.api.nvim_get_var('amake_jobs')
        if type(amake_jobs) == 'table' then
            for k,v in pairs(amake_jobs) do
                if type(v) == 'table' then
                    result[k] = v
                    if type(v.msg_success) ~= 'string' then
                        result[k].msg_success = default_job_description.msg_success
                    end
                    if type(v.msg_error) ~= 'string' then
                        result[k].msg_error = default_job_description.msg_error
                    end
                else
                    -- TODO
                end
            end
        else
            print('amake.nvim: g:amake_jobs is set to a non table value. Ignoring')
        end
    end

    return result
end

local function keys(table)
    local result = {}
    for k,_ in pairs(table) do
        table.insert(result, k)
    end
    return result
end

local function populate_qf(output, job)
    local old_error_format = vim.o.errorformat

    vim.o.errorformat = default_job_description.error_format

    local lines = vim.fn.split(output, '\n')

    -- empty quickfix list before populating it
    vim.fn.setqflist({})


    -- TODO pass line to nvim command
    for _, line in pairs(lines) do
        -- an attempt to pass data from lua to vim land
        vim.api.nvim_set_var('amake_line', line)
        vim.api.nvim_command_output('caddexpr g:amake_line')
    end
    -- open quickfix window if not empty
    vim.api.nvim_command_output('cwindow')

    -- restore errorformat
    vim.o.errorformat = old_error_format

    if (vim.bo.syntax ~= 'qf') then
        -- if syntax is not "quickfix" than we have no errors
        print(job.msg_success)
    else
        -- error message
        print(vim.fn.substitute(job.msg_error, '{{count}}', vim.fn.len(vim.fn.getqflist()), ''))
    end
end

function M.init(job_name)
    logger(3, 'init job_name: '..job_name)
    local known_jobs = get_known_jobs()

    if known_jobs[job_name] == nil then
        print('Unknown job ' .. job_name)
        return nil
    end
    -- check if such job_name is currently executing
    -- if so, kill it and print log to the user
    if current_jobs[job_name] ~= nil then
        -- stop the job
        vim.fn.jobstop(current_jobs[job_name])
        -- remove the job from currently executing
        vim.fn.remove(current_jobs, job_name)
        -- DO NOT DELETE
        print('job '..job_name..' has been canceled')
    end

    if vim.fn.has_key(known_jobs, job_name) == 0 then
        local str_keys = vim.fn.join(keys(known_jobs), '/')
        print('Unknown job name "' .. job_name .. '", provide one of ' .. str_keys)
        return nil
    end

    local output = ''

    -- @param job_id number
    -- @param data table
    -- @param event string: 'output' | 'stderr' | 'exit'
    local callbacks = {
        on_stdout = function(_, data, event)
            logger(3, 'on_stdout ' .. event)
            output = output .. vim.fn.join(data, '\n')

            return nil
        end,

        on_stderr = function(_, data, event)
            logger(3, 'on_stderr ' .. event)
            logger(3, vim.inspect(data))
        end,

        on_exit = function(_, _, event)
            logger(3, 'on_exit ' .. event)
            populate_qf(output, known_jobs[job_name])

            -- drop_table_key(current_jobs, job_name)
            current_jobs[job_name] = nil
        end,
    }

    local job_id = vim.fn.jobstart(
        default_job_description.cmd,
        callbacks
    )

    current_jobs[job_name] = job_id
end

function M.list_jobs()
    print(vim.inspect(get_known_jobs()))
end

return M
