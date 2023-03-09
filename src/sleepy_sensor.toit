// Copyright 2022, 2023 Ekorau LLC
import device show hardware_id
import gpio
import i2c
import ntp

import gpio.adc
import esp32
import bme280
import system.storage

import .sn_qos3_client
import .ezsbc
import .admin show MiniStore GATEWAY
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
  monitor_tphv
  esp32.deep_sleep (Duration --m=15)
  

monitor_tphv -> none:
  bme := bme280.Driver (board.add_i2c_device 0x77)
  message = "{\"ti\": $Time.now.s_since_epoch, \"id\": \"$board.short_id\", \"t\": $(%.1f bme.read_temperature), \"h\": $(%.1f bme.read_humidity), \"p\": $(%.1f bme.read_pressure/100), \"v\": $(%.3f board.battery_voltage)}"
  store := MiniStore "lite"
  store.add message
  // print ".... $store.size, msg: $message"
  
  if store.size >= 32:
    if board.network_on:
      // print ".... Sending $store.size messages."
      client := SN_QoS3_Client --gateway=GATEWAY
      client.open
      while store.size > 0:
        message = store.remove_first
        // print ".... $store.size, msg: $message"
        client.publish_string "b_" message
      sleep --ms=1_000 // Appear to need time before closing the socket, to allow last message to flow.
      // print ".... Send complete."
      client.close
      board.network_sync
      board.network_off