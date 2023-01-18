// Copyright 2022 Ekorau LLC

import bytes
import binary
import net
import net.udp

/*
packet_id is the same as msg_id in the MQTT_SN spec

Packet layout:
  Length / MsgType / Flags / TopicId / MsgId / Data 

Flag byte layout:
  DUP  QoS   Retain  Will  CleanSession  TopicIdType   Description
  (7)  (6,5) (4)     (3)   (2)           (1,0)         (bits)
*/
PUBLISH ::= 0x0C
QOS3_FLAGS ::= 0b01100010 // 0x62

class SN_QoS3_Client:

  gateway /string
  port /int
  network := null
  udp_socket := null
  server_address :=null
  packet_id := 0

  constructor --.gateway --.port=1885:

  open -> none:
    network = net.open
    udp_socket = network.udp_open
    server_address = net.SocketAddress (net.IpAddress.parse gateway) port


  publish_string topic/string data/string -> none:
    publish topic data.to_byte_array

  publish topic/string data_b/ByteArray -> none:
    /* 
    This is only for the specialized PUBLISH with QoS -1 (aka 3), defined in Section 6.8 of the MQTT-SN spec:
      https://www.oasis-open.org/committees/document.php?document_id=66091&wg_abbrev=mqtt
    "
    This feature is defined for very simple client implementations which do not support any other features except
      this one. There is no connection setup nor tear down, no registration nor subscription. The client just sends its
      PUBLISH messages to a GW (whose address is known a-priori by the client) and forgets them. It does not care
      whether the GW address is correct, whether the GW is alive, or whether the messages arrive at the GW.
    "
    ONLY short topic names are supported, not pre-defined.
    No validation is done on data size, so if the UDP packet size is exceeded, expect failure.
    */

    if topic == "" or topic.size > 2: throw "INVALID_TOPIC"
    topic_b := topic.to_byte_array

    buffer := bytes.Buffer
    min_size := data_b.size + 7
    if (min_size + 2) > udp_socket.mtu: throw "PACKET_TOO_BIG"

    if (min_size <= 255):                   // Length
      buffer.write_byte min_size
    else:
      buffer.write_byte 0x01
      buffer.write_int16_big_endian (min_size + 2)
    buffer.write_byte PUBLISH               // MsgType
    buffer.write_byte QOS3_FLAGS            // Flags
    buffer.write topic_b                    // TopicId
    buffer.write_int16_big_endian packet_id // MsgId
    buffer.write data_b                     // Data
    send_ buffer.bytes

  send_ payload/ByteArray -> none:
    msg := udp.Datagram payload server_address
    udp_socket.send msg
    packet_id++

  close -> none:
    udp_socket.close