// Copyright 2022 Ekorau LLC
import device show hardware_id
import gpio
import i2c
import bme280
import ntp

import gpio.adc
import esp32

import .sn_qos3_client

/*
Refer to:
  https://docs.toit.io/tutorials/starter/temperature/
  https://github.com/toitlang/toit/blob/master/examples/triggers/gpio.toit
*/

WAKEUP_PIN ::= 32  // Use a pull-down resistor to pull pin 32 to ground.
GATEWAY ::= "192.168.0.130"  // Substitute with your MQTT-SN gateway

main:

// Wait for WiFi connection to establish
  sleep --ms=10_000
  
  result ::= ntp.synchronize
  if result:
    print "ntp: $result.adjustment ±$result.accuracy"
    esp32.adjust_real_time_clock result.adjustment
  else:
    print "ntp sychronize failed"

  if esp32.wakeup_cause == esp32.WAKEUP_EXT1:
    wait_on_jag
  else:
    monitor_tph
  init_wakeup_pin
  esp32.deep_sleep (Duration --m=1)

monitor_tph:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22
  
  device := bus.device 0x77
  bme := bme280.Driver device

  print "Device: $hardware_id  Time: $Time.now"
  print "Publishing via MQTT-SN to $GATEWAY:1885 on topics, \"t_\": $(%.1f bme.read_temperature), \"h_\": $(%.1f bme.read_humidity), \"p_\": $(%.1f bme.read_pressure/100)"
  // Temperature in C, humidity in %, pressure in hPa.

  client := SN_QoS3_Client --gateway=GATEWAY
  client.open
  client.publish "t_" "$(%.1f bme.read_temperature)"
  client.publish "h_" "$(%.1f bme.read_humidity)"
  client.publish "p_" "$(%.1f bme.read_pressure)"
  sleep --ms=10_000 // Appear to need time before closing the socket, to allow last message to flow.
  client.close
 
init_wakeup_pin:
  pin := gpio.Pin WAKEUP_PIN
  mask := 0
  mask |= 1 << pin.num
  esp32.enable_external_wakeup mask true

wait_on_jag:
  // Give the pin a chance to go low again and for JAG to connect
  print "Opening window for JAG connect ................."
  sleep (Duration --m=1)
  print "................. closing window for JAG connect"
