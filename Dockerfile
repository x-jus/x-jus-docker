FROM daggerok/jboss-eap-7.2
MAINTAINER crivano@jfrj.jus.br

#--- SET TIMEZONE
#--- RUN sh -c "ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone"

#--- DOWNLOAD LATEST VERSION FROM GITHUB
RUN echo "downloading x-jus.war" && curl -s https://api.github.com/repos/x-jus/x-jus/releases/latest \
  | grep browser_download_url \
  | grep .war \
  | cut -d '"' -f 4 \
  | wget -qi -

#--- DEPLOY DO ARQUIVO .WAR ---
RUN mv x-jus.war ${JBOSS_HOME}/standalone/deployments/

# COPY --chown=jboss ./*.war ${JBOSS_HOME}/standalone/deployments/

COPY --chown=jboss ./standalone.xml ${JBOSS_HOME}/standalone/configuration/standalone.xml

EXPOSE 8080