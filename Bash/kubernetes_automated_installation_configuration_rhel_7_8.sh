#!/bin/bash

###############################################################################################
# Script: kubernetes_installation_configuration_script_emre.sh
# Author: Ibrahim Emre Asan
# Version & Date: 1.0 & 06/2023
# Description: This is a bash script for installing Kubernetes cluster on RHEL 7 and 8.
# Note: This script has been tested on CentOS 7.9 and 8.5. No problem has been encountered.
###############################################################################################
# Tip 1: "configure_etc_hosts" function and "kubeadm init --pod-network-cidr", "hostname -I" commands must be configured according to the environment.
# Tip 2: The manual operations required for the worker nodes to join the cluster are specified in the "setup_kubernetes_worker" function.
# Tip 3: If you have the firewalld service disabled, you can disable the call of the "configure_firewall_*" functions in the "setup_kubernetes_*" functions.
###############################################################################################


# Disable SWAP
disable_swap() {
    sudo sed -i '/swap/d' /etc/fstab
    sudo swapoff -a
}

# SELinux configuration
set_selinux_to_permissive() {
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
}

# Update Iptables Settings
update_iptables_settings() {
	sudo sh -c 'cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF'
	sysctl --system
}

# Configure Firewall (Master Node)
configure_firewall_master() {
    sudo firewall-cmd --permanent --add-port=6443/tcp
    sudo firewall-cmd --permanent --add-port=2379-2380/tcp
    sudo firewall-cmd --permanent --add-port=10250/tcp
    sudo firewall-cmd --permanent --add-port=10251/tcp
    sudo firewall-cmd --permanent --add-port=10252/tcp
    sudo firewall-cmd --permanent --add-port=10255/tcp
    sudo firewall-cmd --reload
}

# Configure Firewall (Worker Nodes)
configure_firewall_worker() {
    sudo firewall-cmd --permanent --add-port=10251/tcp
    sudo firewall-cmd --permanent --add-port=10255/tcp
    firewall-cmd --reload
}

# Configuring the Kubernetes repository
configure_kubernetes_repo() {
	sudo sh -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF'
}

# Configuring the /etc/hosts file & change the following lines according to your hosts
configure_etc_hosts() {
    sudo bash -c 'echo -e "192.168.20.153\tmaster-153" >> /etc/hosts'
    sudo bash -c 'echo -e "192.168.20.157\tnode-157" >> /etc/hosts'
    sudo bash -c 'echo -e "192.168.20.167\tnode-167" >> /etc/hosts'
}

# Load/Enable br_netfilter kernel module and make persistent
br_netfilter_persistent() {
    sudo modprobe br_netfilter
    sudo sh -c "echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables"
    sudo sh -c "echo '1' > /proc/sys/net/bridge/bridge-nf-call-ip6tables"
    sudo sh -c "echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf"
    sudo sh -c "echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf"
}



# Installing Docker and Kubernetes
install_docker_kubernetes() {
    # Installing Docker
    sudo yum -y install yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker
    # The following sed command has been added to avoid "CRI v1 runtime API is not implemented" error, then we restart containerd
    sed -i 's/^disabled_plugins = \["cri"\]/#&/' /etc/containerd/config.toml
    sudo systemctl restart containerd
    sudo systemctl enable containerd

    # Installing Kubernetes
    sudo yum -y makecache fast
    sudo yum -y install kubelet kubeadm kubectl
    systemctl enable kubelet
}

# Set Up Kubernetes master node
setup_kubernetes_master() {
    # Configure master firewall
    configure_firewall_master
	
    # Create Cluster with kubeadm at Master & change the following Network and CIDR values according to your environment
    sudo kubeadm init --pod-network-cidr=192.168.20.0/22
    echo "We will use the 'kubeadm join ...' command to add the worker nodes to the cluster after running the same script for the each worker node, so save the command in this output"

    # Copying the config file of Kubernetes
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    # Set Up Pod Network
    sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
}

# Set Up Kubernetes worker nodes
setup_kubernetes_worker() {
    # Configure worker firewall
    configure_firewall_worker
	
    # Creating config file of Kubernetes then filling it manually
    mkdir -p $HOME/.kube
    touch $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    echo "now first copy the lines of '$HOME/.kube/config' file in master node and paste it into the kubeconfig file via command 'vi $HOME/.kube/config' in this worker node,"
    echo "then run the 'kubeadm join ...' command output we saved after the master installation on this running node,"
    echo "then check the result with 'kubectl get nodes' command."
}



# MAIN WORKFLOW
disable_swap
set_selinux_to_permissive
br_netfilter_persistent
configure_kubernetes_repo
# I recommend editing the /etc/hosts file before the script runs, so I left "configure_etc_hosts" function turned off below
#configure_etc_hosts
install_docker_kubernetes
update_iptables_settings

# Performing master node operations & replace the following value with the "hostname -I" command output of your master
if [[ $(hostname -I) =~ "192.168.20.153" ]]; then
    setup_kubernetes_master
else
    # Performing worker node operations
    setup_kubernetes_worker
fi
