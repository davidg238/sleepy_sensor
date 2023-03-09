# Reporting data from a 'sleepy' device

If you have a sensor which is to be monitored by a battery powered device, power conservation is a primary concern.  From the size of battery and device componentry, a power budget can be determined, for how long the battery will last before being discharged.  Often the processor has the highest power demand, and manufacturers address this by providing various sleep modes.  The ESP32 is no different.

In Toit, when you write `sleep --ms=1_000`, the processor remains active.  To actually save power, it is necessary to call `deep_sleep duration/Duration`, part of the [esp32](https://github.com/toitlang/toit/blob/master/lib/esp32.toit) library.  This puts the ESP32 into deep sleep mode, saving several orders of magnitude of current consumption, but pausing program execution and severing any open communications links.

[MQTT](https://mqtt.org/) is a popular communications protocol for reporting data from device to server, and is thus supported in the Toit library [mqtt](https://github.com/toitware/mqtt) and by the major cloud vendors. MQTT relies upon a connected transport, so to address sleeping nodes 'MQTT For Sensor Networks' [MQTT-SN](https://www.oasis-open.org/committees/download.php/66091/MQTT-SN_spec_v1.2.pdf) was developed. MQTT-SN supports non-connected transports and limited channel bandwidth. As the ESP32 in this example uses WiFi, channel bandwidth is not an issue, but being able to run on UDP, allows the device to deep sleep. MQTT-SN relies upon a gateway, to translate the MQTT-SN messges to MQTT.  

A useful reference for all things MQTT is [Practical MQTT with Steve](http://www.steves-internet-guide.com/)

In this show and tell, 3 features are demonstrated:  
  - an application to monitor a BME280 sensor, deep_sleeping most of the time to conserve power
  - a very simple MQTT-SN client, a protocol designed for sleepy devices
  - in a development scenario, how to keep the connection to Jaguar responsive

The code is just proof-of-concept and not production ready.


## The application

The application looks 'normal', other than the last expression `esp32.deep_sleep (Duration --m=15)`.  Rather than the application terminating after the last expression is evaluated, the ESP32 enters deep sleep for (at most) the duration, after which the application is restarted from the beginning.  No program state is carried to the next invocation, unless explicitly stashed in say [FlashStorage](https://libs.toit.io/device/class-FlashStore).

## A very simple MQTT-SN client

Rather than writing a complete MQTT-SN client, I took advantage of **Section 6.8 Publish with QoS Level -1** (aka QoS3) of the specification:
```
This feature is defined for very simple client implementations which do not support any other features except this one.  
There is no connection setup nor tear down, no registration nor subscription.  
The client just sends its PUBLISH messages to a GW (whose address is known a-priori by the client) and forgets them.  
It does not care whether the GW address is correct, whether the GW is alive, or whether the messages arrive at the GW.
```
This allowed for a tiny client, that could simply report the BME280 temperature, humidity and pressure values.  Payloads lengths are restricted by UDP packet size, so if you experiment with this sample, beware.  A short sleep is inserted between the last PUBLISH and closing the client, as I noticed the last message was not delivered to the server without it, but I did not spend a lot of time tuning/debugging this.

## In development, working with Jaguar and sleepy devices

Referencing v1.0 code:

When the ESP32 enters deep_sleep, it is no longer responsive to the Jaguar CLI.  This is a real nuisance, especially if your code executes quickly, you lose CLI access to the target device.  (You can recover by re-flashing the device, explicitly nominating the port, like `jag flash --port /dev/ttyUSB0`)

Assuming the development target is 'within reach', an alternative is to dedicate a gpio to a wake-on-pin [trigger](https://github.com/toitlang/toit/blob/master/examples/triggers/gpio.toit). A test on `esp32.wakeup_cause` is used to determine the reason for the device coming out of deep_sleep, in this case either the deep_sleep duration timer expiring or wake-on-pin trigger.  If the latter, simply sleep the device for a period, to give the Jaguar CLI time to connect.  I chose one minute as a relaxed window to connect, however 10 seconds is likely the minimum to allow WiFi to start and the Jaguar client on the target be responsive to CLI commands.

Finally, as pointed out in a Discord [thread](https://discordapp.com/channels/918498540232253480/1027095521074090034), 'Programs that should survive a reboot or deep sleep need to be installed as a container:
```
jag container install sleeper sleepy_sensor.toit
```

Referencing the v2.0 code:

To minimize power comsumption the radio should only be enabled periodically, to report data.  To ensure the radio is only powered at intervals determined by user code, it is necessary to exclude JAG from the device, otherwise every time the device emerges from deep sleep, JAG will power the radio on and begin listening for console commands.

Using the technique noted in [toit-zygote](https://github.com/kasperl/toit-zygote), run the Makefile
```
make firmware
```
then flash via a serial connection:
```
jag flash --exclude-jaguar build/firmware.envelope
```


# Setup and test

The following was tested on an Ubuntu 20.04 desktop running Jaguar v1.7.1, communicating with an [ESP32 Feather](https://www.ezsbc.com/product/esp32-feather/), wired to a BME280 and a trigger input on pin 32.  (These detailed instructions are for v1.0.x of the software).  

### Setup and test MQTT-SN

1. On the desktop, download and make [Really Small Message Broker](https://github.com/eclipse/mosquitto.rsmb).  On an IPv4 network, as Toit is of this writing, the `broker.config` might look like:
    ```
      trace_output protocol

      # normal MQTT listener
      listener 1883 INADDR_ANY

      # MQTT-S listener
      listener 1885 INADDR_ANY mqtts

      # optional multicast groups to listen on
      # multicast_groups 224.0.18.83

      #This will advertise the Gateway address to clients
      # optional advertise packets parameters: address, interval, gateway_id
      # advertise 225.0.18.83:1885 30 33
    ```
    As noted in the **rsmb** build notes, create a rsmb execution directory, with the following files:
    - broker (the broker executable)
    - broker.config (as above)
    - broker_mqtts (the MQTT-SN gateway executable)
    - Message.1.3.0.2


2) Open a **gateway** terminal window and start the rsmb SN gateway with `./broker_mqtts broker.config`
3) Download and make [MQTT-SN-Tools](https://github.com/njh/mqtt-sn-tools)
4) To begin testing your setup, open a **subscriber** terminal window in the `mqtt-sn-tools` directory, and execute
    ```
    ./mqtt-sn-sub -t t_ -p 1885
    ```
    which subscribes to messages on topic `t_` on the mqtt-sn gateway at localhost:1885
4) Open a **publisher** terminal window in the `mqtt-sn-tools` directory and execute
    ```
    ./mqtt-sn-pub -p 1885 -t t_ -q -1 -m 12.4
    ```
    which publishes the message `12.4` on topic `t_` to the gateway on localhost:1885
5) If your setup is working, you should see in the **gateway** terminal:  

    ```
    20221013 210534.358 4 127.0.0.1:35065  <- MQTT-S PUBLISH msgid: 0 qos: -1 retained: 0
    20221013 210534.358 4 127.0.0.1:38631 mqtt-sn-tools-9204 -> MQTT-S PUBLISH msgid: 0 qos: 0 retained: 0 (0)
    ``` 
    showing the broker receiving the PUBLSIH and echoing it to the subscriber

    in the **subscriber** terminal, you should see `12.4`  

    Using known good tooling, you have subscribed to and published a message.

### Test sleepy_sensor sending MQTT-SN messages

6) In the `sleepy_sensor` directory, open a **JAG** terminal and run `jag flash` to install the Jaguar client on the target.
7) Open a **monitor** terminal, run `jag scan`, then `jag monitor` to monitor the device target.
8) In the **JAG** terminal, run `jag container install sleeper sleepy_sensor.toit` to install the application container on the target.  The response should be like:
    ```
        Installing container 'sleeper' from 'sleepy_sensor.toit' on 'illegal-sweet' ...
        Success: Sent 53KB code to 'illegal-sweet'
    ```
9) In the **monitor** terminal, when the runtime first boots, you should see:
    ```
    ets Jul 29 2019 12:21:46

    rst:0x1 (POWERON_RESET),boot:0x13 (SPI_FAST_FLASH_BOOT)
    configsip: 0, SPIWP:0xee
    clk_drv:0x00,q_drv:0x00,d_drv:0x00,cs0_drv:0x00,hd_drv:0x00,wp_drv:0x00
    mode:DIO, clock div:2
    load:0x3fff0030,len:320
    load:0x40078000,len:13216
    load:0x40080400,len:2964
    entry 0x400805c8
    E (577) psram: PSRAM ID read error: 0xffffffff
    E (578) spiram: SPI RAM enabled but initialization failed. Bailing out.
    [toit] INFO: starting <v2.0.0-alpha.33>
    [toit] DEBUG: clearing RTC memory: invalid checksum
    [wifi] DEBUG: connecting
    [wifi] DEBUG: connected
    [wifi] INFO: network address dynamically assigned through dhcp {ip: 192.168.0.245}
    [jaguar] INFO: running Jaguar device 'illegal-sweet' (id: '671d7655-3a2e-4af7-9d46-5964ef15b14d') on 'http://192.168.0.245:9000'
    [jaguar] INFO: container 'sleeper' installed and started
    ntp: 462697h13m57.301756842s ±55.475272ms
    Device: c259116f-11df-5b74-ae84-09c2e1345a79  Time: 2022-10-14T04:27:02Z
    Publishing via MQTT-SN to 192.168.0.130:1885 on topics, "t_": 27.2, "h_": 36.4, "p_": 968.9
    Entering deep sleep for 60000ms

    ```
    showing the runtime booting, the application running and then entering deep sleep

10) In the **gateway** terminal, you should periodically see:
    ```
    20221013 213624.809 4 192.168.0.245:53707  <- MQTT-S PUBLISH msgid: 0 qos: -1 retained: 0
    20221013 213624.810 4 127.0.0.1:38631 mqtt-sn-tools-9204 -> MQTT-S PUBLISH msgid: 0 qos: 0 retained: 0 (0)
    20221013 213624.810 4 192.168.0.245:53707  <- MQTT-S PUBLISH msgid: 0 qos: -1 retained: 0
    20221013 213624.810 4 192.168.0.245:53707  <- MQTT-S PUBLISH msgid: 0 qos: -1 retained: 0

    ```
    which is the three messages published to the broker, one of which the topic `t_`is echoed to the subscriber.
    In the **subscriber** terminal, you should see the actual temperature.

