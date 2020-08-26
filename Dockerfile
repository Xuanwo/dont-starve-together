FROM centos:8
MAINTAINER Xuanwo <github@xuanwo.io>

# Set build arguments.
# Container runtime related.
ENV GOSU_VERSION 1.12
# Steam related.
ENV STEAM_USER "steam"
ENV STEAM_HOME "/opt/steam"
ENV STEAM_URL "https://cdn.steamstatic.com/client/installer/steamcmd_linux.tar.gz"
# DST related.
ENV DST_HOME /opt/dst
ENV DST_CLUSTER_PATH /var/lib/dst/cluster
ENV DST_SHARD "Master"
ARG DST_BRANCH
ENV DST_BRANCH ${DST_BRANCH}
ARG DST_BRANCH_PASSWORD
ENV DST_BRANCH_PASSWORD ${DST_BRANCH_PASSWORD}

# Add our user/group first to ensure their IDs get set consistently.
RUN groupadd -r $STEAM_USER && useradd -rm -d $STEAM_HOME -g $STEAM_USER $STEAM_USER

# Copy scripts
COPY scripts/* /usr/bin/

# Install dependences
RUN yum makecache && yum -y install glibc.i686 && yum clean all

# Install gusu
RUN curl -o /usr/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && chmod +x /usr/bin/gosu

# Install steamcmd
RUN curl -sSL $STEAM_URL | gosu $STEAM_USER tar -xzvC $STEAM_HOME

# Install Don't Starve Together Server.
RUN mkdir -p $DST_HOME \
    && chown $STEAM_USER:$STEAM_USER $DST_HOME \
    && ulimit -n 2048 \
    && gosu $STEAM_USER steamcmd \
      +@ShutdownOnFailedCommand 1 \
      +login anonymous \
      +force_install_dir $DST_HOME \
      +app_update 343050 \
        $([ -n "$DST_BRANCH" ] && printf %s "-beta $DST_BRANCH") \
        $([ -n "$DST_BRANCH_PASSWORD" ] && printf %s "-betapassword $DST_BRANCH_PASSWORD") \
        validate \
      +quit \
    && rm -rf $STEAM_HOME/Steam/logs $STEAM_HOME/Steam/appcache/httpcache \
    && find $STEAM_HOME/package -type f ! -name "steam_cmd_linux.installed" ! -name "steam_cmd_linux.manifest" -delete

# Set up volumes for presist files.
VOLUME ["$DST_HOME/mods", "$DST_CLUSTER_PATH"]

CMD ["dontstarve_server"]