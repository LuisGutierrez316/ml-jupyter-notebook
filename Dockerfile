# Jupyter container used for Tensorflow
FROM jupyter/tensorflow-notebook:latest

MAINTAINER Anup Kumar, anup.rulez@gmail.com

ENV DEBIAN_FRONTEND noninteractive

# Install system libraries first as root
USER root

RUN apt-get -qq update && apt-get install --no-install-recommends -y libcurl4-openssl-dev libxml2-dev \
    apt-transport-https python-dev libc-dev pandoc pkg-config liblzma-dev libbz2-dev libpcre3-dev \
    build-essential libblas-dev liblapack-dev gfortran libzmq3-dev libyaml-dev libxrender1 fonts-dejavu \
    libfreetype6-dev libpng-dev net-tools procps libreadline-dev wget software-properties-common octave \
    protobuf-compiler libprotoc-dev \
    # IHaskell dependencies
    zlib1g-dev libtinfo-dev libcairo2-dev libpango1.0-dev && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

################################# Nvidia driver


RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/ /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl && \
    rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 10.1.243
ENV CUDA_PKG_VERSION 10-1=$CUDA_VERSION-1

RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-cudart-$CUDA_PKG_VERSION \
        cuda-compat-10-1 && \
        ln -s cuda-10.1 /usr/local/cuda && \
        rm -rf /var/lib/apt/lists/*

#RUN apt install --reinstall libcublas10

RUN echo "/usr/local/cuda-10.1/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/cuda-10.1/lib64" >> /etc/ld.so.conf.d/nvidia.conf

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
#ENV NVIDIA_DRIVER_CAPABILITIES compute,util

RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-libraries-$CUDA_PKG_VERSION \
    cuda-nvtx-$CUDA_PKG_VERSION && \
    #libnccl2=$NCCL_VERSION-1+cuda10.1 && \
    #apt-mark hold libnccl2 && \
    rm -rf /var/lib/apt/lists/*
    
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-nvml-dev-$CUDA_PKG_VERSION \
    cuda-command-line-tools-$CUDA_PKG_VERSION \
    cuda-libraries-dev-$CUDA_PKG_VERSION \
    #libnccl-dev=$NCCL_VERSION-1+cuda10.1 \
    cuda-minimal-build-$CUDA_PKG_VERSION && \
    rm -rf /var/lib/apt/lists/*

ENV LIBRARY_PATH /usr/local/cuda-10.1/lib64/stubs

ENV CUDNN_VERSION 7.6.5.32
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-10-2 \
    libcudnn7=$CUDNN_VERSION-1+cuda10.2  \
    libcudnn7-dev=$CUDNN_VERSION-1+cuda10.2 \
&& \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*

#ENV CUDNN_VERSION 8.0.4.30
#LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

#RUN apt-get update && apt-get install -y --no-install-recommends \
#    cuda-10-1 \
#    libcudnn8=$CUDNN_VERSION-1+cuda10.1  \
#    libcudnn8-dev=$CUDNN_VERSION-1+cuda10.1 \
#&& \
#    apt-mark hold libcudnn8 && \
#    rm -rf /var/lib/apt/lists/*

ENV PATH=/usr/local/cuda-10.1/bin:/usr/local/cuda/bin:/usr/bin:/usr/local/cuda-10.2/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda-10.1/lib64:/usr/lib64:/usr/local/cuda-10.2/lib64:/usr/local/cuda-10.2/targets/x86_64-linux/lib:$LD_LIBRARY_PATH

################################################

USER $NB_USER

# Python packages
RUN pip install --no-cache-dir tensorflow-gpu==2.3.1 onnx onnx-tf
# tf2onn

ADD ./startup.sh /startup.sh

USER root

RUN mkdir /import

COPY ./jupyter_notebook_config.py /home/$NB_USER/.jupyter/
ADD ./default_notebook_ml.ipynb /home/$NB_USER/tensorflow_notebook.ipynb

RUN mkdir -p /home/$NB_USER/.jupyter/custom/

ADD ./custom.js /home/$NB_USER/.jupyter/custom/custom.js
ADD ./useGalaxyeu.svg /home/$NB_USER/.jupyter/custom/useGalaxyeu.svg
ADD ./custom.css /home/$NB_USER/.jupyter/custom/custom.css

ENV DEBUG=false \
    NOTEBOOK_PASSWORD=none \
    CORS_ORIGIN=none \
    DOCKER_PORT=none \
    REMOTE_HOST=none

RUN chown -R $NB_USER:users /home/$NB_USER /import

WORKDIR /import 

CMD /startup.sh
