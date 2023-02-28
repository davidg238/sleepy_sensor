import esp32
import system.storage as storage
import .ezsbc

import .admin

board := ESP32Feather

main:

  print "starting"
  sleepy := 15

  board.on
  // If the wakeup because of hardware pin, exit.
  if esp32.wakeup_cause == esp32.WAKEUP_EXT1:
    print ".... exiting, you have $sleepy seconds to uninstall the container! "
    return 
//  val := Time.now.s_since_epoch

  voltage := 0.0

  while true:
    // val := "{\"ti\": \"$Time.now.s_since_epoch\"}"
    // val ::= "{\"ti\": $Time.now.s_since_epoch, \"id\": \"$board.short_id\", \"v\": $(%.3f board.battery_voltage)}"
    // val ::= "{\"ti\": $Time.now.s_since_epoch, \"v\": $board.battery_voltage}"
    
    /* This works !
    voltage = random 3 5
    val ::= "{\"ti\": $Time.now.s_since_epoch, \"v\": $voltage}"
    */
    // This worked, until 7th iteration !
    voltage = (random 3 5).to_float
    val ::= "{\"ti\": $Time.now.s_since_epoch, \"v\": $voltage}"
    
    // This fails after 3 iterations
    // voltage = board.battery_voltage
    // val ::= "{\"ti\": $Time.now.s_since_epoch, \"v\": $voltage}"


    BufferStore.add val

    print "stored $val, size now $BufferStore.size"

    if BufferStore.size >= 10:
      print "buffer full, emptying"
      while BufferStore.size > 0:
        print "data: $BufferStore.remove_first"
      print "buffer emptied, size now $BufferStore.size"

    sleep --ms=5_000

