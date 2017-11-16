FROM baltig.infn.it:4567/gerda/gerdasw-containers/gerda-base:g4.9.6

LABEL maintainer="luigi.pertoldi@pd.infn.it"

USER root

# compile and install the gerda software:
# some shell logic is needed to speed up the build with make -j"$(nproc)" 
# when an error occurs and thus Docker stops the build
#
# the software will be installed in /opt/gerdasw

COPY MGDO /opt/gerdasw/src/MGDO
WORKDIR /opt/gerdasw/src/MGDO
RUN mkdir -p /opt/gerdasw && \
    ./configure --enable-tam --enable-streamers --prefix="/opt/gerdasw" && \
    make -j"$(nproc)" || true && \
    make -j"$(nproc)" || true && \
    make -j"$(nproc)" || true && \
    make && make install

# make the software visible

ENV PATH="/opt/gerdasw/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/gerdasw/lib:$LD_LIBRARY_PATH" \
    MGDODIR="/opt/gerdasw/src/MGDO"

COPY GELATIO /opt/gerdasw/src/GELATIO
WORKDIR /opt/gerdasw/src/GELATIO
RUN ./configure --prefix="/opt/gerdasw" && \
#    make -j"$(nproc)" || true && \
#    make -j"$(nproc)" || true && \
#    make -j"$(nproc)" || true && \
    make && make install

ENV GELATIODIR="/opt/gerdasw/src/GELATIO"

COPY databricxx /opt/gerdasw/src/databricxx
WORKDIR /opt/gerdasw/src/databricxx
RUN ./autogen.sh && ./configure --prefix="/opt/gerdasw" && \
    make -j"$(nproc)" && make install && \
    rm -rf /opt/gerdasw/src/databricxx

COPY gerda-ada /opt/gerdasw/src/gerda-ada
WORKDIR /opt/gerdasw/src/gerda-ada
RUN ./autogen.sh && ./configure --prefix="/opt/gerdasw" && \
    make -j"$(nproc)" && make install && \
    rm -rf /opt/gerdasw/src/gerda-ada

COPY MaGe /opt/gerdasw/src/MaGe
WORKDIR /opt/gerdasw/src/MaGe
RUN ./configure --prefix="/opt/gerdasw" && \
    make -j"$(nproc)" || true && \
    make -j"$(nproc)" || true && \
    make -j"$(nproc)" || true && \
    make && make install && \
    rm -rf /opt/gerdasw/src/MaGe

ENV GERDA_ANA_SANDBOX="/common/sw-other/gerda-ana-sandbox" \
    MGGERDAGEOMETRY="/common/sw-other/gerdageometry" \
    MGGENERATORDATA="/common/sw-other/gerda-ana-sandbox/BackgroundModel/MaGe_Datafiles" \
    MU_CAL="/common/sw-other/gerda-metadata/config/_aux/geruncfg"

# install dotfiles

COPY local-env-skeleton /root/local-env-skeleton
WORKDIR /root/local-env-skeleton
RUN ./install-sh

WORKDIR /root
RUN rm -rf .gitconfig local-env-skeleton && \
    sed -i '/ZSH=<.../c\ZSH=/root/.oh-my-zsh' .zshrc && \
    sed -i '/DEFAULT_USER="<...>"/c\DEFAULT_USER=root' .zshrc && \
    sed -i '29 i POWERLEVEL9K_HOST_TEMPLATE="gerda-sw"' .zshrc

CMD /bin/zsh
