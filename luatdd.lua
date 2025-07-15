-- luatdd.lua
-- A simple TDD framework for Lua.
local M = {}

local version = "0.2.0"
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
      local test_passing = test_proc()
      if not test_passing then
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
M.version = version
M.deep_equal = deep_equal
M.run_tests = run_tests
M.print_test_pass = print_test_pass
M.print_test_fail = print_test_fail

return M
