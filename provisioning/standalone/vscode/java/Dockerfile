# syntax = edrevo/dockerfile-plus

INCLUDE+ ./base/Dockerfile


# Setup permissions

# Install required packages
RUN apt-get update && apt-get install -y \
  wget \
  maven \
  nginx \
  procps \
  --no-install-recommends
RUN  wget https://corretto.aws/downloads/latest/amazon-corretto-25-x64-linux-jdk.deb
RUN apt install ./amazon-corretto-25-x64-linux-jdk.deb

# Install VS code extension
RUN code-server --extensions-dir ${VSCODE_SRV_DIR}/extensions \
  --install-extension vscjava.vscode-java-pack \
  --install-extension vscode.simple-browser

# Remove apt and useless/dangerous packages
RUN apt-get clean && \
    apt-get remove --autoremove --purge -y apt sudo --allow-remove-essential

COPY ./java/settings.json ${VSCODE_SRV_DIR}/data/User/settings.json

COPY ./java/vscode/user-tasks.json ${VSCODE_SRV_DIR}/data/User/tasks.json

COPY ./java/devtools/h2-console.sh /usr/local/bin/h2-console
RUN chmod +x /usr/local/bin/h2-console


RUN chown -R ${USER}:${USER} ${VSCODE_SRV_DIR}

USER ${USER}

WORKDIR ${VSCODE_SRV_DIR}

# Forces Maven to preload dependencies
RUN --mount=type=bind,source=./java/triggerproject/,target=./triggerproject cd ${VSCODE_SRV_DIR}/triggerproject && mvn -q -DskipTests dependency:go-offline test && rm -rf /tmp/target

RUN git config --global credential.helper 'cache --timeout=10800'&&\
    git config --global user.email student@crownlabs.polito.it &&\
    git config --global user.name crownlabs
    
ENTRYPOINT [ "/start.sh" ]
