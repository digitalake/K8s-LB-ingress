# K8s-LB-ingress

### <a name="road">ROADMAP</a>
  - #### [Info](#info)
  - #### [Preparing VM](#instance)
  - #### [Deploying K8s with Kubespray](#spray)
  - #### [Ingress controller instalation](#controller)
  - #### [Creating Domain name](#dn)
  - #### [Nginx deployment](#nginx)
  - #### [Ingress deployment](#ingress)
  - #### [Get certificate](#cert)
  - #### [Result](#res)


### <a name="info">SOME INFO</a> | [ROADMAP](#road)

In this project i've:
  - created VM in GCP via Terraform
  - deployed K8s single-node cluster on it with components:
    - MetalLB
    - Nginx-controller
    - Cert-manager with Let'sencrypt
    - Nginx deployment
    - Nginx service
    - Cluster issuer
    - Ingress
    
So lets go through all the stages.

### <a name="instance">VM IN GCP WITH TERRAFORM </a> | [ROADMAP](#road)

Running Terraform is useful for VM creation in Cloud envs.

VM requirenments:
  - 4 CPU
  - 8GB memory
  - 35GB disk
  - OS - Ubuntu 20.04 LTS
  - SSH key added
  
> NOTE! If clonning the repo, provide your own variables with _terraform.tfvars_ file.

VM config provided with variable (type:map of obj)
```
vms = {
  kube-master = {
    instance_type   = "custom-4-8192", # 4->CPU, 8192->MEM 
    disk_size       = "35", # boot disk size
    disk_type       = "pd-standard",
    boot_disk_image = "ubuntu-os-cloud/ubuntu-2004-lts", # providing boot disk image
    ssh_user        = "deployer",
    ssh_pub_key     = "~/.ssh/terraform_gcp.pub" # ssh key path
  }
}
```
SSH-key added by metadata:
```
...
metadata = {
    ssh-keys = "${each.value.ssh_user}:${file("${each.value.ssh_pub_key}")}"
  }
...
```
Plan the creation:
```
terraform plan
```
Apply with changes if everythink ok
```
terraform apply --auto-approve
```
Check the output:
```
terraform output
```
Output:

<img src="https://user-images.githubusercontent.com/109740456/217586807-98960315-a7b4-4a2c-9684-759c8a890ce0.png" width="400">

### <a name="spray">K8S WITH KUBESPRAY</a> | [ROADMAP](#road)

For this part its needed to clone Kubespay repo and run Docker with Kubespray inside

Clone Kubespray release  repository
```
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
git checkout release-2.20
```

Copy and edit inventory file
```
cp -rfp inventory/sample inventory/mycluster
```

Apply changes to inventory file as shown below, use public ip of the VM u've created 
```
nano inventory/mycluster/inventory.ini
```
Inventory sample:
```
[all]
node1 ansible_host=<vm-ip>

[kube_control_plane]
node1

[etcd]
node1

[kube_node]
node1

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
```

Turn on MetalLB

Edit addons.yml:
```
nano inventory\mycluster\group_vars\k8s_cluster\addons.yml
```
addons.yml sample:
```
…
metallb_enabled: true
metallb_speaker_enabled: true
metallb_avoid_buggy_ips: true
metallb_ip_range:
  - "<VM-private-ip>/32" 
…
```
Edit k8s-cluster.yml:
```
nano inventory\mycluster\group_vars\k8s_cluster\k8s-cluster.yml
```
Apply changes to k8s-cluster.yml:
```
…
kube_proxy_strict_arp: true
…
```

Run execute the Docker container with Kubespray:
```
docker run --rm -it -v <clonned-kubespray-dir-path>:/mnt \
  -v <ssh-key-dir>:/pem \
  quay.io/kubespray/kubespray:v2.20.0 bash
```

Container will start and the bash shell will appear. Go to kubespray folder and start ansible-playbook:
```
cd /mnt/kubespray
```
```
ansible-playbook -i inventory/mycluster/inventory.ini --private-key /pem/<private-key> -e ansible_user=r<ssh-user> -b  cluster.yml
```

![Знімок екрана_20230207_182020](https://user-images.githubusercontent.com/109740456/217592181-7bfdc1df-8791-4fae-adb6-89df22c0aac7.png)

After successful installation connect to VM and copy kubectl configuration file:
```
ssh -i <private-key-path> <ssh-user>@<vm-public-ip>
```
Run in cli:
```
mkdir ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chmod 777 ~/.kube/config
kubectl get nodes
```

<img src="https://user-images.githubusercontent.com/109740456/217593142-68a10c86-aff4-40b3-920f-665e57bb1477.png" width="350">


### <a name="controller">INSTALL INGRESS CONTROLLER</a> | [ROADMAP](#road)

Install Ingress-controller
```
kubectl apply -f nginx-ctl.yaml
kubectl apply -f path_provisioner.yml
```
Check the result:
```
kubectl get pods -n ingress-nginx -w
```

<img src="https://user-images.githubusercontent.com/109740456/217594014-b59306e5-de86-46f3-ae76-90e2efa3ed57.png" width="550">

```
kubectl get svc -–all-namespaces
```

![image](https://user-images.githubusercontent.com/109740456/217594512-027bae28-915d-4d43-b646-77e0d5d3d51f.png)

### <a name="dn">PREPARING THE DOMAIN NAME</a> | [ROADMAP](#road)

For this part i've used [this](https://dynv6.com/) free resource.

<img src="https://user-images.githubusercontent.com/109740456/217595248-4d4af7f7-6af8-4dde-92fd-9a2aacb1abc7.png" width="250">

### <a name="nginx">NGINX DEPLOYMENT</a> | [ROADMAP](#road)

Deploy the Nginx and Cluster-IP Service:
```
kubectl apply -f nginx-service.yaml
```
Check pods in default NS:
```
kubectl get pods
```
<img src="https://user-images.githubusercontent.com/109740456/217596807-6a223a40-341a-481c-86b0-c1b5fb91e549.png" width="450">


### <a name="ingress">INGRESS DEPLOYMENT</a> | [ROADMAP](#road)

Specify the the host in ingeress.yaml using [Domain name](#dn)

Run apply
```
kubectl apply -f ingress.yaml
```

Check the ingress:
```
kubectl get ingress
```
<img src="https://user-images.githubusercontent.com/109740456/217598186-ef358379-43b3-48bc-ba86-1a2083aa25d6.png" width="500">

### <a name="cert">GET CERTIFICATE</a> | [ROADMAP](#road)

Install cert-manager from github:
```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
```
Deploy letsencrypt:
```
kubectl apply -f staging-issuer.yaml
```
Ckeck the certificate:
```
kubectl get certificate
```

<img src="https://user-images.githubusercontent.com/109740456/217600005-5ae52cf3-fe42-478d-8b73-436c7992999d.png" width="400">

### <a name="res">CHECK THE RESULT</a> | [ROADMAP](#road)

Got to browser and search for:
```
https://<domain-name>
```
> Here's [my link](https://vantus.dns.army/) 

<img src="https://user-images.githubusercontent.com/109740456/217600637-91d8437c-b8dd-44e8-a6b4-8eac5db99233.png" width="600">














  
