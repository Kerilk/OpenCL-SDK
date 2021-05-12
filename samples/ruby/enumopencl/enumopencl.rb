require 'opencl_ruby_ffi'
require 'yaml'

puts YAML.dump(
{ "platforms" => OpenCL.platforms.collect { |p|
    { "name" => p.name,
      "vendor" => p.vendor,
      "version" => p.version,
      "devices" => p.devices.collect { |d|
        { "name" => d.name,
          "type" => d.type.to_s,
          "vendor" => d.vendor,
          "version" => d.version,
          "profile" => d.profile,
          "driver_version" => d.driver_version
        }
      }
    }
  }
})
