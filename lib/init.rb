require "set"
require "benchmark"

STDOUT.sync = true # DO NOT REMOVE
LOG_LEVEL = 1 # 0 is off

# @param relevance [Integer] the lower, the more priority. [0=off, 1=everything, 2=core, 3=timing]
def debug(message, _ = 1)
  return if LOG_LEVEL.zero?

  STDERR.puts(message)
end

# @param time [Float] seconds strsight from Benchmark.relatime
def report_time(time, message)
  return if time < 0.01 # as in 10ms

  debug("Took #{(time * 1000).round}ms to #{message}", 3)
end