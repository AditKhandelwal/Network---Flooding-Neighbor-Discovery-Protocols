#include "../../includes/packet.h"
#include "../../includes/protocol.h"

module NeighborDiscoveryP {
    provides interface NeighborDiscovery;
    uses interface Receive;
    uses interface Packet;
    uses interface AMSend;
    uses interface Timer<TMilli> as Timer;
}

implementation {
    pack sendPackage;
    message_t pkt;
    message_t rtnPkt;
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

    command void NeighborDiscovery.start(uint16_t dest, uint8_t* payload, uint8_t length) {
        pack* msg = (pack*) (call Packet.getPayload(&pkt, sizeof(pack)));
        makePack(msg, TOS_NODE_ID, dest, 1, PROTOCOL_PING, 1, payload, length);
        call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(pack));
        // call Timer.startPeriodic(1000);
    }
    
    event void AMSend.sendDone(message_t* msg, error_t error) {

    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        pack* receivedPack = (pack*) payload;
        // logPack(receivedPack);
        if (receivedPack->protocol == PROTOCOL_PING && receivedPack->TTL == 1) {
            //send dat shit back to the source node
            pack* rtnMsg = (pack*) (call Packet.getPayload(&rtnPkt, sizeof(pack)));
            makePack(rtnMsg, TOS_NODE_ID, receivedPack->dest, 1, PROTOCOL_PINGREPLY, 1, "ack", len);
            // logPack(receivedPack);
            call AMSend.send(receivedPack->src, &rtnPkt, sizeof(pack));
            return msg;
        }  
        else if (receivedPack->protocol == PROTOCOL_PINGREPLY) {
            dbg(NEIGHBOR_CHANNEL, "I am %u and a neighbor is %u.\n", TOS_NODE_ID, receivedPack->src);
        }
        return msg;
    }

    event void Timer.fired() {
        call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(pack));
        call Timer.startPeriodic(1000);
    }

    void makePack(pack* Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    
}