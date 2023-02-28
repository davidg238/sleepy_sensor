import esp32
import system.storage as storage

import encoding.tison

main:

  print "starting"
  sleepy := 15

//  val := Time.now.s_since_epoch

  voltage := 0.0
  my_buffer := []


  while true:
    // val := "{\"ti\": \"$Time.now.s_since_epoch\"}"
    // val ::= "{\"ti\": $Time.now.s_since_epoch, \"id\": \"$board.short_id\", \"v\": $(%.3f board.battery_voltage)}"
    // val ::= "{\"ti\": $Time.now.s_since_epoch, \"v\": $board.battery_voltage}"
    
    // This works, for 3 iterations !
    voltage = random 3 5
    val ::= "{\"ti\": $Time.now.s_since_epoch, \"v\": $voltage}"
    
    // This worked, until 7th iteration !
    // voltage = (random 3 5).to_float
    // val ::= "{\"ti\": $Time.now.s_since_epoch, \"v\": $voltage}"
    
    // This fails after 3 iterations
    // voltage = board.battery_voltage
    // val ::= "{\"ti\": $Time.now.s_since_epoch, \"v\": $voltage}"

    my_buffer.add (tison.encode val)
    print "stored $val, size now $my_buffer.size"

    if my_buffer.size >= 5:
      print "buffer full, emptying"
      entry := null
      while my_buffer.size > 0:
        entry = my_buffer.first
        print "data: $entry"
        my_buffer = my_buffer[1..].copy
      print "buffer emptied, size now $my_buffer.size"

    sleep --ms=5_000

