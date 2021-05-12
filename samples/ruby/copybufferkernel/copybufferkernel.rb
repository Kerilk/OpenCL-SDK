require 'optparse'

options = { platform: 0, device: 0 }
OptionParser.new do |parser|
  parser.banner = "Usage: ruby #{File.basename($PROGRAM_NAME)} [options]"
  parser.on("-p", "--platform INDEX", Integer, "Index of the platform to use (default 0)")
  parser.on("-d", "--device INDEX", Integer, "Index of the device to use (default 0)")
end.parse!(into: options)

require 'opencl_ruby_ffi'
require 'narray_ffi'

kernel_string = <<EOF
kernel void CopyBuffer( global uint* dst, global uint* src )
{
    uint id = get_global_id(0);
    dst[id] = src[id];
}
EOF

buffer_size = 1024 * 1024

p = OpenCL.platforms[options[:platform]]
raise "Invalid platform index #{options[:platform]}" unless p
d = p.devices[options[:device]]
raise "Invalid device index #{options[:device]}" unless d
puts "Running on platform: #{p.name}"
puts "Running on device: #{d.name}"

c = OpenCL.create_context(d)
q = c.create_command_queue(d)

program = c.create_program_with_source(kernel_string)
begin
  program.build
rescue
  puts "Compilation of program failed:"
  program.build_log.each { |device, log|
    _, status = program.build_status(device)
    puts " - #{device.name} (#{status}):"
    puts log
  }
  #something is wrong with the platform, exit gracefully
  exit
end

device_src = c.create_buffer(buffer_size*OpenCL::UInt.size, flags: OpenCL::Mem::ALLOC_HOST_PTR)
device_dst = c.create_buffer(buffer_size*OpenCL::UInt.size, flags: OpenCL::Mem::ALLOC_HOST_PTR)

_, host_ptr = q.enqueue_map_buffer(device_src, OpenCL::MapFlags::WRITE_INVALIDATE_REGION, blocking: true)
arr = NArray.to_na(host_ptr, NArray::INT)
buffer_size.times { |i| arr[i] = i }
q.enqueue_unmap_mem_object(device_src, host_ptr)

program.CopyBuffer(q, [buffer_size], device_dst, device_src)

_, host_ptr = q.enqueue_map_buffer(device_dst, OpenCL::MapFlags::READ, blocking: true)
arr = NArray.to_na(host_ptr, NArray::INT)
buffer_size.times { |i|
  raise "invalid copy: wanted #{i}, got #{arr[i]}" unless arr[i] == i
}
q.enqueue_unmap_mem_object(device_dst, host_ptr)

puts "Success."
