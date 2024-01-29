# docker run -d --name jenkins-agent --network gitlab_gitlab_network jenkins-agent:v1

FROM ubuntu:22.04

LABEL maintainer="Eduardo Fernández <eduardo.fernandez@tii.ae>"

RUN apt update && apt install -y \
        openjdk-11-jre-headless curl git build-essential cmake doxygen graphviz

RUN mkdir -p /root/.ssh

ADD agent.jar agent.jar
ADD id_rsa /root/.ssh/id_rsa
ADD known_hosts /root/.ssh/known_hosts

RUN chmod 400 /root/.ssh/id_rsa

CMD ["java", "-jar", "agent.jar", "-jnlpUrl", "http://f16b0cc359e7:8080/computer/agent1/jenkins-agent.jnlp", "-workDir", "/home/ubuntu/jenkins"]
