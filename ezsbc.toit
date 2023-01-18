// Copyright 2022 Ekorau LLC
import device show hardware_id
import gpio
import i2c
import ntp

import gpio.adc show Adc
import esp32
import math show pow


// Specific for ezSBC Feather.  https://github.com/EzSBC/ESP32_Feather
BATTERY_VOLTAGE ::= 35
BATTERY_SENSE ::= 2
RED_LED ::= 13

// Assignable.
WAKEUP_PIN ::= 32  // Use a pull-down resistor to pull pin 32 to ground.

class ESP32Feather:

  result/ntp.Result? := null
  rled := gpio.Pin RED_LED --output
  battery_adc/Adc := Adc (gpio.Pin BATTERY_VOLTAGE)
  battery_sense_pin := gpio.Pin BATTERY_SENSE --output  
  bus/i2c.Bus? := null

  on:
    // Wait for WiFi connection to establish.
    
    sleep --ms=5_000
    
    if esp32.wakeup_cause == esp32.WAKEUP_EXT1:
      print "Wakeup from external signal, wait on JAG to reprogram."
      wait_on_jag

    result = ntp.synchronize
    if result:
      print "ntp: $result.adjustment ±$result.accuracy"
      esp32.adjust_real_time_clock result.adjustment
    else:
      print "ntp sychronize failed"

    bus = i2c.Bus
      --sda=gpio.Pin 21
      --scl=gpio.Pin 22
    
    battery_sense_pin.set 0 // Do not sense, by default.
    init_wakeup_pin
    print "ezSBC Feather $short_id started"

  off:

  red_on -> none:
    rled.set 0
  red_off -> none:
    rled.set 1

  short_id -> string:
    return (hardware_id.stringify)[24..]

  battery_voltage -> float:
    battery_sense_pin.set 1
    sleep --ms=100
    voltage := battery_adc.get  // battery_voltage_pin.get
    battery_sense_pin.set 0
    return voltage*2.0

  init_wakeup_pin:
    pin := gpio.Pin WAKEUP_PIN
    mask := 0
    mask |= 1 << pin.num
    esp32.enable_external_wakeup mask true

  blink -> none:
    sleep --ms=1000
    red_on
    sleep --ms=1000
    red_off

  wait_on_jag -> none:
    // Give the pin a chance to go low again and for JAG to connect
    print "Opening window for JAG connect ................."
    15.repeat: blink
    print "................. closing window for JAG connect"

//  https://github.com/EzSBC/ESP32_Feather/blob/main/ESP32_Feather_Vbat_Test.ino

/*
  raw_voltage -> float:
    battery_sense_pin.set 1
    sleep --ms=100
    voltage := voltage battery_adc  // battery_voltage_pin.get
    battery_sense_pin.set 0
    return voltage

  battery_voltage -> float:
    battery_sense_pin.set 1
    sleep --ms=10
    x := 7600.0
    10.repeat:
      x = x + 200* (voltage battery_adc)// (voltage battery_voltage_pin)
    x = 0.9*x + 200* (voltage battery_adc)// (voltage battery_voltage_pin)
    battery_sense_pin.set 0
    return x/2.0

    voltage adc/Adc -> float:
    reading := adc.get // Reference voltage is 3v3 so maximum reading is 3v3 = 4095 in range 0 to 4095
    if reading < 1 or reading > 4095:
      return 0.0
  // Return the voltage after fixin the ADC non-linearity
    return linearize reading

  linearize reading/float -> float:
    return -0.000000000000016*(pow reading 4) + 0.000000000118171*(pow reading 3 ) - 0.000000301211691*(pow reading 2) + 0.001109019271794*reading + 0.034143524634089

  */  



