#!/usr/bin/env bash

set +x
cloudsource_url=http://download.suse.de/ibs/home:/comurphy:/Fake:/Cloud:/8:/A/bootstrap_copy
image_mirror_url=http://provo-clouddata.cloud.suse.de/images/openstack/x86_64
echo cloudsource URL is $cloudsource_url
image_id_compute=cleanvm-jeos-SLE12SP3
echo compute node image $image_id_compute
echo

git_automation_repo='https://github.com/cmurphy/automation'
git_automation_branch='master'
build_pool_name=''
build_pool_size='0'

set -ex
JOB_NAME=colleen
STACK_NAME=cloud-ci-openstack-ardana-${BUILD_NUMBER}
if [ -n "${JOB_NAME}" ]; then
    STACK_NAME=${STACK_NAME}-${JOB_NAME}
fi
CLOUD_CONFIG_NAME=engcloud-cloud-ci
cat - > stack_env <<EOF
BUILD_POOL_NAME="$build_pool_name"
BUILD_POOL_SIZE="$build_pool_size"
STACK_NAME="$STACK_NAME"
CLOUD_CONFIG_NAME="$CLOUD_CONFIG_NAME"
EOF

export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_KEEP_REMOTE_FILES=1
# the name for the cloud defined in ~./config/openstack/clouds.yaml

# init the git tree
rm -r automation-git
git clone $git_automation_repo --branch $git_automation_branch automation-git
pushd automation-git/scripts/jenkins/ardana/

#case $model in
#    standard)
#        num_controller=3
#        num_compute=3
#        ;;
#    std-split|std-3cp|dac-3cp)
#        num_controller=3
#        num_compute=1
#        ;;
#    std-min)
#        num_controller=2
#        num_compute=1
#        ;;
#    std-3cm)
#        num_controller=1
#        num_compute=3
#        ;;
#    dac-min*)
#        num_controller=0
#        num_compute=1
#        ;;
#    deployerincloud*)
        num_controller=0
        num_compute=2
#        ;;
#    *)
#        num_controller=1
#        num_compute=2
#        ;;
#esac

model=deployerincloud-lite

openstack --os-cloud $CLOUD_CONFIG_NAME stack create --timeout 5 --wait \
    -t heat-ardana-${model}.yaml  \
    --tags "$build_pool_name" \
    --parameter image_id_compute=$image_id_compute \
    --parameter number_of_computes=$num_compute \
    --parameter number_of_controllers=$num_controller \
    $STACK_NAME

DEPLOYER_IP=$(openstack --os-cloud $CLOUD_CONFIG_NAME stack output show $STACK_NAME deployer-ip-floating -c output_value -f value)
NETWORK_MGMT_ID=$(openstack --os-cloud $CLOUD_CONFIG_NAME stack output show $STACK_NAME network-mgmt-id -c output_value -f value)
sshargs="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
# FIXME: Use cloud-init in the used image
sshpass -p linux ssh-copy-id -o ConnectionAttempts=120 $sshargs root@${DEPLOYER_IP}
pushd ansible
cat << EOF > hosts
[hosts]
$DEPLOYER_IP ansible_user=root
EOF

cat hosts

cat << EOF > ardana_net_vars.yml
---
deployer_mgmt_ip: $(openstack --os-cloud $CLOUD_CONFIG_NAME stack output show $STACK_NAME deployer-net-mgmt-ip -c output_value -f value)
EOF

echo "controller_mgmt_ips:" >> ardana_net_vars.yml
for ip in $(openstack --os-cloud $CLOUD_CONFIG_NAME stack output show $STACK_NAME controllers-net-mgmt-ips -c output_value -f value); do
    cat << EOF >> ardana_net_vars.yml
    - $ip
EOF
done

echo "compute_mgmt_ips:" >> ardana_net_vars.yml
for ip in $(openstack --os-cloud $CLOUD_CONFIG_NAME stack output show $STACK_NAME computes-net-mgmt-ips -c output_value -f value); do
    cat << EOF >> ardana_net_vars.yml
    - $ip
EOF
done

# Get the IP addresses of the dns servers from the mgmt network
echo "mgmt_dnsservers:" >> ardana_net_vars.yml
openstack --os-cloud $CLOUD_CONFIG_NAME port list --network $NETWORK_MGMT_ID \
          --device-owner network:dhcp -f value -c 'Fixed IP Addresses' | \
    sed -e "s/^ip_address='\(.*\)', .*$/\1/" | \
    while read line; do echo "  - $line" >> ardana_net_vars.yml; done;

cat ardana_net_vars.yml

ansible-playbook -v -i hosts ssh-keys.yml
ansible-playbook -v -i hosts -e "build_url=$BUILD_URL" \
                             -e "cloudsource=${cloudsource}" \
                             -e "repositories='${repositories}'" \
                             repositories.yml
verification_temp_dir=$(ssh $sshargs root@$DEPLOYER_IP \
                          "mktemp -d /tmp/ardana-job-rpm-verification.XXXXXXXX")
ansible-playbook -v -i hosts -e "deployer_floating_ip=$DEPLOYER_IP" \
                             -e "deployer_model=${model}" \
                             -e "verification_temp_dir=$verification_temp_dir" \
                             init.yml

## Run site.yml outside ansible for output streaming
#ssh $sshargs ardana@$DEPLOYER_IP "cd ~/scratch/ansible/next/ardana/ansible ; \
#     ansible-playbook -vvv -i hosts/verb_hosts site.yml"

## Run Update if required
#if [ -n "$update_cloudsource" -a "$update_cloudsource" != "$cloudsource" -o -n "$update_repositories" ]; then
#
#    # Run pre-update checks
#    ansible-playbook -v -i hosts \
#        -e "image_mirror_url=${image_mirror_url}" \
#        -e "tempest_run_filter=${tempest_run_filter}" \
#        pre-update-checks.yml
#
#    ansible-playbook -v -i hosts \
#        -e "build_url=$BUILD_URL" \
#        -e "cloudsource=${update_cloudsource}" \
#        -e "repositories='${update_repositories}'" \
#        repositories.yml
#
#    ansible-playbook -v -i hosts \
#        -e "cloudsource=${update_cloudsource}" \
#        -e "update_method=${update_method}" \
#        update.yml
#fi

# Run post-deploy checks
ansible-playbook -v -i hosts \
    -e "image_mirror_url=${image_mirror_url}" \
    -e "tempest_run_filter=${tempest_run_filter}" \
    -e "verification_temp_dir=$verification_temp_dir" \
    post-deploy-checks.yml
