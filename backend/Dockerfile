FROM ruby:3.2.2-slim AS base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev curl libyaml-dev postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

RUN chmod +x docker-entrypoint.sh bin/*

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
