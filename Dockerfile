FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y sudo vim nano curl git build-essential libreadline-dev \
            zlib1g-dev libssl1.0-dev libbz2-dev libsqlite3-dev libffi-dev jq

RUN mkdir -p /pbi/dept /pbi/collections /pbi/analysis

# Create non-root user
RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1000 ubuntu
WORKDIR /home/ubuntu
RUN chown -R ubuntu /pbi

# Pyenv:
ENV PYENV_ROOT="/home/ubuntu/.pyenv" \
    PATH="/home/ubuntu/.pyenv/shims:/root/.pyenv/bin:${PATH}" \
    PIPENV_YES=1 \
    PIPENV_DONT_LOAD_ENV=1 \
    LC_ALL="C.UTF-8" \
    LANG="en_US.UTF-8"

RUN curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash \
    && /home/ubuntu/.pyenv/bin/pyenv install 2.7.8 && /home/ubuntu/.pyenv/bin/pyenv global 2.7.8 \
    && /home/ubuntu/.pyenv/bin/pyenv rehash && pip install --upgrade pip

# Install python libraries here
RUN pip install -r requirements.txt

# Add tool-specific code
ADD src/ /home/ubuntu/src
ADD etc/ /home/ubuntu/etc

USER ubuntu
ENTRYPOINT ["python", "/home/ubuntu/src/main.py"]