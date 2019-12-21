FROM phusion/passenger-ruby23:latest
MAINTAINER Hannu "hkroger@gmail.com"

RUN apt-get update
RUN apt-get -y install apt-utils
RUN apt-get -y install sudo autoconf automake pkg-config libtool tzdata

ENV TZ=Europe/Helsinki
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV HOME /root  
ENV RAILS_ENV production
ENV DB_HOSTS ""

CMD ["/sbin/my_init"]

RUN gem update bundler

RUN rm -f /etc/service/nginx/down  
RUN rm /etc/nginx/sites-enabled/default  

WORKDIR /home/app/measurinator_website

# Handle the gems first
ADD Gemfile /home/app/measurinator_website/
ADD Gemfile.lock /home/app/measurinator_website/
RUN chown -R app:app /home/app/measurinator_website
RUN gem environment
RUN sudo -u app bundle install --deployment

# Handle the app itself
ADD bin /home/app/measurinator_website/bin
ADD config /home/app/measurinator_website/config
ADD app /home/app/measurinator_website/app
ADD db /home/app/measurinator_website/db
ADD lib /home/app/measurinator_website/lib
ADD test /home/app/measurinator_website/test
ADD public /home/app/measurinator_website/public
ADD script /home/app/measurinator_website/script
ADD vendor /home/app/measurinator_website/vendor
ADD Rakefile /home/app/measurinator_website/
ADD config.ru /home/app/measurinator_website/
RUN mkdir -p log tmp

RUN chown -R app:app /home/app/measurinator_website
RUN sudo -u app RAILS_ENV=production rake assets:precompile

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD nginx.conf /etc/nginx/sites-enabled/measurinator.conf
ADD nginx-env.conf /etc/nginx/main.d/measurinator-env.conf
