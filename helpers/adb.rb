require_relative 'io_stream'

module CaptainADB
  module ADB    
    def list_devices
      list = `adb devices`
      devices = list.split("\n")[1..-1].inject([]) do |devices, device|
        devices.push(device.split("\t").first)
      end
    end
    
    def list_devices_with_details
      devices = list_devices.inject({}) do |devices, device_sn|
        device_details = {}
        ['manufacturer', 'brand', 'model'].each do |property|
          cmd = "adb -s #{device_sn} shell getprop | grep 'ro.product.#{property}'"
          regex = /#{property}\]:\s+\[(.*?)\]$/
          property_value = regex.match(`#{cmd}`.chomp)
          device_details[property] = property_value ? property_value[1] : 'N/A'
        end
        devices[device_sn] = device_details
        devices
      end
    end

    def uninstall_app(package_name)
      result = `adb uninstall #{package_name}`.chomp
      if result == 'Success'
        'Uninstalled successfully.'
      elsif result == 'Failure'
        'Can not uninstall, app does not exist.'
      else # - waiting for device -
        'Please check your device connection.'
      end
    end

    def clear_app(package_name)
      result = `adb shell pm clear #{package_name}`.chomp
      if result == 'Success'
        'Cleared app\'s data & cache successfully.'
      elsif result == 'Failed'
        'Can not clear, app does not exist.'
      else # - waiting for device -
        'Please check your device connection.'
      end
    end

    def start_monkey_test(package_name, numbers_of_events = 50000)
      # `adb shell monkey -p #{package_name} -v #{numbers_of_events}`
      cmd = "adb shell monkey -p #{package_name} -v #{numbers_of_events}"
      IoStream.redirect_command_output(cmd) do |line|
        puts line
      end
    end
    
    def stop_monkey_test
      `adb shell ps | awk '/com\.android\.commands\.monkey/ { system("adb shell kill " $2) }'`
    end
  end
end