FROM joelametta/whipper

# required env variables for the script
ENV LOG_DIR=/logs

USER root

# setup beets, dependency munkres supports python2 up to 1.0.12
RUN pip install --quiet beets munkres==1.0.12 \
  && apt-get install -yqq python-requests \
  && mkdir /home/worker/.config/beets && chown worker: /home/worker/.config/beets \
  && mkdir -p -- "$LOG_DIR" \
  && chown worker: "$LOG_DIR"
COPY --chown=worker:worker beets.yml /home/worker/.config/beets/config.cover.yaml

# add startup script
COPY auto-rip-audio-cd.sh /auto-rip-audio-cd.sh
RUN chmod +x /auto-rip-audio-cd.sh

VOLUME "$LOG_DIR"
USER worker

ENTRYPOINT ["/auto-rip-audio-cd.sh"]
