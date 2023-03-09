## There seems to be something subtle going on at first execution, with --ram, after flashing the device:

How I found it:
```
david@MSI-7D43:~$ jag monitor -a
Starting serial monitor of port '/dev/ttyUSB0' ...
[jaguar] INFO: container 'sleepy' installed and started
.... ezSBC Feather 09c2e1345a79 started

******************************************************************************
As check failed: null is not a Collection.
  0: List.from                 <sdk>/core/collections.toit:180:20
  1: MiniStore.add             admin.toit:25:15
  2: monitor_tphv              sleepy_sensor.toit:37:9
  3: main                      sleepy_sensor.toit:29:3
******************************************************************************
```

#### To isolate issue

1. run: `jag flash`

2. Run script, either way:
```
  list := bucket.get "mail" --if_absent= (: bucket["mail"] = [])
//  list := bucket.get "mail" --init= (: bucket["mail"] = [])
  print "list = $(bucket["mail"])"
```

3. In the monitor window (both ways shown)

```
david@MSI-7D43:~$ jag monitor -a
Starting serial monitor of port '/dev/ttyUSB0' ...
[jaguar] INFO: denied request, header: 'X-Jaguar-Device-ID' was '42943ab1-498e-43f6-85d6-fd227f2972d3' not '95df0a5f-a9a5-46df-8b1a-ac63f3c7044d'
[jaguar] INFO: program ed2aa754-ba93-5637-a46a-1ae596ae7fce started
list = null
[jaguar] INFO: program ed2aa754-ba93-5637-a46a-1ae596ae7fce stopped
[jaguar] INFO: program 0fad244a-d0f7-5e93-ae4a-cdb98735c2ba started
list = null
[jaguar] INFO: program 0fad244a-d0f7-5e93-ae4a-cdb98735c2ba stopped
```

4. So, write to the slot explicitly `bucket["mail"] = []`, see:

```
[jaguar] INFO: program 6f924dd9-6958-59c7-a6a0-796f41798934 started
[jaguar] INFO: program 6f924dd9-6958-59c7-a6a0-796f41798934 stopped
```
5. now script works as expected
```
[jaguar] INFO: program 0fad244a-d0f7-5e93-ae4a-cdb98735c2ba started
list = []
[jaguar] INFO: program 0fad244a-d0f7-5e93-ae4a-cdb98735c2ba stopped
```

6. don't think it is tison, because:
```
foo := tison.encode []
bar := tison.decode foo
print "bar = $bar"
```
yields:
```
[jaguar] INFO: program 5d88c53d-5fdb-5bd2-be99-1820455eef70 started
bar = []
[jaguar] INFO: program 5d88c53d-5fdb-5bd2-be99-1820455eef70 stopped
```

7. Check RAM vs Flash (using script in 2.)

It is only with RAM.  
If I re-flash the unit, run with `--flash`, you see first execution is ok, get `[]`  
Edit to `--ram`, get `null`

```
david@MSI-7D43:~$ jag monitor -a
Starting serial monitor of port '/dev/ttyUSB0' ...
[jaguar] INFO: denied request, header: 'X-Jaguar-Device-ID' was '95df0a5f-a9a5-46df-8b1a-ac63f3c7044d' not '9aad8500-1d55-4a9b-82e2-8f9c6d1a4983'
[jaguar] INFO: program fee581d0-6d46-5445-a36a-8138e3874005 started
list = []
[jaguar] INFO: program fee581d0-6d46-5445-a36a-8138e3874005 stopped
[jaguar] INFO: program ed2aa754-ba93-5637-a46a-1ae596ae7fce started
list = null
[jaguar] INFO: program ed2aa754-ba93-5637-a46a-1ae596ae7fce stopped
```
8.  The trivial workaround I am using:
```
  add entry/any -> none:
    buffer := buffer_[name] == null? [] : List.from buffer_[name]

```