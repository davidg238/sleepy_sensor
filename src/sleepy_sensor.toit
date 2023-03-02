// Copyright 2022, 2023 Ekorau LLC
import device show hardware_id
import gpio
import i2c
import ntp

import gpio.adc
import esp32
import bme280
import system.storage

import encoding.tison
import .sn_qos3_client
import .ezsbc
import .admin as admin
import system.containers

/*
Refer to:
  https://docs.toit.io/tutorials/starter/temperature/
  https://github.com/toitlang/toit/blob/master/examples/triggers/gpio.toit
*/

board := ESP32Feather
message := ""

main:

  board.on
//  set_time_once

  monitor_tphv
  esp32.deep_sleep (Duration --s=15)


/*
Hack. Relies upon storage not existing, the very first time program runs.
The timestamp should be right on the first data batch.
Normally is synced at the end of data transmission.
*/
set_time_once:
  if not admin.BufferStore.exists:
    if board.network_on:
      board.network_sync
      board.network_off

monitor_tphv -> none:
  bme := bme280.Driver (board.add_i2c_device 0x77)
  message = "{\"ti\": $Time.now.s_since_epoch, \"id\": \"$board.short_id\", \"t\": $(%.1f bme.read_temperature), \"h\": $(%.1f bme.read_humidity), \"p\": $(%.1f bme.read_pressure/100), \"v\": $(%.3f board.battery_voltage)}"
  admin.BufferStore.add message
  print ".... ram: $admin.BufferStore.size, msg: $message"
  
  if admin.BufferStore.size >= 3:
    if board.network_on:
      print ".... Sending $admin.BufferStore.size messages."
      client := SN_QoS3_Client --gateway=admin.GATEWAY
      client.open
      while admin.BufferStore.size > 0:
        client.publish_string "b_" admin.BufferStore.remove_first
      sleep --ms=1_000 // Appear to need time before closing the socket, to allow last message to flow.
      print ".... Send complete."
      client.close
      board.network_sync
      board.network_off