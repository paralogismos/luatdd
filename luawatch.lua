#! /usr/bin/env lua
-- luawatch.lua
-- Automatically run tests when files change.
local tdd = require 'luatdd'

local watch_msg = string.format("luatdd %s press CTRL-C to quit", tdd.version)
local file_pattern = ".lua$"
local match_test = "*_test.lua"

-- Get list of test modules.
local found_tests = io.popen(string.format('find -name "%s"', match_test))
local test_modules = {}
for tf in found_tests:lines() do
   test_modules[#test_modules + 1] =
      string.match(tf, "^%.[\\/](.*%.lua)$")
end

local mod_count = #test_modules
local attempt_count = 1

-- File watching loop.
local watching = true
while watching do
   io.write(string.format("\nAttempt: %s\n", attempt_count))
   pass_count, fail_count = tdd.run_tests(test_modules)
   attempt_count = attempt_count + 1

   io.write(string.format("%d passing %s in %d test %s\n",
                          pass_count, tdd.plural("module", pass_count),
                          mod_count, tdd.plural("module", mod_count)))
   if fail_count > 0 then
      io.write(string.format("%d failing %s in %d test %s\n",
                             fail_count, tdd.plural("module", fail_count),
                             mod_count, tdd.plural("module", mod_count)))
   end
   io.write(string.format("\n%s\n", watch_msg))
   watching = os.execute(
      string.format('inotifywait -rqq -e modify --include %s .', file_pattern))
end

-- I can't figure out how to suppress the "^C" when a user quits.
-- I didn't have this problem with `watch`.
-- Printing a newline makes is look less stupid.
print("")
