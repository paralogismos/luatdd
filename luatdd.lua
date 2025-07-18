-- luatdd.lua
-- A simple TDD framework for Lua.
-- Public
local M = {}
local version = "0.3.0"
local err = false
local check = true
local nocheck = false

-- Private
local RED = "\x1b[31m"
local GRN = "\x1b[32m"
local NRM = "\x1b[0m"
local pass = GRN .. "Passed:" .. NRM
local fail = RED .. "FAILED:" .. NRM

-- Utility Functions

-- `plural('word', n)` returns 'word' when `n` is 1,
-- or 'words' for any other value of `n`.
local function plural(s, n)
   return n == 1 and s or s .. "s"
end

-- `table_inspect(t)` prints a readable representation of  table `t`.
-- This seems like it might be useful, but I'm not sure it belongs in this module.
-- This function also needs more scrutiny, and maybe a rewrite; at a minimum I'll
-- probably change the function signature to `(t)`, and define a helper function
-- to make recursive calls with extra arguments.
local function table_inspect(t, ...)
   local depth, parent = ...
   depth = depth or 0
   parent = parent or ""
   for k, v in pairs(t) do
      if depth > 0 then
         if type(v) == 'table' then
            table_inspect(v, depth+1, parent .. string.format("[%s]", k))
         else
            io.write(string.format("%s[%s] = %s\n",
                                   tostring(parent),
                                   tostring(k),
                                   tostring(v)))
         end
      elseif type(v) == 'table' then
         table_inspect(v, 1, parent .. string.format("[%s]", k))
      else
            io.write(string.format("[%s] = %s\n",
                                   tostring(k),
                                   tostring(v)))
      end
   end
end

-- `deep_equal(a, b)` returns `true` if `a` and `b` are of the same type, and
-- if `a` and `b` are scalars and compare `==`
-- or if `a` and `b` are tables such that every key in `a` occurs in `b` with
-- the same value, and every key in `b` occurs in `a` with the same value.
local function deep_equal (a, b)
   local ta, tb = type(a), type(b)
   if ta ~= tb then return false end
   if ta == "table" then
      local acount = 0
      for k, v in pairs(a) do  -- All keys in `a` occur in `b` with same values?
         acount = acount + 1
         if not b[k] or not deep_equal(v, b[k]) then
            return false
         end
      end
      local bcount = 0
      for k, _ in pairs(b) do  -- There are no extra keys in `b`?
         bcount = bcount + 1
      end
      if acount == bcount then
         return true
      else
         return false
      end
   else
      return a == b  -- `a` and `b` are not tables: simple comparison.
   end
end

-- `catch_errors(f, objp, ...)` calls `f` with arguments `...`.
-- If no error is raised in the function call, then all values
-- returned from the function call are returned by `catch_errors`.
-- If `opjp` is `check` and an error is raised in the function call,
-- then the error object is returned (stripped of metadata).
-- If `objp` is `nocheck` and an error is raised in the funciton call,
-- then `false` is returned.
local function catch_errors (f, objp, ...)
   local result = table.pack(pcall(f, ...))
   if result[1] == true then
      table.remove(result, 1)
      return table.unpack(result)
   else
      if objp then
         -- Strip error message metadata.
         local _, p = string.find(result[2], ':%d*: ')
         return string.sub(result[2], p+1)
      else
         return false
      end
   end
end

-- `capture_output(f, ...)` calls `f` with arguments `...` and returns a string
-- containing all lines written to default output during the function call,
-- followed by any values returned by the call to `f`.
-- Multiple lines written to the output result in a string with newlines delimiting
-- each individual line, but there is no final newline.
local function capture_output(f, ...)
   -- Create temporary file to collect output.
   local tf = io.tmpfile()

   -- Redirect default output.
   local save_defout = io.output()
   io.output(tf)

   -- `print` calls `fputs`, so need to wrap this in call to `io.output`,
   -- but only if default output is `stdout`.
   local save_print
   if save_defout == io.stdout then
      save_print = print
      print = function (...)
         io.output():write(...)
      end
   end

   -- Call `f` and save the return values.
   local r = table.pack(pcall(f, ...))

   -- Restore output configuration.
   if save_print then print = save_print end
   io.output(save_defout)

   -- Report attempt to call missing function.
   if r[1] then
      table.remove(r, 1)
   else
      io.write(string.format("Missing test_proc(): %s", r[2]))
      r = {}
   end

   tf:flush()
   tf:seek('set')
   local ls = tf:read('a')
   return ls, table.unpack(r)
end

-- `print_fail(msg)` prints a failing message followed by a newline.
local function print_test_fail (msg)
   msg = msg or " - "
   io.write(string.format("....%s %s\n", fail, msg))
end

-- `print_pass(msg)` prints a passing message followed by a newline.
local function print_test_pass (msg)
   msg = msg or " - "
   io.write(string.format("....%s %s\n", pass, msg))
end

local function print_test_status (test_name, status)
   local msg
   if status then
      msg = string.format("..%s %s\n", pass, test_name)
   else
      msg = string.format("..%s %s\n", fail, test_name)
   end
   io.write(msg)
end

local function print_mod_status (mod, tests_passed, tests_failed, mod_passing)
   local msg
   if mod_passing then
      msg = string.format("%s %d %s in %s\n", pass,
                          tests_passed, plural("test", tests_passed), mod)
   else
      msg = string.format("%s %d %s in %s\n", fail,
                          tests_failed, plural("test", tests_failed), mod)
   end
   io.write(msg)
end

-- `test_module(mod)` takes a table of test functions in the form:
--   { this_test = function (args) body end, }
-- as its argument, runs the tests and prints a report.
local function test_module (mod, call_site)
   local call_site = call_site:match('(.*)%.lua$')
   local mod_passing = true
   local tests_passed, tests_failed = 0, 0
   io.write(string.format("Running %s\n", call_site))
   for test_name, test_proc in pairs(mod) do
      local ok, test_passing = pcall(test_proc)
      if not ok then
         mod_passing = false
         tests_failed = tests_failed + 1
         print_test_fail(string.format("Missing test_proc(): %s", test_passing))
      elseif not test_passing then
         mod_passing = false
         tests_failed = tests_failed + 1
      else
         tests_passed = tests_passed + 1
      end
      print_test_status(test_name, test_passing)
   end
   print_mod_status(call_site, tests_passed, tests_failed, mod_passing)
   if mod_passing then
      return true
   else
      return false
   end
end

-- `run_tests(mod)` runs all of the tests in a module
-- and returns the numbers of passing and failing tests.
local function run_tests (mods)
   local pass_count, fail_count = 0, 0
   for _, mod in ipairs(mods) do
      local m = dofile(mod)
      if test_module(m, mod) then
         pass_count = pass_count + 1
      else
         fail_count = fail_count + 1
      end
   end
   return pass_count, fail_count
end

-- Public Interface

-- Constants
M.version = version
M.err = err
M.check = check
M.nocheck = nocheck

-- Functions
M.deep_equal = deep_equal
-- M.deftest = deftest
M.catch_errors = catch_errors
M.capture_output = capture_output
M.test_module = test_module
M.run_tests = run_tests
M.print_test_pass = print_test_pass
M.print_test_fail = print_test_fail
M.plural = plural
M.table_inspect = table_inspect

return M
