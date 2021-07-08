#!/bin/bash
cd /install-prometheus

chmod +x kubectl-bin/kubectl.sh
./kubectl-bin/kubectl.sh

chmod +x prometheus/prometheus-install.sh
cd prometheus && ./prometheus-install.sh

