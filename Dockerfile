FROM macromind/docker-apache-php74:latest
MAINTAINER MACROMIND Online <idc@macromind.online>
LABEL description="Laravel 5.8 + ModSecurity (OWASP CRS) + RemoteIP"

RUN apt-get update \
    && apt-get install -y --no-install-recommends libapache2-mod-security2 curl ca-certificates \
    && apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/*

# OWASP Core Rule Set 3.3.5 (compatível com ModSecurity 2.9)
RUN mkdir -p /etc/modsecurity/crs \
    && curl -sL https://github.com/coreruleset/coreruleset/archive/v3.3.5.tar.gz \
       | tar -xz --strip-components=1 -C /etc/modsecurity/crs \
    && cp /etc/modsecurity/crs/crs-setup.conf.example /etc/modsecurity/crs/crs-setup.conf \
    && cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf \
    && sed -i 's|SecRuleEngine DetectionOnly|SecRuleEngine On|' /etc/modsecurity/modsecurity.conf

COPY conf/000-docker.conf /etc/apache2/sites-available/
COPY conf/security2.conf /etc/apache2/mods-available/security2.conf
COPY conf/remoteip.conf /etc/apache2/conf-available/remoteip.conf

RUN /usr/sbin/a2dissite '*' \
    && /usr/sbin/a2ensite 000-docker \
    && /usr/sbin/a2enmod headers security2 remoteip \
    && /usr/sbin/a2enconf remoteip

COPY apache2-foreground /usr/local/bin/
RUN chmod +x /usr/local/bin/apache2-foreground

EXPOSE 80

WORKDIR /var/www/html/

CMD ["apache2-foreground"]
