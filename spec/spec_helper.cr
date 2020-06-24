require "spec"

# Returns (Process::Status, STDOUT.strip, STDRER.strip)
def run(input : String, *args : String, env = nil)
  cmd = ["bin/em"]

  inp = IO::Memory.new(input)
  output = IO::Memory.new
  error = IO::Memory.new
  s = Process.run("bin/em", args, env, clear_env: false, shell: true, input: inp, output: output, error: error)
  {s, output.to_s.strip, error.to_s.strip}
end
