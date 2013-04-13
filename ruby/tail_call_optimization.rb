
# enables tail call optimization in ruby 1.9.x
# see Ruby MRI / ​vm_opts.h

RubyVM::InstructionSequence.compile_option = {
  :tailcall_optimization => true,
  :trace_instruction => false
}
