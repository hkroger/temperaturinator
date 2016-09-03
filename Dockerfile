FROM phusion/passenger-ruby22
MAINTAINER Hannu "hkroger@gmail.com"

RUN apt-get update 
RUN apt-get -y install apt-utils
RUN apt-get -y install sudo autoconf automake pkg-config libtool

ENV HOME /root  
ENV RAILS_ENV production

CMD ["/sbin/my_init"]

RUN rm -f /etc/service/nginx/down  
RUN rm /etc/nginx/sites-enabled/default  
ADD nginx.conf /etc/nginx/sites-enabled/temperaturinator_website.conf

ADD . /home/app/temperaturinator_website
WORKDIR /home/app/temperaturinator_website  
RUN chown -R app:app /home/app/temperaturinator_website  
RUN sudo -u app bundle install --deployment  
RUN sudo -u app RAILS_ENV=production rake assets:precompile

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*  
