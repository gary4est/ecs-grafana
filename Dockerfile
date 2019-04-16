FROM grafana/grafana:6.0.2

USER root

RUN apt-get update && apt-get -qq -y install wget && \
        apt-get autoremove -y && \
        rm -rf /var/lib/apt/lists/*

RUN wget -O /bin/aws-env https://github.com/Droplr/aws-env/blob/master/bin/aws-env-linux-amd64
RUN chmod +x /bin/aws-env

ENTRYPOINT ["/bin/bash", "-c", "eval $(/bin/aws-env) && /run.sh"]
