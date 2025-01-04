configuration  FloodingC{
    provides interface  Flooding;
}

implementation{
    components FloodingP;
    Flooding = FloodingP.Flooding;

    components new AMSenderC(AM_PACK);
    FloodingP.AMSend -> AMSenderC;

    components new TimerMilliC() as timer;
    FloodingP.TimeOut -> timer;

    components new AMReceiverC(AM_PACK);
    FloodingP.Receive -> AMReceiverC;
    FloodingP.Packet -> AMReceiverC;
}