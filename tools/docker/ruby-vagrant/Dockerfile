FROM ruby:latest

RUN git clone https://github.com/hashicorp/vagrant.git &&\
    cd vagrant &&\
    gem build  &&\
    gem install vagrant-*.dev.gem &&\
    gem install rspec

CMD ["/bin/bash"]
