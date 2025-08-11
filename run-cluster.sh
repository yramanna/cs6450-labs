#!/bin/bash
set -euo pipefail

# Configuration
ROOT="/mnt/nfs/cs6450-labs"
LOG_ROOT="${ROOT}/logs"
SERVER_NODES=("node0" "node1")  # Edit as needed
CLIENT_NODES=("node2" "node3")  # Edit as needed

# Timestamped log directory
TS=$(date +"%Y%m%d-%H%M%S")
LOG_DIR="$LOG_ROOT/$TS"
mkdir -p "$LOG_DIR"

echo "Logs will be in $LOG_DIR"

echo "Building the project..."
make

# Start servers
for node in "${SERVER_NODES[@]}"; do
    echo "Starting server on $node..."
    ssh $node "${ROOT}/bin/server > \"$LOG_DIR/server-$node.log\" 2>&1 & echo \$! > \"$LOG_DIR/server-$node.pid\""
done

# Start clients
SERVER_NODE="${SERVER_NODES[0]}"  # Use the first server node as the host for clients
for node in "${CLIENT_NODES[@]}"; do
    echo "Starting client on $node..."
    ssh $node "${ROOT}/bin/client -host $SERVER_NODE > \"$LOG_DIR/client-$node.log\" 2>&1 & echo \$! > \"$LOG_DIR/client-$node.pid\""
done

echo "Waiting for clients to finish..."
for node in "${CLIENT_NODES[@]}"; do
    echo "Waiting for client on $node to finish..."
    ssh $node "while kill -0 \$(cat \"$LOG_DIR/client-$node.pid\") 2>/dev/null; do sleep 1; done" || true
done

echo "Cleaning up server process..."
for node in "${SERVER_NODES[@]}"; do
    echo "Cleaning up server on $node..."
    ssh $node "kill \$(cat \"$LOG_DIR/server-$node.pid\") 2>/dev/null || true"
done

rm $LOG_DIR/*.pid || true

echo "Run complete. Logs in $LOG_DIR"
echo

for node in "${SERVER_NODES[@]}"; do
    awk '/ops\/s / { a[NR] = $2 } 
        END {
            n = asort(a)
            if (n % 2) 
                print "median op/s " a[(n+1)/2]
            else 
                print "median op/s " (a[n/2] + a[n/2+1]) / 2
        }' < "$LOG_DIR/server-$node.log"
done

