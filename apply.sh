talosctl apply-config --insecure -n 10.1.33.11 -e 10.1.33.11 --file kubernetes/main/bootstrap/talos/clusterconfig/kube-01.yaml
talosctl apply-config --insecure -n 10.1.33.12 -e 10.1.33.12 --file kubernetes/main/bootstrap/talos/clusterconfig/kube-02.yaml
talosctl apply-config --insecure -n 10.1.33.13 -e 10.1.33.13 --file kubernetes/main/bootstrap/talos/clusterconfig/kube-03.yaml


# Workers
talosctl apply-config --insecure -n 10.1.33.14 -e 10.1.33.14 --file kubernetes/main/bootstrap/talos/clusterconfig/kube-04.yaml
talosctl apply-config --insecure -n 10.1.33.15 -e 10.1.33.15 --file kubernetes/main/bootstrap/talos/clusterconfig/kube-05.yaml


# Bootstrap etcd
talosctl bootstrap -e 10.1.33.11 --talosconfig ./kubernetes/main/talosconfig  -nodes 10.1.33.11

talosctl kubeconfig -e 10.1.33.11 --talosconfig ./talosconfig  -nodes 10.1.33.11 