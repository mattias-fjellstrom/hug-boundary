FROM registry.access.redhat.com/ubi9-minimal:latest
 
USER root

RUN microdnf -y install yum-utils && \
   yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
   microdnf -y install boundary-enterprise && \
   mkdir -p /opt/boundary/{data,config} && \
   cp /etc/boundary.d/worker.hcl /opt/boundary/config/ 

RUN chgrp -R boundary /usr/bin/boundary && \                   
   chmod -R g=u /usr/bin/boundary && \
   chgrp -R boundary /opt/boundary && \
   chmod -R g=u /opt/boundary && \
   chown boundary /usr/bin/boundary && \                   
   chown -R boundary /opt/boundary
 
USER boundary
 
ENTRYPOINT ["boundary"]
CMD ["server", "-config=/opt/boundary/config/worker.hcl"]