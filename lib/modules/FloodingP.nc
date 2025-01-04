#include "../../includes/packet.h"
#include "../../includes/protocol.h"


module FloodingP{
    provides interface Flooding;
    uses interface Receive;
    uses interface Packet;
    uses interface AMSend;
    uses interface Timer<TMilli> as TimeOut;

}

implementation{
    pack sendPackage;
    message_t pkt;
    uint8_t sourceNodeNum;
    uint16_t seq_num = 1;
    uint16_t seenPacket[256] = {0};
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

    command void Flooding.send(uint16_t dest, uint8_t* payload, uint8_t length) {
        pack* msg = (pack*) (call Packet.getPayload(&pkt, sizeof(pack)));
        makePack(msg, TOS_NODE_ID, dest, MAX_TTL, PROTOCOL_FLOOD, seq_num, payload, length);
        sourceNodeNum = TOS_NODE_ID;
        call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(pack));
        seenPacket[TOS_NODE_ID] = seq_num;
        seq_num++;
        // logPack(msg);
        dbg(FLOODING_CHANNEL, "I am %u and I am SENDING TO %u.\n", TOS_NODE_ID, msg->dest);
        call TimeOut.startOneShot(1000);
    }

    event void AMSend.sendDone(message_t* msg, error_t error){
        // dbg(GENERAL_CHANNEL, "Sent\n");
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        pack* receivedPack = (pack*) payload;
        
        // Check if the packet has been seen using both src and seq_num
        if (seenPacket[receivedPack->src] >= receivedPack->seq) {
            // dbg(FLOODING_CHANNEL, "Already seen this packet\n");
            return msg;
        }
        if (receivedPack->TTL == 0) {
            // dbg(FLOODING_CHANNEL, "TTL Expired!\n");
            return msg;
        }

        // logPack(receivedPack);
        
        // Handle acknowledgements
        if (receivedPack->dest == TOS_NODE_ID && strcmp((char*)receivedPack->payload, "ack") == 0) {
            dbg(FLOODING_CHANNEL, "acknowledgement\n");
            return msg;
        }

        // Handle packet destination
        if (receivedPack->dest == TOS_NODE_ID) {
            dbg(FLOODING_CHANNEL, "I am %u and I am acknowledging receiving a packet from %u.\n", TOS_NODE_ID, receivedPack->src);
            // Optionally send acknowledgment
            return msg;
        }

        // Process the packet and decrement TTL
        receivedPack->TTL--;
        seenPacket[receivedPack->src] = receivedPack->seq;

        // Send the packet if TTL is still positive
        if (receivedPack->TTL > 0) {
            dbg(FLOODING_CHANNEL, "I am  %u and I am flooding to my neighors.\n", TOS_NODE_ID);
            call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(pack));
        }
    }
   

    void makePack(pack* Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    event void TimeOut.fired(){
        call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(pack));
        call TimeOut.startOneShot(1000);
    }
}

