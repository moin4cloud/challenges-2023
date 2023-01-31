#! /bin/sh
export project_name=`gcloud config get-value project`

### case1: Code block to fetch the metadata details of all VM instances located under the project in JSON format
echo "Fetching the metadata of each VM instance under this project: "

for project in $project_name
do
    gcloud compute instances list --format="json(name, machineType, disks, metadata)" >> ${project_name}_metadata.json
    echo "JSON metadata file generated successfully"
done

### Code block to list the VM instances associated with this project
echo "List of all VM instances associated with this project: "

for project in $project_name
do
    gcloud compute instances list
done

### case2: Code block to fetch the metadata details of a single VM instance on GCP and provide JSON output file
echo "*** Getting the metadata details of a GCP VM instance ***"
echo -n "Enter the name of the VM: "
read vm_name

for project in $project_name
do
    gcloud compute instances describe $vm_name >> ${vm_name}_metadata.json
    echo "VM instance metadata JSON file generated successfully"
done

### case3: Code block to fetch a particular key value individually
echo -n "Enter the name of the key you want to retrieve value for: "
read key_name

for project in $project_name
do
    gcloud compute instances describe $vm_name --format='value[](metadata.items.'$key_name')'
done