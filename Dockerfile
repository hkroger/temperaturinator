FROM phusion/passenger-ruby23:latest
MAINTAINER Hannu "hkroger@gmail.com"

RUN apt-get update 
RUN apt-get -y install apt-utils
RUN apt-get -y install sudo autoconf automake pkg-config libtool

ENV HOME /root  
ENV RAILS_ENV production
ENV DB_HOSTS ""

CMD ["/sbin/my_init"]

RUN gem update bundler

RUN rm -f /etc/service/nginx/down  
RUN rm /etc/nginx/sites-enabled/default  

# Handle the gems first
ADD Gemfile /home/app/temperaturinator_website/
ADD Gemfile.lock /home/app/temperaturinator_website/
WORKDIR /home/app/temperaturinator_website
RUN chown -R app:app /home/app/temperaturinator_website
RUN gem environment
RUN sudo -u app bundle install --deployment

# Handle the app itself
ADD bin /home/app/temperaturinator_website/bin
ADD config /home/app/temperaturinator_website/config
ADD app /home/app/temperaturinator_website/app
ADD db /home/app/temperaturinator_website/db
ADD lib /home/app/temperaturinator_website/lib
ADD public /home/app/temperaturinator_website/public
ADD script /home/app/temperaturinator_website/script
ADD vendor /home/app/temperaturinator_website/vendor
ADD Rakefile /home/app/temperaturinator_website/
ADD config.ru /home/app/temperaturinator_website/
RUN mkdir -p log tmp

RUN chown -R app:app /home/app/temperaturinator_website
RUN sudo -u app RAILS_ENV=production rake assets:precompile

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD nginx.conf /etc/nginx/sites-enabled/measurinator.conf
ADD nginx-env.conf /etc/nginx/main.d/measurinator-env.conf
