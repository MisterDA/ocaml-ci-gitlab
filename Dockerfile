FROM ocaml/opam:debian-11-ocaml-4.13 AS build
RUN sudo apt-get update && sudo apt-get install libev-dev capnproto m4 pkg-config libsqlite3-dev libgmp-dev graphviz -y --no-install-recommends
RUN cd ~/opam-repository && git pull origin -q master && git reset --hard 61c80509aec809b94b4ff7a505235f1ba605c756 && opam update
RUN sudo ln -f /usr/bin/opam-2.1 /usr/bin/opam

COPY --chown=opam \
    ocurrent/current_docker.opam \
    ocurrent/current_git.opam \
    ocurrent/current_github.opam \
    ocurrent/current_gitlab.opam \
    ocurrent/current.opam \
    ocurrent/current_rpc.opam \
    ocurrent/current_web.opam \
    /src/ocurrent/

COPY --chown=opam \
    ocaml-gitlab/gitlab-unix.opam \
    ocaml-gitlab/gitlab.opam \
    /src/ocaml-gitlab/

COPY --chown=opam \
    ocluster/ocluster-api.opam \
    ocluster/current_ocluster.opam \
    /src/ocluster/

COPY --chown=opam \
    ocaml-version/ocaml-version.opam \
    /src/ocaml-version/

COPY --chown=opam \
    ocaml-dockerfile/dockerfile*.opam \
    /src/ocaml-dockerfile/

COPY --chown=opam \
    ocaml-matrix/matrix-common.opam \
    ocaml-matrix/matrix-ctos.opam \
    ocaml-matrix/matrix-current.opam \
    /src/ocaml-matrix/

COPY --chown=opam \
    ocaml-ci/ocaml-ci-service.opam \
    ocaml-ci/ocaml-ci-api.opam \
    ocaml-ci/ocaml-ci-solver.opam \
    ocaml-ci/ocaml-ci.opam \
    /src/ocaml-ci/

WORKDIR /src
RUN opam pin add -yn gitlab.dev "./ocaml-gitlab" && \
    opam pin add -yn gitlab-unix.dev "./ocaml-gitlab" && \
    opam pin add -yn current_docker.dev "./ocurrent" && \
    opam pin add -yn current_git.dev "./ocurrent" && \
    opam pin add -yn current_gitlab.dev "./ocurrent" && \
    opam pin add -yn current_github.dev "./ocurrent" && \
    opam pin add -yn current.dev "./ocurrent" && \
    opam pin add -yn current_web.dev "./ocurrent" && \
    opam pin add -yn current_ocluster.dev "./ocluster" && \
    opam pin add -yn ocaml-version.dev "./ocaml-version" && \
    opam pin add -yn dockerfile.dev "./ocaml-dockerfile" && \
    opam pin add -yn dockerfile-opam.dev "./ocaml-dockerfile" && \
    opam pin add -yn ocaml-ci-service.dev "./ocaml-ci" && \
    opam pin add -yn ocaml-ci-solver.dev "./ocaml-ci" && \
    opam pin add -yn ocaml-ci-api.dev "./ocaml-ci" && \
    opam pin add -yn ocaml-ci.dev "./ocaml-ci" && \
    opam pin add -yn matrix-common.dev "./ocaml-matrix" && \
    opam pin add -yn matrix-ctos.dev "./ocaml-matrix" && \
    opam pin add -yn matrix-current.dev "./ocaml-matrix" && \
    opam pin add -yn ocluster-api.dev "./ocluster"
COPY --chown=opam ocaml-ci-gitlab.opam /src/
RUN opam install -y --deps-only .
ADD --chown=opam . .
RUN opam exec -- dune build ./_build/install/default/bin/ocaml-ci-gitlab
RUN opam exec -- dune build ./_build/install/default/bin/ocaml-ci-solver

FROM debian:11
RUN apt-get update && apt-get install libev4 openssh-client curl gnupg2 dumb-init git graphviz libsqlite3-dev ca-certificates netbase -y --no-install-recommends
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN echo 'deb [arch=amd64] https://download.docker.com/linux/debian buster stable' >> /etc/apt/sources.list
RUN apt-get update && apt-get install docker-ce -y --no-install-recommends
WORKDIR /
ENTRYPOINT ["dumb-init", "/usr/local/bin/ocaml-ci-gitlab"]
ENV OCAMLRUNPARAM=a=2
# Enable experimental for docker manifest support
ENV DOCKER_CLI_EXPERIMENTAL=enabled
COPY --from=build /src/_build/install/default/bin/ocaml-ci-gitlab /src/_build/install/default/bin/ocaml-ci-solver /usr/local/bin/
