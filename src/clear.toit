import .admin as admin

main:
  admin.BufferStore.clear
  print "cleared, size now $admin.BufferStore.size"