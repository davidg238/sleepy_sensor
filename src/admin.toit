// Copyright (C) 2023 Ekorau LLC.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import device
import esp32
import system.storage as storage

GATEWAY ::= "192.168.0.130"  // Substitute with your MQTT-SN gateway.

reboot -> none:
  esp32.deep_sleep (Duration --ms=10)


class MiniStore:

  buffer_/storage.Bucket
  name /string

  constructor .name:
    buffer_ = storage.Bucket.open --flash "/admin"
    buffer_.get name --if_absent= (: buffer_[name] = [])

  add entry/any -> none:
    buffer := List.from buffer_[name]
    buffer.add entry
    buffer_[name] = buffer

  clear -> none:
    buffer_[name] = []

  has_more -> bool:
    return size > 0

  size -> int:
    return buffer_[name].size

  remove_first -> any:
    buffer := buffer_[name]
    entry := buffer.first
    buffer_[name] = buffer[1..].copy  // `copy`, so as not to store a ListSlice_
    return entry
