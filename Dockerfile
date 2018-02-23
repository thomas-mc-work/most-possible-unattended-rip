FROM whipper/whipper

# required env variables for the script
ENV BEETS_CONFIG=/config.albums-cover.yaml
ENV LOG_DIR=/logs
ENV OUTPUT_DIR=/output

USER root

# setup beets
RUN pip install beets \
  && apt-get install -y python-requests \
  && mkdir /home/worker/.config/beets && chown worker: /home/worker/.config/beets
COPY beets.yml /config.albums-cover.yaml
RUN chown worker: /config.albums-cover.yaml \
  && mkdir $LOG_DIR && chown worker: $LOG_DIR
VOLUME "$LOG_DIR"

# setup script
ENV SCRIPT_PATH=/auto-rip-audio-cd.sh
COPY auto-rip-audio-cd.sh $SCRIPT_PATH
RUN chmod +x $SCRIPT_PATH

USER worker

ENTRYPOINT ["/auto-rip-audio-cd.sh"]
