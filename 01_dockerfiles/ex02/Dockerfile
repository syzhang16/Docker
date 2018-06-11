FROM ruby
# gem = paquet fournit 
RUN apt-get update && apt-get install -y nodejs && gem install rails && mkdir -p /opt/app
ONBUILD WORKDIR /opt/app
ONBUILD EXPOSE 3000
# bundle pour etre sure que les bons gems sont presents
# db:migrate = migration de framework en node.js rake = Make
# db:seed = population de db
ONBUILD RUN bundle install && rake db:migrate && rake db:seed

# pour verifier il faut une app rails avec un Dockerfile :
# FROM ft-rails-on-build
# CMD ["rails", "s", "-b", "0.0.0.0"]
#
# d'abord ce dockerfile en dehors du dossier de l'app puis celui dessus
# docker run -d -p 3000:3000 ft-rails
