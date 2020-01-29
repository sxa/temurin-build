#!/bin/bash

################################################################################
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=sbin/common/constants.sh
source "$SCRIPT_DIR/../../sbin/common/constants.sh"
export PATH="/opt/freeware/bin:/usr/local/bin:/opt/IBM/xlC/13.1.3/bin:/opt/IBM/xlc/13.1.3/bin:$PATH"
# Without this, java adds /usr/lib to the LIBPATH of anything it forks which breaks linkage
export LIBPATH="/opt/freeware/lib:$LIBPATH"
export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} --with-memory-size=10000 --with-cups-include=/opt/freeware/include"

# Any version below 11
if  [ "$JAVA_FEATURE_VERSION" -lt 11 ]
then
  export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} --with-extra-ldflags=-lpthread --with-extra-cflags=-lpthread --with-extra-cxxflags=-lpthread"
fi

export BUILD_ARGS="${BUILD_ARGS} --skip-freetype"

if [ "${VARIANT}" == "${BUILD_VARIANT_OPENJ9}" ]; then
  export LDR_CNTRL=MAXDATA=0x80000000
fi
echo LDR_CNTRL=$LDR_CNTRL

# Any version above 8 (11 for now due to openjdk-build#1409
if [ "$JAVA_FEATURE_VERSION" -gt 11 ]; then
    BOOT_JDK_VERSION="$((JAVA_FEATURE_VERSION-1))"
    BOOT_JDK_VARIABLE="JDK$(echo $BOOT_JDK_VERSION)_BOOT_DIR"
    if [ ! -d "$(eval echo "\$$BOOT_JDK_VARIABLE")" ]; then
      bootDir="$PWD/jdk-$BOOT_JDK_VERSION"
      # Note we export $BOOT_JDK_VARIABLE (i.e. JDKXX_BOOT_DIR) here
      # instead of BOOT_JDK_VARIABLE (no '$').
      export ${BOOT_JDK_VARIABLE}="${bootDir}"
      if [ ! -d "${bootDir}/bin" ]; then
        mkdir -p "${bootDir}"
        wget -q -O - "https://api.adoptopenjdk.net/v3/binary/latest/${BOOT_JDK_VERSION}/ga/aix/${ARCHITECTURE}/jdk/hotspot/normal/adoptopenjdk" | tar xpzf - --strip-components=1 -C "${bootDir}"
      fi
    fi
    export JDK_BOOT_DIR="$(eval echo "\$$BOOT_JDK_VARIABLE")"
    "$JDK_BOOT_DIR/bin/java" -version 2>&1 | sed 's/^/BOOT JDK: /'
fi


if [ "${VARIANT}" == "${BUILD_VARIANT_OPENJ9}" ]; then
  export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} --disable-warnings-as-errors --with-openssl=fetched"
else
  export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} DF=/usr/sysv/bin/df"
fi

if [ "$JAVA_FEATURE_VERSION" -ge 11 ]; then
  export LANG=C
  if [ "$JAVA_FEATURE_VERSION" -ge 13 ]; then
    export PATH=/opt/freeware/bin:$JAVA_HOME/bin:/usr/local/bin:/opt/IBM/xlC/16.1.0/bin:/opt/IBM/xlc/16.1.0/bin:$PATH
    export CC=xlclang
    export CXX=xlclang++
  else
    export PATH=/opt/freeware/bin:$JAVA_HOME/bin:/usr/local/bin:/opt/IBM/xlC/13.1.3/bin:/opt/IBM/xlc/13.1.3/bin:$PATH
  fi
fi
