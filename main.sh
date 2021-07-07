SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd /installer

chmod +x $SCRIPTDIR/kubectl-bin/kubectl.sh
$SCRIPTDIR/kubectl-bin/kubectl.sh

chmod +x $SCRIPTDIR/prometheus/prometheus-install.sh
$SCRIPTDIR/prometheus-install.sh

