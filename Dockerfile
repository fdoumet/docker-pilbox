FROM ubuntu:18.04
RUN apt-get -qq update && apt-get -y \
    install python3-pip python3-dev libtiff5-dev libjpeg-turbo8-dev zlib1g-dev libpng-dev\
    libxml2-dev libxslt1-dev libfreetype6-dev libwebp-dev libcurl4-openssl-dev cmake wget build-essential libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev

# Build OpenCV with TBB Enabled
RUN pip3 install numpy \
    && mkdir /opencv-src/ \
    && wget https://github.com/opencv/opencv/archive/2.4.13.6.tar.gz -O /opencv-src/opencv-2.4.13.6.tar.gz \
    && tar -xzf /opencv-src/opencv-2.4.13.6.tar.gz -C /opencv-src \
    && cd /opencv-src/opencv-2.4.13.6 \
    && mkdir build \
    && cd /opencv-src/opencv-2.4.13.6/build \
    && cmake -DBUILD_opencv_python2=False -DBUILD_opencv_python3=True -DCMAKE_CXX_STANDARD=98 -DCMAKE_C_STANDARD=99 -DCMAKE_C_EXTENSIONS=OFF -DCMAKE_CXX_EXTENSIONS=OFF -DCMAKE_CONFIGURATION_TYPES=Release -DWITH_CUDA=OFF -DWITH_CUFFT=OFF -DWITH_MATLAB=OFF -DBUILD_TBB=ON -DWITH_TBB=ON -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_EXAMPLES=OFF -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DBUILD_opencv_gpu=OFF -DBUILD_opencv_gpuarithm=OFF -DBUILD_opencv_gpubgsegm=OFF -DBUILD_opencv_gpucodec=OFF -DBUILD_opencv_gpufeatures2d=OFF -DBUILD_opencv_gpufilters=OFF -DBUILD_opencv_gpuimgproc=OFF -DBUILD_opencv_gpulegacy=OFF -DBUILD_opencv_gpuoptflow=OFF -DBUILD_opencv_gpustereo=OFF -DBUILD_opencv_gpuwarping=OFF -DPYTHON3_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.6m.so -DPYTHON3_INCLUDE_DIR=/usr/include/python3.6 -DPYTHON3_PACKAGES_PATH=/usr/lib/python3.6/dist-packages -DINSTALL_C_EXAMPLES=OFF -DBUILD_DOCS=OFF -DWITH_FFMPEG=OFF .. \
    && make -j7 \
    && make install \
    && ldconfig

RUN mkdir /wheels
RUN pip3 wheel --disable-pip-version-check --no-deps --wheel-dir /wheels https://github.com/fdoumet/pilbox/archive/master.zip
COPY requirements.txt requirements.txt
RUN pip3 wheel --disable-pip-version-check --no-deps --wheel-dir /wheels -r requirements.txt

RUN apt-get update && apt-get install -y \
    libtiff5 libxml2 libxslt1.1 libopenjp2-7 libfreetype6-dev libwebp6 libssl-dev\
    &&  apt-get autoremove -y &&  apt-get clean -y

RUN ln -s /usr/lib/x86_64-linux-gnu/libz.so /lib/
RUN ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /lib/

# Build regular Pillow here so that other libraries below try to install it themselves
RUN pip3 install pillow==5.2.0 ring==0.7.3 requests==2.22.0 pycurl==7.43.0.3
RUN pip3 install --disable-pip-version-check --no-index --no-deps /wheels/* && rm -rf /wheels requirements.txt
# Replace Pillow with Pillow-SIMD. This has to be the last step, because otherwise the other libraries installed via `pip-install` will still try to install Pillow and overwrite Pillow-SIMD since they have different package names.
RUN CC="cc -mavx2" pip3 install -U pillow-simd==5.2.0.post1

COPY server.conf server.conf

ENTRYPOINT ["pilbox", "--config=server.conf"]
