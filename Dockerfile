FROM ruby:3

ENV PORT=9292
ENV RACK_ENV=production

EXPOSE ${PORT}

WORKDIR /usr/src/app

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs chromium

COPY Gemfile ./
RUN bundle install --without="development test"

COPY package.json ./
RUN npm install

COPY public/ ./public
COPY views/ ./views
COPY config.ru server.rb ./

CMD ["bundle", "exec", "rackup"]