# CRPropa3 v3.2.1 + JupyterLab
# Base: Ubuntu 22.04 (ships SWIG 4.0.2, satisfying CRPropa's >= 4.0.2 requirement)
FROM ubuntu:22.04

# Avoid interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    # Build tools
    build-essential \
    cmake \
    git \
    pkg-config \
    # Python
    python3 \
    python3-dev \
    python3-pip \
    python3-numpy \
    # SWIG (>= 4.0.2 required for CRPropa's builtin option)
    swig \
    # FFTW3 with single precision (required for turbulent magnetic field grids)
    libfftw3-dev \
    libfftw3-single3 \
    # HDF5
    libhdf5-dev \
    # muParser (optional but useful for CRPropa expressions)
    libmuparser-dev \
    # zlib
    zlib1g-dev \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# ── Python packages ───────────────────────────────────────────────────────────
RUN pip3 install --no-cache-dir \
    jupyterlab \
    notebook \
    numpy \
    scipy \
    matplotlib \
    healpy \
    # CRDB Python client (Cosmic Ray DataBase)
    crdb

# ── Build CRPropa3 v3.2.1 from source ────────────────────────────────────────
WORKDIR /opt

RUN git clone --depth 1 --branch v3.2.1 https://github.com/CRPropa/CRPropa3.git

WORKDIR /opt/CRPropa3/build

RUN cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DENABLE_PYTHON=ON \
    -DENABLE_SWIG_BUILTIN=ON \
    -DENABLE_FFTW3F=ON \
    -DENABLE_HDF5=ON \
    -DDOWNLOAD_DATA=ON \
    && make -j$(nproc) \
    && make install

# Make sure Python can find the crpropa module
ENV PYTHONPATH=/usr/local/lib/python3/dist-packages:$PYTHONPATH

# ── Jupyter configuration ─────────────────────────────────────────────────────
RUN mkdir /notebooks
WORKDIR /notebooks

EXPOSE 8888

CMD ["jupyter", "lab", \
     "--ip=0.0.0.0", \
     "--port=8888", \
     "--no-browser", \
     "--allow-root", \
     "--NotebookApp.token=''", \
     "--NotebookApp.password=''"]
