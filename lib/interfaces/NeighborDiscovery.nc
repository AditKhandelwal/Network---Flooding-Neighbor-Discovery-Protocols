interface NeighborDiscovery{
  command void start(uint16_t dest, uint8_t* payload, uint8_t length);
  event message_t* receive(message_t* msg, void* payload, uint8_t len);
//   command uint32_t* getNeighbors();
//   command void printNeighbors();
}
