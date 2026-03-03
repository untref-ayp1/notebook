FROM jbindinga/java-notebook

COPY --chown=jovyan:users . /home/jovyan/

WORKDIR /home/jovyan/notebooks
