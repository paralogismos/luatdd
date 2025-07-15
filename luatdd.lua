-- luatdd.lua
-- A simple TDD framework for Lua.
local M = {}

local RED = "\x1b[31m"
local GRN = "\x1b[32m"
local NRM = "\x1b[0m"
local pass = GRN .. "Passed:" .. NRM
local fail = RED .. "FAILED:" .. NRM

-- `deep_equal(a, b)` returns `true` if `a` and `b` are of the same type, and
-- if `a` and `b` are scalars and compare `==`
-- or if `a` and `b` are tables such that every key in `a` occurs in `b` with
-- the same value, and every key in `b` occurs in `a` with the same value.
local function deep_equal(a, b)
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

-- `print_fail(msg)` prints a failing message followed by a newline.
local function print_test_fail (msg)
   io.write(string.format("....%s %s\n", fail, msg))
end

-- `print_pass(msg)` prints a passing message followed by a newline.
local function print_test_pass (msg)
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

local function print_suite_status (suite, suite_passing)
   local msg
   if suite_passing then
      msg = string.format("%s %s\n", pass, suite)
   else
      msg = string.format("%s %s\n", fail, suite)
   end
   io.write(msg)
end

-- `run_tests(tests)` takes a table of test functions in the form:
--   { this_test = function (args) body end, }
-- as its argument, runs the tests and prints a report.
local function run_tests (tests)
   local call_source = debug.getinfo(2, 'S').source -- This could fail...
   call_source = call_source:match("[^/]*.lua")
   local suite_passing = true
   io.write(string.format("Running %s\n", call_source))
   for test_name, test_proc in pairs(tests) do
      local test_passing = test_proc()
      if not test_passing then
         suite_passing = false
      end
      print_test_status(test_name, test_passing)
   end
   print_suite_status(call_source, suite_passing)
end

M.deep_equal = deep_equal
M.run_tests = run_tests
M.print_test_pass = print_test_pass
M.print_test_fail = print_test_fail

return M
