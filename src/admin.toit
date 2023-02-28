// Copyright (C) 2023 Ekorau LLC.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import device
import esp32
import system.storage as storage

GATEWAY ::= "192.168.0.130"  // Substitute with your MQTT-SN gateway.

STORE_     ::= storage.Bucket.open --ram   "/admin" // Persists between reboots.
// STORE_  ::= storage.Bucket.open --flash "/admin" // Persists between reboots and power cycles.

reboot -> none:
  esp32.deep_sleep (Duration --ms=10)


class BufferStore:

  static exists -> bool:
    return null != (STORE_.get "buffer")

  static get_buff_ -> List:
    buffer := STORE_.get "buffer"
    if not buffer: buffer = []
    return buffer

  static add entry/any -> none:
    buffer := List.from get_buff_
    buffer.add entry
    STORE_["buffer"] = buffer

  static clear -> none:
    STORE_["buffer"] = []

  static size -> int:
    return get_buff_.size

  static remove_first -> any:
    buffer := get_buff_
    entry := buffer.first
    STORE_["buffer"] = buffer[1..]
    return entry