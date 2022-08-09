FROM ruby:3

ENV PORT=80
ENV RACK_ENV=production

EXPOSE ${PORT}

WORKDIR /usr/src/app

COPY Gemfile ./
RUN bundle install --without="development test"

COPY public/ ./public
COPY views/ ./views
COPY config.ru server.rb ./

CMD ["bundle", "exec", "rackup"]