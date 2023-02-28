// Copyright 2022, 2023 Ekorau LLC
import device show hardware_id
import gpio
import i2c
import bme280
import ntp

import gpio.adc
import esp32

import encoding.tison
import .sn_qos3_client
import .ezsbc

/*
Refer to:
  https://docs.toit.io/tutorials/starter/temperature/
  https://github.com/toitlang/toit/blob/master/examples/triggers/gpio.toit
*/

// Transmit data after each measurement.

GATEWAY ::= "192.168.0.130"  // Substitute with your MQTT-SN gateway

main:

  board := ESP32Feather
  board.on
  
  // device := board.bus.device 0x77
  // bme := bme280.Driver device

  message ::= "{\"ti\": \"$Time.now.local\", \"id\": \"$board.short_id\", \"v\": $(%.3f board.battery_voltage)}"
  print message

  client := SN_QoS3_Client --gateway=GATEWAY
  client.open
  client.publish_string "d_" message
  sleep --ms=2_000 // Appear to need time before closing the socket, to allow last message to flow.
  client.close

  esp32.deep_sleep (Duration --m=1)

