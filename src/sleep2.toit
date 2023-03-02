import system.storage
import esp32

// with ram it fails, flash it works
bucket := storage.Bucket.open --ram "/admin"


main:

  list := bucket.get "mail"  --if_absent= (: bucket["mail"] = [ ])
  
/* the alternative loop, not using deep sleep, works for ram and flash
  5.repeat:
    print "list  $bucket["mail"]"
    add Time.now.s_since_epoch
    sleep --ms= 5_000
*/
  print "list  $bucket["mail"]"
  add Time.now.s_since_epoch
  esp32.deep_sleep (Duration --s=10)


add entry/any -> none:
    buffer := List.from bucket["mail"]
    buffer.add entry
    bucket["mail"] = buffer
