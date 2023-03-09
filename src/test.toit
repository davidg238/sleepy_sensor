import system.storage
import esp32
import encoding.tison

// bucket_f := storage.Bucket.open --flash "/admin"
bucket := storage.Bucket.open --ram "/admin"

main:

  // list := bucket.get "mail" --if_absent= (: bucket["mail"] = [])
  // list := bucket.get "mail" --init= (:[])
  // print "list = $(bucket["mail"])"

  list := bucket.get "mail" --init= : []
  print "list = $bucket["mail"]"
  add Time.now.s_since_epoch
  if (random 10) < 9: esp32.deep_sleep (Duration --s=3)

add entry/any -> none:
  buffer := List.from bucket["mail"]
  buffer.add entry
  bucket["mail"] = buffer
