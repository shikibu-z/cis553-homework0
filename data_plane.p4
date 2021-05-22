// Name: Junyong Zhao
// PennKey: junyong

/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>


/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

header ethernet_t {
    bit<48> dstAddr;
}

struct headers_t {
    ethernet_t  ethernet;
}


struct local_variables_t {
}


/*************************************************************************
***********************  P A R S E   P A C K E T *************************
*************************************************************************/

parser cis553Parser(packet_in packet,
                    out headers_t hdr,
                    inout local_variables_t metadata,
                    inout standard_metadata_t standard_metadata) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}


/*************************************************************************
***********************  I N G R E S S  **********************************
*************************************************************************/

control cis553Ingress(inout headers_t hdr,
                      inout local_variables_t metadata,
                      inout standard_metadata_t standard_metadata) {
    action aiForward(bit<9> egress_port) {
        // for hw0, use passed in egress port
        standard_metadata.egress_spec = egress_port;
    }
    table tiForward {
        key = {
            hdr.ethernet.dstAddr : exact;
        }
        actions = {
            aiForward;
        }
    }

    apply {
        tiForward.apply();
    }
}


/*************************************************************************
***********************  E G R E S S  ************************************
*************************************************************************/

control cis553Egress(inout headers_t hdr,
                     inout local_variables_t metadata,
                     inout standard_metadata_t standard_metadata) {
    apply { }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control cis553VerifyChecksum(inout headers_t hdr,
                             inout local_variables_t metadata) {
     apply { }
}


/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   ***************
*************************************************************************/

control cis553ComputeChecksum(inout headers_t hdr,
                              inout local_variables_t metadata) {
    // The switch handles the Ethernet checksum.
    // We don't need to deal with this.
    apply { }
}


/*************************************************************************
*************************  E M I S S I O N    ****************************
*************************************************************************/

control cis553Deparser(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.ethernet);
    }
}


/*************************************************************************
****************************  S W I T C H  *******************************
*************************************************************************/

V1Switch(cis553Parser(),
         cis553VerifyChecksum(),
         cis553Ingress(),
         cis553Egress(),
         cis553ComputeChecksum(),
         cis553Deparser()) main;
