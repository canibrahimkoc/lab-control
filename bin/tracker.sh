
# journalctl Tracker
system_journalctl() {
    journalctl -f
}

# tcpdump 
system_network_tpcdump() {
    tcpdump
}

# Karnel Tracker Fllow
system_karnel_dmesg() {
   dmesg --follow
}

# Port Fllow
system_network_port() {
  ss -tuln && netstat -tulnp
}

# All Connect
system_all_connect() {
    ss -tnp
}
