#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Z7G4N1U8 (Peace)

# Install reclient
curl -LSs https://chrome-infra-packages.appspot.com/dl/infra/rbe/client/linux-amd64/+/latest -o reclient.zip
unzip -o -q reclient.zip -d reclient && rm reclient.zip

# Enable RBE
export USE_RBE=1
export RBE_DIR=reclient
export NINJA_REMOTE_NUM_JOBS=2048

# BuildBuddy Connection
export RBE_service=android.buildbuddy.io:443
export RBE_remote_headers=x-buildbuddy-api-key=$BB_KEY
export RBE_use_rpc_credentials=false
export RBE_service_no_auth=true

# Unified Downloads/Uploads
export RBE_use_unified_downloads=true
export RBE_use_unified_uploads=true

# Execution Strategies
export RBE_R8_EXEC_STRATEGY=remote_local_fallback
export RBE_D8_EXEC_STRATEGY=remote_local_fallback
export RBE_JAVAC_EXEC_STRATEGY=remote_local_fallback
export RBE_JAR_EXEC_STRATEGY=remote_local_fallback
export RBE_ZIP_EXEC_STRATEGY=remote_local_fallback
export RBE_TURBINE_EXEC_STRATEGY=remote_local_fallback
export RBE_SIGNAPK_EXEC_STRATEGY=remote_local_fallback
export RBE_CXX_EXEC_STRATEGY=remote_local_fallback
export RBE_CXX_LINKS_EXEC_STRATEGY=remote_local_fallback
export RBE_ABI_LINKER_EXEC_STRATEGY=remote_local_fallback
export RBE_ABI_DUMPER_EXEC_STRATEGY=
export RBE_CLANG_TIDY_EXEC_STRATEGY=remote_local_fallback
export RBE_METALAVA_EXEC_STRATEGY=remote_local_fallback
export RBE_LINT_EXEC_STRATEGY=remote_local_fallback

# Enable RBE for Specific Tools
export RBE_R8=1
export RBE_D8=1
export RBE_JAVAC=1
export RBE_JAR=1
export RBE_ZIP=1
export RBE_TURBINE=1
export RBE_SIGNAPK=1
export RBE_CXX_LINKS=1
export RBE_CXX=1
export RBE_ABI_LINKER=1
export RBE_ABI_DUMPER=
export RBE_CLANG_TIDY=1
export RBE_METALAVA=1
export RBE_LINT=1

# Resource Pools
export RBE_JAVA_POOL=default
export RBE_METALAVA_POOL=default
export RBE_LINT_POOL=default

# Timeouts
export RBE_reclient_timeout=60m
export RBE_exec_timeout=10m