### Test working with Jaguar

11) Then periodically as the device target exits deep_sleep, in the **monitor** terminal, you should see:
    ```
    ets Jul 29 2019 12:21:46

    rst:0x5 (DEEPSLEEP_RESET),boot:0x13 (SPI_FAST_FLASH_BOOT)
    configsip: 0, SPIWP:0xee
    clk_drv:0x00,q_drv:0x00,d_drv:0x00,cs0_drv:0x00,hd_drv:0x00,wp_drv:0x00
    mode:DIO, clock div:2
    load:0x3fff0030,len:320
    load:0x40078000,len:13216
    load:0x40080400,len:2964
    entry 0x400805c8
    E (51) psram: PSRAM ID read error: 0xffffffff
    E (51) spiram: SPI RAM enabled but initialization failed. Bailing out.
    [toit] INFO: starting <v2.0.0-alpha.33>
    [jaguar] INFO: container 'sleeper' started
    [wifi] DEBUG: connecting
    [wifi] DEBUG: connected
    [wifi] INFO: network address dynamically assigned through dhcp {ip: 192.168.0.245}
    [jaguar] INFO: running Jaguar device 'illegal-sweet' (id: '671d7655-3a2e-4af7-9d46-5964ef15b14d') on 'http://192.168.0.245:9000'
    ntp: -195.066433ms ±76.358866ms
    Device: c259116f-11df-5b74-ae84-09c2e1345a79  Time: 2022-10-14T04:53:53Z
    Publishing via MQTT-SN to 192.168.0.130:1885 on topics, "t_": 26.9, "h_": 37.6, "p_": 969.0
    Entering deep sleep for 60000ms
    ```
    It is essential the WiFi be fully started before attempting the NTP correction or MQTT-SN publish, hence the 10s sleep on line 25 of `sleepy_sensor.toit`

