FROM python:3.6.5
RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get -y \
    install libtiff5-dev libjpeg62-turbo-dev zlib1g-dev libpng-dev\
    libxml2-dev libxslt1-dev libfreetype6-dev libwebp-dev libcurl4-openssl-dev

RUN mkdir /wheels
RUN pip wheel --disable-pip-version-check --no-deps --wheel-dir /wheels https://github.com/fdoumet/pilbox/archive/master.zip
COPY requirements.txt requirements.txt
RUN pip wheel --disable-pip-version-check --no-deps --wheel-dir /wheels -r requirements.txt

FROM python:3.6.5

RUN apt-get update && apt-get install -y \
    libtiff5 libjpeg62-turbo-dev zlib1g-dev \
    libxml2 libxslt1.1 libopenjp2-7 libfreetype6-dev libwebp6 libpng-dev libcurl4-openssl-dev \
    &&  apt-get autoremove -y &&  apt-get clean -y

COPY --from=0 /wheels /wheels
RUN ln -s /usr/lib/x86_64-linux-gnu/libz.so /lib/
RUN ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /lib/
RUN pip install -U pip

# Build regular Pillow here so that other libraries below try to install it themselves
RUN pip install pillow==5.2.0 ring==0.7.3 requests==2.22.0 pycurl==7.43.0.3
RUN pip install --disable-pip-version-check --no-index --no-deps /wheels/* && rm -rf /wheels requirements.txt
# Replace Pillow with Pillow-SIMD. This has to be the last step, because otherwise the other libraries installed via `pip-install` will still try to install Pillow and overwrite Pillow-SIMD since they have different package names.
RUN CC="cc -mavx2" pip3 install -U pillow-simd==5.2.0.post1

COPY server.conf server.conf

ENTRYPOINT ["pilbox", "--config=server.conf"]
