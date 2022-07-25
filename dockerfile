# ------------------------------------------------------------------------------
# Pull base image.
FROM ubuntu:20.04
LABEL maintainer "Kazuki Isogai <i@kazukiisogai.net>"

# ------------------------------------------------------------------------------
# Install Base
RUN apt-get update && \
  apt-get install -y sudo locales curl g++ git vim libreadline-dev libpq-dev && \
  lsof bzip2 build-essential libssl-dev zlib1g-dev autoconf bison && \
  libyaml-dev libncurses-dev libffi-dev libgdbm6 libgdbm-dev && \
  curl https://cli-assets.heroku.com/install.sh | sh && \
  locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# ------------------------------------------------------------------------------
# Install PostgreSQL
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y postgresql postgresql-contrib

# ------------------------------------------------------------------------------
# Add users
USER root
RUN useradd -G sudo -m -s /bin/bash ubuntu && \
  echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/ubuntu && \
  echo 'root:password' | chpasswd
USER ubuntu

# ------------------------------------------------------------------------------
# Install Ruby 3.0.0
RUN git clone https://github.com/sstephenson/rbenv.git /home/ubuntu/.rbenv && \
    git clone https://github.com/sstephenson/ruby-build.git /home/ubuntu/.rbenv/plugins/ruby-build
ENV PATH /home/ubuntu/.rbenv/bin:$PATH
ENV RBENV_VERSION 3.0.0
ENV RACK_ENV development
RUN eval "$(rbenv init -)"; rbenv install $RBENV_VERSION && \
    eval "$(rbenv init -)"; rbenv global $RBENV_VERSION && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc && \
    mkdir /home/ubuntu/workspace

# ------------------------------------------------------------------------------
# Expose ports
EXPOSE 4567

# ------------------------------------------------------------------------------
# Add volumes
VOLUME /home/ubuntu/workspace
WORKDIR /home/ubuntu/workspace
ADD ./Gemfile Gemfile

# ------------------------------------------------------------------------------
# Setup bundle
RUN eval "$(rbenv init -)"; gem update --system && \
    eval "$(rbenv init -)"; gem install bundler -f && \
    eval "$(rbenv init -)"; bundle update && \
    eval "$(rbenv init -)"; bundle install

# ------------------------------------------------------------------------------
# Setup PostgreSQL
USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER ubuntu WITH SUPERUSER PASSWORD 'ubuntu';" && \
    createdb -O ubuntu ubuntu
USER ubuntu
RUN sed -i -e '$a sudo /etc/init.d/postgresql start && clear' ~/.bashrc

# ------------------------------------------------------------------------------
# Entrypoint
ENTRYPOINT ["/bin/bash"]