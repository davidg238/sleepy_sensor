import system.storage
import esp32

bucket := storage.Bucket.open --flash "/admin"


main:

  bucket["mail"] = [ ]