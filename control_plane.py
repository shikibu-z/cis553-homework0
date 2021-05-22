# Name: Junyong Zhao
# PennKey: junyong

import argparse
import json
import os
import sys
import threading
from time import sleep

sys.path.append("utils")
import bmv2
import helper
from convert import *


# User control plane code goes here
def RunControlPlane(sw, id_num, p4info_helper):
    # set matches for switches, hard coding
    # for h1, the egress port needs to be configured differently
    if id_num is 1:
        table_entry = p4info_helper.buildTableEntry(
            table_name="cis553Ingress.tiForward",
            match_fields={"hdr.ethernet.dstAddr": 0x000000000101},
            action_name="cis553Ingress.aiForward",
            action_params={"egress_port": 3})
        sw.WriteTableEntry(table_entry)
    elif id_num is 2:
        table_entry = p4info_helper.buildTableEntry(
            table_name="cis553Ingress.tiForward",
            match_fields={"hdr.ethernet.dstAddr": 0x000000000101},
            action_name="cis553Ingress.aiForward",
            action_params={"egress_port": 2})
        sw.WriteTableEntry(table_entry)
    elif id_num is 3:
        table_entry = p4info_helper.buildTableEntry(
            table_name="cis553Ingress.tiForward",
            match_fields={"hdr.ethernet.dstAddr": 0x000000000101},
            action_name="cis553Ingress.aiForward",
            action_params={"egress_port": 1})
        sw.WriteTableEntry(table_entry)
    else:
        pass

    # configure egress port for sending to h2 and h3
    table_entry = p4info_helper.buildTableEntry(
        table_name="cis553Ingress.tiForward",
        match_fields={"hdr.ethernet.dstAddr": 0x000000000202},
        action_name="cis553Ingress.aiForward",
        action_params={"egress_port": 1})
    sw.WriteTableEntry(table_entry)
    table_entry = p4info_helper.buildTableEntry(
        table_name="cis553Ingress.tiForward",
        match_fields={"hdr.ethernet.dstAddr": 0x000000000303},
        action_name="cis553Ingress.aiForward",
        action_params={"egress_port": 2})
    sw.WriteTableEntry(table_entry)
    sw.UpdateTableEntry(table_entry)

    while 1:
        # just stay running forever
        sleep(1)

    sw.shutdown()


# Starts a control plane for each switch. Hardcoded for our Mininet topology.
def ConfigureNetwork(p4info_file="build/data_plane.p4info",
                     bmv2_json="build/data_plane.json"):
    p4info_helper = helper.P4InfoHelper(p4info_file)

    threads = []

    print "Connecting to P4Runtime server on s1..."
    sw1 = bmv2.Bmv2SwitchConnection('s1', "127.0.0.1:50051", 0)
    sw1.MasterArbitrationUpdate()
    sw1.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                    bmv2_json_file_path=bmv2_json)
    t = threading.Thread(target=RunControlPlane, args=(sw1, 1, p4info_helper))
    t.start()
    threads.append(t)

    print "Connecting to P4Runtime server on s2..."
    sw2 = bmv2.Bmv2SwitchConnection('s2', "127.0.0.1:50052", 1)
    sw2.MasterArbitrationUpdate()
    sw2.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                    bmv2_json_file_path=bmv2_json)
    t = threading.Thread(target=RunControlPlane, args=(sw2, 2, p4info_helper))
    t.start()
    threads.append(t)

    print "Connecting to P4Runtime server on s3..."
    sw3 = bmv2.Bmv2SwitchConnection('s3', "127.0.0.1:50053", 2)
    sw3.MasterArbitrationUpdate()
    sw3.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                    bmv2_json_file_path=bmv2_json)
    t = threading.Thread(target=RunControlPlane, args=(sw3, 3, p4info_helper))
    t.start()
    threads.append(t)

    for t in threads:
        t.join()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='CIS553 P4Runtime Controller')

    parser.add_argument("-b", '--bmv2-json',
                        help="path to BMv2 switch description (json)",
                        type=str, action="store",
                        default="build/data_plane.json")
    parser.add_argument("-c", '--p4info-file',
                        help="path to P4Runtime protobuf description (text)",
                        type=str, action="store",
                        default="build/data_plane.p4info")

    args = parser.parse_args()

    if not os.path.exists(args.p4info_file):
        parser.error("File %s does not exist!" % args.p4info_file)
    if not os.path.exists(args.bmv2_json):
        parser.error("File %s does not exist!" % args.bmv2_json)

    ConfigureNetwork(args.p4info_file, args.bmv2_json)