12) Now since the target device is mostly deep_sleeping, if in the **JAG** terminal you attempt to use the Jaguar CLI `jag container list`, it will fail with an error like:
    ```
    
    Error: Get "http://192.168.0.245:9000/list": dial tcp 192.168.0.245:9000: connect: no route to host
    Usage:
      jag container list [flags]

    Flags:
      -d, --device string   use device with a given name, id, or address
      -h, --help            help for list

    ```
    The target device is in deep_sleep and thus un-responsive to network traffic.

13) The gpio trigger is leveraged to wake the application, by raising pin 32 to rail rather than ground. The test on `esp32.wakeup_cause` on line 34, rather than measuring the BME280, simply sleeps, giving the Jaguar CLI a window to access the target.
    ```
    ets Jul 29 2019 12:21:46

    rst:0x5 (DEEPSLEEP_RESET),boot:0x13 (SPI_FAST_FLASH_BOOT)
    configsip: 0, SPIWP:0xee
    clk_drv:0x00,q_drv:0x00,d_drv:0x00,cs0_drv:0x00,hd_drv:0x00,wp_drv:0x00
    mode:DIO, clock div:2
    load:0x3fff0030,len:320
    load:0x40078000,len:13216
    load:0x40080400,len:2964
    entry 0x400805c8
    E (51) psram: PSRAM ID read error: 0xffffffff
    E (51) spiram: SPI RAM enabled but initialization failed. Bailing out.
    [toit] INFO: starting <v2.0.0-alpha.33>
    [jaguar] INFO: container 'sleeper' started
    [wifi] DEBUG: connecting
    [wifi] DEBUG: connected
    [wifi] INFO: network address dynamically assigned through dhcp {ip: 192.168.0.245}
    [jaguar] INFO: running Jaguar device 'illegal-sweet' (id: '671d7655-3a2e-4af7-9d46-5964ef15b14d') on 'http://192.168.0.245:9000'
    ntp: -365.861535ms ±137.612945ms
    Opening window for JAG connect .................

    ................. closing window for JAG connect
    Entering deep sleep for 60000ms
    ```

    When you see `Opening window for JAG connect ..` in the **monitor** terminal, you have a chance to interact with the target in the **JAG** terminal.  
    If you re-issue the list command now, the containers will be listed:
    ```
    DEVICE          IMAGE                                  NAME
    illegal-sweet   5ae0a7dd-6276-5e0d-92cd-1473fa5890fa   sleeper
    illegal-sweet   453b7dcb-5794-5ec2-8875-b476e7de498f   jaguar
    ```
    When you see `.. closing window for JAG connect`, the CLI is unavailable again and program execution has resumed.  
    The gpio trigger thus enables an edit/run development cycle, with deep_sleep code.


