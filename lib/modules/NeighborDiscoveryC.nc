configuration NeighborDiscoveryC {
    provides interface NeighborDiscovery; 
}

implementation {
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;

    components new AMSenderC(AM_PACK);
    NeighborDiscoveryP.AMSend-> AMSenderC;

    components new TimerMilliC() as timer;
    NeighborDiscoveryP.Timer->timer;

    components new AMReceiverC(AM_PACK);
    NeighborDiscoveryP.Receive->AMReceiverC;
    NeighborDiscoveryP.Packet->AMReceiverC;
}