# DO NOT RUN THIS SCRIPT ON DOCKER (can't do Docker on Docker)
# RUN the following script on WSL2 for example

# Check if sudo needed
sudo
if [ "$?" -le 10 ]
then
L_SUDO=sudo
else
L_SUDO=
fi

set -e

# Set env
EDGETPU_VERSION_TAG=release-grouper
TFLITE_VERSION_TAG=v2.8.0
TFLITE_VERSION_HASH=3f878cff5b698b82eea85db2b60d65a2e320850e
TFLITE_VERSION_SHA256=21d919ad6d96fcc0477c8d4f7b1f7e4295aaec2986e035551ed263c2b1cd52ee
# Findout SHA256
# git clone https://github.com/tensorflow/tensorflow.git
# cd tensorflow
# TFLITE_VERSION_HASH=`git show-ref -s ${TFLITE_VERSION_TAG}`
# cd ..
# curl -OL https://github.com/tensorflow/tensorflow/archive/${TFLITE_VERSION_HASH}.tar.gz
# TFLITE_VERSION_SHA256_RAW=`sha256sum ${TFLITE_VERSION_HASH}.tar.gz`
# TFLITE_VERSION_SHA256=(${TFLITE_VERSION_SHA256_RAW// / })


# Prepare output directory
DIR_TOP=`pwd`
DIR_ARTIFACTS=`pwd`/edgetpu_prebuilt
mkdir ${DIR_ARTIFACTS}


# Install requirements


# Get code
git clone https://github.com/google-coral/libedgetpu.git
cd libedgetpu
DIR_EDGETPU=`pwd`
git checkout ${EDGETPU_VERSION_TAG}
## Replace TENSORFLOW_COMMIT and TENSORFLOW_SHA256
sed -i s/a4dfb8d1a71385bd6d122e4f27f86dcebb96712d/${TFLITE_VERSION_HASH}/g workspace.bzl
sed -i s/cb99f136dc5c89143669888a44bfdd134c086e1e2d9e36278c1eb0f03fe62d76/${TFLITE_VERSION_SHA256}/g workspace.bzl


# Build for x64, armv7, aarch64
DOCKER_CPUS="k8 armv7a aarch64" DOCKER_IMAGE="ubuntu:18.04" DOCKER_TARGETS=libedgetpu make docker-build

mkdir -p ${DIR_ARTIFACTS}/include
cp -r out/* ${DIR_ARTIFACTS}/.
cp tflite/public/*.h ${DIR_ARTIFACTS}/include/.

# Compress artifacts
cd ${DIR_TOP}
tar czvf edgetpu_prebuilt_linux.tgz -C ${DIR_ARTIFACTS}/../ edgetpu_prebuilt
