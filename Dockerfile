FROM ubuntu:16.10

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -qy apt-utils aptitude
RUN aptitude install -yq zsh

SHELL ["zsh", "-c"]

RUN aptitude install -yq \
      nano less vim-nox cowsay libczmq3 ruby bundler rake git ruby-ffi-rzmq
RUN ln -s /usr/lib/x86_64-linux-gnu/libzmq.so.5 /usr/lib/libzmq.so

COPY ./ /root/zeromq-example
COPY ./zlogin /root/.zlogin

WORKDIR /root/zeromq-example/gem
RUN rm Gemfile.lock && \
    bundle install && gem build zeromq_example.gemspec && \
    gem install zeromq_example-*.gem

ENV TERM screen-256color

CMD ["zsh", "-l"]
