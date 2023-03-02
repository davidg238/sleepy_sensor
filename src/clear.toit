import .admin

main:
  buffer := MiniStore "lite"
  print "cleared, size now $buffer.size"