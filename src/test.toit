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
  val := "{\"ti\": \"$Time.now.s_since_epoch\"}"

  BufferStore.add val

  print "storing $val"
  print "size $BufferStore.size after storing"

  if BufferStore.size >= 4:
    while BufferStore.size > 0:
      print "data: $BufferStore.remove_first"
    print "buffer emptied, size now $BufferStore.size"

  esp32.deep_sleep (Duration --s=15)
