FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=non-interactive

RUN apt-get update && \
    apt-get install -y openssh-server python3 python3-pip python3-venv git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh /root/entrypoint.sh
COPY ./ansible-cli.sh /root/ansible-cli.sh
RUN chmod +x /root/ansible-cli.sh && \
    /root/ansible-cli.sh install

ENTRYPOINT ["/root/entrypoint.sh"]
CMD ["bash"]