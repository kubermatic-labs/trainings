FROM ubuntu:20.10
RUN mkdir /data
ENTRYPOINT [ "/bin/sh", "-c", "while true; do echo $(date) >> /data/file.txt; sleep 10; done;" ]
