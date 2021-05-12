require 'opencl_ruby_ffi'

buffer_size = 1024 * 1024

p = OpenCL.platforms.first
d = p.devices.first
c = OpenCL.create_context(d)
q = c.create_command_queue(d)

puts "Running on platform: #{p.name}"
puts "Running on device: #{d.name}"

device_src = c.create_buffer(buffer_size*OpenCL::UInt.size, flags: OpenCL::Mem::ALLOC_HOST_PTR)
device_dst = c.create_buffer(buffer_size*OpenCL::UInt.size, flags: OpenCL::Mem::ALLOC_HOST_PTR)

_, host_ptr = q.enqueue_map_buffer(device_src, OpenCL::MapFlags::WRITE_INVALIDATE_REGION, blocking: true)

host_ptr.write_array_of_uint(buffer_size.times.to_a)

q.enqueue_unmap_mem_object(device_src, host_ptr)

q.enqueue_copy_buffer(device_src, device_dst)

_, host_ptr = q.enqueue_map_buffer(device_dst, OpenCL::MapFlags::READ, blocking: true)

result = host_ptr.read_array_of_uint(buffer_size)

buffer_size.times { |i|
  raise "invalid copy: wanted #{i}, got #{result[i]}" unless result[i] == i
}

puts "Success."
