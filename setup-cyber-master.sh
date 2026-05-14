#!/bin/bash

# Taak 1: Genereer de mapstructuur via een Bash script
BASE_DIR="cyber-master"

echo "Creating directory structure for $BASE_DIR..."
mkdir -p "$BASE_DIR"/{recon,dfir,enrich,phishing,mail,hunting,intel,scoring,reporting,common,cache,rules,templates,config}
echo "Directory structure created successfully."
