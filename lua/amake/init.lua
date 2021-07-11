local JOBS = require('amake.jobs')
local M = {}

-- TODO sort jobs by the list,
-- there cannot be two jobs fighting to place the output in the same list
--
-- { [job_name]: job_id | nil }
local current_jobs = {}

local function logger(severity, msg)
    if severity < 1 then
        return nil
    end
    local g_severity = vim.g.amake_debug_severity
    if g_severity == nil then
        return nil
    end
    if severity < g_severity then
        return nil
    end
    local to_print = 'Amake('..severity..'): '

    print(to_print .. msg)
end

-- returns merged default and user jobs
local function get_known_jobs()
    -- Default jobs
    local result = JOBS.jobs

    -- Assign user jobs
    local amake_jobs = vim.g.amake_jobs
    if amake_jobs == nil then
        return result
    end
    if type(amake_jobs) ~= 'table' then
        print('amake.nvim: g:amake_jobs is set to a non table value. Ignoring')
        return result
    end

    for k,v in pairs(amake_jobs) do
        if type(v) == 'table' then
            result[k] = v
            if type(v.msg_success) ~= 'string' then
                result[k].msg_success = JOBS.default_fields.msg_success
            end
            if type(v.msg_error) ~= 'string' then
                result[k].msg_error = JOBS.default_fields.msg_error
            end
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

    vim.o.errorformat = job.error_format

    local lines = vim.split(output, '\n')

    -- empty quickfix list before populating it
    vim.fn.setqflist({})


    -- TODO pass line to nvim command
    for _, line in pairs(lines) do
        -- an attempt to pass data from lua to vim land
        vim.g.amake_line = line
        -- using output to make sure it behaves synchronously
        vim.api.nvim_command_output('caddexpr g:amake_line')
    end
    -- open quickfix window if not empty
    vim.cmd('cwindow')

    -- restore errorformat
    vim.o.errorformat = old_error_format

    if (vim.bo.syntax ~= 'qf') then
        local success_msg_template = job.msg_success or JOBS.default_fields.msg_success
        -- if syntax is not "quickfix" than we have no errors
        print(vim.fn.substitute(success_msg_template, '{{job}}', job.name, ''))
    else
        local err_count = vim.fn.len(vim.fn.getqflist())
        local err_msg_template = job.msg_error or JOBS.default_fields.msg_error
        local count_replaced = vim.fn.substitute(err_msg_template, '{{count}}', err_count, '')
        local job_replaced = vim.fn.substitute(count_replaced, '{{job}}', job.name, '')
        -- error message
        print(job_replaced)
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

    if known_jobs[job_name] == nil then
        local str_keys = table.concat(keys(known_jobs), '/')
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
            output = output .. table.concat(data, '\n')

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
        known_jobs[job_name].cmd,
        callbacks
    )

    current_jobs[job_name] = job_id

    print('Amake: started executing "' .. job_name .. '" job...')
end

function M.list_jobs()
    print(vim.inspect(get_known_jobs()))
end

function M.setup(options)
    options = options or {}

    vim.g.amake_jobs = options.jobs or {}
end

return M
