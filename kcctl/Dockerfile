FROM registry.access.redhat.com/ubi8/ubi-minimal:8.6
WORKDIR /home
COPY kcctl-1.0.0.Alpha5-linux-x86_64 /kcctl
RUN cp /kcctl/bin/kcctl /usr/bin
RUN chmod 775 /kcctl
CMD ["bash"]