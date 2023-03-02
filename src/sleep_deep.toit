import esp32
import system.storage as storage
import .ezsbc

import .admin

board := ESP32Feather

main:

  print "starting"

  val := "{\"ti\": \"$Time.now.s_since_epoch\"}"
  deque := MiniStore "lite"

  deque.add val

  print "storing $val, size then $deque.size"

  if deque.size >= 4:
    while deque.has_more:
      print "data: $deque.remove_first"
    print "buffer emptied, size now $deque.size"

  esp32.deep_sleep (Duration --s=15)