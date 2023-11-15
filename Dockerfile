FROM ruby:3.1

WORKDIR /consult

COPY Gemfile consult.gemspec ./
COPY lib/consult/version.rb ./lib/consult/version.rb
RUN bundle package --all --no-install
RUN bundle install

COPY . .

ENTRYPOINT ["ruby", "bin/consult"]
CMD ["--help"]
