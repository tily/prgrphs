FROM ruby:2.0.0
ENV WORKDIR /usr/local/app
ADD . $WORKDIR
WORKDIR $WORKDIR
RUN apt-get update && apt-get install -y libqt4-dev libqtwebkit-dev xvfb vim unzip
ADD fonts.conf /etc/fonts/fonts.conf
RUN bundle install
RUN cd /tmp && \
    mkdir noto && \
    curl -O -L https://noto-website-2.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip && \
    unzip NotoSansCJKjp-hinted.zip -d ./noto && \
    mkdir -p /usr/share/fonts/noto && \
    cp ./noto/*.otf /usr/share/fonts/noto/ && \
    chmod 644 /usr/share/fonts/noto/*.otf && \
    fc-cache -fv && \
    rm -rf NotoSansCJKjp-hinted.zip ./noto
