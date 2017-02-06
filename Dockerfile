FROM ruby:2.0.0
ENV WORKDIR /usr/local/app
ADD . $WORKDIR
WORKDIR $WORKDIR
RUN apt-get update && apt-get install -y libqt4-dev libqtwebkit-dev xvfb
RUN bundle install
