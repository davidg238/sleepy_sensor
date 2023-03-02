import system.storage
import esp32

bucket := storage.Bucket.open --ram "/admin"


main:

  bucket["mail"] = [ ]