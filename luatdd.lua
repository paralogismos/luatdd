-- luatdd.lua
-- A simple TDD framework for Lua.
-- Public
local M = {}
local version = "0.2.0"
local err = false
local check = true
local nocheck = false

-- Private
local RED = "\x1b[31m"
local GRN = "\x1b[32m"
local NRM = "\x1b[0m"
local pass = GRN .. "Passed:" .. NRM
local fail = RED .. "FAILED:" .. NRM

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
function catch_errors (f, objp, ...)
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
function capture_output(f, ...)
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

local function print_ste_status (ste, ste_passed, ste_failed, ste_passing)
   local msg
   if ste_passing then
      local tst = ste_passed == 1 and "test" or "tests"
      msg = string.format("%s %d %s in %s\n", pass, ste_passed, tst, ste)
   else
      local tst = ste_failed == 1 and "test" or "tests"
      msg = string.format("%s %d %s in %s\n", fail, ste_failed, tst, ste)
   end
   io.write(msg)
end

-- `run_tests(tests)` takes a table of test functions in the form:
--   { this_test = function (args) body end, }
-- as its argument, runs the tests and prints a report.
local function run_tests (tests)
   local call_source = debug.getinfo(2, 'S').source -- This could fail...
   call_source = call_source:match("[^/]*.lua")
   local ste_passing = true
   local ste_passed, ste_failed = 0, 0
   io.write(string.format("Running %s\n", call_source))
   for test_name, test_proc in pairs(tests) do
      local ok, test_passing = pcall(test_proc)
      if not ok then
         ste_passing = false
         ste_failed = ste_failed + 1
         print_test_fail(string.format("Missing test_proc(): %s", test_passing))
      elseif not test_passing then
         ste_passing = false
         ste_failed = ste_failed + 1
      else
         ste_passed = ste_passed + 1
      end
      print_test_status(test_name, test_passing)
   end
   print_ste_status(call_source, ste_passed, ste_failed, ste_passing)
   if ste_passing then
      os.exit(true)
   else
      os.exit(false)
   end
end

-- Public Interface
-- Constants
M.version = version
M.err = err
M.check = check
M.nocheck = nocheck

-- Functions
M.deep_equal = deep_equal
M.catch_errors = catch_errors
M.capture_output = capture_output
M.run_tests = run_tests
M.print_test_pass = print_test_pass
M.print_test_fail = print_test_fail

return M
