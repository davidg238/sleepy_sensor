import .admin show MiniStore

main:

  buffer := MiniStore "lite"


  print "store size $buffer.size"


  buffer.add "hello"

  print "store size $buffer.size  after add"
