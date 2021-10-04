#!/bin/bash

export PYTHON_BIN_PATH=$(which python)
export TF_CUDNN_VERSION="5"
export TF_CUDA_VERSION_TOOLKIT=8.0
export TF_CUDA_VERSION="$TF_CUDA_VERSION_TOOLKIT"
export CUDA_TOOLKIT_PATH="/usr/local/cuda-$TF_CUDA_VERSION"
export CUDNN_INSTALL_PATH="/usr/local/cuda-$TF_CUDA_VERSION"
export TF_UNOFFICIAL_SETTING=1
export TF_NEED_CUDA=1
export TF_NEED_OPENCL=0
export TF_CUDA_COMPUTE_CAPABILITIES="6.1"

# no google cloud computing
export TF_NEED_GCP=0
export GCC_HOST_COMPILER_PATH=$(which gcc)
export TF_NEED_HDFS=0


# fix issue with anaconda installation
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/python2.7/site-packages/numpy/.libs/

export PYTHON_PATH=$CONDA_PREFIX/lib/python2.7/site-packages
export USE_DEFAULT_PYTHON_LIB_PATH=1

function tf_config()
{
  ./configure
}

function tf_build()
{
    echo "building tf"
    bazel build -c opt --config cuda //tensorflow/tools/pip_package:build_pip_package
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
    echo "to install please type: sudo pip install $(ls /tmp/tensorflow_pkg/*.whl)"
}

function tf_dev_python_build()
{
    echo "building +cuda +dbg +strip pip_package"
    bazel build -c opt --config cuda -c dbg --strip=never //tensorflow/tools/pip_package:build_pip_package
}

function tf_python_build()
{
  bazel build -c opt --copt=-mavx --copt=-mavx2 --copt=-mfma \
  --copt=-mfpmath=both \
  --copt=-msse4.2 --copt=-march=native --config=cuda -k \
  --verbose_failures \
  //tensorflow/tools/pip_package:build_pip_package
}

function tf_cc_build()
{
  bazel build -c opt --copt=-mavx --copt=-mavx2 --copt=-mfma \
  --copt=-mfpmath=both --copt=-msse4.2 \
  --config=cuda -k //tensorflow:libtensorflow_cc.so 
}

function tf_dev_cc()
{
    bazel build -c opt --config cuda -c dbg --strip=never //tensorflow:libtensorflow_cc.so
}

function tf_dev_py_test()
{
     bazel test --test_output=streamed --verbose_failures -c opt --config cuda -c dbg --strip=never --test_arg $1 //tensorflow/python/
}

function tf_install_python()
{
     bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
     wheel_package=$(ls /tmp/tensorflow_pkg/*.whl)
     echo "pip install $wheel_package"
}
