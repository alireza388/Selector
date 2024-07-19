#!/bin/bash

# Function to generate a random name
generate_random_name() {
    echo $(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 10 | head -n 1)
}

# Function to prompt for API token and account ID
get_credentials() {
    read -p "Enter your Cloudflare API token: " CF_API_TOKEN
    read -p "Enter your Cloudflare account ID: " CF_ACCOUNT_ID
}

# Function to create a new Worker with a random name and custom code
create_worker() {
    local worker_name=$(generate_random_name)
    echo "Creating a new Worker with name: $worker_name"
    mkdir $worker_name
    cd $worker_name
    curl -O https://raw.githubusercontent.com/bia-pain-bache/BPB-Worker-Panel/main/_worker.js
    echo "name = \"$worker_name\"" > wrangler.toml
    echo "type = \"javascript\"" >> wrangler.toml
    echo "account_id = \"$CF_ACCOUNT_ID\"" >> wrangler.toml
    echo "workers_dev = true" >> wrangler.toml
    echo "kv_namespaces = []" >> wrangler.toml
    CF_API_TOKEN=$CF_API_TOKEN CF_ACCOUNT_ID=$CF_ACCOUNT_ID wrangler publish
    cd ..
    echo $worker_name
}

# Function to create a KV namespace with a random name
create_kv_namespace() {
    local kv_name=$(generate_random_name)
    echo "Creating KV namespace with name: $kv_name"
    CF_API_TOKEN=$CF_API_TOKEN CF_ACCOUNT_ID=$CF_ACCOUNT_ID wrangler kv:namespace create $kv_name
    echo $kv_name
}

# Function to bind a KV namespace to a Worker
bind_kv_namespace() {
    local worker_name=$1
    local kv_name=$2
    echo "Binding KV namespace $kv_name to Worker $worker_name with variable name 'bpb'"
    cd $worker_name
    echo "kv_namespaces = [{ binding = \"bpb\", id = \"$kv_name\" }]" >> wrangler.toml
    CF_API_TOKEN=$CF_API_TOKEN CF_ACCOUNT_ID=$CF_ACCOUNT_ID wrangler publish
    cd ..
}

# Main script execution
get_credentials
worker_name=$(create_worker)
kv_name=$(create_kv_namespace)
bind_kv_namespace $worker_name $kv_name

worker_url="https://${worker_name}.workers.dev/panel"
echo "Worker $worker_name created and bound to KV namespace $kv_name with variable name 'bpb'."
echo "You can visit your Worker at: $worker_url"
